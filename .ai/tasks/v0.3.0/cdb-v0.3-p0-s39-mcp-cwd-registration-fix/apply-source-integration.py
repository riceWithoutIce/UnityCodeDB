"""Apply the user-approved S39 72-path proposal without staging or delivery."""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[4]
PREP = ROOT / ".artifacts/maintenance/s39-source-integration-proposal"
OUT = ROOT / ".artifacts/maintenance/s39-source-integration-execution"
PACKAGE = "com.rice.ai-codedb/"


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def sha(data):
    return hashlib.sha256(data).hexdigest() if data is not None else None


def read(path):
    target = ROOT / path
    return target.read_bytes() if target.is_file() else None


def inventory():
    return set(git("ls-files", "--", PACKAGE).decode().splitlines()) | set(
        git("ls-files", "--others", "--exclude-standard", "--", PACKAGE).decode().splitlines())


assert not OUT.exists(), "Preserve prior execution evidence; no automatic retry."
proposal = json.loads((PREP / "proposal.json").read_bytes())
baseline = json.loads((PREP / "input-package-sha256.json").read_bytes())
assert proposal["status"] == "PROPOSAL_ONLY_PRIMARY_NOT_WRITTEN"
assert git("rev-parse", "HEAD").decode().strip() == proposal["base"]
rows = proposal["rows"]
assert len(rows) == 72 and len({r["path"] for r in rows}) == 72
assert inventory() == set(baseline), "Package path inventory drift."
assert all(sha(read(p)) == expected for p, expected in baseline.items()), "Package input drift."
index_path = Path(git("rev-parse", "--git-path", "index").decode().strip())
if not index_path.is_absolute():
    index_path = ROOT / index_path
index_before = sha(index_path.read_bytes())
candidate = {}
for row in rows:
    path = row["path"]
    target = ROOT / path
    assert path.startswith(PACKAGE) and target.resolve().is_relative_to(ROOT.resolve())
    data = (PREP / "candidate-delta" / path).read_bytes()
    assert sha(data) == row["proposed_sha256"], "Proposal bytes drift: " + path
    assert sha(read(path)) == row["before_sha256"], "Preimage drift: " + path
    if row["before_sha256"] is not None:
        assert sha((PREP / "preimage" / path).read_bytes()) == row["before_sha256"]
    candidate[path] = data

archive = git("archive", proposal["accepted_source"], "--", PACKAGE + "Payload~/Generations/")
with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
    predecessors = {m.name: tar.extractfile(m).read() for m in tar.getmembers()
                    if m.isfile() and "/poc.44/" not in m.name}
assert len(predecessors) == 447


def verify(reader):
    payload = json.loads(reader(PACKAGE + "Payload~/payload-manifest.json"))
    assert payload["generation_id"] == "poc.44" and len(payload["files"]) == 62
    for entry in payload["files"]:
        path = PACKAGE + "Payload~/" + entry["source"]
        assert sha(reader(path)) == entry["sha256"], "Payload closure: " + path
    for gen in ["poc.42", "poc.43", "poc.44"]:
        prefix = PACKAGE + "Payload~/Generations/" + gen + "/"
        manifest = json.loads(reader(prefix + "generation-manifest.json"))
        for entry in manifest["files"]:
            assert sha(reader(prefix + entry["path"])) == entry["sha256"], prefix + entry["path"]
    assert all(reader(path) == data for path, data in predecessors.items())
    pointer = json.loads(reader(PACKAGE + "Payload~/host-current.json"))
    assert pointer["generation_id"] == "poc.44"
    assert pointer["generation_manifest_sha256"] == sha(reader(
        PACKAGE + "Payload~/Generations/poc.44/generation-manifest.json"))
    status = json.loads(reader(PACKAGE + "Tests/Editor/OwnerIdentityV2Status.json"))["status"]
    for view in [status, status["operational_readiness"]]:
        assert view["selected_generation_id"] == "poc.44"
        assert view["target_generation_id"] == "poc.44"
        assert view["runtime_contract_sha256"] == sha(reader(PACKAGE + "Payload~/payload-manifest.json"))


verify(lambda p: candidate[p] if p in candidate else read(p))
OUT.mkdir(parents=True)
written = []
with (OUT / "writes.jsonl").open("x", encoding="utf-8") as journal:
    for row in rows:
        path = row["path"]
        assert sha(read(path)) == row["before_sha256"], "Concurrent source drift: " + path
        target = ROOT / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(candidate[path])
        assert sha(read(path)) == row["proposed_sha256"], "Write mismatch: " + path
        written.append(path)
        journal.write(json.dumps({"path": path, "sha256": row["proposed_sha256"]}) + "\n")
        journal.flush()
verify(read)
assert all(sha(read(p)) == expected for p, expected in baseline.items() if p not in candidate)
assert inventory() == set(baseline) | set(candidate), "Unexpected Package path change."
assert git("rev-parse", "HEAD").decode().strip() == proposal["base"]
assert sha(index_path.read_bytes()) == index_before, "Git index changed."
receipt = {
    "status": "SOURCE_INTEGRATION_PASS_NOT_COMMITTED_NOT_RELEASE_ACCEPTED",
    "base_head_unchanged": proposal["base"], "accepted_source": proposal["accepted_source"],
    "proposal_sha256": sha((PREP / "proposal.json").read_bytes()),
    "applied_paths": len(written), "payload_entries_checked": 62,
    "generation_closure_checked": ["poc.42", "poc.43", "poc.44"],
    "predecessor_files_equal": 447, "fixture_selection_and_contract_match": True,
    "out_of_scope_package_bytes_unchanged": True, "package_inventory_unchanged_outside_allowlist": True,
    "git_index_unchanged": True, "retained_preimages": ".artifacts/maintenance/s39-source-integration-proposal/preimage/",
    "remaining_local_package_paths": proposal["remaining_local_package_paths"],
    "applied": [{"path": r["path"], "sha256": r["proposed_sha256"]} for r in rows]
}
(OUT / "result.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: v for k, v in receipt.items() if k != "applied"}, indent=2))

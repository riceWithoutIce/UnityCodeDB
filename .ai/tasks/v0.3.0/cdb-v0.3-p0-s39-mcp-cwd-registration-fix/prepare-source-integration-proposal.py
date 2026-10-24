"""Build an S39 integration proposal under .artifacts; never write source."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[4]
BASE = "237c72d9980114b99887fb8e805658447dd8d4fd"
SOURCE = "c848049d90fbdf618905be25225580642d98d987"
PACKAGE = "com.rice.ai-codedb/"
OUT = ROOT / ".artifacts/maintenance/s39-source-integration-proposal"
assert not OUT.exists(), "Preserve an existing proposal; do not overwrite it."


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def blob(ref, path):
    return git("show", ref + ":" + path)


def sha(data):
    return hashlib.sha256(data).hexdigest() if data is not None else None


def local(path):
    target = ROOT / path
    return target.read_bytes() if target.is_file() else None


def save(relative, data):
    target = OUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)


assert git("rev-parse", "HEAD").decode().strip() == BASE, "Primary HEAD drift."
tracked = git("ls-files", "--", PACKAGE).decode().splitlines()
all_paths = sorted(set(tracked) | set(git(
    "ls-files", "--others", "--exclude-standard", "--", PACKAGE
).decode().splitlines()))
before = {p: sha(local(p)) for p in all_paths}
delta = git("diff", "--name-only", BASE, SOURCE, "--", PACKAGE).decode().splitlines()
assert len(delta) == 41
overlay = {p: blob(SOURCE, p) for p in delta}
contract = PACKAGE + "Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md"
for name, data in [("local", local(contract)), ("base", blob(BASE, contract)),
                   ("accepted", overlay[contract])]:
    save("merge-inputs/" + name + ".md", data)
merged = subprocess.run([
    "git", "merge-file", "-p", str(OUT / "merge-inputs/local.md"),
    str(OUT / "merge-inputs/base.md"), str(OUT / "merge-inputs/accepted.md")
], cwd=ROOT, capture_output=True)
assert merged.returncode == 0, merged.stderr.decode(errors="replace")
overlay[contract] = merged.stdout
predecessors = git("ls-tree", "-r", "--name-only", SOURCE, "--",
                   PACKAGE + "Payload~/Generations/").decode().splitlines()
predecessors = [p for p in predecessors if "/poc.44/" not in p]
assert len(predecessors) == 447
adjacent = []
for path in predecessors:
    accepted = blob(SOURCE, path)
    if local(path) != accepted:
        overlay[path] = accepted
        adjacent.append(path)
assert len(adjacent) == 31, "Adjacent predecessor disposition drift."


def proposed(path):
    return overlay[path] if path in overlay else local(path)


payload = json.loads(proposed(PACKAGE + "Payload~/payload-manifest.json"))
prior_payload = json.loads(local(PACKAGE + "Payload~/payload-manifest.json"))
inventory = {}
for key in ["bootstrap_transitions", "retired_targets"]:
    old = {json.dumps(x, sort_keys=True) for x in prior_payload[key]}
    new = {json.dumps(x, sort_keys=True) for x in payload[key]}
    assert not old - new, "Unique local inventory needs disposition."
    inventory[key] = {"local": len(old), "proposed": len(new), "local_only": 0}
closure = []
for entry in payload["files"]:
    path = PACKAGE + "Payload~/" + entry["source"]
    actual = sha(proposed(path))
    assert actual == entry["sha256"], "Payload mismatch: " + path
    closure.append({"path": path, "sha256": actual})
for gen in ["poc.42", "poc.43", "poc.44"]:
    prefix = PACKAGE + "Payload~/Generations/" + gen + "/"
    manifest = json.loads(proposed(prefix + "generation-manifest.json"))
    for entry in manifest["files"]:
        assert sha(proposed(prefix + entry["path"])) == entry["sha256"], prefix + entry["path"]
assert all(proposed(p) == blob(SOURCE, p) for p in predecessors)
rows = []
for path, data in sorted(overlay.items()):
    previous = local(path)
    if previous is not None:
        save("preimage/" + path, previous)
    save("candidate-delta/" + path, data)
    rows.append({"path": path, "before_sha256": sha(previous),
                 "proposed_sha256": sha(data),
                 "disposition": "merge_local_contract" if path == contract else
                 "restore_predecessor" if path in adjacent else "accepted_s39_delta"})
assert before == {p: sha(local(p)) for p in all_paths}, "Primary input drift."
remaining = [p for p in all_paths if p not in overlay and
             local(p) != blob(SOURCE, p)]
receipt = {"status": "PROPOSAL_ONLY_PRIMARY_NOT_WRITTEN", "base": BASE,
           "accepted_source": SOURCE, "overlay_paths": len(rows),
           "accepted_delta_paths": len(delta), "adjacent_predecessor_paths": len(adjacent),
           "payload_entries_checked": len(closure), "predecessor_files_equal": len(predecessors),
           "generation_closure_checked": ["poc.42", "poc.43", "poc.44"],
           "inventory": inventory, "primary_unchanged": True,
           "remaining_local_package_paths": remaining,
           "rows": rows}
save("proposal.json", (json.dumps(receipt, indent=2) + "\n").encode())
save("input-package-sha256.json", (json.dumps(before, indent=2) + "\n").encode())
print(json.dumps({k: v for k, v in receipt.items() if k != "rows"}, indent=2))

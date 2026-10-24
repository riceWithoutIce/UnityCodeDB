"""Read an explicit consumer root; write only a repository-owned receipt."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument("--project-root", type=Path, required=True)
args = parser.parse_args()
project = args.project_root.resolve()
repository = Path(__file__).resolve().parents[4]
output = repository / ".artifacts/maintenance/s39-lifecycle-acceptance/preparation-01"
assert not output.exists(), "Preserve an existing baseline; do not overwrite."


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(relative):
    return (project / relative).read_bytes()


def document(relative):
    return json.loads(read(relative))


pointer_path = "AIWork/.runtime/codedb/control/current-instance.json"
pointer_bytes = read(pointer_path)
pointer = json.loads(pointer_bytes)
assert pointer["instance_id"] == "fe3b257859f34023a9e290db3b2ad457"
assert pointer["activation_epoch"] == "5bed173a875e461c981da8b7829a897b"
assert pointer["generation_id"] == "poc.44"
instance_path = pointer["instance_relative_path"] + "/instance.json"
instance_bytes = read(instance_path)
instance = json.loads(instance_bytes)
assert sha(instance_bytes) == pointer["instance_manifest_sha256"]
assert instance["project_identity"] == pointer["project_identity"]
assert instance["instance_id"] == pointer["instance_id"]
assert instance["state"] == "READY" and instance["package_version"] == "0.3.0-preview.5"
ref = document("Packages/manifest.json")["dependencies"]["com.rice.ai-codedb"]
assert ref == "file:../../Packages/c848049-codedbtest2/com.rice.ai-codedb"
lock = document("Packages/packages-lock.json")["dependencies"]["com.rice.ai-codedb"]
assert lock["version"] == ref and lock["source"] == "local"
package = (project / "Packages" / ref[5:]).resolve()
archive_path = repository / ".artifacts/exports/s39-cwd-c848049/com.rice.ai-codedb.zip"
archive_sha = sha(archive_path.read_bytes())
assert archive_sha == "3d266307ba7e052140575ada0c39d689e5a62d28a9aa3d686420f15e76a98a5d"
with zipfile.ZipFile(archive_path) as archive:
    entries = [entry for entry in archive.infolist() if not entry.is_dir()]
    assert len(entries) == 664
    expected = set()
    for entry in entries:
        relative = entry.filename.removeprefix("com.rice.ai-codedb/")
        expected.add(relative)
        assert sha((package / relative).read_bytes()) == sha(archive.read(entry)), relative
extras = sorted(p.relative_to(package).as_posix() for p in package.rglob("*")
                if p.is_file() and p.relative_to(package).as_posix() not in expected)
assert extras == ["Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta"]
config_sha = sha(read(".codex/config.toml"))
assert config_sha == "2d288afd9490ad2f51560f5a62658f12d2bb456326980e919b894035b3f0c2fd"
sample_path = "Assets/CodeDBValidation/CodeDBQueryProbe.cs"
assert sha(read(sample_path)) == "d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432"
control = "AIWork/.runtime/codedb/control/"
contract = control + "contracts/v0.3-control/v2/"
activation = document(contract + "activation.json")
assert activation["publication_phase"] == "COMMITTED"
assert activation["activation_epoch"] == pointer["activation_epoch"]
assert activation["current"]["instance_id"] == pointer["instance_id"]
runtime_sha = "ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5"
assert activation["runtime_contract_sha256"] == runtime_sha
assert sha((package / "Payload~/payload-manifest.json").read_bytes()) == runtime_sha
desired = document(control + "desired-state.json")
assert desired["desired_state"] == "INSTALLED"
supervisor = document(contract + "supervisor/supervisor-state.json")
keys = ["project_identity", "selected_instance_id", "selected_generation_id",
        "activation_epoch", "readiness_state", "reason_code", "updated_at_utc"]
observed = {k: supervisor.get(k) for k in keys}
operation = document(contract + "supervisor/operation.json")
assert read(pointer_path) == pointer_bytes, "Selection changed during baseline."
hash_paths = ["ProjectSettings/ProjectVersion.txt", "Packages/manifest.json",
              "Packages/packages-lock.json", ".codex/config.toml", pointer_path,
              instance_path, sample_path, contract + "activation.json"]
receipt = {
    "status": "DISK_BINDING_PASS_HUMAN_MANAGER_STATE_PENDING",
    "sampled_at_utc": datetime.now(timezone.utc).isoformat(),
    "project": "<test-projects>/CodedbTest_2", "unity_version": "2022.3.62f3",
    "package_reference": ref, "source_commit": "c848049d90fbdf618905be25225580642d98d987",
    "archive_sha256": archive_sha, "package_entries_matching": 664,
    "package_extra_files": [{"path": p, "sha256": sha((package / p).read_bytes())} for p in extras],
    "project_identity": pointer["project_identity"], "instance_id": pointer["instance_id"],
    "activation_epoch": pointer["activation_epoch"], "generation_id": "poc.44",
    "runtime_contract_sha256": runtime_sha,
    "originating_action": instance["originating_action"],
    "desired_state": desired["desired_state"], "cleanup_state": desired.get("cleanup_state"),
    "selected_pointer_unchanged_during_baseline": True,
    "supervisor_file_observation": observed,
    "supervisor_observation_limit": "Existing file only; not a current UI, live process, or lease-ownership assertion.",
    "last_supervisor_operation": {k: operation.get(k) for k in
                                  ["operation_id", "manager_action_id", "name", "state", "phase", "completed_at_utc"]},
    "input_sha256": {p: sha(read(p)) for p in hash_paths},
    "external_writes": 0, "explicit_codedb_tool_calls": 0, "component_starts_or_stops": 0
}
output.mkdir(parents=True)
(output / "baseline.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: v for k, v in receipt.items() if k != "input_sha256"}, indent=2))

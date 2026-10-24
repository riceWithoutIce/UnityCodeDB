# Diagnostics exact delivery and fresh-project preparation — 2026-10-20

Status: EXACT_DIAGNOSTICS_DELIVERY_PASS / FRESH_PROJECT_PREPARATION_PASS /
HUMAN_COMPILE_AND_FIRST_INSTALL_PENDING / REAL_CLIENT_QUERY_BLOCKED.

The human explicitly approved grants A/B. Their bounded execution completed.
No additional commit, push, public publish or runtime attempt is implied.

## Frozen source and exact artifact

- Commit: `237c72d9980114b99887fb8e805658447dd8d4fd`.
- Parent: `c07bb5903b5b3fcda7d97f5238c2915e3c566cf8`.
- Message: `fix(codedb): retain bootstrap termination diagnostics`.
- Scope: exactly six Package paths and seven named task records, 13 paths total.
  RESULT staging selected only diagnostics/preparation additions, leaving older
  historical unstaged additions untouched. Unrelated working-file bytes and
  existing deleted-file state were identical before and after the commit.
- ZIP: `.artifacts/tests/s39-diagnostics-delivery/r-e9f859cd/execution-9c51a1ce/export/com.rice.ai-codedb.zip`.
- ZIP SHA-256: `f6c1811ddd65f229f995192918940e1d07ac98bb8f5482aae6c01f890ebdcf7e`.
- Extracted Package: 631 files, 13,484,287 bytes, exactly one Package root.
- Runtime contract: `750f54d6bd187b51a436e28002ea2099b9ce0a21b9f9fe6543ecc4197269b84a`.
- Version remains `0.3.0-preview.5`; generation remains `poc.43`. The new commit,
  wrapper hash and runtime-contract hash distinguish this diagnostic delivery.

The committed exporter validated both the commit archive and exact ZIP:
60/60 source closure, production materializer admission and native binding PASS.
The exact ZIP's own path-provenance/helper binding checks PASS. All 15 isolated
diagnostic scenarios PASS using that same extracted Package:
`.artifacts/tests/s39-bootstrap-diagnostics/r-51a150b7-d13a-4b03-989f-b92442f5946d/result.json`.
These tests use synthetic workers, not the real Provider or Codex host.

## External Package and project

The exact extracted Package was copied to the new
`<external-packages>/237c72d/com.rice.ai-codedb` directory. Every one of its 631
file paths/hashes matches both the ZIP extraction and approved candidate.
The old c07bb59 Package inventory remains unchanged.

Only two new-project files were written:

| CodedbTest_1-relative path | Result / SHA-256 |
| --- | --- |
| `Packages/manifest.json` | Added only `com.rice.ai-codedb = file:../../Packages/237c72d/com.rice.ai-codedb`; `43ffa7711ccc5778f2461e12225b5bd1d3076782af5386658120e7f3e828bf22` |
| `Assets/CodeDBAcceptance/S39QueryProbe.cs` | Marker at line 5; `0b606ee895088add24435eb628f6ebfb2e3af8facec3133b6eee96623ba3041b` |

The Package URI resolves relative to the manifest's Packages directory to the
verified delivery. Other dependencies are unchanged. The marker is
`CODEDB_S39_EXTERNAL_20261020`. The sample uses UTF-8/LF as proposed.

The original version/lock hashes still match the read-only baseline. Unity is
reported closed by the human and no UnityLockfile appeared. No process inventory
was substituted for that human report. `.meta` and lock updates await normal
Unity import. No AIWork runtime or `.codex/config.toml` was pre-created.

CodedbTest_0's protected manifest, lock, MCP configuration, query sample, stable
wrapper and selected pointer hashes remain unchanged; the enumerated instance
manifest path's existence/hash is recorded in the receipt. No old-project file
was written and no old process was controlled.

## Receipts and next gate

Run root:
`.artifacts/tests/s39-diagnostics-delivery/r-e9f859cd/execution-9c51a1ce/`.

- `commit.json`, `staged.json`, `worktree-before.json`: source attribution.
- `export.log`, `exact-zip-diagnostics.log`, `exact-zip-provenance.log`: checks.
- `zip-inventory.json`, `external-inventory.json`, `external-copy.json`: exact copy.
- `old-package-before.json`, `original-project-before.json`: protected baselines.
- `project-before/`: byte-preserving backup of fresh project's version/manifest/lock.
- `project-preparation.json`: final file hashes and gate attribution.

Post-delivery result/checklist updates remain uncommitted; there was one approved
source commit, no amend and no push. The Git index is empty.

Next: `DIAGNOSTICS-HUMAN-FIRST-INSTALL-CHECKLIST.md`, executed by the human in
CodedbTest_1. No Unity, real Provider, Supervisor, Install/Reinstall/Uninstall,
real MCP query, new-chat dispatch or trace was started by this session. Install
and response identity do not exist yet for the new project. This result proves
artifact delivery and static preparation, not startup root cause, real-client
query, performance, upgrade or release acceptance.

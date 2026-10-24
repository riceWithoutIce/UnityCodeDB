# Updated S42 exact commit/export proposal

Status: APPROVED_AND_COMPLETE; see INSTANCE-CONTEXT-DELIVERY-RESULT.md.
Source repair and focused evidence are complete
in INSTANCE-CONTEXT-REPAIR-RESULT.md. This proposal concerns an internal exact
artifact only, not live retirement, consumer delivery or public release.

## Frozen candidate

Existing repository-local S42 isolated checkout; branch
codex/coordinator-query-readiness. Parent:
267b921dee0385962885e8e3142b4e4903ab711b. Exactly two changed paths:

| Path under com.rice.ai-codedb | SHA-256 |
| --- | --- |
| Tools~/codedb-project-supervisor.mjs | 50260e1a355907a163e7841dc7a076e1917c0cec1e4b0d3f4f6f4a7186e59aca |
| Tests~/test-codedb-project-supervisor.mjs | dcfb3008eac55880b0ba5eae26f7acb962dcb345b3d92cab467d279b02b41e06 |

Prepared complete tree: 2ccee6fa1e29b597c0c87397dec4c8703036e0cf.
Computed in memory from the base tree and frozen raw blobs; baseline tree encoder
matched Git. No Git objects, index entries or commits were written in preparation.

INSTANCE-CONTEXT-DELIVERY-SNAPSHOT.json SHA-256:
8af47274b7ef68dfdc2b9a5668a9cf0f5b714617469cf564f4a2ec12c56207c0.

## Single proposed execution envelope

If the human explicitly approves this proposal, execute the following sequence
without asking again between its steps:

1. Recheck exact source/base/branch, empty isolated index and two-path scope.
   Fingerprint primary index without changing it. Stage exact raw blobs and verify
   indexed hashes/tree. One isolated-branch commit, title
   `Bind watch manager child to selected instance context`. No primary merge,
   cherry-pick, push, unrelated stage or history rewrite.
2. Existing exporter from the isolated checkout:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/export-codedb-package.ps1 -Commit <new-commit> -OutputRoot <repository-root>/.artifacts/exports/s42-instance-context-<sha7>`.
   Destination must be new. Require production payload admission and byte closure
   for both committed Package stage and exact ZIP extraction; no metadata repair.
3. Full stage/extracted inventory agreement and both frozen source hashes. Run
   only the three directly relevant explicit fixture modes from the extracted
   artifact: watch-manager context, S42 query-readiness and S32 disposition.
   Context is the new fix; readiness is the combined S42 delivery promise;
   disposition preserves the prior adjacent retirement/admission boundary.
   This repeats artifact acceptance on changed bytes, not unchanged Coder tests.
4. Record commit/parent/tree, exact ZIP SHA-256, inventory, closure and fixture
   results. Check isolated checkout clean and primary index unchanged. Stop here.

Prepared executors (syntax checked, not run):
execute-context-delivery-commit.cjs (requires a fresh human approval receipt bound
to the snapshot above), verify-context-exact-export.cjs.
Canonical new receipts: .artifacts/tests/s42-context-commit-export/execution-a/.
Prior export and all earlier attempt evidence remain untouched.

Stop affected execution on drift, unexpected scope, export/admission/fixture
failure or output collision; preserve already-created effects. No repair/replay
outside the agreed source objective, no consumer fallback.

Not included: live consumer reads/process probes/RPC, human Unity close/open,
Supervisor shutdown, watcher Stop/Start, Package copying/reference switching,
Install/Uninstall, MCP query, cleanup or public release. Unity does not need to
close for this repository-only gate.

Authorization boundary: the approved INSTANCE-CONTEXT-REPAIR-TASK explicitly
excluded commit/export. The project workflow's HANDOFF stage requires explicit
human authorization for this operation. Approval here covers the entire closed
commit/export/closure sequence, not the later live recovery gate.

# S29 Failed-Install Recovery - Accepted Commit And Local Delivery

Date: 2026-10-07. Status: DELIVERY_PASS / HUMAN_COMPILE_CHECKPOINT_READY.
Human ACCEPT applies to the source repair. Necessary preparation proceeded
under the standing instruction without repeated approval questions. S29 remains
PARTIAL; F-IMC-01/P3 remains DEFERRED.

## Commit and preservation

- Commit: 651f9b3b4a8af3108823036107f1d76bc450f760.
- Parent: 13bf5fd16c15c42e1379ce35a06e49c20753195f.
- Message: fix(host): finalize failed first-install recovery.
- Exactly 18 changed paths: nine accepted source/test paths, eight bounded
  task records, and only the new Failed Preparation Removal contract section.
- All ten source identities and frozen RESULT/IDENTITY matched before staging.
  All 358 generation hashes retained aggregate
  6014a59cde8ed85d47338b97a11adb272823fbe22cafcef3c99ca7c3b2ca8d94.
- Index was empty. Exact raw blobs were staged and compared; the dirty contract
  blob was built from HEAD plus only the accepted section. Standard staged
  diff-check passed. Committed blobs matched intended bytes for all 18 paths.
- Index is empty after commit; unrelated dirty/untracked content remains.
  No clean-worktree claim, add -A, reset/clean, amendment, push or tag.

## Exact local artifact

Root: .artifacts/0.3.0-preview.5-s29-failed-install-recovery-poc40.
Destination was absent; repository containment and reparse ancestors checked.
Unchanged committed exporter used the exact new commit once, without generation
or metadata repair. Existing artifacts remain preserved.

Exact Package entry:
G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-failed-install-recovery-poc40/review/com.rice.ai-codedb/package.json

- Version: 0.3.0-preview.5, generation poc.40.
- ZIP: com.rice.ai-codedb.zip, 2383933 bytes.
- ZIP SHA256: f9f80bb0596f5f45d88017d3f726405c66769d43cc65d6e361371fba3483b66b.
- Package files / ZIP entries: 513 / 513; content bytes: 10631890.
- Commit-staged byte closure: PASS, 52 sources, 0 mismatches.
- Exact extracted ZIP byte closure: PASS, 52 sources, 0 mismatches.
- All ten accepted source/test hashes match the extracted review Package.

## Exact-artifact consumer evidence

Command: Windows PowerShell -NoProfile -ExecutionPolicy Bypass -File
<exact Package>/Tests~/test-codedb-host-payload-materializer.ps1
-FailedPreparationRecoveryOnly.

Single invocation, no retry or source changes. The script's own PSScriptRoot
resolved the extracted Package; no worktree helper or Git-history substitution.
This newly executed full family complements, rather than relabels, the earlier
source windows' partial/reused evidence.

- Start: 2026-10-07T15:19:32.0561536Z; end: 2026-10-07T15:23:05.9227961Z.
- Wall: 213815 ms; family: 213181 ms; 300-second deadline not reached.
- Exit 0; 201 assertions; native_children=0; stderr 0 bytes.
- Exact PASS: [PASS] FailedPreparationRecoveryOnly; cases=201;
  native_children=0; elapsed_ms=213181.
- Stdout: 15959 UTF-8 bytes / 267 nonempty lines, drained and summarized rather
  than dumped into conversation. Stdout SHA256:
  a130dcb628dc1048f4dd1e2549086831aadab27b729d80f9db9d0c754e4e3a65.
- Covers CURRENT/ABSENT/OLD wrapper removal -> new Install -> retained PENDING,
  real record readers/transactions, wrong-binding preservation, publication
  interruption/recovery, status/admission/cleanup and existing v1 semantics.
- Provider/process/prerequisite/runtime availability fixture seams remain;
  this is isolated consumer evidence, not live runtime acceptance.

## Subsequent standing preparation - consumer reference

After the export/consumer gate passed, continued the already authorized
pre-human preparation: switched only CodeDB references in the human-reported
closed UnityFreshInstallValidationProjectS29's Packages/manifest.json and
Packages/packages-lock.json. This is a follow-on reference-preparation step,
not a real Install/Uninstall or part of the source commit.

Old reference:
file:G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-compile-fix-70f33f7/review/com.rice.ai-codedb

New reference:
file:G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-failed-install-recovery-poc40/review/com.rice.ai-codedb

Both JSON documents match the precomputed expected documents with only that
reference changed. testables and all other dependencies/settings are preserved.
Consumer paths and ancestors passed reparse checks. No Unity/process probe.

| File | Before raw SHA256 | After raw SHA256 |
| --- | --- | --- |
| manifest.json | 124caa8325f8b641ad5521c32026dcad324822bc9e909f0dd06e5aa76dddc5da | 41f1b1c3bec650e34d8208f3fb8bf620b29656863dfc39d30f93a393de6ebd15 |
| packages-lock.json | 11deb674346453ba067af4619d894cababdb933202a836c7f2d035178b14855a | e24d916afab5f3c0e9cd66904f756db30eaf8ed4e42e522efb70b56c7d985f50 |

No candidate, runtime/control record, lease, machine Provider or MCP config
was changed. No real recovery, Install, Unity launch, CUA/MCP/BatchMode, remote
task write or publication occurred. Source/tool/test paths are clean relative
to the new commit; local reference and follow-up documentation remain uncommitted.

## Handoff

FAILED-INSTALL-HUMAN-CHECKLIST.md gives one human-owned compile / 11-case / Manager
observation checkpoint. Keep the current real failed candidate intact. Do not
click Install, removal or Configure Dependencies before the concrete recovery
step is aligned. Unity may stay open after this checkpoint for the same-session
follow-up. C# compilation/EditMode, real recovery/ready and release remain NOT RUN.

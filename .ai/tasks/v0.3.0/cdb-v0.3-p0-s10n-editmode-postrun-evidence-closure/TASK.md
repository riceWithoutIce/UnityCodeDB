# Task: cdb-v0.3-p0-s10n-editmode-postrun-evidence-closure

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: v0.3.verifier.deep after Planner routing, only if this result is
  stable
- Review mode: GUARDED
- Complexity: Low
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor:
  `cdb-v0.3-p0-s10m-corrected-git-admission-editmode` (`BLOCKED` only because
  its frozen generic normal-completion log pattern matched zero lines after the
  exact Unity process had exited `0` and XML had passed `69/69`).
- Human authorization: on 2026-09-08 the user authorized this independent
  read-only evidence-closure task.

## Objective

- Close only S10m's residual post-run evidence gap using its existing frozen
  XML and Unity log.
- Recognize the exact `Saving results to:` record as the log-side completion
  evidence when its normalized target equals the frozen S10m XML.
- Complete the previously skipped ten-file identity, scoped-status, and final
  matching-Unity process checks once.
- Do not start Unity, rerun tests, or modify production, tests, Package,
  configuration, prior records, or existing evidence artifacts.

## Scope

- Read-only inputs:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10m-corrected-git-admission-editmode/TASK.md`;
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10m-corrected-git-admission-editmode/RESULT.md`;
  - `UnityValidationProject/TestResults-S10m-control-plane.xml`;
  - `UnityValidationProject/Logs/S10m-control-plane-corrected-editmode.log`;
  - the exact ten tracked files listed below.
- Only allowed output:
  - this task's `RESULT.md`.
- One admission/evidence command forms evidence batch `1/1`; retry `0/0`.
- Existing S10m XML/log are protected and must not be deleted, overwritten,
  normalized, touched, or regenerated.

## Frozen Inputs

- Expected HEAD:
  `6408b0d540b32584147588efb67ecc5ba12b2fda`.

| Repository-relative input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10m-corrected-git-admission-editmode/TASK.md` | `10931` | `b2bc1da1ba74c90a28673532f9af6c6e67ebecd3e7420123d0b048ebabb380bb` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10m-corrected-git-admission-editmode/RESULT.md` | `8482` | `866df276c39f9d12eee7537e8abad066aad286529274ba833ebefbae015879f9` |
| `UnityValidationProject/TestResults-S10m-control-plane.xml` | `55243` | `6628875ece46714f1b217ed08f4ff8b4b1c0f6cdd808d7dcb8b8738c874c9dd9` |
| `UnityValidationProject/Logs/S10m-control-plane-corrected-editmode.log` | `93997` | `1b60d8d43f6513d5f235fe862dfd915dd98180a2022fbc142f6c3d288949ca51` |

- Required tracked post-run identities:

| Repository-relative file | Expected status | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | ` M` | `249662` | `cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | ` M` | `733447` | `ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | ` M` | `183864` | `ce5784f90d4cdc18ffe4668329924557f909dc5a9280276d44907240d93d691b` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | clean | `156471` | `9d6b1c13e35562162b34d1e59c1d36bf28b7e1df7113793029a6e6dbc026898d` |
| `com.rice.ai-codedb/package.json` | clean | `723` | `4932ecb76b699ae3d917d4fbbde9513691bc8b62f2a0f1e39bf4b3bf70d31957` |
| `UnityValidationProject/Packages/manifest.json` | ` M` | `308` | `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd` |
| `UnityValidationProject/Packages/packages-lock.json` | ` M` | `1377` | `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913` |
| `UnityValidationProject/ProjectSettings/ProjectVersion.txt` | clean | `85` | `f450bbe4b5dc999988f56dff01af912886a765726ca3240d157357cff10517bf` |
| `UnityValidationProject/ProjectSettings/ProjectSettings.asset` | ` M` | `23135` | `9b1debf0b71ede99cbef5291d8aa9f5f3dac0a68c519ef60e2d70cf1638015e7` |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | ` M` | `378` | `8e18b1c820e9c09e16bbd1f1b7842e9fb3b0158a0921b0964e0b8fa12c6e2c01` |

- Preserve all unrelated modified and untracked worktree state. A commit is
  not an execution prerequisite.

## Single Evidence Batch

- Execute one self-contained read-only evidence command, batch `1/1`, retry
  `0/0`, with a maximum command duration of `30s` and captured output below
  `16 KiB`.
- Require all four frozen input identities and exact HEAD before reading
  evidence. Any mismatch is `BLOCKED` and ends the task.
- Parse the frozen XML structurally exactly once and require:
  - root result `Passed`;
  - total/passed `69/69`;
  - failed/skipped/inconclusive `0/0/0`;
  - exactly `39` distinct represented method identities;
  - no missing or extra mapping relative to the exact 39-name filter in the
    frozen S10m task.
- Read the frozen Unity log exactly once and perform only these bounded checks:
  - exactly one local `com.rice.ai-codedb` Package record whose normalized
    source and location equal the repository Package;
  - zero `error CS####` records;
  - zero immediate compiler-error summaries;
  - zero fatal/abort/crash markers;
  - exactly one `Saving results to:` record whose normalized target equals
    `UnityValidationProject/TestResults-S10m-control-plane.xml`.
- Treat that exact saved-results record, the frozen S10m exact-process exit
  `0`, and the structured XML `69/69` result as the three-way normal-completion
  evidence. Do not require or search for S10m's unmatched generic completion
  phrase.
- Do not print source lines, absolute paths, Package locations, or broad log
  excerpts. Emit compact assertion names and PASS/FAIL only.

## Post-Run Snapshot Closure

- In the same evidence batch, recompute all ten tracked file lengths and
  SHA-256 identities exactly once and require the table above.
- Query Git status exactly once for only those ten paths using porcelain v1
  with NUL delimiters. Preserve the two-character status code and compare
  normalized unordered path sets.
- Require exactly seven ` M` paths and three clean paths as declared above.
- If resolving Git through `Get-Command`, select one existing scalar
  executable from the returned application records before assigning
  `ProcessStartInfo.FileName`. Never join multiple executable paths and never
  print or persist the chosen machine path.
- Perform one point-in-time passive process query and require zero `Unity.exe`
  processes whose command line resolves to `UnityValidationProject/`.
- If a matching Unity process exists, return `BLOCKED`; do not poll, attach,
  signal, stop, or otherwise control it.

## Result Contract

- Write this task's `RESULT.md` with repository-relative paths only.
- Record:
  - exact frozen input and HEAD admission;
  - XML counts and exact 39-method coverage;
  - the saved-results completion disposition and its three-way correlation;
  - Package/compiler/fatal conclusions;
  - all ten final identities and exact `7 modified / 3 clean` status result;
  - final matching-Unity process count;
  - batch `1/1`, retry `0/0`, duration/output ledger, actual profile, and
    explicit `NOT RUN` / `DEFERRED` boundaries.
- Do not record machine, user-profile, Git/Unity executable, Package,
  temporary, synthetic, or evidence-line absolute paths.
- A passing result closes S10m's evidence procedure only. It remains focused
  development EditMode evidence, not manual UI, runtime, consumer, release,
  publication, or Verifier acceptance.

## Prohibited Actions

- Do not start Unity, Unity Hub, Unity MCP, Package Manager, Supervisor, Node,
  PowerShell product probes, or any other validation process.
- Do not rerun EditMode, a compiler, L0/L1 harness, test, or alternate log
  extraction.
- Do not modify source, tests, Package/configuration, validation settings,
  workflow, predecessor records, XML, or log.
- Do not run full status/diff, broad repository search, broad log output,
  `git diff --check`, or a second process/status query.
- Do not stop a process, delete an artifact, commit, push, stash, reset, clean,
  rebase, amend, contact Verifier, or dispatch repair work.

## Stop Conditions

- HEAD, a frozen input, XML/log structure, completion correlation, Package,
  compiler/fatal evidence, any tracked identity/status, or final process count
  differs from the declared contract.
- Output truncates, the command exceeds `30s`, or any retry, second read/query,
  investigation, edit, process action, or scope expansion would be required.

## Definition Of Done

- Existing S10m XML/log prove one normally completed focused run with `69/69`
  cases across exactly 39 methods.
- All ten post-run tracked identities and the exact seven-modified/three-clean
  status match the pre-run frozen snapshot.
- No matching validation-project Unity process exists at the final point check.
- No Unity/test execution or repository input modification occurs.

## Verification

- After Planner confirms a stable COMPLETE result, route the exact S10m/S10n
  evidence snapshot to `v0.3.verifier.deep` for one GUARDED targeted read-only
  review.
- Verifier must reuse the existing artifacts and must not rerun Unity or any
  test. Any fix or rerun requires another Planner/user decision.

## Handoff

Current task: cdb-v0.3-p0-s10n-editmode-postrun-evidence-closure
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.standard
Next action: execute the one-shot read-only evidence closure and return
`RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: Verifier routing, manual Unity
acceptance, any fix/rerun, commit, and push remain separate actions

# Task: cdb-v0.3-p0-s10m-corrected-git-admission-editmode

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep after Planner routing, only if the result is
  stable
- Review mode: GUARDED
- Complexity: High
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor:
  `cdb-v0.3-p0-s10l-corrected-focused-editmode-rerun` (`BLOCKED` before Unity
  launch because its command-local admission helper passed two Git executable
  paths to one `ProcessStartInfo.FileName`).
- Human authorization: on 2026-09-07 the user accepted S10k and authorized the
  next independent bounded task.

## Objective

- Correct only S10l's command-local Git executable selection during admission.
- If the corrected admission passes, run exactly one fresh synchronous Unity
  2022.3 EditMode batch for the unchanged S10l filter: `39` methods / `69`
  NUnit cases.
- Establish focused development evidence for Package resolution, Editor/test
  compilation, complete filter coverage, test results, and process exit.
- Do not modify production code, tests, Package/configuration, or prior task
  records.

## Scope

- Validation project: `UnityValidationProject/` only.
- The complete S10l validation contract remains authoritative except for the
  explicit helper and artifact-name corrections in this task.
- Read these predecessor inputs once:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10l-corrected-focused-editmode-rerun/TASK.md`;
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10l-corrected-focused-editmode-rerun/RESULT.md`;
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10k-supervisor-schema-expectation-evidence/DECISION.md`.
- Allowed durable output:
  - this task's `RESULT.md`.
- Allowed ignored run artifacts:
  - `UnityValidationProject/TestResults-S10m-control-plane.xml`;
  - `UnityValidationProject/Logs/S10m-control-plane-corrected-editmode.log`.
- Do not create a Unity project or change the validation project.

## Frozen Identity

- Expected HEAD:
  `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- S10l task:
  - bytes: `16177`;
  - SHA-256:
    `9bef5bf3a1febfd21f7f747adf97ac1e07b5ea686f332f3e6d8bdb29c806e3db`.
- S10l result:
  - bytes: `4600`;
  - SHA-256:
    `0eba4ed7fb24f5bf8dba0b7b7986f9fc4ed990f8029c694f3fc2ce5307a83b97`.
- Accepted S10k decision:
  - bytes: `2250`;
  - SHA-256:
    `8771ca404d2902bc5350eeb31b1a3ea8d6022aec163864b85076fbfadb877025`.
- Corrected lifecycle test input:
  - path: `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`;
  - bytes: `183864`;
  - SHA-256:
    `ce5784f90d4cdc18ffe4668329924557f909dc5a9280276d44907240d93d691b`.
- The ten tracked input identities in S10l `TASK.md` remain unchanged and are
  incorporated here by the exact frozen S10l task identity above. Verify each
  once during admission.
- Expected relevant status remains exactly S10l's seven modified paths and
  three clean paths. Preserve the two-character porcelain status and compare
  normalized unordered path sets.
- Preserve all unrelated modified and untracked worktree state. Commit is not
  an execution prerequisite.

## Corrected Admission Helper

- Execute one bounded admission stage. S10l's partial admission is historical
  evidence only and must not be promoted or reused as a completed admission.
- For the NUL-delimited scoped-status process, discovery may return multiple
  Git application records. Select exactly one concrete scalar executable path
  before assigning `ProcessStartInfo.FileName`:

```powershell
$gitApplications = @(Get-Command git -CommandType Application -ErrorAction Stop)
$gitExecutable = @(
    $gitApplications |
        ForEach-Object { $_.Source } |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace($_) -and
            (Test-Path -LiteralPath $_ -PathType Leaf)
        } |
        Select-Object -Unique
)[0]

if ([string]::IsNullOrWhiteSpace($gitExecutable)) {
    throw "No concrete Git executable is available."
}

$processStartInfo.FileName = [string]$gitExecutable
```

- Require at least one valid discovered executable; multiple discovery records
  are allowed. Never join, concatenate, or interpolate multiple paths into
  `FileName`.
- Do not persist or print the executable path. This is a command-local helper
  correction, not a repository source change.
- Preserve NUL delimiters and run scoped porcelain-v1 status only for S10l's
  exact ten tracked paths. Do not fall back to a full status, textual line
  parsing, a broad diff, or a second Git status command.
- In the same admission stage, apply every other S10l admission requirement
  unchanged:
  - exact HEAD, predecessor identities, ten tracked file identities, and
    seven-modified/three-clean scoped status;
  - `UnityValidationProject/` version `2022.3.47f1`, revision
    `88c277b85d21`;
  - both new S10m artifacts absent, without deletion or overwrite;
  - one passive check showing no matching Unity process;
  - exactly one matching Unity Hub editor registration, without starting Hub;
  - structurally valid repository-local Package manifest and lock contract;
  - exact S10l filter shape and split: `39` distinct methods, Lifecycle/Manager
    `22/17`, Manager declaring classes `10/3/4`.
- Read the exact 39 fully qualified names from the frozen S10l task and use
  them verbatim, joined with `;`, with no additional filter.
- Any admission mismatch is `BLOCKED`. Do not correct, retry, launch Unity, or
  investigate within this task.

## Single Synchronous Unity Invocation

- Continue only after the corrected admission completes successfully.
- Launch exactly one Unity process with `Start-Process -PassThru` and retain
  that exact process object.
- Use the S10l invocation contract unchanged, substituting only the new S10m
  artifact paths:

```text
-batchmode
-projectPath <UnityValidationProject/>
-runTests
-testPlatform EditMode
-testFilter <the exact joined 39-name S10l filter>
-testResults <UnityValidationProject/TestResults-S10m-control-plane.xml>
-logFile <UnityValidationProject/Logs/S10m-control-plane-corrected-editmode.log>
```

- Do not add `-quit`, `-nographics`, another filter/test argument, or a second
  Unity invocation.
- Wait only on the returned process object with `WaitForExit(300000)`, then
  refresh and read its exit code after normal exit.
- Focused Unity L1 batch: `1/1`. Retry: `0/0`. Maximum wait: `300s`.
- Do not poll globally while the process is running. Do not terminate, signal,
  attach to, or detach-control Unity. A timeout is `BLOCKED`; return process
  ownership to the human and do not parse incomplete artifacts.

## Post-Run Evidence

- Continue only after the exact Unity process exits within the limit.
- Parse the S10m XML structurally once and require:
  - root result `Passed`;
  - total/passed `69/69`;
  - failed/skipped/inconclusive `0/0/0`;
  - exactly `39` distinct declared method identities represented;
  - every returned case maps to exactly one declared filter identity.
- Read the S10m log once with bounded extraction. Require:
  - exactly one local `com.rice.ai-codedb` Package record resolving to the
    repository Package;
  - zero `error CS####` records and zero immediate compiler-error summaries;
  - zero fatal/abort/crash markers;
  - normal focused test completion.
- On failure, record only the first bounded sanitized excerpt and stop. Do not
  investigate or search with another pattern.
- Recompute the ten frozen tracked identities and the same scoped status once.
  Perform one final passive matching-Unity process check. Any drift or
  remaining process is `FAIL`; preserve it and do not repair or stop it.

## Result Contract

- Write `RESULT.md` using repository-relative paths only.
- Record:
  - human authorization and the S10l helper failure disposition;
  - corrected concrete-Git selection result without its absolute path;
  - HEAD and all frozen pre/post identities/status;
  - Unity version, sanitized invocation shape, process exit code and wall time;
  - XML totals and exact filter coverage;
  - Package, compiler, fatal-marker, artifact, and final-process conclusions;
  - admission `1/1`, Unity L1 `1/1`, retry `0/0`, wait/output budgets;
  - actual profile and explicit `NOT RUN` / `DEFERRED` boundaries.
- Do not record machine, user-profile, Unity executable, Package, temporary, or
  synthetic absolute paths.
- A passing result is focused development EditMode evidence only. Do not claim
  manual UI, runtime, consumer, release, publication, or Verifier acceptance.

## Prohibited Actions

- Do not modify source, tests, Package/configuration, validation settings,
  workflow, predecessor records, or other tracked inputs.
- Do not create a Unity project or use Unity MCP/Unity Hub to launch the run.
- Do not run a second admission, Unity invocation, retry, alternate filter,
  compiler, L0/L1 harness, broader test, full status/diff, or broad log search.
- Do not delete or overwrite artifacts, stop a process, contact Verifier, or
  dispatch repair work.
- Do not commit, push, stash, reset, clean, rebase, or amend.

## Stop Conditions

- Any frozen identity/status, Package structure, editor registration, filter
  count, fresh-artifact, or no-running-Unity admission requirement differs.
- The helper does not select one valid scalar Git executable or cannot preserve
  the exact NUL-delimited scoped status.
- Unity times out, exits abnormally, produces missing/invalid evidence, fails
  Package/compile/test requirements, does not yield exact `69/69` coverage,
  changes a tracked input, or leaves a matching process.
- Any retry, investigation, source/config edit, process termination, or scope
  expansion would be required.

## Definition Of Done

- Corrected admission completes once without changing the repository snapshot.
- One authorized synchronous Unity process exits normally within `300s`.
- The repository Package resolves and Editor/test compilation has zero errors.
- Exactly `39` methods execute as `69/69` passing cases with no skipped or
  inconclusive result.
- Frozen tracked inputs remain unchanged and no matching Unity process remains.

## Verification

- Only after Planner confirms a stable COMPLETE result, route the exact
  snapshot to `v0.3.verifier.deep` for one GUARDED targeted read-only review.
- Verifier must reuse the S10m artifacts/result and must not rerun Unity or any
  test. Any repair or rerun requires another Planner/user decision.

## Handoff

Current task: cdb-v0.3-p0-s10m-corrected-git-admission-editmode
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.deep
Next action: execute the corrected one-shot admission and, only after it passes,
run the single synchronous focused `39/69` Unity EditMode batch
Human decision or authorization required: Coder dispatch, Verifier routing,
manual Unity acceptance, any further retry/fix, commit, and push remain separate
actions

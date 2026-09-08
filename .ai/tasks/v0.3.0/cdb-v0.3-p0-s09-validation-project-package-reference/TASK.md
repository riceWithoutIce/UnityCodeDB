# Task: cdb-v0.3-p0-s09-validation-project-package-reference

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: v0.3.verifier.standard
- Review mode: GUARDED
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor:
  `cdb-v0.3-p0-s08d-control-plane-code-freeze-l0` (`ACCEPT`; no commit is
  required as an execution prerequisite).
- Requirement source:
  `com.rice.ai-codedb/Documentation~/development-workflow.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  user decision on `2026-09-07` to repair the validation-chain prerequisite
  before affected Unity EditMode validation.

## Objective

- Single outcome: correct the tracked local Package dependency so
  `UnityValidationProject/Packages/` resolves the repository package at
  `com.rice.ai-codedb/package.json` on the next separately authorized Unity
  run.

## Scope

- In scope:
  - In `UnityValidationProject/Packages/manifest.json`, replace only the exact
    `com.rice.ai-codedb` value `file:../com.rice.ai-codedb` with
    `file:../../com.rice.ai-codedb`.
  - Apply the same exact version change to the `com.rice.ai-codedb` entry in
    `UnityValidationProject/Packages/packages-lock.json`.
  - Preserve JSON formatting, dependency versions, ordering, and all unrelated
    fields byte-for-byte.
  - Prove statically that both documents parse, both values match, the path
    resolved from `UnityValidationProject/Packages/` contains `package.json`,
    and that package declares `name = com.rice.ai-codedb`.
- Out of scope:
  - Starting, refreshing, closing, attaching to, or controlling Unity or Unity
    MCP; triggering Package Manager; deleting or regenerating `Library/`,
    `Temp/`, `Logs/`, or any lock/cache state.
  - C# compilation, EditMode, PlayMode, full regression, real lifecycle,
    consumer/third-party Package, Codex Desktop, release, publication, or
    deployment evidence.
  - Changing the Package itself, Test Framework version, Unity version,
    validation Assets/ProjectSettings, workflow, roadmap, or any S08 behavior.
  - Commit, push, stash, reset, clean, rebase, or amend.
- Allowed files:
  - `UnityValidationProject/Packages/manifest.json`
  - `UnityValidationProject/Packages/packages-lock.json`
  - this task's `RESULT.md`
- Protected state:
  - All other tracked and untracked files remain unchanged.
  - Preserve the accepted S08 two-file Package patch exactly:
    - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
    - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - A Unity process currently opening `UnityValidationProject/` is a hard stop.
    Report `BLOCKED` and ask the human to close it; do not stop the process or
    edit either dependency document while it is open.
- Snapshot binding:
  - Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
  - Expected accepted S08 combined patch identity:
    `aae922016172611d6742e7d878cf1d9e6378c617`.
  - Initial `manifest.json` SHA-256:
    `2754e01f91683e7143a88d0fcc41305ee5087cc2ef123e6a81f8404f99486a0f`.
  - Initial `packages-lock.json` SHA-256:
    `1a2deae91f462a0f7c30750ac49f160f64e038610999289495dae013637516a0`.
  - Both validation dependency files were tracked and clean when this task was
    frozen. Any admission drift stops the task; do not repair around it.

## Execution

- Coder actions:
  - Read this task once and perform one bounded admission check for the exact
    HEAD, two initial file hashes, scoped status, and accepted S08 identity.
  - Perform one read-only process check limited to `Unity.exe` instances whose
    command line names the resolved `UnityValidationProject/` path. If one is
    present, stop before editing and return `BLOCKED`; do not inspect unrelated
    processes and do not terminate anything.
  - Use `apply_patch` for the two exact string replacements. Do not serialize
    either complete JSON document through a formatter.
  - Run the following static L0 block once after the edit:

```powershell
$manifest = Get-Content -LiteralPath 'UnityValidationProject/Packages/manifest.json' -Raw | ConvertFrom-Json
$lock = Get-Content -LiteralPath 'UnityValidationProject/Packages/packages-lock.json' -Raw | ConvertFrom-Json
$expected = 'file:../../com.rice.ai-codedb'
if ($manifest.dependencies.'com.rice.ai-codedb' -ne $expected) { throw 'Manifest local Package reference is incorrect.' }
if ($lock.dependencies.'com.rice.ai-codedb'.version -ne $expected) { throw 'Lock-file local Package reference is incorrect.' }
$packagesRoot = (Resolve-Path -LiteralPath 'UnityValidationProject/Packages').Path
$packageRoot = [IO.Path]::GetFullPath((Join-Path $packagesRoot '../../com.rice.ai-codedb'))
$packageJsonPath = Join-Path $packageRoot 'package.json'
if (-not (Test-Path -LiteralPath $packageJsonPath -PathType Leaf)) { throw 'Resolved repository package.json is missing.' }
$package = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
if ($package.name -ne 'com.rice.ai-codedb') { throw 'Resolved repository package identity is incorrect.' }
Write-Output '[OK] Validation project local Package reference is structurally valid.'
```

  - Run one scoped `git diff --check` for the two dependency files. Do not run
    a full diff or repository-wide search.
  - Record final file hashes, exact scoped status, command exit/wall time,
    batch/retry ledger, actual model/effort, deferred boundaries, and the
    completion-routing footer in `RESULT.md`. Leave all changes uncommitted.
- Focused tests:
  - L0: exactly the one static PowerShell validation block above.
  - Affected L1: none in this task; Package resolution and C# compilation are
    intentionally deferred to the separately authorized focused EditMode task.
  - Batch budget: `1/1`; retry budget: `0/0`.
  - Explicitly not run: Unity, Unity MCP, Package Manager, C# compilation,
    EditMode, PlayMode, other L0/L1, full regression, real processes,
    consumer/third-party Package, release, publication, and deployment.
  - Test rationale: the observed failure is an exact relative-path defect in
    two tracked JSON records. Filesystem and structured-JSON evidence can close
    the edit itself; one later Unity run will jointly validate resolution,
    compilation, and focused EditMode without a redundant Editor launch.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - `UnityValidationProject/` is open in Unity at admission.
  - HEAD, initial hashes, S08 identity, or the two-file scoped state has drifted.
  - Correct resolution requires any value other than the two declared exact
    replacements or requires changing another file.
  - Unity, Package Manager, cache deletion, network access, another test batch,
    retry, process termination, or broader inspection appears necessary.
  - The static L0 fails, output is truncated, the workflow command/time budget
    is reached, or the first context compaction occurs.
- Escalation triggers:
  - The repository package identity is not `com.rice.ai-codedb`.
  - Unity still resolves a different location after this static fix; preserve
    that future Unity error for the focused EditMode task instead of changing
    this frozen scope.
- Model escalation: none; the standard profile is sufficient for this exact
  two-record configuration correction.

## Definition Of Done

- Expected result:
  - Both tracked dependency documents contain the exact repository-relative
    reference `file:../../com.rice.ai-codedb` and no other field changes.
  - Static resolution from `UnityValidationProject/Packages/` reaches the
    existing Package with the expected package identity.
- Required evidence:
  - Matching admission identity and exact two-file changed scope.
  - One static L0 PASS with exit status, wall time, output disposition, batch
    `1/1`, and retry `0/0`.
  - One scoped `git diff --check` result and final file hashes.
  - Explicit `NOT RUN` / `DEFERRED` list; do not claim Unity Package resolution
    until the later authorized Unity run observes it.
- Deferred risks:
  - Actual Unity Package Manager resolution, package import, C# compilation,
    and affected EditMode behavior.
  - Fresh full EditMode, cold start, Play/Domain Reload, real runtime/Codex/MCP,
    consumer/third-party Package, and release acceptance.

## Handoff

- Current task: cdb-v0.3-p0-s09-validation-project-package-reference
- Current status: READY
- Next notification: v0.3.coder.standard (manual)
- Next action: after the human closes any Unity Editor using
  `UnityValidationProject/` and explicitly dispatches this task, apply the exact
  two-record correction, run the one static L0 block, and return `RESULT.md` to
  UnityCodeDB v0.3 Planner.
- Human decision or authorization required: close or otherwise release the
  currently open validation project, then manually dispatch Coder. Unity,
  Unity MCP, retry, scope expansion, commit, and push remain separately gated.

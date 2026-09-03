# Task: cdb-v0.3-p0-s02-runtime-contract-routing

## Metadata
- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: UnityCodeDB v0.3 Coder
- Verifier: UnityCodeDB v0.3 Verifier
- Review mode: GUARDED
- Requirement source: `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md` (P0 Package runtime version contract and routing); `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md` (versioned namespace invariants); `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective
- Single outcome: route every project Supervisor entry path in this slice through the Package-declared `control_contract` namespace, while retaining the legacy namespace as read-only diagnostic evidence.

## Scope
- In scope:
  - Reuse `AICodedbPackageRuntimeContract.ControlContract` and `AICodedbControlContract.GetSupervisorRuntimePath` as the only authority; do not add a second contract or generation policy.
  - Update the C# Supervisor launcher and Bridge path, state, pipe, retirement, and empty-bootstrap checks to use the contract-derived namespace.
  - Update `codedb-project-supervisor.mjs` to derive and validate its expected Supervisor runtime from the Package contract, rejecting a fixed or mismatched `--runtime` path.
  - Add or adjust only the focused routing and package-boundary tests needed to prove the new namespace and legacy-path rejection.
- Out of scope:
  - Activation journal/epoch, candidate activation, rollback, retirement mutation, or the `Reinstall CodeDB` execution route.
  - Production integration of the migration classifier into lifecycle state or Manager presentation.
  - PowerShell/materializer policy changes, payload-generation bumps, Provider/query work, or UI redesign.
  - Starting Unity, EditMode/full regression, cold-start/Play acceptance, real Codex acceptance, or third-party Package acceptance.
  - Deleting or quarantining legacy evidence, stopping any external process, or changing global/user configuration.
- Allowed files:
  - `com.rice.ai-codedb/Editor/AICodedbSupervisorLauncher.cs`
  - `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
  - `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
  - `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Protected state:
  - `com.rice.ai-codedb/Editor/AICodedbControlContract.cs` and `com.rice.ai-codedb/Payload~/payload-manifest.json` remain the frozen contract authority for this slice.
  - Project `current-instance.json`, selected immutable generations, legacy `control/supervisor` evidence, external MCP/Codex processes, and user/global configuration are read-only and must remain intact.
- Snapshot binding: current clean worktree at `HEAD 25209d931d449a5002d888ba127dfb7e69584bc0`; a commit is not a prerequisite for implementation or verification.

## Execution
- Coder actions:
  - Read this task once and perform one bounded status/preflight check before editing.
  - Trace the existing Package contract into the C# launcher/Bridge and Node `buildContext`; keep selection paths distinct from Supervisor control paths.
  - Implement the smallest contract-derived routing change and its direct focused regressions.
  - Record changed files, focused evidence, limits, and the completion footer in `RESULT.md`; leave the worktree uncommitted and may only propose a commit.
- Unity/MCP boundary: Coder and Verifier must not create or launch Unity, run a hidden/background Unity validation process, or substitute a direct probe. If Unity MCP is unavailable or fails, stop that evidence path, preserve the original error, notify the human, and record `BLOCKED` or `DEFERRED` without retrying or switching endpoints.
- Focused tests:
  - L0 tests: one focused batch containing the existing `test-codedb-project-supervisor.mjs` routing/contract cases and `test-codedb-package-boundary.ps1` contract/source-boundary checks.
  - Affected L1 tests: at most one focused batch using only the directly affected editor compile/test harness if changed C# signatures require it; do not start Unity.
  - Explicitly not run: full Editor test suites, full repository regression, Unity EditMode, cold-start/Play, real Codex, and third-party Package acceptance.
  - Test rationale: the change crosses the C# launcher/Bridge and Node runtime-path boundary; L0 proves contract derivation and mismatch rejection, while L1 is limited to direct C# consumers.
  - Batch budget: Coder may run at most one L0 batch and one Affected L1 batch; Verifier may run at most one targeted read-only review batch and must not rerun unchanged Coder tests.
  - Keep output within the workflow budgets and do not expand the declared boundary without an authorized task-card exception.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - A required change reaches activation, migration mutation, PowerShell/materializer policy, or Manager/lifecycle state reduction.
  - A live or ambiguous owner would need to be removed, stopped, or rewritten to make a test pass.
  - A command reaches its workflow limit, a second failure occurs after one corrected retry, the declared batch budget would be exceeded, or a new independent blocker appears.
- Escalation triggers:
  - The Package contract is missing/invalid or the namespace cannot be derived without inventing another authority.
  - The same runtime path is accepted by one entry point and rejected by another after the focused correction.
  - Any external process, global configuration, or immutable generation would be touched.

## Definition Of Done
- Expected result:
  - C# launcher/Bridge and Node Supervisor agree on the Package-derived Supervisor namespace and canonical pipe identity.
  - The old fixed namespace is never used for automatic start, connection, retirement, or fallback; it is inspected only by the existing read-only migration diagnostics.
  - Incorrect or legacy `--runtime` input fails closed without project mutation or process termination.
- Required evidence:
  - Focused Node and package-boundary tests pass for the derived namespace and mismatch cases.
  - Any directly affected C# compile/test evidence is recorded with its exact scope.
  - `RESULT.md` records the executed L0/L1 batch counts and any authorized exception.
  - `RESULT.md` contains the changed-file list, evidence, limits, risks, and completion-routing footer.
- Deferred risks:
  - Migration classifier results are not yet wired into lifecycle/Manager state.
  - Activation journal/epoch, explicit Reinstall, real Unity EditMode, and release acceptance remain separate tasks and must not be claimed here.

## Handoff
- Current task: cdb-v0.3-p0-s02-runtime-contract-routing
- Current status: READY
- Next notification: UnityCodeDB v0.3 Coder (manual)
- Next action: human-notify the Coder with this frozen `TASK.md`; execute only this routing slice and write `RESULT.md` without committing.
- Human decision or authorization required: confirm manual dispatch; any EditMode run, commit, push, or release acceptance requires a separate explicit authorization.

# Task: cdb-v0.3-p0-s10-control-plane-focused-editmode

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_FOR_AUTHORIZATION
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep
- Review mode: GUARDED
- Complexity: High
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessors:
  - `cdb-v0.3-p0-s08d-control-plane-code-freeze-l0` (`ACCEPT`)
  - `cdb-v0.3-p0-s09-validation-project-package-reference` (`ACCEPT`)
  - `cdb-v0.3-p0-s09a-validation-project-tagmanager-repair` (`ACCEPT`)
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Produce one fresh Unity 2022.3 EditMode evidence set for the directly affected
  S02-S07 control-plane C# tests on the accepted current snapshot.
- The same single Unity invocation must also prove that
  `UnityValidationProject/` resolves the repository Package, compiles the
  Package Editor and test assemblies, and executes exactly the frozen focused
  filter.

## Scope

- Validation project: `UnityValidationProject/` only.
- Evidence-only task: production, tests, Package configuration, validation
  project configuration, workflow, and prior task records are read only.
- Allowed durable file:
  - this task's `RESULT.md`
- Allowed ignored evidence artifacts:
  - `UnityValidationProject/TestResults-S10-control-plane.xml`
  - `UnityValidationProject/Logs/S10-control-plane-focused-editmode.log`
- This task does not implement or repair anything. The first compile, Package,
  filter, test, timeout, output, or project-drift failure ends the task and is
  returned to Planner without investigation or retry.

## Frozen Snapshot

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Accepted S08 combined patch identity:
  `aae922016172611d6742e7d878cf1d9e6378c617`.
- Expected relevant file SHA-256 values:

| File | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `064477ab5068532e175faaf2e6a73e9349c5bd5f5c1fd3b465356ed99395892b` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `9d6b1c13e35562162b34d1e59c1d36bf28b7e1df7113793029a6e6dbc026898d` |
| `UnityValidationProject/Packages/manifest.json` | `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd` |
| `UnityValidationProject/Packages/packages-lock.json` | `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913` |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | `8e18b1c820e9c09e16bbd1f1b7842e9fb3b0158a0921b0964e0b8fa12c6e2c01` |

- Expected scoped modified files are only the accepted S08 two-file patch, the
  accepted S09 two Package records, and the accepted S09a TagManager repair.
  The two C# test files and all Package Editor source files must be clean.
- A commit is not an execution prerequisite. Do not reset, clean, stash,
  rebase, amend, commit, or push this snapshot.

## Focused Test Filter

- Assembly: `Rice.AICodedb.Editor.Tests`.
- Filter derivation: test methods intersecting the two Editor test-file changes
  from the S02 baseline `25209d931d449a5002d888ba127dfb7e69584bc0` through
  the frozen HEAD, excluding the file-tail helper-only change.
- Frozen size: 39 methods and 69 NUnit cases.
- Do not substitute either complete test class, the complete assembly, or all
  EditMode tests.

```text
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_ReinstallSerializesOnlyExplicitMutationConfirmation
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_UsesCanonicalPipeIdentityAndRecognizesExactV1Handoff
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_StatusHandshakeBlocksWrongProjectIdentity
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_ReadyWithoutProviderHandshakeIsBlocked
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_RunningOperationCannotReportReady
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_LegacyCommandModelCannotMasqueradeAsCurrent
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_LegacyHandoffWaitsForAdmittedMaintenance
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorBridge_BootstrapFallbackRequiresReviewedMaterializerCommandAndEmptyRuntime
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorLauncher_UsesProjectControlSupervisorRuntime
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorLauncher_ValidatesExternalPackageAgainstItsOwnRoot
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_ConsecutiveScheduledTicksStayQuiescentButExplicitTriggerReadmits
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_ScheduledSuppressionDoesNotAffectOtherNeedsAttentionRecovery
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_UsableStatesPreserveAutomaticConvergenceWithoutAdmissionDryRun
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_ColdStartMissingPrerequisiteTakesPriorityWithoutReinstall
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_ExplicitCurrentPrerequisiteMapsBlockedState
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_UntrustworthyPrerequisiteEvidenceFailsClosedWithoutReinstall
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_UninstalledKeepsInstallSemanticsWithoutAdmissionDryRun
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_InvalidIntegrationKeepsExistingAttentionWithoutAdmissionDryRun
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.LifecycleSource_NeverIssuesAutomaticReinstall
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ReadyCurrentInstance_WithPendingCleanup_SelectsThrottledRetirementOnly
Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.MissingOrUnavailableCurrentInstance_StillRunsFullConvergence
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ManagerSource_DoesNotOwnMigrationClassificationOrAdmissionDryRun
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ActionsSource_RechecksCurrentReinstallEvidenceOnAWorker
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ResolvePrimaryAction_ExposesOnlyOneContextualUserAction
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.Build_MissingPrerequisitePreservesOneGuidanceAndNoFixAction
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.MissingProviderPrerequisite_OffersOnlyConfigureDependenciesAction
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.VerifiedProvider_KeepsSecondaryConfigureDependenciesActionAvailable
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ReadyProvider_DoesNotKeepConfigureDependenciesOnOverview
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.GenericNeedsAttentionDescription_HidesInternalsAndDoesNotPrescribeReinstall
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.CachedMigrationStatus_ControlsReinstallAndPreservesDiagnostics
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.UninstalledState_KeepsInstallAsTheOnlyProjectAction
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.BuildScriptArguments_HaveNoVersionControlOrAuthorizationArguments
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.BuildScriptArguments_ProjectMutationsRequireConfirmation
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.BuildScriptArguments_ProjectIntegrationActionsUseExactConfirmedContract
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ReinstallCodeDB_CancelDoesNotInvokeRecoveryAction
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ReinstallCodeDB_ConfirmationRunsExactlyOnePackageOwnedRecoveryAction
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ReinstallCodeDB_AdmissionRequiresExactCachedAndCurrentEvidence
Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests.ReinstallCodeDB_OneConfirmedCommandRequestsOneReconcileOnlyAfterSuccess
```

## Authorization Request

- EditMode authorization: NOT_REQUESTED.
- Creating this task card and later dispatching it do not authorize Unity.
- Before dispatch, the human must close every Unity Editor using
  `UnityValidationProject/` and explicitly authorize the following one-shot
  acceptance request:

```text
Project path: UnityValidationProject/
Purpose and criterion: resolve the repository Package, compile its Editor/test
  assemblies without errors, and pass exactly 69/69 frozen focused EditMode
  cases with no skip or inconclusive result.
Exact command and test filter: the single foreground command and exact 39-name
  semicolon filter declared in Execution below.
Evidence class: fresh development Unity EditMode evidence; not consumer,
  released-artifact, real Codex/MCP, runtime lifecycle, or release evidence.
Expected duration / maximum wait: approximately 60-180 seconds / 300 seconds.
Cleanup and ownership handoff: the authorized command owns only the Unity
  process it starts and expects normal self-exit; on timeout it must not kill
  Unity, and process disposition returns to the human.
```

## Execution

- Before starting Unity, Coder performs one bounded admission check for the
  exact HEAD, seven file hashes, relevant scoped status, Unity project version,
  and absence of a Unity process whose command line names the resolved
  validation project. Any mismatch returns `BLOCKED`; do not repair it.
- Resolve the Unity executable for the exact version in
  `UnityValidationProject/ProjectSettings/ProjectVersion.txt` from the current
  user's Unity Hub `editors-v2.json`. Require exactly one matching registered
  editor and an existing executable. Do not record its machine path in
  `RESULT.md`.
- Require both ignored evidence artifact paths to be absent before the run. Do
  not delete or overwrite an earlier artifact; report `BLOCKED` instead.
- Build `$testFilter` by copying the 39 lines above into an array and joining
  them with `;`. Assert array count `39`, distinct count `39`, and the expected
  Lifecycle/Manager split `22/17` before launch.
- Invoke Unity once, synchronously in the foreground. Do not use a background
  job, detached process, scheduled task, hidden window, Unity MCP, or another
  endpoint. The native invocation is exactly:

```powershell
& $unityEditor `
  -batchmode `
  -projectPath $projectPath `
  -runTests `
  -testPlatform EditMode `
  -testFilter $testFilter `
  -testResults $testResultsPath `
  -logFile $logPath
```

- Do not add `-quit`, `-nographics`, another test argument, or a second Unity
  invocation. Do not start Package Manager, Unity Hub, or Unity MCP separately.
- Focused batch budget: `1/1`. Retry budget: `0/0`.
- Maximum wait: `300 seconds`. If Unity is still running at that boundary, stop
  waiting, record `TIMEOUT`, do not terminate or signal it, and hand process
  ownership to the human. Do not run post-timeout checks that require Unity to
  have exited.
- Per-command captured output limit: `16 KiB`; task aggregate `64 KiB`. Keep
  raw Unity output in the ignored log and copy only bounded error excerpts into
  `RESULT.md`.
- After normal process exit, parse the NUnit XML structurally. Require:
  - root result `Passed`;
  - exactly `69` total test cases and `69` passed;
  - `0` failed, `0` skipped, and `0` inconclusive;
  - every returned method belongs to the declared 39-name filter.
- Confirm from the bounded Unity log that `com.rice.ai-codedb` resolved to the
  repository Package and no C# compiler error occurred. Record only the
  sanitized conclusion or the first relevant error; do not copy machine paths
  or broad logs into the report.
- Recompute the seven hashes and the same relevant scoped status once after a
  normal exit. Unity may write only ignored generated/evidence state. Any
  tracked input drift is `FAIL`; preserve it and do not revert it.
- Write `RESULT.md` with authorization reference, resolved Unity version,
  pre/post identity, exact command disposition, exit status, wall time,
  XML counts, Package/compile conclusion, batch/retry/output ledger, process
  cleanup state, actual profile, and all deferred boundaries.

## Test Boundary

- L0 tests: none; accepted S08d L0 evidence is reused without rerun.
- Affected L1: exactly one Unity EditMode batch using the frozen 39-method,
  69-case filter.
- Explicitly not run: either full test class, full Editor test assembly, fresh
  full EditMode, PlayMode, cold start, Play/Domain Reload transitions, real
  Manager/Supervisor/PowerShell/Node processes, Unity MCP, Codex client,
  consumer/third-party Package, release, publication, and deployment.
- Test rationale: these are the test methods directly intersecting the S02-S07
  C# control-plane changes. S08 behavior already has accepted non-Unity L0 and
  introduced no C# test change; broader Unity coverage belongs to later,
  separately authorized acceptance tasks.

## Stop Conditions

- Explicit Unity/EditMode authorization is absent.
- The validation project is open in any Unity process at admission.
- Frozen identity, hash, scoped status, project version, editor registration,
  filter count, or evidence-artifact precondition differs.
- Unity MCP or an alternate endpoint appears necessary.
- The one Unity invocation fails, exceeds `300 seconds`, produces truncated
  evidence, does not create a valid XML result, runs a different case count, or
  leaves tracked input drift.
- Any source/config/test edit, retry, failure investigation, full-class/full-
  assembly filter, second Unity start, process termination, or broader test is
  proposed.

## Verification

- After Planner confirms a stable `RESULT.md`, route the exact snapshot to
  `v0.3.verifier.deep` for one GUARDED targeted read-only review.
- Verifier reuses the Coder Unity/XML/log evidence and does not rerun Unity,
  EditMode, compilation, or any other test.
- Verifier may create only this task's `verifications/VERIFICATION-01.md` and
  reports findings once. A repair requires a new Planner/user decision.

## Definition Of Done

- The single authorized Unity invocation exits normally within `300 seconds`.
- The repository Package is actually resolved by the validation project, its
  Editor/test assemblies compile, and exactly `69/69` declared cases pass with
  zero failure, skip, or inconclusive result.
- Pre/post frozen inputs match and Unity changes no tracked input.
- Result boundaries remain development-focused; no runtime, consumer, full-
  regression, release, or publication claim is made.

## Handoff

Current task: cdb-v0.3-p0-s10-control-plane-focused-editmode
Current status: READY_FOR_AUTHORIZATION
Next notification: Human / UnityCodeDB v0.3 Planner
Next action: close the currently open validation project, explicitly authorize
the one-shot Unity/EditMode request, then route the frozen task to
`v0.3.coder.deep`
Human decision or authorization required: Unity/EditMode execution and Coder
dispatch; Verifier routing, any retry/fix, full EditMode, commit, and push remain
separately gated

# Task: cdb-v0.3-p0-s10l-corrected-focused-editmode-rerun

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep after Planner routing, if the result is stable
- Review mode: GUARDED
- Complexity: High
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10k-supervisor-schema-expectation-evidence`
  (`ACCEPT`; static proof closed the stale schema expectation and the prior
  S10f run's only test failure).
- Human authorization: on 2026-09-07 the user accepted S10k and authorized the
  next fresh corrected Unity/EditMode task.

## Objective

- Run one fresh Unity 2022.3 EditMode evidence batch on the current corrected
  snapshot.
- Execute exactly the affected `39` methods / `69` NUnit cases, including the
  corrected `SupervisorSchemaVersion == 3` expectation.
- Prove repository-local Package resolution, clean Editor/test compilation,
  complete test coverage, and normal process exit using bounded structured
  evidence.
- This task is development validation only; it is not manual UI, runtime,
  consumer, release, or publication acceptance.

## Scope

- Validation project: `UnityValidationProject/` only.
- Source, tests, Package files, validation settings, workflow, and earlier task
  records are read only.
- Allowed durable output:
  - this task's `RESULT.md`
- Allowed ignored run artifacts:
  - `UnityValidationProject/TestResults-S10l-control-plane.xml`
  - `UnityValidationProject/Logs/S10l-control-plane-corrected-editmode.log`
- Do not create a Unity project or alter project configuration.
- One admission, one Unity invocation, and one bounded post-run extraction form
  a single batch. The first failure ends the task; no retry or investigation is
  allowed here.

## Frozen Snapshot

- Expected HEAD:
  `6408b0d540b32584147588efb67ecc5ba12b2fda`
- Required tracked inputs:

| Repository-relative file | Bytes | SHA-256 |
| --- | ---: | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `249662` | `cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `733447` | `ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `183864` | `ce5784f90d4cdc18ffe4668329924557f909dc5a9280276d44907240d93d691b` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `156471` | `9d6b1c13e35562162b34d1e59c1d36bf28b7e1df7113793029a6e6dbc026898d` |
| `com.rice.ai-codedb/package.json` | `723` | `4932ecb76b699ae3d917d4fbbde9513691bc8b62f2a0f1e39bf4b3bf70d31957` |
| `UnityValidationProject/Packages/manifest.json` | `308` | `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd` |
| `UnityValidationProject/Packages/packages-lock.json` | `1377` | `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913` |
| `UnityValidationProject/ProjectSettings/ProjectVersion.txt` | `85` | `f450bbe4b5dc999988f56dff01af912886a765726ca3240d157357cff10517bf` |
| `UnityValidationProject/ProjectSettings/ProjectSettings.asset` | `23135` | `9b1debf0b71ede99cbef5291d8aa9f5f3dac0a68c519ef60e2d70cf1638015e7` |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | `378` | `8e18b1c820e9c09e16bbd1f1b7842e9fb3b0158a0921b0964e0b8fa12c6e2c01` |

- S10k task identity:
  - bytes: `8360`;
  - SHA-256:
    `acc30748b64ee4e9c220bcd71fd9f3a54e0d11927b7b2f99d2d75160013c6776`.
- S10k result identity:
  - bytes: `4093`;
  - SHA-256:
    `c6fa0288169467b069282acaf1d98808b09d720a13e36eb469ef08a734ff7e6d`.
- Expected relevant scoped status is the existing seven modified paths shown by
  the preceding task: the two accepted runtime/fixture files, lifecycle test,
  two Package records, ProjectSettings serialization state, and TagManager.
  The Manager test, Package JSON, and ProjectVersion remain clean in scope.
- Preserve all unrelated modified and untracked paths. A commit is not an
  execution prerequisite.

## Corrected Focused Filter

- Assembly: `Rice.AICodedb.Editor.Tests`.
- Required split: Lifecycle `22 methods / 26 cases`; Manager declaring classes
  `17 methods / 43 cases`; combined `39 methods / 69 cases`.
- Manager declaring-class split: `AICodedbProductStatusTests 10`,
  `AICodedbHostPayloadMaterializerTests 3`,
  `AICodedbLifecycleControlTests 4`.
- `AICodedbManagerUiTests` is a filename stem, not a declaring type.
- Use exactly these 39 fully qualified method identities, joined with `;` and
  with no extra filter:

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
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.ManagerSource_DoesNotOwnMigrationClassificationOrAdmissionDryRun
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.ActionsSource_RechecksCurrentReinstallEvidenceOnAWorker
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.ResolvePrimaryAction_ExposesOnlyOneContextualUserAction
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.Build_MissingPrerequisitePreservesOneGuidanceAndNoFixAction
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.MissingProviderPrerequisite_OffersOnlyConfigureDependenciesAction
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.VerifiedProvider_KeepsSecondaryConfigureDependenciesActionAvailable
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.ReadyProvider_DoesNotKeepConfigureDependenciesOnOverview
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.GenericNeedsAttentionDescription_HidesInternalsAndDoesNotPrescribeReinstall
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.CachedMigrationStatus_ControlsReinstallAndPreservesDiagnostics
Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.UninstalledState_KeepsInstallAsTheOnlyProjectAction
Rice.AI.Codedb.Editor.Tests.AICodedbHostPayloadMaterializerTests.BuildScriptArguments_HaveNoVersionControlOrAuthorizationArguments
Rice.AI.Codedb.Editor.Tests.AICodedbHostPayloadMaterializerTests.BuildScriptArguments_ProjectMutationsRequireConfirmation
Rice.AI.Codedb.Editor.Tests.AICodedbHostPayloadMaterializerTests.BuildScriptArguments_ProjectIntegrationActionsUseExactConfirmedContract
Rice.AI.Codedb.Editor.Tests.AICodedbLifecycleControlTests.ReinstallCodeDB_CancelDoesNotInvokeRecoveryAction
Rice.AI.Codedb.Editor.Tests.AICodedbLifecycleControlTests.ReinstallCodeDB_ConfirmationRunsExactlyOnePackageOwnedRecoveryAction
Rice.AI.Codedb.Editor.Tests.AICodedbLifecycleControlTests.ReinstallCodeDB_AdmissionRequiresExactCachedAndCurrentEvidence
Rice.AI.Codedb.Editor.Tests.AICodedbLifecycleControlTests.ReinstallCodeDB_OneConfirmedCommandRequestsOneReconcileOnlyAfterSuccess
```

## Admission

- Read this task once and execute one bounded admission stage.
- Require exact HEAD, all ten tracked file identities, and both S10k task/result
  identities.
- Query only the ten tracked paths with NUL-delimited porcelain v1; preserve
  the two-character status code and compare normalized unordered path sets.
  Require exactly seven ` M` paths and three clean paths as described above.
- Require ProjectVersion `2022.3.47f1` with revision `88c277b85d21`.
- Require both fresh S10l artifact paths to be absent. Do not delete or
  overwrite an existing artifact.
- Perform one point-in-time passive process check; require zero `Unity.exe`
  processes whose command line resolves to `UnityValidationProject/`.
- Resolve the exact editor version from the current user's Unity Hub
  `editors-v2.json`; require exactly one registered matching editor and an
  existing executable. Do not start Hub or persist its machine path.
- Parse `manifest.json` and `packages-lock.json` structurally and require:
  - dependency and lock version exactly `file:../../com.rice.ai-codedb`;
  - `testables` contains `com.rice.ai-codedb` once;
  - lock source `local`, depth integer `0`, and zero dependency properties;
  - resolving the file reference from `Packages/` equals the repository Package
    directory.
- Build the filter from the block above and require `39` total/distinct names,
  Lifecycle/Manager `22/17`, and Manager class split `10/3/4`.
- Any mismatch returns `BLOCKED` without launching Unity.

## Single Synchronous Unity Invocation

- Launch exactly once with `Start-Process -PassThru`, retaining the returned
  process object. Do not use a background job, detached process, scheduled
  task, Unity MCP, Unity Hub, or `-Wait`.
- Wait only on that exact object with a `300000ms` limit:

```powershell
$unityProcess = Start-Process -FilePath $unityEditor `
  -ArgumentList $quotedArguments `
  -PassThru
$completed = $unityProcess.WaitForExit(300000)
if ($completed) {
    $unityProcess.WaitForExit()
    $unityProcess.Refresh()
    $unityExitCode = $unityProcess.ExitCode
}
```

- Arguments must be exactly:

```text
-batchmode
-projectPath <UnityValidationProject/>
-runTests
-testPlatform EditMode
-testFilter <the exact joined 39-name filter>
-testResults <UnityValidationProject/TestResults-S10l-control-plane.xml>
-logFile <UnityValidationProject/Logs/S10l-control-plane-corrected-editmode.log>
```

- Do not add `-quit`, `-nographics`, another test/filter argument, or a second
  Unity invocation. Do not terminate or signal Unity on timeout.
- Focused L1 batch: `1/1`. Retry: `0/0`. Expected duration: `60-180s`;
  maximum wait: `300s`.
- On timeout record `TIMEOUT`/`BLOCKED`, return process ownership to the human,
  and do not parse incomplete artifacts or run post-exit checks.

## Post-Run Evidence

- Continue only after normal exit within the limit. Parse the XML structurally
  exactly once and require:
  - root result `Passed`;
  - total `69`, passed `69`, failed/skipped/inconclusive `0`;
  - exactly `39` distinct declared method identities, all represented;
  - every returned case maps to exactly one declared filter identity.
- Read the Unity log exactly once for Package resolution, compiler errors,
  fatal/abort/crash markers, and test completion. Require exactly one local
  Package record with source and location resolving to the repository Package
  directory. Never persist absolute captured paths.
- Require zero `error CS####` entries and zero immediate compiler-error
  summaries. On failure record only the first bounded sanitized excerpt.
- Recompute all ten frozen tracked identities and the same scoped status once;
  any tracked input drift is `FAIL` and must be preserved without repair.
- Perform one final point-in-time matching-Unity process check; require zero
  and do not stop a remaining process.
- Do not perform a broad log read, full status/diff, second pattern, or retry.

## Result Contract

- Write this task's `RESULT.md` with authorization, Unity version, sanitized
  invocation shape, exit code/wall time, XML counts/filter coverage,
  Package/compile/fatal conclusions, pre/post identities/status, process
  disposition, `1/1` and `0/0` ledgers, output limits, actual profile, and
  explicit `NOT RUN`/`DEFERRED` boundaries.
- Use repository-relative paths only. Do not record machine, user-profile,
  executable, temporary, or Package absolute paths.
- Do not claim manual Unity acceptance, runtime/consumer/release acceptance, or
  Verifier approval.

## Prohibited Actions

- Do not modify source, tests, configuration, prior records, or tracked inputs.
- Do not create a project or use Unity MCP/Hub to launch the run.
- Do not run another Unity invocation, test, compiler, L0/L1 harness, retry, or
  broader filter.
- Do not kill, signal, attach to, or detach-control Unity.
- Do not use full diff/status, broad logs/search, or investigate a failure.
- Do not commit, push, stash, reset, clean, rebase, amend, or contact Verifier.

## Stop Conditions

- Human authorization, frozen identity, scoped status, Package structure,
  editor registration, filter counts, artifact absence, or no-running-Unity
  admission differs.
- Unity does not exit normally within `300s`, artifacts are invalid/missing,
  Package origin or compile evidence fails, XML is not exactly `69/69`, a
  filter is omitted/extra, tracked inputs drift, or a matching process remains.
- Any retry, second invocation, source/config edit, process termination,
  investigation, or broader test would be required.

## Definition Of Done

- One authorized synchronous Unity process exits normally within `300s`.
- Repository Package resolves and Editor/test assemblies compile without errors.
- Exactly `39` methods execute as `69/69` passing cases with no skip or
  inconclusive result.
- Frozen tracked inputs remain unchanged and no matching Unity process remains.
- Evidence remains limited to development EditMode validation.

## Verification

- After Planner confirms a stable result, route this exact snapshot to
  `v0.3.verifier.deep` for one GUARDED targeted read-only review.
- Verifier reuses the XML/log/result evidence and does not rerun Unity or any
  test. Any repair or rerun requires a new Planner/user decision.

## Handoff

Current task: cdb-v0.3-p0-s10l-corrected-focused-editmode-rerun
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.deep
Next action: execute the one authorized synchronous corrected `39/69` EditMode run and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: Verifier routing, manual Unity acceptance, any retry/fix, commit, or push remains separately gated

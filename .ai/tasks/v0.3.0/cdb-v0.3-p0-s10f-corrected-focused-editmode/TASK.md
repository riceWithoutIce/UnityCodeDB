# Task: cdb-v0.3-p0-s10f-corrected-focused-editmode

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep after Planner review and explicit routing
- Review mode: GUARDED
- Complexity: High
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessors:
  - `cdb-v0.3-p0-s10-control-plane-focused-editmode` (first Unity evidence;
    incomplete filter and four test-only failures)
  - `cdb-v0.3-p0-s10b-editmode-evidence-extraction` (corrected declarations,
    `39 methods / 69 cases`, and four test-only failure classification)
  - `cdb-v0.3-p0-s10c-editmode-test-fixture-fix` (test patch preserved despite
    a malformed static command)
  - `cdb-v0.3-p0-s10e-test-fix-static-evidence-recapture` (`COMPLETE`)
- Human authorization: on 2026-09-07 the user accepted S10e and explicitly
  authorized this one-shot corrected Unity/EditMode execution.

## Objective

- Produce one fresh Unity 2022.3 EditMode evidence set for exactly the affected
  S02-S07 control-plane tests on the current frozen snapshot.
- Use the corrected declaring classes so all `39` intended methods and `69`
  NUnit cases execute.
- Wait synchronously on the exact Unity process object, rather than treating a
  GUI launcher return as process completion.
- Establish repository-local Package resolution with structured manifest/lock
  checks plus the exact Package-resolution record from this run.

## Scope

- Validation project: `UnityValidationProject/` only.
- This is an evidence-only execution task. All source, tests, Package and
  validation-project configuration, workflow files, and prior task records are
  read only.
- Allowed durable output:
  - this task's `RESULT.md`
- Allowed ignored run artifacts:
  - `UnityValidationProject/TestResults-S10f-control-plane.xml`
  - `UnityValidationProject/Logs/S10f-control-plane-corrected-editmode.log`
- Do not create a Unity project. Do not open or use Unity Hub interactively.
- The first admission, launch, timeout, compile, Package, filter, test,
  post-identity, or process-cleanup failure ends the task without retry or
  investigation.

## Frozen Snapshot

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Required file identities:

| Repository-relative file | Bytes | SHA-256 |
| --- | ---: | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `249662` | `cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `733447` | `ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `183864` | `8048a39235dc115465cf972441135e328de81a6af3a96b126ce0f8f81b8c411f` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `156471` | `9d6b1c13e35562162b34d1e59c1d36bf28b7e1df7113793029a6e6dbc026898d` |
| `com.rice.ai-codedb/package.json` | `723` | `4932ecb76b699ae3d917d4fbbde9513691bc8b62f2a0f1e39bf4b3bf70d31957` |
| `UnityValidationProject/Packages/manifest.json` | `308` | `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd` |
| `UnityValidationProject/Packages/packages-lock.json` | `1377` | `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913` |
| `UnityValidationProject/ProjectSettings/ProjectVersion.txt` | `85` | `f450bbe4b5dc999988f56dff01af912886a765726ca3240d157357cff10517bf` |
| `UnityValidationProject/ProjectSettings/ProjectSettings.asset` | `23135` | `9b1debf0b71ede99cbef5291d8aa9f5f3dac0a68c519ef60e2d70cf1638015e7` |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | `378` | `8e18b1c820e9c09e16bbd1f1b7842e9fb3b0158a0921b0964e0b8fa12c6e2c01` |

- `ProjectSettings.asset` has pre-existing serialization-only whitespace drift.
  It is protected input, not an accepted S10f change; its hash must remain
  identical before and after this run.
- S10e `RESULT.md` is the static acceptance input:
  - bytes: `4019`;
  - SHA-256:
    `b930d672dd02237ce452491e0f976af72fc4a02a8bb63ca232f17a7bb7f7c8ec`.
- Expected relevant scoped state includes the existing changes only. In the
  declared scope, Package Editor source and `AICodedbManagerUiTests.cs` remain
  clean; the lifecycle test and listed runtime/fixture/validation-project
  records retain their exact current statuses and identities.
- Preserve every unrelated modified and untracked path. A commit is not an
  execution prerequisite.

## Corrected Focused Filter

- Assembly: `Rice.AICodedb.Editor.Tests`.
- Expected split:
  - `AICodedbEditorLifecycleTests`: `22 methods / 26 cases`;
  - Manager-source declaring classes: `17 methods / 43 cases`;
  - combined: `39 methods / 69 cases`.
- `AICodedbManagerUiTests` is a filename, not a declaring type. Do not use it
  as a class name.
- Copy these exact lines into an array and join them with `;`:

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

- Read this task once. Perform one bounded admission stage only.
- Require:
  - exact HEAD, S10e result identity, and all ten frozen file identities;
  - the expected relevant scoped status, without a full repository status or
    diff;
  - project version exactly `2022.3.47f1` with revision
    `88c277b85d21`;
  - both fresh S10f evidence paths absent; do not delete or overwrite evidence;
  - zero `Unity.exe` processes whose command line resolves to
    `UnityValidationProject/`.
- The Unity-process admission is one point-in-time read, not polling. Do not
  stop, signal, attach to, or otherwise control an existing process.
- Resolve the exact editor version from the current user's Unity Hub
  `editors-v2.json`. Require exactly one registered matching editor and an
  existing `Unity.exe`; do not start Hub and do not record machine paths.
- Parse `manifest.json` and `packages-lock.json` as JSON and require:
  - manifest dependency and lock version both equal
    `file:../../com.rice.ai-codedb`;
  - manifest `testables` contains `com.rice.ai-codedb` exactly once;
  - lock entry has `source: local`, `depth: 0`, and no dependencies;
  - resolving the manifest's file reference relative to the `Packages/`
    directory equals the repository Package directory.
- Build the exact filter and require count `39`, distinct count `39`, split
  `22/17`, and corrected declaring-class split `10/3/4` before launch.
- Any mismatch returns `BLOCKED`; do not repair, retry, or start Unity.

## Single Synchronous Unity Invocation

- Launch Unity exactly once through `Start-Process -PassThru`. Do not pass
  `-Wait`; wait through the returned exact process object so a `300000ms`
  timeout can be enforced.
- Do not pass `-WindowStyle Hidden`, use a background job, detached helper,
  scheduled task, Unity MCP, Unity Hub, or another endpoint.
- Arguments are exactly:

```text
-batchmode
-projectPath <resolved UnityValidationProject/>
-runTests
-testPlatform EditMode
-testFilter <the exact joined 39-name filter>
-testResults <resolved fresh S10f XML path>
-logFile <resolved fresh S10f log path>
```

- Do not add `-quit`, `-nographics`, another test/filter argument, or a second
  Unity invocation.
- The synchronous control shape is:

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

- Quote native path/filter arguments without logging their resolved machine
  values. Record only the repository-relative command shape in `RESULT.md`.
- Focused L1 batch: `1/1`. Retry: `0/0`.
- Expected duration: approximately `60-180 seconds`. Maximum wait: `300
  seconds`.
- On timeout:
  - stop waiting and record `TIMEOUT` / `BLOCKED`;
  - do not terminate, signal, stop, or detach-control the Unity process;
  - record that process ownership has returned to the human;
  - do not parse possibly incomplete artifacts or run post-exit checks.

## Bounded Post-Run Evidence

- Perform this stage only after the exact process exits normally within the
  limit. Evidence extraction is part of the same one-shot batch, not a retry.
- Record the exact process exit code and wall time.
- Parse the NUnit XML structurally once. Require:
  - root result `Passed`;
  - exactly `69` total cases and `69` passed;
  - `0` failed, `0` skipped, and `0` inconclusive;
  - exactly `39` distinct declared method identities represented;
  - each case name equals a filter identity or begins with that identity plus
    its parameterized-case suffix;
  - each filter identity appears at least once.
- Read the Unity log once for only Package-resolution, compiler-error, test
  completion, and immediate fatal-error evidence.
- For repository Package proof, require exactly one line matching the current
  run's Package record shape:

```text
com.rice.ai-codedb@file:<resolved-source> (location: <resolved-location>)
```

- Extract both path fields in memory, normalize them, and require each to equal
  the repository Package directory already established from manifest/lock.
  Do not copy either absolute value into `RESULT.md`.
- Require zero `error CS####` entries and zero immediate Unity compiler-error
  summary markers. On failure, record only the first bounded relevant error.
- Perform one post-run frozen identity/scoped-status check identical to
  Admission. Any tracked input drift is `FAIL`; preserve it and do not revert.
- Perform one point-in-time post-run check for a Unity process whose command
  line resolves to the validation project. Require zero; do not stop or signal
  a process if one remains.
- Do not use a broad log read, full status/diff, or secondary evidence pattern.

## Result Contract

- Write `RESULT.md` with:
  - the human authorization reference;
  - Unity version, sanitized invocation shape, exit code, and wall time;
  - exact XML counts and method/filter coverage;
  - structured manifest/lock and runtime Package-resolution conclusions;
  - compile conclusion;
  - pre/post frozen identity and scoped-state disposition;
  - process cleanup/ownership disposition;
  - `1/1` batch and `0/0` retry ledger, captured-output budget, and actual
    execution profile;
  - explicit `NOT RUN` / `DEFERRED` boundaries and standard routing footer.
- Use repository-relative paths only. Do not record an absolute machine,
  repository, Unity executable, user-profile, temporary, or Package location.
- Captured output: `16 KiB` per command and `64 KiB` aggregate. Normal
  non-Unity command maximum: `60 seconds`.

## Test Boundary

- Reused static/L0 evidence: S08d and S10e; do not rerun either.
- Affected L1: exactly one Unity EditMode batch using this `39-method / 69-case`
  filter.
- Explicitly not run: full test classes, full Editor assembly, full EditMode,
  PlayMode, cold start, Play/Domain Reload transitions, real Manager,
  Supervisor, PowerShell, Node or Codex processes, Unity MCP, consumer or
  third-party Package projects, release, publication, and deployment.
- This is development validation evidence only. It is not final manual UX,
  consumer, runtime lifecycle, released-artifact, or release acceptance.

## Prohibited Actions

- Do not modify source, tests, configuration, prior records, or frozen tracked
  inputs.
- Do not create a project or launch Unity through Unity MCP/Hub.
- Do not run another test, invocation, filter, compile command, L0/L1 harness,
  or retry.
- Do not kill or signal Unity, even on timeout or failure.
- Do not use full diff/status, broad logs/search, or investigate a failure.
- Do not commit, push, stash, reset, clean, rebase, amend, contact Verifier, or
  dispatch any repair.

## Stop Conditions

- Human authorization is absent or contradicted.
- Frozen admission, Package structure, Unity registration, filter count, fresh
  artifact, or no-running-Unity prerequisite differs.
- The exact Unity process does not exit within `300 seconds`.
- Unity exits abnormally, evidence is missing/invalid/truncated, Package origin
  is not exact, compile evidence fails, XML is not exactly `69/69`, a filter is
  omitted/extra, tracked input drifts, or a matching Unity process remains.
- A retry, second pattern, source/config edit, process termination,
  investigation, or broader test would be required.

## Definition Of Done

- One authorized Unity process exits normally within `300 seconds`.
- The validation project structurally and at runtime resolves the repository
  Package and compiles its Editor/test assemblies without errors.
- All exact `39` methods execute as `69/69` passing cases, with zero failed,
  skipped, or inconclusive cases.
- All frozen tracked inputs and relevant scoped state remain unchanged, and no
  matching Unity process remains.
- Evidence remains narrowly classified as development EditMode evidence.

## Verification

- After Planner confirms a stable `RESULT.md`, Planner may route the exact
  snapshot to `v0.3.verifier.deep` for one GUARDED targeted read-only review.
- Verifier must reuse the Coder XML/log/result evidence and must not rerun Unity
  or any test. Any repair or rerun requires a new user decision.

## Handoff

Current task: cdb-v0.3-p0-s10f-corrected-focused-editmode
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.deep
Next action: execute the one authorized synchronous corrected focused EditMode run and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: Verifier routing, any retry/fix, manual Unity acceptance, commit, or push remains separately gated

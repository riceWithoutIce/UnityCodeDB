# S29 retained-disposition focused human Unity checklist

Status: READY / exact package reference already switched.
Project: G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29.
Source: 74c4db0cb44afd431b3b861439b3e6ef219d71f3.
Package: .artifacts/s29-retained-disposition-74c4db0/review/com.rice.ai-codedb.
No second export/reference switch, automatic Unity launch, or real package action.

## Human launch prerequisite for the focused test group

Three methods below consume the existing isolated production observation. To
avoid Ignore results, open the already closed S29 project yourself from a
PowerShell window using this process-local launch. This does not change system
environment or project/runtime data. Run it only when S29 is closed; parent
has not executed this command or launched Unity. It uses the project's current
2022.3.62f3 editor, not BatchMode/MCP.

```powershell
$priorRetainedFixture = $env:CODEDB_RETAINED_OBSERVATION_FIXTURE
try {
    $env:CODEDB_RETAINED_OBSERVATION_FIXTURE = 'G:/RiceProgram/UnityCodeDB/.artifacts/tests/s29-retained-disposition/r-e40e4566'
    & 'F:/unity/unity-2022.3.62f3/Editor/Unity.exe' -projectPath 'G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29'
} finally {
    $env:CODEDB_RETAINED_OBSERVATION_FIXTURE = $priorRetainedFixture
}
```

ProductionObservation, ActualAdmission (two cases) and WindowAttachment require
the environment; TwoFailedReceipts is independent. Environment-bound execution
is three methods/four cases. Ignore/Skipped must be reported as
NOT_RUN; it cannot be called PASS. The production fixture is read-only reused
authority plus isolated test workspaces, never a real S29 operational target.

## User actions and visible results

1. Wait for import/compile. Expected: no new C# error.
2. In EditMode Test Runner, run only the thirteen methods below from
   AICodedbProjectSettingsTests, twenty-six cases total. Expected: pass without
   Ignore; report failed/ignored names separately. The carried-forward direct
   attribution cases were not previously reported for the exact human package.
3. Open Manager in EditMode and observe about one minute. Expected: current
   state and historical warnings have coherent separate explanations; no old
   user-local-root error or unexplained stuck running/recovering state.
   Current S29 is INSTALLED with deferred generation mismatch; Install may
   remain absent. Do not require Ready or an Install button.
4. Close/reopen Manager once and switch its usual tabs. Expected: no exception,
   stable rederived presentation. If readiness changes, report the displayed
   transitions/reasons; final Ready alone is not stable-readiness proof.
5. Close Unity normally. Expected: no crash.

Focused methods (13 / 26 cases):

- ManagerRetainedDisposition_ProductionObservationReachesJournalSessionAndUi (1)
- ManagerRetainedDisposition_TwoFailedReceiptsAggregateWithoutRepresentative (1)
- ManagerRetainedDisposition_ActualAdmissionPublishesExactOwnerAndRelease (2)
- ManagerRetainedDisposition_WindowAttachmentClearsOnlyHistoricalProjection (1)
- ManagerActionJournal_ValidInstanceIdsPreserveCurrentAndLegacyAdmission (4)
- ManagerActionJournal_InvalidInstanceDirectoryStillFailsClosed (3)
- ManagerActionJournal_UnownedProvisioningCandidateBlocksHistoryRecovery (1)
- ManagerActionJournal_CurrentIndexWithUnownedCandidateStaysConflict (1)
- ManagerActionSession_DurableRetainedResultReplacesStaleRecoveringSession (1)
- ManagerActionSession_DurableRetainedResultClearsPendingAfterDomainReload (1)
- DirectCandidateArguments_BindActualActionBeforeAdmission (3)
- CandidateArguments_RequireManagerActionAttribution (6)
- LifecycleUpgradeArguments_PreserveDirectBootstrapAttribution (1)

Stop on a material failure and preserve its test message/screenshot. Do not run
the entire suite or the ActualPowerShellRetainedEffectsProof producer fixture.
Do not click Install, Uninstall, Remove Integration or Configure.

## Technical evidence and remaining gates

Source accepted and independent FIX review PASS_WITH_LIMITS. Both package
closure stages PASS, eight source hashes match, exact extraction semantic
compile and fifteen managed cases PASS. Native Unity import/lifecycle/UI,
human NUnit and actual current project state are separate evidence.
The Window test uses managed uninitialized allocation and invokes real
attachment/label/callback selection; rendering and callback execution are not
covered by that test and remain human observation boundaries.

After the human report, parent performs bounded read-only journal/log attribution
and records it against this package. No history cleanup, generation migration,
real install/remove or release is implied. S29/release remain PARTIAL.

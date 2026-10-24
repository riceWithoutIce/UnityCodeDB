# S31-C focused human Unity acceptance

Status: PASS. Human confirms no compile errors, all run tests passed, both
uninstall entries are visible, Manager reopen/tabs are normal and Unity exits
normally. See HUMAN-RESULT.md for evidence limits. No repeat run is requested.

## Exact Baseline

- Open the existing `UnityFreshLifecycleValidationProjectS30` with its recorded
  Unity `2022.3.62f3`.
- Source commit: `cc49c95e84945308385f64640963716d93d070ea`.
- Both consumer references already select
  `.artifacts/s31c-uninstall-entry-cc49c95/review/com.rice.ai-codedb`.
- No reinstall or manual package replacement is required. Preserve current
  installation. Do not click/confirm real Install, Uninstall or Remove actions
  in this round. Actual uninstall transaction is a subsequent bounded gate.

## Focused Editor Tests

After compilation succeeds, use Test Runner EditMode; run only these changed
or directly adjacent tests, including all parameterized cases:

- All six method groups beginning `UninstallEntry_` under
  `Rice.AI.Codedb.Editor.Tests.AICodedbProjectSettingsTests`.
- `RemovalMenu_KeepsKnownIntegrationVisibleWithoutGrantingAdmission`
- `MissingRemovalStatus_KeepsUninstallRequestReachableWithoutOfferingPrimaryMutation`
- `UninstallPreflight_UsesReadOnlyActionWithoutHidingRequestEntry`
- `UninstallCodeDB_ConfirmationControlsExactlyOneProjectAction`
- `RemovalPreflightFailureCache_PreservesBackendReasonWithoutDispatch`
- `RetainedCandidateUninstalledPresentationUsesWorkerPreflightWithoutDispatchOnCancelledWorker`

These tests use test-owned fixtures/seams; they do not authorize uninstall of
the real S30 installation. No full-suite/Provider/real-backend test is requested.
If a listed test fails or is unavailable, preserve its exact name/error and
stop that path; do not repeat, repair the fixture or recreate the project.

## Human UI Checks

1. Check that compilation has no errors.
2. In Ready, Overview primary button reads `Uninstall CodeDB from Project`.
   If not Ready, report the actual state and displayed primary action rather
   than changing installation to force Ready.
3. Open the header action menu and confirm Uninstall is present. Dismiss the
   menu without starting the action.
4. Close/reopen Manager once and switch its tabs; check for errors and retained
   entry visibility.
5. Close Unity normally and report the outcome. The earlier CleanupMono/shutdown
   observation stays deferred; this task does not diagnose it.

Return focused test results, state/button/menu observations and any Console
errors. Passing this round establishes the entry/local action boundary in
Unity, not successful actual backend uninstall or closure of S31-B.

# Optional bootstrap focused human acceptance

2026-10-09. HUMAN_FOCUSED_CONSUMER_AND_MANAGER_PASS. S29 PARTIAL.
User reported focused EditMode PASS and screenshot confirms Install entry, with
original failed/incomplete history restored and incorrect Conflict gone.
This checklist is completed; do not repeat it. Next gate is one new Manager
Install after human confirmation; see HUMAN-RESULT.
Corrected source commitb79fbb8, package `.artifacts/s29-optional-flat-compile-poc42`.
Human owns Unity compile/EditMode/Manager; Parent never launches the Editor.

Open UnityFreshInstallValidationProjectS29 once after Parent switches the local
Package references. Confirm zero C# errors. In EditMode run only:

`ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession`

The method is self-contained on Windows: it resolves the installed Package,
invokes the actual isolated PowerShell fixture under the owned test workspace,
then reads emitted retained evidence with the production C# journal/session.
PowerShell prerequisite fixture may take around two minutes; do not interrupt
it or launch another test at the same time. No manual command or env variable.
Do not rerun unchanged test suites merely to compensate for this narrow change.

If the test passes, open CodeDB Manager and confirm that Install CodeDB is
visible and the "unrecorded effect" conflict is gone. Send the test result and
one Manager screenshot. If compile/test fails or entry remains missing, stop
and send full error/detail. Keep Unity open for diagnosis; no close/open cycle
unless a concrete subsequent Package reference switch requires it.

The completed reader-only acceptance checkpoint required no Install. The
normal fresh Install remains the next explicitly confirmed action after actual
consumer/Manager validation. Preserve original failed/unknown action, retained
candidates and cleanupPENDING. A historical warning may remain as an honest
outcome; acceptance is removal of the incorrect safety Conflict, not rewriting
history as command success. No real recovery replay or physical cleanup.

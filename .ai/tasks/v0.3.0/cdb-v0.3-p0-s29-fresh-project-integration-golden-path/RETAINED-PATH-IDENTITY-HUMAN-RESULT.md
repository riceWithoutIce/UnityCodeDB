# Retained path identity human validation result

2026-10-09. HUMAN_COMPILE_TEST_OBSERVATION_PASS / REAL_RECOVERY_PENDING.
User reports all three requested EditMode methods PASS and Manager open/close
normal. Console screenshot shows zero errors, four distinct warnings. Delivery
commit a06944c1cb7e29ff0b2b209eebe6ca4fe502de85, artifact directory
s29-retained-path-poc42 (actual protected generation remains poc.41).

Executed human evidence:
- RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot: PASS.
- ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession: PASS.
- RetainedCandidateUninstalledPresentationUsesWorkerPreflightWithoutDispatchOnCancelledWorker: PASS.
- Manager open/close observation: normal, no observed exception.
- No C# errors displayed; three compile warnings and one lifecycle warning.

The actual emitted-proof test exercises full journal/session restoration of
synthetic production-emitted records, original failed/incomplete result,
equivalent path forms, and adjacent root/hash refusals. This closes the human
consumer gate for the scoped path correction, not real candidate recovery.

## Reported warnings and read-only source assessment

CS4014 at ManagerWindow.cs1600/2170: both Configure Dependencies UI entry points
discard RunUserActionAsync's Task. The main command body catches exceptions,
but early awaited admission is outside that catch, so no blanket claim that
all exceptions are observed. Track explicit async entry exception observation
as a focused follow-up; no runtime exception on this route was reported here.
Do not mechanically add await to void UI callbacks or merely hide the warning.

CS0414 at ManagerWindow.cs124: _transientStatusRefreshAttempts is assigned but
never read (assignments at802/852/2806). Unused state cleanup is a nonblocking
follow-up, not a reason to repeat this completed human gate.

Automatic uninstall cleanup warning: lifecycle Uninstalled branch dispatches
Upgrade for pending automatic cleanup; its failure is logged at698, constructed
at1180. Existing engine next-change admission throws the quoted unbound-or-
ambiguous candidate refusal when an instance lacks validated binding. Manager
screenshot still shows historical failed INSTALL f14c0524af324b7a802335a393483fa0,
UNINSTALLED and unknown retained admission/effects. Real candidates were not
recovered by fixture tests or reference changes. This is consistent with the
known protected historical state; no assertion of exact live holder safety or
specific offending directory is made without a separate read-only live check.

Next phase should align a concrete real retained-candidate recovery preflight
and authorization, preserving original failed records and no automatic replay.
Automatic cleanup refusal is not permission to remove/rebind/delete candidates.
Repeated warning presentation/deduplication can be considered separately;
physical pending cleanup alone must not fabricate failed scoped test evidence.

No warning source fixes, real receipts/runtime mutations, process termination,
new Unity launch/test rerun, commit/export or remote write occurred while
recording this result. Human Unity closure has not been reported for this
session. S29 remains PARTIAL; Ready, real recovery/fresh Install/runtime/release
acceptance remain open. User owns source-task acceptance/next phase disposition.

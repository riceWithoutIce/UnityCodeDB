# S31-D focused human Unity acceptance

Status: REPORTED TESTS / MANAGER REOPEN PASS; SHUTDOWN MIXED, FOLLOW-UP DEFERRED.

See HUMAN-RESULT.md for the exact human report, screenshot interpretation and
read-only follow-up. This checklist is retained as the requested scope; no
repeat run is requested. Tab switching was not separately reported. A later
user report adds one shutdown blockage; preserve both normal and blocked
samples rather than treating shutdown stability as established.

Open the existing `UnityFreshLifecycleValidationProjectS30` using its recorded
Unity version. Both Package references already point to the exact extraction
from commit `97471f537749eba97171f6756a29112dd552a22b`:
`.artifacts/s31d-uninstall-terminal-97471f5/review/com.rice.ai-codedb`.
No reinstall or manual Package replacement is needed.

## Focused Test Runner

After compilation, run these EditMode methods, including any parameterized cases:

- `AICodedbS31DTerminalTests.SupervisorTerminal_GenericSuccessHasNoBoundProvenance`
- `AICodedbProjectSettingsTests.ManagerActionSession_ReleaseFailureRetainsSpecificAuthenticationDetail`
- `AICodedbProjectSettingsTests.ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission`
- `AICodedbProjectSettingsTests.ManagerActionSession_MissingCommandResultCannotReleaseAdmission`
- `AICodedbProjectSettingsTests.ManagerActionSession_UnconfirmedTransportFailureKeepsRecovery`

The namespace is `Rice.AI.Codedb.Editor.Tests`. The producer/reader/F1 fixture
assertions are internal focused-harness helpers, not selectable Test Runner
methods; their exact extracted-artifact checks already passed. Do not run a
full suite or seek a separate test project for those helper names.

## UI And Closure

1. Confirm compilation has no errors.
2. Open Manager, close/reopen once and switch tabs; report actual state, any
   warning and Console errors. Preserve the existing old pending action.
3. Close Unity normally and report the result. Earlier shutdown observations
   remain deferred; this round does not diagnose them.

Do not click/confirm Install, Uninstall or Remove. The preserved pre-repair S30
action lacks the new terminal anchors and may remain pending/unconfirmed; this
is a declared historical limit, not a requirement to force Ready or rerun it.
This checklist establishes compilation/tests/UI acceptance only. Real backend
handoff, current-record lifecycle behavior and old-action reconciliation remain
separate gates. If a listed test fails or is unavailable, retain the exact
name/error and stop that path for analysis.

# S29 historical handoff capability — human Unity checklist

Use the exact project `UnityFreshInstallValidationProjectS29` after confirming
the Package reference points to `.artifacts/s29-historical-handoff-04e9a6b/review/com.rice.ai-codedb`.

1. Open the project in the approved Unity 2022.3 line and wait for compilation.
   Record compile errors, if any.
2. Run the focused Editor tests for the accepted lifecycle and Manager paths,
   including the historical-removal routing, preflight handoff, retained-entry
   routing and `RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot`
   cases. Record the exact test result and any first failure.
3. Open Manager, close it, reopen it once, and switch its tabs. Confirm that
   historical previous-v2 identity does not present automatic Upgrade/Ready;
   removal presentation appears only when authenticated removal preflight is
   available, and unavailable/foreign evidence keeps it closed.
4. Observe the Manager status long enough to record any NeedsAttention/Ready
   transitions and their displayed reasons. Do not treat final Ready alone as
   stable-readiness proof.
5. Close Unity normally once. Record whether it closes, including any first-run
   CleanupMono wait or shutdown block. Do not force-kill for this checklist.

Do not perform real Remove, Install, Upgrade, Uninstall, cleanup or historical
receipt deletion during this acceptance. Report the visible result and exact
test names; internal hashes and process details remain technical evidence.

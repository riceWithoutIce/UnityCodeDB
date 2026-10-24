# S29 Manager admission — exact-package human result

Date: 2026-10-12. Status: FOCUSED_HUMAN_GATE_PASS_WITH_LIMITS / SHUTDOWN_CONFIRMED.

## User-reported evidence

The user reported that all selected EditMode tests passed, Manager open/close was
normal, tab switching was normal, and Unity closed normally. The supplied
screenshot shows the repaired package Manager with a fail-closed
historical warning and `CodeDB needs attention` state. The warning explains the
unknown prior outcome and blocks new project changes; it does not claim a valid
instance directory is malformed.

## Read-only package confirmation

- S29 manifest and lock both resolve to
  `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-manager-admission-3077ee6/review/com.rice.ai-codedb`.
- Target package.json exists.
- HEAD is `3077ee61d6124bacc1e4989cff9f4c50cf0db466`.
- The Editor.log evidence records completed reconciles with no main-thread
  violations, and the screenshot corresponds to the new package extraction.

## Shutdown discrepancy

After the report, a read-only process check still found PID `56640` running the
exact S29 project (`UnityFreshInstallValidationProjectS29`), responsive with its
Unity main window. PID `50768` is the unrelated miniGame_int project and was not
touched. The parent did not stop either process. Unity shutdown therefore stays
unconfirmed at that checkpoint.

The user subsequently confirmed closure again. A fresh process enumeration found
no S29 Unity process and PID 56640 was absent. Only miniGame_int's Editor and a
miniGame_int UnityCLI command remained; both are outside scope and untouched.
The user report of normal, crash-free close is now supported by process-exit
observation. The shared Editor.log currently belongs to other activity and was
not used to claim S29-specific shutdown diagnostics.

## Final scoped disposition and limits

The selected nine methods / twenty-one cases passed according to the human
report; no test-result XML was independently examined. Manager open/close and
tab switching passed according to the report, and process exit is confirmed.
The reported stale-session test failure is closed for this exact package.

The screenshot still displays `Manager action index escapes its user-local root`
and generation mismatch diagnostics. It proves that changes remain blocked;
it does not prove that the intended orphan-ownership explanation is reached or
that setup/readiness has recovered. These existing diagnostics remain recorded
as limitations, without a new repair or button-restoration claim.

No Install, Uninstall, Remove Integration, Configure, receipt/candidate edit,
retry, source edit, or package regeneration was performed after the human report.
This focused repair's human gate is complete with the above limits. Historical
ownership reconciliation, full retained-producer execution and the continuous
fresh-project Install/removal/reinstall route remain outside this gate;
S29/release remain PARTIAL.

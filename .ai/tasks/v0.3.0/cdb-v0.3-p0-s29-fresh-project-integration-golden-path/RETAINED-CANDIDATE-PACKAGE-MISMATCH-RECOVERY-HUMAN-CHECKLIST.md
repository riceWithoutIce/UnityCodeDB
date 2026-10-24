# S29 package-mismatch recovery — human Unity checklist

Target package:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-package-mismatch-recovery-9179d8a/review/com.rice.ai-codedb`

1. Open `UnityFreshInstallValidationProjectS29` and wait for import. Confirm no new C# compile errors.
2. Open CodeDB Manager and confirm the Package path is the target above.
3. Confirm the Manager now shows `Install CodeDB` while the historical action warning remains informational.
4. Click `Install CodeDB` once. Do not click Uninstall, Remove Integration, Configure, or a second Install.
5. Wait for a terminal result and record action id, outcome, elapsed time, and any failure category/detail.
6. Observe EditMode for about two minutes. Record `Starting`, `Ready`, `NeedsAttention`, and each non-Ready reason.
7. Close and reopen Manager once; observe for about one minute.
8. Close Unity normally.

Stop on timeout, unknown/non-terminal outcome, crash, or other key failure. Preserve screenshots/logs and do not retry in this gate. Runtime manifests, receipts, leases, indexes, and cleanup state must not be edited manually.

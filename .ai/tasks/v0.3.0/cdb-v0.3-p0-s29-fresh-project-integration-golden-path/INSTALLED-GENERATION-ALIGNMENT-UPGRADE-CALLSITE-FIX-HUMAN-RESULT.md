# S29 Upgrade call-site fix — human Unity result

Date: 2026-10-13. Status: HUMAN_ACCEPTANCE_PARTIAL / SHUTDOWN_OBSERVATION_DEFERRED.

Exact Package:
`G:/RiceProgram/UnityCodeDB/.artifacts/s29-upgrade-callsite-fix-34b3a65/review/com.rice.ai-codedb`.
Source commit: `34b3a65c8c3f136ccb052ba52bb10a8476676546`.

## Human observations

- Package import/C# compilation: PASS; the previous CS7036 is gone.
- Dedicated `AICodedbHostPayloadMaterializerPreflightHandoffTests`: PASS.
- Manager close/reopen: PASS.
- Manager tab switching: PASS.
- First Unity close: BLOCKED/DELAYED. The Unity dialog showed
  `Hold on (busy for 11s)... Application.Shutdown.CleanupMono` and
  `Waiting for Unity's code to finish executing.`
- Second Unity close: PASS / no repeat reported.

The provided screenshot is retained as human evidence:
`C:/Users/admin/AppData/Local/Temp/codex-clipboard-3e440b29-c196-4ffb-bfba-e1e3eb1d4e2e.png`.

## Read-only attribution

The current user Editor.log contains the matching lifecycle evidence from the
first close. At `editor_quitting_entry`, `reconcile_in_flight=1` and
`queue_active=1`; at the return boundary both remain active. The same log then
contains `Cleanup mono` and the normal shutdown summary. Its performance sample
records `Application.Shutdown.CleanupMono` at 247 ms, so the visible 11-second
hold is not explained by the native CleanupMono sample alone.

The accepted repair changes only the Upgrade call-site argument in
`AICodedbHostPayloadMaterializer.cs`; the shutdown lifecycle callback and its
queue/dispose path are unchanged. Therefore this sample is a separate shutdown
observation and cannot yet be attributed to the repair. It is also insufficient
to declare a permanent Unity or product shutdown defect because the second
close completed normally. Preserve the sample and continue observation in a
later dedicated shutdown investigation.

No process was force-terminated, no Install/Remove/Uninstall action was run,
and no source repair was made from this observation. Repaired-package compile,
focused tests and Manager UI acceptance pass; normal-close acceptance remains
PARTIAL. The user decided to collect more close/reopen samples before treating
`CleanupMono` as a high-priority repair. Keep this as a deferred observation;
do not open a shutdown-fix slice or change source from the current sample alone.
S29/release remain PARTIAL.

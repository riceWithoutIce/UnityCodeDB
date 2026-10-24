# S39 passive observation capability inventory

Date: 2026-10-20. Status: READ_ONLY_INVENTORY_COMPLETE / NO_CAPTURE_STARTED.
Authority: user agreed to first inspect installed capabilities while discussing
a diagnostic approach that preserves real project registration/MCP timing.

## Observed local capabilities

Windows 10 build 19045; current process is not elevated. WPR reports not
recording at the observation. This does not establish absence of every other
ETW session. Existing services EventLog/EventSystem/Winmgmt are running.

| Capability | Observed availability | Evidence and limits |
| --- | --- | --- |
| System WPR | Installed, 10.0.19041.6093 | Status query only; capture permission untested |
| SDK WPR / WPA | Installed, 10.0.26100.8249 / 11.7.395 | Profiles/status metadata only; OS compatibility of a real capture untested |
| logman / tracerpt | Installed | Provider metadata query only; no session created |
| Kernel-Process ETW provider | Present, process keyword 0x10 | Start/stop templates include PID/time/image and parent identity on start, exit code on stop; actual emitted versions/data not yet tested |
| WMI process start/stop classes | Metadata present | Start has PID/parent/name/time; stop includes ExitStatus; subscription permission/delivery untested |
| Live Win32_Process snapshot | CommandLine/ExecutablePath/CreationDate available | Querying after start may miss a process that exits in 100 ms |
| Procmon | Not found in PATH or checked common locations | Not an exhaustive disk search; no download/install/launch |
| Sysmon operational channel | Not found by exact-name lookup | No Sysmon installation or service change |
| Security event log | Current access denied | No elevation, audit-policy change or Security-event dump |
| Kernel-Process Analytic channel | Exists, disabled | Left disabled; its metadata is not retained process history |

The locally advertised Kernel-Process start templates (event 1, versions 0-3)
do not contain CommandLine, CurrentDirectory or stderr. Stop templates (event 2,
versions 0-2) advertise ExitCode. WMI event templates also lack cwd/stderr.
Do not promise those fields from this route. Other WPR/kernel providers could
have different fields; they were not established by this bounded inventory.

Raw structured inventory: `.artifacts/tests/s39-passive-trace-capabilities.json`.
Owner S39; preserve as capability evidence, not capture/acceptance evidence.

## Recommended direction for discussion

Prefer a short system-side process-event capture with the original Codex/
project Node command, cwd, registration, stdio and environment unchanged.
Use a uniquely owned session, only process keyword 0x10, without CPU sampling,
stack collection, registry/network collection or broad file I/O. Never stop or
cancel another recorder. If elevation is needed, elevate only the recorder;
do not restart/elevate Codex or Unity and thereby change the tested environment.

This can first establish creation/exit ordering, PID/parent identity, image and
exit status. It does not by itself close actual cwd/stderr attribution. If the
missing cwd/path evidence is decisive, separately assess a suitable existing
tool or explicitly agree another route before collecting more data. No claim
that one process-only capture must determine the full cause is made.

The earlier wrapper/shim proposal remains deferred and unapproved. No project
registration edit, intermediary process or redirected MCP stream is selected.
No capture, subscription, event-channel enabling, elevation, new client chat,
MCP startup/query, process control or external project write occurred here.

Next: agree the concrete passive route, actual expected fields, permission
handling, one user-triggered observation window and bounded recorder cleanup.
Do not interpret inventory agreement as authorization to start recording or
repeat either stopped client attempt.

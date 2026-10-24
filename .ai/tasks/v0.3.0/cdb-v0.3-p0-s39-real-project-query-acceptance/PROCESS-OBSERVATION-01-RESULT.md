# Process observation 01 — provider enable failed, no target trigger

Date: 2026-10-21. Status: STOPPED_PERMISSION_FAILURE / OWNED_SESSION_CLEANED.

User authorized the previously proposed one-window observer. Exactly one real
create/start command was attempted in the non-elevated process. No target chat
was requested, created or messaged; no target CodeDB tools were called. There
was no second create/start or automatic retry.

## Observed outcome and correction

`logman create trace ... -ets` returned -2147024891 (0x80070005), access denied.
The initial script mistakenly equated a nonzero return with absence of a session
and returned without stopping it. Subsequent exact-name verification found the
new session still running with the exact owned ETL output path. The agent then
stopped that unique session successfully and verified that its name was no
longer found. No other recorder or target process was stopped.

The ETL is 8192 bytes. Get-WinEvent decoded one header event and **zero events**
from Microsoft-Windows-Kernel-Process. No target launch evidence was obtained.
The file's creation/last-write timestamps span approximately 04:02:00Z to
04:03:02Z, about 62 seconds. The intended 60-second cleanup bound was exceeded
while verifying partial creation; this must not be reported as a compliant
60-second capture. The original receipt's ended_utc is the script return time,
not session termination. A correction object preserves both facts.

Evidence: `.artifacts/tests/s39-process-observation/64386f26670141b695edc147edced1e1/`.
Input hashes for registration, manifest, lock, selected pointer and wrapper
matched before/after script execution. The ETL cannot establish whether a
particular Node child existed, and permission denial is not the cause of the
previous MCP initialize failure.

## Recorder correction and limited validation

`Observe-TargetProcessWindow.ps1` now checks the name is absent before starting;
after a failed start it queries for partial creation, verifies the owned output
path before cleanup, stops only the owned session, and verifies absence. The
timer begins before create so startup work counts toward the observation bound.
The actual system stop call/flush still takes time; no hard preemption bound is
claimed. Only process keyword 0x10 is requested; raw scope is system-wide
process metadata, with a circular 16 MiB file limit. This is not target-only raw
retention and cannot supply stderr/cwd/argv.

PowerShell syntax validation passed. Two final mocked command fixtures passed:
partial create -> exact owned cleanup -> absence verification; and existing
session -> no create/stop. Those fixtures made zero real ETW calls. The initial
mock fixture failed due to its function-scope setup, was corrected, and remains
retained separately; it was not a second real observation. Successful elevated
provider enable and emitted process fields remain unverified.

## Next boundary

This observation is stopped. A fresh, user-authorized run would use an independent
administrator PowerShell for the recorder only, while Codex/Unity keep their
normal privileges and environment. Prepared procedure:
`PROCESS-OBSERVATION-ADMIN-HANDOFF.md`. It is not dispatched or run. No target
session should be triggered until the new observer reports OBSERVER_READY.

Another interpretation correction: the inspected StdioConnection is the desktop
to app-server child stderr handler. Its presence cannot establish direct target
MCP stderr handling or prove that a target stderr message was read but lost.
For the target MCP, binary strings and generic failure records remain incomplete
evidence. Similarly, absent process events cannot prove no child creation
without verified provider delivery, loss checks and target attribution.

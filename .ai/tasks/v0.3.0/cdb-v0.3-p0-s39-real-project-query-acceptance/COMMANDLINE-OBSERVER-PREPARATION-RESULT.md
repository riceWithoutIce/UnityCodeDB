# S39 command-line observer preparation result

Date: 2026-10-21. Status: OFFLINE_CHECKS_PASS / LIVE_WINDOW_NOT_AUTHORIZED.
The user's continuation authorizes the proposed preparation and offline checks.
No real ETW call, new target startup, CodeDB query or Unity launch occurred.

## Prepared snapshot

- NativeProcessTrace.cs: x64 native ETW adapter and owned-handle controller;
  unique session name/GUID, process flag only, 16-MiB circular file and timer.
- CommandLineObserver.Core.ps1: target-only host-log selection, before/after
  input hashes, protected evidence destination and explicit cleanup receipts.
- Observe-TargetCommandLineWindow.ps1: independent administrator entry; requires
  an explicit live-window switch, rejects stale loaded native types.
- Read-CommandLineTraceXml.ps1: read-only tracerpt-XML summarizer. Reports event
  coverage, available loss fields, decoding errors and entry-text candidates;
  does not emit full command lines. Text matches are not resolved argv/cwd or
  project identity. Real trace delivery/decoding is still unverified.
- A source-hash-pinned machine-local launcher is prepared, not executed, under
  `.artifacts/tests/s39-commandline-observation/`. See the separate handoff.

The original observation-03 observer, receipts, Package and target registration
were not edited. No new operational run directory has been created.

## Offline validation

Final snapshots each passed 24 cases with real_etw_calls=0:

| Host | Evidence under .artifacts/tests/s39-commandline-observation/ |
| --- | --- |
| Windows PowerShell 5.1.19041.6456 | offline-windowsps51-fe4b35b022f047cf82e3db1bafa234cf/summary.json |
| PowerShell 7.6.5 | offline-pwsh7-b6d04b9a4ffa45ef8449f0434400d9f0/summary.json |

Cases cover normal cleanup, deadline stop without observer polling, late timer
callback, pre-existing session, unknown preflight, failed absent start, failed
present start, start collision race/exception, missing handle, failed/throwing
stop, unknown final state, scheduler failure, retained loss counters, actual
managed timer-thread callback (simulated stop target), host-terminal/timeout/
collision/failure/missing-log receipts, evidence-path refusal, and synthetic
classic XML filtering/redaction. A repeated Begin or Finish cannot restart a
run or perform a second native stop. All filesystem fixtures are task-local;
no fixture is an operational ETL or actual target-project input.

An initial offline Windows PowerShell 5.1 fixture failed to convert a PSMethod
to System.Action. A compiled callback delegate repaired fixture compatibility;
the final two-host results above include that check. This was not an observer
or MCP startup failure. Earlier fixture evidence is retained.

Source hashes are recorded in both final summary files and pinned by the live
launcher. The native EVENT_TRACE_PROPERTIES layout (120 bytes on x64), process
flag, mode and size limit are exercised through the simulated API. This does
not prove real native session creation, field delivery, loss-free collection,
native cleanup success or target attribution.

## Safety and limits

Native return codes are uint Win32 values: 4201 means session absent; this is
not logman's HRESULT or localized text. A successful start and nonzero returned
handle are the only stop authority. An unsuccessful start followed by a present
session is reported unconfirmed and never stopped by name. Stop is attempted
once; uncertainty does not trigger a retry or a global cleanup command.

The managed timer requests owned-handle stop at the 60-second deadline,
independently of desktop-log polling. Start/stop API blocking, recorder-host
termination or stop failure can defeat that bound; no hard kill or persistent
external watchdog is installed. Actual elapsed time and cleanup must therefore
be checked from the real receipt. Such failures stop the workflow, not authorize
a second window or arbitrary process termination.

The proposed raw scope includes other processes' full command lines, existing
process rundown and UserSID. Filtering the summary does not narrow raw capture.
These files remain local retained evidence, with no upload or automatic delete.
Explicit acceptance of that scope and one real window is still required.

No root-cause diagnosis, query/response-identity PASS, performance, upgrade or
release conclusion follows from these offline checks. Attempt 04 query
acceptance stays ON_HOLD; process observation 04 is a separate future window.

Subsequent authorization checkpoint: the user explicitly approved this one live
window and the stated broader raw-command-line/rundown scope. Status is now
AUTHORIZED_AWAITING_HUMAN_ADMINISTRATOR_LAUNCH, not recording. Four pinned
source hashes match and the unique live run directory is still absent at
handoff. No new offline check or real ETW call was needed for this status update.

Subsequent live result: observation 04 is COMPLETE / DO_NOT_RERUN. See
PROCESS-OBSERVATION-04-RESULT.md. Native capture/cleanup succeeded; expected
argv is present but root cause remains open. Actual raw trace also contains
automatic SystemConfig metadata beyond the process-only expectation. This
preparation record's earlier authorization statuses are historical.

# S39 command-line trace assessment

Date: 2026-10-21. Decision: DEFER_CAPTURE / READ_ONLY_ASSESSMENT_COMPLETE.
No new controller, WPR profile, recorder or client launch was executed.
Observation 03 is complete; acceptance Attempt 04 remains ON_HOLD.

## Evidence gap

Observation 03 found two Node children of the same Codex parent. PID 70836
exited code 1 immediately before target initialize failed. Timing cannot
establish which child ran the target entry.

Local root/wmi Process_V2_TypeGroup1 metadata advertises CommandLine,
ProcessId, ParentId, ImageFileName, ExitStatus, UniqueProcessKey and UserSID.
Microsoft documents CommandLine as the full command line. This is a different
event family from the manifest Kernel-Process events captured in observation
03. Uncaptured command lines cannot be recovered from that old ETL. Schema
availability does not establish actual field delivery in a future capture.

New command-line evidence could bind a PID to the wrapper entry and --root
argument. Relative arguments still do not prove effective cwd, resolved wrapper
bytes or project identity. This route supplies no stderr or environment block
and cannot promise an exact failing check. Wrong arguments could explain a
failure; correct arguments alone would leave its cause open.

## Candidates and decision

| Route | Support and boundary | Decision |
| --- | --- | --- |
| Existing evidence | No changes or new data; old family lacks argv | Keep baseline; cannot fill this gap retrospectively |
| WPR custom ProcessThread profile | Inbox WPR and documented profile syntax; includes threads. -instancename identifies WPR instances, but does not prove private underlying kernel-session isolation; SystemCollector docs list reserved kernel logger names | DEFER; no broad built-in profile or assumed isolation |
| Native ETW system logger with unique name/GUID, process flag only | Windows 8+ private system sessions documented; inbox APIs, no download; explicit ownership possible, raw argv still system-wide | Preferred candidate for further preparation; no live approval |

For the native candidate, Microsoft specifies EVENT_TRACE_SYSTEM_LOGGER_MODE,
a private LoggerName, and a fresh Wnode.Guid distinct from
SystemTraceControlGuid. This is not EVENT_TRACE_PRIVATE_LOGGER_MODE, which is
a separate ETW mode. EVENT_TRACE_FLAG_PROCESS is 0x00000001; do not reuse the
manifest provider's 0x10 or the broader PROC_THREAD+LOADER+CSWITCH example.
Finite system-session capacity means collision/resource failure must stop;
never stop another session or fall back to a reserved logger name.

## Hard gates

| Gate | Assessment |
| --- | --- |
| Target OS | PASS at documentation level: Windows 8+ system logger multiplexing; local Windows 10 build 19045 |
| Distribution/build | PASS at API level: inbox Windows ETW; controller and decoding not yet implemented/validated |
| Generated data | DEFER pending scope: local unique run directory, proposed 60-second and 16-MiB circular-ETL bounds, retained evidence |
| Ownership/isolation | API design supports unique name/GUID; implementation must refuse collisions, stop only its own session and verify absence |
| Raw-data minimization | Target-only acquisition NOT established; analysis filtering is not raw collection isolation |
| Other side effects | Independent administrator recorder; no registration, target cwd/command/stdio/environment, service or audit-policy changes |
| Repeatability/cleanup | Require offline mocked error/timeout/cleanup checks and a reviewed handoff before live collection |
| Benefit | Can catch argv of a short-lived child without changing its launch; delivery and attribution remain unproven |

DCStart/DCEnd enumerate processes already running when a kernel session starts
and ends. Conservatively, raw scope includes other running processes and full
command lines, potentially paths, identifiers or secrets supplied as arguments,
as well as schema fields such as UserSID. Short bounds and post-filtering do
not make this target-only. No raw upload, full argv dump, environment collection
or automatic evidence deletion is proposed. This exceeds observation 03's
process-metadata scope and needs explicit alignment before capture.

## Concrete next step

If selected, first prepare a task-local native controller and offline mocked
checks for numeric errors, unique-session ownership, collisions, timeout,
owned-only cleanup and uncertain-state receipts. Do not make live ETW calls
or launch test processes in offline validation. Keep observation 03's working
script/receipts intact. Freeze the controller, decoder, bounds and handoff
before requesting a new window.

A separately approved live window would use one independent administrator
recorder and one normal human-created CodedbTest_1 chat after OBSERVER_READY,
with zero CodeDB calls. Stop at the first target host terminal event, observer
error or 60-second bound. No retry. Preserve Codex privileges, registration,
Node command, relative cwd/args, stdio and environment. Validate event family,
versions, loss counters, delivered argv, PID/parent/time binding and cleanup
before interpreting results. Missing binding/error detail means INCONCLUSIVE,
not permission for another window. Successful argv attribution is still not
query, response-identity, performance or release acceptance.

No new Unity project, Package replacement or MCP registration change follows
from current evidence. No capture/startup was authorized or performed here.

## Sources checked read-only

- [Process_V2_TypeGroup1](https://learn.microsoft.com/en-us/windows/win32/etw/process-v2-typegroup1): full command line and DCStart/DCEnd.
- [SystemTraceProvider sessions](https://learn.microsoft.com/en-us/windows/win32/etw/configuring-and-starting-a-systemtraceprovider-session): OS support, private name/GUID/system mode and privileges.
- [EVENT_TRACE_PROPERTIES](https://learn.microsoft.com/en-us/windows/win32/api/evntrace/ns-evntrace-event_trace_properties): process flag and circular-file size limit.
- [WPR SystemProvider](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/systemprovider) and [SystemCollector](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/systemcollector): profile and collector syntax.
- Local inbox wpr -help and -help start/stop/cancel/status: lifecycle/instance help only; no recorder started.
- Local Get-CimClass root/wmi Process_V2_TypeGroup1: class metadata only, no event subscription/process enumeration.

Subsequent preparation checkpoint: the user agreed to continue with preparation
and offline validation. A separate controller/entry/decoder and 24-case checks
on each of Windows PowerShell 5.1 and PowerShell 7 are now prepared; native ETW
calls remain zero. See COMMANDLINE-OBSERVER-PREPARATION-RESULT.md and
COMMANDLINE-OBSERVATION-04-HANDOFF.md. Live capture and its broader raw-data
scope remain unapproved; the original read-only findings above are unchanged.

# Process observation 04 result

Date: 2026-10-21. Status: CAPTURE_COMPLETE / OWNED_SESSION_ABSENT /
CONFIGURED_ARGV_OBSERVED / ROOT_CAUSE_OPEN.
This is process observation 04, not query acceptance Attempt 04. No rerun.

## Recorder and scope

The human ran the explicitly authorized administrator launcher once. Native
receipt: StartCode=0, StopCode=0, initial/final QueryCode=4201, cleanup
STOPPED_ABSENT, no exception/error, deadline not reached. A subsequent exact-name
read-only logman query independently confirmed absence (0x80300002).

- Native start: 2026-10-21T05:54:42.5523823Z.
- OBSERVER_READY: 05:54:42.5613614Z.
- Native stop returned: 05:54:49.4355592Z; receipt ended 05:54:49.4405605Z.
- Recorded native elapsed: 6.8837564 seconds; READY-to-ended: 6.8791991 seconds.
- ETL: 4,456,448 bytes (4.25 MiB), below 16-MiB bound; 68 buffers written.
- Native events/log-buffers/realtime-buffers lost: all zero. Tracerpt also
  reports zero lost events. Size and buffer count do not indicate reaching the
  circular limit; zero loss alone is never a general no-overwrite guarantee.
- Five before/after input hashes match: project config, manifest, lock,
  selected pointer and stable wrapper. No project/Package/config edit or
  CodeDB call was performed by this development session.

Actual raw scope requires a correction to the process-only expectation:
besides 3,262 process events (including rundown and defunct history), the
native logger emitted 539 SystemConfig events and 9 trace metadata events.
SystemConfig includes service/device/storage/network-adapter inventory classes;
these are configuration metadata, not file/Registry/network activity tracing.
No unrelated values were displayed or separately extracted. They remain in
the retained local raw ETL/XML; no upload or deletion occurred. This automatic
metadata was not anticipated in the proposed process-event-only description.
Do not reuse this collector under a claim of process-only raw isolation or
start a further window without resolving its actual scope.

## Target chat and host startup attribution

Read-only app lookup confirms the supplied chat:
title **报告 MCP 启动观测**, id
01a15d06-c3f9-7921-9c21-c79e752c79c0, correct CodedbTest_1 cwd,
completed/idle and the supplied user instruction/result. Target namespace
absent, CodeDB calls zero. The target used shell commands for cwd and a filtered
environment-key lookup to obtain its id; the latter went beyond the minimal
cwd lookup. No environment output was read or retained in this analysis.
Those commands occur after initialization and do not establish child cwd.

The receipt captured the intended chat's first target starting/failed pair.
An existing desktop-log read limited to the same server and 05:54:46-50 UTC
found three pairs within the one observation window:

| Host thread | Starting UTC | Failed UTC | Closely matched process PID |
| --- | --- | --- | --- |
| Supplied target chat | 05:54:47.037 | 05:54:47.137 | 30012 |
| Other host thread, ending f4a2b623f1dd | 05:54:47.717 | 05:54:47.850 | 8120 |
| Supplied target chat again | 05:54:48.048 | 05:54:48.121 | 53648 |

All failures report initialize-response connection closure. The other host
thread's purpose/ownership is not established. Do not call it a human-created
replacement chat. Runtime DB row 98356684 labels the supplied chat's later
failure mcp.runtime.refresh:new; this is an observed host refresh, not a manual
retry by the target agent. The observer stops on the first pair it reads, but
native shutdown/rundown need not end at that pair's timestamp. The later
events do not authorize or represent extra observer windows.

## Captured entry and process lifecycle

All three processes share parent PID 75104. Its trace rundown identifies
codex.exe with the same process key at start/end. The three child starts and
ends carry matching per-process keys, image node.exe, and the exact expected
Node executable plus these arguments:

```text
AIWork/codedb/wrapper/codedb-project-wrapper.mjs --root .
```

The absolute Node executable in the retained local trace matches the previously
verified installation; no new Node runtime-version measurement was made. There
are no extra arguments in these captured command lines.

| PID | Event-header start UTC | Event-header end UTC | End status |
| --- | --- | --- | --- |
| 30012 | 05:54:47.0481141 | 05:54:47.1316812 | 1 |
| 8120 | 05:54:47.7296925 | 05:54:47.8492466 | 1 |
| 53648 | 05:54:48.0630958 | 05:54:48.1208411 | 1 |

These are actual Start/End events, not only existing-process rundown. The
captured start status 259 is the running-state field, not the exit result.
The first process lived roughly 84-87 ms across reader time interpretations;
avoid submillisecond creation/latency conclusions. Exit code 1 does not reveal
the exact failing check or termination actor.

The evidence now directly binds these PIDs to the configured entry text and
arguments. Assigning a service/thread to each PID still uses parent/timing
correlation with the host pairs; ETW has no service-name/thread/cwd field.
Relative entry/root arguments do not prove actual cwd, the file Node resolved
or execution of the intended wrapper body. Do not promote this to verified
target runtime identity or a successful wrapper/worker checkpoint.

## Decoder and additional evidence limits

Tracerpt exited 0: 3,810 events, 101 starts, 74 ends, 74 terminate events,
561 DCStart, 588 DCEnd and 1,864 defunct events. It supplies 3,188 command-line
fields, 1,316 nonempty; only matching entry candidates were displayed. One
trace-header ProcessingErrorData and a schema warning remain. The process
candidate payloads decode with this reader.

Get-WinEvent returns 3,809 events and the same 3,262 process event headers,
but candidate payloads are ProcessingErrorData, not independent argv decoding.
Its event-header UTC/PID/opcode confirm candidate event ordering. Tracerpt's
rendered timezone is +07:59 and its start times differ by a few milliseconds
from these headers. Both forms are retained; tracerpt offsets are not treated
as verified UTC. This is a decoder limitation, not a reason to rerun the trace.

A bounded readonly query of the active runtime log DB, 05:54:46-50 UTC,
returned 11 MCP-target rows, 5 naming the target service, and zero stderr
marker rows. It confirms pending/no-ready omission and the later refresh
failure, but provides no child stderr or direct service-to-PID binding. This
store is not asserted to contain every stderr message.

A single post-window bootstrap-directory snapshot still contains only the
60580 baseline from 01:47:53Z. No new bootstrap diagnostic was observed; this
does not prove wrapper code never ran. Existing wrapper source writes only
after diagnostic-root initialization and suppresses diagnostic-write failures.

## Conclusion and next boundary

Registration is recognized and startup is attempted. New evidence establishes
actual Node process launch with the expected wrapper argument vector, followed
by code-1 exits before initialize can succeed. A wrong captured executable or
obvious argument substitution is not observed. Source defect versus environment
defect remains unresolved; absent bootstrap/stderr does not identify a stage.

Remaining decisive gaps: effective child cwd/resolved entry, Node loader/import
error or another primary stderr detail, and attributable wrapper execution
checkpoint. Stop repeating unchanged process/argv windows. Existing static
host cwd-resolution evidence and delivered entry/import paths can be reviewed
next; any launch/logging change needs a concrete separately scoped proposal.
No repair, new project, Package switch or extra runtime test is justified yet.
Query/response identity, performance, upgrade and release gates remain open.

Evidence root:
`.artifacts/tests/s39-commandline-observation/b3acf08815d24ac9bc9880e4f80f6973/`.
Retained receipt, process.etl, process-decoded.xml, trace-summary.txt,
decode-result.txt, trace-analysis.json, candidate-analysis.json,
runtime-window-summary.json and evidence-hashes.json. Raw broader data stays
local; durable results contain only relevant sanitized findings.

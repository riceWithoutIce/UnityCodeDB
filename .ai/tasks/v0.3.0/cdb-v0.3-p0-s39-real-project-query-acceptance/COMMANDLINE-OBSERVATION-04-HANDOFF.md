# Process observation 04: command-line boundary

Status: OBSERVATION_04_COMPLETE / DO_NOT_RERUN.
The human executed this one authorized window. Capture and owned-session
cleanup are complete and independently confirmed. See
PROCESS-OBSERVATION-04-RESULT.md for argv evidence, attribution/decoder limits
and the unanticipated automatic SystemConfig metadata. Remaining instructions
are historical and do not authorize another run.

Historical pre-run status: AUTHORIZED / AWAITING_HUMAN_ADMINISTRATOR_LAUNCH.
The user's explicit agreement authorizes this single window, including the
system-wide full-command-line/rundown scope below. No further confirmation is
needed for the stated human launch/trigger steps. No real capture has started.
This is not query acceptance Attempt 04. Observations 01-03 remain closed.
Preparation and offline checks are complete; see
COMMANDLINE-OBSERVER-PREPARATION-RESULT.md. No live window has started.

## Authorized scope

One independent x64 administrator recorder, one normal human-created local
CodedbTest_1 chat after OBSERVER_READY, zero CodeDB calls, no retry. Use the
same v0.3 Package and existing project. Preserve Codex/Unity privileges,
registration, Node command, relative cwd/args, environment and stdio.

The trace requests native process events only, including full command lines,
PID/parent/image/exit information and schema fields such as UserSID. It may
include processes already running at start/end and unrelated processes in the
window. Raw acquisition is system-wide, even though the displayed summary is
filtered. Full argv can contain sensitive argument values. No environment,
stderr, cwd, network, Registry, file access, stacks or sampling is requested.
Keep raw data local and retained; no upload or automatic deletion.

Bounds: 16-MiB circular ETL, independent managed stop timer at 60 seconds;
observer also stops at the first target host terminal event or an error.
Native blocking/stop failure or recorder-host termination can exceed the
deadline; actual elapsed time and cleanup are validation gates. No automatic
retry, broad session cancellation, process kill or persistent system change.

## Prepared identity and files

Run id: b3acf08815d24ac9bc9880e4f80f6973.
Session: CodeDB-S39-Cmd-b3acf08815d24ac9bc9880e4f80f6973.
Session GUID: f4324b4d-8daa-47b7-a730-748815ea0995.
Evidence root: `.artifacts/tests/s39-commandline-observation/` plus this run id.
That directory does not exist yet. Reuse is rejected.

Machine-local launcher:
`.artifacts/tests/s39-commandline-observation/launch-04-b3acf08815d24ac9bc9880e4f80f6973.ps1`.
It pins the four reviewed source hashes and the existing external project,
checks administrator rights/project existence, chooses the latest t0 desktop
log and starts nothing unless passed the explicit approved-window switch.
No guessed cwd, alternate project or replacement service is permitted.

The scope/window is now approved. The human runs the prepared launcher with
`-ApprovedLiveWindow` ONCE in the independent administrator terminal. Do not
run it from the development session or elevate Codex/Unity.
Do not execute the previous launcher as well or invent another id after failure.
Keep the normal Codex UI ready beforehand; create the new chat only on
OBSERVER_READY. A setup error is a stop condition, not an automatic retry.

## Instruction for the single target chat

```text
你负责 CodedbTest_1 的一次启动观测配合，不是查询验收。
独立观察器已就绪；仅允许本新会话正常发生的 MCP 初始化。
报告实际 cwd 和可确认的本会话 ID；cwd 不符立即停止。
只报告精确命名空间 mcp__codedb_codedbtest_1__* 是否可见。
所有 CodeDB 调用必须为 0；不运行 Node、wrapper、worker、Provider、
探针、Codex CLI、重连或其他诊断；不修改配置/环境，不启动 Unity，
不启停进程，不做 trace，不重试，不续跑任何旧 Attempt。
缺少工具不证明 Node 未创建；工具暴露不构成查询通过。
```

## End and development-session analysis

Return the terminal result, receipt path and target-chat result. No second chat
if timeout occurs. The observer stops only via its successful-start handle and
checks exact-name absence (Win32 4201). On any unknown/failed cleanup, preserve
the receipt and stop; do not stop all ETW sessions or kill Node/Codex processes.

After the approved window, development may decode the retained ETL read-only
using inbox tracerpt into a new process-decoded.xml in the same run directory,
retaining its summary/errors. Do not overwrite earlier evidence or print raw
XML/command-line dumps. Read-CommandLineTraceXml.ps1 summarizes that XML without
full argv. Check both native receipt and trace loss/error metadata; circular
overwrite is not ruled out merely by zero lost-event counters.

Check event family/version, actual command-line field delivery, exact host
thread attribution, new start rather than rundown alone, parent identity,
PID/time/exit and scoped target argv. A text match to a relative wrapper path
is only a candidate; effective cwd/project binding remains separate. If needed,
read only a directly relevant candidate's argv locally and report sanitized
entry/arguments, never unrelated command lines. No captured binding or primary
error means INCONCLUSIVE and no retry. This route cannot promise stderr or the
precise failing check. Do not turn successful launch attribution into query,
response-identity, performance or release PASS.

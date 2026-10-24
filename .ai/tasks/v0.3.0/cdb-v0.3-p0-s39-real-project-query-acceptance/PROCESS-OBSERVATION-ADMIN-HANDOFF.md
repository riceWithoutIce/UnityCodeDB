# Administrator recorder handoff — observation 03 complete, historical instruction

Status: OBSERVATION_03_COMPLETE / DO_NOT_RERUN.
The user ran the authorized launcher and target chat. Capture/cleanup completed;
see PROCESS-OBSERVATION-03-RESULT.md. The remaining instructions are historical,
not authorization to rerun this or another window.
Observation 02 was executed by the user and stopped before ETW create because
the observer incorrectly required an English absent-session message. The repair
uses numeric exit codes and was checked with mocked cases on Windows PowerShell
5.1 and PowerShell 7. See PROCESS-OBSERVATION-02-RESULT.md. No real retry or new
window has been started. The remaining procedure describes the proposed next
window. The user subsequently explicitly authorized observation 03; one fresh
window and one human-created normal target-root chat are now authorized. The
recorder has not been launched. No further retry is included.

Machine-local corrected next-run launch script (not run):
`.artifacts/tests/s39-process-observation/launch-03-eae4fb16d8894512967086c76f0ceaab.ps1`.
It checks administrator rights, fixes the run id/output/project binding, resolves
the current desktop log and calls the reviewed observer. It does not elevate
or launch Codex/Unity. Its evidence destination is
`.artifacts/tests/s39-process-observation/eae4fb16d8894512967086c76f0ceaab/`.

Keep Codex and Unity at their existing privileges/state. Use a separate
administrator PowerShell for the recorder only. Do not launch Codex, Unity,
Node/wrapper, or a target session from that elevated terminal. No new software,
audit-policy change or global environment/config change is involved.

## Before launch

Raw trace scope is all process start/stop metadata emitted by the selected
provider during the window, not only CodeDB. No command line, cwd, stderr,
network, Registry, file-access, stacks or sampling is requested. The trace has a
16 MiB circular limit. Records stay in this task's unique repository evidence
directory; there is no automatic deletion. Only relevant candidate events may
be displayed. Circular overwrite or provider loss can invalidate absence claims.

Have the normal Codex UI ready with the CodedbTest_1 project selected; do not
create the diagnostic chat yet. A newly created chat may itself trigger normal
MCP initialization, so the recorder must be ready first.

For the next run after authorization, execute the prefilled launcher once from a separate
administrator PowerShell. It needs no cwd or path input. The generic equivalent
below is explanatory only: do not execute both launchers or generate a new run id
as a workaround. The prepared command checks elevation without launching
anything elevated itself.

```powershell
$observerIdentity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (!$observerIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Use a separate administrator PowerShell; keep Codex/Unity unchanged.'
}
$observerProject = Read-Host 'Existing CodedbTest_1 absolute root'
$observerId = [guid]::NewGuid().ToString('N')
$observerEvidence = Join-Path (Get-Location) ('.artifacts/tests/s39-process-observation/' + $observerId)
$observerLogRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) ('Codex/Logs/' + (Get-Date -Format 'yyyy/MM/dd'))
$observerLog = Get-ChildItem -LiteralPath $observerLogRoot -File -Filter '*-t0-*.log' |
    Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
if ($null -eq $observerLog) { throw 'No expected desktop log; stop without recording.' }
& '.ai/tasks/v0.3.0/cdb-v0.3-p0-s39-real-project-query-acceptance/Observe-TargetProcessWindow.ps1' `
    -ProjectRoot $observerProject -EvidenceRoot $observerEvidence `
    -SessionName ('CodeDB-S39-' + $observerId) -DesktopLog $observerLog.FullName
```

When the terminal prints `OBSERVER_READY`, manually create exactly one normal
local Codex chat rooted at CodedbTest_1. Send the instruction below. Do not retry
or create a replacement chat if the 60-second window expires. If creation is
too slow, report no attributed trigger and stop this run. If startup fails,
the observer stops on the first new target-server terminal log event it sees;
that event's thread id still needs correlation with the new chat. Another
thread's event is not attributable merely because its service name matches.

## Target-chat instruction

```text
你负责 CodedbTest_1 的一次启动观测配合，不是查询验收。
独立观察器已启动；仅允许这个新会话自身正常发生的 MCP 初始化。
先报告实际 cwd 和本会话标识（若工具/宿主可提供）；cwd 不符立即停止。
只报告精确目标工具命名空间 mcp__codedb_codedbtest_1__* 是否可见。
所有 CodeDB 工具调用次数必须为 0；不要运行 Node、wrapper、worker、
Provider、探针、Codex CLI、重连或其他诊断命令。
不修改项目/配置/环境，不启动 Unity，不启停进程，不做 trace，不重试。
如实返回可见结果。命名空间未暴露不证明 Node 未创建；工具暴露也不构成
查询通过。不复用/续跑旧 Attempt，不要求第二个会话补救。
```

## End and interpretation

Allow the prepared script's finally block to stop only its unique owned
recorder. On `OWNED_RECORDER_STOP_FAILED` or `RECORDER_ABSENCE_NOT_CONFIRMED`,
or `PARTIAL_SESSION_STATE_UNCONFIRMED`,
stop further work and return the exact receipt; never stop all ETW sessions or
kill unrelated processes. Return terminal output, receipt location and the
target-chat result. Do not manually run a second observation.

The development session may then decode the retained ETL read-only, verify
provider delivery/loss and correlate PID/parent/time with target host events.
A shared Node image or nearby timestamp alone is insufficient attribution.
No candidate process is an inconclusive result unless delivery and coverage
are established. An exit code does not identify who killed a process or prove
which wrapper check failed. Host startup success alone is not query acceptance.

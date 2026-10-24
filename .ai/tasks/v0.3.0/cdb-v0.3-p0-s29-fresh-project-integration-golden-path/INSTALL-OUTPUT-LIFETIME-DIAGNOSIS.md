# S29 Install execution/output lifetime: bounded read-only diagnosis

Date: 2026-10-08. User authorized continuing read-only diagnosis after the first
real fresh Install failed. No repair/retry/cleanup authority is inferred.
Action f14c0524af324b7a802335a393483fa0; candidate
5a6ff71560234b558e1a42148b680a77; operation5acbabf5705f48208d7d57882702d14d.
Project UnityFreshInstallValidationProjectS29. Candidate Package is the previously
accepted/exported d56f0e5 at .artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb.

## What is established

The failed step is narrowed to observing completion of watcher Ensure after its
startup work, not the earlier instance-manifest type error or the repaired
BLOCKED/FAILED semantic mismatch. Instance creation calls prepare, adapter build,
then manage-codedb-project-watch.ps1 -Action Ensure -RequireNewOwner -ExclusiveOwner.
Only after those calls return does the engine publish the candidate READY manifest
and run its availability probe. The recorded candidate remains PROVISIONING.

The retained native stdout contains successful freshness refresh, generated watch
configuration, STARTED coordinator and provider_ready/adapter-watching status for
this exact candidate lifecycle. Its stderr file is empty. These are startup
observations, not completed activation or overall product Ready.

The outer terminal confirms exit6,32507ms, timed_out=false, output_overflow=false,
output_drain_incomplete=true. Admission binds the current Package materializer,
project and exact originating action/operation. It records writer PID51772.
The complete supplied command result reports INSTANCE_EXECUTION_OBSERVATION_INCOMPLETE,
the native direct-child observed exit0 and two locked-output messages.

## Execution ownership chain

1. Manager one-shot writer starts the Package materializer PowerShell child with
   stdout/stderr pipes and a bounded EOF drain after child exit.
2. Materializer's instance engine uses Invoke-BoundedNativeProcessWithFileOutput
   to start a generation script through Windows PowerShell Start-Process,
   redirecting stdout/stderr to candidate/tmp/native-*.log files.
3. Watcher Ensure runs the Node coordinator CLI, which starts a long-lived daemon
   with detached:true, stdio:"ignore", windowsHide:true and unref(), then waits
   for an attributable ready response and returns startup status.
4. The daemon owns its Provider and adapter worker. These are intentionally
   longer-lived than the Ensure command; their existence is not by itself an error.

The materializer helper observes direct-child exit, then ReadAllText retries any
IOException until a shared5second observation deadline. The error text collapses
the original exception to "output remained locked" and replaces actual output.
This does not identify the underlying exception, file owner, or handle holder.
The outer Manager writer independently runs a5second pipe drain and reports
missing EOF. Those two symptoms are compatible with an output/handle lifetime
problem across nested execution, but their common cause is not yet proved.

Node's explicit stdio:"ignore" means the source does not intentionally attach
daemon standard output to the caller. Do not assert ordinary stdout inheritance
as a proven cause. Potential extra inherited handles, Windows PowerShell redirect
writer lifetime and asynchronous redirection completion remain hypotheses.
An observed exit0 alone cannot substitute for the missing completion evidence.

## Retained operation evidence and its limits

Retained stdout file: 9,981 bytes.
Stderr:0bytes. Files are now readable. Coordinator log records UTC:

- 10:18:11.497 coordinator_start PID48092.
- 10:18:11.802 adapter_worker_ready PID42128.
- 10:18:11.841 provider_ready PID51536.
- 10:19:38.194 editor_leases_reclaimed, invalid_or_stale.
- 10:19:38.235 coordinator_stop, last_editor_lease_gone, exit0.

One read-only Win32_Process query restricted to recorded PIDs48092,51536,42128,
51772 returned no rows at inspection time. It did not enumerate/stop unrelated
processes. With these processes already absent, current observation cannot recover
the exact historical handle owner. Natural lease expiry does not authorize clearing
the failed attempt, rewriting its receipt, selecting its candidate or replaying.

The deployed poc.40 watcher script and coordinator source match the exact Package
copies. The preceding checkpoint also matched all three Package-level runner/engine
scripts. No observed artifact/source mismatch explains this symptom.

The directly inspected native-helper test loop covers a leaf child printing and
exiting0, printing and exiting7, and timing out. Those cases do not cover a short
Ensure command returning while a detached daemon remains alive, nested inside the
real Manager writer. The recent45Editor tests cover result semantics, not this
actual output-lifetime boundary. This is a concrete gap in the inspected evidence;
it is not a claim that every other repository test was audited.

## Proposed next coherent task, not executed

First reproduce this topology in a project-local isolated fixture using the actual
Manager writer/native launcher plus fixture-owned short command and detached daemon.
Keep the daemon alive after command completion to determine which layer retains
output handles. Cover the normal detached-service case and intentionally retained
output handles separately; stop only fixture-owned processes with exact attribution.
Retain stage/script identity, output paths and original IOException/HResult so the
next failure does not lose the information needed to distinguish causes.

Then align implementation around an explicit ownership boundary: short-command
stdout/stderr completion belongs to that command; daemon lifetime/readiness belongs
to the coordinator's existing status channel. Preserve bounded waits and genuine
unknown-effects refusal. Do not simply increase a timeout, treat a shared-file read
as EOF, accept exit0 without complete evidence, or adopt the failed candidate.

Only after the isolated cause is reproduced should the exact repair allowlist and
regression scope be frozen. If generation-owned code must change, poc.40 is observed
and immutable: use the existing successor-generation route; do not alter it in place.
No new supervisor, generic process manager, global logging service or Windows/client
restart is selected. Missing activity progress indicator remains one P3 follow-up
for Install/Uninstall; it is not evidence of the output collection cause.

## Fingerprints of inspected evidence

Paths relative to candidate root unless identified otherwise:

| Evidence | SHA256 |
| --- | --- |
| instance.json | 1344F215160516141399556C250670021677E0AD0EFA0465663C0821664B16F5 |
| tmp/native-3f509d0c88f7445f90fea1f3e434788d.stdout.log | A7519150F18E9F87A99E14BA13D390C653D1AB347DC77B8B00C47D5256ACC6C9 |
| matching stderr.log | E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855 |
| watch/coordinator/coordinator.log | 7E0B267C1958F14FDCE172C6CE4129CE89BB24FF8633659E92C7B10BBF05F0B0 |
| compact action 11a2ab8a6119800d.admitted.json | 85CCE9F0721295C5EEECC1236B9D9E40A6389C44E36C8096F392606CCAB4203B |
| compact action 11a2ab8a6119800d.claim.json | F19743C72C551408F5A610CA09D9B377AEAA43C9985FF3BC98F27867E7B6AAD5 |
| compact action 11a2ab8a6119800d.terminal.json | CB7F796D8588117509DA1792E4B8C392B5538B2B42889EA4F754F8085F30DC64 |
| compact action action.json | F662468C1E27B7A5CA30AAB40AB084A69351549109BA6107FC68FCFD14890B5B |

No production edits, live writes, tests/reproduction, process termination, Unity
control, reinstall/cleanup, package switch, commit or publication occurred. Only
diagnostic task records were written. Some initial read output was truncated;
targeted follow-ups supplied the relevant markers/branches, not test evidence.
Status: READ_ONLY_DIAGNOSIS_COMPLETE / WATCH_ENSURE_OUTPUT_BOUNDARY_IDENTIFIED /
EXACT_HANDLE_CAUSE_UNPROVEN / ISOLATED_REPRODUCTION_PROPOSED / S29_PARTIAL.

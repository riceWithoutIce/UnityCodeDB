# S42 single authenticated Stop result

Status: STOPPED_NO_REPLAY / OWNED_RETIREMENT_NOT_ESTABLISHED.

The human explicitly approved this one live Stop. The prepared adapter ran once;
its two script hashes matched the approved values. Unity was kept open. No Stop
was retried and no package delivery or reference mutation followed.

## Recorded evidence

Safe receipt:
`<repository-root>/.artifacts/tests/s42-retirement/2026-10-22T04-29-15-932Z-32b8e5/receipt.json`

Receipt SHA-256:
`47d276ce10bfcc43a1fa70202b3e57dffe8c3caa494b4781631a9b30b9ea7080`.

The adapter passed its selected pointer/reference/source, authenticated Supervisor
owner and coordinator process/start/invocation/status preconditions. Its receipt
binds instance `a492a5e936c14e4da3ed7e4cc7c8c16c`, activation
`063aa347f49a4b9f955a5447f293a0ac`, Supervisor owner
`7960ba8ac54541dcb54a1d767ae2fd16`, coordinator PID 45228 and lifecycle
`unity-bridge`.

At 2026-10-22T04:29:17.793Z the client wrote exactly one watcher Stop with the
expected lifecycle. The operation was admitted and correlated as
`cbe070b2575946efb75ad8eaef555b61`. The client then issued four operation reads.
The last successfully validated operation state was `queued`. The fourth read
returned a non-success response with safe server error
`SUPERVISOR_COMMAND_FAILED`; the client ended at 04:29:25.877Z with
`SERVER_REJECTED`, exit code 1.

Counts: Stop requests/writes 1/1; operation reads 4; authenticated inspection
status requests 2; process probes 2; CodeDB MCP calls 0.

## Interpretation and limits

The initial Stop was admitted; the later operation observation failed. The
receipt's `queued` value is the last accepted observation, not proof of the
operation's final state. This record does not establish whether the maintenance
child ran, whether it made partial changes, or whether the service stopped.
`SUPERVISOR_COMMAND_FAILED` alone is not a root cause diagnosis.

Stop postconditions were not reached or checked. No terminal completed/exit-zero
result, coordinator absence or manual-stopped state was established. No extra
runtime snapshot, Stop replay, process kill, reset, Supervisor shutdown, Start,
Install/Uninstall, Unity operation or reference switch was performed.

The single Stop grant is consumed. Keep Unity open while aligning the next gate.
The delivery plan's successful-retirement prerequisite is not met; do not advance
to the closed-Unity package switch. The exported S42 package remains undelivered.

## Proposed next gate (not executed)

Follow-up: the later human-authorized read-only continuation is recorded in
STOP-DIAGNOSIS-RESULT.md. It establishes this operation's terminal child failure
and the interactive-session guard, without changing this original attempt's
record or establishing successful retirement.

Prepare a single read-only diagnosis scoped to this exact operation ID and owner:
read the existing persisted operation/result and its attributed child evidence,
emit a sanitized projection of state/error/disposition, and compare the original
Supervisor error mapping statically. Do not dispatch maintenance, retry Stop or
infer current ownership from historical PIDs. Any need for live authentication or
process probes must be explicitly included in that next bounded grant.

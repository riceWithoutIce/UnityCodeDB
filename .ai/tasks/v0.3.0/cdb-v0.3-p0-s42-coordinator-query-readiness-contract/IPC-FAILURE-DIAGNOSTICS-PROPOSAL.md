# Minimal client IPC failure diagnostics proposal

Status: EXACT_COMMIT_EXPORT_PASS / NOT_CONSUMER_DELIVERED.
The proposal below records the agreed design. The implementation envelope was
subsequently frozen in IPC-FAILURE-DIAGNOSTICS-TASK.md and completed. See
IPC-FAILURE-DIAGNOSTICS-RESULT.md for exact source hashes, offline evidence and
limits. Exact commit/export is recorded in IPC-FAILURE-DIAGNOSTICS-DELIVERY-RESULT.md. No consumer change or real reproduction was performed in this slice.
Motivation: static mapping and one historical extraction cannot identify which
command exchange or I/O stage produced an existing SUPERVISOR_IPC_TIMEOUT.

Proposed first implementation envelope: the Bridge's existing pipe request path
and direct command/poll caller context in Editor/AICodedbSupervisorBridge.cs,
with narrowly adjacent offline transport tests only. Use normal repository-local isolation,
preserve dirty state, and freeze exact source snapshot before editing.

Record local per-request stage transitions only: connect, write, read, complete;
caller kind (initial command vs operation poll), command/action, request ID,
known operation ID, UTC start, monotonic elapsed, and bytes received. On timeout,
append a bounded structured summary to the existing failure evidence path; avoid
new per-byte logging, files, timers, retries, probes, validation or status calls.
Do not interpret an ID as proof the server received the request. No tokens, pipe
addresses, raw request/response bodies, project paths or source text in output.

Preserve all existing timeouts, cancellation/disposal semantics, command/result
codes, owner validation, lifecycle/lease behavior, cached status and UI decisions.
This is phase diagnosis, not a readiness, heartbeat or queue repair. A lightweight
local accumulator may have overhead; do not claim identical runtime timing.

Focused offline checks should distinguish write/read failures and initial/poll
context, show no sensitive output, and verify original failure codes/behavior
remain intact. Freeze the exact focused checks before implementation; no broad
regression, Unity launch, real project calls or consumer mutation in that grant.

Only if client evidence still cannot discriminate the cause should correlated
server receive/dispatch/respond instrumentation be proposed. Do not add it now.

Commit/export, consumer delivery and any one bounded human-driven reproduction
remain later separately authorized gates. No approval is requested for an
unprepared live reproduction. Current consumer remains unchanged with B retained.

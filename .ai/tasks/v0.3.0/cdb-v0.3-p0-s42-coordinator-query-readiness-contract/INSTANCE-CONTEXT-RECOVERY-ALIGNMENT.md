# Updated S42 consumer recovery alignment

Status: STATIC_ROUTE_PREPARED / LIVE_NOT_AUTHORIZED_BY_THIS_DOCUMENT.
No current consumer/process state was sampled during this preparation.

## Preferred ordinary close route

Do not replay the old watch-manager Stop after an isolated source repair: the
already running old Supervisor retains its old code. Do not patch live scripts,
create fake Editor leases or delete runtime evidence to force retirement.

The accepted S40 source already supports an ordinary human Editor close route:

- Editor OnEditorQuitting queues lease deletion and RequestOwnedShutdownAsync,
  requesting shutdown with expected lifecycle unity-bridge; no missing owner is
  launched by that Bridge request.
- Old Supervisor shutdown dispatch checks the expected lifecycle and queues
  retirement, deferring while its active operation is running.
- Its shutdown function directly sends authenticated coordinator stop with the
  expected lifecycle, without entering the watch-manager Editor-session guard.
  It then removes only its owned state/lock evidence and exits.

This is an existing distinct lifecycle entry, not a new bypass of the manual Stop
prerequisite. Source references: Editor/AICodedbEditorLifecycle.cs quitting and
QueueOwnedSupervisorShutdown; Editor/AICodedbSupervisorBridge.cs
RequestOwnedShutdownAsync; accepted S40 Supervisor shutdown dispatch/function at
lines 1633-1660 (Git source, not a fresh consumer execution observation).

It is best-effort. Bridge scheduling may not finish before Unity exits;
coordinator-stop errors are caught; Supervisor disappearance alone cannot prove
coordinator/children stopped. No outcome is asserted from source inspection.

## Proposed later execution order

1. First finish separately approved exact updated commit/export and artifact
   checks. Unity may retain its present state during this repository-only gate.
2. Align and authorize a bounded close/observe/copy/switch envelope. Human closes
   CodedbTest_2 normally and reports closed. Do not request a Manager Stop or
   launch an automatic alternate shutdown client as part of that close.
3. After closure, a prepared read-only observer must establish target Unity
   absence/lock disposition, stable selected pointer and old Package binding,
   old Supervisor/coordinator owner/process disposition and any attributable
   maintenance child. Re-establish current bindings; historical PIDs are only
   correlation hints. Do not infer retirement from stale timestamps, a missing
   state file, a shutdown acknowledgement or an absent/reused PID alone.
   Freeze finite sampling/wait and process-probe counts before this gate; no
   implicit retry or live snapshot loop is authorized by this alignment.
4. Only on established retirement and Unity closure, copy the verified exact
   artifact to a new external Package directory and compare full inventory.
   Back up exact manifest/lock bytes and change only their CodeDB reference.
   Preserve project registration, selected pointer, probes and unrelated files.
   Do not clean any legacy directory possibly created by the failed Stop.
5. Human opens Unity and reports compilation and Manager state. Inspect actual
   policy/manual state before proposing restoration; do not assume the failed
   Stop created manual-stopped state or that no other action did. Any required
   Start is one explicitly scoped existing route, not an automatic replay.
6. Verify complete service shape, then a bounded real target-client status/query.
   A-to-B freshness follows separately. Do not close heartbeat/Unconfirmed or
   formal response-identity items from these source/artifact checks.

If normal close leaves an owner/child live or unknown, stop before copying or
reference switching. Preserve the observation and choose the next exact owned
recovery action with the human. Do not add a fallback PID kill, delete locks,
extend wait indefinitely or silently substitute direct coordinator control.

This alignment supersedes the earlier plan's requirement to establish manual
watcher Stop before human close, if the human approves this route change. Manual
Stop failed; ordinary Editor close remains a separate route whose outcome needs
evidence. No new live action is executed by preparing or approving only the
repository commit/export proposal.

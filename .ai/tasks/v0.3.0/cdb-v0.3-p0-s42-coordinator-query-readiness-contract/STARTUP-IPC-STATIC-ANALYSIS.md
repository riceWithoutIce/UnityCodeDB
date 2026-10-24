# Startup IPC timeout: source and retained-evidence analysis

Status: READ_ONLY_COMPLETE / FAILURE_PATH_NARROWED / ROOT_CAUSE_NOT_ESTABLISHED.
Human approved static mapping and existing-evidence整理 after S41 scoped PASS.
No delegation, product edits, runtime reads, process probes, status IPC, CodeDB
calls, automatic Unity action or new reproduction. No tests run: source analysis
and retained evidence only. Seven installed Package source files were read for
hash parity; this did not sample live service state.

## Source authority and evidence

Inspected isolated clean HEAD 4589249564c7affb541634d61656c0cc895ca9d4. These
sources match bytes in the delivered 4589249-s42-codedbtest2 Package:
Editor/AICodedbSupervisorBridge.cs, AICodedbEditorLifecycle.cs,
AICodedbHostPayloadMaterializer.cs, AICodedbStatusSnapshot.cs,
AICodedbSupervisorLauncher.cs, AICodedbLifecycleEvidence.cs, and
Tools~/codedb-project-supervisor.mjs. References below are relative to that
Package root and frozen source, not the dirty primary checkout.

Historical evidence: HUMAN-REOPEN-RESULT.md screenshots/report show initial
SUPERVISOR_IPC_TIMEOUT with exact message "The Supervisor IPC request timed out."
and later cached Ready. Exact screenshot times and intervening manual actions
were not supplied. The later service-shape sample at 06:33:51-53Z established
authenticated healthy shape, not the earlier failure's state. Subsequent target
fixed query and scoped S41 A-to-B PASS do not reconstruct that failure.

## Confirmed source sequence

1. Deferred Editor lifecycle initialization sets first reconcile not-before
   time to now + 1.5s, queues initial reconcile and attempts a permitted reconnect
   (Editor/AICodedbEditorLifecycle.cs:273-289, 334 onward). Reconnect is gated by
   initialization, automatic-start admission and compile/import/Play boundaries
   (2756 onward). Do not assume every queued intent actually started.
2. For an existing selected instance, lifecycle reconciliation calls
   RunSupervisorCommand(materialize, Probe) then builds/publishes product status
   (1324-1339, 2170-2201). Bridge ensures/validates the owner, constructs a command
   with a new request ID, sends it, then conditionally waits for its operation
   (Editor/AICodedbSupervisorBridge.cs:1834 onward, 1988-2005).
3. SendPipeRequest connects with a 1500ms timeout. After successful connect it
   starts a separate 1500ms deadline shared by write and full response-line read
   (2509-2538). These are separate budgets; not a single 1500ms end-to-end launch
   deadline. ReadBoundedUtf8Line uses one-byte reads under that shared deadline.
4. WaitForPipeIo produces the exact observed message on write/read deadline
   expiry (2600 onward). Initial command and later operation polling both call
   SendPipeRequest (1998, 2318). Therefore the message narrows the path to a
   post-connect message exchange, but does not identify write vs read, initial
   acknowledgment vs operation poll, server receipt, or server processing time.
5. SendCommandWorker catches TimeoutException as exit 124 / timedOut true,
   SUPERVISOR_IPC_TIMEOUT for a non-Manager-action request (2148-2164). A request
   with a valid Manager action ID may instead return OUTCOME_UNCONFIRMED; its
   snapshot can still carry IPC_TIMEOUT. Error code alone cannot prove which
   action failed. requestDispatched is set before SendPipeRequest, so that flag
   alone is not proof that the server received a request.
6. The product builder maps unsuccessful/timed-out results to NeedsAttention
   (Editor/AICodedbHostPayloadMaterializer.cs:958-977). This generic mapping can
   explain a transient IPC failure being shown as setup attention. Unknown /
   Not evaluated child tiles are not independent installation-corruption proof.
7. Later lifecycle work can publish a new coherent status tuple and Ready
   (Editor/AICodedbEditorLifecycle.cs:1338, 3449 onward). Manager's Ready projection
   explicitly describes the cached observation (AICodedbStatusSnapshot.cs:184-212).
   This explains a supported recovery route, not the actual successful request
   responsible for the second screenshot.

Ordinary reconnect errors are handled differently: ConnectSupervisorWorker's
general catch maps to SUPERVISOR_BRIDGE_ERROR (Bridge:1510), unlike the command
catch above. Do not equate the observed command-path code with a demonstrated
Codex MCP registration or ordinary reconnect failure.

## Server behavior and bounded candidates

Tools~/codedb-project-supervisor.mjs has these distinct response paths:

- status dispatch returns an authenticated snapshot immediately, scheduling
  refresh asynchronously (1544-1551). It does not deliberately await Provider
  startup or maintenance completion. "status waits for Provider startup" is not
  supported by this source.
- materialize dispatch admits a durable operation and returns its accepted /
  pending response (1417-1538, 1627-1644). Coordinator ensure and materializer
  execution belong to the later admitted operation. Slow child execution alone
  does not explain a delayed initial acceptance response.
- operation lookup runs through queueQuery (1553 onward). Internal refresh shares
  that query lane and may await Coordinator status with its own 1500ms IPC
  timeout (1270-1295, 2647 onward). If a timed-out exchange was an operation
  lookup, queue time plus work can consume the client's separate 1500ms budget.
  Source establishes the possible contention, not its occurrence in this event.
- Request reception/authentication/dispatch and socket response are in handleClient
  (3135-3155). Operation admission/state/event publication uses synchronous file
  operations. Event-loop scheduling, file work and client full-line read overhead
  are candidate contributors, not measured causes or current blockers.

Priority for evidence collection: first identify the exact failed command and
exchange stage; then determine whether operation-queue delay, synchronous server
work or client message processing exceeded its budget. Do not repair each
theoretical contributor or weaken owner validation from this static inventory.

## Heartbeat, Unconfirmed and recovery are separate

Editor heartbeat interval is 5s, initial reconcile delay 1.5s and normal reconcile
retry cadence 30s (Editor/AICodedbEditorLifecycle.cs:21,31-32,420-469,616-724).
Compiling/import/Play deferral and in-flight guards can defer work. These are
scheduling constants, not response-time promises or an explanation of a measured
one-minute recovery. No precise recovery duration was supplied for this reopen.

Lease refresh and scheduled reconcile can be triggered from the same callback;
that does not equate an IPC timeout with an expired lease. This event lacks
failure-time lease/epoch/request evidence. Historical UI Unconfirmed may also
refer to an unconfirmed Manager action result; do not merge that semantic with
heartbeat liveness or formal response-identity gaps without its original code /
details. Keep these investigations separate until evidence connects them.

## Missing evidence and next proposed scope

Already retained events/operation records may show server start, operation
start/end and owner epochs. Source event schema (Supervisor:1081-1092) and Editor
lifecycle counters do not supply a complete correlated client connect/write/read
and server receive/respond timeline. No broad raw log dump is justified.

Recommended next gate: bounded read-only extraction from already existing
Supervisor event/error and operation-history records for this reopen, and a
small matching Editor log excerpt if available. Derive the old reopen window
from delivery end 06:26:02Z and the healthy 06:33:53Z capture; identify which
historical owner/operation belongs there. Validate names/path binding and size,
cap records/bytes before reading, and emit only timestamps, safe event/error
codes, request/operation IDs and source hashes. Treat overwritten/missing records
as unavailable evidence; do not substitute current state or create a fresh event.
Prepare that exact read closure and budget before execution. No launch/retry/
reconnect/status requests or complete unfiltered Editor/Supervisor log output.

If retained evidence cannot discriminate the stages, propose minimal diagnostic
instrumentation separately: client request kind/action, request/operation ID,
connect/write/read stage, monotonic elapsed and timeout stage; server correlated
receive/dispatch/respond stages. No tokens, pipe addresses, raw requests,
source text, absolute paths, new polling/validation or altered timeouts. This is
an instrumentation proposal only, not authority to implement or reproduce.

## Disposition

No root-cause fix is selected. Do not increase timeout, suppress Needs attention,
alter readiness policy or refactor lifecycle yet. Source confirms the timeout-to-
attention projection and a possible later recovery route, while failure-stage
timing remains unknown. Existing source/artifact/service/query/S41 results retain
their original scope. Consumer remains unchanged with B retained.

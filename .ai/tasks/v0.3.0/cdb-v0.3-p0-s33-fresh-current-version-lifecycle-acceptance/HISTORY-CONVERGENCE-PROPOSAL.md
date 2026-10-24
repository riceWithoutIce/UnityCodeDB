# S33 reinstall blocker: bounded history convergence proposal

Date: 2026-10-19.
Status: USER_APPROVED_SCOPE / FROZEN_REQUIREMENTS / DELEGATION_PENDING.

## Observed facts

Read-only structural inventory of 5301 JSON history records found:

| Name / state / phase | Count |
| --- | ---: |
| materialize:Probe / completed / completed | 3532 |
| materialize:Upgrade / completed / completed | 1767 |
| materialize:Uninstall / completed / completed | 1 |
| materialize:Probe / failed / invalidated | 1 |

Only one record has a nonempty Manager action id: the successful Uninstall.
This inventory is not authentication or proof that every completed operation
is inert, nor a performance measurement. Current Supervisor persistOperation
writes operation.json and an operation-history entry for each operation id.
No history pruning route was found in the inspected exact-Package producer.
Install rejects the history directory above 4096 records before classifying it.

The canonical operation is c61cdf881d39405f85d4f19ae8ac1076, a Probe invalidated
on selection change after Uninstall. It records failed / invalidated, UNKNOWN,
null child, null started_at_utc, and result missing overflow/drain flags.
Current Install terminal validation rejects phase mismatch, missing start time,
incomplete result flags and UNKNOWN disposition. Thus merely reducing the count
does not establish a pass. No retry was run to manufacture another failure.

failQueuedMaintenance writes that shape. invalidatePendingRequests calls it for
pendingMaintenance before admission. The helper is also called on admission
publication failures, so any producer correction must preserve exact call-site
execution knowledge; null child alone must never become proof of no execution.

The earlier Console-noise observation and this history growth are distinct
outputs of background work. Shared activity does not establish that Console
logging causes history growth or that suppressing logs fixes this blocker.

## Proposed requirements for one bounded repair

1. Separate live/recovery evidence from routine diagnostic history. Retention
   may bound older background terminal records only after their complete,
   attributable execution disposition is known and they are no longer needed
   by current/canonical operation, Manager action maps, or instance origins and
   retirement/removal authorities. Keep referenced records and uncertain or
   incomplete execution evidence. Never use age, count, completed label or path
   alone as permission to discard evidence. Map references must not dangle.
2. Align producer and consumer terminal semantics for a request canceled before
   execution. Record explicit no-child disposition only where the producer
   positively knows invocation did not start; retain cancellation reason and
   truthful timing/result fields. Consumers accept that exact terminal contract.
   Running/unknown paths remain distinct. Do not weaken all failed-record checks.
3. Preserve resource bounds. Do not simply raise 4096, remove all limits, or
   truncate to the most recent N records before classification. Retention must
   operate under existing ownership/serialization with crash-safe publication;
   interrupted maintenance must not erase an unresolved operation. If protected
   evidence exceeds capacity, report that actual cause rather than deleting it.
4. Keep S33 first-failure evidence. Existing UNKNOWN records are not retroactively
   certified by a new producer contract. A bounded, separately reviewed disposition
   for this exact canonical record is required before restoring this baseline.
   Do not archive its directory to evade discovery or silently rewrite history.
   If that disposition cannot be established, stop and discuss the existing
   baseline-reset/archive options, without general historical recovery work.

## Validation and scope

Use meaningful focused cases: sustained routine background history crossing the
old count, pinned Manager/current/instance-origin records, unknown or incomplete
execution, positively no-execution invalidation, and interruption during retention.
Keep relevant identity/PID-reuse checks intact. Tests should establish the actual
retention and admission behavior, not just assert a higher count constant.

Once source is accepted and delivered through the existing flow, return to the
one S33 reinstall route with separate real-action authorization. No general
performance audit, new history database, all-versions migration, repeated
isolation rebuilding, log/UI repair, force-stop or Provider/model work is proposed.
If existing contract boundaries require a broader design, return to User before
implementation expansion. No live history changes are granted.

## User disposition - 2026-10-19

User `好的 同意` accepts the immediately preceding bounded repair proposal.
Freeze its two coupled outcomes: history retention and truthful pre-execution
invalidation terminals. Implementation and focused local evidence are within
that source-repair scope; child delegation/execution-route confirmation remains
pending under the supplied AGENTS.md. Source task entry:
../cdb-v0.3-p0-s34-supervisor-history-retention-terminal-closure/TASK.md.
This grant does not authorize real S33 history maintenance or another Install.

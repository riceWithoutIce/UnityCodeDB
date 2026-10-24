# S31 bounded read-only protocol design — 2026-10-15

Status: DESIGN_COMPLETE / SOURCE_PARTIAL / IMPLEMENTATION_CONTINUATION_APPROVED.
Authority: User `同意` to the parent-only 30-minute design pass. No agent
dispatch, source edit, new test, live scan or process operation. TASK.md remains
the product requirement. This is a proposed protocol, not source/runtime PASS.

## Conclusion and evidence

Use one existing durable materializer route for Uninstall in every Manager
state. Manager owns confirmation/presentation; Manager action journal owns
durable admission; materializer owns execution/configuration transactions;
runtime owners provide quiescence, child identity and stop. Supervisor readiness
is not an admission prerequisite. Do not run Uninstall inside a Supervisor
maintenance operation that then waits for that same Supervisor to exit.

The full promise needs runtime producer changes outside the current allowlist.
Create a successor generation; never modify accepted poc.43 or substitute hashes
to disguise an immutable change. Exact generation source/tool paths and identity
authority must be frozen before dispatch. This pass did not establish an
existing generation-authoring tool; do not invent a command or silently add one.

| Current source anchor | Observation | Consequence |
| --- | --- | --- |
| ManagerActionJournal.cs:1459; Paths.cs:405 | Project-key index with short index.lock; one pending owner excludes another. | Reuse admission across windows/reload/Package locators. |
| Paths.cs:372 | Receipts live in environment-derived local application data. | Same supported host/user receipt environment for every consumer; no absolute machine path or cross-machine guarantee. |
| Actions.cs:186,318 | Supervisor command with conditional direct fallback. | One direct admitted Uninstall route, not two execution engines. |
| Supervisor.mjs:1239,1615,1631 | Retirement defers active maintenance; shutdown acknowledgement precedes exit. | Settle writers first; avoid self-wait and verify exit. |
| Supervisor.mjs:2022,3013 | Node also starts materializer; generic timer calls child.kill. | C# timeout changes alone cannot fix writer safety. |
| materialize PS:2689; instance engine:3102,3140 | Exclusive materializer lock, PREPARED/ACTIVATING/COMMITTED journal, rollback/recovery. | Reuse these for writes; never steal a live lock. |
| instance engine:5225,3242 | Uninstall commits desired state/MCP/selection; repeat requests reach recovery before the terminal leaf. | No-op must precede new recovery/cleanup; distinguish a genuinely unfinished transaction. |
| Supervisor.mjs:478,809,2689 | OS start/executable/argv evidence exists; invocation validation derives script/Package from the imported directory. | Authenticate the recorded execution's reviewed locator, not current import path equality. |
| accepted poc.43 coordinator:390,425,1284 | Demand/restart logic uses watch policy/manual mode/Editor leases, without Manager uninstall admission. | Editor-only fence does not close runtime restart paths. |
| accepted poc.43 coordinator:1567,1679 | PIDs/root/config are published, without full original spawn identity for each child. | Do not grant new external force authority from the old roster. |
| accepted poc.43 coordinator:24-29,640,1240 | Query drain can take 95s; CLI exit observation is 13s. | Coordinate phase deadlines; an early CLI timeout is not stop/force proof. |

Runtime reads used the accepted ed97c38 Package, not dirty Payload. The table
records static evidence, not newly executed behavior or an independent audit.

## Persistent request and fence

Extend the existing mutable project action index under index.lock with a
versioned uninstall-request envelope. Keep original action manifests/claims/
receipts immutable. Logical fields: project identity, request action id,
original execution owner, explicit confirmation attribution, phase and protocol.
Freeze exact schema and all readers together before implementation.

1. Before confirmation, inspect only. An already accepted uninstall attaches to
   its progress/result without another dialog.
2. After confirmation, atomically create one request or return its existing id.
   Competing callbacks converge; no parallel writer or repeated effects.
3. If a compatible writer is active, attach one pending uninstall to the same
   admission envelope. Preserve its action/evidence. Its terminal admission
   update preserves/promotes the request atomically, with no delete/recreate gap.
4. Do not hot-enrol an old/unknown active writer into an unsupported protocol.
   Observe boundedly; otherwise retain ownership and return Blocked/Unknown.
5. Reload/reopen observes the original operation, never replays or auto-retries.

The accepted request is the startup fence. Consumers: C# reconcile/reconnect/
launcher and explicit mutations; Supervisor start/maintenance/materializer
dispatch; PS mutation admission; coordinator start/restart/adapter scheduling.
Resolve the existing locator and validate record/project identity at admission
and effects. Malformed/inaccessible evidence is Unknown, not no fence. Add no
parallel daemon, queue or recovery executor.

Do not hold index.lock while awaiting IPC, processes or materializer.lock.
Readers observe atomic records without keeping index.lock. Materializer.lock
remains the configuration writer lock; brief index updates may occur while it
is held, but index-lock holders must never wait for materializer.lock.

No action needed requires proved absence of integration AND pending effects.
Uninstalled requires actual owned-runtime exit and committed deactivation.
Unknown/partial/cancel-pending retains attribution and prevents automatic replay.
Known pre-effect refusal closes without claiming Uninstalled. Subsequent retry/
Install needs separate confirmation and classification of original effects.
Do not convert unsupported historical requests into an open-ended compatibility
route. Existing desired state remains the logical terminal, not an early fence.

## Safe writer protocol

Extend existing admission/claim/receipt evidence with action-bound cancellation
and producer checkpoints; do not infer safety from stdout or a phase label.
Supervisor mutation dispatch must use the same durable writer policy, replacing
generic runChild kill for admitted configuration writes.

- Check cancellation at preparation/wait boundaries before starting more work.
- During a transaction, finish commit or verified rollback under the existing
  lock. Timeout/output overflow/caller loss cannot kill it between mutations.
- A safe-cancel acknowledgement means no further mutations can begin and the
  producer has settled the transaction; it exits normally. Verify exit/effects
  before terminal publication. A checkpoint that can resume is not kill authority.
- Drain output into bounded storage with an independent receipt sink, so Editor
  caller loss does not destroy observation. Child checks writer-owner loss at
  safe boundaries and exits after safe completion; no new detached executor.
- No safe checkpoint/exit by the deadline -> Unknown with original owner/lock/
  journal retained, no replay or invented cancellation. A genuinely OS-stalled
  transaction cannot have a guaranteed bounded safe forced exit.

Propose a 30s safe-completion observation capped by any earlier caller deadline;
retain unrelated action timeout limits. Reload does not renew that deadline.
Late receipts may resolve the original result. Complete/replace the current
ConfirmedProjectMutation WIP as a coupled change, with Install/Remove/Repair
regression evidence. Merely removing kill is not the completed fix.

## Owned-runtime stop and postconditions

Separate process ownership from Ready and pipe health. Unresponsive IPC does
not erase sufficient OS execution evidence; conflicting/unavailable evidence
remains Unknown. No fallback to a bare PID, name, directory or process tree.

For the bounded S30 same-version/different-directory case, follow only the
Package locator in the OS-matched captured invocation. Validate its reviewed
script/Package closure and runtime contract against project/control/activation;
require relevant execution bytes to match for this case. Keep original start
identity, executable, full argv and owner-epoch checks. No historical Package
search, directory alias or script-hash-only ownership. Missing closure blocks.

New runtime producers capture original PID, OS start identity, executable,
invocation identity, project/instance/generation and owner epoch for every
coordinator/Provider/adapter worker/build target. Missing capture must not be
reported as absence. Revalidate at the termination boundary, retaining the
authenticated process handle where supported. Reused PID/unknown targets survive.

Sequence: settle active writer; close runtime admission/restart scheduling;
capture owned roster; request graceful drain; verify child exits; then end
coordinator/Supervisor. An unresponsive parent does not authorise blind tree kill.
Do not stop a parent first and lose the remaining child ownership evidence.

Proposed bounds: 120s total graceful drain/exit (existing 95s query drain plus
child-stop allowance), then 10s total identity-revalidated force/exit observation.
Identity queries retain a 5s maximum capped by remaining phase time. One monotonic
deadline per phase, not a fresh full timeout per child. Use synthetic clocks in
deadline scenarios, with separately labeled native fixture evidence if run.

After quiescence, acquire/reacquire materializer.lock, revalidate request and
selection, and execute existing deactivation transaction. Never wait for a
writer/runtime shutdown while holding a lock that writer needs. Final checks:
owned executions exited, authority not republished, selection revoked, project
MCP registration disabled and desired state committed UNINSTALLED. Content
retention/physical cleanup is separate. Repeated requests read the result before
starting recovery/cleanup; an unfinished original transaction is not a no-op.

Do not patch/hot-enrol poc.43. Authenticated graceful shutdown may succeed via
its original owner and then needs real exit/closure verification. Its PID-only
roster does not justify the new external force-stop authority. If old closure
cannot be proved, return Blocked/Unknown and request a separate reset/archive
disposition. New-generation success does not imply old-runtime acceptance or
permission to reinstall/reset S30. This is the bounded historical policy.

## Implementation proposal and evidence envelope

Propose one continued S31 deliverable, implemented in this order:

1. Existing C#/Tools allowlist: request/fence, direct Uninstall, writer safe
   completion and coupled stale UI/shared-writer tests.
2. Explicitly approved successor-generation sources: coordinator fencing and
   per-child identity, with watch-manager integration and generated identity
   closure. Freeze exact paths, canonical contract/loaders and generation tools
   first; no manual hash substitution or edit to accepted poc.43. Current
   Payload exclusions remain until that scope is approved.
3. Join stop/deactivation/postconditions; run focused original-path C#/Node/PS
   evidence; freeze one completed snapshot; independent read-only Verifier.
   No intermediate subset becomes a source ACCEPT or deliverable.

Required scenarios: cancellation before admission; concurrent confirmation;
multiwindow/reload/Package locator; absent vs Unknown; repeat no-op without
cleanup/recovery replay; compatible/old active writer; timeout/output overflow/
caller or writer loss/rollback on both dispatch routes; startup/restart race;
same-byte old locator; graceful/force exit; PID reuse/unknown refusal; partial
results and retained user/external content; Install/Remove/Repair regressions.
Original source compilation and directly affected semantic/integration tests;
no broad fresh audit. Compilation is not scenario execution or Unity acceptance.

Recommended decision: retain product safety rules and approve the runtime
producer dependency via a successor generation. Proposed renewed ceiling:
an additional envelope of up to 120M Coder and 30M Verifier as a task-local
exception, with prior elapsed history recorded separately and correction counters
retained. This document grants neither scope nor budget.
Exact generation source/tool identities are a pre-dispatch prerequisite; their
discovery may identify a further concrete boundary, not authority to improvise.
No commit, export, reference switch, Unity or live operation is included.

## Limits and completion routing

This pass is static design only. Early source excerpts were marked TRUNCATED;
only bounded relevant follow-up anchors support this result. One documentation
patch context mismatch failed atomically and was corrected; no source changed.
The four WIP source hashes still match the Coder terminal. Real projects,
accepted Packages, external receipts/config and processes remain untouched.

Subsequent disposition: User `批准` approved the runtime producer/successor
identity expansion and renewed budget. TASK.md's approved continuation freezes
the isolated checkout, exact poc.44 source closure, canonical identity projection
method and role gates; it supersedes the pending-decision footer below.

Current task: cdb-v0.3-p0-s31-project-uninstall-workflow
Current status: DESIGN_COMPLETE / SOURCE_PARTIAL / NOT_ACCEPTED
Next notification: WAITING_FOR_USER_DECISION; current parent Planner
Next action: decide runtime-producer scope and renewed budget, then freeze exact
generation source/tool paths before Coder continuation
Human decision or authorization required: successor-generation/identity scope
and 120M Coder / 30M Verifier ceiling; delivery/live authority stays NONE

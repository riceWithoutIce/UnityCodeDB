# S30 uninstall terminal closure — read-only analysis and proposed repair

Status: READ-ONLY ANALYSIS COMPLETE / REPAIR BOUNDARY AGREED / NO SOURCE EDIT.

The original grant covered tracing the completed result and proposing a narrow
repair. The user subsequently replied `好的 同意` to that repair boundary.
The executable scope, consumer map and evidence plan are now frozen in
`../cdb-v0.3-p0-s31d-uninstall-terminal-session-closure/TASK.md`.
Only its explicit execution-route/delegation decision remains pending.
No source edits, test run, child dispatch, delivery or real operation occurred
during task preparation. The original S30 attempt remains preserved.

## Current Facts And More Direct Source Cause

See UNINSTALL-ACCEPTANCE-RESULT-2026-10-17.md for the one real attempt and exact
seven-record evidence snapshot. Backend uninstall is complete with cleanup
PENDING; the Manager action remains pending. Those pending states are distinct.

Read the delivered cc49c95 Package as the execution authority. Its relevant
source also matches the active checkout for the scoped Bridge/Lifecycle/
ManagerWindow/Supervisor files; dirty unrelated ProcessRunner/runtime/Payload
work remains protected and is not an implementation baseline by implication.

The source establishes a stronger cause than a speculative first-response race:

1. Supervisor persists the completed operation and its Manager-action mapping.
   On a terminal operation query with handoff queued, it schedules retirement.
2. Bridge polls the original operation to terminal and, after successful
   materializer execution, completes the Supervisor handoff before returning.
3. Manager stores the initial command result, then ALWAYS calls
   ResolveActionEvidenceAsync for the durable action. That resolver considers
   the reported result only for PreEffectRefusal. It does not adopt an already
   validated Supervisor terminal from the normal returned command.
4. With no direct-writer stage receipt, it calls Lifecycle recovery, which
   queries manager_action_operation on the original Supervisor with startup
   disabled. Its state may already be gone as the successful handoff requires.
5. Recovery becomes Pending; the session's existing release check correctly
   retains the action index because it has no accepted exact-action terminal.

Thus the current design can successfully retire a Supervisor and immediately
require that same Supervisor to reconfirm the completed command. No timeout,
repeated click or interrupted historical operation is needed to explain this.
The sample's exact initial returned object is not preserved in the record;
do not claim independent proof that every first-response parsing step succeeded.

## Existing Authorities And Reuse Limits

| Boundary | Existing authority | Consequence for the repair |
| --- | --- | --- |
| Runtime result producer | Supervisor operation history plus exact action mapping | Retain it as the backend result authority; never use global latest operation, which is now a separate Probe. |
| Online terminal envelope | operationResponse includes operation/action identity and result | Validate the exact dispatched operation and action before treating the returned result as terminal. |
| Direct-writer receipts | ProcessRunner admission/claim/terminal chain | The sample has no such stage. Do not fabricate direct-writer receipts for Supervisor execution. |
| Manager admission | Existing action metadata and pending index bind action/project/Package | Reuse exact session ownership and release API; do not delete or bypass the index. |
| Release rule | Exact action terminal, complete output and matching index | Keep it; fix the result delivery rather than relaxing release guards. |

Important constraint: AICodedbSupervisorCommandResponse.ToCommandResult currently
sets authoritativeTerminalEvidence broadly for a non-timeout/non-uncertain
response. That bit alone is not equivalent to HasOperationEvidence, a matched
operation/action, or a complete final result. A repair cannot simply trust every
reported Succeeded/authoritative flag and short-circuit the existing resolver.

Existing history records are useful, but there is no existing C# offline
Supervisor-terminal reader equivalent to the direct-writer receipt reader.
The history/action map is not automatically interchangeable with a Manager
receipt. Its action map lacks explicit Package/command/owner bindings; some
bindings reside in the operation's child invocation and runtime fields. Any
offline adoption must explicitly close that identity map, not merely parse JSON
containing exit_code 0. If a necessary anchor is unavailable, preserve Unknown
and align the producer change; do not invent authentication from matching IDs.

## Recommended Coherent Repair Boundary

Objective: one current uninstall completion is confirmed once, durably readable
for its exact action, and closes only its own Manager session after Supervisor
retirement. Command result, online readiness and retained-content cleanup remain
independent. Both online completion and reopen consumption use one result policy.

1. Preserve a validated Supervisor operation terminal through the normal return
   path, retaining exact action/operation/project/Package execution bindings.
   Reuse it at Manager completion without requiring a second live query after
   the operation has already retired its Supervisor.
2. Close the producer-to-reader contract for that same durable terminal. Prefer
   the existing operation history/action mapping and existing Manager evidence
   boundary; define necessary admission anchors before implementation. If the
   current records lack a required binding, propose only that tightly coupled
   producer/consumer correction rather than weakening the reader. No second
   lifecycle result authority or independent migration/recovery platform.
3. A reopen of a confirmed completed current action can read its attributable
   terminal without starting Supervisor, replaying Uninstall or relying on the
   current-instance file that uninstall deliberately removes. Nonterminal,
   missing, wrong-action, wrong-context or conflicting evidence stays blocked.
4. Feed the result into existing TryReleaseDurableIndex/TryCompleteRecovery.
   Preserve direct-versus-Supervisor conflict detection, timeout/output limits,
   duplicate-writer prevention and fail-closed behavior.

Before implementation, freeze the precise record/field/anchor consumer map and
file allowlist in the repair task. Expected direct surfaces: ManagerWindow,
SupervisorBridge, Lifecycle, command-result evidence type if necessary, the
Supervisor Package-side producer only if bindings need strengthening, and their
focused Editor/producer tests. Record contract documentation follows the same
scope. No immutable generation edit, ProcessRunner timeout repair, Provider
readiness, owned process termination, UI redesign or historical archive scan.

Current S30 evidence is preserved. This proposal does not promise automatic
adoption of an older record missing the frozen anchors; any such limitation
must be stated before delivery. Never clear the original action manually to
make reinstall available. Historical reconnect remains deferred.

## Bounded Evidence Proposal

- Original producer -> real reader -> exact Manager release, using task-owned
  records with Supervisor runtime state already absent. Match the canonical
  delivered record shapes and actual serialization route; no handwritten PASS
  string or replacement reader. No Provider or real Install/Uninstall.
- Normal authenticated terminal reaches completion without second online
  lookup. A credible failed terminal remains failure while ending its action;
  it must not be confused with successful uninstall or missing evidence.
- Cover directly adjacent pending/missing, action/operation/context mismatch,
  conflicting routes and incomplete/timed-out result; none grants unlock.
- Reopen reads the same completed action idempotently without a second writer.
- Existing test fixtures/compiler are reused only within a frozen bounded plan.
  If native initialization blocks session evidence, record the boundary once;
  use human Unity for that gate rather than repairing the environment again.
- Source acceptance, exact package delivery and any further real lifecycle
  operation remain separate from these focused source/evidence checks.

## Current Handoff

No source edit, test run, subagent, Unity operation, record cleanup or retry was
performed in this analysis. The normal-path double-confirmation dependency is
established; terminal authentication and persistence must be designed together.
The scope is now agreed and its consumer map/execution envelope are frozen in
the S31-D task above. Next: resolve its execution route, then implement within
that envelope. This supersedes the earlier proposal-only handoff.

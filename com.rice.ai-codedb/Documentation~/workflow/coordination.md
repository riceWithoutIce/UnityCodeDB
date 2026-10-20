# Development Workflow v2.6 — Coordination And Routing

This file is a normative module of `codedb-workflow-v2` revision `2.6`.
The stable entry point remains [development-workflow.md](../development-workflow.md);
this module does not create a second workflow or authority.

## Dispatch Protocol

### Authorized Stage Continuation And Risk Boundaries

The user approved this clarification on `2026-10-12`: simplify repeated
confirmation inside an authorized envelope; retain risk-boundary confirmation.
Model speed or capability does not change scope, evidence requirements,
delegation authority, side effects, attempt budgets, or acceptance rights.

Record the approved stages and the attributable user grant in the task's
execution envelope. Once authorized, continue those stages without asking
again whether to start the next declared stage or execute its contained
commands. A task card records authority; writing it does not create authority.
Applicable delegation and session-mode rules still apply.

| Transition | Continuation or human decision |
| --- | --- |
| Authorized diagnosis -> implementation -> focused evidence -> consolidated result | Continue inside the frozen objective, allowlist, evidence and budgets. |
| Stable Coder result -> already authorized read-only Verifier | Planner checks snapshot admission and dispatches review without another stage approval; Coder must have stopped. |
| Verifier returns findings | Return findings together to User; User decides ACCEPT, FIX, DEFER or STOP. Verifier does not assign repairs or interrupt development. |
| User approves a bounded FIX | Continue the declared same-scope repair and targeted repair review without another start confirmation; review only original findings and nearest regressions. |
| Source acceptance or next independent deliverable | Obtain the user's disposition; source acceptance does not authorize delivery or real-environment execution. |
| Scope, architecture, evidence class, protected state or side-effect authority must expand | Stop the dependent path and obtain explicit authorization before crossing the boundary. |

Known risk boundaries include real Unity or external-environment execution,
external process control, actual Install/Uninstall/removal/configuration,
history or candidate cleanup, generation migration, commit, export, project
reference switching, push and publication. These require explicit bounded
authorization identifying the actions, targets, prerequisites and stop
conditions. A user may authorize a concrete group of delivery actions in one
grant; continue only the named actions after their prerequisites pass. This
avoids repeated confirmation without merging their evidence or risk boundaries.
Unlisted actions, a changed target or an expanded side effect need a new grant.

"Continue", passing tests, source ACCEPT and agreement with this workflow do
not imply unlisted permissions. A brief approval may confirm a concrete pending
proposal; bind it to that proposal's scope. Existing narrower task-local grants
remain narrower, and historical tasks are not rewritten or retroactively given
new authority. Missing prerequisites or exhausted budgets still require the
existing stop/handoff behavior. Task-scoped parents remain active through
terminal child completion; durable sessions retain their separate dispatch rules.

When a management session dispatches work to a Code session, the two sessions
have distinct responsibilities:

- The management session owns requirement alignment, task-card freezing, and
  review. The Code session owns the bounded preflight, continuous
  implementation/repair, focused verification, and consolidated result.
- Immediately before dispatch, management performs one bounded target-state
  check. Once the task card is frozen and sent, the Code session starts its
  declared preflight and executes it without an ACK or a second approval.
- After durable-session dispatch, management does not poll, wait, send a
  follow-up, or duplicate the task while the target is active. For an already
  authorized task-scoped child, Planner may use the orchestration wait path but
  does not busy-poll, duplicate the child, send scope-changing follow-ups, or
  edit the child's owned record. It inspects again only on a returned result or
  necessary checkpoint, an explicit user request, or a platform-reported
  interruption or attention event.
- A user interruption or platform interruption does not prove that no work
  started. Record the operational state as `INTERRUPTED`, preserve the latest
  checkpoint, and require an explicit re-dispatch before retrying the slice.

`ALIGN` is the pre-dispatch decision boundary, not a post-dispatch ACK phase.
The task card authorizes the complete declared execution envelope. The Code
session does not request command-level approval for diagnosis, same-scope
repairs, or validation attempts already inside that envelope. `RESULT` is the
normal return boundary; `CHECKPOINT` is used only when execution genuinely
needs a durable resume point. Neither record creates a new task by itself.

Implementation completion, a passing focused test, or writing a `RESULT` does
not authorize a commit. A Code session may propose a commit by stating the
exact files or hunks, message, and expected scope in its `RESULT` or
`CHECKPOINT`, but it must leave the worktree uncommitted until a human
explicitly initiates that exact commit operation, individually or in a bounded
group of named actions. Push and publish each retain explicit authorization;
neither is inferred from permission for a local commit.

## Session Profile Routing

Each task selects one logical execution profile before dispatch. The versioned
profile catalog is `.ai/workflows/codedb-workflow-v2/profile-map.md`. It is a
routing catalog, not a second requirements source, delegation authorization,
or permission to create or modify a durable session.

- Use a `standard` profile for a bounded task with a known behavior, named files,
  and a focused evidence plan.
- Use a `deep` profile for cross-layer contracts, unresolved ambiguity,
  conflicting evidence, P0 risk, or formal release review.
- The profile level does not expand file scope, test scope, Unity permission,
  commit authority, or release authority.
- For `DURABLE_SESSION`, the routing owner resolves the profile to an existing
  session binding. Before dispatch, perform one bounded check that the binding
  is idle and its workspace/snapshot is compatible. After dispatch, follow the
  normal no-poll, no-wait, no-duplicate rule.
- Durable profile capacity is a hard limit. If the selected binding is busy,
  unknown, missing, or incompatible, record `DEFERRED` or `BLOCKED` and notify
  the human. Do not create a replacement session, interrupt the active one,
  silently downgrade, or route the task to a different role.
- Durable session creation, replacement, and profile rebinding are manual
  provisioning actions. A bounded child spawned under `FAST_SUBAGENT` is not a
  durable binding and follows the separate authorization and lifecycle rules
  below.
- A profile change during an active task requires a checkpoint and explicit
  human approval before a new turn. The Coder or Verifier may request an
  escalation but may not silently switch itself.
- The Coder -> Planner -> Verifier -> Planner/User chain remains unchanged;
  Verifier does not dispatch repairs directly to Coder.
- `RESULT.md` or `VERIFICATION.md` records the actual model and reasoning effort
  used. A mismatch is reported to the routing owner and is not a reason for a
  blind rerun.

## Execution Mode Routing

Roles and execution modes are separate. Planner, Coder, and Verifier retain the
same ownership regardless of whether a role runs in a task-scoped child thread
or a durable named session. Every newly frozen task declares one mode:

- `FAST_SUBAGENT`: a task-scoped child Coder and, when required, a later
  task-scoped child Verifier execute one bounded task under the Planner's
  orchestration.
- `DURABLE_SESSION`: an existing reusable Coder or Verifier session owns work
  that needs history, multi-turn continuity, human environment handoffs, or
  stronger long-lived review separation.

Legacy frozen tasks without an execution-mode field are interpreted as
`DURABLE_SESSION`; do not rewrite them merely to adopt this revision. Execution
mode changes transport and continuity only. It never widens the objective,
allowlist, read closure, evidence class, side effects, model authority, Unity
permission, commit authority, or release authority.

Select `FAST_SUBAGENT` only when all of these are true:

- the objective, change allowlist, direct-reference closure, evidence plan,
  budgets, protected state, and stop conditions are frozen;
- the work is expected to converge in one continuous working window without a
  human-owned Unity or external-environment handoff;
- no architecture decision, route reassessment, release promotion, persistent
  cross-project coordination, or long-term session history is required; and
- the task records an applicable human delegation authorization.

Select `DURABLE_SESSION` when any of these apply:

- architecture, redesign, cross-layer authority, unresolved ambiguity, or a
  route reassessment is part of the work;
- the task is expected to span working windows, interruptions, or human Unity,
  consumer, Provider, publication, or other external acceptance steps;
- release review, high-risk migration/data safety, or strong durable review
  independence is required;
- the expected context cannot be represented by one concise task packet and
  direct references; or
- a prior task-scoped child reached a mode-promotion trigger below.

### Delegation Authorization

The task records exactly one delegation state:

- `NOT_AUTHORIZED`: no child agent may be created;
- `TASK_SPECIFIC`: the user authorized task-scoped Coder/Verifier children for
  this frozen task and no other task;
- `STANDING_WORKFLOW`: the user separately granted a revocable standing
  authorization for children that satisfy this section.

Agreement with this workflow, profile selection, a task card, or a passing test
does not by itself create `STANDING_WORKFLOW` authorization. When no explicit
grant is recorded, use `NOT_AUTHORIZED` and ask before spawning a child.

Project standing status: `STANDING_WORKFLOW / ACTIVE`, granted by the user on
`2026-09-16`. Planner may create depth-one task-scoped Coder and later Verifier
children without a new spawn confirmation only when the frozen task satisfies
all `FAST_SUBAGENT` admission rules. The grant is revocable and does not cover
scope expansion, Unity or another human-owned environment, commits, pushes,
publication, release promotion, destructive actions, or durable-session
creation/rebinding; those retain their existing explicit gates.

### Task-Scoped Child Lifecycle

`FAST_SUBAGENT` is a single-writer, depth-one pipeline:

1. Planner freezes `TASK.md`, selects the profile, records delegation authority,
   and spawns at most one Coder child for that task.
2. The Coder child owns only the change allowlist and `RESULT.md`. It does not
   spawn another agent, contact Verifier, alter Planner records, commit, push,
   publish, or continue after a promotion trigger.
3. Planner waits for the terminal child result without busy polling, duplicate
   dispatch, or concurrent edits. Planner then performs one bounded result and
   identity admission.
   For task-scoped children, dispatch is not completion: Planner remains active
   through the authorized child stages, consumes returned questions or blockers,
   and uses bounded waits/status checks to confirm terminal completion. Do not
   end the parent turn merely because a child was dispatched. A user-owned
   decision or human validation gate may still require a handoff; waiting does
   not authorize extra scope or automatic repairs. This monitoring requirement
   does not change the separate durable-session dispatch policy.
4. Only after Coder has stopped and the snapshot is stable may Planner spawn at
   most one Verifier child. The Verifier receives the frozen task, result,
   identity, and declared review claims as fresh minimal context; it is not
   spawned by Coder and does not inherit authority from Coder's conclusions.
   When this review stage and delegation are already authorized, do not request
   another confirmation merely to start it.
5. The Verifier is read-only for implementation/test paths and owns only the
   declared `VERIFICATION.md`. It does not spawn agents or dispatch repairs.
6. Planner returns the consolidated findings to User for `ACCEPT`, `FIX`,
   `DEFER`, or `STOP`. Once User approves a bounded FIX, Planner continues its
   declared repair and targeted repair review without another stage approval.
   A same-task FIX may
   reuse the stopped Coder child when the platform supports it and the envelope
   remains unchanged; otherwise Planner requests the next authorized route.

Coder and Verifier children never run concurrently against the shared
worktree. Planner does not edit a record while its owning child is writing it.
The phase ownership is: Planner owns `TASK.md`, `ROUTE-REASSESSMENT.md`, and
`DECISION.md`; Coder owns the allowlisted implementation/test bytes and
`RESULT.md`; Verifier owns only `VERIFICATION.md`. Child thread IDs and other
live orchestration data are not frozen task identity.

A child thread is an execution aid, not durable project memory. Important
decisions, identities, findings, deferred evidence, and the next-role pointer
remain in the Markdown task packet. Durable chat history is supplemental and
never replaces those records.

### Mode Promotion

A `FAST_SUBAGENT` child stops and returns `MODE_PROMOTION_REQUIRED` when any of
these occurs:

- objective, architecture, allowlist, dependency closure, evidence class,
  side-effect authority, or protected state must expand;
- a structural escalation or route-reassessment signal appears;
- a human Unity/external-environment handoff, multi-window wait, release gate,
  publication decision, or durable independent audit becomes necessary;
- the task cannot converge within its active-time/attempt budget or requires
  history beyond the frozen packet; or
- another Coder/Verifier would need to write concurrently or recursive
  delegation would be required.

Promotion preserves the same task when its independently acceptable objective
has not changed; Planner appends the new authorization and durable route. Use a
new task only under `Slice Sizing`. The child must not create a durable session,
silently continue, broaden scope, or self-promote. A task already routed to
`DURABLE_SESSION` does not demote mid-execution without a Planner/User decision
at a stable handoff.

## Trust And Review Modes

Planner and Coder use a contract-based trust model to avoid repeating low-value
admission and test work. Trust means that the Coder owns the declared
implementation evidence; it does not grant authority to change scope, commit,
publish, or claim release acceptance.

Every task declares one review mode:

- `NORMAL`: documentation, pure logic, or another bounded change with no
  external process, persistent data, or configuration side effect. Coder's
  `RESULT` and declared focused tests are the primary implementation evidence;
  Planner checks consistency and does not rerun unchanged tests. Verifier is
  optional.
- `GUARDED`: protocol, serialization, lifecycle, process, configuration/data,
  Unity EditMode, or a known blocker. Coder still owns implementation evidence,
  but Verifier performs one targeted, read-only review of the declared risk.
- `RELEASE`: release, migration, user-data safety, or formal acceptance. An
  independent Verifier review and the exact acceptance evidence are required.

Verifier scope is always narrower than implementation scope. A Verifier admits
the frozen identity once, reads only the declared claims, changed paths, and
directly adjacent evidence, and reports all material in-scope findings in one
review. It does not perform exploratory repository auditing, rerun unchanged
Coder tests, or convert theoretical hardening and unrelated observations into
release blockers. A repair review covers only the original findings and their
nearest regressions.

Trust is escalated to `GUARDED` when scope changes, evidence is missing, a
result is `PARTIAL`/`BLOCKED`/`DEFERRED`, a test fails beyond the allowed retry,
or an external process, project, configuration, or persistent data is touched.
Escalation changes the next review mode; it does not authorize a blind rerun,
automatic dispatch, or interruption of the active session.

## Completion Routing

At the end of every terminal task turn, the owning session appends a concise
completion-routing footer to the relevant task record and its user-facing
handoff.
Terminal states include `COMPLETE / PASS`, `COMPLETE /
TEST_FAILURE_CLASSIFIED`, `COMPLETE / INFRASTRUCTURE_FAILURE_CLASSIFIED`,
`PARTIAL`, `BLOCKED`, `DEFERRED`, and `INTERRUPTED`. A completed command or test
with valid failure evidence is classified under `COMPLETE`; `BLOCKED` is
reserved for an unavailable external prerequisite, missing/corrupt evidence,
timeout without a classifiable result, or another condition that prevents the
declared work from continuing.

```text
Current task:
Current status:
Next notification:
Next action:
Human decision or authorization required:
```

`Next notification` names the responsible role and exact session alias (for
example, `UnityCodeDB v0.3 Planner`) and states the one bounded action it must
take next. When more than one handoff is necessary, list the notifications in
order; do not broadcast them without an owner. If no handoff is ready, write
`WAITING_FOR_USER_DECISION` and state the decision needed.

This footer is a coordination record, not delegation authorization. For a
durable session it does not authorize polling, waiting, duplicate dispatch, or
interruption. Under an already authorized `FAST_SUBAGENT` task, Planner may
perform the depth-one child lifecycle and use its orchestration wait path, but
does not busy-poll or duplicate a child. Planner remains the routing owner for
review and repair decisions; Verifier returns findings to Planner/User and does
not assign repairs directly to Coder.

Default role routing is:

- Planner completion: identify whether Coder or Verifier receives the next
  bounded action, according to the frozen task card.
- Coder completion: notify Planner with the result, evidence, and any commit
  proposal; Planner decides whether to start Verifier review.
- Verifier completion: notify Planner/User with the review conclusion and
  disposition needed; do not send a direct repair request to Coder.

A typical footer may therefore read:

```text
Current task: cdb-v0.3-p0-s01
Current status: COMPLETE
Next notification: UnityCodeDB v0.3 Planner
Next action: decide commit authorization, then route the exact SHA to Verifier
Human decision or authorization required: commit confirmation
```

# Development Workflow

Status: active project workflow.

This document defines how development and validation work is executed. It is
not a product requirements document. Version roadmaps remain the authority for
what a version must deliver; this document defines how that work is scoped,
implemented, tested, and handed off.

## Authority And Scope

Use the following precedence when rules appear to overlap:

1. The current user's explicit instruction.
2. This project workflow for execution and validation.
3. The active version roadmap for product scope and release gates.
4. A version or P0 companion document for an already-scoped technical
   contract.
5. Historical notes and prior test results as context only, never as new
   requirements.

For the active v0.3 line, the sole product requirement source is
`Documentation~/v0.3.0-roadmap.md`. Companion documents may clarify an item
already in that roadmap, but may not expand the active scope.

## Work Stages

Every task uses these stages in order:

1. `ALIGN`: inspect the current state and agree on one bounded objective.
2. `IMPLEMENT`: change only the files and behavior approved for that slice.
3. `VERIFY`: run the pre-declared focused tests and classify the evidence.
4. `CHECKPOINT`: record the result, remaining risks, and the next entry point.
5. `ACCEPTANCE`: perform user-facing or real-environment acceptance only when
   the implementation slice is ready for it.
6. `HANDOFF`: commit, push, publish, or transfer ownership only after a human
   initiates and explicitly authorizes the exact operation.

Do not enter a later stage while an earlier stage still has an open decision
that can change the implementation.

## Dispatch Protocol

When a management session dispatches work to a Code session, the two sessions
have distinct responsibilities:

- The management session owns requirement alignment, task-card freezing, and
  review. The Code session owns the bounded preflight, implementation, focused
  verification, and checkpoint.
- Immediately before dispatch, management performs one bounded target-state
  check. Once the task card is frozen and sent, the Code session starts its
  declared preflight and executes it without an ACK or a second approval.
- After dispatch, management does not poll, wait, send a follow-up, or duplicate
  the task while the target is active. It inspects again only on a returned
  checkpoint, an explicit user request, or a platform-reported interruption or
  attention event.
- A user interruption or platform interruption does not prove that no work
  started. Record the operational state as `INTERRUPTED`, preserve the latest
  checkpoint, and require an explicit re-dispatch before retrying the slice.

`ALIGN` is the pre-dispatch decision boundary, not a post-dispatch ACK phase.
`CHECKPOINT` is the result boundary for the same frozen outcome; it does not
create a second approval gate before implementation.

Implementation completion, a passing focused test, or writing a `RESULT` does
not authorize a commit. A Code session may propose a commit by stating the
exact files or hunks, message, and expected scope in its `RESULT` or
`CHECKPOINT`, but it must leave the worktree uncommitted until a human
explicitly initiates that exact commit operation. Push and publish remain
separate human-gated operations.

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

Trust is escalated to `GUARDED` when scope changes, evidence is missing, a
result is `PARTIAL`/`BLOCKED`/`DEFERRED`, a test fails beyond the allowed retry,
or an external process, project, configuration, or persistent data is touched.
Escalation changes the next review mode; it does not authorize a blind rerun,
automatic dispatch, or interruption of the active session.

## Completion Routing

At the end of every terminal task turn, the owning session appends a concise
completion-routing footer to the relevant task record and its user-facing
handoff.
Terminal states include `COMPLETE`, `PARTIAL`, `BLOCKED`, `DEFERRED`, and
`INTERRUPTED`.

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

This footer is a coordination record, not an automatic dispatch. It does not
authorize polling, waiting, duplicate dispatch, or interruption of an active
session. Planner remains the routing owner for review and repair decisions;
Verifier returns findings to Planner/User and does not assign repairs directly
to Coder.

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

## Task Card And File Layout

Create and freeze one short `TASK.md` before `IMPLEMENT`. It is the only
execution entry point the Coder must read. General workflow rules, budgets, and
role definitions stay in this document and are not copied into every task.

The minimum `TASK.md` shape is:

```text
# Task: <task-id>

## Metadata
- Product:
- Version:
- Status: READY | DOING | COMPLETE | PARTIAL | BLOCKED | DEFERRED
- Planner:
- Coder:
- Verifier: optional
- Review mode: NORMAL | GUARDED | RELEASE
- Requirement source:

## Objective
- Single outcome:

## Scope
- In scope:
- Out of scope:
- Allowed files:
- Protected state:
- Snapshot binding: optional; only for GUARDED/RELEASE

## Execution
- Coder actions:
- Focused tests:
- EditMode authorization: NOT_REQUESTED | authorized
- Stop conditions:
- Escalation triggers:

## Definition Of Done
- Expected result:
- Required evidence:
- Deferred risks:

## Handoff
- Current task:
- Current status:
- Next notification:
- Next action:
- Human decision or authorization required:
```

Use the following minimal task directory. Do not create empty optional files:

```text
.ai/tasks/<version>/<task-id>/
  TASK.md              # required; Planner freezes it
  RESULT.md            # Coder terminal result or blocking report
  VERIFICATION.md      # only for GUARDED/RELEASE or an explicit request
  DECISION.md          # only when a human disposition is needed
  CHECKPOINT.md        # only for interruption, timeout, budget stop, or recovery
```

Use `.ai/tasks/shared/<task-id>/` only when the contract intentionally spans
versions. The task ID is immutable and must not contain a session name. A
session replacement such as `Coder.2` updates result metadata without rewriting
the frozen task.

`RESULT.md` contains only the outcome, changed-file list, focused evidence,
risks/limits, and the same handoff footer. `VERIFICATION.md` contains only the
review scope, targeted checks, findings, verdict, and handoff. Raw logs,
generated files, and complete diffs remain outside the task documents.

The task card is frozen before `IMPLEMENT`. If a new requirement or behavior
appears, stop at a checkpoint and create a new slice instead of silently
extending the current one.

## Read-Only Preflight

The beginning of a task is read-only and bounded:

- By default, run one `git status --short --branch`. Read `HEAD` only when the
  task's review mode or snapshot binding requires it.
- Do not run a full `git diff`, full history scan, or repository-wide file dump
  as routine admission work. If scope must be checked, use one targeted command
  restricted to the task's allowed files.
- Read `TASK.md` once, then search only the named files and their direct
  references before expanding the surface.
- Prefer line-ranged reads and symbol searches over dumping complete large files
  or generated output.
- Resolve scope, ownership, and acceptance language before editing.

Existing dirty worktree changes are preserved. They are not reset, checked out,
cleaned, or rewritten unless the user explicitly authorizes that exact action.

## Bounded Inspection

The first pass over a large file, generated output, log, or session record is an
index pass: collect only metadata, sizes, timestamps, counts, and matching line
numbers needed to choose the next read. Then read the smallest relevant
excerpts.

- Do not load a complete session JSONL, log, generated artifact, or repository
  dump into the active context.
- A broad `rg` is allowed only with a path or symbol filter and the lower log
  or session output limit in the budget table below.
- When repeated extraction is justified, reuse an existing bounded helper or
  make one small reusable extractor. Do not create one-off full dumps merely to
  avoid selecting evidence.
- `git diff` is not a routine evidence source. When explicitly needed, restrict
  it to the named allowlist and capture only the relevant summary or check
  result once.

## Slice Sizing

The default slice has:

- one observable behavior;
- no more than two runtime boundaries;
- roughly five or fewer production files;
- one focused test batch;
- a target of 45 to 60 minutes of active work;
- at most one context compaction.

These are stop-and-split defaults, not a reason to force an artificial split in
a tiny change. A slice that exceeds them must be checkpointed and divided.
Before `IMPLEMENT`, any exception must be written in the task card with a
reason and an explicit split point. Crossing C#, Node, and PowerShell is not by
itself a reason to keep one large slice: keep the changes together only when
they implement one observable contract and are mechanically coupled; otherwise
split by authority or adapter.

## Command, Output, And Retry Budgets

The following are default hard workflow limits for one implementation slice.
They are execution rules for the task owner; this document does not install an
automatic command wrapper or hook. A future mechanical enforcer is a separate
slice.

| Budget | Warning | Limit and required action |
| --- | --- | --- |
| Active implementation time | `45 minutes` | `60 minutes`; write a checkpoint at the warning and stop the slice at the limit unless a task-card exception was authorized in advance. |
| A normal command's captured output (stdout and stderr) | None | `64 KiB`; mark the result `TRUNCATED`, retain a concise summary, and narrow the next command. |
| A log, session record, or broad `rg` result | None | `16 KiB` or `120` lines, whichever is reached first; keep only the relevant excerpt or an aggregate summary. This lower limit takes precedence over the normal command limit. |
| Cumulative captured output in one slice | None | `256 KiB`; stop expanding the inspection, write a checkpoint, and continue only from that checkpoint. |
| A normal non-test command's wall-clock wait (including reads and searches) | `60 seconds` | `120 seconds`; stop waiting and record `TIMEOUT`. Do not automatically terminate the process. |
| A focused test command's wall-clock wait | `120 seconds` | `300 seconds`; stop waiting and record `TIMEOUT`. Do not automatically terminate Unity or another external process. |
| The same command or semantically equivalent filter after failure | None | At most `1` retry, and only after recording a concrete correction or changed prerequisite. A second failure stops the slice and requires a checkpoint. |
| Context compaction in one slice | None | At most `1`; after the first compaction, write a checkpoint before doing more work and do not expand the slice. |

Count output limits in UTF-8 bytes. When a tool cannot expose a byte count, use
a conservative estimate and stop before the applicable limit. A retry means
the same logical operation even if whitespace, ordering, or a display-only
argument changes. Warnings are a signal to reduce scope; they do not authorize
a blind rerun. A timeout stops waiting, not ownership or lifecycle cleanup:
starting, pausing, and closing Unity or another external process still requires
explicit authorization and a recorded cleanup plan.
Any planned exception to a numeric limit must be written in the task card and
authorized before the command starts; otherwise the limit is hard.

### Budget Ledger And Stop Gate

Keep a small ledger for each slice: active minutes, paused or interrupted
minutes, compaction count, retry count, and cumulative captured output. Calendar
waiting is not active work, but it is recorded separately so elapsed time is
not mistaken for implementation effort.

The first of the following events closes the current implementation window and
requires a checkpoint before another command: the task-card active-time budget
is reached (by default, checkpoint at 45 minutes and stop at 60), the first
context compaction occurs, captured output is near the cumulative limit, or a
second independent behavior or blocker appears. A second compaction or a
repeated budget overrun stops the slice and requires a new slice; continuation
may not silently enlarge the original task card.

## Implementation Rules

- Use the repository's existing APIs, patterns, and ownership boundaries.
- Use `apply_patch` for manual edits.
- Keep changes semantic and local; do not perform opportunistic refactors,
  compatibility work, or formatting churn.
- Keep comments limited to important or non-obvious behavior.
- Do not add a second source of truth for version, control, or lifecycle policy.
- Do not commit, push, publish, stop external processes, or mutate global
  configuration during implementation unless that action is explicitly
  authorized. Code sessions must never auto-commit when implementation or
  focused verification ends. A commit proposal is allowed, but the session
  must not infer authorization from dispatch, the task card, a `RESULT`, or a
  passing test.
- Subagents are off by default. Use one only for an independent, bounded task
  after the user approves delegation.

## Focused Testing And Regression Convergence

Testing is derived from the changed behavior, not from the size of the module
or the number of nearby tests.

### Test Levels

1. `L0` covers the changed pure logic, parsers, schemas, serialization,
   classifiers, and script syntax. It is mandatory for every implementation
   slice.
2. `Affected L1` covers only the nearest consumers that directly call or
   consume the changed contract. It is selected before editing and updated only
   when a newly discovered direct dependency requires it.
3. `Full regression` is not the default. It requires an explicit release gate,
   a user request, or a shared/public contract change whose impact cannot be
   bounded statically.

Regression tests must be justified by the actual diff or by a known failure
path. Shared directory membership, similar names, or a general desire for
confidence are not sufficient reasons to add coverage.

Review mode controls duplicate validation: `NORMAL` accepts the Coder's
bounded result without a second run of unchanged tests; `GUARDED` adds one
targeted Verifier review; `RELEASE` adds independent acceptance evidence. A
passing Coder test never substitutes for a required Unity, consumer, or release
gate.

If a broader set is proposed, record:

```text
Additional tests:
Code change they cover:
Direct impact relationship:
Risk if they are not added:
```

Do not repeatedly rerun unchanged tests when the source, test, and environment
are unchanged. An unrelated failure is recorded as `FOLLOW-UP` unless it
directly affects the current definition of done.

## Unity EditMode Authorization

Unity EditMode is a separate evidence class and is not a default implementation
step. Classify the slice before `IMPLEMENT` and request EditMode only when the
lower-cost evidence cannot answer the declared criterion:

Creating a Unity project or starting a Unity process is forbidden during normal
implementation. Only a separately declared and explicitly authorized
acceptance request may start an existing project or process, with the project
path, exact criterion, maximum wait, and cleanup ownership recorded below.

### Standard Development Validation Project

`<repository-root>/UnityValidationProject` is the only default EditMode
validation project for UnityCodeDB development. Resolve and record its absolute
path from the current repository root before an authorized run; do not hard-code
another checkout. It is a tracked Unity 2022.3 project with a relative reference
to the sibling `com.rice.ai-codedb` package.

- The tracked project's presence does not authorize starting Unity. Every run
  still requires the EditMode request below and an exact focused test filter.
- Do not create, copy, regenerate, or substitute another Unity project during
  an implementation slice. If the tracked project is missing, invalid, or
  cannot be opened with its declared Unity version, record `BLOCKED`.
- Treat `Assets`, `Packages`, and `ProjectSettings` as the validation-project
  contract. Change them only in an explicitly scoped validation-project
  maintenance task. Unity-generated state, logs, and test results remain under
  the project's ignored paths.
- Evidence from this project is development EditMode evidence only. It does not
  replace real consumer-project, third-party Package-only, released-artifact,
  or Codex Desktop acceptance.

- `Low`: documentation, configuration, pure logic, parsers, schemas, or static
  harness work. Do not start Unity EditMode.
- `Medium`: an isolated editor API, package contract, or direct consumer whose
  behavior is not fully covered by L0. EditMode may be requested as one focused
  L1 check; it is not automatic.
- `High`: Unity lifecycle, asset import/serialization, scene/project state, or
  multiple Unity boundaries. If that boundary is part of the definition of
  done, an EditMode request is required; it must remain a focused filter rather
  than a broad project regression. If it is not part of the definition of done,
  record the gate as `DEFERRED` instead of starting Unity opportunistically.

Every request must state all of the following before the process is started:

```text
Project path:
Purpose and criterion:
Exact command and test filter:
Evidence class:
Expected duration / maximum wait:
Cleanup and ownership handoff:
```

The request must receive explicit authorization. The focused-test budget above
applies to the approved command, and the result is labeled `PASS`, `FAIL`,
`BLOCKED`, or `DEFERRED`. Unity startup, shutdown, and any process left after a
timeout are recorded in the checkpoint; a timeout never authorizes an automatic
`Stop-Process`.

## Evidence Labels

Every validation result uses one of these labels:

- `PASS`: the declared check ran and met its criterion;
- `FAIL`: the check ran and did not meet its criterion;
- `BLOCKED`: the required environment or prerequisite was unavailable;
- `DEFERRED`: intentionally outside the current slice;
- `FOLLOW-UP`: observed but unrelated to the current completion boundary.

Static harnesses, Unity EditMode tests, real Unity behavior, Codex Desktop
behavior, released artifacts, and third-party Package-only behavior are
separate evidence classes. One class never substitutes for another.

## Status Namespaces

Workflow execution status and product or runtime status are separate namespaces.
Operational states such as `DISPATCHED`, `ACTIVE`, `CHECKPOINT`, `BLOCKED`,
`DEFERRED`, and `INTERRUPTED` describe this workflow; version-specific states
such as `READY`, `REINSTALL_REQUIRED`, or `NEEDS_ATTENTION` belong to the
product contract. One namespace must not be inferred from the other.

Any persistent product `NEEDS_ATTENTION` state must expose a reason, owner, next
action, and exit criterion. `READY` is set only by the acceptance evidence
declared for that product state, not by a focused test pass alone.

## Context And Checkpoints

Keep the active context small and resumable:

- Bound every inspection command; narrow it when output is truncated.
- Do not repeat the complete repository history after an interruption.
- Send a concise progress update at meaningful milestones, not a full log.
- Produce a `RESULT` after a terminal slice. Produce a `CHECKPOINT` only when
  an interruption, timeout, budget stop, contradiction, or recovery trigger
  occurs.
- Stop and checkpoint after the first context compaction or when a second
  independent behavior enters the task.

Each checkpoint contains only:

```text
Completed:
Actual diff:
Tests and exact results:
Not completed:
Remaining risks:
Next slice entry point:
```

A new task starts from the latest checkpoint rather than reloading the whole
roadmap and all prior tool output.

After an interruption, do not infer that the slice was never started and do not
rerun it automatically. Use the latest checkpoint and the task-card owner to
decide whether to resume or re-dispatch.

## Acceptance And Handoff

User-facing acceptance must be written in terms a normal user can observe and
perform. Do not ask the user to inspect PIDs, hashes, leases, internal JSON, or
developer logs as the ordinary acceptance procedure.

Every user-facing acceptance entry has this shape:

```text
User action:
Visible result:
Technical evidence (separate from the user procedure):
```

Real Unity, Codex Desktop, released-artifact, and third-party acceptance are
separate tasks unless the current task explicitly declares them in scope.
Unexecuted gates remain `BLOCKED` or `DEFERRED`; focused tests do not close
them.

Commit, push, and publish are separate human-gated `HANDOFF` actions:

1. Recheck status, ownership, and focused evidence with commands restricted to
   the authorized files; do not produce a full repository diff.
2. The Code session may present a proposal for the exact operation, including
   commit scope and message when applicable.
3. A human explicitly initiates and authorizes the exact operation. A session
   may execute it only as the direct response to that request; otherwise it
   waits for the human to perform it.
4. Perform only the authorized operation and verify the resulting commit or
   remote state.

## Version Overlays

A version roadmap may add narrower scope, test cases, or acceptance gates, but
it must not silently weaken the workflow's safety or regression-convergence
rules. Version-specific details belong in that roadmap or its companion task;
the reusable process belongs here.

For v0.3, the default implementation verification is L0 plus directly
affected L1. Full regression and live Unity/Codex gates require an explicit
acceptance task, and later Discover Read work remains outside an unrelated
runtime or migration slice.

Changes to this workflow are themselves a process decision: discuss and freeze
the change before applying it to an active implementation task.

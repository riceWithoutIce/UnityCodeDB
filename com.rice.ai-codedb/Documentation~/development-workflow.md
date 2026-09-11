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

## AIServer Memory And Wiki Context

AIServer memory and wiki content are contextual references, not the current
source of truth. They may lag behind the repository, the active task, or the
user's latest decision. Do not query them routinely during alignment,
implementation, verification, or handoff.

Run an AIServer memory or wiki query only when the current user explicitly
requests it or a frozen task card explicitly declares it as required evidence.
Do not infer permission from a generic request for historical context, a stale
result, or a prior session summary. When a query is authorized, keep it narrow,
label the result as memory/wiki-derived, and verify any decision against the
current repository or other live evidence before acting. Do not repeat an
unchanged query merely to refresh context.

## Work Stages

Every task follows this outcome flow:

1. `ALIGN`: inspect the current state and agree on one independently
   acceptable engineering objective and its execution envelope.
2. `IMPLEMENT / REPAIR`: diagnose, implement, and correct same-cause defects
   continuously inside that envelope.
3. `VERIFY`: run the declared evidence plan and classify the result.
4. `ACCEPTANCE`: perform user-facing or real-environment acceptance only when
   the implementation is ready for it.
5. `HANDOFF`: commit, push, publish, or transfer ownership only after a human
   initiates and explicitly authorizes the exact operation.

`CHECKPOINT` is an exceptional resume record, not a mandatory stage. A command
error, failed test, fixture correction, or direct regression returns to
`IMPLEMENT / REPAIR` while it remains part of the same objective and execution
envelope. Do not enter acceptance while an open decision can still change the
implementation.

## Dispatch Protocol

When a management session dispatches work to a Code session, the two sessions
have distinct responsibilities:

- The management session owns requirement alignment, task-card freezing, and
  review. The Code session owns the bounded preflight, continuous
  implementation/repair, focused verification, and consolidated result.
- Immediately before dispatch, management performs one bounded target-state
  check. Once the task card is frozen and sent, the Code session starts its
  declared preflight and executes it without an ACK or a second approval.
- After dispatch, management does not poll, wait, send a follow-up, or duplicate
  the task while the target is active. It inspects again only on a returned
  result or necessary checkpoint, an explicit user request, or a
  platform-reported interruption or attention event.
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
explicitly initiates that exact commit operation. Push and publish remain
separate human-gated operations.

## Session Profile Routing

Each task selects one logical execution profile before dispatch. The versioned
profile catalog is `.ai/workflows/codedb-workflow-v1/profile-map.md`. It is a
routing catalog, not a second requirements source and not permission to create
or modify a session.

- Use a `standard` profile for a bounded task with a known behavior, named files,
  and a focused evidence plan.
- Use a `deep` profile for cross-layer contracts, unresolved ambiguity,
  conflicting evidence, P0 risk, or formal release review.
- The profile level does not expand file scope, test scope, Unity permission,
  commit authority, or release authority.
- The routing owner resolves the profile to an existing session binding. A
  future wrapper may automate this lookup, but the current management session
  remains the routing owner.
- Before dispatch, perform one bounded check that the selected binding is idle
  and its workspace/snapshot is compatible. After dispatch, follow the normal
  no-poll, no-wait, no-duplicate rule.
- Profile capacity is a hard limit. If the selected binding is busy, unknown,
  missing, or incompatible, record `DEFERRED` or `BLOCKED` and notify the human.
  Do not create a new session, interrupt the active one, silently downgrade, or
  route the task to a different role.
- Session creation, replacement, and any profile rebind are manual provisioning
  actions. An automation, if added later, must be reuse-only and must not create
  a session on a routing failure.
- A profile change during an active task requires a checkpoint and explicit
  human approval before a new turn. The Coder or Verifier may request an
  escalation but may not silently switch itself.
- The Coder -> Planner -> Verifier -> Planner/User chain remains unchanged;
  Verifier does not dispatch repairs directly to Coder.
- `RESULT.md` or `VERIFICATION.md` records the actual model and reasoning effort
  used. A mismatch is reported to the routing owner and is not a reason for a
  blind rerun.

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
- Status: READY | DOING | COMPLETE | PARTIAL | BLOCKED | DEFERRED | ROUTE_REASSESSMENT_REQUIRED
- Planner:
- Coder:
- Verifier: optional
- Review mode: NORMAL | GUARDED | RELEASE
- Execution profile: <profile-id from the session profile map>
- Session policy: REUSE_ONLY | MANUAL_PROVISION
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
- Continuous repair: allowed scope and same-cause correction boundary
- Validation attempts: exact per evidence class; Unity must be explicit
- Side-effect authorization: external process, persistent state, or none
- Stop conditions:
- Escalation triggers:
- Structural escalation guard: starting repair count <count>/2; starting consecutive diagnostic-only checkpoint count <count>/3; immediate structural triggers apply
- Model escalation: none | request-only | human-approved

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
  ROUTE-REASSESSMENT.md # only after the structural escalation gate triggers
  CHECKPOINT-NN.md     # only for a real interruption, external block, or handoff
```

Use `.ai/tasks/shared/<task-id>/` only when the contract intentionally spans
versions. The task ID is immutable and must not contain a session name. A
session replacement such as `Coder.2` updates result metadata without rewriting
the frozen task.

`RESULT.md` contains only the outcome, changed-file list, focused evidence,
risks/limits, and the same handoff footer. Same-objective diagnosis, repair,
and validation evidence is appended to that result instead of creating a new
task directory for each attempt. `VERIFICATION.md` contains only the review
scope, targeted checks, findings, verdict, and handoff. Raw logs, generated
files, and complete diffs remain outside the task documents.

The task card freezes the objective, authority boundary, protected state, and
execution envelope before `IMPLEMENT`; it does not freeze each internal command
or repair step. A discovered dependency, fixture defect, parser/construction
error, or immediate regression remains in the current task when it is necessary
to achieve the same accepted outcome and stays inside the declared files,
side effects, and risk. Create a new task only when the outcome changes, work
crosses into an independently owned subsystem, a new high-risk authority is
needed, or the current result is independently acceptable and the next work is
a separate deliverable.

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

The unit of slicing is one independently acceptable engineering outcome, not a
command, file count, language, test batch, elapsed work window, failure count,
or context compaction. A healthy task has:

- one observable product, contract, migration, or acceptance objective;
- one coherent causal chain from diagnosis through validation;
- declared authority, protected state, allowed files, and evidence classes;
- one stable result suitable for acceptance or targeted Verifier review.

Crossing C#, Node, and PowerShell or touching more than five files does not by
itself require a split when the changes implement one mechanically coupled
contract. File count, runtime boundaries, active time, output volume, and
context compaction are planning signals used to narrow commands and summarize
progress; they do not create task identity.

Split only when at least one of these is true:

- the independently acceptable objective changes;
- work enters a separately owned subsystem or produces a separately shippable
  deliverable;
- continuing requires a new high-risk side effect or authority outside the
  frozen envelope;
- an external condition prevents meaningful progress and the remaining work
  can no longer continue as the same owned outcome.

## Structural Escalation And Route Reassessment

Continuous repair is valid only while the evidence still describes a local
defect and the same user acceptance path is advancing. The task must enter
`ROUTE_REASSESSMENT_REQUIRED` no later than either of these limits:

- the same user acceptance path remains blocked after `2` local repair
  iterations;
- `3` consecutive checkpoints improve diagnostics without advancing that
  acceptance path.

A local repair iteration is one causally distinct source or fixture correction
returned for the blocked path and followed by an acceptance re-evaluation. It
is not each edit, command, parser correction, quoting correction, or other
mechanical pre-side-effect correction. A diagnostic-only checkpoint is a
terminal handoff that adds cause or symptom detail but leaves the same
acceptance gate blocked. Counts persist across replacement sessions and are
recorded in `RESULT.md` and the task handoff. These numeric limits are the
latest mandatory escalation point, not a quota to consume before escalating.

Escalate immediately, regardless of count, when evidence shows any of these
structural signals:

- duplicate authorities for the same state, readiness, or admission decision;
- semantic conflict across components that independently classify the same
  product condition;
- a decision composed from caches or observations belonging to different
  revisions or snapshots;
- concrete causes repeatedly compressed into a generic error that prevents
  authoritative diagnosis or routing;
- progress requires another special-case branch, compatibility hole, or local
  exception instead of restoring one coherent contract.

When this gate triggers:

1. Stop further patches, repeated Unity or screenshot cycles, repeated tests,
   and Verifier routing for the affected path.
2. Preserve the current source, task records, and evidence as one frozen
   snapshot. Do not commit, revert, clean, or discard it merely because the
   gate triggered.
3. The Coder records the trigger, counters, structural signals, frozen identity,
   last acceptance state, and handoff to Planner. The Coder may identify the
   signals but may not expand scope or choose a new architecture.
4. Planner creates `ROUTE-REASSESSMENT.md`, consolidates the causal chain and
   affected authorities, and presents one route recommendation to the user.
5. The user chooses exactly one disposition: `CONTINUE_PATCH`, `REFACTOR`,
   `REDESIGN`, `DEFER`, or `STOP`.

`CONTINUE_PATCH` requires a recorded bounded hypothesis, allowed surface, and
new evidence envelope before work resumes. `REFACTOR` or `REDESIGN` becomes one
coherent vertical task spanning the affected contract from authority through
user-visible acceptance; do not decompose it into one microtask per symptom,
file, or test failure. `DEFER` and `STOP` preserve the frozen evidence and close
the current route accordingly. No role infers a disposition from silence.

`ROUTE-REASSESSMENT.md` has this minimum shape:

```text
# Route Reassessment: <task-id>

## Trigger
- Blocked acceptance path:
- Repair iterations: <current>/2
- Consecutive diagnostic-only checkpoints: <current>/3
- Immediate structural signals:

## Frozen State
- Source/task identity:
- Last acceptance state:
- Protected state and active external ownership:

## Causal Summary
- Established facts:
- Conflicting or duplicated authorities:
- Uncertainty and deferred evidence:

## Route Recommendation
- Recommended disposition:
- Coherent target boundary:
- Rejected patch-only alternatives:

## Human Decision
- Disposition: PENDING | CONTINUE_PATCH | REFACTOR | REDESIGN | DEFER | STOP
- Authorized envelope or next task:

## Handoff
- Current task:
- Current status: ROUTE_REASSESSMENT_REQUIRED
- Next notification: Planner/User
- Next action:
- Human decision or authorization required: yes
```

Route reassessment is a planning and decision artifact, not a checkpoint.
`CHECKPOINT` remains reserved for a real external interruption, unavailable
prerequisite, session handoff, or evidence contradiction that needs a durable
resume point.

## Command, Output, And Retry Budgets

The following guards limit resource use and unsafe repetition without defining
task identity. This document does not install an automatic wrapper or hook.

| Budget | Default guard | Required action |
| --- | --- | --- |
| Active implementation time | Review progress near `60 minutes` | Narrow or summarize the current approach. Continue the same task while the objective and execution envelope remain valid; elapsed time alone does not require a checkpoint or split. |
| A normal command's captured output (stdout and stderr) | `64 KiB` | Mark the output `TRUNCATED`, retain a concise summary, and narrow the next command. |
| A log, session record, or broad `rg` result | `16 KiB` or `120` lines, whichever is reached first | Keep only the relevant excerpt or an aggregate summary. This lower limit takes precedence over the normal command guard. |
| Cumulative captured output in one working window | `256 KiB` | Stop expanding inspection, summarize what is known, and continue with narrower commands inside the same task. |
| A normal non-test command's wall-clock wait | Warn at `60 seconds`; stop waiting at `120 seconds` | Record `TIMEOUT`. Do not automatically terminate the process. |
| A focused test command's wall-clock wait | Warn at `120 seconds`; stop waiting at `300 seconds` | Record `TIMEOUT`. Do not automatically terminate Unity or another external process. |
| Parser, escaping, path-normalization, or admission command construction before side effects | Initial attempt plus at most `2` mechanical corrections | Record the concrete construction error and correction. These attempts do not consume the test or Unity invocation budget. Repeating the same uncorrected error is not allowed. |
| Test or external validation attempts | Exact count declared per evidence class in `TASK.md` | One human authorization covers the declared envelope. Every rerun requires a concrete same-cause repair or changed prerequisite; exhausted attempts return to Planner/User but do not create a new task. |
| Context compaction | Summarize after a compaction | Continue the same task from a concise state record. Create a file checkpoint only if execution stops, ownership changes, or evidence needs a durable recovery point. |

Count output limits in UTF-8 bytes when the tool exposes a byte count; otherwise
use a conservative bound without maintaining a manual byte ledger. A retry is
the same logical validation even if ordering or a display-only argument
changes. Warnings narrow the next action but do not authorize a blind rerun. A
timeout stops waiting, not ownership or lifecycle cleanup: starting, pausing,
and closing Unity or another external process still requires explicit
authorization and a recorded cleanup plan.

Unity and other expensive or externally stateful invocations have no implicit
budget. Their exact maximum count must be human-authorized in the task card.
For a release/full gate, the request may authorize an initial run plus up to two
same-scope corrected runs as one envelope; this is a maximum, not a requirement
to consume every attempt.

### Budget Ledger And Continuation Gate

Record only evidence that affects safety or interpretation: external/test
invocations, corrected attempts, retries, timeouts, truncation, and any process
whose ownership returns to the human. Do not maintain minute-by-minute or
estimated-byte accounting when the tools do not provide it.

Pause for Planner/User only when the objective changes, authority must expand,
an external prerequisite prevents progress, evidence is unavailable or corrupt,
or the authorized external/test attempt envelope is exhausted. An exhausted
envelope may be extended by appending authorization to the same task record;
it does not require a new task unless the independently acceptable outcome has
changed.

## Implementation Rules

- Use the repository's existing APIs, patterns, and ownership boundaries.
- Use `apply_patch` for manual edits.
- Keep changes semantic and local; do not perform opportunistic refactors,
  compatibility work, or formatting churn.
- Keep comments limited to important or non-obvious behavior.
- Do not add a second source of truth for version, control, or lifecycle policy.
- Keep Git inspection milestone-based and scoped: normally one bounded
  target-state check before dispatch and one final scoped status/diff or
  `diff --check` at handoff. Do not repeatedly run full-repository status,
  diff, or identity calculations. Freeze exact identities once, only when a
  `GUARDED` or `RELEASE` handoff needs them.
- Do not commit, push, publish, stop external processes, or mutate global
  configuration during implementation unless that action is explicitly
  authorized. Code sessions must never auto-commit when implementation or
  focused verification ends. A commit proposal is allowed, but the session
  must not infer authorization from dispatch, the task card, a `RESULT`, or a
  passing test.
- Coder and Verifier sessions must never create a Unity project, launch a
  Unity Editor, or run a Unity validation process in the background or hidden
  from the human. A task card or the presence of the standard validation
  project is not authorization. Unity may start only under the explicit
  EditMode/acceptance request defined below.
- If Unity MCP is unavailable, a connection fails, or the required MCP
  surface cannot be used, stop that Unity evidence path, preserve the original
  error, and notify the human. Do not retry in the background, switch to an
  unreviewed endpoint, create a substitute project, or present a direct probe
  as Unity/MCP evidence. Classify the gate as `BLOCKED` or `DEFERRED`.
- Subagents are off by default. Use one only for an independent, bounded task
  after the user approves delegation.

## Focused Testing And Regression Convergence

Testing is derived from the changed behavior, not from the size of the module
or the number of nearby tests.

### Test Levels

1. `L0` covers the changed pure logic, parsers, schemas, serialization,
   classifiers, and script syntax. It is required when an applicable harness
   exists; otherwise record the boundary once as `DEFERRED` instead of building
   an unrelated harness inside the task.
2. `Affected L1` covers only the nearest consumers that directly call or
   consume the changed contract. It is selected before editing and updated only
   when a newly discovered direct dependency requires it.
3. `Full regression` is not the default. It requires an explicit release gate,
   a user request, or a shared/public contract change whose impact cannot be
   bounded statically.

### Test Plan And Batch Boundaries

Before `IMPLEMENT`, every `TASK.md` declares the test boundary:

```text
L0 tests:
Affected L1 tests:
Explicitly not run:
Test rationale:
```

A focused test batch is one named filter or one tightly coupled harness
invocation for the same behavior. It is not an entire repository suite or a
collection of unrelated neighboring tests.

The default evidence ownership is:

- Coder: one initial `L0` batch and one initial `Affected L1` batch when
  applicable, plus only the same-cause corrected attempts declared by the task
  envelope;
- Verifier: at most one targeted, read-only review batch, with no rerun of
  unchanged Coder tests.

A completed failing run with readable artifacts is evidence, not a workflow
blocker. Diagnose it inside the same task. A fixture defect, repair-created
compile error, or immediate regression may be corrected and rerun when it stays
inside the declared outcome and attempt envelope. An unrelated failure is
classified once and returned to Planner; it does not trigger automatic repair
or a new task. Any additional evidence class must be justified and authorized,
but same-class attempts already covered by the envelope do not need
command-level approval.

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

The prohibition applies equally to Coder and Verifier. Neither role may use a
hidden/background Unity process to obtain unrequested evidence. When an
authorized Unity MCP call is unavailable or fails, the role must stop the MCP
path and notify the human; it must not perform automatic reconnects, alternate
endpoint attempts, or substitute a direct Unity/CLI probe. The failed gate is
reported as `BLOCKED` or `DEFERRED` with the original error and no release
claim.

### Standard Development Validation Project

`<repository-root>/UnityValidationProject` is the only default EditMode
validation project for UnityCodeDB development. Resolve and record its absolute
path from the current repository root before an authorized run; do not hard-code
another checkout. It is a tracked Unity project with a relative reference to
the sibling `com.rice.ai-codedb` package. Its current declared compatibility
line is Unity `2022.3`.

- The tracked project's presence does not authorize starting Unity. Every run
  still requires the EditMode request below and an exact declared test boundary:
  a focused filter by default, or an explicitly authorized no-filter full gate.
- CodeDB product and runtime behavior must not read or branch on the installed
  Unity Editor version. The package compatibility declaration and the
  validation project's `ProjectVersion.txt` are support/reproducibility
  metadata, not Supervisor, Manager, admission, migration, or lifecycle
  decisions.
- Do not create, copy, regenerate, or substitute another Unity project during
  an implementation slice. If the tracked project is missing or invalid,
  record the requested Unity evidence as `BLOCKED`; do not convert that
  environment result into a product failure.
- Treat `Assets`, `Packages`, and `ProjectSettings` as the validation-project
  contract. Change them only in an explicitly scoped validation-project
  maintenance task. Unity-generated state, logs, and test results remain under
  the project's ignored paths.
- Evidence from this project is development EditMode evidence only. It does not
  replace real consumer-project, third-party Package-only, released-artifact,
  or Codex Desktop acceptance.

Every task that requests Unity must declare an Editor compatibility level before
the process is started:

- `NONE`: the task has no Unity boundary. Do not resolve or start an Editor.
- `LINE`: use a human-approved Editor in the package/project declared
  compatibility line (currently `2022.3`). Record the actual Editor version
  after the run. If opening the project would upgrade or otherwise mutate its
  tracked contract, stop and return the Unity evidence as `BLOCKED` or
  `DEFERRED`.
- `PINNED`: use the exact project-declared Editor version only when the task's
  criterion requires serialization/lifecycle reproducibility, a known
  version-specific behavior, or an explicit release gate. This is a test
  reproducibility condition, not a CodeDB product condition.

The human owns Editor selection and project open/close. Coder and Verifier must
not install, search for, or automatically choose an Editor. A CLI invocation
may use a human-provided executable route for the current run, but must not
invent or persist an environment alias such as `UNITY_EDITOR_*` in order to
hide that route. If no approved Editor route is available, defer or block only
the Unity evidence class.

- `Low`: documentation, configuration, pure logic, parsers, schemas, or static
  harness work. Do not start Unity EditMode.
- `Medium`: an isolated editor API, package contract, or direct consumer whose
  behavior is not fully covered by L0. EditMode may be requested as one focused
  L1 check; it is not automatic.
- `High`: Unity lifecycle, asset import/serialization, scene/project state, or
  multiple Unity boundaries. If that boundary is part of the definition of
  done, an EditMode request is required. A focused filter is the default; a
  no-filter full suite is permitted only when the task explicitly declares a
  full code-freeze or release gate. If the Unity boundary is not part of the
  definition of done, record it as `DEFERRED` instead of starting Unity
  opportunistically.

Every request must state all of the following before the process is started:

```text
Project path:
Purpose and criterion:
Editor compatibility level (NONE, LINE, or PINNED):
Exact command and test boundary (filter or explicit no-filter gate):
Evidence class:
Expected duration / maximum wait:
Cleanup and ownership handoff:
```

The request must receive explicit authorization. The evidence-attempt budget
declared in the task card applies to the approved command, and the result is
labeled `PASS`, `FAIL`, `BLOCKED`, or `DEFERRED`. Unity startup, shutdown, and
any process left after a timeout are recorded in the checkpoint; a timeout
never authorizes an automatic `Stop-Process`.

## Evidence Labels

Every validation result uses one of these labels:

- `PASS`: the declared check ran and met its criterion;
- `FAIL`: the check ran and did not meet its criterion;
- `BLOCKED`: the required environment or prerequisite was unavailable, the
  evidence was missing/corrupt, or execution could not produce a classifiable
  result;
- `DEFERRED`: intentionally outside the current slice;
- `FOLLOW-UP`: observed but unrelated to the current completion boundary.

When a run completes with valid non-passing evidence, use `COMPLETE /
TEST_FAILURE_CLASSIFIED`. When Package, compiler, result persistence, or other
infrastructure evidence explains the completed failure, use `COMPLETE /
INFRASTRUCTURE_FAILURE_CLASSIFIED`. Neither classification is `BLOCKED` merely
because another repair or authorized attempt is needed.

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
- Produce one consolidated `RESULT` for the task outcome. Append same-objective
  diagnosis, repairs, and validation evidence to that result instead of
  creating attempt-level task directories.
- Produce a `CHECKPOINT` only when an interruption, externally owned timeout,
  unavailable prerequisite, session handoff, or evidence contradiction needs
  a durable resume point. A context compaction, elapsed-time signal, parser
  correction, or completed failing test alone does not require one.

Each checkpoint contains only:

```text
Completed:
Actual diff:
Tests and exact results:
Not completed:
Remaining risks:
Next task entry point:
```

Resume the same task from its latest result or checkpoint without reloading the
whole roadmap and all prior tool output. Start a new task only when the split
criteria in `Slice Sizing` are met.

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

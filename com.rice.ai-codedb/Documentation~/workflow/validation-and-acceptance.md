# Development Workflow v2.6 — Validation And Acceptance

This file is a normative module of `codedb-workflow-v2` revision `2.6`.
The stable entry point remains [development-workflow.md](../development-workflow.md);
this module does not create a second workflow or authority.

## Focused Testing And Regression Convergence

Testing is derived from the changed behavior, not from the size of the module
or the number of nearby tests.

An isolated PASS proves only the declared evidence level. Apply the
[Isolation Environment Specification](../../../.ai/workflows/codedb-workflow-v2/isolation-environment-spec.md)
before treating an environment failure as a product finding or promoting an
isolated result to a real-environment or release claim.

### Test Levels

1. `L0` covers the changed pure logic, parsers, schemas, serialization,
   classifiers, and script syntax. It is required when an applicable harness
   exists; otherwise record the boundary once as `DEFERRED` instead of building
   an unrelated harness inside the task.
2. `Affected L1` covers only the nearest consumers that directly call or
   consume the changed contract. It is selected before editing and updated only
   when a newly discovered direct dependency requires it.
   Serialized-record changes use the Record Contract Consumer Closure map;
   language-local acceptance is not evidence for a different runtime reader.
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

- Coder: one initial `L0` scenario and one initial `Affected L1` scenario when
  applicable, plus up to two causally justified corrected semantic attempts
  already covered by the task envelope;
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

Commit, export, project reference switching, push and publish retain explicit
human authorization. A concrete proposal may group named delivery actions;
approval applies only to that group and never grants an unlisted real operation
or release action. For each authorized action:

1. Recheck status, ownership, and focused evidence with commands restricted to
   the authorized files; do not produce a full repository diff.
2. The Code session may present a proposal for the exact operation, including
   commit scope and message when applicable.
3. A human explicitly initiates and authorizes the exact operation or a bounded
   group containing it. Record that grant before execution; do not repeat the
   approval question while the action and its prerequisites remain unchanged.
4. Perform only the authorized action and verify its resulting commit, artifact,
   reference or remote state before proceeding to the next named action.

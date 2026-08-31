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
6. `HANDOFF`: commit, push, publish, or transfer ownership only after explicit
   authorization.

Do not enter a later stage while an earlier stage still has an open decision
that can change the implementation.

## Task Card

Before editing, write a short task card containing:

```text
Task/Slice:
Single outcome:
Requirement source:
In scope:
Out of scope:
Existing dirty files:
Files allowed to change:
Definition of done:
L0 tests:
Directly affected L1 tests:
User-facing acceptance:
Real-environment acceptance:
Forbidden actions:
Stop conditions:
```

The task card is frozen before `IMPLEMENT`. If a new requirement or a new
behavior appears, stop at a checkpoint and create a new slice instead of
silently extending the current one.

## Read-Only Preflight

The beginning of a task is read-only and bounded:

- Check `git status`, branch, `HEAD`, the latest diff, and the relevant roadmap
  section.
- Classify every existing change as owned by the current task or pre-existing.
- Search the named files and their direct references before expanding the
  search surface.
- Prefer line-ranged reads and symbol searches over dumping complete large
  files or generated output.
- Resolve scope, ownership, and acceptance language before editing.

Existing dirty worktree changes are preserved. They are not reset, checked out,
cleaned, or rewritten unless the user explicitly authorizes that exact action.

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

## Implementation Rules

- Use the repository's existing APIs, patterns, and ownership boundaries.
- Use `apply_patch` for manual edits.
- Keep changes semantic and local; do not perform opportunistic refactors,
  compatibility work, or formatting churn.
- Keep comments limited to important or non-obvious behavior.
- Do not add a second source of truth for version, control, or lifecycle policy.
- Do not commit, push, publish, stop external processes, or mutate global
  configuration during implementation unless that action is explicitly
  authorized.
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

## Context And Checkpoints

Keep the active context small and resumable:

- Bound every inspection command; narrow it when output is truncated.
- Do not repeat the complete repository history after an interruption.
- Send a concise progress update at meaningful milestones, not a full log.
- Produce a checkpoint after each slice and before the context budget is
  exhausted.
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

## Acceptance And Handoff

User-facing acceptance must be written in terms a normal user can observe and
perform. Do not ask the user to inspect PIDs, hashes, leases, internal JSON, or
developer logs as the ordinary acceptance procedure.

Real Unity, Codex Desktop, released-artifact, and third-party acceptance are
separate tasks unless the current task explicitly declares them in scope.
Unexecuted gates remain `BLOCKED` or `DEFERRED`; focused tests do not close
them.

Commit, push, and publish are separate `HANDOFF` actions:

1. Recheck status, ownership, diff, and focused evidence.
2. Obtain explicit authorization for the exact operation.
3. Perform only that operation.
4. Verify the resulting commit or remote state.

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

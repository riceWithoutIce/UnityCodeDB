# Development Workflow v2.7

Status: active project workflow (`codedb-workflow-v2`).

Revision `2.7` adds the Artifact Lifecycle And Retention rules for repository-
local generated output while preserving explicit cleanup authorization.
Revision `2.6` removes repeated confirmation between already authorized stages
while preserving human decisions at risk boundaries. Revision `2.5` adds
repository-local development output, backup ownership, Git
tracking, and protected-retention rules. Revision `2.4` added a pre-freeze
Package path-provenance gate. Revision `2.3`
added the Package Release Closure Gate on top of the Package Identity Authority
Gate and hybrid execution-mode routing. The stable workflow ID and existing
task directories remain `codedb-workflow-v2`; do not rewrite frozen tasks
solely to add this revision.

The 2026-10-07 record-contract consumer-closure amendment joins the existing
identity, focused-test and release gates. It does not add a separate workflow,
approval round or implicit external execution grant.

The user-approved 2026-10-15 acceptance-project amendment bounds historical
recovery and permits a separately authorized choice between a new acceptance
project and scoped removal/reset of an existing project. See
[Acceptance Project Baseline And Historical Recovery](#acceptance-project-baseline-and-historical-recovery).

The user-approved 2026-10-19 retention amendment makes necessary issue/evidence
archives the long-term record and bounds complete historical validation-project
retention. See [Validation Project Evidence Retention And Deletion](workflow/safe-execution.md#validation-project-evidence-retention-and-deletion).

The user-approved 2026-10-20 artifact-retention amendment adds lifecycle states,
canonical-output rules, task-level review triggers and staged cleanup checks.
It does not authorize deletion or bulk relocation of existing `.artifacts`
content; each later cleanup pass still names exact targets and retained
evidence.

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

A roadmap, companion document, or task card may narrow product scope, changed
files, evidence, side effects, or execution time. It must not silently weaken
this workflow's safety boundaries or redefine a mechanical command-construction
error as a product-test attempt. A stricter task-local stop or retry rule is
valid only when it names the semantic or side-effect risk and the user approves
that exception explicitly.

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

## Workflow Modules

The detailed rules are split into the following normative modules. The stable
workflow ID, authority order, and compatibility entry point remain in this
file; the modules below are part of the same codedb-workflow-v2 revision.

- [Coordination And Routing](workflow/coordination.md)
- [Task Records And File Layout](workflow/task-records.md)
- [Safe Execution And Route Reassessment](workflow/safe-execution.md)
- [Package Integrity Gates](workflow/package-gates.md)
- [Validation And Acceptance](workflow/validation-and-acceptance.md)
- [Isolation Environment Specification](../../.ai/workflows/codedb-workflow-v2/isolation-environment-spec.md)

## Compatibility Anchors

The detailed sections formerly contained in this file now live in the linked
modules. These short entries preserve the primary section anchors for existing
records and navigation without duplicating their rules.

## Dispatch Protocol

See [Coordination And Routing](workflow/coordination.md#dispatch-protocol).

## Task Card And File Layout

See [Task Records And File Layout](workflow/task-records.md#task-card-and-file-layout).

## Acceptance Project Baseline And Historical Recovery

See [Safe Execution And Route Reassessment](workflow/safe-execution.md#acceptance-project-baseline-and-historical-recovery).

## Focused Testing And Regression Convergence

See [Validation And Acceptance](workflow/validation-and-acceptance.md#focused-testing-and-regression-convergence).

## Unity EditMode Authorization

See [Validation And Acceptance](workflow/validation-and-acceptance.md#unity-editmode-authorization).

## Acceptance And Handoff

See [Validation And Acceptance](workflow/validation-and-acceptance.md#acceptance-and-handoff).

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

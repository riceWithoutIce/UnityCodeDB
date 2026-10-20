# Development Workflow v2.6 — Task Records And File Layout

This file is a normative module of `codedb-workflow-v2` revision `2.6`.
The stable entry point remains [development-workflow.md](../development-workflow.md);
this module does not create a second workflow or authority.

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
- Workflow: codedb-workflow-v2
- Workflow revision: 2.6
- Status: READY | DOING | COMPLETE | PARTIAL | BLOCKED | DEFERRED | ROUTE_REASSESSMENT_REQUIRED
- Planner:
- Coder:
- Verifier: optional
- Review mode: NORMAL | GUARDED | RELEASE
- Execution mode: FAST_SUBAGENT | DURABLE_SESSION
- Execution profile: <profile-id from the session profile map>
- Delegation authorization: NOT_AUTHORIZED | TASK_SPECIFIC | STANDING_WORKFLOW
- Session policy: SPAWN_BOUNDED | REUSE_ONLY | MANUAL_PROVISION
- Requirement source:

## Objective
- Single outcome:

## Scope
- In scope:
- Out of scope:
- Change allowlist:
- Read-only dependency closure: DIRECT_REFERENCES_ONLY | <exact paths>
- Protected state:
- Snapshot binding: optional; only for GUARDED/RELEASE

## Execution Envelope
- Mode: CONTINUOUS_WITHIN_SCOPE
- Approved stages and user grant: <stages, attributable approval and exclusions>
- Delivery authorization: NONE | <explicit actions, targets, prerequisites and stop conditions>
- Coder actions:
- Evidence scenarios:
- L0 tests:
- Affected L1 tests:
- Explicitly not run:
- Test rationale:
- EditMode authorization: NOT_REQUESTED | authorized
- Mechanical corrections per scenario: 2
- Corrected semantic attempts per local evidence scenario: 2
- Independent product causes before reassessment: 2
- Active time budget: STANDARD_30M | DEEP_60M | <explicit exception>
- Output budget: V2_DEFAULT | <explicit exception>
- Broad search/full diff/full regression: FORBIDDEN | <exact exception>
- Side-effect authorization: external process, persistent state, or none
- Stop conditions:
- Escalation triggers:
- Mode-promotion triggers: DEFAULT_V2_1 | <narrower explicit triggers>
- Structural escalation guard: starting repair count <count>/2; starting independent product-cause count <count>/2; starting consecutive diagnostic-only checkpoint count <count>/3; immediate structural triggers apply
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

The reusable skeletons live under `.ai/workflows/codedb-workflow-v2/`. Use
`TASK.template.md`, `RESULT.template.md`, and `VERIFICATION.template.md`
instead of copying a historical task. Those templates are recording aids; this
document remains the normative workflow source.

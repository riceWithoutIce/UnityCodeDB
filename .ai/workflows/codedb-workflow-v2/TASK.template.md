# Task: <task-id>

## Metadata

- Product:
- Version:
- Workflow: codedb-workflow-v2
- Status: READY
- Planner:
- Coder:
- Verifier: optional
- Review mode: NORMAL | GUARDED | RELEASE
- Execution profile: v<version>.<role>.<level>
- Session policy: REUSE_ONLY | MANUAL_PROVISION
- Requirement source:

## Objective

- Single independently acceptable outcome:

## Scope

- In scope:
- Out of scope:
- Change allowlist:
- Read-only dependency closure: DIRECT_REFERENCES_ONLY | <exact paths>
- Protected state:
- Snapshot binding: optional; required for GUARDED/RELEASE handoff

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE
- Coder actions:
- Evidence scenarios:
- L0 tests:
- Affected L1 tests:
- Explicitly not run:
- Test rationale:
- Mechanical corrections per scenario: 2
- Corrected semantic attempts per local evidence scenario: 2
- Independent product causes before reassessment: 2
- Active time budget: STANDARD_30M | DEEP_60M | <explicit exception>
- Output budget: V2_DEFAULT | <explicit exception>
- Broad search/full diff/full regression: FORBIDDEN | <exact exception>
- EditMode authorization: NOT_REQUESTED | <exact human-authorized envelope>
- Side-effect authorization: NONE | <exact external/persistent action>
- Stop conditions:
- Escalation triggers:
- Structural escalation guard: repairs <count>/2; independent causes <count>/2;
  diagnostic-only checkpoints <count>/3; immediate structural triggers apply
- Model escalation: NONE | REQUEST_ONLY | HUMAN_APPROVED

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

The task authorizes the complete envelope, not individual commands. A
task-local zero-retry or first-failure stop is valid only for an explicitly
named semantic assertion or side effect with a human-approved risk rationale;
it never disables the workflow's mechanical-correction allowance.

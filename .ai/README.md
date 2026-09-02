# UnityCodeDB AI Development Artifacts

This directory contains version-controlled planning, execution, verification,
checkpoint, and decision artifacts for the UnityCodeDB repository. It is
process metadata only. It is not package runtime state, generated output, or a
second implementation source of truth.

## Authority

The authority order for an active task is:

1. The current user's explicit instruction.
2. `com.rice.ai-codedb/Documentation~/development-workflow.md`.
3. The active version roadmap and its scoped companion documents.
4. The packet files under this directory.

The workflow document remains the CodeDB execution authority. The templates
below encode its packet shape and do not copy or replace the workflow rules.

## Template version

The current packet templates are grouped under:

```text
.ai/templates/codedb-workflow-v1/
```

Increase the workflow template directory when packet semantics change. A
product version change alone does not require a new template directory.

## Roles

Roles are logical responsibilities. Session names are aliases for traceability
and are not task identities.

```text
Planner:  UnityCodeDB v0.3 Planner
Coder:    UnityCodeDB v0.3 Coder
Verifier: UnityCodeDB v0.3 Verifier
```

Future product versions may use corresponding version-specific sessions. A
session replacement updates the relevant result or checkpoint metadata; it does
not rename or rewrite a frozen TASK.

## Packet flow

```text
TASK -> RESULT -> VERIFICATION -> DECISION
          ^             |
          |             +-- a recheck creates a new verification attempt
          +-- a checkpoint may be recorded during execution
```

`TASK` is frozen before implementation. `RESULT` reports Coder facts and does
not accept the task. A `RESULT` may contain a commit proposal, but it never
authorizes a commit. `VERIFICATION` is read-only evidence bound to an exact
SHA. `DECISION` records the user's accept, fix, defer, or stop decision.

## Completion Routing

Every terminal task handoff appends the following footer to the relevant packet
and the session's completion message:

```text
Current task:
Current status:
Next notification:
Next action:
Human decision or authorization required:
```

The footer identifies the next role/session and bounded action in order. It is
an explicit coordination record only; it does not automatically dispatch,
poll, wait, duplicate, or interrupt another session. `WAITING_FOR_USER_DECISION`
is used when no session should be notified yet.

Default routing is Coder -> Planner for completed implementation, Planner ->
Verifier for review, and Verifier -> Planner/User for findings and disposition.
A session may record this route, but it must not bypass the routing owner or
turn the footer into an automatic cross-session dispatch.

## Task storage

Create a task directory only when a task is frozen:

```text
.ai/tasks/v0.3/<task-id>/
  TASK.md
  results/
  verifications/
  checkpoints/
  decisions/
```

Use `.ai/tasks/shared/` for a task whose contract intentionally spans product
versions. The task ID is immutable and must not contain a session name.

## Version control rules

- Templates and concise packet records are tracked.
- Checkpoints are tracked; raw logs and temporary command output are not.
- Do not store secrets, machine identities, or unnecessary absolute paths.
- Do not put generated Unity state, Provider state, or runtime files here.
- Do not overwrite an existing result, verification attempt, or decision.
- Code sessions must not auto-commit after implementation. A human must
  explicitly initiate the exact commit operation; push and publish require
  separate confirmation.
- Implementation commits must not silently include administrative packet files.

The default budget profile and validation boundaries come from the project
workflow. A task records only its profile and any explicitly authorized
override.

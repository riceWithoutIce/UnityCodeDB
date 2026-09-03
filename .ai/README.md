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
4. The task records under this directory.

The workflow document remains the CodeDB execution authority. The task
structure below records task-specific scope and evidence without copying or
replacing the workflow rules.

## AIServer Context

AIServer memory and wiki results are optional historical context and may be
stale. Queries are off by default. Perform one only when the current user
explicitly requests it or a frozen task card names it as required evidence.
Keep an authorized query narrow, label its result as memory/wiki-derived, and
verify it against the current repository or live evidence. Do not repeatedly
query unchanged context or treat a stale result as a scope, test, or release
decision.

## Roles And Trust

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

Each task declares `NORMAL`, `GUARDED`, or `RELEASE` review mode. `NORMAL`
trusts the Coder's bounded result and avoids rerunning unchanged tests;
`GUARDED` adds one targeted Verifier review; `RELEASE` requires independent
acceptance evidence. Trust never authorizes scope expansion, commit, push, or
release claims.

## Session Profiles

The versioned logical profile catalog is
`.ai/workflows/codedb-workflow-v1/profile-map.md`. Task cards reference a
profile key rather than a thread ID:

```text
v0.3.coder.standard
v0.3.verifier.standard
v0.3.coder.deep
v0.3.verifier.deep
```

`standard` uses `gpt-5.6-sol/high`; `deep` currently uses `gpt-5.6-sol/max`
as a provisional trial setting. Each profile has capacity `1` and manual-only
provisioning. A busy, unknown, or missing binding is `DEFERRED`/`BLOCKED`; the
router does not create, duplicate, interrupt, or silently downgrade a session.
Profile selection does not grant Unity, test expansion, commit, push, or release
authority. Actual thread bindings and live status are runtime data, not task
identity.

## Unity Safety

Coder and Verifier sessions never create a Unity project, launch Unity, or run
Unity validation in a hidden or background process. The standard validation
project and a task card do not authorize a Unity run; an explicit request must
name the project, criterion, command/filter, wait limit, and cleanup owner.

When Unity MCP is unavailable or a required MCP call fails, the session stops
that evidence path, preserves the original error, and notifies the human. It
does not retry in the background, switch endpoints, create a substitute
project, or relabel a direct probe as Unity/MCP evidence. The gate is recorded
as `BLOCKED` or `DEFERRED`.

## Test Scope

Every `TASK.md` names its `L0` tests, directly affected `L1` tests, explicitly
unrun tests, and the rationale for the boundary. A focused batch is one named
filter or one tightly coupled harness for the same behavior, not a full
repository suite.

By default, Coder runs at most one `L0` batch and one `Affected L1` batch.
Verifier runs at most one targeted read-only review batch and does not rerun
unchanged Coder tests. A concrete failure may receive one corrected retry;
additional batches require an authorized task-card exception, and a second
independent behavior or blocker requires a checkpoint or new task.

## Task Flow

```text
TASK -> RESULT -> (optional VERIFICATION) -> (optional DECISION)
  ^
  +-- CHECKPOINT is created only for interruption, timeout, budget stop, or recovery
```

`TASK` is frozen before implementation. `RESULT` reports Coder facts and does
not accept the task. A `RESULT` may contain a commit proposal, but it never
authorizes a commit. `VERIFICATION` is read-only targeted evidence when the
task's review mode requires it. `DECISION` records a human disposition when one
is needed.

## Completion Routing

Every terminal task handoff appends the following footer to the relevant task
record and the session's completion message:

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
.ai/tasks/<version>/<task-id>/
  TASK.md
  RESULT.md            # Coder terminal result or blocking report
  VERIFICATION.md      # only for GUARDED/RELEASE or explicit request
  DECISION.md          # only when a human disposition is needed
  CHECKPOINT.md        # only for interruption/recovery
```

Use `.ai/tasks/shared/<task-id>/` for a task whose contract intentionally spans
product versions. The task ID is immutable and must not contain a session name.
Do not create empty optional files. Raw logs and generated output stay outside
the task documents.

## TASK.md Minimum Shape

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
- Stop conditions:
- Escalation triggers:
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

`RESULT.md` and `VERIFICATION.md` use only four sections: outcome, evidence,
risks/findings, and handoff. The complete field rules live in the project
workflow rather than being duplicated in every task.

## Version control rules

- Concise task records are tracked.
- Checkpoints are tracked; raw logs and temporary command output are not.
- Do not store secrets, machine identities, or unnecessary absolute paths.
- Do not put generated Unity state, Provider state, or runtime files here.
- Do not overwrite an existing result, verification attempt, or decision.
- Code sessions must not auto-commit after implementation. A human must
  explicitly initiate the exact commit operation; push and publish require
  separate confirmation.
- Implementation commits must not silently include administrative task files.
- The logical session profile map is versioned; volatile thread bindings and live
  status stay outside frozen task identity and are not copied into task cards.
- Routine `git diff`, full history scans, and repeated status checks are not
  required. Use a targeted Git check only when the task's review mode or an
  explicitly requested commit requires it.

The default budget profile and validation boundaries come from the project
workflow. A task records only its profile and any explicitly authorized
override.

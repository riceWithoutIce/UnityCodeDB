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

The current rules revision is `2.5`; the stable workflow identifier remains
`codedb-workflow-v2` so existing frozen tasks do not require migration.

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

## Execution Profiles

The versioned logical profile catalog is
`.ai/workflows/codedb-workflow-v2/profile-map.md`. Task cards reference a
profile key rather than a thread ID:

```text
v0.3.coder.standard
v0.3.verifier.standard
v0.3.coder.deep
v0.3.verifier.deep
```

`standard` uses `gpt-5.6-sol/high`; `deep` currently uses `gpt-5.6-sol/max`
as a provisional trial setting. Profiles describe role, model, reasoning, and
budget; they can be carried by an authorized task-scoped child or an existing
durable session. Durable sessions retain capacity `1` and manual-only
provisioning. A busy, unknown, or missing durable binding is
`DEFERRED`/`BLOCKED`; the router does not duplicate, interrupt, silently
downgrade, or auto-create a replacement session. Profile selection does not
grant delegation, Unity, test expansion, commit, push, or release authority.
Actual thread bindings and live status are runtime data, not task identity.

## Hybrid Execution Modes

New tasks declare one execution mode:

| Mode | Use |
| --- | --- |
| `FAST_SUBAGENT` | One bounded, continuous, task-scoped Coder/Verifier pipeline with a frozen allowlist and no human environment wait. |
| `DURABLE_SESSION` | Architecture, route reassessment, multi-turn history, human Unity/external handoff, release, or durable independent review. |

`FAST_SUBAGENT` is depth one and single writer. Planner may spawn at most one
Coder child, admit its stopped snapshot, then spawn at most one read-only
Verifier child. They never write concurrently and neither child may recursively
delegate. Planner owns task/route/decision records, Coder owns allowlisted
implementation and `RESULT.md`, and Verifier owns only `VERIFICATION.md`.

Every child requires the delegation state recorded in the frozen task:
`TASK_SPECIFIC` or a separately granted `STANDING_WORKFLOW`. Otherwise the
state is `NOT_AUTHORIZED` and Planner asks the human before spawning. A child
that reaches architecture/scope expansion, structural reassessment, a human
Unity/external handoff, a release gate, or another continuity boundary returns
`MODE_PROMOTION_REQUIRED` and stops. Planner decides the durable route; the
child does not self-promote.

Current project delegation status: `STANDING_WORKFLOW / ACTIVE`, granted
`2026-09-16` under the limits in the authoritative workflow. This authorizes
eligible task-scoped child creation only; all Unity, Git publication, release,
scope-expansion, destructive-action, and durable-session gates remain intact.

Durable session history is useful context, but Markdown remains the source of
handoff truth in both modes. Important decisions, identities, findings,
deferred evidence, and the next-role pointer must be recorded in the task
packet.

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

Every `TASK.md` names its evidence scenarios, `L0` tests, directly affected
`L1` tests, explicitly unrun tests, and the rationale for the boundary. A
focused scenario is one named filter or one tightly coupled harness for the
same behavior, not a full repository suite. Attempt counts, correction rules,
review limits, and route reassessment are defined by the project workflow and
recorded through the v2 templates; this index does not duplicate them.

## Package Identity Authority

Tasks that change Package, payload, generation, pointer, instance, or release
identity must declare one canonical contract route and its language-specific
readers. Runtime scripts may validate or project that contract but may not
carry independent version or sequence literals. Package-boundary evidence must
verify the complete package/payload/pointer/generation/instance closure and
scan direct consumers for duplicated identity declarations.

Immutable generations are successor-only after freeze or external observation.
An identity mismatch found in an external consumer is a structural finding:
stop retries, preserve the failed generation and runtime evidence, and route a
single authority-refactor task before any further Unity or Package acceptance.

## Task Flow

```text
TASK -> RESULT -> (optional VERIFICATION) -> (optional DECISION)
  ^
  +-- CHECKPOINT is created only for an external interruption/block, handoff, or evidence contradiction

TASK/RESULT -> ROUTE-REASSESSMENT -> HUMAN DECISION
               (only when the structural escalation gate triggers)
```

`TASK` is frozen before implementation. `RESULT` reports Coder facts and does
not accept the task. A `RESULT` may contain a commit proposal, but it never
authorizes a commit. `VERIFICATION` is read-only targeted evidence when the
task's review mode requires it. `DECISION` records a human disposition when one
is needed. `ROUTE-REASSESSMENT` freezes repeated-blocker evidence and returns
the route to Planner/User before more patches, tests, or Verifier work.

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
an explicit coordination record only and never grants delegation. Durable
session routing does not automatically dispatch, poll, wait, duplicate, or
interrupt another session. Under an already authorized `FAST_SUBAGENT` task,
Planner may perform the depth-one child lifecycle without busy polling or
duplicate dispatch. `WAITING_FOR_USER_DECISION` is used when no role should be
notified yet.

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
  ROUTE-REASSESSMENT.md # only after the structural escalation gate triggers
  CHECKPOINT.md        # only for interruption/recovery
```

Use `.ai/tasks/shared/<task-id>/` for a task whose contract intentionally spans
product versions. The task ID is immutable and must not contain a session name.
Do not create empty optional files. Raw logs and generated output stay outside
the task documents.

## TASK.md Minimum Shape

Use the versioned recording templates instead of copying a historical task:

- `.ai/workflows/codedb-workflow-v2/TASK.template.md`
- `.ai/workflows/codedb-workflow-v2/RESULT.template.md`
- `.ai/workflows/codedb-workflow-v2/VERIFICATION.template.md`

The templates do not define authority. Their field meanings, default budgets,
continuation rules, and stop conditions come only from
`com.rice.ai-codedb/Documentation~/development-workflow.md`.

When the route-reassessment gate triggers, Coder stops the affected repair and
records the frozen identity and evidence. Planner creates
`ROUTE-REASSESSMENT.md`; the user chooses `CONTINUE_PATCH`, `REFACTOR`,
`REDESIGN`, `DEFER`, or `STOP`. Numeric thresholds are mandatory escalation
limits, not patch quotas. The authoritative triggers, counters, document shape,
and role boundaries are defined in the project workflow.

## Version control rules

- Repository-owned export copies belong under root `.artifacts/`; residual
  recovery copies belong under root `.backups/`. Both storage roots are ignored
  by Git, but are not disposable. Track concise provenance, consumer references,
  hashes, and retention decisions in existing task records instead of copying
  raw output or backup trees here. The normative destination, exception, and
  migration rules are in the workflow's "Repository-Local Development Artifacts
  And Backups" section; this index does not authorize a migration or cleanup.
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

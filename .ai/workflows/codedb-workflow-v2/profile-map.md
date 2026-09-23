# UnityCodeDB Execution Profile Map

Status: active routing catalog for `codedb-workflow-v2`, revision `2.3`.

This file maps stable logical profiles to bounded execution budgets for both
task-scoped child agents and durable sessions. It does not authorize child
creation, create durable sessions, dispatch tasks, grant write authority, or replace
`com.rice.ai-codedb/Documentation~/development-workflow.md`.

Current delegation state: `STANDING_WORKFLOW / ACTIVE` (user-granted
`2026-09-16`). It applies only to tasks admitted as `FAST_SUBAGENT` by the
normative workflow and is not durable-session provisioning or broader action
authority.

## Scope And Authority

- Product line: UnityCodeDB v0.3 (`v0.3.0`)
- Workflow: `codedb-workflow-v2`
- Normative workflow source:
  `com.rice.ai-codedb/Documentation~/development-workflow.md`
- Task-specific source: the frozen `TASK.md`
- Profile key: `v<version>.<role>.<level>`

Profiles identify role/model/budget lanes, not thread IDs or execution modes.
Model strength and active time never widen file scope, evidence scope, Unity
permission, side effects, commit authority, or release authority.

## Logical Profiles

| Profile | Role | Model | Reasoning | Active time | Capacity | Durable binding | Fallback |
| --- | --- | --- | --- | ---: | ---: | --- | --- |
| `v0.3.coder.standard` | Coder | `gpt-5.6-sol` | `high` | 30 min | 1 | manual-only | `BLOCKED` |
| `v0.3.verifier.standard` | Verifier | `gpt-5.6-sol` | `high` | 15 min | 1 | manual-only | `BLOCKED` |
| `v0.3.coder.deep` | Coder | `gpt-5.6-sol` | `max` (trial) | 60 min | 1 | manual-only | `BLOCKED` |
| `v0.3.verifier.deep` | Verifier | `gpt-5.6-sol` | `max` (trial) | 30 min | 1 | manual-only | `BLOCKED` |

`max` remains a provisional experience setting. Changing it requires a later
human decision based on task time, rework, and review scope.

## Selection Guidance

- Use `standard` for one known behavior with named files and focused evidence.
- Use `deep` for a coherent cross-layer contract, unresolved ambiguity,
  conflicting evidence, P0 risk, or release review.
- Do not select `deep` merely because a command is slow or a test failed.
- At the active-time limit, finish only the current bounded,
  non-side-effecting operation, start no new work, and return a consolidated
  result or review.

## Binding And Dispatch

- `DURABLE_SESSION`: resolve the profile to one existing, compatible, idle
  session immediately before dispatch. Capacity `1` is a hard limit. A busy,
  unknown, missing, or incompatible lane is `DEFERRED` or `BLOCKED`; do not
  duplicate, interrupt, silently downgrade, or reroute it. Creation,
  replacement, and rebinding remain manual provisioning actions.
- `FAST_SUBAGENT`: after the frozen task records `TASK_SPECIFIC` or
  `STANDING_WORKFLOW` delegation, Planner may create one task-scoped child for
  the active role using the selected profile. The child is not a new durable
  binding. At most one Coder and one later Verifier child exist for the task;
  depth is `1`, recursive spawning is forbidden, and their write phases never
  overlap.
- After durable dispatch, do not poll, wait, append follow-ups, or duplicate the
  active task. For a task-scoped child, Planner may use the orchestration wait
  path but must not busy-poll, duplicate the child, or edit its owned record.
  Resume routing only after a terminal result, real checkpoint, explicit user
  request, or platform attention event.
- The route remains Coder -> Planner -> Verifier -> Planner/User. Verifier does
  not dispatch repairs directly.

## Mode Selection

- Use `FAST_SUBAGENT` for one frozen bounded outcome expected to converge in a
  continuous working window without human Unity/external handoff, route
  reassessment, release promotion, or scope expansion.
- Use `DURABLE_SESSION` for architecture/redesign, cross-layer authority,
  repeated blockers, multi-turn or human-owned environment work, release, and
  durable independent review.
- A child returns `MODE_PROMOTION_REQUIRED` rather than creating a session or
  continuing when a durable-mode condition appears.
- Existing frozen tasks without an execution-mode field remain
  `DURABLE_SESSION`; do not rewrite them for this catalog revision.

Thread IDs, host IDs, worktree paths, and live status are runtime data and must
not be copied into a frozen task card. Each terminal result records the actual
model and reasoning effort used.

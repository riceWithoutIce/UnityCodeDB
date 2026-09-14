# UnityCodeDB Session Profile Map

Status: active routing catalog for `codedb-workflow-v2`.

This file maps stable logical profiles to bounded execution budgets. It does
not create sessions, dispatch tasks, grant write authority, or replace
`com.rice.ai-codedb/Documentation~/development-workflow.md`.

## Scope And Authority

- Product line: UnityCodeDB v0.3 (`v0.3.0`)
- Workflow: `codedb-workflow-v2`
- Normative workflow source:
  `com.rice.ai-codedb/Documentation~/development-workflow.md`
- Task-specific source: the frozen `TASK.md`
- Profile key: `v<version>.<role>.<level>`

Profiles identify reusable lanes, not thread IDs. Model strength and active
time never widen file scope, evidence scope, Unity permission, side effects,
commit authority, or release authority.

## Logical Profiles

| Profile | Role | Model | Reasoning | Active time | Capacity | Provisioning | Fallback |
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

- Resolve the profile to one existing, compatible, idle session immediately
  before dispatch.
- Capacity `1` is a hard limit. A busy, unknown, missing, or incompatible lane
  is `DEFERRED` or `BLOCKED`; do not duplicate, interrupt, silently downgrade,
  or reroute it.
- Session creation, replacement, and profile rebinding are manual provisioning
  actions. Automation must remain reuse-only.
- After dispatch, do not poll, wait, append follow-ups, or duplicate the active
  task. Resume coordination only after a terminal result, real checkpoint,
  explicit user request, or platform attention event.
- The route remains Coder -> Planner -> Verifier -> Planner/User. Verifier does
  not dispatch repairs directly.

Thread IDs, host IDs, worktree paths, and live status are runtime data and must
not be copied into a frozen task card. Each terminal result records the actual
model and reasoning effort used.

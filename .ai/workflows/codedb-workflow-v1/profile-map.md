# UnityCodeDB Session Profile Map

Status: active routing catalog for the `codedb-workflow-v1` process.

This file defines stable logical profiles for UnityCodeDB v0.3 Coder and
Verifier sessions. It does not create sessions, dispatch tasks, grant write
authority, or replace `com.rice.ai-codedb/Documentation~/development-workflow.md`.

## Scope And Authority

- Product line: UnityCodeDB v0.3 (`v0.3.0`)
- Workflow: `codedb-workflow-v1`
- Normative workflow source: `com.rice.ai-codedb/Documentation~/development-workflow.md`
- Task-specific source: the frozen `TASK.md` for the current task
- Profile key: `v<version>.<role>.<level>`

The profile key is stable across session replacement. A task must reference the
profile key, not a thread ID or a transient session title.

## Logical Profiles

| Profile | Role | Model | Reasoning | Capacity | Provisioning | Fallback |
|---|---|---|---|---:|---|---|
| `v0.3.coder.standard` | Coder | `gpt-5.6-sol` | `high` | 1 | manual-only | `BLOCKED` |
| `v0.3.verifier.standard` | Verifier | `gpt-5.6-sol` | `high` | 1 | manual-only | `BLOCKED` |
| `v0.3.coder.deep` | Coder | `gpt-5.6-sol` | `max` (trial) | 1 | manual-only | `BLOCKED` |
| `v0.3.verifier.deep` | Verifier | `gpt-5.6-sol` | `max` (trial) | 1 | manual-only | `BLOCKED` |

`max` is a provisional experience setting. Lowering it to `xhigh` or `high`
requires a later human decision based on observed task time, rework, and review
scope. A profile level never authorizes Unity, broader tests, commits, pushes,
or release claims.

## Selection Guidance

- Use `standard` for a bounded task with a known behavior, named files, and a
  focused evidence plan.
- Use `deep` for cross-layer contracts, unresolved ambiguity, conflicting
  evidence, P0 risk, or formal release review.
- A deep profile is an explicit task choice or an approved escalation, not an
  automatic response to a slow command or a missing test result.
- The Coder and Verifier role boundaries remain unchanged when a deep profile
  is selected.

## Binding And Dispatch Rules

- The routing owner resolves a task's profile to an existing session binding
  before dispatch.
- A binding may be reused only after one bounded check confirms that the target
  is idle and its workspace/snapshot is compatible with the task.
- `Capacity` is a hard upper bound for active bindings. The dispatcher must not
  create another session when a profile is busy, unknown, or unavailable.
- A busy or unknown target is reported as `DEFERRED` or `BLOCKED`; it is not
  duplicated, interrupted, silently downgraded, or routed to another role.
- Session creation and profile replacement are manual provisioning actions.
  Any future wrapper must use `auto_create=false` and `reuse_only=true`.
- A profile change during an active task requires a checkpoint and an explicit
  human approval before a new turn is started.
- The normal routing chain is Coder -> Planner -> Verifier -> Planner/User.
  Verifier never dispatches a repair directly to Coder.
- After dispatch, the management session does not poll, wait, append a follow-up,
  or duplicate the active task.

## Runtime Binding

Thread IDs, host IDs, worktree paths, live status, and current task ownership
are runtime data. They are not task identity and must not be copied into a
frozen `TASK.md`. If a local binding registry is introduced for a wrapper, it
must be keyed by profile, kept outside the versioned rule documents, and updated
manually when a session is replaced.

Each terminal result records the actual model and reasoning effort used. A
model mismatch is reported to the routing owner; it does not authorize a blind
rerun.

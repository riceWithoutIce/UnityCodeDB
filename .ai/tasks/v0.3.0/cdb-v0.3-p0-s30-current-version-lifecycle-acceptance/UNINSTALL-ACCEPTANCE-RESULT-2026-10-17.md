# S30 one-request real uninstall acceptance — 2026-10-17

Status: BACKEND LOGICAL UNINSTALL PASS / MANAGER RESULT CLOSURE BLOCKED.

## Grant And Scope

User `好的 同意` approved the concrete one-request proposal in
UNINSTALL-ACCEPTANCE-PLAN-2026-10-17.md. Parent owns targeted preparation and
read-only postchecks; User owns Unity startup and one explicit uninstall
confirmation. No further permission is needed inside this envelope.
No agent executes a lifecycle command or terminates processes. No second
attempt, reinstall, package export/reference change or recovery expansion.

## Fresh Baseline And Backup

- Project: `UnityFreshLifecycleValidationProjectS30`.
- Manifest and lock still select the cc49c95 exact Package extraction.
- Fresh desired state remains INSTALLED/PENDING and has the planned state ID.
- Current instance, activation epoch, generation poc.43 and actual selected
  manifest hash all match the approved preparation baseline.
- UnityLockfile absent during preparation. Opening Unity belongs to User.
- Backup: `.backups/s30-uninstall-20261017-152826/`.
  Exactly four files copied with their project-relative structure. All source
  and backup SHA-256 values matched before/after copying; backup is Git-ignored.

| Project-relative file | SHA-256 |
| --- | --- |
| `AIWork/.runtime/codedb/control/desired-state.json` | `12ea9a95cdf65e2f6074597f668fde38644e18a0d4b57b36e0295ae545335ab9` |
| `AIWork/.runtime/codedb/control/current-instance.json` | `4ddaaf30494676b32ad18380b514c7aaa5d9ff5aed5af40ca02f2592f51b3417` |
| `AIWork/.runtime/codedb/instances/3d3c1c70c59a4268bd453a735b63ee2c/instance.json` | `4b89517d74bd9d6f3e83a031d7668d9c54d3a4537029713d8b6b4cc7cc92a1f3` |
| `.codex/config.toml` | `6fc5bec9b869296c829112f899d91e30f4e531666e440272eafafc66f761bf83` |

Configuration content was not printed. No installation/runtime files were
changed by preparation. No tests or lifecycle scripts were executed.

## Human Handoff

Open S30 and Manager. Click Overview `Uninstall CodeDB from Project` once and
confirm once. Observe the original action to a result without another click,
Install or force-closing a potentially active operation. Report its exact
result/detail and any Console error. If blocked/error/unknown/stuck, report
that state without retry; the parent will inspect the attributable evidence.

Once the original action reports successful uninstall, Manager reopen may
verify Install as the primary action and Uninstall still in its header menu;
do not execute Install. No repeat Test Runner session is requested.

## Outcome

- User reports no error; supplied screenshot shows the uninstalled product
  presentation but `Outcome unconfirmed`, a missing Supervisor state message,
  and a warning blocking new project changes. Install is not offered normally.
- Manager action: `1e53bbcf798241c48f72b8bfa8ee2e30`.
- Its exact Supervisor action map names operation
  `36d0c70eacb7489c94d36b1b58ba1b50`.
- Operation history binds that same action, S30 project, delivered Package
  invocation, original instance and runtime contract. State is `completed`,
  exit_code 0, stderr empty, timed_out false. Structured result is
  UNINSTALL / UNINSTALLED / COMPLETE / LOGICAL_UNINSTALL_COMPLETE, cleanup PENDING.
- Actual desired state is UNINSTALLED/PENDING; current-instance.json is absent.
- Original instance.json remains with unchanged authenticated hash.
- Project MCP config has no active CodeDB table. Every nonempty line is
  commented with the exact uninstall-state prefix; decoding that prefix restores
  the original backed-up config apart from trailing newlines. Configuration
  content was not printed. No unrelated active section existed in the baseline.
- These checks establish logical uninstall and retained-content disposition.
  No full index/provider tree comparison or independent external-process
  lifecycle acceptance is claimed.
- Manager index for the same action remains `pending`. Its compact action
  receipt root has only action.json, no stage terminal receipt. Supervisor's
  durable operation history nevertheless contains the successful result.
- End-to-end acceptance remains BLOCKED because the original action is not
  closed in Manager and normal subsequent project changes remain blocked.
- One authorized human attempt used; no retry or further mutation authorized.

## Bounded Causal Finding

The durable uninstall operation completed at 07:40:17.392Z, with handoff queued
for `selected_instance_changed`. Supervisor event sequence 21 records uninstall
completion; sequence 22 at 07:40:17.483Z records retirement for
`selected_instance_changed_observed`. Current supervisor-state.json is absent.

Delivered `AICodedbSupervisorBridge.WaitForAcceptedOperation` polls the original
Supervisor pipe for the operation result. Its `RecoverManagerActionAsync` also
queries that Supervisor (`manager_action_operation`, startIfMissing=false).
Supervisor shutdown removes its owned runtime state. Thus normal uninstall
can persist its successful outcome and retire before Manager observes it;
the remaining Manager path lacks a confirmed result after that endpoint is gone.
This explains the observed missing-state/unknown-outcome boundary. No precise
IPC exception timing or unrelated process cause is inferred from the screenshot.

The separate queued Probe was invalidated after selection changed; it has no
manager_action_id and is not the terminal result of this uninstall. No historical
candidate investigation is required to explain the current failure.

## Preserved Evidence And Disposition

Seven exact, hash-verified records copied into ignored
`.artifacts/s30-uninstall-20261017-1e53bbcf/`: post desired state, removal intent,
Manager action metadata and pending index, Supervisor action map, exact completed
uninstall operation, and its event log. No live evidence was edited or released.
Uninstall operation SHA-256:
`33ea10cba7b769a724f3d8319913053db0a2cf1e334e829f2570bb0b41aa34dd`.
Pending Manager index SHA-256:
`f358a22ec7bea22d1d1e5b1a6c526d6d823bdd7bef1e3fb0ac4a5792e59cffa6`.

Next recommendation: align a bounded current-operation terminal-delivery repair
so an authenticated completed uninstall can close its exact Manager session
after Supervisor retirement. Preserve identity checks and refuse missing,
conflicting or nonterminal evidence. Do not infer success from UNINSTALLED
alone, manually delete the index, restart Supervisor just to query history,
rerun uninstall/Install, or broaden into historical reconnect/Provider/S31-B.
Source repair, delegation and delivery have not been authorized by this result.

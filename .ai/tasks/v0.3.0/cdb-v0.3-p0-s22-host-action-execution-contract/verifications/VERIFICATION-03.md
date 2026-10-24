# S22 GUARDED Source Verification 03

## Verdict

**FAIL**. The frozen source identity is stable and the reviewed Manager,
direct-writer, Supervisor-correlation, fallback, multistage, and readiness
paths are present. One adjacent P1 remains: receipt recovery accepts a
terminal record without validating the full writer/child-process evidence
required by the frozen contract.

This is a bounded source review. It is not C# semantic compile, Editor/EditMode,
Unity, external-action, commit-derived Package, or release acceptance.

## Admission Identity

- HEAD: `6b64f27adb51eeab8394aac6bca722117ac6863c` (matched).
- Ordered tracked 13-path binary-diff Git blob: `5867991f75878ea932e67b0a264aa0267faf2750` (matched).
- New writer Git blob: `1072cb06b529fc47271c51a39025076252c5ab1e` (matched).
- Composite SHA-256 of the recorded UTF-8 identity input: `a296d312f676664947660a91493d92e84313c30ba2a770f39afbc364f4a8b43c` (matched).
- The tracked blob was confirmed with a raw-byte `git diff HEAD --binary -- <ordered 13 paths> | git hash-object --stdin` pipeline; no identity drift was observed.

## Review Scope And Conclusions

### Manager admission/reentry

**PASS within source scope.** `AICodedbManagerActionSession.TryStart` restores
the durable pending marker and rejects a running or recovering session. The
Manager persists the action marker before the worker action, and
`ClearCompleted` retains it for Recovery. `InspectActionRecoveryAsync` is
observation-only and never replays a missing or pending command. A recovered
terminal result must match the persisted action ID and authoritative-evidence
bit before admission is released (`Editor/AICodedbManagerWindow.cs:2940-2960,
3036-3051`; recovery inspection at `:356-474`).

### Direct one-shot writer and receipt binding

**FAIL: P1-01.** The writer creates distinct admitted, claimed, and terminal
records and binds the core action/stage/project/package/command/effect/authority
identities. The reader also rejects missing receipt files and conflicting
core identities (`Editor/AICodedbProcessRunner.cs:740-857`). However,
`ReadTerminalReceipt` does not require or validate:

- admission `schema_version`, `managed_by`, and `state`;
- claim `schema_version`, `managed_by`, `state`, or `writer_start_utc_ticks`;
- terminal `child_pid`, `completed_at_utc`, or `output_overflow`.

The writer does emit these fields (`Tools~/invoke-codedb-manager-action.ps1:207-214,
326-347`), and its focused fixture asserts positive writer/child PIDs, but the
Manager recovery parser can still accept a partial or altered receipt when the
subset it checks remains internally consistent. That is not fail-closed for
the frozen requirement that terminal evidence bind writer and child identity,
actual timeout/output provenance, and reject partial evidence. No deletion or
external-process authority is created by this gap, so it is P1 rather than a
BLOCKER.

### Supervisor manager_action_id recovery

**PASS within reused evidence and source scope.** Manager-routed commands carry
the current action ID into `SendCommandAsync`; the Supervisor persists a
per-action record before/with operation evidence and exact lookup uses
`manager_action_operation`. The record validates project/runtime identity and
the latest operation's matching `manager_action_id`. Coalescing with another
owner is rejected when the IDs differ. The recorded Supervisor L0 passed lost
acceptance response, a later unrelated operation, and restart correlation.

### Fallback and multistage provenance

**PASS within source scope.** Fallback is enabled only by the Bridge's explicit
bootstrap proof, never by output text or an unconfirmed transport result.
Redeploy stages use distinct action-stage identities; nonterminal preflight and
mutation stages cannot close the Manager action, while the terminal stage is
the only stage accepted as terminal-for-action. Combined results preserve the
current action ID through the ambient action context and retain aggregate
authoritative-terminal status (`AICodedbActions.cs:107-155, 814-833`).

### Command result versus product readiness

**PASS within source scope.** `AICodedbUserActionStatus` marks command
completion from the command result, while product readiness is supplied only by
the separate status refresh/reconcile observation. A successful Provider or
materializer command can therefore present Completed/Needs Attention rather
than falsely claiming Ready (`Editor/AICodedbActivityPanel.cs:475-520,
635-704`; Manager completion at `Editor/AICodedbManagerWindow.cs:2450-2465`).

## Reused Coder Evidence

- Focused writer/receipt L0: exit `0`, about `4007 ms`; fixture-only success,
  timeout, and identity-rejection scenarios passed.
- Supervisor Manager-action correlation L0: exit `0`, about `16401 ms`;
  lost acceptance, unrelated operation, and restart scenario passed.
- Manager source/syntax batch: exit `0`, about `432 ms`; bounded source
  assertions passed. C# tests themselves were not run.
- Package-boundary L0: exit `0`, about `10581 ms`.
- Package release closure: exit `0`, `source_count=46`, `mismatch_count=0`.
- Ordered tracked diff-check: exit `0`, no output; writer whitespace/final-LF
  check: exit `0`.
- The above evidence was reused without rerunning any command.

## Findings

1. **P1-01 — Partial terminal receipt is accepted as authoritative.**
   `ReadTerminalReceipt` validates only a subset of the admitted/claim/terminal
   envelope. A receipt missing or altering the writer/child/output metadata can
   still reach `TryCompleteRecovery` if the checked identities agree. This
   violates the frozen fail-closed partial/conflicting-evidence boundary.

No BLOCKER or additional P2 finding was identified. The accepted S21 partial-v1
risk remains outside this S22 review.

## NOT RUN / DEFERRED

- C# semantic compilation and direct Editor tests: **NOT RUN**.
- EditMode, Unity/Unity MCP, Domain Reload runtime survival, and human-owned
  Manager actions: **NOT RUN / DEFERRED**.
- Real Provider installation, consumer-project mutation, process probes, and
  protected runtime reads: **NOT RUN / DEFERRED**.
- Full regression, commit/push, Package export/publication, and release
  acceptance: **NOT RUN / DEFERRED**.

## Routing

Current task: `cdb-v0.3-p0-s22-host-action-execution-contract`

Current status: **FAIL**

Next notification: UnityCodeDB v0.3 Planner

Next action: Planner/User disposition of P1-01 (`ACCEPT / FIX / DEFER / STOP`).
Any follow-up must remain limited to full receipt-envelope validation and its
immediate negative recovery regression; no broader audit is implied.

Current S22 GUARDED source verification is complete. Next, notify Planner/User
for the `ACCEPT / FIX / DEFER / STOP` decision; no repair, test rerun, commit,
push, export, publication, or role dispatch was performed.

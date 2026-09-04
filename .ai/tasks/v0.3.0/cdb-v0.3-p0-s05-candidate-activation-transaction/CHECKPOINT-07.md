# Checkpoint 07: Phase-Aware Operation Evidence Cardinality

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: repair the confirmed phase-insensitive
  operation-directory cardinality check for a finalized activation contract.
- This is a new independent bounded production fix. It does not extend or
  reset any prior S05 batch or retry budget.
- Preserve the current uncommitted S05 snapshot. Do not reset, clean, stash,
  rebase, revert, rewrite, commit, or push it.

## Confirmed Finding

- `Publish-InstanceActivationTransaction` publishes the matching activation
  and operation records as `COMMITTED`, then removes the low-level
  `operations/<operation_id>` directory.
- `Get-InstanceActivationContractState` currently requires exactly one
  matching operation directory for every phase.
- A normal finalized `COMMITTED` contract therefore fails the next identical
  convergence attempt with `Activation contract operation evidence does not
  match the authoritative operation_id.`
- A crash can also occur after the `COMMITTED` pair is durable but before the
  matching low-level directory is removed, so that one matching directory is
  valid only as a cleanup window for `COMMITTED`.

## Authorized Fix

- Change only
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`.
- In `Get-InstanceActivationContractState`, make operation-directory
  cardinality validation phase-aware after both contract records have passed
  their existing strict validation and identity matching:
  - `PREPARED` and `ACTIVATING` must retain exactly one directory whose name
    exactly matches the authoritative `operation_id`.
  - `COMMITTED` may contain zero directories after normal finalization, or one
    directory exactly matching the authoritative `operation_id` during the
    post-publication cleanup window.
  - Every other cardinality, extra directory, or mismatched directory remains
    fail-closed.
- Preserve existing namespace, path, reparse-point, record identity, phase,
  orphan, recovery, cleanup, and error semantics except for the confirmed
  phase-aware cardinality correction.
- Do not modify the activation transaction harness, contract schemas,
  publication ordering, mutation/recovery logic, or any other file.

## Validation Budget

- A targeted AST parse and scoped `git diff --check` are allowed for
  `codedb-instance-engine.ps1`.
- Run exactly one focused command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationTransactionOnly
```

- Corrected retries: `0`. No retry is authorized for this checkpoint.
- Do not run Package-boundary, other L0/L1, full regression, C# compile,
  EditMode, Unity, Unity MCP, real Codex, or external-process validation.

## Stop Conditions

- If the focused command exposes any next independent failure, stop
  immediately and report `BLOCKED`; do not repair it in this checkpoint.
- Stop on a workflow time/output limit or any required change outside the
  phase-aware operation-directory cardinality check.
- Do not contact or dispatch Verifier.

## Required Result Record

- Append the exact code change, command, exit status, wall time, captured
  output, batch/retry counts, and deferred/not-run gates to `RESULT.md`.
- Keep the snapshot uncommitted and direct completion to
  `UnityCodeDB v0.3 Planner` for focused review and routing.

## Handoff

- Next notification: `v0.3.coder.deep`.
- Next action: apply the phase-aware operation-evidence cardinality fix and
  execute the single focused validation command. Any further production fix,
  additional run, or Verifier routing requires a later Planner decision.

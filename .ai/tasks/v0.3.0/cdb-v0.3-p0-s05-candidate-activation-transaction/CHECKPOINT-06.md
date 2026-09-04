# Checkpoint 06: Recovery Directory Array Fix

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: repair the confirmed single-item array
  unwrapping defect in the versioned activation recovery reader.
- This is a new independent bounded production fix. It does not extend or
  reset any prior S05 batch or retry budget.
- Preserve the current uncommitted S05 snapshot. Do not reset, clean, stash,
  rebase, revert, rewrite, commit, or push it.

## Confirmed Finding

- `Get-InstanceActivationContractState` obtains the operation directories from
  an `if` expression whose branches emit arrays.
- Windows PowerShell unwraps a single emitted directory during assignment, so
  the variable becomes a `DirectoryInfo` rather than an array.
- Under strict mode, the subsequent `.Count` access fails during PREFLIGHT
  recovery when exactly one authoritative operation directory exists.

## Authorized Fix

- Change only
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`.
- In `Get-InstanceActivationContractState`, materialize the complete
  operation-directory conditional result as an array for zero, one, and many
  entries.
- Preserve all existing namespace validation, exact one-directory identity
  checks, missing/orphan behavior, ordering, recovery semantics, and error
  messages except where formatting is mechanically required.
- Do not modify activation phases, contract schemas, mutation/recovery logic,
  harness assertions/diagnostics, or any other file.

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
  operation-directory array materialization.
- Do not contact or dispatch Verifier.

## Required Result Record

- Append the exact code change, command, exit status, wall time, captured
  output, batch/retry counts, and deferred/not-run gates to `RESULT.md`.
- Keep the snapshot uncommitted and direct completion to
  `UnityCodeDB v0.3 Planner` for focused review and routing.

## Handoff

- Next notification: `v0.3.coder.deep`.
- Next action: apply this array-materialization fix and execute the single
  focused validation command. Any further production fix, additional run, or
  Verifier routing requires a later Planner decision.

# Checkpoint 05: Nullable Mutation Hash Fix

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: repair the confirmed PowerShell null-to-
  empty-string binding defect in activation mutation evidence.
- This is a new independent bounded production fix. It does not extend or
  reset any prior S05 batch or retry budget.
- Preserve the current uncommitted S05 snapshot. Do not reset, clean, stash,
  rebase, revert, rewrite, commit, or push it.

## Confirmed Finding

- `New-InstanceTransactionEntry` correctly records `OriginalSha256 = $null`
  when a target did not exist.
- `New-InstanceActivationMutationEvidence` declares its nullable
  `DesiredSha256` and `PreImageSha256` inputs as `[string]`. Windows PowerShell
  converts an explicitly supplied `$null` to an empty string during binding.
- The empty value then violates the existing absent-target pre-image rule.
  The same coercion would also make a valid null desired hash for a Delete
  mutation appear non-null.

## Authorized Fix

- Change only
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`.
- Adjust only the `DesiredSha256` and `PreImageSha256` parameter declarations
  in `New-InstanceActivationMutationEvidence` so actual null values remain
  null through PowerShell binding.
- Preserve the existing lowercase SHA-256 validation, Write/Delete rules,
  absent/pre-image semantics, returned document shape, and strict reader.
- Do not modify activation phases, recovery, mutation ordering, transaction
  entries, error handling, harness assertions/diagnostics, or any other file.

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
- Stop on a workflow time/output limit or any required change outside the two
  nullable mutation-hash parameter declarations.
- Do not contact or dispatch Verifier.

## Required Result Record

- Append the exact code change, command, exit status, wall time, captured
  output, batch/retry counts, and deferred/not-run gates to `RESULT.md`.
- Keep the snapshot uncommitted and direct completion to
  `UnityCodeDB v0.3 Planner` for focused review and routing.

## Handoff

- Next notification: `v0.3.coder.deep`.
- Next action: apply this paired nullable-hash fix and execute the single
  focused validation command. Any further production fix, additional run, or
  Verifier routing requires a later Planner decision.

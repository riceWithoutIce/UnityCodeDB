# Checkpoint 04: Nullable Selection Evidence Fix

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: repair the confirmed nullable binding
  defect that prevents activation contract initialization when no
  last-known-good instance exists.
- This is a new independent bounded production fix. It does not extend or
  reset any prior S05 batch or retry budget.
- Preserve the current uncommitted S05 snapshot. Do not reset, clean, stash,
  rebase, revert, rewrite, commit, or push it.

## Confirmed Finding

- The transaction fixture has a valid current selection and no
  last-known-good selection.
- `Publish-InstanceActivationTransaction` accepts a nullable
  `PreviousLastKnownGood`, but `New-InstanceActivationSelectionEvidence`
  declares its `Instance` parameter mandatory while its body explicitly
  returns null for a null value.
- PowerShell therefore rejects the null argument before the versioned
  activation contract is initialized. The injected activation mutation fault
  is not reached.

## Authorized Fix

- Change only
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`.
- Add the appropriate nullable parameter annotation to
  `New-InstanceActivationSelectionEvidence` so a missing current/LKG value is
  represented by the function's existing null-return behavior.
- Do not change activation phases, recovery behavior, mutation ordering,
  error handling, contract schemas, or any harness assertions/diagnostics.
- All other production, payload/manifest, C#/Node, test, and package-boundary
  files are out of scope.

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
  single authorized production file and nullable contract.
- Do not contact or dispatch Verifier.

## Required Result Record

- Append the exact code change, command, exit status, wall time, captured
  output, batch/retry counts, and deferred/not-run gates to `RESULT.md`.
- Keep the snapshot uncommitted and direct completion to
  `UnityCodeDB v0.3 Planner` for a focused review and routing decision.

## Handoff

- Next notification: `v0.3.coder.deep`.
- Next action: apply this one nullable-contract fix and execute the single
  focused validation command. Any further production fix, additional run, or
  Verifier routing requires a later Planner decision.

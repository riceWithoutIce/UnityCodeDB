# Checkpoint 03: Activation Contract Investigation

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: investigate the reported missing
  versioned recovery contract before authorizing any production fix.
- This is a new independent investigation. It does not extend or reset any
  prior S05 L0 batch or retry budget.
- Preserve the current uncommitted S05 snapshot. Do not reset, clean, stash,
  rebase, revert, rewrite, commit, or push it.

## Finding Under Investigation

- `CHECKPOINT-02` reached the activation-failure assertion and preserved the
  selected/LKG/old-generation bytes, but the expected versioned contract root
  was absent.
- The harness did not prove that `-TestFailAfterMutation 1` reached the
  versioned activation mutation; an earlier pre-contract error remains
  possible.
- Treat the causal attribution as unresolved. Do not assume a production
  deletion bug.

## Authorized Scope

- Read the direct path only: `Invoke-InstanceConvergence`,
  `Publish-InstanceActivationTransaction`, contract initialization/recovery,
  the focused transaction fixture, and the fault hook.
- The only permitted source edit is a narrowly diagnostic change in
  `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` that
  records the complete `$activationFailure.Text` and distinguishes the
  injected mutation fault from an earlier error. Do not weaken the
  fail-closed or durable-contract assertions.
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` and
  `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` are
  read-only for this checkpoint. No production fix is authorized.

## Validation Budget

- A targeted AST parse and scoped `git diff --check` are allowed for any
  diagnostic fixture edit.
- Run exactly one focused command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationTransactionOnly
```

- Corrected retries: `0`. No retry is authorized for this checkpoint.
- Do not run Package-boundary, other L0/L1, full regression, C# compile,
  EditMode, Unity, Unity MCP, real Codex, or external-process validation.

## Stop Conditions

- If the diagnostic shows the injected fault was not reached, stop and report
  the exact preceding error; do not broaden the harness or patch production.
- If the injected fault is reached and the contract is still absent, stop and
  report a confirmed production activation finding; do not fix it in this
  checkpoint.
- Stop on any second independent behavior, workflow time/output limit, or
  ambiguity outside the declared path.
- Do not contact or dispatch Verifier.

## Required Result Record

- Append the exact diagnostic change, command, exit status, wall time,
  captured output, batch/retry counts, and deferred/not-run gates to
  `RESULT.md`.
- Keep the snapshot uncommitted and direct completion to
  `UnityCodeDB v0.3 Planner` for the next fix decision.

## Handoff

- Next notification: `v0.3.coder.deep` (manual).
- Next action: perform this bounded investigation exactly once and return the
  evidence. A production repair or Verifier routing requires a later Planner
  decision.

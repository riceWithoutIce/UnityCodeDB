# Checkpoint 02: Harness Assertion Correction

## Authorization

- Checkpoint date: 2026-09-04.
- Human authorization: approved after Planner review of the prior bounded
  attempt.
- This is a new independent attempt. It does not extend or reset any prior
  L0 batch or retry budget.
- The preserved uncommitted S05 snapshot remains the input. Do not reset,
  clean, stash, rebase, revert, rewrite, commit, or push it.

## Finding Being Addressed

- The prior focused run stopped at the transaction fixture assertion in
  `test-codedb-host-payload-materializer.ps1` because the fixture expected a
  fixed `Instance activation failed ...` prefix while the production catch
  uses the requested action name (`Upgrade`).
- This checkpoint treats the discrepancy as a harness expectation mismatch,
  not as a confirmed production activation defect.

## Authorized Scope

- Change only the narrowly failing activation-failure assertion in
  `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`.
- Make the assertion action-parametric or otherwise assert the invariant that
  the result reports `Upgrade` failed without selecting an unverified
  candidate. Do not weaken the fail-closed requirement.
- Production activation code, payload/manifest, C#/Node code, package
  boundary tests, and all other files are out of scope.

## Validation Budget

- Before the focused run, a targeted AST parse and scoped `git diff --check`
  are allowed for the changed fixture file.
- Run exactly one focused command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationTransactionOnly
```

- Corrected retries: `0`. No retry is authorized for this checkpoint.
- Do not run Package-boundary, other L0/L1, full regression, C# compile,
  EditMode, Unity, Unity MCP, real Codex, or external-process validation.

## Stop Conditions

- If the corrected assertion exposes a genuine production or activation-state
  failure, stop immediately and report `BLOCKED`; do not modify production
  code in this attempt.
- If the command reaches a workflow time/output limit or fails for another
  independent behavior, stop and preserve the exact evidence.
- Do not contact or dispatch Verifier from this attempt.

## Required Result Record

- Append the exact changed file, command, exit status, wall time, output,
  batch/retry counts, and all deferred/not-run gates to `RESULT.md`.
- Keep the completion footer directed to `UnityCodeDB v0.3 Planner` for a
  fresh read-only review. Leave the snapshot uncommitted.

## Handoff

- Next notification: `v0.3.coder.deep` (manual).
- Next action: execute this checkpoint exactly once, then return the result to
  Planner. Verifier routing remains deferred until the complete transaction
  fixture passes or a new decision is made.

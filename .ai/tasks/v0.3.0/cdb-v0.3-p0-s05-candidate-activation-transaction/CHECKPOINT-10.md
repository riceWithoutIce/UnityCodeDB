# Checkpoint 10: Correct Transaction Fixture Allowlist Placement

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: correct the misplaced CHECKPOINT-09
  harness change and run one bounded focused validation.
- This is a new independent bounded harness correction. It does not extend or
  reset any prior S05 batch or retry budget.
- Preserve the current uncommitted S05 snapshot. Do not reset, clean, stash,
  rebase, revert, rewrite, commit, or push it.

## Confirmed Finding

- CHECKPOINT-09 reported that the production-approved stable-wrapper target
  was added to `Invoke-ActivationTransactionScenarios`.
- Current source shows that the entry was instead added to
  `Invoke-ActivationContractFoundationScenarios`, while the actual transaction
  fixture still initializes `$script:AllowedTargetPaths` as empty.
- The focused test therefore reproduced the same wrapper-target rejection
  because the authorized correction never reached the executed fixture.
- This is a harness placement error, not a new production-contract finding.

## Authorized Fix

- Change only
  `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`.
- Remove the CHECKPOINT-09 stable-wrapper allowlist entry from
  `Invoke-ActivationContractFoundationScenarios`, restoring its prior empty
  `$script:AllowedTargetPaths` initialization.
- Add exactly
  `AIWork/codedb/wrapper/codedb-project-wrapper.mjs = $true` to the existing
  `$script:AllowedTargetPaths` initialization inside
  `Invoke-ActivationTransactionScenarios`.
- Do not add any other target, derive an allowlist from journal input, or alter
  the existing conflicting-journal mutation and expected
  `identities do not match` assertion.
- Do not modify production scripts, target validation, activation semantics,
  other fixture behavior, or any other file.

## Pre-Run Placement Gate

- Before the focused command, perform one bounded static check of the two
  named function bodies and confirm:
  - the stable-wrapper allowlist entry is absent from
    `Invoke-ActivationContractFoundationScenarios`;
  - it is present exactly once inside `Invoke-ActivationTransactionScenarios`.
- Stop without running the focused command if either condition is false.
- A targeted PowerShell AST parse and scoped `git diff --check` are allowed
  only for `test-codedb-host-payload-materializer.ps1`.

## Focused Validation Budget

- Run exactly one command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationTransactionOnly
```

- Corrected retries: `0`. Do not start the command a second time.
- Maximum total wall-clock wait: `120 seconds`.
- If the execution tool yields an ongoing session, continue waiting on that
  same session until final exit or the total limit. Do not launch a replacement
  process.
- Do not run Package-boundary, other L0/L1, full regression, C# compile,
  EditMode, Unity, Unity MCP, real Codex, or external-process validation.

## Stop Conditions

- If the focused command exposes any next independent failure, stop
  immediately and report `BLOCKED`; do not investigate or repair it.
- If it passes, stop and return the complete focused evidence to Planner; do
  not contact or dispatch Verifier.
- If total waiting reaches `120 seconds` without a final exit status, stop
  waiting, perform at most one bounded read-only check for that exact process,
  do not terminate it, and report `BLOCKED` with ownership/state.
- Stop on workflow output/time limits, unexpected snapshot drift, or any
  required change outside the two exact fixture initialization edits.

## Required Result Record

- Append a correction stating that CHECKPOINT-09 changed the S04 foundation
  fixture rather than the S05 transaction fixture; do not rewrite or delete
  the prior immutable result record.
- Append the exact harness correction, placement-gate evidence, AST/diff-check
  results, focused command, final exit status, wall time, concise output,
  batch/retry counts, and deferred/not-run gates to `RESULT.md`.
- Keep the snapshot uncommitted and return completion to
  `UnityCodeDB v0.3 Planner` for focused review and routing.

## Handoff

- Next notification: `v0.3.coder.deep`.
- Next action: move the exact allowlist entry to the correct transaction
  fixture, prove its placement, and run the one focused validation command.
  Any further fix, additional run, Verifier routing, commit, or push requires
  a later Planner or human decision.

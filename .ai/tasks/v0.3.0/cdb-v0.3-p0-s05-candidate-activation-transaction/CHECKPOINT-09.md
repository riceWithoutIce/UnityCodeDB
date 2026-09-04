# Checkpoint 09: Transaction Fixture Allowlist Context Fix

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: repair the confirmed activation-
  transaction fixture context gap exposed by CHECKPOINT-08.
- This is a new independent bounded harness fix. It does not extend or reset
  any prior S05 batch or retry budget.
- Preserve the current uncommitted S05 snapshot. Do not reset, clean, stash,
  rebase, revert, rewrite, commit, or push it.

## Confirmed Finding

- The CHECKPOINT-08 run passed the injected mutation fault, recovery,
  `COMMITTED` publication, and identical retry before entering the intended
  conflicting-journal assertion.
- `Invoke-ActivationTransactionScenarios` loads production functions into the
  fixture process, then initializes `$script:AllowedTargetPaths` as empty.
- Its direct call to `Get-InstanceActivationContractState` consequently
  rejects the valid committed mutation target
  `AIWork/codedb/wrapper/codedb-project-wrapper.mjs` before reaching the
  deliberately corrupted activation/operation identity.
- The production materializer already includes that exact stable-wrapper path
  in its audited target allowlist. The observed failure is missing fixture
  context, not authorization to widen the production activation surface.

## Authorized Fix

- Change only
  `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`.
- Within `Invoke-ActivationTransactionScenarios`, seed the existing fixture
  `$script:AllowedTargetPaths` map with exactly
  `AIWork/codedb/wrapper/codedb-project-wrapper.mjs` before the direct contract
  reader is exercised.
- Match the production allowlist identity and comparison behavior. Do not add
  unrelated targets or derive a broader allowlist from untrusted fixture
  journal data.
- Preserve the existing conflicting-journal mutation and its expected
  `identities do not match` assertion.
- Do not modify production scripts, contract readers, target validation,
  activation semantics, other fixture scenarios, or any other file.

## Validation Budget

- A targeted PowerShell AST parse and scoped `git diff --check` are allowed
  only for `test-codedb-host-payload-materializer.ps1`.
- Run exactly one focused command:

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
- If it completes successfully, stop and return the complete focused evidence
  to Planner; do not contact or dispatch Verifier.
- If total waiting reaches `120 seconds` without a final exit status, stop
  waiting, perform at most one bounded read-only check for that exact process,
  do not terminate it, and report `BLOCKED` with ownership/state.
- Stop on workflow output/time limits, unexpected snapshot drift, or any
  required change outside the single fixture allowlist entry.

## Required Result Record

- Append the exact harness change, AST/diff-check results, focused command,
  final exit status, total wall time, concise output, batch/retry counts, and
  deferred/not-run gates to `RESULT.md`.
- Keep the snapshot uncommitted and return completion to
  `UnityCodeDB v0.3 Planner` for focused review and routing.

## Handoff

- Next notification: `v0.3.coder.deep`.
- Next action: add the exact production-approved stable-wrapper target to the
  transaction fixture context and run the one focused validation command.
  Any further fix, additional run, Verifier routing, commit, or push requires
  a later Planner or human decision.

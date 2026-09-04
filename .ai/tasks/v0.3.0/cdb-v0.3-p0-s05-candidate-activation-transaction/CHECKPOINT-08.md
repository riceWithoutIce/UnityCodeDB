# Checkpoint 08: Activation Transaction Evidence Recapture

## Authorization

- Checkpoint date: 2026-09-04.
- Human-authorized Planner decision: perform one evidence-only recapture for
  the CHECKPOINT-07 phase-aware operation-directory fix.
- The prior `30.0086225s` tool wait ended without a final process exit status.
  This was below the focused-test workflow warning of `120 seconds` and did
  not establish a product failure or a workflow test timeout.
- This is one new, independent validation attempt. Preserve the current
  uncommitted S05 snapshot. Do not reset, clean, stash, rebase, revert,
  rewrite, commit, or push it.

## Frozen Snapshot And Scope

- Make no source, test, harness, task-contract, or configuration changes.
- Do not repair, instrument, reformat, or add diagnostics before or during
  this attempt.
- The only objective is to obtain the complete terminal result for the
  existing focused activation-transaction command on the current snapshot.

## Authorized Validation

- Run exactly once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationTransactionOnly
```

- Corrected retries: `0`. Do not start the command a second time.
- Maximum total wall-clock wait for this command: `120 seconds`.
- If the execution tool yields an ongoing session before the command exits,
  continue waiting on that same session until it returns a final exit status
  or the total `120-second` limit is reached. Continuing the same process is
  evidence capture, not a retry; launching another process is forbidden.
- Capture the final exit status, wall time, and concise terminal output.
- Do not run AST parse, `git diff --check`, Package-boundary, other L0/L1,
  full regression, C# compile, EditMode, Unity, Unity MCP, real Codex, or any
  external validation.

## Stop Conditions

- If the command returns the next independent product or harness failure,
  stop immediately and report `BLOCKED`; do not investigate or repair it.
- If the command passes, stop and report the complete focused evidence for
  Planner review; do not contact Verifier directly.
- If total waiting reaches `120 seconds` without a final exit status, stop
  waiting, perform at most one bounded read-only check of whether that exact
  test process remains, do not terminate it, and report `BLOCKED` with process
  ownership/state. Do not start a replacement command.
- Stop on unexpected snapshot drift or any required file change.

## Required Result Record

- Append the exact command, final exit status or explicit unavailability,
  total wall time, concise captured output, process state if timed out,
  batch/retry counts, and deferred/not-run gates to `RESULT.md`.
- Record that no files were changed by this checkpoint, except the required
  append to `RESULT.md`.
- Keep the snapshot uncommitted and return completion to
  `UnityCodeDB v0.3 Planner` for focused review and routing.

## Handoff

- Next notification: `v0.3.coder.deep`.
- Next action: recapture one complete focused transaction result on the frozen
  snapshot. A product fix, harness change, additional run, Verifier routing,
  commit, or push requires a later Planner or human decision.

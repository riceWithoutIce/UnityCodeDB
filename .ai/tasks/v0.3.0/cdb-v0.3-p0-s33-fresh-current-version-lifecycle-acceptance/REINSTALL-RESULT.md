# S33 same-version reinstall result - 2026-10-19

Status: BLOCKED_BY_HISTORY_BOUND / NO_MUTATION / REINSTALL_NOT_ACCEPTED.

## Human evidence

User supplied the Manager output and screenshot ending
`codex-clipboard-6271c350-f815-48aa-bdc9-7b753f1e0f67.png` after the one
authorized Install attempt. Manager reports `Command failed with exit code 6`,
while the Overview still reports the project as uninstalled and keeps
`Install CodeDB` available.

## Exact failed action

- Action id: `3a9f458bf874431b80c32e9355d8a5b6`.
- Terminal stage id: `72d14896856a677f4c8e6c6d587e2bb95ff9649a05e7a7023ef773300d2c46f8`.
- Writer exit code `6`; elapsed `4918 ms`; timed out, output overflow and
  incomplete drain all false.
- Stderr: `Instance Install failed without selecting an unverified candidate.
  Install Supervisor history exceeds its bounded record count.`
- Command result: `INSTALL / BLOCKED / PREFLIGHT /
  INSTANCE_CONVERGENCE_FAILED`, `mutated_scopes=[]`, `cleanup_state=COMPLETE`.
- No candidate was selected or activated. No retry or manual state repair ran.

## Read-only cause evidence

The exact Package source checks the Supervisor `operation-history` directory
against a hard bound of 4096 records before Install can proceed:

- `Tools~/codedb-instance-engine.ps1` line 4931 throws
  `Install Supervisor history exceeds its bounded record count.`
- `Tools~/materialize-codedb-host-payload.ps1` line 10276 applies the same
  4096-operation-history bound during namespace proof.

S33 currently contains 5301 operation-history JSON records. This is the direct
preflight cause. The history is project-local and the sampled records use the
expected S33 runtime identity; no foreign-identity conclusion is being made.

## Post-failure state

- `desired-state.json` remains `UNINSTALLED` with `cleanup_state=PENDING`.
- `current-instance.json` remains absent.
- The prior Install-owned instance directory remains retained; no new instance
  was created by this failed attempt.
- The previous logical Uninstall remains the last successful mutation.

## Scope disposition

Same-version reinstall is BLOCKED and does not pass. This is now a concrete
product retention/convergence defect. Background work also emits the earlier
diagnostic logs, but Console logging is not established as the cause of history
growth. The next step is read-only alignment on a
bounded history-retention strategy and its safety invariant. No history deletion,
compaction, Install retry, source repair, package export or reference switch is
authorized by this result.

Further read-only inventory and the adjacent queued-invalidation contract
mismatch are recorded in HISTORY-CONVERGENCE-PROPOSAL.md. No retry was needed
to identify that merely lowering the history count is insufficient.

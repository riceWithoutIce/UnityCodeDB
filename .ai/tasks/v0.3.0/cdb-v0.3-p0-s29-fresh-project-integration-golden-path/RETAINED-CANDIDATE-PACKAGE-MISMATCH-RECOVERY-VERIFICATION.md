# S29 retained-candidate package-mismatch recovery — Verifier result

## Verdict

`PASS_WITH_LIMITS` — the original P1 is fixed in the re-reviewed snapshot;
Unity/runtime/release gates and two pre-existing package-boundary limitations
remain open.

This is a read-only source review of the Coder working-tree snapshot based on
`427a42495e0fd8a5707da3adf368f895dbf524ad`. No source, runtime, receipt,
marker, package, Unity project, or external process was modified by this
Verifier.

## Snapshot and scope

Coder result reviewed:

`RETAINED-CANDIDATE-PACKAGE-MISMATCH-RECOVERY-RESULT.md`

The three allowlisted source hashes match
`RETAINED-CANDIDATE-PACKAGE-MISMATCH-RECOVERY-SOURCE-SHA256.txt`:

```text
66908ff33408fe87fc05c6c2f9ead35d26da838d158aba818947689b62ae26e0  com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
19b5e36c0cf30bfbd1c97a9cda5dbff10e821b7bb3a6514b1966049e27a2172a  com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
bfa98b2a3805d16822082c2d5bbf15191b17b6fe1772daa985857009af22618b  com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
```

`git diff --check` reports no touched-file whitespace errors. The Coder's
reported package-boundary results were retained: ManagerActionWriterOnly
passed; PathProvenanceOnly was deferred/failing on the pre-existing absolute
package path admission; retained-entry-routing was deferred/failing on the
pre-existing `poc.42` coordinator source hash mismatch.

## Original P1 re-review — fixed

The new code parses and validates the selected instance origin before the
package-mismatch return. `IsAuthenticatedFreshInstallOrigin` requires
`INSTALL`, `READY`, a non-empty action id, and an action id different from the
retained failed action. Only after that proof does `packageMismatch` return,
so the bypass is limited to the old Package-owned activation/wrapper contract
comparison. The current desired state remains required as `INSTALLED`, and
`CanPublishEditorLease` plus the selected/retained instance-id distinction are
still enforced.

The focused tests now cover and reject `UPGRADE`, `REINSTALL`, and same-action-
id candidates (3/3 according to the Coder result). No finding remains for the
original P1.

## Other checks

- `ResolvePrimaryAction` checks `actionInFlight` first, so the new primary
  action is hidden while an action is running.
- The new UI predicate requires retained failed-install evidence, a completed
  (non-recovering) session, `NeedsAttention` with no attention/migration
  reason, `HostPayloadState.SetupRequired`, and a canonical Package-key
  mismatch. Other status conflicts remain fail-closed.
- The journal path itself is read-only; no marker, receipt, retained effect,
  runtime, or index write was added by this change.
- Existing removal/recovery code paths remain reachable in the diff; no
  direct mutation or removal-path regression was observed in static review.
- The added UI regression covers the positive predicate and action-in-flight
  suppression; the three selected-origin negative cases cover the original
  bypass directly.

## Targeted review batch and evidence limits

One targeted standalone batch was attempted in this re-review:

`com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -ManagerActionWriterOnly`

It could not start the isolated PowerShell child because the configured
Codex-runtime `powershell.exe` path was missing. The Coder's prior result for
this batch was PASS (12 focused writer scenarios), so this environment failure
does not overturn that source/package evidence. The Coder-reported
PathProvenanceOnly and retained-entry-routing failures remain pre-existing
limits. Unity EditMode, runtime, MCP/IPC, device, and release gates were
**NOT RUN**.

## Priority summary

- P1: none after re-review; original selected-instance-origin bypass is fixed.
- BLOCKER: none raised by this source-only review.
- P2/FOLLOW-UP: none identified in the original finding.


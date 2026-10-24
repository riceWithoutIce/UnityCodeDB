# S29 Failed-Install Recovery - Human Checkpoint Evidence

Date: 2026-10-08. Source delivery: commit 651f9b3, local artifact
.artifacts/0.3.0-preview.5-s29-failed-install-recovery-poc40.
Status: HUMAN_FOCUSED_TEST_PASS / MANAGER_HISTORICAL_RECEIPT_CONFLICT /
REAL_RECOVERY_NOT_STARTED / S29_PARTIAL.

## Focused EditMode tests

Human reported `都测试通过了` in response to the four-method/11-case checklist.
Screenshot codex-clipboard-7184d672-cdc8-4d97-b1e7-64f74c05a896.png shows
EditMode, aggregate 11 passed / 0 failed, with all four filtered
UnselectedRetainedInstance_BlocksAutomaticConvergence cases green.
The other methods are not individually visible in this filtered image; their
completion is supported by the human report and aggregate count.
SHA256: de0ddb7c8fd884f938881d850449d8be1c539416adc325fefb2aed47f81b58c8.
All four requested methods / 11 cases are recorded as human-reported PASS.
The screenshot is Test Runner, not Console; no separate exhaustive zero-Console-
error observation is inferred. No tests were rerun by the assistant.

## Manager observation

Human then supplied codex-clipboard-5927c139-99f7-4e4e-8554-11c4c0386a03.png.
SHA256: 69feea972553542f3fff7d7759f8b1734e5f9adbfb697c5341db5faa6ecff81d.
Visible Package v0.3.0-preview.5, Overview selected, CodeDB needs attention.
Banner names previous action d8c736504562495dbafdd673c6851efb and the new
failed-install-recovery-poc40 artifact path, unknown command outcome, with
new project changes blocked until execution safety is proved.
Last activity: No recent command. Outcome unconfirmed:
`Historical Manager action receipt validation failed: A resolved action marker
conflicts with its original receipt.`
Diagnostics show Host payload Needs Setup; current instance and other checks
Inactive / Not evaluated. No Install/removal button is visible in this Overview
capture; this alone does not establish absence from other tabs/menus.

This is a Manager action-journal admission blocker before real project recovery,
not a failed execution of the new Uninstall/Install flow. Retained failed
candidate may legitimately keep product Needs attention, but the contradictory
historical receipt is unresolved and cannot be dismissed as expected readiness.

## Bounded read-only source check

AICodedbManagerActionJournal.cs around lines 336-361 compares a resolved marker
with the original admitted Package key and recovered action state; historical-
unknown markers additionally bind stage count/identity and admission/claim hashes.
The visible message is shared by multiple failed comparisons. The screenshot
does not identify which field differs or establish the underlying cause.
Do not infer corrupted bytes, new Package attribution, a stale outcome, or a
specific code fix from the message alone. Its displayed new artifact path and
old action ID merit comparison with the original receipt.

No live receipt/marker bytes were inspected in this checkpoint; only the error's
source location was read. No source, Package, runtime/candidate, registration,
process or Unity state was changed. Evidence/task documentation only.

Next: read-only comparison of this exact action's resolved marker, original
admission and terminal recovery evidence, through their real consumer, to identify
the concrete mismatch. Do not replay historical actions, clear admission, delete
receipts, click Install/removal/Configure Dependencies or invent a resolved state.
Unity may remain open during read-only diagnosis; no close/reopen cycle required.
Human tests PASS and source ACCEPT remain valid at their own scope; real recovery,
Ready/MCP and whole S29 acceptance remain unproved.

# S22 Host Action Execution Contract - GUARDED Verification 01

## Verdict And Identity

- Verdict: **FAIL** for the frozen S22 source contract. This is a focused read-only review, not Editor or Unity acceptance.
- Branch: `codex/v0.3.0-legacy-workflow`.
- HEAD: `6b64f27adb51eeab8394aac6bca722117ac6863c` - PASS.
- Ordered six-path binary diff identity: `c253448ac6c51d446da0eed715849bcb94dedac3` - PASS.
- Identity order: `Editor/AICodedbActions.cs`, `Editor/AICodedbActivityPanel.cs`, `Editor/AICodedbManagerWindow.cs`, `Editor/AICodedbPaths.cs`, `Editor/AICodedbProcessRunner.cs`, `Tests/Editor/AICodedbManagerUiTests.cs`, all under `com.rice.ai-codedb/`.
- Existing unrelated dirty worktree content was left untouched. The accepted S21 `FAIL/P1-01` partial-v1 presentation risk was not treated as fixed by S22.

## One-Time Findings

### P1-01 - Manager open still performs full status I/O on the Unity main thread

`AICodedbManagerWindow.OnEnable` calls `RefreshStatus()` (`Editor/AICodedbManagerWindow.cs:174`). That method explicitly records main-thread filesystem, hash, and full-status work and calls synchronous `AICodedbStatusSnapshot.Refresh()` (`:300-366`). The snapshot constructor reads Package/project/current-instance state and resolves the Host generation (`Editor/AICodedbStatusSnapshot.cs:54-75`). `OnGUI` can also call `RefreshStatus()` when its snapshot is null (`Editor/AICodedbManagerWindow.cs:249-250`), and the Refresh control invokes it through `RefreshAllStatus()` (`:1041-1045`). This directly conflicts with the frozen contract's no filesystem/hash work in Manager open/repaint callbacks. The S22 change removed the synchronous refresh at action start, but not these normal Manager paths. Its focused Editor tests do not run and do not prove the open/repaint boundary. A slow or blocked status read can therefore stall the Editor UI on the normal Manager path.

### P1-02 - Acknowledging an unconfirmed action releases admission without authoritative recovery evidence

After a window close or Domain Reload, the session restores a pending marker as `Recovery` (`Editor/AICodedbManagerWindow.cs:3016-3034`), correctly refusing a new action while `IsRecovering` (`:2909-2914`). But the Activity panel offers `Acknowledge` with a null result (`Editor/AICodedbActivityPanel.cs:71-78`), or `Clear` when the prior command result is present (`:232-245`). Either route invokes `ClearCompleted()` (`Editor/AICodedbManagerWindow.cs:2433-2445`), which unconditionally clears the pending marker and session for recovery (`:3003-3012`). There is no required fresh owner/journal/status observation or operation-identity match before that release. `TryStart()` can then admit another action even if the earlier external command's outcome is still unknown. The UI's instruction to review status is advisory only. This violates the contract's requirement to keep bounded recovery until the authoritative outcome is known and to prevent a silent second action owner. Existing backend checks remain important, but they do not prove the Manager admission guarantee for every listed action.

- BLOCKER: none separately identified.
- P2: none.
- FOLLOW-UP: none within this focused scope.

## Focused Checks And Evidence Boundary

- Source checks support main-thread capture of `_executionContext`, `AsyncLocal` worker propagation, action ID diagnostics, single-session rejection while Running/Recovery, actual Provider/Host command result preservation, and separation of successful command evidence from Needs Attention. This source support does not close the two findings above.
- Backend mutation authority was not moved into Manager. The S21 accepted partial-v1 risk remains unchanged. No backend mutation was performed.
- Reused Coder evidence from `RESULT.md`: final six-file Roslyn syntax parse PASS; Package boundary PASS; release closure PASS (`source_count=46`, `mismatch_count=0`); scoped six-file `git diff --check` PASS. These are not C# semantic compilation or UI/runtime evidence.
- Not run: Editor tests, C# compile, EditMode, UnityValidationProject, Unity/Unity MCP, actual Provider install, real-project mutation, full regression, and release acceptance. No test was rerun in this review.
- No source, test, contract, protected runtime, or external process was changed; no Coder contact, commit, push, or publication occurred.

## Routing

Next actor: Planner/User. Decide `FIX / DEFER / ACCEPT / STOP` for the two P1 findings. A fix review should verify only these findings and their immediate regression, on a newly frozen stable identity; do not infer Unity or release PASS from this report.

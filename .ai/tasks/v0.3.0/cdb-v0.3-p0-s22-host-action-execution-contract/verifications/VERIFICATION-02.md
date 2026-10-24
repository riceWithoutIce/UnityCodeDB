# S22 FIX 01 - GUARDED Targeted Verification 02

## Verdict And Identity

- Verdict: **FAIL** for complete S22 source closure. The unsafe re-admission portion of the original P1-02 is fixed, but an immediately adjacent recovery-liveness gap remains. This is a source review, not a Unity runtime verdict.
- Branch `codex/v0.3.0-legacy-workflow`, HEAD `6b64f27adb51eeab8394aac6bca722117ac6863c`: PASS.
- Ordered six-path binary diff identity `7607e335771d0bfe6cbaa01991fa80d4644a3713`: PASS, using the path order recorded in `RESULT.md`. Identity did not drift during review.
- The prior `VERIFICATION-01.md` remains unchanged. Its P1-01 description incorrectly associated the no-argument cache-only `RefreshStatus()` with the separate `RefreshStatus(AICodedbCommandResult)` synchronous overload; FIX 01 removed the latter. The original finding is withdrawn on this source evidence.

## Original Findings And Immediate Regression

### P1-01 - CLOSED

`OnEnable` and the null-snapshot `OnGUI` path call the no-argument `RefreshStatus()` (`Editor/AICodedbManagerWindow.cs:174,250,300-349`). Explicit Refresh uses that same cache-only overload, followed by `BeginStatusRefresh(true)` (`:1023-1028`). The method reads the in-memory Ready cache or lifecycle-published `SessionState`, then creates a display-only snapshot; it no longer calls synchronous `AICodedbStatusSnapshot.Refresh()` or records main-thread filesystem/hash/full-status work. The lifecycle display read uses published project identity and `SessionState`, without project-file validation (`Editor/AICodedbEditorLifecycle.cs:2872-2908`). Fresh full status remains in `RefreshStatusAsync`, which uses `AICodedbStatusSnapshot.RefreshAsync` on a worker (`Editor/AICodedbManagerWindow.cs:450-510`; `Editor/AICodedbStatusSnapshot.cs:514-533`). This closes the specific source finding; the Editor test and Unity main-thread counters remain unexecuted.

### P1-02 - UNSAFE RE-ADMISSION CLOSED; RECOVERY LIVENESS OPEN

For an unconfirmed action, the Activity panel no longer offers Acknowledge when the result is null, and suppresses Clear when a result is shown with `Outcome unconfirmed` (`Editor/AICodedbActivityPanel.cs:71-96,231-248`). `ClearCompleted()` refuses a recovering session and retains its `SessionState` pending marker (`Editor/AICodedbManagerWindow.cs:3002-3019`); `RestorePending()` recreates Recovery and `TryStart()` rejects another action (`:2885-2907,3022-3040`). A null result, including the post-reload case, enters or remains Recovery (`:2924-2940,2956-2975`). A closed window with a known terminal command result instead completes as status-unavailable, retains that result, and clears the pending marker without claiming Ready (`:2969-2975`). These changes close the original second-owner admission path on the reviewed source.

**Remaining P1, directly adjacent to P1-02:** no production path resolves a restored Recovery session after a later authoritative status observation. `ApplyStatusSnapshot()` forwards a fresh product state only to `AICodedbUserActionStatus.UpdateProductState` (`Editor/AICodedbManagerWindow.cs:434-447`), which updates only `Completed`, not `Recovery` (`Editor/AICodedbActivityPanel.cs:570-577`). `ClearCompleted()` deliberately refuses Recovery, and the session has no method to bind a later owner/journal/operation result and complete or explicitly retire that marker. Therefore a Domain Reload with no command result keeps the Manager's action lane rejected for the remainder of the Editor session, even after fresh status becomes available. This is fail-closed for safety but does not meet the frozen contract's bounded recovery and subsequent normal-action availability. The focused tests assert continued rejection; they do not cover recovery to a verified terminal state. No source evidence supports calling this path runtime PASS.

- BLOCKER: none separately identified.
- P2: none.
- FOLLOW-UP: none beyond the P1 recovery-liveness finding above.
- S21's previously accepted partial-v1 presentation risk remains unchanged and is not reopened here.

## Evidence And Boundary

- Reused Coder FIX 01 evidence from `RESULT.md`: Roslyn syntax parse PASS for three touched C# files; Package boundary PASS; release closure PASS (`source_count=46`, `mismatch_count=0`); scoped six-file `git diff --check` PASS, no retry. Earlier S22 source evidence remains as recorded; no command was rerun by this Verifier.
- NOT RUN / DEFERRED: direct Editor tests, C# semantic compile, EditMode, UnityValidationProject import or UI lifecycle, Unity/Unity MCP, actual Provider installation or project mutation, full regression, and release acceptance.
- Production/test/contract and protected runtime remained read-only. No Coder contact, commit, push, or publication occurred.

## Routing

Next actor: Planner/User. Decide `FIX / DEFER / ACCEPT / STOP` for the remaining P1 recovery-liveness risk. Any follow-up fix review should remain confined to that path and its immediate regression on a newly frozen identity. Do not infer Editor or Unity PASS from this report.

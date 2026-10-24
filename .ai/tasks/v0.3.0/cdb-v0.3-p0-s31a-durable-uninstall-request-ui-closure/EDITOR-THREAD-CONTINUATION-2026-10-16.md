# S31-A Editor-thread continuation — 2026-10-16

## Scope

One authorized, isolated Unity EditMode focused run. No source edits, package
delivery, reference switching, real Install/Uninstall, or live process control.

## Command correction

The earlier attempts placed `-quit` on the Unity command line. Unity exited
before the Test Runner started (`RunNativeTestsIfRequiredAndExit : 100 ns`) and
did not produce XML. The continuation omitted explicit `-quit` and used the
Test Runner's normal completion path.

## Evidence

- Project: `<isolated-worktree>/UnityValidationProject`
- Unity: `<unity-editor-executable>` (2022.3.62f3)
- Filter: `ManagerActionSession_ReloadRestoresUnconfirmedOutcomeWithoutRetry`
- XML: `<repository-root>/.artifacts/tests/s31a-editor-thread/reload-unconfirmed-noquit.xml`
- Result: `Passed`, total `1`, passed `1`, failed `0`
- Duration: `0.3261705` seconds
- Task-owned Unity process: no remaining process after completion
- `git diff --check` on the eight S31-A source/test surfaces: pass

## Gate interpretation

This closes the previous environment blocker for one Editor-thread test and
adds one PASS to the S31-A evidence set. It does not promote the task: the
remaining Domain Reload, two-window/reopen, terminal UI, startup/reconnect
fence, and Install/Remove/Repair Editor scenarios are still `UNRUN`.

## Follow-up focused runs

With the same corrected command shape (no explicit `-quit`), two additional
focused EditMode tests passed:

- `ManagerActionSession_DurableRetainedResultClearsPendingAfterDomainReload`
  — `<repository-root>/.artifacts/tests/s31a-editor-thread/domain-reload.xml`
- `ManagerActionSession_WindowCloseWithCommandRetainsResultWithoutClaimingReady`
  — `<repository-root>/.artifacts/tests/s31a-editor-thread/window-reopen.xml`

Both XML files report total `1`, passed `1`, failed `0`. No task-owned Unity
process remained after either run. These are additional PASS results only; the
full S31-A gate remains open for the scenarios listed above.

The terminal replacement scenario also passed:

- `ManagerActionSession_DurableRetainedResultReplacesStaleRecoveringSession`
  — `<repository-root>/.artifacts/tests/s31a-editor-thread/terminal-replacement.xml`

Its XML reports total `1`, passed `1`, failed `0`, and no task-owned Unity
process remained.

## Repository-local evidence migration — 2026-10-16

The fourteen raw XML/log files were copied from the transient isolated run
output to `<repository-root>/.artifacts/tests/s31a-editor-thread/`. SHA-256
was checked by filename for every source/destination pair; all fourteen pairs
matched. The original transient files were preserved and were not deleted.
Tracked task records use `<repository-root>` and `<isolated-worktree>` symbols;
no machine-specific absolute path is required for the durable handoff.

The terminal UI projection test was invoked but returned `Skipped:Ignored`:

- `ManagerRetainedDisposition_WindowAttachmentClearsOnlyHistoricalProjection`
  — `<repository-root>/.artifacts/tests/s31a-editor-thread/terminal-ui.xml`

The test explicitly requires the isolated production
`RetainedDispositionOnly` output, which was not present in this run. This is
`UNRUN` evidence, not a source failure or PASS.

The admission fence scenario also passed:

- `ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission`
  — `<repository-root>/.artifacts/tests/s31a-editor-thread/admission-fence.xml`

Its XML reports total `1`, passed `1`, failed `0`, and no task-owned Unity
process remained.

## Follow-up authorization blocked — 2026-10-16

The requested continuation to generate `RetainedDispositionOnly` and run its
focused Editor test was not started. The archived S31-A worktree snapshot could
not be restored because the worktree manager reported that its snapshot was
missing. The currently active S31 worktree differs from the frozen S31-A
snapshot in `AICodedbManagerWindow.cs` and
`AICodedbManagerActionJournal.cs`; therefore it cannot provide attributable
S31-A evidence. No fixture was generated and no mismatched Editor test was run.

The S31-A source snapshot remains `PARTIAL / NOT_ACCEPTED`. Recovery requires a
new attributable source snapshot or an explicit route decision; this record
does not authorize copying the active S31 worktree back into S31-A.

# S31-A rebaseline Coder result

## Status

`PARTIAL / NOT_ACCEPTED` for the full S31-A gate. A new attributable source
snapshot was established from the current active S31 source worktree. The
production RetainedDispositionOnly fixture generator passed, and the requested
focused Unity EditMode test passed on that same eight-file source snapshot.

No source was copied to the main worktree. No commit, package export, reference
switch, real Install/Uninstall, runtime process control, or S31-B work was done.

## Baseline identity

- Base commit: `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`
- Source snapshot: repository-local rebaseline worktree derived from the
  current active S31 checkout.
- All eight allowlisted source/test files match the active S31 checkout
  byte-for-byte; hashes are recorded in `REBASELINE-SOURCE-SHA256.txt`.
- The snapshot contains no intentional changes outside the S31-A allowlist.

## Fixture evidence

The existing production `RetainedDispositionOnly` generator was run against
the immutable retained-disposition package input. It completed with:

`[PASS] FailedPreparationRecoveryOnly; cases=47; native_children=0`

The generated fixture is retained under:

`<repository-root>/.artifacts/tests/s31a-rebaseline/generated-retained74c4/<run-id>/`

The fixture was then bound to the rebaseline package/project identities for the
Editor consumer run. The original retained fixture remains untouched.

A separate attempt using the current snapshot payload was stopped at the
existing production-definition expectation mismatch (`default-old-reader-not-
weakened`); it is retained as diagnostic evidence under the rebaseline
artifact root and is not used as PASS evidence.

## Focused Unity evidence

Unity 2022.3 EditMode Test Runner executed exactly:

`Rice.AI.Codedb.Editor.Tests.AICodedbProjectSettingsTests.ManagerRetainedDisposition_WindowAttachmentClearsOnlyHistoricalProjection`

Result: **PASS** (`total=1, passed=1, failed=0, skipped=0`).

Evidence:

- `<repository-root>/.artifacts/tests/s31a-rebaseline/editor/ManagerRetainedDisposition_WindowAttachmentClearsOnlyHistoricalProjection-fresh.xml`
- `<repository-root>/.artifacts/tests/s31a-rebaseline/editor/ManagerRetainedDisposition_WindowAttachmentClearsOnlyHistoricalProjection-fresh.log`

Unity compiled the package and test assemblies as part of the run. No
task-owned Unity process remained after completion; unrelated Unity processes
were not inspected or operated on.

## Remaining S31-A limits

This focused run closes only the production retained-disposition fixture and
window-attachment seam. Domain Reload/reopen, two-window admission, terminal
UI restoration, startup/reconnect fence, and Install/Remove/Repair Editor
regressions remain unrun. Therefore the S31-A acceptance gate remains partial,
and no Verifier admission or delivery authority is implied.

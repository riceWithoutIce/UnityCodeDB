# S29 test workspace - independent source verification

Date: 2026-10-08. Disposition: SCOPED SOURCE REVIEW PASS.
No actionable finding in the frozen workspace contract and direct fixture
regressions. This is not C# compilation, fixture execution, Unity/EditMode,
real recovery/removal or release acceptance. Whole S29 remains PARTIAL.

## Exact snapshot and scope

Verified HEAD `932e3e7ff695019ebebac9d3e7ba2f4b9e205105`, empty staged index,
and all four final SHA256s in TEST-WORKSPACE-REPAIR-RESULT.md: MATCH.
Result SHA256 also matched:
`1A3AE75B167ED24DE1861ECF9D39D3218E6D2C2DEF52C5331AE24F359B68E4C3`.

Read the review packet, active task, Coder result, canonical
`Documentation~/test-workspace-contract.md`, and original human failure boundary.
Reviewed the shared helper, its focused tests, receipt/session consumers, moved
S29 context tests, direct nested/finally paths and assembly/API assumptions.
Large whitespace-only wrapping changes were not dumped or treated as new logic.

The human evidence proves one old receipt-fixture Dispose access failure under
`C:\WINDOWS\TEMP`; it does not prove that all original business assertions passed
or explain every failed human case. This review does not change that boundary.

## Contract findings

1. **Root ownership and capture: supported.**
   `Tests/Editor/AICodedbTestWorkspace.cs:30-43` requires the Editor main-thread
   synchronization context and obtains actual `Application.dataPath`, without
   using an overridden `AICodedbPaths.ProjectRoot`. It derives exactly the actual
   project's `Library/CodeDB/Tests/run-<token>` root. `:46-61` initializes it before
   invoking synchronous or asynchronous test bodies. No system-temp, environment,
   Package-root, drive-search or privilege fallback exists in this entry.
   `:64-74` accepts only explicit descendants and rejects traversal/reparse paths.

2. **Explicit fixture propagation and isolation: supported.**
   `AICodedbManagerUiTests.cs:26-40` receives the owner, derives its receipt root
   from that owner, checks simulated project/Package containment, and registers
   receipt-scope restoration before journal admission can assert or fail.
   `:501-539` derives session project/Package paths from the same owner's unique
   session subtree and saves the original session before detaching it. Direct
   callers now enter `AICodedbTestWorkspace.Run` and pass that owner explicitly.
   Receipt Dispose restores its scope; the owner performs filesystem cleanup.
   The negative missing-predecessor fixture uses owned-tree deletion instead of
   unbounded recursive deletion. No production journal/storage policy changed.

3. **Capabilities and cleanup containment: supported.**
   `AICodedbTestWorkspace.cs:106-145` checks containment/reparse boundaries,
   rejects a preexisting run root, creates a unique ownership marker, and probes
   actual directory/file creation, readback and deletion before the body.
   Errors report operation and effective root without selecting another root.
   `:148-203` checks exact ownership and path boundaries before traversal and
   again before deletion. The full tree must pass the 4,096-entry/depth-32 bound;
   deletion is explicit files followed by empty directories, not recursive
   deletion of shared parents. The ownership marker is removed last.
   Parent/other-run targets and reparse boundaries are rejected. An unprovable
   owner or failed cleanup retains an identified residual path and fails.

4. **Primary errors, cleanup errors and restoration: supported.**
   `AICodedbTestWorkspace.cs:86-103` captures cleanup failures without throwing
   over a body exception. `:206-219` attempts remaining registered resources and
   filesystem cleanup; a sole primary exception is rethrown with its dispatch
   information, while simultaneous failures are preserved separately with the
   primary first and the workspace path recorded. Cleanup-only failure throws.
   `AICodedbManagerUiTests.cs:541-577` preserves constructor failure, attempts
   original-session/key/gate restoration separately, and records cleanup errors.
   Direct callers' finally blocks use the same capture boundary. The nested
   rejection, explicit Dispose and fault-path caller at `:1480-1529` retains its
   restoration assertions and per-owner key handling.

5. **Async entry and API assumptions: supported at source level.**
   `AICodedbEditorLifecycleTests.cs:17-94` puts the two S29 methods in
   `AICodedbS29ExecutionContextTests`, separate from the unrelated class's
   OS-temp SetUp/TearDown. The async method creates its workspace on the main
   thread before action overrides and `Task.Run`; existing action scopes still
   dispose around the awaited work. The helper awaits the body before cleanup.
   The new helper uses existing NUnit `Test`, `TestCase`, `Assert.That` and
   generic `Assert.Throws` conventions. It introduces no NonParallelizable,
   TestContext lifecycle assumptions or dependency/asmdef changes.
   `Rice.AICodedb.Editor.Tests.asmdef` retains Editor/TestAssemblies references;
   the declared Unity minimum is 2022.3. The added BCL APIs, including
   ExceptionDispatchInfo and Directory.EnumerateFileSystemEntries, are available
   for that target. These observations do not substitute for Unity compilation.

## Focused evidence and remaining acceptance

All nine new workspace cases were inspected in source
(`AICodedbTestWorkspace.cs:256-373`): owned root/probe, three capability failures
before body/no fallback, containment/ownership refusal, injected reparse boundary,
primary exception and scope preservation, primary plus cleanup errors, and
cleanup-only failure. They use test-owned fault injection rather than real ACL,
junction, system-temp or process changes. The paired metadata exists.

The unchanged business assertions remain inside the migrated receipt and direct
session fixture flows; the three S29 context cases retain their existing checks
under the new class. Coder's 902 Manager and 788 lifecycle assertion-line equality
results remain attributed source-consistency evidence; they were not rerun here
or relabeled as executed assertions.

Human scope remains exactly the Coder manifest: 38 receipt cases, 12 additional
direct session cases, 3 moved S29 context cases and 9 new workspace cases =
62 cases across 24 methods, all NOT RUN. Human filters must use
`AICodedbS29ExecutionContextTests` for the moved context methods. L0 remains
DEFERRED; C# compile/EditMode, original unattributed human failures, actual
project recovery/removal and release gates remain open. F-IMC-01/P3 was not
reopened. No new whole-product or theoretical hardening findings were added.

## Procedure and stop

No tests/compiler/Unity/MCP/CUA, live temp/receipt/process/ACL probes, Coder
contact, child agents, source writes, commit/export/push or automatic fixes.
Only this verification report was written. Review completed within 30 minutes.
No Coder validation batch was repeated. Prior reported deviations remain in
their original evidence records.

Reads used byte-checked slices within 4 KiB (normally 40 lines; two source slices
were 45/50 lines), and command/search outputs stayed below their limits. No
truncation was observed. Returned-output accounting before report generation
was 81,388 characters; adding 32,768 bytes of metadata/encoding headroom yields
a 114,156-byte reserve, below 128 KiB. This is a conservative reserve, not an
exact transcript-byte audit. One initial read-only path-inventory command had
PowerShell array-expression grouping wrong and returned path errors; it was
corrected without touching files or repeating validation evidence.

Stop this scoped review. Planner/User decides source acceptance and separately
authorizes the human compilation/EditMode handoff; this report does not ACCEPT S29.

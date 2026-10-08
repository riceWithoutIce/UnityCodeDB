# S29 owned test workspace - Coder stopped snapshot

Date: 2026-10-08. Active work approximately 04:05-04:20 UTC, within 60 minutes.
Base HEAD: `932e3e7ff695019ebebac9d3e7ba2f4b9e205105`.
Final source identities captured at 04:18:56 UTC; no later source edits.
Status: TEST_SOURCE_IMPLEMENTED / FOCUSED_STATIC_PASS / CSHARP_UNITY_NOT_RUN /
INDEPENDENT_REVIEW_PENDING. Whole S29 remains PARTIAL.

## Root design and implementation

The supplied human exception establishes failure while deleting the old receipt
fixture under `C:\WINDOWS\TEMP`. It does not establish that all business assertions
passed, or that every reported failing case had the same cause. Those other human
failures remain unattributed until the corrected human test gate supplies evidence.

Added `Tests/Editor/AICodedbTestWorkspace.cs` and paired Unity metadata. This helper
is a test-only fixture lifetime boundary, not a production storage or execution
platform. On the Editor main thread it captures `Application.dataPath` directly,
before test action overrides, and derives the actual project's
`Library/CodeDB/Tests/run-<unique-token>/`. There is no Package-root, OS-temp,
environment-variable, repository-search, sibling-root or privilege fallback.

The unique owner writes an ownership marker and probes file/directory creation,
readback and deletion before the body starts. Setup errors identify the operation
and effective path. Simulated session project/Package roots and receipt journals
are explicit descendants supplied by this owner. The receipt fixture registers
its context restoration immediately, so even a constructor assertion failure
cannot abandon the async-local receipt-root scope.

Cleanup revalidates directory-boundary containment, marker identity and reparse
ancestors before scanning and before each delete. It first validates a bounded
tree (4,096 entries, depth 32), then deletes exact files and empty directories;
there is no recursive `Directory.Delete(..., true)` in the shared cleaner. The
ownership marker is removed last. The existing missing-predecessor test uses the
same checked deletion entry for its owned stage subtree. Parent directories,
another run and historical/system leftovers are not cleanup targets.

Fixture resource restoration runs before filesystem cleanup. Dispose records
cleanup errors with the owner rather than replacing an in-flight body exception.
The entry rethrows a sole primary exception with `ExceptionDispatchInfo`; when
cleanup also fails, an AggregateException retains the primary as its first inner
exception, cleanup exceptions separately, and the workspace/residual path. Cleanup
failure without a primary still fails. Session restoration/key-removal failure is
also recorded explicitly, and remaining restoration steps are attempted.

## Changed consumers and scope

- Manager session fixture: all 17 constructor sites in 15 direct test methods
  receive the single per-test owner. Existing nested/fault-path fixture callers
  remain covered. Existing cleanup-finally blocks in these methods record cleanup
  errors separately. Business assertion statements were not weakened.
- Manager receipt fixture: root selection is delegated to that owner; Dispose
  restores its registered scope and leaves owned filesystem cleanup to the entry.
- The two S29 context methods moved into `AICodedbS29ExecutionContextTests` within
  the same lifecycle test file. This is necessary because their former class-wide
  SetUp/TearDown always allocated OS temp even when their local context did not.
  The unrelated original `AICodedbEditorLifecycleTests` setup and test family were
  left unchanged. Human filters must use the new S29 class name.
- No production C#, runtime script, asmdef, NUnit dependency or frozen contract
  was changed. The canonical workspace contract remains a read-only authority.
  Repository static validation created no scratch tree; it did not require a new
  repository runner or `.artifacts/tests` implementation in this correction.

## Evidence actually obtained

1. One existing focused command:
   `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`
   returned exit 0. Reported Package path provenance PASS and existing instance
   projection/binding checks PASS (3 helper projections, 2 PS bindings, 2 Node
   bindings). No default or ManagerActionWriterOnly branch was run.
2. One scoped `git diff --check`: PASS, exit 0. New untracked helper/metadata
   whitespace was separately checked in the source batch. Production C# diff
   listing was empty.
3. One bounded source consistency batch: PASS, exit 0. It checked explicit owner
   propagation, exact direct caller/case counts, retained assertions, workspace
   root/probe/ownership/reparse/bounded-cleanup/error invariants, separation from
   legacy lifecycle setup, and new-file whitespace. The complete assertion-line
   sequences remain identical to HEAD after trimming indentation: 902 Manager
   lines and 788 lifecycle lines. This is source evidence, not assertion execution.
4. Baseline/final SHA256 identities below. Existing source paths were clean before
   this repair. New helper and metadata had no baseline file.

L0 DEFERRED: no applicable pure Editor C# harness; no substitute compiler/runtime
was introduced. Human C# compilation, all EditMode cases, Unity/MCP/CUA/BatchMode,
fixture execution, real Install/Remove/replay, process/ACL probes and full
regression were NOT RUN. No old 48/11/201 batch ran. No test-generated project or
receipt directory was created by Coder; only source/evidence files were written.

## Exact human test scope: 62 cases / 24 methods, all NOT RUN

The original 41-case assertions remain: 38 receipt cases plus 3 S29 context cases.
Because the shared session fixture also serves eight other direct methods, those
12 cases are included in the next focused human handoff. Nine new workspace
cases bring the bounded total to 62; this is not an entire-class/full regression.

### AICodedbProjectSettingsTests - receipt methods (38 cases)

| Method | Cases |
| --- | --- |
| ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory | 4 |
| ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects | 7 |
| ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain | 11 |
| ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate | 4 |
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage | 8 |
| ManagerReceipt_ConflictWithoutAuthenticatedContextLabelsOriginalUnavailable | 1 |
| ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown | 3 |

### AICodedbProjectSettingsTests - additional direct callers (12 cases)

| Method | Cases |
| --- | --- |
| ManagerActionSession_RejectsOverlapAndRetainsResultAcrossWindowInstances | 1 |
| ManagerActionSession_ReloadRestoresUnconfirmedOutcomeWithoutRetry | 1 |
| ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission | 1 |
| ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation | 5 |
| ManagerActionSession_WindowCloseWithCommandRetainsResultWithoutClaimingReady | 1 |
| ManagerActionSession_WindowCloseWithoutCommandKeepsRecoveryAdmissionBlocked | 1 |
| ManagerActionSession_MissingCommandResultCannotReleaseAdmission | 1 |
| ManagerActionSession_UnconfirmedTransportFailureKeepsRecovery | 1 |

### AICodedbS29ExecutionContextTests - moved, same methods (3 cases)

| Method | Cases |
| --- | --- |
| LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait | 2 |
| ActionContext_NewIdentityResetsStageAndRestoresOuterScope | 1 |

### AICodedbTestWorkspaceTests - new (9 cases)

| Method | Cases | Focus |
| --- | --- | --- |
| TestWorkspace_OwnedRootUsesActualProjectAndProbesCapabilities | 1 | Actual project root, ownership/probe, action override isolation, final cleanup. |
| TestWorkspace_UnavailableCapabilityFailsBeforeBodyWithoutFallback | 3 | Test-owned create/read/delete fault injection, no body/fallback, setup evidence. |
| TestWorkspace_CleanupRejectsOutsideTargetAndChangedOwnership | 1 | Parent/traversal rejection and changed-marker refusal; marker restored within owner. |
| TestWorkspace_ReparseBoundaryIsRejectedBeforeTraversal | 1 | Test-owned injected reparse boundary; no real junction, ACL or system path change. |
| TestWorkspace_PrimaryFailureRestoresRegisteredScope | 1 | Exact original exception and receipt-root scope restoration. |
| TestWorkspace_PrimaryAndCleanupFailuresRemainSeparate | 1 | Both original exception objects retained, remaining scope restored and owned root cleaned. |
| TestWorkspace_CleanupOnlyFailureCannotPass | 1 | Cleanup-only error remains failure. |

## Identity manifest

Paths relative to `com.rice.ai-codedb/`:

| Path | Baseline SHA256 | Final SHA256 |
| --- | --- | --- |
| Tests/Editor/AICodedbManagerUiTests.cs | 9B9487C941A07B9127CD8E4CB28BFED08706E3905A8CC09BE030AFDFB1E992DC | 65EF3CF0E808F3DE8A50DC5F7183DF5D8D2C33588E3F9711125A5AF217CE4CDE |
| Tests/Editor/AICodedbEditorLifecycleTests.cs | 59BF754DF11E63F9EE3755EA4A8700069172DDA4D189F1885736BB5BFA4D2068 | B4D5520E89213B320F90C502DBBE4E690127AACDBB76B35B0008352DA92933FC |
| Tests/Editor/AICodedbTestWorkspace.cs | Absent (new) | DAB83A6DCAFC755388AA18B280058923EA8EBF71180C52B00998292BF9DA9714 |
| Tests/Editor/AICodedbTestWorkspace.cs.meta | Absent (new) | 2F0257CD7B69D4C5F60EC6F41B13D89E12551F1F856CF66B89BA67738DE6ACB4 |

New Unity metadata GUID: `ff0e0294ab9d49edb81462d11a0c134a`.

## Guard accounting and stop

No failed/repeated validation batch. Two planned mechanical adaptations wrapped
the inventoried Manager methods and the two S29 context methods; their body
assertions were then checked against HEAD. Searches and visible source slices
were bounded. Conservative output reserve is 97,200 bytes (64,000-byte allowance
for early output plus twice subsequent returned output string lengths), below
128 KiB; this is a conservative accounting reserve, not an exact transcript audit.
No observed guard breach in this pass. Prior passes' recorded breaches are not
erased or retroactively reclassified.

Coder is stopped at the exact manifest above. Parent may admit it for independent
workspace-contract/direct-consumer review. The open human project, frozen export,
live receipts, runtime generations, system temp leftovers and inherited dirty
files were not changed. No commit, export, push or publication. Human validation,
S29 real recovery and F-IMC-01/P3 remain separate deferred gates.

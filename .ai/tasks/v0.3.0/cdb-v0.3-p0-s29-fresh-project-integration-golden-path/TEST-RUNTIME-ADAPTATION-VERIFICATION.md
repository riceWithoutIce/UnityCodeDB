# S29 test runtime adaptation - independent verification

2026-10-08. SOURCE_REVIEW_PASS within the frozen test-runtime adaptation scope.
No actionable source finding identified in the two reported failure classes or
their immediate regressions. HUMAN_COMPILE_DISCOVERY_TEST_PENDING remains open.
Latest human acceptance remains failed; this report is not a claim that the new
source has compiled, been discovered, passed Unity tests, or closed S29/release.

## Snapshot

Coder was stopped before review. Read active TASK, complete RESULT/IDENTITY,
canonical workspace revision and narrow changed-source slices. Independent
checks matched all nine final hashes and all nine baseline hashes against FIX01.
Exactly TestWorkspace, ManagerUi and EditorLifecycle tests changed; the six
production/script files remained identical. HEAD/index/branch match the packet:

- HEAD: df91ef6a279ba0ffd3387ff00369137a5878df04
- Branch: codex/v0.3.0-legacy-workflow
- Index SHA256: DB534FC6FA1C87089AA41937D3F941A8129BF11BF9807CF7DA488ADDD093BFA0
- RESULT SHA256: 8093E0EECF09BEB94D70249C468A78C2872C762305698B8281550FF0A39798EC
- IDENTITY SHA256: 480982AA59A9431DBA96277EF91A393B7C1420C12FE5ABC3EAB30A2BCEE2F284

Final changed files, relative to com.rice.ai-codedb:

| File | SHA256 |
| --- | --- |
| Tests/Editor/AICodedbTestWorkspace.cs | 0A6937B7EF035E37748DABC15E7C49A6D7EF2F1C3A86DC936E935F2ABF3F56BF |
| Tests/Editor/AICodedbManagerUiTests.cs | C0C3252660EF36C3B6E6948CA3D340348F33DF70C6A564470A5DDC235E6214B6 |
| Tests/Editor/AICodedbEditorLifecycleTests.cs | CA1DDD9C2355F52C3A93F60BC68A9878FE50953765F14B343AA9E7C8BE3F4951 |

All other exact verified hashes are preserved in the authenticated adaptation
IDENTITY. Staged diff is empty. Existing dirty documentation and live/exported
artifacts were not changed by this reviewer.

## Legacy path feasibility and ownership

TestWorkspace.cs now derives one workspace from actual Application.dataPath:
Library/cdt/<8 lowercase hex>, retaining the full32hex token. The same parent
CreateNew reservation, existing-directory rejection, no retry/adoption and owner
marker checks remain (Initialize :124-149). No previous workspace migration or
cleanup is introduced.

The default Compact profile still enumerates production required record/temp/
journal paths. CompactAndLegacy appends all four legacy evidence kinds through
GetManagerActionReceiptRoot and GetManagerStageReceiptPath with explicit null
layout (:175-198). It preserves Project24/Package24/Action32/Stage64; it does not
substitute compact paths or add unused historical writer temporary files.
ManagerUiTests changed only the two intended profile arguments at :1231 and :1344;
their existing legacy recovery and historical-marker assertions remain unchanged.

Before each probe write, the workspace validates ownership/containment/reparse
boundaries; it uses CreateNew and actual System.IO create/read/delete. Missing
directories are individually recorded when created, then removed in reverse order
with ownership revalidation and nonrecursive Directory.Delete (:199-246). Existing
directories are not adopted into this probe-removal list. A failed probe exits
before body execution and disposes the receipt-root scope; outer owned cleanup
retains primary and separate cleanup failures (:308-329). Diagnostics include
profile/layout, operation, path and length. No skip, fallback, numeric admission
limit, environment/OS setting or production storage change was introduced.

Arithmetic independently checked: the root revision saves13 characters. The
provided S29 root length98 becomes85. Full legacy admitted adds162 characters:
25 project +25 Package +33 Action +65 Stage +14 filename/separator =247 total.
Start-failure adds167 =252 total. These are path calculations, not measured Unity
System.IO results or guarantees for arbitrary project roots.

The new profile test (:415) covers both profiles, verifies four legacy paths only
when requested, probes an owned representative root of at least85 characters,
checks all files and created directories were removed and reports deepest paths.
The legacy failure test (:472) covers create/read/delete faults, fail-before-body,
exact diagnostic path/length, scope restoration and owned root/reservation cleanup.
Existing ownership, collision and primary/cleanup tests remain in the manifest.

## Async test entry adaptation

EditorLifecycleTests.cs:21-38 exposes two distinct parameterless [UnityTest]
IEnumerator methods for terminal/nonterminal. The shared enumerator starts the
original async helper on its first main-thread MoveNext, yields null while its
Task is incomplete, then calls GetAwaiter().GetResult() only after completion.
There is no blocking wait on an incomplete Task, async void entry, swallowed
assertion, Task-returning NUnit case or test-framework upgrade.

The helper retains main-thread workspace capture before its first await. Its
real Task.Run/Task.Yield/await assertions, action-scope restoration and cleanup
remain intact. An independent exact comparison of the original async body against
HEAD, after newline normalization, returned equal. Fault/cancellation reaches the
enumerator through the completed Task awaiter; the workspace still preserves the
primary exception through ExceptionDispatchInfo when cleanup succeeds. The separate
identity-reset test remains in AICodedbS29ExecutionContextTests.

This is the requested source entry shape for the locked runner. Actual Unity
import/compile and discovery of both entries remain human validation, not facts
established by this source review.

## Merged manifest and evidence boundary

Independent line-based source attribute inspection matches the RESULT inventory:
39 methods /88 cases, with zero count mismatches:

- AICodedbProjectSettingsTests:24 methods /68 cases.
- AICodedbTestWorkspaceTests:12 methods /17 cases.
- AICodedbS29ExecutionContextTests:3 methods /3 cases.

The original34/80 remains; two old async cases become two wrapper methods plus
the prior identity-reset case (37/83), then two new workspace methods add five
cases (39/88). No unresolved prior context case disappears from the inventory.

Coder's single PathProvenanceOnly PASS and scoped diff-check PASS are retained as
reported non-Unity evidence, not independently rerun. Unchanged writer/fixture
script hashes retain attribution of earlier PS12/12, without new PS execution.
All C# compile, Unity discovery,88 test executions and actual Unity full-path I/O
remain NOT RUN. Prior failed human evidence remains valid history.

## Procedure and stop

Only this report was written. No implementation edits, Coder contact, recursive
agents, production receipt re-audit, test reruns, C# substitute, Unity/MCP/CUA,
live project/process/state access, real cleanup, commit/export/reference switch
or external publication occurred.

Captured shell output was approximately57 KiB, within the64 KiB cumulative review
budget and20-minute window. Two early combined output commands exceeded the
80-line per-read/command bound: the75-line RESULT slice plus canonical diff, and
the RESULT tail/search plus two-file diff. No output was truncated. These are
procedural deviations, not retroactively compliant reads; later narrow slices do
not erase them. The Coder's separately disclosed read-limit breaches likewise
remain historical. Source conclusions above are limited to the inspected frozen
scope and do not assert procedural perfection or runtime success.

The source review is complete. Stop here; human compile/discovery/execution of
the next accepted artifact remains a separate gate.

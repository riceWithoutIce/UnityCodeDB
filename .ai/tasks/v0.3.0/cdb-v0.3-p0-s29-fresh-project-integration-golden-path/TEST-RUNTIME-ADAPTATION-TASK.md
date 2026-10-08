# S29 test runtime adaptation and merged acceptance closure

2026-10-08. User approved the single continuous task after alignment of the three
human failures. IMPLEMENT authorized. FAST_SUBAGENT / STANDING_WORKFLOW, one Coder
then independent Verifier, no recursive agents. Architecture choices frozen below.
Base HEAD df91ef6a279ba0ffd3387ff00369137a5878df04 on codex/v0.3.0-legacy-workflow.
Unity presumed open on immutable export; do not access it or switch refs. Source
edits in checkout are separate from that export. Preserve all inherited dirt.

## Proven symptoms and scope

ManagerActionRecovery_ClaimWithoutTerminalStaysUnknownAndStartFailureIsDistinct
fails before its assertions at ManagerUiTests:1180. It explicitly selects legacy
layout with null. Supplied path length260, parent246, after CreateDirectory;
long-path behavior is the leading cause, not independently reproduced runtime
proof. Longest legacy start-failure would be265. Do not convert the legacy test
to compact format or claim the recovery logic failed.

LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait(true/false)
both fail Test Runner admission: Method has non-void return value, but no result
is expected. Existing entry is TestCase+async Task. Project locks Unity Test
Framework1.1.33/ext.nunit1.0.6; do not upgrade. It never reached the body.
Current asmdef already has optionalUnityReferences TestAssemblies.

## Frozen implementation decisions

One shared Unity test root becomes actual project Library/cdt/<8lowercasehex>/.
cdt means CodeDB tests. Full32hex owner token and existing parent CreateNew
reservation remain, one allocation attempt, explicit collision failure/no adoption.
No helper chooses its own root, no OS temp, hardcoded project path, reparse escape,
ACL/env change, drive alias, global OS setting or production storage change.
Never move/delete previous Library/CodeDB/Tests or exported artifacts.

Expose explicit workspace capability selection: default compact, optional
compact+legacy chosen by the two existing legacy receipt tests before test body.
Keep current compact path/temp/journal probe through production path helper.
Add legacy probe through GetManagerActionReceiptRoot/GetManagerStageReceiptPath
with null layout, retaining full hierarchy; create/read/delete all four evidence
filenames using real System.IO. Legacy readers use existing journal paths already
probed. They do not launch the old writer, so don't append unused atomic suffixes
to read-only legacy fixtures or introduce old writer execution.
Remove only proven probe-owned empty directories before test body. Error includes
layout/operation/path/length and restores scopes, retaining primary/cleanup errors.
Keep owned cleanup and full-identity rules unchanged. Current project arithmetic:
legacy admitted247/start-failure252. No arbitrary path-length admission constant:
actual API probe decides availability, no skip/fallback/false PASS. Authored deep
coverage includes both profiles and reports actual measured paths.

Async entry: replace two parameterized Task TestCase cases with two distinctly
named parameterless [UnityTest] IEnumerator wrappers in AICodedbS29ExecutionContextTests.
Use a shared helper for terminal true/false, preserving all real Task.Run/await
assertions and main-thread workspace capture. Yield while task incomplete; after
completion propagate original failure/cancellation. No async void, Wait/Result,
blocking main thread, suppressing assertions or returning Task to NUnit. Existing
ActionContext_NewIdentityResetsStageAndRestoresOuterScope stays in the same class.

## Exact write allowlist / roles

Relative to com.rice.ai-codedb:
- Tests/Editor/AICodedbTestWorkspace.cs (shared root/profile/probe+focused tests)
- Tests/Editor/AICodedbManagerUiTests.cs (two explicit legacy fixture callers only)
- Tests/Editor/AICodedbEditorLifecycleTests.cs (S29 context class entry adapters only)

No production Editor code, scripts, asmdef, metadata, generation, live project,
machine state or old artifact edits. Planner owns canonical docs and task/checklist.
Coder writes TEST-RUNTIME-ADAPTATION-RESULT.md and TEST-RUNTIME-ADAPTATION-IDENTITY.json
only beyond three sources. Verifier writes TEST-RUNTIME-ADAPTATION-VERIFICATION.md
only after stopped snapshot admission. Read this card, canonical workspace contract
and direct named APIs; no whole historical TASK/reports or large source dumps.

## Evidence and merged human manifest

Inspect both legacy callers, compact/legacy setup profiles, exclusive allocation/
cleanup, Task-to-coroutine propagation and preservation of original assertions.
One PathProvenanceOnly and scoped diff-check, plus source test inventory. No C#
compiler/Unity substitute, Unity/MCP/CUA/BatchMode/process probe, real Host/Provider,
writer batch rerun, full regression, real cleanup or mutation. Production/scripts
unchanged: retain prior evidence at hashes, don't rerun PS12/12. Children cannot
commit/export/switch references/push/publish.

Merged manifest starts with all34methods/80cases in RECEIPT-LAYOUT-HUMAN-CHECKLIST.md
plus prior3 context cases from TEST-WORKSPACE-HUMAN-CHECKLIST.md. After two coroutine
wrappers this is37methods/83cases before focused new workspace tests. Inventory
every addition/rename and exact case count; preserve all prior business assertions.
Do not infer complete suite PASS from screenshot counters. Human compile/discovery/
execution remain NOT RUN until a new accepted delivered artifact is checked.

Coder<=40min/96KiB cumulative; reviewer<=20min/64KiB. Read<=80lines/8KiB, search
<=30matches. Result<=8KiB, exact baseline/final SHA256 for three changed sources
and original other implementation/script files from FIX01 identity, HEAD/index.
Initial+at most2 justified corrected non-Unity checks, no blind retry. If production
or broader scope redesign becomes necessary, stop with consolidated reassessment.
Stop stable; review only the reported two failure classes and immediate regressions.

## Human evidence retained

Screenshot0dbd9542: C622FBAAABF9FA941DC3E4E833D1A9FDE74A9731FD796E388773CD7AED0F8DD6.
Screenshot50859f0b: E51F5D82D2FF6607D469EDC81596D217F2EA483123B968AD69EEBB349A04E080.
Screenshot4e200d7c: 59C39CEE2F4F42A821275D65CE99B115122FC3F26D6B4F63BEF88D35C21440CE.
Human artifacts are evidence only. Source ACCEPT is historical scope; latest human
acceptance FAILED, S29 PARTIAL. No closure inferred from previous source/PS counts.

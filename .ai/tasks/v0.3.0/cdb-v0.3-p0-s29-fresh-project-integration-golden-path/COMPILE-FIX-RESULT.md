# S29 Compile Interface Repair Result

Status: SOURCE_FIX_READY_FOR_REVIEW.
Evidence: FOCUSED STATIC/SOURCE ONLY, not C# compilation, EditMode, Ready, integration, S29 ACCEPT or release PASS.

## Entry and baseline
Read COMPILE-FIX-GRANT.md first and TASK only at Import Compile Failure/latest closure/routing. Human project closure is confirmed by the grant, not an agent probe. Same v0.3.coder.deep, DURABLE_SESSION/REUSE_ONLY, settings unchanged; no child/session override. Actual model/reasoning unavailable (not exposed).
Branch: codex/v0.3.0-legacy-workflow
Base HEAD: 306f329b8f51f82695dccc5e8de67c6bcea5320e
Actual stable HEAD: 306f329b8f51f82695dccc5e8de67c6bcea5320e
Preflight three paths clean; all baseline SHA-256 rows matched. Inherited dirty/untracked content preserved; no reset/clean/stash/rebase/commit.

## Cause, changed subset and symbol mapping
Frozen human diagnostic: CS1503 at ProjectIntegrationState.cs:339/341/342, IDictionary origin passed to Dictionary-only GetRequiredString. Raw human screenshot/compiler text not reread/reproduced; attribution reused from TASK/grant.

Only two source/test files changed under com.rice.ai-codedb/:
- Editor/AICodedbStrictJson.cs: exactly two parameter declarations, Dictionary<string, object> -> IDictionary<string, object>, in GetRequiredString and private GetRequiredProperty; 2 added/2 removed lines. All method bodies/parser/property/type/missing-value exceptions unchanged; no overload/duplicate reader/cast/dynamic/suppression.
- Tests/Editor/AICodedbEditorLifecycleTests.cs: 39 inserted lines, two methods / five authored cases:
  InstanceOrigin_InterfaceDictionaryUsesRequiredStringBoundary: non-Dictionary SortedDictionary via IDictionary, original origin validator and concrete ParseObject neighbor.
  StrictJson_RequiredStringRejectsInvalidInterfaceValue: missing/null/wrong-type/null-object.
- Editor/AICodedbProjectIntegrationState.cs byte unchanged; legacy absent/null origin, three exact fields, INSTALL/UPGRADE/REINSTALL and both strict lowercase 32-hex-ID checks retained.
All existing test content outside the new block, including ten prior InstanceOrigin_* cases, unchanged. Authored tests NOT EXECUTED.

IDictionary origin -> GetRequiredString(IDictionary) -> GetRequiredProperty(IDictionary) -> unchanged TryGetValue/missing check and string/type rejection. Dictionary parser outputs remain compatible. Six required helpers use the coupled property reader; existing integer/boolean/array/nullable-string/parser signatures and bodies preserved.

## Focused evidence and attempts
One initial signature/call-chain static/source batch PASS: exit 0, native 0.367 s, tool 0.4709154 s. Checked exact baseline plus two signatures; unchanged state/all original tests; origin guards; coupled helper/null/type/missing rejection; scalar/parser neighbors; unique direct regression block and four negative parameters.
Ten caller files / 496 required-string calls inventoried: 493 existing + three new regression calls. Simple first-argument shape checked; this is source consistency, NOT compiler type-checking.

Static batch 1/1; corrected semantic attempts 0/2. Mechanical lookup correction 1, separate: guessed protocol file absent; diagnostic command exit 1:
rg: com.rice.ai-codedb/Editor/AICodedbSupervisorProtocol.cs: IO error for operation on com.rice.ai-codedb/Editor/AICodedbSupervisorProtocol.cs: 系统找不到指定的文件。 (os error 2)
Symbol locator found AICodedbSupervisorProtocol in AICodedbSupervisorBridge.cs; IsManagerActionId definition read only. No blind replay/new production cause.

One final command:
git diff --check -- com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs com.rice.ai-codedb/Editor/AICodedbStrictJson.cs com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
Exit 0, empty output, tool 0.2220606 s.

One final three-full-file SHA-256/canonical identity generation: exit 0, native 0.323 s, tool 0.4336138 s. Branch/HEAD/scoped status/numstat confirm only the two changed allowlist files.

## Canonical identity
COMPILE-FIX-IDENTITY.txt is only these ordered rows, UTF-8/no BOM, two spaces, LF including final row:
34ea23e11d5b0704c57cd4048a1bd9450fd5134780c9b8d504c5ea792b77dcac  com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs
ae607244e11097b890e7071ed5b0472b207a5a22e6ce7af40b076908fe48bd05  com.rice.ai-codedb/Editor/AICodedbStrictJson.cs
9c9f12c2884ac4dc963a330178581379e75c061a0fbcd6cff3fcd4c2adf4afad  com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs

Canonical SHA-256 of the exact 371-byte text:
e81b9e86379b48b28e06feb07e73720cb37cf422e364016b1678cc5bd06c9c55
No patch-id/full-repository identity. Final record size/UTF-8/equality closure is reporting only; no source hash/static/diff replay.

## Command receipts
Tool wall seconds. Full invocation/range scripts and raw outputs retained in this Coder turn. Index/range reads are retrieval, not repeated evidence batches.

| Command/operation | Exit | Tool wall s |
| --- | --- | --- |
| grant-read | 0 | 0.2407845 |
| memory-boundaries | 0 | 0.0000259 |
| task-section-index | 0 | 0.0000078 |
| bounded-preflight | 0 | 0.3985064 |
| latest-task-grant | 0 | 0.0000265 |
| strict-json-index | 0 | 0.0000177 |
| origin-index | 0 | 0.1202263 |
| direct-test-index | 0 | 0.2100227 |
| strict-json-contract-read | 0 | 0.0000207 |
| required-property-coupling-read | 0 | 0.0000167 |
| origin-and-id-contract-read | 1 | 0.0000151 |
| origin-direct-tests-read | 0 | 0.203642 |
| affected-caller-file-index | 0 | 0.1946847 |
| protocol-path-lookup-correction | 0 | 0.2119171 |
| affected-call-argument-inventory | 0 | 0.3082694 |
| resolved-strict-id-definition | 0 | 0.2767611 |
| focused-static-source-batch-initial | 0 | 0.4709154 |
| final-three-path-diff-check | 0 | 0.2220606 |
| stable-three-path-canonical-identity | 0 | 0.4336138 |

Window: 2026-10-06 23:42:39 UTC+08:00 start; 2026-10-07 00:12:39 deadline. Checkpoint 2026-10-06 23:57:02 UTC+08:00; elapsed 863s, no renewal. Active/paused unavailable; compactions observed in this repair window 0; earlier count unavailable.
Known captured stdout/stderr 48255 UTF-8 bytes / serialized receipts 52829 bytes through source identity; later compact reporting/framework overhead excluded/unavailable. Normal 32 KiB/200 lines, rg 16 KiB/50 matches, cumulative 128 KiB guards; no captured-output breach. One 8414-byte report draft rejected before writing and shortened; no file limit exceeded or evidence retry.

## Deferred boundaries and completion routing
C#/compile/EditMode/Unity/MCP/CUA/BatchMode/real Install/Remove/reinstall NOT RUN. Backend L0/L1, closure/path-provenance/FirstInstall not replayed. No compiler/harness/install, runtime/Provider/process/global-config/history/candidate operation, Git/remote/publication/export.
Old failure Package and .artifacts bytes preserved; no version/metadata/Tools/Payload/poc.39/consumer manifest/lock/TASK/grant/contract/roadmap/workflow/old-role-record edits. Only new records: this report and COMPILE-FIX-IDENTITY.txt.

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: SOURCE_FIX_READY_FOR_REVIEW
Next notification: UnityCodeDB v0.3 Planner (return in this thread/records, no automatic cross-thread message)
Next action: admit stopped canonical snapshot, then targeted independent review of CS1503 boundary/origin semantics/direct JSON neighbors.
Human authorization required: findings disposition; exact frozen source commit before new delivery; later human compile/test/action retry, S29 ACCEPT and release. Stop here.

## Narrow retained path identity compile correction — 2026-10-09

Human Unity compile exposed one unresolved test symbol in the retained path
identity continuation. The single call in `Tests/Editor/AICodedbManagerUiTests.cs`
now qualifies the existing helper as
`AICodedbControlContractMigrationClassifierTests.SerializeObject(record)`.
No runtime/source helper, evidence, Payload, or unrelated test code changed.

Base HEAD: `9330930b037c5ab9ed73829c9580965280bcf997`.
Post-fix SHA256 (`Tests/Editor/AICodedbManagerUiTests.cs`):
`25c8b5a72b69567591f6e000d0b329d86f92aeb68065f3fff88b759a69804fa4`.
Validation was limited to exact diff inspection; no broad Unity or evidence rerun.

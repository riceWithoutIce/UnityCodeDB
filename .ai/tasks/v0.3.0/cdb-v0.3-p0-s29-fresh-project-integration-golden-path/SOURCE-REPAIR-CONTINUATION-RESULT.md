# S29 consolidated source-repair continuation result

Task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Scoped status: SOURCE_REPAIR_COMPLETE / SCOPED_NON_UNITY_EVIDENCE_PASS
Overall real-project integration: BLOCKED

Workspace: G:/RiceProgram/UnityCodeDB
Branch: codex/v0.3.0-legacy-workflow
Base/final HEAD: b15292f8978272244e605805a9ec064049141ee2
Window 03 input SHA-256: 2f3dd9fb152e76addedccea62d1185bbc59c3fcfc401cfe8b2d000b1547db70d
Final fifteen-path SHA-256: 7a3556f686f359b93070e606a4bf51895c45a42773e22cb77cecf33d5006ffd8
Profile/session: inherited v0.3.coder.deep, DURABLE_SESSION / REUSE_ONLY.
Actual model/reasoning: unavailable; not inferred from the profile/tool catalog.
No new task/chat/agent, model override or automatic Window 04.

## Outcome and applicability

All required remaining isolated non-Unity gates closed. Window 03 changed only two direct C# test files and the Node fixture/test. All production hashes and the PowerShell materializer-harness hash still match the Window 03 admitted input rows. Window 03 therefore did not invalidate the recorded Window 02 FirstInstallAttributionOnly coverage.

FirstInstallAttributionOnly was NOT RUN here. Its initial +2 corrections are exhausted (3/3). Reuse is of the earlier attributed execution, not a fresh replay or independent proof that every current byte was tested. Planner's input fingerprint admits this draft, not semantic/product acceptance.

Nineteen new C# cases are authored/source-checked only. No C# compile/EditMode or actual Unity/Provider/project integration PASS is claimed.

## Consolidated implementation

Inherited production changes retained byte-for-byte in Window 03:

- ProjectIntegrationState: distinct NotIntegrated/CanInstall, without fabricated UNINSTALLED/state_id. Existing anchors, project MCP registration, blocked/invalid contract or unknown namespaces cannot establish first Install.
- ControlContract: readonly exact current Supervisor-only namespace, ordinal matching/reparse guard; optional origin validation in v1 owner observation.
- Lifecycle: current migration read before integration classification; NotIntegrated publishes cache and returns before admission, with automatic Supervisor start and lease disabled.
- StatusSnapshot/Manager: inactive NotIntegrated, explicit Overview/Setup/primary Install, no cached Checking. Authenticated Uninstalled/reinstall remains distinct; unknown action history does not replace current product state.
- Engine: additive action/action_id/operation_id is documentary, not ownership authority. A durable PROVISIONING instance.json is staged and atomically published before candidate effects. Original command failure, unknown execution effects and cleanup are distinct; retained/unproved attempts stay PENDING rather than fabricated COMPLETE.
- First Install accepts absent control or canonical current Supervisor-only control plus materializer runtime, not unrelated existing resources. Authenticated reinstall remains supported.
- Existing serial verified-candidate activation and strict next-change binding remain authoritative. Window 02 made current-Supervisor preservation an explicit transaction-bootstrap option; default fresh rejection and other namespace/journal checks remain.
- Existing Supervisor operation forwards original IDs to the main materializer/convergence. No second queue/owner, retrospective attribution, real candidate adoption or bypass.

Window 03 additions:

1. Lifecycle tests (18 authored cases): valid Supervisor-only first Install; obsolete/ambiguous and invalid-current contract refusal; additional legacy/foreign/activation/unknown-runtime evidence refusal; absent/null legacy origin; INSTALL/UPGRADE/REINSTALL origin; invalid action/IDs/extra/missing/nonobject origin.
2. Manager test (1 authored case): cached NotIntegrated remains inactive and Install-capable without uninstall history/Checking, even with the cache's in-flight flag. Existing history/primary/restore cases remain.
3. Node fixture records original IDs at its synthetic child boundary; the runtime correlation assertion checks action/operation IDs against the existing durable operation. Lost acceptance, conflicting/unrelated action and restart checks remain. No production marker branch.

## Writer/resource map

| Owner | Resource/boundary |
| --- | --- |
| Existing Supervisor operation | Original IDs passed to its existing materializer child; no new authority. |
| Candidate/convergence writer | Project-bound runtime-derived transaction/staging root; PROVISIONING instance.json with origin before effects, then atomic publication under AIWork/.runtime/codedb/instances/<id>. |
| Existing activation/operation writer | Verified candidate precedes selection; PREPARED/ACTIVATING/COMMITTED, project/hash/retirement and next-change checks remain authoritative. Origin cannot admit mutation. |
| Current/retired PS and current/v1 C# readers | Optional origin is validated within existing ownership/generation evidence. Legacy absence/null accepted; malformed declaration refused. |
| Worker/Manager cache | Worker owns filesystem/status evidence; Manager display does not create identity/history/ownership. |
| Isolated fixtures | Runtime-derived temporary roots and mocked native outputs. Node uses fixture-owned Supervisor/Coordinator/PowerShell children with existing finally cleanup, not actual Provider/business processes. |

No real retained candidate, protected runtime, user-local history or global configuration was read/adopted/cleaned/rebound.

## Final changed subset

13/15 paths changed from HEAD (relative to the workspace above):

- com.rice.ai-codedb/Editor/AICodedbControlContract.cs
- com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs
- com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs
- com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
- com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs
- com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs
- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
- com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
- com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
- com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1
- com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
- com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1

AICodedbActions.cs and AICodedbManagerActionJournal.cs are unchanged from HEAD/input. Window 03 modified only AICodedbEditorLifecycleTests.cs, AICodedbManagerUiTests.cs and test-codedb-project-supervisor.mjs.

SOURCE-REPAIR-CONTINUATION-IDENTITY.txt contains exactly fifteen ordinal-sorted rows: relative path + TAB + lowercase SHA-256(actual bytes), LF joined, final LF, UTF-8/no BOM. Its canonical digest is above. Source identity was calculated once.

## Commands, exit, wall and outputs

Exact invoked focused commands from repository cwd (capture wrappers only bound/sanitize output and preserve the native exit):

| Gate | Command | Evidence |
| --- | --- | --- |
| Window 02 reused first Install | powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 -FirstInstallAttributionOnly | exit 0, 26 cases, native_children=0, harness 16.565 s, reported emission 3,258 bytes; no Window 03 replay. |
| Next-change | powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 -NextChangeAdmissionIntegrationOnly | exit 0, 45 cases, native_children=0, harness 21.733 s, 47 native/emitted lines and 3,184 bytes. |
| Correlation | RICE_CODEDB_SUPERVISOR_TEST_FILTER=manager-action-correlation node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs | exit 0, correlation/restart/new original-ID assertion PASS; 1 native/emitted line, 107 bytes. Process environment set/restored in finally. |
| Provenance | powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly | exit 0, Package path provenance PASS; native wall 4.460 s/tool 4.614812 s; 1 native/emitted line, 33 bytes. |
| Static/source | One inline bounded PowerShell AST/Node syntax/scoped lexical-source batch | exit 0; measured batch wall 0.748 s/tool 0.870599 s; 14 semantic assertions PASS; CSharp_execution=DEFERRED. |
| Scoped whitespace | git diff --check HEAD -- <the exact fifteen explicit paths in the identity file> | exit 0, tool wall 0.257591 s, empty output; no full diff. |
| Final identity | One inline ordinal/TAB/SHA-256/LF/UTF-8 actual-byte calculation; git rev-parse HEAD; git branch --show-current; git -c core.quotepath=false diff --name-only HEAD -- <same fifteen explicit paths> | exit 0, tool wall 0.409721 s; HEAD/branch retained, 13 changed paths and final digest above. |

Next-change started 13:48:32 UTC; final observed exit 13:49:31 (59 s including polling/continuation); actual tool wait 10.005929 s. Correlation started 13:50:21; final observed exit 13:51:28 (67 s including polling/continuation); tool wait 10.002434 s. Full process wall for these yielded sessions is unavailable; neither tool wait nor observed wall is presented as native elapsed. The same sessions were resumed, never restarted.

Capture wrappers capped emitted output at 100 lines/24,000 bytes, sanitized temp prefixes and emitted native/emitted counts. No focused timeout/warning threshold was reached.

Static/source subcommands and assertions:

- Management.Automation.Language.Parser::ParseFile on engine, main materializer and materializer harness: zero errors, no production invocation.
- AST: candidate StageRoot/OriginatingAction; manifest before Directory.Move; PENDING/COMPLETE; direct origin readers Get-ValidatedCurrentInstance/Get-ValidatedRetiredInstance.
- node --check com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
- node --check com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
- Inline source body piped to node --input-type=commonjs. Body SHA-256: 95a5918be73cf273ff0c959ccf991dbdf7fd29e0f0a6456c5568fafa8fa9b224. Selected C# bodies lexed with string/comment handling, not whole-file brace counting.
- 14 checks: current migration/contract; existing anchors; exact Supervisor namespace; legacy/malformed origin; fixed actions/IDs; current/v1 origin readers; migration-before-classification; early cache return/no lease/start; inactive cache/not Checking; cache constructor no filesystem/hash/process/store reads; primary/Setup Install; authored regressions; history independence; single-operation ID forwarding.
- Inline commands are attributable in this execution record; only bounded inputs/subcommands/assertions/hash are repeated here, not whole transcripts.

## Failures and attempt accounting

Window 02 FirstInstallAttributionOnly:

1. Initial exit 1; tool wall 8.236331 s: “Activation contract namespace is not fresh: unexpected entry supervisor”. Corrected explicit current-Supervisor preservation while retaining default rejection.
2. Correction 1 exit 1; tool wall 5.838612 s: “Cannot bind argument to parameter 'RelativePath' because it is an empty string.” Fixture script-scope construction, not production path relaxation.
3. Correction 2 exit 0 as above: unchanged production definitions/preambles share one New-Module; script-local native seams remain synthetic. Starts 3/3, corrections 2/2 permanently consumed.

Window 03:

- Next-change/Node/provenance/static: each initial 1, corrections 0/2.
- Final scoped diff-check 1; final source identity 1; neither repeated.
- Source-navigation command exit 1/tool 0.377620 s at a pre-emission >50-match guard; source matches were not emitted. Query narrowed; not an L0 retry or product failure.
- Result prewrite size guard refused a 17,454-byte draft before any file write. Shortened documentation only; no source/gate rerun.
- Prior mechanical count 1 retained from inherited summary. Window 03 navigation correction 1 and document composition guard 1 are disclosed separately; not invented as behavioral retry consumption.
- Window 03 observed compactions 0; earlier/full-history count unavailable. New independent product causes here 0.
- No reset/clean/stash/rebase, commit/tag/push/publication, Verifier contact or unsolicited cross-chat reply.

## Windows and output facts

- Window 01: inherited conservative elapsed 59m52s and 255,951 captured UTF-8 bytes; prior guard breach retained, not retrospectively compliant.
- Window 02: first action 2026-10-05 08:50:09 UTC / 16:50:09 client time; expiry 09:50:09 / 17:50:09. No revival/discount. Cumulative output unavailable after inherited state loss; prior 50–70 KiB was only an estimate. Exact reported FirstInstall emission 3,258 bytes retained.
- Window 03: first action 2026-10-05 13:40:45 UTC / 21:40:45 client time; deadline 14:40:45 / 22:40:45. Active/paused unavailable; conservative elapsed used.
- Source freeze 14:02:55 / 22:02:55, elapsed 22m10s.
- Accounting at 14:05:48 UTC: known stdout/stderr 68,366 UTF-8 bytes; serialized ledger result payloads 73,759 bytes. Kickoff grant-read captured size unavailable; conservatively reserve 32,768 bytes, not a fabricated measurement. Known serialized payload plus reservation 106,527 bytes before small artifact checks, below cumulative 131,072 guard. Unavailable framework/control-message overhead excluded.
- No normal command output exceeded observed 32 KiB/200 lines. Oversized navigation matches were blocked before emission; no repository-wide/source/log/history dump.
- Final small artifact checks/timestamp are recorded in the closing entry.

Old SOURCE-REPAIR-RESULT.md/SOURCE-REPAIR-IDENTITY.txt, Stage A RESULT.md/HUMAN-CHECKLIST.md, TASK.md, roadmap/index, four readonly contracts and inherited unrelated dirty state remain untouched. Old identities/admission were not recalculated.

## NOT RUN / DEFERRED and risks

NOT RUN: exhausted first-Install replay; whole suites, unrelated or predecessor reruns.

DEFERRED / NOT AUTHORIZED: C# compile/L1/EditMode; Unity/MCP/CUA/BatchMode; actual Provider or project/user-local/global/protected runtime inspection; actual Install/Remove/Reinstall; retained candidate adoption/cleanup/rebinding; consumed artifacts/immutable generations; export/package switching, remote Project writes, commit/tag/push/publication.

Nineteen C# cases require separately authorized execution. Origin is documentary, never admission. Unknown effects stay unresolved/PENDING; original real candidate remains untouched. This scoped PASS proves neither current Ready/shutdown/runtime behavior nor real-project recovery/overall S29/S25/S28 closure.

## Handoff closing entry

- Artifact check: exit 0/tool wall 0.225587 s; pre-closing RESULT 15,380 bytes; identity 1,831 bytes, exact fifteen captured rows, LF/no BOM. No source rehash.
- Window 03 reporting closes 2026-10-05 14:16:00 UTC / 2026-10-05 22:16:00 client time; conservative elapsed 35m15s. Active/paused unavailable. Original 60-minute deadline retained.
- Through artifact verification: known raw output 68560 UTF-8 bytes; serialized ledger result payload 74261 bytes. With 32,768-byte kickoff reservation: 107029 bytes, below 131,072; unavailable framework/control-message overhead excluded. Final document acknowledgements/metadata are small unmetered reporting overhead, not claimed as exact total.
- Stable source remains frozen; no additional source modification, gate, diff-check or source identity calculation.

## Completion routing

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: SOURCE_REPAIR_COMPLETE / SCOPED_NON_UNITY_EVIDENCE_PASS
Overall integration status: BLOCKED
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews stable snapshot, reused evidence applicability and DEFERRED gates; decides explicit subsequent-role/runtime authorization.
Human decision or authorization required: Verifier routing, C# compile/EditMode, Unity/Provider/project work, artifact/package switch, commit/tag/push/publication.

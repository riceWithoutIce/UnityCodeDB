# S29 F-D01 documentation-only FIX

Status: BLOCKED / TARGET_CONFIRMED / AWAITING_HUMAN_AUTHORIZATION.

## Authorization and changes
Latest TASK Metadata, preceding finding and F-D01 grant read once. Same S29, DURABLE_SESSION/REUSE_ONLY, settings unchanged; no child.
Fresh window: 2026-10-06 03:26:18 UTC start, 03:36:18 UTC deadline. No renewal. Active/paused/model/reasoning unavailable; no observed compaction in this window.

Human-confirmed target: G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29. No existence inspection/create/open; human Unity/C#/actions remain unauthorized.

Only HUMAN-CHECKLIST-SOURCE-ACCEPTED.md and this new report written. Corrections:
- CachedNotIntegratedSnapshot_OffersInstallWithoutCheckingOrUninstallHistory
- CachedUninstalledSnapshot_PreservesInstallStateWithoutLiveScan
- ResolvePrimaryAction_ExposesOnlyOneContextualUserAction
These use Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.
ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation uses Rice.AI.Codedb.Editor.Tests.AICodedbProjectSettingsTests.
Target/status wording corrected; checklist final status discloses DOCUMENT_FIX_BLOCKED.

Names/parameters, 16 groups, 19 new + 24 adjacent = 43 planned cases unchanged. Exact Package path, More actions -> Uninstall CodeDB from Project, Install CodeDB authenticated reinstall and obsolete guard preserved.

## One check batch: failed, stopped
Command operations: strict UTF-8/no BOM, exact pre-edit document + eleven authorized replacements comparison, group/case counts, exact-ZIP declaration ownership, planned checklist size/hash.
Declaration source:
G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
Exit 1; tool wall 0.4950837 s; native wall unavailable (exception).
MATCH receipts: CachedNotIntegrated 2136, CachedUninstalled 2110, ResolvePrimaryAction 1692, all AICodedbProductStatusTests.
Raw error:
Fixture ownership mismatch: ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation

Nearest-preceding-class heuristic is not scope-aware; this failure does not establish that the frozen binding is wrong. No further investigation/correction/retry. Exact edit/count/UTF-8 checks preceded failure; four-group evidence incomplete.
Final checklist size/hash unavailable: receipt not reached; no extra check after stop. Report serialization bounded <=4 KiB; final disk size/encoding NOT RUN. Two oversized report drafts rejected before write, then shortened; not evidence retries.
Batch 1/1, retry 0, tests 0. Initial reads are retrieval. Cumulative output unavailable; no observed per-command guard overrun.

## Preserved receipts / NOT RUN
Source 306f329b8f51f82695dccc5e8de67c6bcea5320e.
Accepted digest 7a3556f686f359b93070e606a4bf51895c45a42773e22cb77cecf33d5006ffd8.
ZIP 717700a9ffe7af7ace1e937e29be3491ca13ae61aeb7b350678de257ea949141; both prior closures 46/0 reused, not replayed.
DELIVERY-PREPARATION-RESULT.md preserved; received 14806 bytes / SHA-256 1004d63e871dc10e24c9832fdc8839af2281a19508a308766ba9f43a38b7d63e reused, not reverified. All older records/source/tests/metadata/artifacts unchanged.

NOT RUN: Unity/MCP/CUA/BatchMode, C#/compile/EditMode/L0/FirstInstall, project/runtime/Provider/process probes, real actions or old candidate handling. No Ready/release PASS, Verifier, Git/publication/remote actions.

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: BLOCKED / TARGET_CONFIRMED / AWAITING_HUMAN_AUTHORIZATION
Next action: Planner/User disposition and separate authorization for a corrected scope-aware check. Stop in this thread/record.
Human authorization required: corrected evidence; later project/C#/runtime stages. No cross-thread notification authorized by this dispatch.

# S29 post-ACCEPT local delivery preparation

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: PREPARATION_COMPLETE / TARGET_CONFIRMATION_PENDING
Human stage: AWAITING_HUMAN_AUTHORIZATION / FRESH_INTEGRATION_NOT_RUN
Source phase: ACCEPTED after SCOPED_SOURCE_REVIEW_PASS; source committed.
This is delivery provenance only, not new source repair, runtime or release acceptance.

## Source and one-time admission

- Workspace/branch: G:/RiceProgram/UnityCodeDB; codex/v0.3.0-legacy-workflow.
- Sole exporter input/current admitted HEAD: 306f329b8f51f82695dccc5e8de67c6bcea5320e.
- Parent/review base: b15292f8978272244e605805a9ec064049141ee2.
- Planner's committed scope receipt: thirteen accepted changed paths; all fifteen accepted raw files equal Git blobs. Reused; no historical packet/source admission replay or full-tree diff.
- Canonical accepted and extracted fifteen-path SHA-256: 7a3556f686f359b93070e606a4bf51895c45a42773e22cb77cecf33d5006ffd8.
- One admission checked HEAD/branch/parent, ordinary non-reparse workspace/artifact parent, contained and absent output root, and absence of both new documents.
- Working exporter raw Git blob fde62eed6bb7aef0642497ce2d8b2ef90838c148 equals the exporter in the source commit (git rev-parse commit:path / git hash-object --no-filters). Thus its disk invocation executed committed bytes; Package content came from git archive of the commit, not the dirty tree.
- Unrelated dirty/staged/untracked contents preserved; a globally clean workspace is not claimed.
- Model/reasoning: unavailable. Existing settings/profile v0.3.coder.deep, DURABLE_SESSION/REUSE_ONLY; no new/replacement/child session or model override.

## Exact delivered artifact

- New contained artifact root: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329
- ZIP: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/com.rice.ai-codedb.zip
- ZIP SHA-256: 717700a9ffe7af7ace1e937e29be3491ca13ae61aeb7b350678de257ea949141
- ZIP bytes: 2250366.
- Commit-staged Package: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/package/com.rice.ai-codedb
- Exact-ZIP extracted root, used for human import: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb
- Absolute imported package.json: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/package.json
- Export receipt: files=483; bytes=10104369; zip_entries=483; one com.rice.ai-codedb ZIP root.
- No overwrite/copy/patch of old consumed candidates. The exporter's generated package.tar was removed after extraction inside this new root; it is reproducible from the source commit. No existing user file was deleted.

## Separate internal closure results — no replay

| Closure | PackageRoot / origin | Result |
| --- | --- | --- |
| Commit-staged closure (first invocation) | G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/package/com.rice.ai-codedb | PASS; source_count=46; mismatch_count=0. |
| Exact-ZIP closure (second invocation) | G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb | PASS; source_count=46; mismatch_count=0. |

Both internal receipts report:

- generation_hash=b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666
- host_current_hash=9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b
- runtime_contract_hash=df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303

The existing exporter invoked Tests~/test-codedb-package-release-closure.ps1 once from each PackageRoot, without RepairCanonicalMetadata. No additional closure validator run, metadata repair, hash patch, generation transition or Provider change occurred.

## Package/generation contract record

Read only from the exact-ZIP Package:

- package name/version: com.rice.ai-codedb / 0.3.0-preview.5.
- package.json unity declaration: 2022.3; Unity 2022.3.x is recommended, not an exact patch/editor-selection gate.
- payload schema=1; payload_version=poc.39; payload_sequence=39.
- generation_id=poc.39; generation manifest schema=1; bootstrap_protocol=1.
- owner_identity_version=2.
- control_contract: id=v0.3-control; version=2; schema_version=1; sha256=e535dd2ef7a120578178d8e8db608e765e29b0a09a619db31c4a39f53b9fcaf2.
- Generation manifest: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/Payload~/Generations/poc.39/generation-manifest.json
- Host-current template: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/Payload~/host-current.json
- Host generation-relative path: AIWork/.runtime/codedb/host/generations/poc.39.
- Runtime-contract file: G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/Payload~/payload-manifest.json.

All Package/payload/host-current/generation metadata remains committed and unchanged. The closure hashes above are the two export receipts, not a new runtime/Provider observation.

## Fifteen accepted bytes binding

Exactly fifteen files under the exact-ZIP extracted Package were hashed once and compared path-by-path against the accepted SOURCE-REPAIR-CONTINUATION-IDENTITY.txt. Their ordinal path/TAB/lowercase-SHA256/LF/UTF8-no-BOM digest equals the accepted digest above; mismatch count=0.

This binds Package bytes to the accepted source plus the trusted commit receipt and commit-staged export. No old source test was rerun, no historical source packet was re-admitted, and no live project/runtime was inspected.

## Commands, exit/wall and evidence limits

Primary export, cwd G:/RiceProgram/UnityCodeDB:

powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/export-codedb-package.ps1 -Commit 306f329b8f51f82695dccc5e8de67c6bcea5320e -OutputRoot G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329

Exit=0; measured native wall=7.081 s; tool wall=7.230278 s. Native/emitted output=3 lines/833 UTF-8 bytes; two PACKAGE_CLOSURE PASS lines followed by PACKAGE_EXPORT PASS. Wrapper capped emitted output at 160 lines/28000 bytes and returned the native exit.

Other read/provenance commands, not extra evidence scenarios:

| Operation / bounded command class | Exit | Tool wall s |
| --- | --- | --- |
| Current TASK Metadata + latest grant/receipt selected Get-Content | 0 | 0.273027 |
| Memory skill/MEMORY selected boundary read | 0 | 0.285906 |
| git show source:Tests~/export-codedb-package.ps1 selected entry | 0 | 0.288206 |
| git show committed exporter terminal and closure validator selected symbols | 0 | 0.320242 |
| git rev-parse HEAD; git branch --show-current; git rev-list --parents -n 1 source; contained/absent root/doc checks; exporter blob comparison | 0 | 0.409735 |
| New exact-ZIP metadata path/contract selected Get-Content | 0 | 0.241639 |
| Exact Package rg method/UI selector map | 0 | 0.326400 |
| Fifteen new-Package Get-FileHash/accepted-row comparison and contract fields | 0 | 0.334786 |
| Exact Package readonly Test/TestCase attribute extraction and asmdef names | 0 | 0.367537 |
| Menu/asmdef lookup plus optional final MenuItems removal-label rg | 1 | 0.275042 |
| Required Manager removal selector rg | 0 | 0.246410 |
| Current removal-route selected read plus optional test-body lookup | 0 (PARTIAL lookup; stderr below) | 0.337163 |

Navigation diagnostics preserved, not silently declared PASS:

1. MenuItems contains the Manager/root menu but not the requested direct removal labels; final optional rg returned no match (exit 1). The directly relevant Manager lookup located the actual labels. No export/evidence retry.
2. Optional body lookup incorrectly requested exact-Package Editor/AICodedbManagerUiTests.cs; actual location is Tests/Editor/AICodedbManagerUiTests.cs. Get-Content reported “Cannot find path .../Editor/AICodedbManagerUiTests.cs because it does not exist”; wrapper exit 0 was nonterminating-error behavior, not successful body validation. Body lookup was abandoned, not retried. Earlier correct-path method/attribute extraction already supplied all selectors. No source or Package was changed.

No substantive closure/hash mismatch and no source repair. These documentation lookup diagnostics do not alter either closure PASS or the fifteen-byte binding.

## Human checklist and literal UI routing

HUMAN-CHECKLIST-SOURCE-ACCEPTED.md operationally supersedes original package directions; original RESULT.md/HUMAN-CHECKLIST.md and all failed/stopped/over-budget Coder/Verifier records remain untouched.

Selectors are read from this exact Package: 19 authored C# cases in eight method groups, plus 24 directly adjacent cases in eight groups (43 planned cases total). The checklist names every method and parameter set. No tests were added or run. Do not Run All or select a whole category/class.

Planned single human-visible Unity session, only after new authorization:
compilation -> selected focused tests -> Install -> stable Ready -> remove current integration -> Uninstalled -> reinstall via Install CodeDB -> stable Ready -> normal shutdown.

Current Package menu: Tools/Rice AI/Codedb/Manager.
For a normal valid Ready installation, “More actions” exposes Uninstall CodeDB from Project. Remove CodeDB Integration is the obsolete-identity-specific route, not a button to force visible in a new healthy project. The checklist maps the requested removal flow to the current normal route, does not fabricate an obsolete identity, and calls this distinction out for Planner review. After Uninstalled, use Install CodeDB for the authenticated reinstall path; no repeated Configure or per-step Codex rebinding.

## Target and deferred gates

Proposed human-created target:
G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29

TARGET_CONFIRMATION_PENDING per the current TASK. Coder did not inspect, create, open or copy the proposed directory or any existing project. Exact path confirmation and an explicit human runtime/action grant are still required; this checklist itself is not that grant.

Old UnityFreshInstallValidationProject and unbound fd14a3cfa964437d9192f787df68bcf3 remain preserved. Recovery/cleanup/adoption/rebinding is DEFERRED. New-project success cannot prove the old project repaired.

NOT RUN/NOT AUTHORIZED:
C# compilation/L1/EditMode; human/agent Unity/MCP/CUA/BatchMode; actual Install/Remove/Reinstall; Provider/native business/process/runtime probes; user/global config/history; old static/L0/FirstInstall replay; publication/push/tag/remote Project operations.

No actual business process, protected runtime or project state was inspected. No source/tests/contracts/metadata/task/roadmap/index/original record was modified; no commit, clean/reset/stash/rebase or Verifier contact. Scope writes: the new artifact root and exactly the two new documents.

## Budget and final reporting

- One continuous delivery window starts 2026-10-06 02:32:49 UTC / 2026-10-06 10:32:49 client time.
- Deadline 2026-10-06 03:32:49 UTC / 11:32:49 client time; no automatic renewal.
- Reporting checkpoint 2026-10-06 02:58:19 UTC / 2026-10-06 10:58:19 client time; conservative elapsed 25m30s. Active/paused unavailable.
- Export scenarios 1/1; staged closure 1; exact-ZIP closure 1; export retry 0. Source/runtime tests 0.
- Output checkpoint: 47520 captured command stdout/stderr UTF-8 bytes; 51548 serialized result payload bytes. Framework/control overhead unavailable. Output guarded before capture: normal 32 KiB/200 lines, rg 16 KiB/50 matches, cumulative 128 KiB. No observed guard overrun. Final small document verification is reporting, not another test.
- Compactions observed in this delivery window: 0; earlier/full-history count unavailable.
- Prior 255951-byte/59m52s Window 01 overrun, Window 02 expiry/failures and FirstInstall 3/3 exhaustion remain unchanged historical facts; this delivery grant does not reset or retrospectively approve them.
- Preparation report <=16 KiB. Final artifact/document-only size verification recorded at closure.

## Completion routing

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: PREPARATION_COMPLETE / TARGET_CONFIRMATION_PENDING
Next notification: UnityCodeDB v0.3 Planner
Next action: Review the source-bound artifact/checklist and normal-removal label mapping; obtain exact human target confirmation and separate one-session Unity/action authorization.
Human decision or authorization required: target path, human project creation/opening and focused C#/runtime session; any later Verifier routing, fixes or release/publication.
Stop here. Return in this thread/records; no cross-chat reply or automatic human-stage continuation.

## Document closure and subsequent human-authorized notification

Closure checkpoint: 2026-10-06 03:02:15 UTC / 11:02:15 client time; elapsed 29m26s from the original start, without resetting the 60-minute window.

Bounded document-only verification used Get-Item, ReadAllBytes, strict UTF8Encoding.GetString, BOM rejection and the RESULT 16-KiB limit. Exit 0; native wall 0.176 s, tool wall 0.2914753 s. Before this closing append: DELIVERY-PREPARATION-RESULT.md 12810 bytes; HUMAN-CHECKLIST-SOURCE-ACCEPTED.md 11667 bytes. Both valid UTF-8 without BOM. A final size/encoding check of the completed documents follows; it is reporting, not a test or export/closure retry.

The earlier compaction count of zero described the 02:58:19 reporting checkpoint. One explicit compaction handoff has since been observed; full-history count remains unavailable. Active/paused time and actual model/reasoning remain unavailable. Known command-output subtotal through the first document verification: 52981 raw UTF-8 bytes / 57280 serialized-result bytes. Subsequent compact reporting/coordination output and framework overhead are not included in that subtotal. No source admission, hash, export, closure or test was rerun.

The human subsequently requested notification of Planner in this chat. This supplies direct messaging authorization only; it does not authorize the human target, Unity integration, fixes, publication or Verifier routing. Notify the freshly located UnityCodeDB v0.3 Planner once, without waiting for ACK or executing the next stage.

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: PREPARATION_COMPLETE / TARGET_CONFIRMATION_PENDING
Next notification: UnityCodeDB v0.3 Planner
Next action: Review artifact/checklist, normal-removal label mapping, exact human target and a separate single-session action grant.
Human decision or authorization required: human target/create/open/C#/runtime session and any later fixes, Verifier or release actions.

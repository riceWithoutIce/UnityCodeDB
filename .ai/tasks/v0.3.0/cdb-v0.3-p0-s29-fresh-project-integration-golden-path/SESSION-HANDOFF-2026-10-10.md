# S29 session handoff — 2026-10-10

## Superseding archive decision — 2026-10-15

S29 is **ARCHIVED / PARTIAL / NOT_RELEASE_ACCEPTED** by user decision.
Read [archive decision](ARCHIVE-DECISION-2026-10-15.md) first. All handoff and
continuation instructions below are historical. Do not resume historical
recovery or replay delivery, installation or human gates from this handoff.
Preserve the project, artifacts and runtime records in place.

## Later continuation: control authentication recovery

The original handoff below is historical. Subsequent human validation and the
P1 shutdown repair preceded the accepted v3 control-auth recovery slice.
Current source commit is `7c82ff46997417a82ccceedcf0f846afd8dcda93`.
Exact export and S29 reference switching are complete; human Unity validation
for this exact package is pending. Start with
CONTROL-AUTH-RECOVERY-DELIVERY-RESULT.md and
CONTROL-AUTH-RECOVERY-HUMAN-CHECKLIST.md. Review/acceptance evidence is in
CONTROL-AUTH-RECOVERY-RESULT.md and CONTROL-AUTH-RECOVERY-VERIFICATION.md.
Do not replay installation, export or reference switching; do not substitute
Unity/MCP/CUA/BatchMode automation for the human gate. S29/release remain PARTIAL.

## Start here

Continue the already accepted S29 post-install status/activity repair at its **human Unity validation gate**. Do not start another repair or replay installation. Repository `G:\RiceProgram\UnityCodeDB`; branch `codex/v0.3.0-legacy-workflow`; current HEAD `f88dd14` (delivery records), source commit `954384d0e8a6f338b68ce181bc4882099412cb34`. The user explicitly accepted the source after independent verification and authorized all pre-human prerequisites. Those prerequisites are now complete. No push/publication was performed.

At handoff, parent verified the two commits, empty staged index, no outstanding Editor/Tests source diff, exact manifest/lock reference and ZIP hash. No matching S29 Unity process was observed. This is a point-in-time observation; the human may open it afterwards. No human result has yet been received for this exact package.

Read these task-folder records, using bounded reads:

1. POST-INSTALL-EDITMODE-UI-HUMAN-CHECKLIST.md — immediate human steps.
2. POST-INSTALL-EDITMODE-UI-DELIVERY-RESULT.md — exact package/source evidence.
3. POST-INSTALL-EDITMODE-UI-VERIFICATION.md — independent review and limits.
4. POST-INSTALL-EDITMODE-UI-TASK.md and DECISION.md — frozen scope/acceptance.
5. RESULT.md, DIAGNOSIS.md and SOURCE-SHA256.txt with the same POST-INSTALL-EDITMODE-UI prefix, only as needed for diagnosis.

## Exact package and project

- Project: `G:\RiceProgram\UnityCodeDB\UnityFreshInstallValidationProjectS29`.
- Selected package: `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb`.
- Both project `Packages/manifest.json` and `Packages/packages-lock.json` were switched after the user confirmed Unity closed; JSON/reference equality and package.json existence passed.
- ZIP: `.artifacts/s29-post-install-ui-poc42/com.rice.ai-codedb.zip`.
- SHA256: `179aef72ff1dface2455773e7e5d0c69a870b1a553a670b0fc16bb170759ce3f`.
- 586 files/ZIP entries; 12,343,641 uncompressed bytes. Generation remains poc.42; no payload/generation bump.
- Export used existing `com.rice.ai-codedb/Tests~/export-codedb-package.ps1` from the frozen source commit. Commit-stage and exact ZIP each passed 60-source byte closure/zero mismatches plus production payload admission/native VerifyOnly.
- Exact six changed-source hashes match acceptance. Exact extraction semantic compilation: zero errors; standalone production-source harness: 13 methods/20 cases PASS. Standalone harness uses explicit Unity initializer/native-entry and old NUnit assertion adapters. This is **not** Unity import, EditMode lifecycle or native UI acceptance.
- Copied actual terminal/index release and session completion passed; 26 original receipt/index hashes unchanged. Protected actual records and selected/desired state were unchanged across the package switch.
- Ignored delivery evidence: `.artifacts/delivery/s29-post-install-ui/`; independent harness `.artifacts/tests/s29-post-install-ui-verifier/`. Preserve previous artifacts.

## What was repaired

1. EditMode cached snapshots no longer falsely describe Play suspension. Only explicit Play factories use Play wording; freshness/provenance stays intact.
2. Running Activity has indeterminate progress when no measurable stage exists. Provider stages remain determinate. No header/global progress; command completion is separate from subsequent status refresh.
3. Historical retirement/Upgrade results no longer substitute for current readiness. The proven lifecycle retirement route performs a subsequent read-only Supervisor Probe and uses its existing authenticated observation binding/freshness. Genuine unavailability/stale evidence is still rejected. Cleanup detail stays separate. The exact photographed oscillation timing has not been reproduced in real Unity.
4. Successful action release failed because the fresh-handoff reader expected fields in the wrong authority: instance.json does not own control_contract/runtime_contract_sha256; generation directories do not own the separately published stable wrapper; absent wrapper preimage is nullable. Reader now uses canonical Package runtime authority and retains declared contract/hash/committed epoch/selection checks. Release return and precise failure details are retained. No manual real index release or weakened ownership semantics.

Six changed files under com.rice.ai-codedb: Editor/AICodedbActivityPanel.cs, AICodedbStatusSnapshot.cs, AICodedbManagerWindow.cs, AICodedbEditorLifecycle.cs, AICodedbManagerActionJournal.cs, Tests/Editor/AICodedbManagerUiTests.cs. CanRequestInstallReconcile remains cleanup-COMPLETE-only; no automatic mutation expansion.

## Actual installation and protected history

The human already completed a successful real INSTALL before this repair:

- Action `dc72675bc8e54b4daaf82592115f2448`; exit0, complete output, no timeout/overflow/drain-incomplete, authoritative terminal_for_action true.
- INSTALLED / INSTANCE_ACTIVATED; product layers CURRENT / READY; historical cleanup PENDING.
- Selected instance `d620abbab0334a2d9c49e59888c1ef55`; generation poc.42; activation epoch `2f8b2a509a1e4086af4a4457e618d037`.
- Instance manifest SHA256 `664d0a7d99ce67c32f4537fecae076c3efcd0ac4e2aee8260957d4269302df62`.
- Committed INSTALL operation `048d631f6e6542bf8e1225f22b156530`; desired state ID `fbd6a56590584b7a97faf7f4de80737a`.
- At source/package isolated checks, actual successful index remains Pending, selected instance Current. Only copied indices were released. Human opening the new package may trigger existing authenticated recovery; re-read actual evidence after the human report, do not assume it is unchanged.

Actual index directory:
`C:\Users\admin\AppData\Local\Rice\CodeDB\manager-actions\a31d47273d22f34d00000fc2`.
Successful action receipts:
`C:\Users\admin\AppData\Local\Rice\CodeDB\manager-actions\dc72675bc8e54b4daaf82592115f2448`.
This receipt store is existing product state, not a development-temp relocation task.

Historical failed INSTALL actions `d8c736504562495dbafdd673c6851efb` and `f14c0524af324b7a802335a393483fa0` remain recorded. Original f14c candidate `5a6ff71560234b558e1a42148b680a77` (poc.40), retained-effects removal state `13852a6e3cd84136985bd25f7e61a563`. Do not delete receipts, rewrite failed outcomes, manually release admission, stop external holders or clear historical cleanup. Historical Pending does not by itself mean the new INSTALL failed.

Project state paths relative to S29:
`AIWork/.runtime/codedb/control/desired-state.json`, `current-instance.json`, and `contracts/v0.3-control/v2/{activation,operation}.json`.
Real read-only checking should attribute changes to human Unity maintenance rather than assuming every old byte remains immutable forever.

## Immediate next steps

Human opens the same S29 project, confirms compilation, runs these **six methods/eight cases** in AICodedbProjectSettingsTests:

- ManagerActionJournal_SuccessWithCleanupPendingReleasesExactIndexAndRetainsTrace
- ManagerActionSession_ReleaseFailureRetainsSpecificAuthenticationDetail
- CachedEditModeProductStatus_DoesNotClaimPlayOrNewVerification
- LifecycleRetirement_UsesNewReadinessObservationInsteadOfCleanupOutcome (two cases)
- RetainedFreshWrapperHandoff_AcceptsProducerNullAndRejectsUnboundPreimage
- UserActionStatus_NoStageOutputKeepsIndeterminateActivityUntilTerminal (two cases)

Then open Manager, remain in EditMode about two minutes, close/reopen Manager once. Verify accurate cache wording, meaningful current readiness distinct from cleanup Pending, and whether dc72675b... still blocks new changes. Old failures may appear as historical information. Record reasons if Ready/unconfirmed/NeedsAttention oscillates; do not insist on Ready when current authenticated availability actually fails.

After human reports, perform bounded read-only original receipt/index and lifecycle-log checks to establish actual recovery/release and continuing observation. Record human evidence against this exact package before any closing claim. Source/isolated PASS, human Unity, actual install, native progress animation and release acceptance remain separate.

**Do not request another Install/Uninstall solely for progress screenshots.** Native animation remains unverified until an otherwise necessary separately confirmed operation supplies it. The prior long actual-PowerShell fixture need not be replayed. No manual PowerShell, Windows reboot or Codex session rebinding is required for this human gate. S29/release remain PARTIAL.

## Workflow and authorization

- User expects contract-first scoped work and sequential Coder -> stable snapshot -> independent read-only Verifier -> User disposition. Current source is already accepted; no outstanding source finding.
- New user clarification is versioned in development-workflow.md: when using task-scoped subagents, parent must stay active, consume their questions/blockers, use bounded waits/status checks and confirm terminal completion. Never finish merely after dispatch. This does not change the separate durable-session policy or authorize automatic extra repairs.
- Coder `/root/s29_post_install_ui_coder` and Verifier `/root/s29_post_install_ui_verifier` are completed/stopped. No active child work needs monitoring for this slice. Their live handles may not transfer to a new conversation; use versioned result/hash records as authority.
- No reviewer directs a running Coder; findings returned together to User; fix review covers original findings and immediate regressions only. Follow-ups do not become new release blockers by default.
- Standing authorization covers pre-human prerequisites without repeated permission. Source accept and local commit/export/reference switch are completed. Human controls Unity launches/tests/clicks; do not substitute MCP/CUA/BatchMode automation.
- New repairs beyond these accepted bytes require disposition of new evidence. No global Codex configuration edit, process stop, system TEMP/ACL workaround, history cleanup or broad Host redesign. Unity2022.3.x is recommended; exact patch version is not a hard gate.
- Preserve dirty state. The repo still contains pre-existing/unrelated dirty docs, Payload generation/manifests, old UnityValidationProject configuration and untracked task/project records. Do not reset/clean/stage wholesale or regenerate Payload from that worktree. Six source files are clean after commit. Task-only doc projections were committed from HEAD, preserving other dirty doc content.
- Development artifacts/backups stay under repository-local ignored `.artifacts`/`.backups`; do not move them outside the workspace or put raw artifacts into Git.
- Workflow/roadmap are updated for this slice. GitHub Project was not updated in this delivery slice; do not claim remote synchronization or infer current remote status. No push/release/publication occurred.

This handoff is a workspace document, not a durable-memory update. It was created at the user's request after the delivery record commits and is initially uncommitted. Do not make an extra commit merely to start the next conversation.

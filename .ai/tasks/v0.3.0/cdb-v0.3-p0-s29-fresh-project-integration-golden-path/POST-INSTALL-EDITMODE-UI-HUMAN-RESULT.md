# S29 post-install human Unity result and read-only follow-up

2026-10-10 (Asia/Shanghai). Human report: “都测试通过；manager 关闭打开没有异常。期间还是会出现状态来回跳变的情况，最终会保持在 ready”。 Parent completed the authorized bounded read-only follow-up. **Human focused tests PASS; Manager reopen PASS; actual successful-action release CONFIRMED; sustained status stability remains unresolved. S29/release PARTIAL.** No additional source repair is accepted or performed by this record.

## Exact delivery attribution

- Source commit: `954384d0e8a6f338b68ce181bc4882099412cb34`; delivery-record HEAD at takeover: `f88dd14`.
- Project: `UnityFreshInstallValidationProjectS29`.
- Manifest and lock both still select `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb`; parsed equality PASS.
- ZIP: `.artifacts/s29-post-install-ui-poc42/com.rice.ai-codedb.zip`; SHA256 re-read equals `179aef72ff1dface2455773e7e5d0c69a870b1a553a670b0fc16bb170759ce3f`.
- Six exact extracted source hashes still match POST-INSTALL-EDITMODE-UI-SOURCE-SHA256.txt, zero mismatches. Editor/Tests source diff and staged index were empty at the follow-up check.
- Editor log contains the exact package extraction path and S29 project path. Human Unity executed the tests; parent did not launch/control Unity or invoke tests.

## Human evidence

The human confirms all six checklist methods/eight cases passed. The Test Runner screenshot shows EditMode selected, eight passed and zero failed; its active filter displays the two Install/Uninstall cases of UserActionStatus_NoStageOutputKeepsIndeterminateActivityUntilTerminal. Individual results for the other methods rely on the attributable human report, rather than this filtered screenshot alone.

Checklist methods:

- ManagerActionJournal_SuccessWithCleanupPendingReleasesExactIndexAndRetainsTrace
- ManagerActionSession_ReleaseFailureRetainsSpecificAuthenticationDetail
- CachedEditModeProductStatus_DoesNotClaimPlayOrNewVerification
- LifecycleRetirement_UsesNewReadinessObservationInsteadOfCleanupOutcome (two cases)
- RetainedFreshWrapperHandoff_AcceptsProducerNullAndRejectsUnboundPreimage
- UserActionStatus_NoStageOutputKeepsIndeterminateActivityUntilTerminal (two cases)

Manager closed/reopened without a human-observed exception. The Ready screenshot uses accurate cached-observation wording: “The last verified Ready observation is cached; reading this display does not perform a new check.” It retains historical failed-action/cleanup information and shows the prior Install completed in about 36.33 seconds. Idle UI and presentation-state tests do not prove native running-operation animation.

Preserved screenshot copies under ignored `.artifacts/delivery/s29-post-install-ui/human-20261010/`:

- `test-runner.png`: SHA256 `9b2c0b0d4cf2b3a82247cc8037f333bbc9c8eeae1f80a4fbb89a5fa26ea5fd95`.
- `manager-ready.png`: SHA256 `eee756183d28f2a8f485964a50492a87cac137497d5d27bda0ace80394b6daf5`.

## Actual successful-action recovery/release

Read-only inspection of the original action store confirms `resolved-action-dc72675bc8e54b4daaf82592115f2448.json`, state `resolved`, disposition `CommandTerminal`; last-write UTC `2026-10-10T02:56:28.3429836Z` (10:56:28 local). Its project/package/action identities match the original successful action metadata. The historical package root remains `s29-optional-flat-compile-poc42`, as required for original action attribution; it was not rewritten to the new package root.

The project index directory contains only `index.lock` and four resolved-action records, with no pending current-action record. Thus the original successful action's retained-index block is released; this does not grant permission for a new mutation or prove every other admission condition. Parent invoked no real release method.

The original successful action still has exit 0, authoritative terminal_for_action true, no timeout/overflow/drain-incomplete, INSTALLED/INSTANCE_ACTIVATED, CURRENT product layers and cleanup PENDING. All four original successful receipt files match their pre-human delivery-harness copies. All four available f14c failed-action receipt files and all three older resolved-action records also match their delivery-harness copies. This is an 11-file bounded comparison, not a renewed claim that all 26 prior protected files were compared. The d8c loose receipt directory is absent in both the inspected clone and actual path; its retained resolved/history record remains equal. No removal is attributed to this session.

Current selection remains instance `d620abbab0334a2d9c49e59888c1ef55`, generation `poc.42`, activation epoch `2f8b2a509a1e4086af4a4457e618d037`; actual instance manifest SHA256 remains `664d0a7d99ce67c32f4537fecae076c3efcd0ac4e2aee8260957d4269302df62`. Desired state remains INSTALLED with state id `fbd6a56590584b7a97faf7f4de80737a` and cleanup PENDING. Operation remains INSTALL/COMMITTED, id `048d631f6e6542bf8e1225f22b156530`.

## Continuing observation and remaining status issue

A bounded Editor.log tail captures reconcile completions 1–12 as:

`NeedsAttention → NeedsAttention → NeedsAttention → Ready → NeedsAttention → Ready → Ready → Ready → Ready → Ready → Ready → Ready`.

Completions 1, 3 and 5 identify `InitialSupervisorProbeEvaluated` with Unknown product layers. Completion 2 identifies `RetirementSelected` with CURRENT layers but ends NeedsAttention. Completions 4 and 6–12 identify `RetirementSelected`, CURRENT layers and Ready. These checkpoints prove actual lifecycle transitions; they do not retain the exact UI reason for every transition.

The log contains: `CodeDB historical cleanup remains pending: Command failed with exit code 4. [SUPERVISOR:SUPERVISOR_COMMAND_FAILED] The Supervisor IPC request timed out.` This establishes a concrete timeout during historical maintenance, but does not prove that all photographed/reported changes have the same cause. The absence of a fully mapped per-transition failure detail prevents closing the status-stability item or treating every NeedsAttention as benign.

The latest sampled Supervisor document at `2026-10-10T03:02:04.133Z` reports top-level `maintenance / SUPERVISOR_MAINTENANCE` while `materialize:Upgrade` is running; its separate operational observation is `core_ready / COORDINATOR_OPERATIONAL`, revision 518, observed at the same UTC time, Provider ready. Observation project, selected instance/generation, activation epoch, runtime hash and owner epoch match the inspected current records. This is a persisted point-in-time observation, not a newly executed authenticated Probe. Supervisor event tails show existing Unity-maintenance Upgrade followed by Probe operations; parent did not initiate them.

Lifecycle counters show zero Play transitions, two Manager opens, one close and zero recorded main-thread violations. This supports the human EditMode/reopen report and does not replace device/performance acceptance.

The inspected tail contains no C# error lines. Exact-package warnings include two CS4014 locations and one CS0414 unused-field location in ManagerWindow; novelty was not assessed. An unattributed `Attempted to call .Dispose on an already disposed CancellationTokenSource` log line also exists; without an attributable product stack it is not established as a CodeDB failure or expanded into a new audit.

## Disposition and limits

Focused human tests, accurate cache wording, reopen behavior and actual successful-action release now have human/live evidence. State oscillation remains a concrete unresolved observation, returned to User/Planner for disposition; later Ready does not close it automatically. No normal-user-path failure, data/config damage or unsafe external process stop was established by this bounded follow-up, so no new BLOCKER is asserted. Native running progress animation and whole S29/release acceptance remain unclaimed; no repeat Install is requested for a screenshot.

No Install/Uninstall, replayed fixture, manual index release, historical outcome rewrite, process stop, cleanup, Unity/MCP/CUA/BatchMode control, source edit, export, package switch, commit, push or publication was performed. Writes were limited to this task result and repository-local ignored screenshot evidence. Existing dirty state is preserved. No subagent was started for this follow-up.

Some initial diagnostic outputs exceeded their requested output bounds and were truncated; conclusions above use explicit-field summaries and bounded comparisons, not a claim that those truncated outputs were fully reviewed. Secrets from runtime authority documents are not retained in this report or evidence artifacts.

# S29 post-install EditMode UI Coder result

2026-10-10. Coder `/root/s29_post_install_ui_coder`. Baseline HEAD `b8a143214076445b3435507782132366eb1418d2`. Status: source implementation and focused standalone evidence COMPLETE; independent Verifier and human Unity evidence PENDING. S29 remains PARTIAL. Implementation is stopped at the source SHA256 manifest in `POST-INSTALL-EDITMODE-UI-SOURCE-SHA256.txt`; no commit, export or reference switch.

## Result and causal evidence

1. Cached snapshots use EditMode observation/cache language by default. Only explicit Play suspension factories opt into Play-specific explanations. Existing observed-at timestamps, display boundary and 30-second freshness checks are unchanged. Cache construction performs no new verification.
2. Running Activity always renders feedback: measured Provider stages keep their determinate bar; operations without stages receive an animated indeterminate segment with no invented percentage. Progress remains in Activity and ends on command terminal independently of the subsequent status observation. No header/global progress API was introduced.
3. The proved retirement branch now performs a read-only Supervisor Probe after the historical Upgrade/retirement command. It classifies and publishes that Probe through the existing observation-binding/freshness route instead of treating cleanup-only output as product readiness. Cleanup outcome and its prior Pending state are retained in diagnostic detail, exposed in cached cleanup detail; cleanup failure can emit a cleanup warning without relabeling a separately authenticated Ready observation. New unavailability, missing Supervisor proof and stale observations remain unable to display Ready. Exact photographed oscillation timing is still not proven by a real lifecycle run.
4. Session release records its bool result and specific detail, and recovery honors the release return instead of discarding it. Conflict details are preserved through journal/session and the retained-action banner. The concrete successful terminal release failure was reproduced in the fresh-installed reader route: `ValidateRetainedCurrentState` expected instance-owned `control_contract`/`runtime_contract_sha256`, a generation-local stable-wrapper file and a string preimage, whereas the producer owns those contract/hash values in the existing Package runtime authority, publishes the stable wrapper separately and emits a required nullable preimage for an absent file. Reader now uses the canonical Package runtime authority and validates activation/operation contract id/version/schema/hash, runtime hash, committed epochs and existing selection/hash bindings. The wrapper mutation uses the required nullable reader and keeps desired hash, old hash, existed-before and uniqueness checks. No ownership/authentication semantics were redefined.

`CanRequestInstallReconcile` remains cleanup-COMPLETE-only. The already scheduled lifecycle path is the proven affected route and is repaired; this task does not broaden post-command automatic mutation admission for PENDING histories. Command success and action-index release do not constitute general authority to mutate historical effects.

## Changed source

- `Editor/AICodedbActivityPanel.cs`: indeterminate Activity rendering/presentation.
- `Editor/AICodedbStatusSnapshot.cs`: explicit Play cache wording and retained cleanup diagnostics.
- `Editor/AICodedbManagerWindow.cs`: explicit Play factory calls, durable release result/detail and recovery presentation.
- `Editor/AICodedbEditorLifecycle.cs`: retirement-to-read-only-observation route and focused classifier helper.
- `Editor/AICodedbManagerActionJournal.cs`: producer-shaped fresh handoff reader and specific conflict detail.
- `Tests/Editor/AICodedbManagerUiTests.cs`: six new focused methods and adjacent assertions (eight new cases), retaining existing Provider, freshness and identity regressions.

All paths are under `com.rice.ai-codedb/`. Other dirty files, payload generation/pointers, consumer configuration and real receipts were not written.

## Evidence

- `git diff --check` for these six files: PASS.
- Original Editor + Editor test source, C# 9 Roslyn semantic compilation using installed Unity 2022.3.47f1 metadata, the actual Unity TestRunner and package NUnit references: **0 errors**. This is external semantic compilation, not Unity compilation/import/EditMode execution.
- Focused standalone run: **13 methods / 20 cases PASS**. Methods cover EditMode versus explicit Play caches, stage-free Install/Uninstall progress and terminal ending, preserved Provider stages, retirement success/failure plus subsequent unavailability and missing observation proof, nullable wrapper mutation binding, successful PENDING-cleanup terminal release, retained release failure detail, malformed/conflicting index rejection and existing project/package/TTL/freshness boundaries.
- Read-only production journal against actual project evidence (with standalone Unity entry shims): selected instance is `Current`; repaired journal is `Pending`, retaining the original `dc72675bc8e54b4daaf82592115f2448` index and both recorded historical failed INSTALL warnings. The baseline reader failed before it could admit this successful index because the fresh instance manifest lacks its assumed `control_contract` field. Additional exact producer-shape contradictions were observed and repaired in that same reader closure.
- Copied manager-action closure under `.artifacts/tests/s29-post-install-ui/manager-clone-*`: the authenticated real action terminal (`exit 0`, complete output) released the **cloned** exact index, completed its cloned session and left the cloned journal `Empty`. Historical failed outcomes/warnings remained recorded. **26 actual source receipt/index files had equal before/after SHA256**. No real journal release or project mutation was invoked.

Evidence harness: `.artifacts/tests/s29-post-install-ui/Semantic.csproj`, `Semantic.cs`, `RuntimeTests.cs`, `RuntimeShim.cs`. The standalone execution removes only the Unity lifecycle static initialization body and substitutes native SessionState/time/Assets entry points with owned in-memory/local fixtures. The old NUnit runtime cannot use its .NET Framework remoting assertion counter under .NET 10, so standalone assertions invoke the original NUnit constraint `ApplyTo` directly; original source/test bodies and constraints are retained. These substitutions are explicit limits, not Unity acceptance. The first direct attempt to load Unity's compiled assembly outside Unity failed its native lifecycle initializer and was not treated as a product failure. Harness construction needed metadata/fixture/assertion plumbing corrections; no successful standalone evidence was claimed from those failed attempts.

## Limits and next gate

- No Unity launch/control, BatchMode/MCP/UI automation, real Install/retry/uninstall, process stop, historical cleanup, receipt rewrite/release or package generation bump.
- Sustained real EditMode observation, native Activity animation, lifecycle retirement execution and real terminal release under Unity are **NOT_RUN**. No claim that the photographed oscillation timing is resolved by runtime evidence.
- Existing historical failed/unknown outcomes and pending cleanup remain separate facts; this repair does not clear them or widen next-change permissions.
- Existing successful INSTALL evidence is reusable. A second real Install solely for a progress screenshot is unnecessary; focused presentation tests establish its stage-free state. Human native rendering checks may use the existing accepted workflow only if a genuine operation is otherwise required and confirmed.
- Independent read-only Verifier receives this six-file stable snapshot. Findings are returned to Planner/User together; Coder does not dispatch or start repairs without disposition.

Next notification: Planner. Next action: admit SHA256 snapshot and dispatch bounded independent Verifier. Human Unity gate remains separate.

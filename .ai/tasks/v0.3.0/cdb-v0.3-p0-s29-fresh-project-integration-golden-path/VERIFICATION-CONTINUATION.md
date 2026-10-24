# S29 Scoped Source Review - Continuation Window 02

Task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Profile/session: existing v0.3.verifier.deep; DURABLE_SESSION / REUSE_ONLY.
Authorization: TASK.md, Scoped Source Review Continuation Window 02 Grant - 2026-10-05 (line 949).
Report date: 2026-10-05. Production, tests, contracts and previous VERIFICATION.md remained read-only.

## Verdict and scope

Scoped verdict: SCOPED_SOURCE_REVIEW_PASS.
Material in-scope product findings: 无.
Budget status: OUTPUT_GUARD_EXCEEDED / TRUNCATED (accounting label; no observed tool-content truncation).
Overall S29 real-project integration: BLOCKED.

This completes only the previously unfinished frozen source/evidence review. It is not full S29 ACCEPT, current product Ready, real-project/Provider/runtime recovery, release acceptance, or S25/S28 closure. Output-budget noncompliance is retained independently of the semantic verdict; Planner/User must decide its disposition.

## Frozen admission reused

- Branch: codex/v0.3.0-legacy-workflow.
- HEAD: b15292f8978272244e605805a9ec064049141ee2.
- Fifteen-path actual-byte SHA256: 7a3556f686f359b93070e606a4bf51895c45a42773e22cb77cecf33d5006ffd8.
- SOURCE-REPAIR-CONTINUATION-RESULT.md: 16059 bytes; SHA256 7b7153e3cd4c2f2ab6c5873c2d4c5f15a25a367c2ba909e6a8010ccae972aa8d.
- SOURCE-REPAIR-CONTINUATION-IDENTITY.txt: 1831 bytes; SHA256 equals the fifteen-path digest.
- Identity algorithm: ordinal path + TAB + lowercase actual-byte file SHA256, LF-separated rows with final LF, UTF-8 without BOM.
- Prior successful independent admission is reused exactly as authorized. No fresh Git/hash admission was run in this window, and no actual drift evidence was found. This is not a claim of newly reverified identity.
- Original VERIFICATION.md preserved: 8277 bytes; SHA256 3ec27de5e888831d7cfeca9e2095afab6296008c744bb5e10b77feee5e961494 (report-preservation check only).

Combined coverage: prior admission, requirements and partial source review remain the original report's evidence. This window completes only the three remaining semantic groups below, including reused ProjectIntegrationState lines 117-150 and engine lines 4332-4382. No full documents, patch dumps, or broad audit were repeated.

Source-reference base below:
G:/RiceProgram/UnityCodeDB/com.rice.ai-codedb/
Line ranges identify reviewed evidence, not claims of executed tests.

## 1. Classification, namespace, UI/lifecycle and version - PASS

- Editor/AICodedbProjectIntegrationState.cs:56-95 and Editor/AICodedbControlContract.cs:232-249 agree with the previously read backend namespace predicate. Fresh evidence allows only control/payload-materializer plus the exact current Supervisor-only contract namespace; integration/host/instances, reparse points, foreign/additional runtime entries, MCP registration and blocked migration do not become NotIntegrated.
- ProjectIntegrationState.cs:151-231 authenticates desired-state schema, managed_by, project root/identity, lowercase GUID, state and cleanup. Uninstalled is distinct from NotIntegrated; invalid evidence remains Invalid. Missing desired-state handling reuses the prior 117-150 read.
- Editor/AICodedbEditorLifecycle.cs:938-953 reads migration before integration classification. NotIntegrated disables automatic Supervisor/editor lease startup, publishes cache and returns before prerequisite admission/current-instance work.
- Editor/AICodedbStatusSnapshot.cs:175-242 and Editor/AICodedbHostPayloadMaterializer.cs:674-703 preserve distinct NotIntegrated/Uninstalled/Invalid results. NotIntegrated remains inactive/unknown rather than fabricated Checking or uninstall history.
- Editor/AICodedbManagerWindow.cs:420,1514,2179,2324-2340 and Editor/AICodedbActions.cs:191-205 retain explicit Install via existing Supervisor route/fallback and explicit reconcile. Inflight blocks Install eligibility; cached NotIntegrated remains otherwise install-capable. No new Manager main-thread filesystem lane was identified in these coupled branches.
- Tools~/materialize-codedb-host-payload.ps1:1291-1300 requires Unity-project markers Assets, Packages/manifest.json and ProjectSettings/ProjectVersion.txt, not exact 2022.3 contents. The reviewed Install routes do not introduce an exact-version admission gate; 2022.3.x remains a recommendation.
- Authenticated reinstall retains state-ID/removal-intent binding in the engine route below; absent integration is not treated as fabricated uninstall.

## 2. Origin, durable publication, failure and strict selection - PASS

- Tools~/codedb-project-supervisor.mjs:2013-2038 forwards the existing operation_id and manager_action_id before child/effects. The current queue/operation remains owner.
- Tools~/codedb-instance-engine.ps1:4383-4478 builds/validates origin before candidate effects, retains original IDs, and generates standalone fallback IDs before effects. First Install is rechecked under the existing project lock; authenticated reinstall retains state-ID/removal-intent binding.
- Engine:2380-2499 establishes captured CandidateAttempt before effects. PROVISIONING manifest with origin is written into owned staging and atomically Directory.Move-published before prepare/adapter/Ensure. READY/probe/availability and ExecutionObservationComplete follow success only.
- Engine:2206-2240,2076-2088,4672-4728 preserve the original nonzero/native error separately from timeout, unconfirmed termination and incomplete drain. Unknown observation, residual candidate/staging, or inspection failure => PENDING; COMPLETE requires proved absence/pre-effects. Cleanup uses captured attempt even when no candidate result returned. No implicit replay; only the exact candidate-owned lifecycle ID may be stopped.
- Engine:2943-3004,4538,4618-4629 retain verified-candidate-before-selection and strict next-change admission at the effect point. Existing current/LKG/retirement/removal-intent/activation bindings or verified in-pass candidate require complete observation, manifest hash, availability, desired-state and selection fingerprints. Origin alone grants no adoption/selection authority; unbound/foreign/ambiguous evidence is refused.
- Engine:844-857,910-967,1579-1581 retains default fresh-namespace rejection. Explicit transaction bootstrap preservation is confined to the exact current contract-root Supervisor directory with reparse and immutable record/attempt checks; it is not a second authority.
- Engine:2057-2074 and Editor/AICodedbProjectIntegrationState.cs:330-345 validate optional origin's exact fields/action/lowercase IDs; legacy absent/null origin remains readable. Calls after existing hash/path binding (ProjectIntegrationState:467; ControlContract:624) do not promote origin to ownership.
- Exception/unknown-effect evidence remains distinguishable from successful activation; this source review performs no real candidate probe, adoption, repair or cleanup.

## 3. Direct coverage and exhausted evidence reuse - PASS within evidence boundary

- Tests/Editor/AICodedbEditorLifecycleTests.cs:78-201 authors 18 Window03 cases: current Supervisor-only (1), blocked migration (2), invalid contract (1), extra legacy/foreign/activation/unknown runtime (4), absent/null origin (1), valid origin (3), invalid origin (6).
- Tests/Editor/AICodedbManagerUiTests.cs:2136-2150 authors one cached NotIntegrated inactive/install-capable case, without fabricated history/Checking. Total: 19 authored/source-checked C# cases only; no compile or Unity execution evidence.
- Tests~/test-codedb-host-payload-materializer.ps1:64-226,232-349 uses exact production AST function bodies/constants, real current/LKG/retirement/activation/journal readers, lock contention/recovery/effect callbacks and filesystem/hash/path refusals, in owned temporary scope. Native boundaries are synthetic; this is logical integration, not real business/native lifecycle.
- Harness:352-452 covers clean first Install/no invented removal state, exact Supervisor-only namespace, unknown entry rejection, verified selection, original IDs, authenticated reinstall, PROVISIONING publication before effects, captured-attempt/PENDING after missing result, origin non-authority, original exit 23 versus unknown effects, and pre-public-manifest failure. Functions share the corrected New-Module fixture scope; machine prerequisite/native collector seams remain synthetic.
- Tests~/test-codedb-project-supervisor.mjs:410-426,1045-1138 (1088-1092),2342 verifies captured original action_id and operation_id, lost acceptance, conflicting action refusal, unrelated-result isolation and restart correlation. Synthetic Probe child correlation is not actual Install/Provider evidence.
- Admitted Window03 attribution states production and PowerShell harness unchanged. This permits retaining the recorded Window02 run, not a new dynamic PASS or runtime proof for every final byte.

## Reused Coder evidence; nothing rerun

Source: frozen SOURCE-REPAIR-CONTINUATION-RESULT.md, reviewed evidence ledger lines 78-143.

| Evidence | Recorded result | Boundary |
| --- | --- | --- |
| FirstInstallAttributionOnly, Window02 | exit 0; 26 cases; native_children 0; 16.565s | 3/3 attempts exhausted; no replay |
| NextChangeAdmissionIntegrationOnly | exit 0; 45 cases; native_children 0; 21.733s; 3184 bytes/47 lines | Reader/filesystem logical integration; full process wall unavailable |
| manager-action-correlation | exit 0; 107 bytes | Synthetic original-ID/lost-acceptance/unrelated/restart assertions |
| PathProvenanceOnly | exit 0; native 4.460s, tool 4.614812s; 33 bytes | Existing focused evidence only |
| static/source | exit 0; 14 checks; native 0.748s, tool 0.870599s | CSharp_execution DEFERRED, not compilation |
| Fifteen-path scoped diff-check | exit 0; 0.257591s; empty output | No rerun |

Retained first-Install failures: attempt 1, unexpected Supervisor fresh namespace, exit 1/8.236331s, corrected by explicit preservation while default rejection remained; attempt 2, empty RelativePath fixture script-scope construction, exit 1/5.838612s, corrected by shared New-Module scope. Final attempt is the recorded 26-case PASS. Neither failure is erased; no remaining replay authorization. Wait/poll durations are not substituted for native runtimes.

## Findings and residual risk

一次性 findings：无（限定冻结需求及本轮三项源码/证据范围）。
No new BLOCKER/P1/P2 product finding was confirmed. Budget overrun below is a workflow deviation, not fabricated source failure or evidence of runtime PASS. Unexecuted integration/runtime gates remain unresolved; this review does not close them.

## Time/output ledger and deviation

- Original window: approximately 16 minutes; measured 31281 captured bytes/82 physical output lines; no actual tool TRUNCATED observed. Earlier stop and budget reservation remain history. Its exact early reservation cause is unconfirmed; it must not be represented as actual exhaustion of 128 KiB.
- Continuation start: 2026-10-05 15:20:11 UTC (23:20:11 Asia/Shanghai); immutable deadline: 15:50:11 UTC. Inspection/report-preservation checkpoint at 15:40:48 UTC => 20m37s. Report-preparation checkpoint at 15:46:09 UTC => conservative elapsed 25m58s, including pauses/compaction. No window reset/renewal.
- Guards: ordinary output <=32768 bytes/200 lines PER COMMAND; rg/log/session <=16384 bytes/50 matches PER RESULT; cumulative captured output <=131072 bytes PER WINDOW; report artifact <=16384 bytes. Command/report inputs are not captured stdout/stderr.
- Violation 1: fixture-source output 35805 UTF-8 bytes, 3037 above the single-command byte guard.
- Violation 2: counter first surfaced 141649 bytes, already 10577 above cumulative guard. Thereafter only narrower already-required Node correlation/bootstrap reads and report-preservation metadata were obtained; no semantic scope expansion.
- Last measured review command stdout/stderr payload: 157927 bytes/152 physical output lines, 26855 above cumulative guard. This is measured payload/minimum, not exhaustive transport statistics. Subsequent artifact checks and notification metadata are separate finishing output; no claim of retroactive compliance.
- OUTPUT_GUARD_EXCEEDED / TRUNCATED is retained as required guard/overrun status. Returned tool content was intact; actual content truncation was not observed. Unknown transport overhead is not used to excuse or infer exhaustion.
- Model/reasoning: existing settings reused without overrides; exact current model and reasoning values not available to this review and not asserted.
- No test retries, duplicate static batches or identity reruns. Navigation rg no-match exit 1 is not a test/source failure or repair attempt.

## NOT RUN / DEFERRED

No tests, C# compile, L1/EditMode, Unity/Unity MCP/CUA/BatchMode, full suites/regression, manual lifecycle acceptance, real prerequisite/Provider/native business processes, real project/protected/user-local/global reads or operations, candidate adoption/repair/cleanup, package export/switch, artifacts/Payload/generation writes, commit/push/tag/publication, or remote Project changes.

Only this new report is written. Original VERIFICATION.md, TASK/Coder records, source/tests/contracts and dirty state are preserved. No Coder contact, repair dispatch, child/new session or model override. Real-project, Provider, runtime and release gates are DEFERRED / NOT RUN; overall integration remains BLOCKED.

## Completion and routing

当前 S29 定向源码续审已完成。下一步通知 UnityCodeDB v0.3 Planner 汇总本报告、输出预算偏差与仍 BLOCKED 的真实工程集成边界；由 Planner/User 决定 ACCEPT / FIX / DEFER / STOP。本报告不自行批准发布、不派发 Coder；跨会话通知仅依用户直接授权执行。

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current scoped status: SCOPED_SOURCE_REVIEW_PASS
Current overall integration status: BLOCKED
Budget status: OUTPUT_GUARD_EXCEEDED / TRUNCATED
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner/User disposition
Human decision or authorization required: ACCEPT / FIX / DEFER / STOP


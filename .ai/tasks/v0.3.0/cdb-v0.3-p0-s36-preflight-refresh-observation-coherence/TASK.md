# Task: cdb-v0.3-p0-s36-preflight-refresh-observation-coherence

## Metadata

- Product: UnityCodeDB, v0.3.0.
- Workflow: codedb-workflow-v2, revision 2.6.
- Status: DOING / CORRECTED_DELIVERY_AUTHORIZED.
- Planner: current parent. Coder then read-only Verifier: approved sequentially.
- Review mode: GUARDED (lifecycle cache publication).
- Execution mode: FAST_SUBAGENT.
- Execution profile: standard role budgets; inherit the parent session's model
  and reasoning, with no model override or escalation.
- Delegation authorization: TASK_SPECIFIC. User replied `同意批准` to the
  concrete S36 Coder -> read-only Verifier proposal on 2026-10-19. Parent stays
  active through both terminal results. Historical standing grants are unused.
- Session policy: SPAWN_BOUNDED; depth one, sequential roles.
- Requirement source: existing v0.3 lifecycle/Manager status contract and S35's
  idle observation, documented in the adjacent S35 RESULT.md.

## Objective

Refreshing only removal preflight must preserve the coherent lifecycle command,
product status and authenticated Supervisor observation. It must not rebind an
old command to a newer Bridge observation or overwrite a newer lifecycle state.
This is a separate source deliverable; S35 remains real acceptance only.

## Scope

- Change allowlist:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Coder owns those files and this directory's `RESULT.md`; Verifier owns only
  `VERIFICATION.md`. Planner owns this task and S35 route records.
- Direct read closure: the existing cache publication/binding, removal
  preflight and no-backend-reconcile path; their product/snapshot types and
  direct callers; Manager cache consumption/freshness boundary and its tests
  (including `AICodedbManagerWindow.cs` and `AICodedbManagerUiTests.cs`);
  applicable workflow modules and existing directly relevant local harness.
- Protected: all unrelated dirty files, exported S34 package/ZIP, every Unity
  project, active runtime/receipts, retained evidence and machine stores.
- Baseline HEAD: `d4a097d20af598ca760163867a3394ff5efb116d`.
  Both change-allowlisted files were clean at Planner admission. Record final
  hashes and narrow diff for stable-snapshot review, preserving unrelated dirt.
- No protocol/schema, identity/generation, process admission, uninstall rules,
  Supervisor polling, Manager freshness policy or package identity changes.
- Exclude log reduction, NotIntegrated wording, CleanupMono, historical
  recovery, Provider/model work, real lifecycle actions and delivery.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE.
- User grant: latest `好的 同意` accepts the proposed narrow source fix:
  preserve the paired observation for preflight-only refresh; retain strict
  equality and freshness. Implementation and proportionate local verification
  are approved. The subsequent `同意批准` authorizes this task's sequential
  Coder and read-only Verifier; it adds no delivery or real-environment authority.
- Delivery authorization: subsequent explicit `同意授权` covers exactly the
  six-path local commit, exact export/checks and closed-S35 reference switch
  recorded in DECISION.md. No push/publication or Unity execution is included.
- Coder actions: read the direct closure, implement the preflight-only update,
  add meaningful nearest regression tests, perform permitted focused checks,
  stop and return one attributable result. Do not start another agent.
- Required invariants:
  1. Read the full cache tuple atomically, including its revision, paired
     snapshot and terminal-failure field. Do not fetch a new Bridge snapshot
     to reinterpret that cached command during a preflight-only update.
  2. Preserve the command and observation identity, revision, timestamps and
     expiry. Update only preflight admission/related diagnostic information;
     a preflight result is not new operational readiness evidence.
  3. Publish the update only if the captured cache revision is still current,
     under the cache lock; advance revision coherently on success. A stale
     update must not overwrite Uninstalled, a newer Ready, terminal failure,
     invalidated cache or another authoritative replacement.
  4. Retain cancellation/context checks and existing terminal semantics.
     Preflight refresh cannot clear a terminal failure or resurrect Ready.
  5. Keep strict `BindProductStatusToSupervisorObservation` equality and
     Manager stale/foreign/incomplete evidence rejection intact. If genuinely
     new readiness is needed, leave it to the existing full observation path;
     do not introduce another observation mechanism in this slice.
- Evidence scenarios: coherent cached observation A while Bridge advances to
  B; preflight available/unavailable updates without changing readiness;
  a newer cache publication before preflight completion; unchanged observation
  age/expiry and terminal-failure protection; true revision mismatch rejection.
- L0: narrow diff/whitespace and source call-path checks; reuse an existing
  directly applicable non-Unity harness only if its closure already supports
  the changed production code. If absent, record execution DEFERRED once;
  do not build a new fake Unity or whole-machine harness.
- Affected L1: add focused NUnit regressions in the allowlisted lifecycle test
  file; retain `LifecycleStatusBinding_RequiresSameOperationalObservationRevision`
  and nearest coherent-cache/Uninstalled checks. Read-only review of existing
  Manager freshness tests, especially stale/foreign/incomplete Ready rejection
  and expiry before unchanged-revision gating. NUnit/Unity execution DEFERRED
  to a separately authorized human gate, not claimed from static inspection.
- Explicitly not run: Unity/EditMode/MCP/BatchMode, lifecycle commands, live
  probes/RPCs, Supervisor/Provider launch, full suites, unchanged broad tests.
- Test rationale: exercise the observed preflight/cache publication defect and
  its direct state/freshness protections without expanding isolation work.
- EditMode authorization: NOT_REQUESTED; Editor compatibility level NONE.
- Side effects: only allowlisted source/test and repository-local task/evidence
  writes. No product state/configuration/process control or network acquisition.
- Any development outputs must remain below a declared repository-local root
  (if needed `.artifacts/s36-preflight-refresh/`); durable records use relative
  paths. No system-temp or user-profile output fallback.
- Budgets: workflow defaults; Coder 30 minutes, Verifier 15 minutes, two
  mechanical corrections and two justified corrected semantic attempts per
  local scenario. Broad search/full diff/full regression forbidden.
- Stop/escalate if other files/contracts, a new readiness mechanism, external
  dependency, human environment action or relaxed guard is needed. No
  unchanged reruns or hidden expansion. DEFAULT_V2_1 mode-promotion rules apply.
- Structural guard starts at repairs 0/2, independent causes 1/2, consecutive
  diagnostic-only checkpoints 0/3. Model escalation: NONE.

## Approved direct NUnit compatibility repair

User replied `同意批准` to the concrete single-attribute correction and reuse
of the stopped Coder -> read-only Verifier. This is a same-task direct test
regression repair, not new delivery authorization. The earlier delivery group
is already consumed; no new commit/export/reference switch is authorized here.

- Repair baseline: HEAD `4291e80795681ad0057518b5ecd6c04e3c9ca92b`.
  Test SHA-256 `2d635f6e858184d11ad28e88c3afd7031ea2945e0c2e766d69ba92f4bf95cc8b`.
  Production SHA-256 `07594a7b236465e26ca91ab2832b9c82d694728a64a3004dac5144d2c0f691a6`.
  Both C# files are clean at this repair admission.
- Repair change allowlist narrows to exactly one test-source line:
  `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`, replacing
  `[NonParallelizable]` with `[Parallelizable(ParallelScope.None)]` on
  `AICodedbPreflightRefreshTests`. Preserve all test bodies/cases and production
  source bytes. Coder appends the repair outcome to RESULT.md; original result
  identities/evidence remain historical and must not be rewritten as a new pass.
- Read closure narrows to this decoration, its NUnit using/assembly reference,
  the S35 actual NUnit DLL/package dependency metadata, existing syntax tool,
  and the failure/accepted records in this task. No broader source review.
- Evidence: exact one-line diff/whitespace; original ten cases remain intact;
  actual NUnit DLL metadata provides ParallelizableAttribute(ParallelScope)
  and ParallelScope.None while NonParallelizableAttribute is absent. If an
  unchanged applicable syntax check is reused, label syntax only. Do not build
  another harness or claim full semantic compilation/NUnit/Unity execution.
- Actual consumer: S35 PackageCache `com.unity.ext.nunit@1.0.6/net35/unity-custom/`
  `nunit.framework.dll`, assembly 3.5.0.0, SHA-256
  `e388e140954de12970384331d1730e95b4613ef53c3326b6f8fa0fffdbc9314f`.
- Independent review: reuse the stopped Verifier only after stopped Coder's
  stable snapshot admission; review original CS0246 finding, replacement
  compatibility/nonparallel intent and unchanged tests/production only.
  Append the repair review to VERIFICATION.md; no unchanged test reruns.
- Existing model, role time/attempt budgets and repository-local output rules
  continue. Subagent mode remains depth-one sequential FAST_SUBAGENT with
  TASK_SPECIFIC current approval. No Unity launch, Test Runner, lifecycle action,
  runtime mutation, package extraction edit, dependency update or process control.
- On any need beyond this one decoration, stop and return its concrete reason.
  This is repair iteration 1/2 for the direct compiler regression; no real
  acceptance reevaluation has yet run on the corrected source.

## Definition Of Done And Handoff

- Source path preserves a paired observation and rejects stale publication;
  nearest tests express both success and state-replacement cases; strict
  binding and freshness guards remain valid. Evidence classes are explicit.
- Coder stops with hashes/diff, focused results and limitations. Parent admits
  the stable snapshot, then an authorized independent Verifier reviews only
  these claims once. Consolidate findings for user ACCEPT/FIX/DEFER/STOP.
- No source acceptance or S35 lifecycle completion is claimed in advance.
  Real idle stability remains unverified until subsequent authorized delivery
  and human observation. S35 Uninstall/reinstall stays paused meanwhile.
- Current status: Coder and read-only Verifier both terminal-completed. Parent
  matched the final hashes after review. Syntax/static checks and targeted source
  review passed with no in-scope finding. Semantic compilation, NUnit and human
  idle stability are deferred. User replied `同意 accept` on 2026-10-19,
  accepting the exact source snapshot with those execution limits. See DECISION.md.
- Next notification: current parent, for the renewed corrected commit/export and
  closed-S35 reference switch. Review closed the original CS0246 finding with
  no new finding; parent matched final hashes and exact +1/-1 diff.
- Next action: execute only the corrected delivery group authorized by the
  user's `授权`; recheck S35 closure before switching and stop if occupied.
- Human decision required: none for this approved correction/review; initial source acceptance
  and delivery remain historical facts, while human compilation has failed.
  No new source work, broader review or dependent S35 lifecycle command starts
  automatically. Real Unity acceptance remains separate. Delivery is recorded
  in DELIVERY-RESULT.md; no lifecycle command or Unity launch was performed.

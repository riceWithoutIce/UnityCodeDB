# Task: cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep
- Review mode: GUARDED
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s06-versioned-lease-aware-retirement`
  (`ACCEPT`, commit `8ccaec40df8773ee0296c4160f8357d5fd7125d3`)
- Requirement source:
  `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: close the explicit, human-confirmed `Reinstall CodeDB` path
  for an installed project whose authenticated legacy control evidence is
  classified as `ObsoleteReinstallRequired`, routing that one action through
  the already accepted S04-S06 activation, rollback, and lease-aware
  retirement contract without enabling automatic migration or a second
  version authority.

## Scope

- In scope:
  - Treat the cached product state
    `NeedsAttention + ControlContractReinstallRequired` as the only Manager
    state that presents and admits `Reinstall CodeDB`. The underlying migration
    state must be the authenticated `ObsoleteReinstallRequired` result and the
    machine prerequisite must already be `Current`.
  - Keep `Uninstalled` on the existing `Install CodeDB` path. Missing
    prerequisite, invalid project integration, `InvalidOrAmbiguous` migration
    evidence, unknown/loading state, and any non-Reinstall attention reason
    must not expose or invoke Reinstall.
  - Require the existing explicit confirmation exactly once. Cancellation
    performs no command, mutation, fallback, or reconcile. Confirmation may
    produce exactly one asynchronous `materialize/Reinstall` request with
    `confirmed_project_mutation=true`.
  - Prefer the authenticated current project Supervisor when it is available.
    Reuse the existing Bridge-authorized one-shot fallback only for its exact
    reviewed empty-current-runtime bootstrap case. A transport outage,
    ambiguous owner, non-empty current namespace, legacy namespace, or stale
    cached UI state must not independently authorize fallback.
  - Reuse the accepted S04-S06 `Invoke-InstanceConvergence` transaction as-is:
    candidate verification precedes selection; PREPARED/ACTIVATING/COMMITTED,
    rollback/recovery, immutable retirement intent, and lease-aware retirement
    remain the only mutation authority.
  - After a successful Reinstall, request one ordinary background reconcile.
    The authenticated current namespace and selected instance become the
    runtime authority; automatic lifecycle work may resume from that result.
    Reconcile must not issue a second Reinstall.
  - Preserve authenticated legacy evidence, unrelated files, existing
    immutable instances, and external holders. Success may report
    `READY + CLEANUP_STATE=PENDING`; physical retirement remains asynchronous
    and must not delay the selected current instance.
  - Add one mutually exclusive old-schema explicit-Reinstall fixture mode to
    the existing materializer harness. It may exercise the accepted production
    Reinstall transaction in a disposable project but must not add or change
    production activation, rollback, retirement, or classification policy.
- Out of scope:
  - Automatic or confirmation-free Reinstall; migration from
    `InvalidOrAmbiguous`; blind deletion, quarantine, or rewriting of legacy
    evidence; and any manual cleanup requirement.
  - Redesigning the control contract, classifier, activation journal,
    retirement intent, lease format, stable wrapper, Supervisor protocol,
    Provider/query/MCP behavior, or immutable Package payload.
  - Changing the accepted S04-S06 transaction engine or Supervisor
    implementation. If the explicit route cannot close without such a change,
    stop and request a separately frozen task instead of expanding this slice.
  - Stopping, killing, signalling, restarting, or attaching to Unity, Codex,
    MCP, Editor, Coordinator, Provider, watcher, Supervisor, or any unrelated
    process.
  - Unity, Unity MCP, EditMode execution, cold-start/Play/Domain Reload, real
    Codex Desktop behavior, consumer/third-party Package acceptance, commit,
    push, publication, deployment, or release claims.
- Allowed files:
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Editor/AICodedbActions.cs`
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
  - `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - this task's `RESULT.md`
- Protected state:
  - `com.rice.ai-codedb/Editor/AICodedbControlContract.cs`,
    `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`,
    `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`,
    `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`,
    `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`, and
    `com.rice.ai-codedb/Payload~/payload-manifest.json` are frozen authorities
    and may be read only through direct references.
  - Existing project/user/global configuration, immutable Package generations,
    runtime state outside disposable fixtures, legacy evidence, active leases,
    and unrelated working-tree files remain unchanged.
  - `UnityValidationProject/` is the only default EditMode validation project.
    Its repository-relative identity is recorded only; it must not be opened,
    changed, copied, recreated, or used to start Unity without separate
    explicit EditMode authorization.
- Snapshot binding:
  - Clean base: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
  - The worktree was clean at task-card creation. Do not reset, clean, stash,
    rebase, amend, or rewrite this base.

## Execution

- Coder actions:
  - Read this task once, then trace only the existing
    Manager -> Actions -> Lifecycle/Bridge -> HostPayloadMaterializer route and
    the direct tests named above. Do not rescan the S04-S06 implementation.
  - First determine which declared behavior is already satisfied. Make only
    the smallest missing admission/routing changes and direct regressions; do
    not churn already-correct production code merely to create a delta.
  - Keep Manager rendering and availability decisions cache-only. The button
    click may enqueue the existing asynchronous action, but must not run the
    classifier, scan/hash files, start a process synchronously, or perform
    mutation on Unity's main thread.
  - Keep the confirmation bit explicit across C#, Bridge, and fallback. Do not
    infer confirmation from the action name, product state, or a previous
    attempt.
  - Use the existing materializer harness to prove composition with the frozen
    Reinstall transaction. Fixture construction may create authenticated known
    obsolete evidence and disposable project state only; it must not modify
    the Package contract or production runtime.
  - Write `RESULT.md` with exact changed files, base/final identity, focused
    evidence, batch/retry counts, actual model/effort, deferred gates, and the
    completion-routing footer. Leave all implementation changes uncommitted.
- Focused tests:
  - L0 tests: add one mutually exclusive `-ControlContractReinstallOnly` mode
    to `test-codedb-host-payload-materializer.ps1`, and run that exact mode at
    most once. One corrected retry after one recorded concrete fixture or
    implementation correction is the hard maximum.
  - The L0 fixture must prove: a known authenticated obsolete state plus
    explicit mutation confirmation reaches the frozen Reinstall transaction;
    candidate verification occurs before selection; the current contract and
    selected current-target instance are valid only after commit; legacy and
    unrelated sentinel bytes remain unchanged; a failed pre-commit attempt
    preserves the prior selection and can be retried explicitly; repeated
    completion is idempotent; and invalid/ambiguous or unconfirmed input fails
    before mutation.
  - The fixture must not start a holder, Unity, Codex, MCP, Supervisor, or other
    external process. Reuse S05/S06 evidence for transaction fault handling and
    live-holder retirement; do not rerun those batches.
  - Affected L1 tests: update only direct Manager/Actions/Lifecycle/Bridge
    source tests for exact status admission, prerequisite and integration
    precedence, cancellation, one confirmed command, fallback authorization,
    no automatic Reinstall, and one post-action reconcile. Execution remains
    `DEFERRED` unless separately authorized through the standard validation
    project.
  - Explicitly not run: S04 `-ActivationContractOnly`, S05
    `-ActivationTransactionOnly`, S06 `-ActivationRetirementOnly`, Supervisor
    Node suites, package-boundary suites, other L0/L1, C# compilation, full
    materializer tests, repository-wide tests, Unity/EditMode, Unity MCP,
    cold-start/Play/Domain Reload, real processes, consumer/third-party
    Package, release, or publication.
  - Test rationale: the new risk is the exact human-action admission and its
    composition with an already accepted Reinstall transaction. Previously
    accepted activation, rollback, retirement, and Supervisor behavior are
    trusted dependencies and are not revalidated here.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - The route can admit Reinstall from `InvalidOrAmbiguous`, missing
    prerequisite, invalid integration, Uninstalled, unknown state, or without
    the current explicit confirmation.
  - A normal Supervisor outage or any non-empty/ambiguous control evidence can
    authorize direct fallback or create a second command owner.
  - Correctness requires changing a protected authority, weakening strict
    validation, rewriting/deleting legacy evidence, stopping a process, or
    touching state outside a disposable fixture.
  - A failed Reinstall changes current selection before candidate verification
    or loses the accepted rollback/retirement authority.
  - A second independent production behavior appears, a command reaches the
    workflow time/output limit, the corrected retry is exhausted, or the first
    context compaction occurs.
  - Unity or Unity MCP is needed. Record the gate as `DEFERRED` or `BLOCKED`
    and notify the human instead of starting, opening, or reconnecting it.
- Escalation triggers:
  - The cached product reason cannot be used as presentation admission without
    running filesystem/classifier work on the Unity main thread.
  - The Bridge cannot distinguish an authenticated empty-current-runtime
    bootstrap from outage, legacy, or ambiguous owner evidence.
  - The frozen materializer/instance engine accepts an invalid migration input
    or cannot complete the known-obsolete fixture without a new lower-level
    policy; propose a separate bounded PowerShell task with the exact finding.
  - Closing the path requires a new public command, Supervisor protocol field,
    control-contract schema, payload transition, or stable-wrapper policy.
- Model escalation: none; the selected deep profile is the approved P0
  cross-layer profile. Any profile or session change requires a checkpoint and
  explicit human approval.

## Definition Of Done

- Expected result:
  - Only an installed, prerequisite-current project with the exact cached
    obsolete-contract reason offers the Reinstall action, and only one explicit
    confirmation launches one serialized Reinstall operation.
  - The action uses the current authenticated Supervisor or the exact
    Bridge-authorized empty-runtime one-shot fallback; outage and ambiguous
    evidence remain fail-closed and cannot create concurrent owners.
  - Successful completion selects a verified current-target instance through
    the accepted versioned transaction, requests one reconcile, preserves
    legacy/unrelated evidence, and allows cleanup to remain safely `PENDING`.
  - Cancellation, pre-commit failure, invalid/ambiguous input, and repeated
    explicit execution are deterministic and do not trigger automatic retry,
    process termination, blind cleanup, or a second authority.
- Required evidence:
  - Exact base/final snapshot identity and changed-file list.
  - One focused `-ControlContractReinstallOnly` command with exit status, wall
    time, captured-output disposition, batch count, and retry count.
  - Direct source-test matrix for UI admission, confirmation, Supervisor versus
    fallback routing, mutation-confirmation propagation, and reconcile count.
  - Fixture evidence for known-obsolete success, invalid/unconfirmed rejection,
    pre-commit preservation, current-contract publication, legacy/sentinel byte
    preservation, and explicit idempotent retry.
  - Explicit `NOT RUN` / `DEFERRED` list. Static and disposable-fixture evidence
    must not be reported as Unity, real runtime, consumer, or release
    acceptance.
- Deferred risks:
  - C# compilation and focused EditMode execution in
    `UnityValidationProject/`.
  - Real Manager interaction, cold start, Domain Reload/Play transitions, and
    real obsolete-project Reinstall with long-lived Codex/MCP/Editor holders.
  - Consumer/third-party Package behavior, sequential activation history,
    final P0 layered acceptance, release, publication, and deployment.

## Handoff

- Current task: cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall
- Current status: READY
- Next notification: v0.3.coder.deep (manual)
- Next action: after explicit human dispatch, execute this frozen task from
  base `8ccaec40df8773ee0296c4160f8357d5fd7125d3`, leave changes uncommitted,
  and return one `RESULT.md` to Planner.
- Human decision or authorization required: manual dispatch; any protected-file
  change, scope/test expansion, Unity/EditMode, external process, commit, push,
  publication, or release action requires separate explicit authorization.

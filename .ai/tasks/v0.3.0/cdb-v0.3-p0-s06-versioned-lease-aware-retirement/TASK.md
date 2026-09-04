# Task: cdb-v0.3-p0-s06-versioned-lease-aware-retirement

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
- Predecessor: `cdb-v0.3-p0-s05-candidate-activation-transaction`
  (`ACCEPT`, commit `0164ee59905d7f72e8d3b4404babf02a6cfed543`)
- Requirement source:
  `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: bind the previous instance retired by one committed S05
  activation to the same versioned control authority, then converge its
  physical cleanup only after all authenticated holders drain. The selected
  new instance becomes and remains usable without waiting for retirement.

## Scope

- In scope:
  - Extend the existing S04/S05 versioned activation namespace. Do not create a
    second activation, generation, lifecycle, or version-policy authority.
  - For an activation with a previous instance, create exactly one immutable
    retirement intent at the derived path
    `retirements/<operation-id>.json` under the same contract namespace.
  - Bind the intent to the trusted control contract and runtime-contract hash,
    project identity, activation epoch, operation id, committed selected
    instance, retired instance, generation identities, and exact instance and
    generation manifest hashes. The versioned operation journal must reference
    the exact intent path and SHA-256. No previous instance means no intent.
  - Publish and validate the intent as part of the existing activation
    transaction before `COMMITTED`. Failure to publish or bind it must preserve
    the S05 rollback/fail-closed behavior. Physical cleanup is never part of
    the activation commit point and never delays the `READY` result.
  - Treat the committed versioned operation plus its referenced retirement
    intent as the only authority to retire an old instance. Never infer
    authority by scanning every non-current instance.
  - Reuse the current serialized materializer lock and `Upgrade` convergence
    entry. A current, usable selected instance with installed
    `cleanup_state=PENDING` enters a retirement-only branch; it must not
    provision a candidate, switch selection, or start another activation.
  - Before deletion, revalidate the committed operation, selected instance,
    intent hash, retired instance closure, path/no-reparse boundaries, MCP
    leases, Editor leases, and Coordinator evidence. Recheck holder evidence
    after publishing the mechanical retiring fence and immediately before
    deletion.
  - Live, invalid, unavailable, conflicting, or ambiguous holder evidence keeps
    the retired instance byte-preserved and reports `READY` with
    `CLEANUP_STATE=PENDING`. No process is stopped by this slice.
  - Proved-stale lease evidence may be removed through the existing owned
    cleanup boundary. Once no active or ambiguous holder remains, delete only
    the intent-bound retired instance. Preserve the immutable intent as durable
    audit evidence; it must remain strictly readable and idempotent after the
    retired instance is absent.
  - Keep the existing Package-manifest-authorized legacy generation/flat
    cleanup behavior mechanically separate and unchanged. Combined cleanup is
    `COMPLETE` only when both the versioned retired-instance work and that
    existing cleanup boundary are complete.
  - Add a narrow Lifecycle route for installed `Ready + PENDING`: use the
    existing background scheduler and single-flight execution, with bounded
    periodic backoff and no immediate `RetrySoon` loop. It may request the
    existing serialized retirement-only convergence but must not perform
    classification, hashing, directory scans, or cleanup on Unity's main
    thread.
  - Keep `control/retired-instances` and instance-local `retiring.json` as
    mechanical fence/compatibility evidence only. They cannot authorize
    deletion without a matching valid versioned retirement intent. Orphaned or
    incompatible evidence remains preserved and `PENDING`.
- Out of scope:
  - Stopping, killing, signalling, or restarting an MCP, Editor, Coordinator,
    Unity, Codex, Provider, watcher, or unrelated process.
  - Changing lease formats, heartbeat policy, Provider/query/MCP protocols,
    stable-wrapper routing, immutable generation contents, payload manifests,
    control-contract identity, or global/user configuration.
  - Candidate provisioning changes beyond adding the retirement intent to the
    existing S05 activation transaction; no new activation phase or public
    user action.
  - Reinstall/Install/Uninstall UI changes, Manager redesign, consumer routing,
    or release/publication work.
  - Unity, Unity MCP, EditMode execution, real Codex Desktop behavior,
    consumer/third-party Package acceptance, commit, push, or deployment.
- Allowed files:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`, only for a
    directly required source/package boundary assertion
  - this task's `RESULT.md`
- Protected state:
  - `com.rice.ai-codedb/Payload~/payload-manifest.json`, immutable Package
    generations, existing project/user/global configuration, runtime state
    outside disposable fixtures, and unrelated working-tree changes remain
    unchanged.
  - Existing retired instances, marker-only evidence, and external process
    state are preserved unless the exact versioned-intent and no-holder proof
    succeeds inside the disposable fixture.
  - `UnityValidationProject/` is the only default EditMode validation project.
    Its presence records the approved project identity only; it must not be
    opened, changed, copied, recreated, or used to start Unity without separate
    explicit EditMode authorization.
- Snapshot binding:
  - Clean base: `0164ee59905d7f72e8d3b4404babf02a6cfed543`.
  - The worktree was clean at task-card creation. Do not reset, clean, stash,
    rebase, or rewrite this base.

## Execution

- Coder actions:
  - Read this task once, then perform one bounded preflight over the allowed
    files and direct retirement/lease helpers only.
  - First preserve the old-instance identity in the versioned activation
    authority; do not begin physical cleanup from the current unbound
    `cleanup_state=PENDING` signal.
  - Keep retirement intent parsing strict: bounded regular files, exact field
    allowlists, exact derived names, containment/no-reparse checks, hashes, and
    cross-record identity consistency. Update the strict contract-namespace
    allowlist for `retirements` without accepting unknown siblings or entries.
  - Keep intent publication, holder classification, deletion, and Lifecycle
    scheduling as one observable contract. If they cannot remain within the
    declared budget, stop at the first stable checkpoint rather than weakening
    authority or expanding tests.
  - Write `RESULT.md` with exact changed files, snapshot identity, focused
    evidence, batch/retry counts, actual model/effort, deferred gates, and the
    completion-routing footer. Leave all implementation changes uncommitted.
- Focused tests:
  - L0 tests: add one mutually exclusive
    `-ActivationRetirementOnly` fixture batch. Run it at most once; one
    corrected retry after a recorded concrete correction is the hard maximum.
  - The L0 fixture must cover: missing/mismatched/orphan intent fails closed;
    valid intent with no holder completes; live MCP lease, live Editor lease,
    and live Coordinator each preserve the instance and process; natural lease
    drain then completes; proved-stale evidence is reclaimed; invalid or
    ambiguous evidence remains preserved; repeated cleanup is idempotent; and
    current selection plus unrelated sentinels remain byte-identical.
  - The fixture may start at most one short-lived, fixture-owned lease-holder
    child process at a time in a disposable project root. It must close the
    process normally in `finally` and prove cleanup never stopped it. This
    authorization does not extend to Unity, Unity MCP, Codex, or a real project
    process.
  - Affected L1 tests: update only the direct Lifecycle scheduling tests that
    prove `Ready + PENDING` selects one throttled retirement request while
    `Ready + COMPLETE`, in-flight, play/compile/update boundaries, and
    invalid/blocked state do not. Execution is deferred unless separately
    authorized through the standard EditMode project.
  - If the package-boundary assertion file changes, run at most one directly
    affected package-boundary batch. Do not add another batch merely because
    the source is shared.
  - Explicitly not run: S05 `-ActivationTransactionOnly`, full materializer or
    Supervisor suites, unchanged L0 groups, C# compilation, repository-wide
    tests, Unity/EditMode, Unity MCP, cold-start/Play/Domain Reload, real
    business processes, consumer/third-party Package, release, or publication.
  - Test rationale: the new risk is exact retirement authorization, holder
    preservation/drain, and one bounded scheduling decision. Previously
    accepted candidate activation and unrelated lifecycle behavior are reused
    as trusted evidence and are not rerun.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - Cleanup authority cannot be bound to the committed activation without
    scanning unbound instances, trusting an old marker, or adding a second
    version-policy authority.
  - A safe result requires stopping a live process, deleting invalid or
    ambiguous evidence, mutating an immutable generation, or touching state
    outside a disposable fixture.
  - `READY` would wait for physical retirement, or a pending lease would cause
    immediate/unbounded materializer retries.
  - A second independent production behavior appears, a command reaches the
    workflow time/output limit, the corrected retry is exhausted, or the first
    context compaction occurs.
  - Unity or Unity MCP is needed. Record the gate as `DEFERRED` or `BLOCKED`
    and notify the human instead of starting or reconnecting it.
- Escalation triggers:
  - Existing S05 contract records cannot safely add a referenced immutable
    retirement intent while preserving rollback and identical retry semantics.
  - Sequential activation or recovery needs activation-history redesign rather
    than the one committed-attempt binding declared here.
  - Lifecycle scheduling cannot be kept single-flight and throttled without a
    new public action, Supervisor protocol, or main-thread filesystem policy.
  - Existing generation/flat cleanup would need a new authority or policy
    change instead of mechanical reuse.
- Model escalation: none; the selected deep profile is the approved P0
  cross-layer profile. Any profile or session change requires a checkpoint and
  explicit human approval.

## Definition Of Done

- Expected result:
  - Every old instance eligible for retirement is named by exactly one valid
    intent referenced by its committed activation operation; arbitrary
    non-current instances and marker-only evidence cannot be deleted.
  - Activation returns `READY/PENDING` without waiting for a live old holder.
    Pending cleanup does not redeploy, reactivate, stop, or disturb the current
    selected instance.
  - Live or ambiguous MCP/Editor/Coordinator evidence preserves the exact old
    closure. After natural drain, a later throttled convergence removes only
    the proved-owned retired instance and reaches `CLEANUP_STATE=COMPLETE`.
  - Crash/retry boundaries remain fail-closed and repeated cleanup is
    idempotent; the versioned intent remains valid audit evidence.
- Required evidence:
  - Exact base and final snapshot identity, changed-file list, and strict
    retirement-intent schema/path/hash relationships.
  - Exact focused command, exit status, wall time, captured-output disposition,
    L0/L1 batch counts, retry count, and fixture process cleanup result.
  - Fixture assertions for authority mismatch, holder preservation, natural
    drain, stale/invalid handling, idempotence, current selection, and unrelated
    sentinel byte identity.
  - Explicit `NOT RUN` / `DEFERRED` list. Static or fixture evidence must not be
    reported as Unity, real runtime, consumer, or release acceptance.
- Deferred risks:
  - Actual Unity lifecycle scheduling and EditMode evidence in
    `UnityValidationProject/`.
  - Real long-lived Codex/MCP drain, Coordinator lifecycle, restart/crash, and
    external Supervisor integration.
  - Sequential activation history, consumer/third-party Package behavior,
    release, publication, and deployment acceptance.

## Handoff

- Current task: cdb-v0.3-p0-s06-versioned-lease-aware-retirement
- Current status: READY
- Next notification: v0.3.coder.deep (manual)
- Next action: after explicit human dispatch, execute this frozen task from
  base `0164ee59905d7f72e8d3b4404babf02a6cfed543`, leave changes uncommitted,
  and return one `RESULT.md` to Planner.
- Human decision or authorization required: manual dispatch; any scope/test
  expansion, Unity/EditMode, another live process, commit, push, publication,
  or release action requires separate explicit authorization.

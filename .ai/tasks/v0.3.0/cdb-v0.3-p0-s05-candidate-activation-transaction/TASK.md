# Task: cdb-v0.3-p0-s05-candidate-activation-transaction

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
- Predecessor: `cdb-v0.3-p0-s04-activation-contract-foundation`
  (`ACCEPT`, commit `769e5c12c7678e490dd25845c9d60c04d4a2b17e`)
- Requirement source:
  `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`
  (delivery order 4); `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: connect the S04 versioned activation contract to one
  serialized candidate-to-activation operation, so a candidate is fully
  verified before selection changes and the versioned activation operation
  record is the authority for the new activation attempt. Do not implement
  retirement or consumer migration in this slice.

## Scope

- In scope:
  - Reuse the existing instance engine and convergence path. Do not create a
    second transaction, candidate, or activation engine.
  - Build the trusted S04 contract context from the Package manifest and bind
    one immutable `activation_epoch`/`operation_id` pair to the attempt.
  - Reuse the existing immutable candidate construction and package-owned
    candidate checks: closure/hash/path/reparse validation, machine
    prerequisite admission, MCP initialize and exact read-only tools/list,
    usable `codedb_status`, and one bounded `codedb_text_search` where the
    existing path supports it.
  - Persist a matching versioned activation record and operation journal in
    `PREPARED` before selection mutation, advance the same attempt to
    `ACTIVATING`, publish the reviewed selection/wrapper/config mutation set
    atomically, verify the selected candidate, and finish as `COMMITTED`.
  - Preserve the pre-activation current and last-known-good selection when
    candidate verification fails. For an interruption or injected activation
    failure, recover from the durable pre-images or return a deterministic
    fail-closed result; never select an unverified candidate.
  - Make an identical retry or recovery of one operation idempotent. A new
    attempt must use a new epoch/id pair and must not overwrite a conflicting
    record.
  - Make the S04 versioned operation record the sole authoritative state for a
    new activation attempt. A legacy/unversioned transaction artifact may be
    retained only as explicitly bound mechanical recovery evidence; it must
    not independently authorize, commit, or classify the activation.
  - Keep old selected instances and external MCP clients alive. Retirement,
    lease drain, and cleanup are not part of this task.
  - Add only deterministic fixture coverage needed for the candidate boundary,
    activation commit boundary, rollback/recovery, idempotence, and strict
    journal conflict handling.
- Out of scope:
  - Retired-instance deletion, quarantine, lease draining, process stopping,
    or any physical cleanup of the previous instance.
  - A new Manager, Bridge, Lifecycle, stable-wrapper, C# or Node policy path;
    the existing callers must not gain a second version authority here.
  - New Reinstall UI/presentation or automatic Reinstall triggering. An
    already named `Install`/`Upgrade`/explicit `Reinstall` command may share
    the common operation only when required to prove the frozen engine path.
  - Provider/query protocol changes, MCP registration redesign, payload or
    manifest changes, immutable generation content changes, or global config
    changes.
  - Unity, Unity MCP, EditMode, real Codex Desktop behavior, consumer or
    third-party Package acceptance, release, publication, commit, or push.
- Allowed files:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`, only when a
    narrowly necessary source/package boundary assertion is added or changed
  - this task's `RESULT.md`
- Protected state:
  - `Payload~/payload-manifest.json`, immutable Package generations, C#/Node
    contract authorities, project/user/global configuration, editor leases,
    existing selected/LKG state outside isolated fixtures, and external
    processes remain unchanged.
  - The Package manifest remains the only version-policy authority. Do not add
    a PowerShell current/previous table, hard-coded `poc.*` policy, or a second
    independently writable activation state.
  - Fixture commands must use temporary project roots and clean up their own
    disposable state; they must not mutate the repository's development
    project runtime.
- Snapshot binding:
  - Clean base: `769e5c12c7678e490dd25845c9d60c04d4a2b17e`.
  - The worktree is clean at task-card creation. Do not reset, clean, stash,
    rebase, or rewrite this base.

## Execution

- Coder actions:
  - Read this task once, then perform a bounded preflight over only the allowed
    files and direct helpers needed to connect S04 to the existing convergence
    path.
  - Reuse `New-VerifiedInstanceCandidate`, the existing candidate probe, and
    the existing durable transaction/pre-image machinery where safe. Adapt the
    machinery to the S04 contract instead of adding parallel policy.
  - Freeze the exact activation mutation allowlist and its pre/postconditions
    in `RESULT.md`; do not broaden it during implementation.
  - Add one mutually exclusive focused harness mode for this slice (for
    example `-ActivationTransactionOnly`) or extend one existing narrowly
    equivalent mode without running unrelated groups.
  - Write `RESULT.md` with exact changed files, command/output/time evidence,
    batch and retry counts, actual model/effort, deferred gates, and the
    completion-routing footer. Leave all changes uncommitted.
- Focused tests:
  - L0: at most one batch of the new activation-transaction harness; one
    corrected retry is the hard maximum. If the package-boundary file is
    changed, run at most one directly affected package-boundary batch.
  - The bounded fixture set must cover: candidate failure leaves current/LKG
    unchanged; successful PREPARED -> ACTIVATING -> COMMITTED publication;
    one activation interruption or failure recovery; identical retry
    idempotence; strict mismatched/conflicting journal rejection; and an old
    external-MCP/legacy-state sentinel that is not stopped or deleted.
  - A real candidate probe may be represented by the existing deterministic
    fixture path only. Do not launch Unity, Unity MCP, a real Codex client, or
    an unrequested external process for evidence.
  - Explicitly not run: full materializer or Supervisor suites, unchanged L0
    groups, C# compilation, Editor tests, repository-wide tests, Unity/EditMode,
    Unity MCP, cold-start/Play/Domain Reload, consumer/third-party Package,
    release, and publication acceptance.
  - Test rationale: this slice changes the PowerShell activation transaction
    boundary and durable selection evidence; only the new contract/rollback
    fixtures are needed. Existing accepted routing and S04 contract tests are
    not rerun unless a changed assertion directly requires the package-boundary
    batch.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - A correct implementation requires changing the manifest/payload, C#/Node,
    Bridge/Manager/Lifecycle, Provider, or the declared file set.
  - The new contract and legacy journal cannot be made one authoritative
    operation without a broader migration design.
  - Candidate verification would require stopping an old or external process,
    deleting/quarantining ambiguous evidence, mutating a published generation,
    or bypassing a path/identity/reparse/prerequisite check.
  - Any command reaches its workflow time/output limit, the allowed retry
    count is exhausted, or a second independent behavior enters the slice.
  - Unity or Unity MCP is needed; record the gate as `DEFERRED`/`BLOCKED`
    instead of attempting an unrequested connection.
- Escalation triggers:
  - Existing convergence writes a second independently authoritative journal
    or cannot bind its low-level rollback evidence to the S04 operation pair.
  - Atomic publication cannot prove that current, LKG, wrapper, and journal
    identities refer to the same candidate and epoch.
  - Recovery after an interrupted mutation cannot distinguish committed,
    rollback-safe, and ambiguous states without adding a new authority.
  - The requested behavior reaches retirement, Reinstall user flow, or
    consumer routing.
- Model escalation: none; the selected deep profile is the approved
  cross-layer profile. Any profile change requires a new checkpoint and human
  approval.

## Definition Of Done

- Expected result:
  - A candidate is admitted and probed before any current-instance selection
    or owned wrapper/config activation mutation.
  - One versioned operation/activation pair records the same contract,
    project, runtime, candidate, epoch, phase, and mutation evidence through
    `PREPARED`, `ACTIVATING`, and `COMMITTED`.
  - Candidate failure, conflicting evidence, interruption, and retry are
    deterministic and fail closed; a previous usable selection remains intact
    until a verified commit.
  - No old instance, external MCP client, unrelated configuration, or
    ambiguous legacy evidence is stopped, deleted, or silently adopted.
  - Retirement and all consumer/UI changes remain untouched for a later slice.
- Required evidence:
  - Exact base/snapshot identity and changed-file list.
  - Exact focused command(s), exit status, wall time/output budget, L0 batch
    count, and retry count.
  - Fixture assertions showing the pre-activation boundary, phase transition,
    commit/recovery result, idempotence, and protected-state byte identity.
  - An explicit list of Unity, runtime, consumer, and release evidence that
    was not run; no static result may be reported as live acceptance.
- Deferred risks:
  - Lease-aware retirement, old-process cleanup, and external-client drain.
  - Explicit Reinstall execution/user flow and Bridge/Lifecycle/Manager
    consumption of activation progress.
  - C# compilation, Unity/EditMode, real Unity/Codex, consumer Package, and
    release acceptance.

## Handoff

- Current task: cdb-v0.3-p0-s05-candidate-activation-transaction
- Current status: READY
- Next notification: v0.3.coder.deep (manual)
- Next action: human-notify the existing deep Coder to execute this frozen
  task from base `769e5c12c7678e490dd25845c9d60c04d4a2b17e`; it must leave the
  implementation uncommitted and write `RESULT.md`.
- Human decision or authorization required: manual dispatch; any scope/test
  expansion, Unity/EditMode, real process, commit, push, publication, or
  release action requires separate explicit authorization.

# Task: cdb-v0.3-p0-s03-migration-state-routing

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
- Requirement source: `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  (P0 control-contract migration); `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`
  (compatibility classification and Manager boundaries);
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: consume the existing read-only control-contract migration
  classifier in the background lifecycle path and present its cached result in
  Manager without automatically starting or mutating an unsafe legacy state.

## Scope

- In scope:
  - Read `AICodedbControlContractMigrationStore` from the background lifecycle
    worker before any Supervisor command that can start or mutate runtime state.
  - Map `ObsoleteReinstallRequired` to `NeedsAttention` with a stable migration
    reason and make `Reinstall CodeDB` the Manager primary action only for that
    explicit reason.
  - Map `InvalidOrAmbiguous` to fail-closed `NeedsAttention` without offering or
    executing Reinstall automatically.
  - Preserve the existing automatic convergence path for `Missing`, `Current`,
    and `CompatibleStale`.
  - Preserve `MissingPrerequisite` precedence over the migration action without
    starting a Supervisor merely to establish that precedence.
  - Keep Manager open, repaint, and drawing paths cache-only; they must not read
    migration files or invoke the classifier.
- Out of scope:
  - Implementing or changing the Reinstall execution path.
  - Candidate provisioning, activation journal/epoch, atomic activation,
    rollback, retirement, cleanup, deletion, quarantine, or process stopping.
  - Changing the classifier schema or weakening its fail-closed rules.
  - Node, PowerShell materializer, payload, Provider, query, MCP registration,
    or immutable-generation behavior.
  - Unity startup, Unity MCP, EditMode execution, full regression, real
    Unity/Codex, consumer or third-party Package acceptance, commit, push, or
    release work.
- Allowed files:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
  - `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
- Protected state:
  - `com.rice.ai-codedb/Editor/AICodedbControlContract.cs` remains the read-only
    classifier authority.
  - Package runtime contracts, current/last-known-good selections, current and
    legacy Supervisor evidence, editor leases, external processes, and global
    configuration remain unchanged.
- Snapshot binding: clean `HEAD cd1ec021179b3c36312774d282dae17652c4d832`.

## State Mapping

| Classifier state | Product/UI result | Automatic Supervisor path |
|---|---|---|
| `ObsoleteReinstallRequired` | `NeedsAttention`; exact Reinstall reason and action | Blocked |
| `InvalidOrAmbiguous` | `NeedsAttention`; diagnostic only, no Reinstall action | Blocked |
| `Missing` | Existing convergence behavior | Allowed |
| `Current` | Existing convergence behavior | Allowed |
| `CompatibleStale` | Existing convergence behavior | Allowed |

`MissingPrerequisite` takes precedence over the Reinstall presentation. The
implementation may introduce one small pure decision helper or status field to
carry this distinction, but it must not add another migration authority.

## Execution

- Coder actions:
  - Read this task once, then inspect only the allowed files and direct members
    needed to place the background admission gate and cached presentation.
  - Reuse the classifier status, detail, and diagnostic detail; do not duplicate
    legacy parsing or contract validation.
  - Add the smallest state/reason carrier needed to distinguish explicit
    Reinstall from generic `NeedsAttention`.
  - Add or adjust only direct lifecycle and Manager decision tests for the five
    classifier states, prerequisite precedence, and cache-only UI behavior.
  - Write `RESULT.md` with the exact changed files, evidence, deferred gates,
    actual model/effort, and completion footer; leave all changes uncommitted.
- Focused tests:
  - L0 tests: at most one focused run of
    `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`, only if its
    existing or narrowly adjusted assertions cover the new source boundary.
  - Affected L1 tests: the directly affected lifecycle/Manager Editor test
    fixtures are required as source coverage but execution is `DEFERRED` unless
    a separate Unity EditMode authorization is granted.
  - Explicitly not run: unchanged Supervisor Node tests, full Editor/full
    repository regression, Unity/EditMode, Unity MCP, cold-start/Play, real
    Codex, consumer/third-party Package, and release acceptance.
  - Test rationale: this slice changes only C# lifecycle state reduction and
    cached Manager presentation; the already accepted Supervisor routing L0 is
    not rerun.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - The classifier would run from Manager drawing, repaint, or another Unity
    main-thread presentation path.
  - Establishing precedence would require starting a Supervisor, mutating a
    project, deleting evidence, clearing a lease, or stopping a process.
  - The change reaches Reinstall execution, activation, rollback, retirement,
    Node/PowerShell policy, or a second independent behavior.
  - A command reaches its workflow limit, a second corrected retry would be
    needed, or the allowed-file boundary is insufficient.
- Escalation triggers:
  - `MissingPrerequisite` cannot be determined without an external process or
    project mutation.
  - Existing product status cannot distinguish explicit Reinstall from generic
    `NeedsAttention` without a cross-contract schema change.
  - Any obsolete or ambiguous evidence would still permit automatic Supervisor
    startup or expose Reinstall for the ambiguous case.
- Model escalation: none; the selected deep profile is already the approved
  cross-layer profile for this slice.

## Definition Of Done

- Expected result:
  - Lifecycle blocks automatic Supervisor work for obsolete and ambiguous
    migration evidence before the first mutating/start-capable command.
  - Only the explicit obsolete classification produces the cached Manager
    `Reinstall CodeDB` action; ambiguous evidence stays fail-closed.
  - Missing prerequisites retain presentation precedence, while missing/current/
    compatible-stale classifier states preserve existing convergence.
  - Manager rendering remains cache-only and the classifier remains the single
    migration authority.
- Required evidence:
  - Focused pure decision/source tests cover every row in the state mapping and
    the missing-prerequisite precedence rule.
  - The exact first Supervisor-command boundary is identified and shown to be
    after migration admission.
  - L0/L1 batch counts, any retry, and all unexecuted Unity gates are recorded
    without substituting static evidence for runtime acceptance.
- Deferred risks:
  - C# compilation and EditMode behavior remain deferred without a separately
    authorized Unity run.
  - Reinstall execution, activation/rollback safety, real Unity/Codex behavior,
    consumer/third-party Package behavior, and release acceptance remain later
    tasks.

## Handoff

- Current task: cdb-v0.3-p0-s03-migration-state-routing
- Current status: READY
- Next notification: v0.3.coder.deep (manual)
- Next action: human-notify the existing deep Coder with this frozen task; do
  not run Unity or commit.
- Human decision or authorization required: manual dispatch; any Unity/EditMode,
  commit, push, or release action requires separate explicit authorization.

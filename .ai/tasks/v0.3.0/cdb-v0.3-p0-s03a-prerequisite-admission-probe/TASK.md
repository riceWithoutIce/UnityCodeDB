# Task: cdb-v0.3-p0-s03a-prerequisite-admission-probe

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
- Predecessor: `cdb-v0.3-p0-s03-migration-state-routing` (`BLOCKED`)
- Requirement source: `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  (P0 control-contract migration);
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`
  (compatibility classification and Manager boundaries);
  `com.rice.ai-codedb/Documentation~/development-workflow.md`;
  predecessor `TASK.md` and its confirmed blocker in `RESULT.md`

## Objective

- Single outcome: close the predecessor's cold-start precedence blocker by
  obtaining one authoritative, read-only prerequisite result on the background
  lifecycle path before mapping a blocked migration state, without starting a
  Supervisor or introducing a second prerequisite-policy authority.

## Snapshot Binding

- Base: `HEAD cd1ec021179b3c36312774d282dae17652c4d832`.
- Required checkpoint: the current uncommitted S03 changes in exactly these
  seven paths are the input snapshot and must be preserved:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
- This is a continuation on the same working tree, not a clean-checkout task.
  Do not reset, clean, stash, rebase, revert, or recreate the S03 checkpoint.
- Do not rewrite the frozen S03 `TASK.md` or its `RESULT.md`. Record S03a work
  only under this task directory.

## Scope

- In scope:
  - Read current project integration state before reducing control-contract
    migration state into a product/UI result.
  - Preserve existing invalid-integration handling and make `Uninstalled`
    retain Install semantics; neither state may expose `Reinstall CodeDB` from
    obsolete migration evidence.
  - Preserve migration admission before every Supervisor command that can
    start or mutate runtime state.
  - For an installed project with `ObsoleteReinstallRequired` or
    `InvalidOrAmbiguous`, use a trustworthy current prerequisite result when
    one is already available in the same admission pass.
  - When no trustworthy current prerequisite result is available, permit at
    most one direct call from the background worker to
    `AICodedbHostPayloadMaterializer.ReadStatus(context, cancellationToken)`.
    This is the existing PowerShell `DryRun` authority; it is not a Supervisor
    command and must remain read-only.
  - Reuse the existing command-result parser and product-status builder to
    distinguish an explicit missing prerequisite from an explicit current
    prerequisite. Do not infer current state from the cold-start default,
    `_leasePrerequisiteCurrent`, `previousProductState`, a fingerprint alone,
    or the absence of an error.
  - Keep the authoritative result cached through the existing lifecycle status
    path. Do not retry inside the same worker pass and do not schedule a timer
    loop solely to repeat this admission probe.
  - Keep Manager open, repaint, and drawing paths cache-only.
- Out of scope:
  - A new C# Node/Provider validator or any duplicated prerequisite policy.
  - Changes to the PowerShell materializer, its prerequisite rules, Provider
    identity/hash rules, command-result schema, or timeout policy.
  - Reinstall execution, candidate provisioning, activation, rollback,
    retirement, cleanup redesign, deletion, quarantine, or process stopping.
  - Changing the migration classifier schema or weakening fail-closed rules.
  - Supervisor Node behavior, payload/Provider/query/MCP behavior, immutable
    generations, Unity startup, Unity MCP, EditMode execution, real probe
    execution during development, commit, push, or release work.
- S03a modification allowlist:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
- Checkpoint-only paths: preserve the inherited changes in
  `AICodedbHostPayloadMaterializer.cs`, `AICodedbManagerWindow.cs`, and
  `AICodedbStatusSnapshot.cs`; do not add S03a edits to them. If the
  modification allowlist is insufficient, stop and report `BLOCKED` rather
  than widening it.
- Protected state:
  - `AICodedbControlContractMigrationStore` remains the sole migration
    classifier authority.
  - PowerShell `DryRun` remains the sole current Node/Provider prerequisite
    authority used by this path.
  - Package runtime contracts, integration state, runtime files, leases,
    external processes, and global configuration remain unchanged by S03a.

## Decision Matrix

| Current integration | Migration admission | Current prerequisite evidence | Product/UI result | External action |
|---|---|---|---|---|
| `Uninstalled` | Any | Not required | `Uninstalled`; Install only | No admission probe; no Reinstall |
| `Invalid` | Any | Not required | Existing invalid-integration attention; no Reinstall | No admission probe |
| Installed | `Missing`, `Current`, or `CompatibleStale` | Not required for this gate | Existing convergence behavior | Existing admitted path |
| Installed | `ObsoleteReinstallRequired` | Explicit `Missing` | `MissingPrerequisite`; no Reinstall | One DryRun maximum if needed |
| Installed | `ObsoleteReinstallRequired` | Explicit `Current` | Migration `NeedsAttention`; Reinstall offered | One DryRun maximum if needed |
| Installed | `InvalidOrAmbiguous` | Explicit `Missing` | `MissingPrerequisite`; no Reinstall | One DryRun maximum if needed |
| Installed | `InvalidOrAmbiguous` | Explicit `Current` | Diagnostic `NeedsAttention`; no Reinstall | One DryRun maximum if needed |
| Installed | Either blocked state | Failed, cancelled, timed out, malformed, unknown, or ambiguous | Fail-closed `NeedsAttention`; no Reinstall | No retry in the same pass |

For a blocked migration, an explicit missing prerequisite has presentation
precedence. An explicit current prerequisite permits the migration mapping but
does not permit automatic Supervisor startup. Any other probe result is not
proof that prerequisites are current and must not expose Reinstall.

## Execution

- Coder actions:
  - Read this task once, then inspect only the modification allowlist and direct
    members needed to use the existing `ReadStatus` and status-builder APIs.
  - Implement the smallest background-worker ordering and pure decision change
    needed for the matrix above.
  - Keep the DryRun call injectable or decision-tested without executing the
    real PowerShell process in development tests.
  - Prove by focused source tests that integration is read first, blocked
    migration remains before the first Supervisor command, and the admission
    DryRun cannot be called from Manager/UI paths.
  - Write `RESULT.md` in this task directory with exact S03a edits, inherited
    checkpoint paths, evidence, deferred gates, actual model/effort, budget
    ledger, and completion footer. Leave the complete checkpoint uncommitted.
- Retry/cache boundary:
  - At most one admission `ReadStatus` call per worker pass.
  - No immediate retry after failure, cancellation, timeout, or ambiguous
    output.
  - A later attempt may occur only through an existing meaningful lifecycle or
    machine-evidence trigger; do not add a periodic or self-rescheduling probe
    loop for a blocked migration.
- Focused tests:
  - L0: at most one run of
    `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`, only after all
    source/test edits are complete.
  - Affected C# lifecycle/Manager tests are required as source coverage for the
    decision matrix, ordering, one-call boundary, and fail-closed behavior.
  - Do not execute a real prerequisite probe to obtain development evidence;
    use pure decisions, supplied command results, or source-boundary assertions.
  - Explicitly do not rerun unchanged Supervisor Node L0, the PowerShell
    materializer suite, full Editor/repository regression, Unity/EditMode,
    Unity MCP, cold-start/Play, real Unity/Codex, consumer/third-party Package,
    or release acceptance.
  - Test rationale: this slice changes only C# lifecycle admission and cached
    status reduction. Existing materializer DryRun authority and S02 Supervisor
    routing are inputs, not retest targets.
- EditMode authorization: NOT_REQUESTED
- Workflow budget: use the default hard limits in `development-workflow.md`;
  no exception is authorized by this task.
- Stop conditions:
  - The solution would start a Supervisor before migration admission or invoke
    DryRun from Unity main-thread presentation code.
  - DryRun would mutate project/runtime state, start a Supervisor, or require a
    PowerShell policy/schema change.
  - More than one admission probe is needed in one worker pass, a periodic
    retry loop is required, or ambiguous evidence would expose Reinstall.
  - The modification allowlist is insufficient, a second independent behavior
    appears, or a command reaches a workflow stop limit.
- Escalation triggers:
  - Existing parsed DryRun output cannot distinguish explicit prerequisite
    `Missing` from explicit `Current` without a new policy authority.
  - Preserving `Uninstalled` or invalid integration would bypass a required
    safety cleanup that cannot remain behind migration admission.
  - The task cannot test call-count/order without executing a real PowerShell
    process or expanding production interfaces beyond the allowlist.
- Model escalation: none; the selected deep profile is already the approved
  cross-layer/P0 profile for this blocker repair.

## Definition Of Done

- Expected result:
  - Cold start no longer treats `Starting` or another stale cache as current
    prerequisite evidence.
  - `Uninstalled` keeps Install semantics even when obsolete migration evidence
    exists.
  - Installed blocked migration uses at most one authoritative DryRun result:
    missing prerequisite wins, current prerequisite permits only the applicable
    migration presentation, and every uncertain result fails closed without
    Reinstall.
  - No blocked migration reaches an automatic Supervisor command, and Manager
    remains classifier/probe-free and cache-only.
- Required evidence:
  - Focused source tests cover every changed row in the decision matrix,
    including cold-start `Starting`, Uninstalled, missing/current prerequisite,
    ambiguous migration, probe failure/cancellation, and the one-call boundary.
  - A focused source-boundary assertion identifies integration read, migration
    admission, optional direct DryRun, and the first Supervisor command in the
    required order.
  - The one permitted L0 batch count, retry count, output/time ledger, and all
    unexecuted runtime evidence classes are recorded honestly.
- Deferred risks:
  - C# compilation and Unity EditMode behavior remain `DEFERRED` without
    separate authorization.
  - The real PowerShell DryRun call on Unity cold start, cancellation/timeout,
    domain reload, and real obsolete/ambiguous fixtures remain runtime evidence
    gaps.
  - Reinstall execution, activation/rollback safety, real Unity/Codex behavior,
    consumer/third-party Package behavior, and release acceptance remain later
    tasks.

## Handoff

- Current task: cdb-v0.3-p0-s03a-prerequisite-admission-probe
- Current status: READY
- Next notification: v0.3.coder.deep (manual)
- Next action: human-notify the existing deep Coder to execute this task on the
  current seven-path S03 checkpoint; do not clean the working tree.
- Human decision or authorization required: manual dispatch; any Unity/EditMode,
  real prerequisite-probe execution for evidence, commit, push, or release
  action requires separate explicit authorization.

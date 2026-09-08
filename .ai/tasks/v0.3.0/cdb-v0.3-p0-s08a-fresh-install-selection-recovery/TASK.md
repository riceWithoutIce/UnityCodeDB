# Task: cdb-v0.3-p0-s08a-fresh-install-selection-recovery

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
- Predecessor: `cdb-v0.3-p0-s08-control-plane-code-freeze-l0`
  (`BLOCKED` at ATTEMPT-03 child `2/8`)
- Requirement source:
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08-control-plane-code-freeze-l0/TASK.md`;
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08-control-plane-code-freeze-l0/RESULT.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: restore the explicit fresh `Install` path after a completed
  `Uninstall` when durable committed activation evidence exists but the old
  current-instance selection has correctly been removed, without weakening
  missing-selection fail-closed behavior for any ordinary installed state.

## Scope

- In scope:
  - Treat the exact S08 ATTEMPT-03 `-UninstallOnly` failure as the reproduction
    evidence; do not rerun it before investigation or repair.
  - Trace only `Invoke-UninstallAcceptanceScenarios`, the materializer's
    `Install` dispatch, `Invoke-InstanceUninstall`,
    `Invoke-InstanceConvergence`, activation-contract recovery, operation
    recovery, and current-selection validation directly involved in the
    failure.
  - Explain why fresh Install observes a recovered `COMMITTED` activation and
    then fails with `Current CodeDB instance selection is missing.`
  - Make the smallest correction at the existing authority boundary. An exact
    authenticated `UNINSTALLED` desired state plus an explicit confirmed
    `Install` may supersede or retire only the prior completed installation
    evidence required by the existing contract.
  - Preserve fail-closed behavior when selection is missing from an installed,
    ambiguous, invalid, mismatched, incomplete, or non-explicit path.
  - Preserve the accepted activation transaction, rollback, recovery,
    retirement-intent, old-schema Reinstall, and holder-safety authorities.
  - Keep the direct fixture assertions that fresh Install creates a new
    instance identity, valid current selection, current generation/stable
    wrapper, `INSTALLED + COMPLETE` desired state, and exact user-owned MCP and
    business sentinel bytes; repeated Install must remain rejected.
- Out of scope:
  - Redesigning the activation schema, operation journal, selection format,
    desired-state contract, retirement intent, control namespace, Supervisor
    protocol, Package payload, or public action surface.
  - General tolerance for a missing current selection, blind deletion of
    activation evidence, adoption of an unauthenticated journal, reuse of the
    retired instance, or changing the fixture expectation to accept failure.
  - Any unrelated Uninstall, Upgrade, Reinstall, Repair, MCP, Provider,
    Supervisor, lifecycle, Manager, query, or release behavior.
  - Resuming the S08 eight-command batch or running any S08 child other than
    the one authorized `-UninstallOnly` repair check.
  - Unity, Unity MCP, EditMode, C# compilation, PlayMode, cold start, Domain
    Reload, real project migration, external acceptance, full regression,
    commit, push, publication, or deployment.
- Allowed files:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08a-fresh-install-selection-recovery/RESULT.md`
- Protected state:
  - The S08 `TASK.md` and `RESULT.md` are immutable input evidence.
  - `Payload~/payload-manifest.json`, all C# files, Supervisor/Node sources,
    wrapper sources, project/user/global configuration, Package generations,
    and runtime state outside harness-owned disposable fixtures are read only.
  - `UnityValidationProject/` remains the only default EditMode project, but
    this task does not authorize opening or using it.
  - Existing unrelated working-tree files must remain unchanged.
- Snapshot binding:
  - Base and expected HEAD:
    `6408b0d540b32584147588efb67ecc5ba12b2fda`.
  - Expected pre-existing untracked inputs are the S08 `TASK.md` and
    `RESULT.md`, plus this S08a `TASK.md`; during execution this task's
    `RESULT.md` may be added.
  - Use `git status --short --untracked-files=all` when file-level task status
    is needed. Do not fail only because default Git status collapses an
    untracked task directory.
  - Do not reset, clean, stash, rebase, amend, or rewrite the base.

## Execution

- Coder actions:
  - Read this task once and only the S08 ATTEMPT-03 failure section needed for
    the preserved reproduction. Do not dump or reread the complete S08 record.
  - Perform one bounded admission check for exact HEAD, clean allowed
    production/test paths, and only the expected task records. Return the raw
    tool result without JavaScript encoding or byte-count wrappers.
  - Inspect only the direct functions named in scope. Record one concrete root
    cause and the chosen authority boundary in `RESULT.md` before describing
    the repair.
  - Make one minimal repair. Prefer the instance engine as the single state
    authority; change the materializer dispatch or fixture only when the direct
    evidence proves that boundary owns the defect. Do not duplicate policy.
  - Preserve strict validation before any cleanup or supersession. Any special
    handling must require exact `UNINSTALLED` desired-state identity and the
    explicit `Install` action, and must not authorize a normal read of invalid
    or incomplete evidence.
  - Run one targeted PowerShell AST parse covering only changed `.ps1` files.
  - Run exactly one focused repair test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

  - Run exactly one scoped `git diff --check` over the allowed production/test
    files after the final edit. Do not run a full diff.
  - Perform one final scoped status and patch-identity capture. Record changed
    files, exact HEAD, patch identity, AST/test/diff evidence, time/output
    disposition, actual model/profile, deferred gates, and the completion
    footer in `RESULT.md`. Use repository-relative paths only and do not copy
    raw logs.
- Focused tests:
  - Preserved reproduction: S08 ATTEMPT-03 `-UninstallOnly`, outer exit `1`,
    inner Install exit `6`, phase `PREFLIGHT`, reason
    `INSTANCE_CONVERGENCE_FAILED`; no reproduction rerun is authorized.
  - New L0 repair batch: exactly one `-UninstallOnly` invocation after the
    repair, maximum wall time `180 seconds`, captured output below `64 KiB`.
  - Retry budget: `0/0`. A failed or incomplete repair run stops this task.
  - Static allowance: one changed-file AST parse and one scoped
    `git diff --check`; neither authorizes another functional test.
  - Explicitly not run: other materializer modes, S08 commands `1` and `3-8`,
    no-switch/full harness, other L0/L1, C# compile, Unity/EditMode, Unity MCP,
    real processes, consumer/third-party Package, and repository-wide tests.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - The failure cannot be explained from the direct Install/uninstall/
    convergence/recovery path within the bounded read.
  - Correctness requires a protected file, schema/protocol change, second state
    authority, broad cleanup, unauthenticated adoption, or weakening ordinary
    missing-selection validation.
  - More than one independent production behavior is found, or the proposed
    correction expands beyond the exact fresh Install transition.
  - AST parse, the single `-UninstallOnly` run, or scoped diff check fails;
    output truncates; the test reaches `180 seconds`; an unexpected process is
    required; or the first context compaction occurs.
  - Unity or Unity MCP appears necessary. Record it as `DEFERRED` or `BLOCKED`
    and notify the human instead of starting or connecting it.
- Escalation triggers:
  - The correct owner of prior committed activation evidence cannot be decided
    without changing the accepted S04-S07 contract.
  - Fresh Install requires a new schema field, a new journal kind, or a new
    public command instead of an exact transition within existing authority.
  - The focused repair passes only by removing an adjacent assertion or by
    failing to prove a new instance and byte-preserved user state.
- Model escalation: none; this P0 state-authority repair remains assigned to
  the approved deep profile.

## Definition Of Done

- Expected result:
  - After exact explicit Uninstall, one confirmed fresh Install creates and
    selects a new verified immutable instance and reaches `INSTALLED` with
    cleanup `COMPLETE` despite authenticated prior committed activation
    evidence.
  - Ordinary installed/invalid/ambiguous missing-selection states remain
    fail-closed; the prior retired identity is not reused; activation,
    rollback, retirement, Reinstall, user MCP content, and unrelated bytes are
    not weakened or rewritten.
- Required evidence:
  - Concrete root cause and ownership decision tied to the direct functions.
  - Exact changed-file list, base/final HEAD, and scoped patch identity.
  - One changed-file AST parse, one `-UninstallOnly` result with exit/wall/
    output disposition, and one scoped `git diff --check` result.
  - Batch count `1/1`, retry count `0/0`, explicit deferred boundaries, and no
    claim that the remaining S08 commands or Unity gates passed.
- Deferred risks:
  - S08 commands `3-8` and a new complete code-freeze batch remain pending
    after this focused repair is accepted.
  - C# compilation, focused EditMode in `UnityValidationProject/`, Unity
    runtime behavior, real Manager/Supervisor/Install flows, consumers, and
    release acceptance remain separate gates.

## Handoff

- Current task: cdb-v0.3-p0-s08a-fresh-install-selection-recovery
- Current status: READY
- Next notification: v0.3.coder.deep
- Next action: implement and validate only the bounded fresh Install recovery
  correction, then return `RESULT.md` to UnityCodeDB v0.3 Planner; do not
  contact Verifier directly.
- Human decision or authorization required: manual Coder dispatch; any scope
  expansion, retry, extra test, Unity/EditMode run, commit, push, or Verifier
  routing requires a separate Planner/user decision.

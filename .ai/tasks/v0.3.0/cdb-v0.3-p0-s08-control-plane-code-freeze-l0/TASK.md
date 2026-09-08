# Task: cdb-v0.3-p0-s08-control-plane-code-freeze-l0

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
- Predecessor: `cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall`
  (`ACCEPT`, commit `6408b0d540b32584147588efb67ecc5ba12b2fda`)
- Requirement source:
  `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: produce one bounded, non-Unity L0 code-freeze evidence set
  for the accumulated S02-S07 control-plane snapshot at commit `6408b0d`,
  without changing production or test behavior.

## Scope

- In scope:
  - Bind all evidence to exact HEAD
    `6408b0d540b32584147588efb67ecc5ba12b2fda`.
  - Run one serial L0 batch consisting only of the eight commands declared
    below. Each command may be invoked at most once.
  - Cover the four remaining fixture categories without a broad harness run:
    clean/fresh Install through `-UninstallOnly`; old-schema migration through
    `-ControlContractReinstallOnly`; interrupted handoff through
    `-ActivationTransactionOnly` and `-ActivationRetirementOnly`; holder-aware
    preservation through `-ActivationRetirementOnly`.
  - Reconfirm machine prerequisite, activation contract, transaction,
    retirement, explicit Reinstall, Supervisor Node behavior, and Package
    boundary/hash closure on the same committed snapshot.
  - Record exact command order, exit code, wall time, output disposition, batch
    budget, and the fixture-to-command coverage map in `RESULT.md`.
- Out of scope:
  - Any production, test, payload, configuration, workflow, or documentation
    change other than this task's `RESULT.md`.
  - Adding an aggregate runner or a new harness mode; running the no-switch
    full materializer harness; running `-RepairOnly`, `-McpAvailabilityOnly`,
    `-McpConfigOnly`, `-UpgradeOnly`, `-PayloadContractOnly`,
    `-PortabilityOnly`, `-TransactionOnly`, or other test suites.
  - Diagnosing or repairing a failure inside this task. A failure is evidence,
    not authorization to edit or rerun.
  - Unity, Unity MCP, EditMode, C# compilation, PlayMode, cold start, Domain
    Reload, real Codex Desktop injection, real project migration, consumer or
    third-party Package acceptance, full regression, release, publication, or
    deployment.
  - Starting, stopping, attaching to, signalling, or inspecting unrelated
    Unity, Codex, MCP, Editor, Coordinator, Provider, watcher, Supervisor, or
    business processes. Existing harness-owned disposable child fixtures may
    be created and cleaned only by the exact authorized test mode that owns
    them.
- Allowed files:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08-control-plane-code-freeze-l0/RESULT.md`
- Protected state:
  - All tracked production, test, payload, configuration, documentation, and
    workflow files are read-only for this evidence-only task.
  - Existing project/user/global configuration, Package generations, runtime
    state outside harness-owned disposable fixtures, leases, and unrelated
    working-tree files remain unchanged.
  - `UnityValidationProject/` remains the only default EditMode validation
    project, but its use is not authorized by this task.
- Snapshot binding:
  - Base and expected HEAD:
    `6408b0d540b32584147588efb67ecc5ba12b2fda`.
  - At dispatch, the only expected pre-existing task delta is this `TASK.md`.
    During execution, only this task's `RESULT.md` may be added or changed.
  - Do not reset, clean, stash, rebase, amend, or rewrite the snapshot.

## Execution

- Coder actions:
  - Read this task once. Do not reread all prior RESULT or VERIFICATION files;
    this task contains the complete command and coverage contract.
  - Perform one bounded admission check: exact HEAD plus scoped working-tree
    status. If HEAD differs or any production/test path is dirty, stop
    `BLOCKED` without running the batch.
  - Execute the following commands serially, in this exact order, as one L0
    batch. Stop immediately after the first non-zero exit, timeout, truncated
    output, unexpected process requirement, or fixture cleanup failure:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -PrerequisiteOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationContractOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationTransactionOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationRetirementOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ControlContractReinstallOnly
node com.rice.ai-codedb\Tests~\test-codedb-project-supervisor.mjs
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1
```

  - The entire serial batch has a cumulative wall-time limit of `300 seconds`.
    Do not start the next child command once the cumulative limit is reached.
  - Captured stdout plus stderr is limited to `64 KiB` per child command and
    `256 KiB` for the complete task. Mark `TRUNCATED` and stop if either limit
    is reached; do not replace the run with a broader or repeated capture.
  - Retry budget is `0`. Do not make a fixture correction, rerun a failed
    command, or invoke a semantically equivalent filter.
  - After the batch, perform one scoped status check sufficient to prove that
    no production/test path changed. Do not run a full diff or repeated Git
    inspection.
  - Write `RESULT.md` using repository-relative paths only. Include the
    pre/post HEAD, status disposition, per-command ledger, total wall time,
    output byte disposition, coverage map, actual model/profile, all deferred
    gates, and the completion-routing footer. Do not copy raw logs into the
    task record.
- Focused tests:
  - Authorized L0: exactly the one eight-command serial batch above.
  - L0 batch budget: `1/1`; child-command retry budget: `0/0`.
  - Verifier budget after Planner routing: one targeted read-only review that
    reuses Coder evidence and does not rerun any command.
  - Explicitly not run: the no-switch materializer suite, any omitted harness
    mode, C# compile, Unity/EditMode, Unity MCP, other L0/L1, real runtime or
    external acceptance, and repository-wide tests.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - HEAD or protected-path status does not match the frozen admission state.
  - A declared child command fails, times out, truncates output, requires an
    undeclared process, or leaves its disposable fixture unclean.
  - Cumulative batch wall time reaches `300 seconds`, per-command output reaches
    `64 KiB`, cumulative output reaches `256 KiB`, or the first context
    compaction occurs.
  - Correctness appears to require a source/test edit, new harness mode,
    changed command list, retry, broader regression, Unity, or Unity MCP.
- Escalation triggers:
  - Any of the four declared fixture categories is not actually exercised by
    its mapped command on the frozen source. Stop before testing and report the
    exact coverage gap instead of silently substituting a broad suite.
  - The eight commands cannot complete as one bounded batch without changing
    production/test code or exceeding the declared budgets.
  - A failure indicates a product defect or fixture defect. Return the exact
    first failure to Planner so a separate bounded FIX task can be frozen.
- Model escalation: none; this cross-layer P0 freeze gate remains assigned to
  the approved deep profile.

## Definition Of Done

- Expected result:
  - All eight child commands pass once, in order, within the single batch and
    declared time/output budgets on exact commit `6408b0d`.
  - Clean/fresh Install, old-schema explicit Reinstall, interrupted handoff,
    and holder-aware preservation each have an explicit command-backed entry
    in the coverage map.
  - No tracked production/test path changes and no unrelated process or state
    is touched.
- Required evidence:
  - Exact pre/post HEAD and scoped status disposition.
  - One per-command ledger with command, exit code, wall time, captured-output
    disposition, and concise result.
  - Aggregate batch count `1/1`, retry count `0/0`, cumulative wall time, and
    cumulative captured-output disposition.
  - Explicit `PASS`, `BLOCKED`, or `DEFERRED` outcome without extrapolating to
    Unity, C#, runtime, consumer, or release acceptance.
- Deferred risks:
  - C# compilation and focused EditMode in `UnityValidationProject/` require a
    separate task and explicit authorization after this non-Unity gate.
  - Fresh Unity cold-start/Play/Domain Reload, real Manager/Supervisor/fallback
    routing, real Codex task injection, third-party Package, full regression,
    release, publication, and deployment remain separate gates.

## Handoff

- Current task: cdb-v0.3-p0-s08-control-plane-code-freeze-l0
- Current status: READY
- Next notification: v0.3.coder.deep
- Next action: execute the exact evidence-only serial L0 batch and return
  `RESULT.md` to UnityCodeDB v0.3 Planner; do not contact Verifier directly.
- Human decision or authorization required: manual Coder dispatch; any command
  change, retry, FIX, Unity/EditMode run, commit, push, or Verifier routing
  requires a separate decision by Planner/user.

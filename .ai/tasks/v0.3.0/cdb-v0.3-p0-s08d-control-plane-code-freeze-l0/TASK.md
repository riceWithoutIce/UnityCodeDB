# Task: cdb-v0.3-p0-s08d-control-plane-code-freeze-l0

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
- Predecessor:
  `cdb-v0.3-p0-s08c-pending-install-retained-closure-variants`
  (`ACCEPT`, combined S08a/S08b/S08c snapshot)
- Supersedes only the incomplete evidence run in
  `cdb-v0.3-p0-s08-control-plane-code-freeze-l0`; the old result remains
  immutable historical evidence.
- Requirement source:
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08c-pending-install-retained-closure-variants/DECISION.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: produce one complete bounded non-Unity L0 code-freeze
  evidence set for the accepted combined S02-S08c control-plane snapshot,
  without changing production or test behavior.

## Scope

- In scope:
  - Bind all evidence to exact HEAD and the accepted two-file uncommitted patch
    identities declared below. A commit is not an execution prerequisite.
  - Run one serial L0 batch consisting only of the eight commands declared in
    this task, each invoked at most once and starting again from command `1/8`.
  - Reconfirm machine prerequisite, clean/fresh and pending Uninstall/Install,
    activation foundation, candidate transaction/recovery, lease-aware
    retirement, explicit obsolete-contract Reinstall, Supervisor behavior, and
    Package boundary/hash closure on one unchanged snapshot.
  - Record exact command order, exit, wall time, output disposition, aggregate
    budget, coverage map, and pre/post identity in `RESULT.md`.
- Out of scope:
  - Reusing the old S08 partial batch as current evidence or resuming it from
    command `3/8`.
  - Any production, test, payload, configuration, workflow, or documentation
    change other than this task's `RESULT.md`.
  - Diagnosing, repairing, or rerunning a failure inside this task. A failure is
    terminal evidence for a separately authorized task.
  - Adding a runner or harness mode; running the no-switch materializer harness,
    omitted modes, C# compilation, Unity, Unity MCP, EditMode, PlayMode, cold
    start, Domain Reload, real Codex injection, consumer/third-party Package,
    repository-wide regression, release, publication, or deployment.
  - Starting, stopping, attaching to, signalling, or inspecting unrelated
    Unity, Codex, MCP, Editor, Coordinator, Provider, watcher, Supervisor, or
    business processes. The exact harness commands may own and clean only their
    disposable fixtures.
- Allowed files:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08d-control-plane-code-freeze-l0/RESULT.md`
- Protected state:
  - All production, test, payload, configuration, documentation, workflow, and
    prior task files are read only.
  - Existing project/user/global configuration, Package generations, runtime
    state outside harness-owned disposable fixtures, leases, and unrelated
    working-tree files remain unchanged.
  - `UnityValidationProject/` is the only default EditMode project, but this task
    does not authorize opening or using it.
- Snapshot binding:
  - Expected HEAD:
    `6408b0d540b32584147588efb67ecc5ba12b2fda`.
  - Expected two-file patch identity:
    `aae922016172611d6742e7d878cf1d9e6378c617`.
  - Expected per-file identities:
    - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`:
      `fbad2e20bf6059912a930d0db61ae54cfc154ad6`;
    - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`:
      `5af62c199883b33458b0b776e922b7cdaca202c5`.
  - Expected Package status contains exactly those two modified files and no
    other Package path. The protected
    `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` is clean.
  - Expected untracked task inputs are the existing S08, S08a, S08b, and S08c
    records plus this S08d `TASK.md`; this task may add only its own `RESULT.md`.
  - Do not reset, clean, stash, rebase, amend, commit, or rewrite the snapshot.

## Execution

- Coder actions:
  - Read this task once. Do not reread complete prior result histories; the
    accepted S08c decision and this task contain the current contract.
  - Perform one bounded admission capture for exact HEAD, the combined/per-file
    patch identities, exact two-file Package status, clean protected
    materializer, and expected task records. Any drift stops the task before
    testing.
  - Execute these commands serially in this exact order as one new L0 batch:

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

  - Stop immediately after the first non-zero exit, timeout, truncated output,
    unexpected process requirement, or fixture cleanup failure. Do not inspect
    the failure beyond the complete output naturally returned by that command.
  - Per-command wall-time limit: `180 seconds`.
  - Complete serial-batch wall-time limit: `420 seconds`. Do not start the next
    child after the aggregate limit is reached.
  - Output limit: `64 KiB` per child and `256 KiB` aggregate. Mark `TRUNCATED`
    and stop when either limit is reached; do not recapture through another run.
  - Batch budget: `1/1`; retry budget: `0/0`. No corrected retry, equivalent
    filter, or partial continuation is authorized.
  - After all eight commands pass, perform one final scoped capture for HEAD,
    combined/per-file patch identities, exact two-file Package status, protected
    materializer cleanliness, and task records. Do not run a full diff.
  - Write `RESULT.md` with the admission/final identities, per-command ledger,
    aggregate wall/output/batch/retry counts, coverage map, actual profile,
    deferred gates, and completion footer. Use repository-relative paths; do
    not copy raw logs.
- Focused tests:
  - Authorized L0: exactly the one eight-command serial batch above.
  - Verifier budget after Planner routing: one targeted read-only review that
    reuses the Coder evidence and runs no command.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - Frozen identity or protected status differs at admission.
  - A child fails, times out, truncates output, requires an undeclared process,
    or leaves its owned fixture unclean.
  - A source/test edit, retry, replacement filter, broader regression, Unity,
    or Unity MCP appears necessary.
  - Per-command `180s`, aggregate `420s`, per-command `64 KiB`, aggregate
    `256 KiB`, or the first context-compaction boundary is reached.

## Coverage Map

| Command | Frozen coverage |
| --- | --- |
| `-PrerequisiteOnly` | Machine prerequisite and fail-closed prerequisite variants |
| `-UninstallOnly` | Clean/fresh Install, logical Uninstall, pending handoff, cleanup serialization |
| `-ActivationContractOnly` | Versioned activation namespace and contract semantics |
| `-ActivationTransactionOnly` | Candidate-before-selection, rollback, recovery, retry/conflict |
| `-ActivationRetirementOnly` | Intent-bound holder-aware retirement and interrupted binding recovery |
| `-ControlContractReinstallOnly` | Explicit obsolete-contract one-action Reinstall |
| Supervisor Node harness | Runtime routing, operation ownership, reconnect, shutdown boundaries |
| Package boundary harness | Payload, hash closure, generated/package boundary |

## Definition Of Done

- All eight child commands pass once in order against the exact accepted
  snapshot within the declared time and output budgets.
- The pre/post HEAD, identities, Package two-file status, and protected
  materializer state match exactly; production/test behavior remains unchanged.
- `RESULT.md` reports `PASS`, `BLOCKED`, or `DEFERRED` without extrapolating to
  C#, Unity, runtime, consumer, or release acceptance.
- Any failure stops this task and returns to Planner for a separate decision.

## Deferred Boundaries

- C# compilation and focused EditMode in `UnityValidationProject/` require a
  separate task and explicit authorization after this non-Unity gate.
- Fresh Unity cold-start/Play/Domain Reload, real Manager/Supervisor/fallback,
  real Codex task injection, consumer/third-party Package, full regression,
  release, publication, and deployment remain separate gates.

## Handoff

- Current task: cdb-v0.3-p0-s08d-control-plane-code-freeze-l0
- Current status: READY
- Next notification: v0.3.coder.deep
- Next action: run the exact evidence-only eight-command L0 batch and return
  `RESULT.md` to UnityCodeDB v0.3 Planner; do not contact Verifier directly.
- Human decision or authorization required: manual Coder dispatch; any command
  change, retry, FIX, Unity/EditMode run, commit, push, or Verifier routing
  requires a separate Planner/user decision.

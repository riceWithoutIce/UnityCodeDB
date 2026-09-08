# Task: cdb-v0.3-p0-s08b-pending-uninstall-install-handoff

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
- Predecessor: `cdb-v0.3-p0-s08a-fresh-install-selection-recovery`
  (`BLOCKED` after FIX 01 target closure)
- Requirement source:
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08a-fresh-install-selection-recovery/TASK.md`;
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08a-fresh-install-selection-recovery/RESULT.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: allow one explicit confirmed `Install` that begins from an
  authenticated `UNINSTALLED + PENDING` state to activate a new verified
  instance without stopping or corrupting the retained old closure, while an
  automatic cleanup bound to the old state-id becomes obsolete after the
  atomic Install commit.

## Scope

- In scope:
  - Preserve the current uncommitted S08a repair and use its FIX 01 terminal
    failure as the reproduction. Do not rerun before investigation or repair.
  - Trace only the `Install-boundary pending Uninstall` scenario, the
    candidate-to-activation handshake, `Invoke-InstanceConvergence`, exact
    COMMITTED activation recovery, uninstall cleanup/state-id ownership, and
    the existing retirement evidence directly needed by this transition.
  - Admit the special transition only for explicit `Install` with an exact,
    authenticated, non-legacy `UNINSTALLED + PENDING` desired-state document
    and pinned state-id. Missing, invalid, legacy, changed-id, or installed
    state remains fail-closed.
  - Candidate verification must finish before current selection or desired
    state changes. Until activation commits, the project remains visibly
    `UNINSTALLED` and an old automatic cleanup remains serialized behind the
    same operation lock.
  - A successful Install must publish its own valid activation/operation
    authority, select a new immutable instance, atomically transition desired
    state to `INSTALLED`, and make cleanup work captured under the old state-id
    exit as obsolete without deleting the new selection or MCP state.
  - Retained old instance/generation/lease/holder evidence must remain valid
    and byte-preserved while owned. No holder or unrelated process may be
    stopped. Cleanup may occur only through an existing authenticated
    authority after holders drain.
  - Preserve S08a behavior already observed as passing: completed-Uninstall
    fresh Install, ordinary installed missing-selection refusal, namespace
    preservation, and waiting Install after automatic cleanup reaches the same
    state-id `COMPLETE`.
- Out of scope:
  - A new schema, journal kind, state authority, public command, Supervisor
    protocol, selection format, retirement format, or Package payload change.
  - Treating arbitrary `PENDING`, missing selection, orphan/mismatched
    activation evidence, or unauthenticated retained files as install
    authority.
  - Blindly deleting the old COMMITTED contract or retained closure; reusing
    the retired instance identity; changing the existing pause assertion to
    hide an early failure; or weakening candidate-before-selection.
  - Unrelated Install, Uninstall, Upgrade, Reinstall, Repair, lifecycle,
    Manager, Supervisor, Provider, query, or release behavior.
  - Continuing S08, running another S08 child, Unity, Unity MCP, EditMode, C#
    compilation, full/no-switch harness, real external acceptance, commit,
    push, publication, or deployment.
- Allowed files:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08b-pending-uninstall-install-handoff/RESULT.md`
- Protected state:
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`, all C#,
    Node/Supervisor, wrapper, payload, manifest, workflow, and prior task files
    are read only.
  - Existing project/user/global configuration, runtime state outside
    harness-owned disposable fixtures, Package generations, and unrelated
    working-tree files remain unchanged.
  - `UnityValidationProject/` remains the only default EditMode project, but
    this task does not authorize opening or using it.
- Snapshot binding:
  - Base and expected HEAD:
    `6408b0d540b32584147588efb67ecc5ba12b2fda`.
  - Required starting two-file patch identity:
    `f2acaaec73b20294d27f37a6258cfdd6f8902b87`.
  - Required starting per-file diff identities:
    - `codedb-instance-engine.ps1`:
      `0299b322acb696f44a1d4c5d34916990c07cb670`;
    - `test-codedb-host-payload-materializer.ps1`:
      `192d70b93c660e079b89fe200aceac3444629c40`.
  - `materialize-codedb-host-payload.ps1` was clean at freeze.
  - Expected untracked inputs are the S08 and S08a `TASK.md`/`RESULT.md` files
    plus this S08b `TASK.md`; this task may add only its own `RESULT.md`.
  - Use `git status --short --untracked-files=all` for task records. Return raw
    tool results without JavaScript encoding or byte-count wrappers.
  - Do not reset, clean, stash, rebase, amend, or rewrite the snapshot.

## Execution

- Coder actions:
  - Read this task once, the S08a FIX 01 terminal evidence only, and the direct
    source/test functions named above. Do not dump prior task histories or scan
    the repository.
  - Perform one bounded admission capture for exact HEAD, exact starting patch
    identities, clean protected materializer, and expected expanded task files.
    Identity drift stops the task before any edit.
  - First determine whether the accepted activation/retirement/uninstall
    authorities can represent this handoff without a new schema or second
    policy owner. Record the concrete authority path in `RESULT.md`. If they
    cannot, stop `BLOCKED` before implementation.
  - Make the smallest correction in the instance engine. The direct harness
    may change only to add an adjacent assertion for the agreed holder/closure
    preservation; retain the existing candidate pause and obsolete-cleanup
    scenario unchanged.
  - Do not authorize mutation merely from the pre-lock `PENDING` read. Recheck
    the pinned desired-state identity and all required committed/retained
    evidence while holding the operation lock immediately before any
    supersession or activation step.
  - Run one AST parse covering only the changed engine and harness files.
  - Run exactly one focused functional check after the repair:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

  - On success, run one scoped `git diff --check` over the two allowed code/test
    files and capture final HEAD, two-file patch identity, per-file identities,
    and scoped status. Do not run a full diff.
  - Append `RESULT.md` with root cause, authority decision, exact changes,
    command ledger, time/output/batch/retry counts, final identity, deferred
    boundaries, and completion footer. Use repository-relative paths only; do
    not copy raw logs.
- Focused tests:
  - Preserved reproduction: S08a FIX 01 reached all earlier target regressions
    and then failed because Install never reached the existing
    candidate-verification pause. Do not reproduce before editing.
  - New L0 batch: exactly one `-UninstallOnly` invocation after the repair,
    maximum `180 seconds`, captured output below `64 KiB`.
  - Retry budget: `0/0`. A failed or incomplete run stops the task.
  - Static allowance: one two-file AST parse and, only after functional pass,
    one two-file scoped `git diff --check`.
  - Explicitly not run: any other materializer mode, S08 continuation,
    no-switch/full harness, other L0/L1, C# compile, Unity/EditMode, Unity MCP,
    real runtime or process acceptance, consumer/third-party Package, and
    repository-wide tests.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - The existing authority cannot safely represent pending old closure plus a
    new selected instance without a schema/protocol/state-owner change.
  - Correctness requires editing a protected file, stopping a holder, deleting
    unauthenticated or still-owned evidence, accepting changed state-id, or
    weakening ordinary missing-selection/COMMITTED validation.
  - Candidate or desired-state publication occurs before verification, an old
    cleanup can delete new state, or the new Install loses the retained old
    closure without authenticated cleanup authority.
  - More than one independent behavior appears; AST/test/diff-check fails;
    output truncates; test time reaches `180 seconds`; an undeclared process is
    required; or the first context compaction occurs.
  - Unity or Unity MCP becomes necessary. Record `DEFERRED`/`BLOCKED` and notify
    the human rather than opening or connecting it.
- Escalation triggers:
  - Live-holder preservation cannot be maintained while allowing one-action
    Install under the accepted contract.
  - The only apparent fix is to wait for cleanup and require another human
    Install action, or to make old cleanup and new activation concurrent
    owners.
  - A new retirement authority or schema field is needed to bind the retained
    old closure after logical Uninstall removed current selection.
- Model escalation: none; this cross-state P0 authority task remains on the
  approved deep profile.

## Definition Of Done

- Expected result:
  - Exact explicit Install from authenticated `UNINSTALLED + PENDING` reaches
    the candidate pause before activation, changes neither selection nor
    desired state before verification, then atomically selects a new instance
    and transitions to `INSTALLED`.
  - Cleanup captured under the old state-id waits for the operation lock and
    exits obsolete after Install, without deleting the new instance,
    generation, MCP state, retained owned closure, or unrelated bytes.
  - Existing complete-cleanup Install, waiting-behind-cleanup Install, ordinary
    missing-selection refusal, rollback/retirement authority, and holder safety
    remain intact.
- Required evidence:
  - Concrete root cause and proof that the existing authority is sufficient.
  - Exact starting and final HEAD, two-file and per-file patch identities, and
    changed-file list.
  - One AST parse, one `-UninstallOnly` result with exit/wall/output details,
    and one scoped `git diff --check` result.
  - Batch `1/1`, retry `0/0`, explicit deferred boundaries, and no claim for
    unexecuted S08, Unity, consumer, or release gates.
- Deferred risks:
  - S08 remains blocked and must later restart its complete code-freeze batch
    on an accepted stable snapshot.
  - C# compile, focused EditMode in `UnityValidationProject/`, Unity runtime,
    real Manager/Supervisor/Install, consumers, and release acceptance remain
    separate gates.

## Handoff

- Current task: cdb-v0.3-p0-s08b-pending-uninstall-install-handoff
- Current status: READY
- Next notification: v0.3.coder.deep
- Next action: implement and validate only the pending-Uninstall explicit
  Install handoff, then return `RESULT.md` to UnityCodeDB v0.3 Planner; do not
  contact Verifier directly.
- Human decision or authorization required: manual Coder dispatch; any scope
  expansion, retry, extra test, Unity/EditMode run, commit, push, or Verifier
  routing requires a separate Planner/user decision.

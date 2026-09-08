# Task: cdb-v0.3-p0-s08c-pending-install-retained-closure-variants

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
- Predecessor: `cdb-v0.3-p0-s08b-pending-uninstall-install-handoff`
  (`DIAGNOSTIC-01` complete; implementation remains `BLOCKED`)
- Requirement source:
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08b-pending-uninstall-install-handoff/TASK.md`;
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08b-pending-uninstall-install-handoff/RESULT.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: allow one explicit `Install` from an exact authenticated
  `UNINSTALLED + PENDING` state when the prior selected instance has already
  been safely removed but another authenticated closure, such as its generation
  lease, legitimately keeps cleanup pending. Preserve the existing strict path
  when the prior instance itself is still present.

## Confirmed Root Cause

- S08b `DIAGNOSTIC-01` proved that the Install child exits in `PREFLIGHT` with
  exit `6`, `INSTANCE_CONVERGENCE_FAILED`, and
  `Retired instance root is not a directory.` before the candidate-ready event.
- `Get-InstanceCleanupState` may safely remove a holder-free instance before
  `Get-InstanceUninstallCleanupState` returns `PENDING` for a separately held
  generation or legacy closure. Therefore aggregate `PENDING` does not prove
  that the committed activation candidate's instance directory still exists.
- The S08b handoff branch currently treats that directory as unconditionally
  present and calls `Get-ValidatedRetiredInstance`. The event timeout was only
  a downstream symptom; this task must not weaken or remove the pause assertion.

## Scope

- In scope:
  - Preserve the current uncommitted S08a + S08b snapshot and use the recorded
    S08b diagnostic as the reproduction. Do not rerun before the repair.
  - Read only the direct handoff path in
    `Invoke-InstanceActivationContractRecovery`, `Invoke-InstanceConvergence`,
    `Publish-InstanceActivationTransaction`, `Get-InstanceCleanupState`,
    `Get-InstanceUninstallCleanupState`, and the adjacent
    `Invoke-UninstallAcceptanceScenarios` fixture.
  - Distinguish exactly two authenticated pending-Uninstall variants while the
    operation lock is held:
    1. the prior instance directory exists and must pass the existing complete
       `Get-ValidatedRetiredInstance` and committed-candidate identity checks;
    2. the prior instance path is genuinely absent, current and last-known-good
       selections are absent, and the exact committed contract plus pinned
       desired-state id prove the completed logical Uninstall transition.
  - Recheck the admitted variant, exact state id, desired state, committed
    contract identity, and selection absence immediately before superseding the
    old contract and publishing the new activation.
  - For an absent prior instance, publish no retirement intent or retired marker
    for that nonexistent instance. Preserve remaining generation/legacy lease
    evidence and its owner process byte-for-byte.
  - Preserve S08b's candidate-before-selection boundary and make cleanup work
    captured under the old state id exit obsolete only after the new atomic
    Install commit.
  - Add only adjacent assertions proving the fixture intentionally has an absent
    prior instance but a retained generation lease, reaches candidate pause,
    preserves that lease/owner and generation, selects a new instance, and does
    not mint unbound retirement authority.
- Out of scope:
  - A schema, journal kind, retirement authority, desired-state field, public
    command, Supervisor protocol, Package payload, or lifecycle change.
  - Treating `PENDING` alone as authority; accepting a file, reparse point,
    invalid directory, incomplete closure, mismatched candidate, changed state
    id, legacy document, or installed missing-selection state.
  - Recreating the deleted old instance, stopping a holder, deleting a live
    generation, weakening `Get-ValidatedRetiredInstance`, or hiding the failure
    in the harness.
  - Unrelated Install, Uninstall, Upgrade, Reinstall, Repair, Manager,
    Supervisor, Provider, query, release, or S08 command behavior.
  - Resuming the S08 eight-command batch, Unity, Unity MCP, EditMode, C# compile,
    full/no-switch harness, real external acceptance, commit, push, publication,
    or deployment.
- Allowed files:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08c-pending-install-retained-closure-variants/RESULT.md`
- Protected state:
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`, all C#,
    Node/Supervisor, wrapper, payload, manifest, workflow, and prior task files
    are read only.
  - Project/user/global configuration, runtime state outside harness-owned
    disposable fixtures, Package generations, and unrelated working-tree files
    remain unchanged.
  - `UnityValidationProject/` is the only default EditMode project, but this task
    does not authorize opening or using it.
- Snapshot binding:
  - Base and expected HEAD:
    `6408b0d540b32584147588efb67ecc5ba12b2fda`.
  - Required starting two-file patch identity:
    `d74922996e4a84920004acefe4c4db23e27d5dcf`.
  - Required starting per-file diff identities:
    - `codedb-instance-engine.ps1`:
      `1a66fd1d7075bb25f32dd956f5938415066d2a79`;
    - `test-codedb-host-payload-materializer.ps1`:
      `a576d7ee806b46aaa5dbdc20548411bf887b8249`.
  - `materialize-codedb-host-payload.ps1` is clean at freeze.
  - Expected untracked inputs are the S08, S08a, and S08b `TASK.md`/`RESULT.md`
    files plus this S08c `TASK.md`; this task may add only its own `RESULT.md`.
  - Do not reset, clean, stash, rebase, amend, or rewrite the snapshot.

## Execution

- Coder actions:
  - Read this task once, S08b `DIAGNOSTIC-01`, and only the direct source/test
    functions named above. Do not dump prior histories or scan the repository.
  - Perform one bounded admission capture for exact HEAD, starting identities,
    clean protected materializer, and expected scoped status. Identity drift
    stops the task before editing.
  - Record the exact authority decision before the repair. If the existing
    committed contract and desired-state authority cannot safely distinguish
    present and absent prior-instance variants, stop `BLOCKED`; do not invent a
    second authority.
  - Make the smallest engine correction and adjacent harness assertions. Keep
    the S08b child diagnostic available unless its removal is strictly required
    by the corrected success path.
  - Run one AST parse covering only the changed engine and harness files.
  - Run exactly one focused functional check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

  - Maximum wall time: `180 seconds`; output limit: `64 KiB`; retry: `0/0`.
    The first independent failure stops the task.
  - After the run, perform one two-file scoped `git diff --check` and one final
    HEAD, two-file/per-file patch identity, and scoped-status capture.
  - Append `RESULT.md` with authority decision, exact change, command ledger,
    wall time/output/batch/retry counts, final identities, deferred boundaries,
    and completion routing. Use repository-relative paths and do not copy raw
    logs.
- Explicitly not run:
  - Other materializer modes; S08 commands `1` or `3-8`; no-switch/full harness;
    other L0/L1; C# compile; Unity/EditMode; Unity MCP; real runtime/process,
    consumer, third-party Package, release, or repository-wide validation.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - A schema/protocol/new-authority change or protected-file edit is required.
  - The absent path cannot be distinguished from invalid, inaccessible, or
    ambiguous evidence without weakening fail-closed behavior.
  - Candidate or desired state changes before verification; old cleanup can
    delete the new selection; a live holder/lease/generation changes; or an
    unbound retirement authority is created.
  - More than one independent behavior appears; AST/test/diff-check fails;
    output truncates; the test reaches `180 seconds`; or Unity/Unity MCP becomes
    necessary.

## Definition Of Done

- Exact explicit Install from authenticated `UNINSTALLED + PENDING` reaches the
  existing candidate pause when the prior instance is legitimately absent and
  another closure keeps cleanup pending.
- Before the pause, selection and desired state remain unchanged. After release,
  one verified new instance is atomically selected, desired state becomes
  `INSTALLED`, and cleanup captured under the old state id exits obsolete.
- The retained generation, lease, external owner, MCP/user configuration, and
  unrelated bytes remain unchanged; no authority is minted for the absent old
  instance.
- Present valid prior instances retain strict validation and retirement binding;
  invalid/non-directory/mismatched evidence and ordinary installed
  missing-selection states remain fail-closed.
- One AST parse, one `-UninstallOnly`, one scoped diff check, exact final
  identities, and explicit deferred boundaries are recorded without claiming
  that S08 or Unity gates passed.

## Handoff

- Current task: cdb-v0.3-p0-s08c-pending-install-retained-closure-variants
- Current status: READY
- Next notification: v0.3.coder.deep
- Next action: implement and validate only the exact absent-versus-present
  pending-Uninstall Install handoff, then return `RESULT.md` to
  UnityCodeDB v0.3 Planner; do not contact Verifier directly.
- Human decision or authorization required: any scope expansion, retry, extra
  test, Unity/EditMode run, commit, push, or Verifier routing requires a separate
  Planner/user decision.

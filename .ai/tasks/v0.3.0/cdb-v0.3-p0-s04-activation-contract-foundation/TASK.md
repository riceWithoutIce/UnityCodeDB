# Task: cdb-v0.3-p0-s04-activation-contract-foundation

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
- Predecessor: `cdb-v0.3-p0-s03a-prerequisite-admission-probe`
  (`ACCEPT`, commit `0c2178e113df2cb43a8936d3fcdb7ca5f6674c35`)
- Requirement source:
  `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`
  (delivery order 3); `com.rice.ai-codedb/Documentation~/development-workflow.md`

## Objective

- Single outcome: establish the Package-derived, versioned activation record,
  operation journal, activation epoch, and safe fresh-namespace provisioning on
  the existing instance engine. Do not activate a candidate or wire Reinstall
  and runtime consumers in this slice.

## Scope

- In scope:
  - Reuse `codedb-instance-engine.ps1`; do not create another transaction or
    activation engine.
  - Make PowerShell strictly parse the existing manifest `control_contract`
    with the same canonical UTF-8 identity, SHA-256, id/version constraints,
    and schema version already used by C# and Node.js.
  - Define `runtime_contract_sha256` as the lowercase SHA-256 of the trusted raw
    `Payload~/payload-manifest.json` bytes.
  - Derive and freeze these paths from that trusted contract:
    - `control/contracts/<id>/v<version>/activation.json`
    - `control/contracts/<id>/v<version>/operation.json`
    - `control/contracts/<id>/v<version>/operations/<operation-id>/`
    - existing `control/contracts/<id>/v<version>/supervisor/`
  - The durable activation record binds the control contract, runtime hash,
    project identity, activation epoch, operation id, candidate/current/LKG
    instance and generation identities, manifest hashes/dispositions,
    publication phase, and timestamp.
  - The operation journal binds the same contract/project/runtime/epoch and
    operation identity plus action, candidate, previous activation-record hash,
    phase, timestamp, and ordered mutation/pre-image evidence.
  - `activation_epoch` and `operation_id` are distinct lowercase 32-hex values.
    One attempt keeps one immutable pair; a retry creates a new pair.
  - Journal phases are `PREPARED`, `ACTIVATING`, and `COMMITTED`. `READY` is
    reserved for later Supervisor publication and is not emitted here.
  - Provision only the derived contract directory and exact operation directory
    after project-local/no-reparse validation. An identical repeat is
    idempotent; malformed or conflicting existing evidence fails closed.
  - Strictly validate field allowlists, size, file type, containment, reparse,
    identity consistency, and hashes for both documents.
  - Keep materializer `txn-v1-*` separate. Keep unversioned
    `current-instance.json`, `last-known-good-instance.json`, and current
    instance behavior unchanged as read-only migration inputs.
- Out of scope:
  - Candidate probes, selection switching, activation mutation, rollback,
    retirement, cleanup, process stopping, or legacy-record migration.
  - Reinstall, Bridge, Lifecycle, Manager, wrapper, Supervisor, Coordinator,
    Provider, MCP, query, or user-visible behavior changes.
  - Changing `payload-manifest.json`, its control identity, immutable payloads,
    or generated closure hashes.
  - Unity, Unity MCP, EditMode, real probes/migration, commit, push, or release.
- Allowed files:
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`, only if a
    cross-language/source-boundary assertion is necessary
  - this task's `RESULT.md`
- Protected state:
  - Manifest/payload files, C#/Node code, runtime state, leases, project/user
    configuration, and external processes remain unchanged.
  - The Package manifest remains the sole version-policy authority; do not add
    a PowerShell current/previous contract table or hard-coded `poc.*` policy.
- Snapshot binding:
  - Clean base: `0c2178e113df2cb43a8936d3fcdb7ca5f6674c35`.
  - This `TASK.md` is the only expected pre-existing uncommitted path.

## Execution

- Coder actions:
  - Read this task once; inspect the allowed files and only the direct C#/Node
    identity/path helpers needed for parity.
  - Reuse existing strict JSON, durable atomic-write, path, reparse, hash, and
    transaction-entry helpers.
  - Keep the new foundation disconnected from existing production command
    routing; no Install/Upgrade/Reinstall path may activate through it yet.
  - Add one `-ActivationContractOnly` focused harness mode.
  - Write `RESULT.md` with exact changes, evidence, deferred gates, actual
    profile/effort, budget ledger, and handoff. Do not commit or push.
- Focused tests:
  - Run `test-codedb-host-payload-materializer.ps1 -ActivationContractOnly` at
    most once after edits are complete.
  - Run `test-codedb-package-boundary.ps1` at most once only if it was modified.
  - Do not run the full materializer suite, unchanged groups, Supervisor Node,
    C#, repository-wide, Unity/EditMode, Unity MCP, or real process tests.
  - One corrected retry after a concrete correction is the hard maximum.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - A manifest/control-identity change, consumer change, process launch, legacy
    mutation/deletion, file-scope expansion, or workflow limit is required.
- Escalation triggers:
  - Safe namespace provisioning cannot be separated from candidate activation.
  - Existing helpers force legacy mutation, or recovery disposition cannot be
    unambiguous without implementing the later atomic-activation slice.
- Model escalation: none

## Definition Of Done

- Expected result:
  - PowerShell accepts only the same trusted control-contract identity as C#
    and Node.js and derives the frozen paths.
  - A fresh namespace/operation directory can be prepared without changing
    selections, consumers, configuration, leases, or processes.
  - Valid records round-trip; unknown, malformed, oversized, redirected,
    mismatched, drifted, or conflicting evidence fails closed.
  - Legacy instance and materializer journal behavior remains unchanged and is
    never mistaken for the new activation authority.
- Required evidence:
  - Focused fixtures cover identity/hash/path parity, provisioning and repeat,
    strict fields, mismatches, path/reparse rejection, and legacy separation.
  - Record exact commands, batch/retry counts, output/time budget, and unrun
    evidence classes without broader claims.
- Deferred risks:
  - Candidate verification, atomic activation/crash recovery, rollback,
    retirement, consumer routing, and one-action Reinstall remain later work.
  - C# compilation, Unity/EditMode, real Unity/Codex, consumer Package, and
    release acceptance remain `DEFERRED`.

## Handoff

- Current task: cdb-v0.3-p0-s04-activation-contract-foundation
- Current status: READY
- Next notification: v0.3.coder.deep (manual)
- Next action: human-notify the existing deep Coder to execute this frozen task
  from base `0c2178e`; it writes `RESULT.md` and leaves changes uncommitted.
- Human decision or authorization required: manual dispatch; any scope/test
  expansion, Unity/EditMode, real probe, commit, push, or release action.

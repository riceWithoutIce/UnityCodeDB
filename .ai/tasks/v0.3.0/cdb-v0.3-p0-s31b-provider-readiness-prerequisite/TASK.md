# Task: cdb-v0.3-p0-s31b-provider-readiness-prerequisite

## Metadata

- Product/version: UnityCodeDB v0.3.
- Workflow: codedb-workflow-v2, revision 2.6.
- Status: ENVIRONMENT_INCOMPLETE / BLOCKED — SOURCE_REQUIRED
- Planner: current parent
- Coder: not assigned
- Verifier: optional, read-only after a stable evidence snapshot
- Review mode: GUARDED when a complete child-local closure is available
- Execution mode: DURABLE_SESSION
- Delegation authorization: NOT_AUTHORIZED
- Session policy: MANUAL_PROVISION
- Requirement source: User-approved independent Provider readiness prerequisite
  after S31-B R4 stopped at coordinator readiness timeout.
- Predecessor: S31-B remains `PARTIAL / BLOCKED — NOT ACCEPTED`.

## Objective

Produce one attributable Provider readiness disposition for the S31-B
production-equivalent route:

1. identify the authoritative source and owner of the Provider's local model
   asset;
2. bind its source, version, provenance and hash without inventing or silently
   downloading an input;
3. if separately authorized, stage the exact asset into a repository-local
   child-local closure; and
4. run at most one bounded `initialize` / `tools/list` readiness check.

The acceptable terminal result is either a complete, hashed readiness closure
or an explicit `ENVIRONMENT_INCOMPLETE` disposition naming the missing owner or
asset. This task does not prove S31-B uninstall behavior by itself.

## Scope

- In scope: Provider binary/protocol inspection; model/runtime asset source and
  ownership; package installer and runtime preparation responsibilities; exact
  source/destination/hash records; child-local closure design; one bounded
  readiness observation after the closure is complete.
- Out of scope: product source changes; uninstall transaction changes; fallback
  branches; machine installation; network acquisition; Unity/MCP/BatchMode;
  real Install/Uninstall; commit, package export or reference switching.
- Change allowlist: this task directory's planning/evidence records only until
  a later execution grant explicitly authorizes child-local staging.
- Read-only dependency closure: S31-B `TASK.md`, `RESULT.md`, `VERIFICATION.md`
  and R4 manifest/evidence; Provider installation contract; isolation spec;
  generation runtime template/common scripts/coordinator; installer contract.
- Protected state: main dirty source tree, S31-B R2/R3/R4 evidence, machine
  Provider files, accepted package generations, validation projects and all
  external processes.
- Durable roots: `<repository-root>/.worktrees/<task-id>/`,
  `<repository-root>/.artifacts/tests/<run-id>/`, and this task directory only.
  No system-temp or user-level worktree is a durable destination.

## Evidence baseline

- R4 owner: `.artifacts/tests/s31b-r4/`.
- R4 result: authentic production prepare/config/watch route reached
  `INSTANCE_CANDIDATE_FAILED / exit 6` after the 120-second coordinator
  readiness timeout; no selected `INSTALLED` authority was published.
- Child-local Provider copy: exactly the reviewed executable, manifest and
  notices. No `models/potion-code-16M` directory exists in the child-local
  fixture.
- Known machine Provider stores contain the same three installation files and
  no model directory. This is an observation, not permission to alter them.
- Runtime config references the model at the project-local path
  `AIWork/.runtime/codedb/<instance>/models/potion-code-16M`.
- Runtime preparation creates config/index/log/temp roots and renders the
  config; no current production script supplies the model asset.
- Static Provider inspection exposes local Model2Vec model-loading and missing
  model-path failure strings. Because Provider stderr was not preserved as a
  causal error in R4, the model hypothesis remains `SUPPORTED_CANDIDATE`, not
  proven root cause.

## Execution envelope

### Stage A — read-only ownership and protocol review

- Inspect the pinned Provider manifest, binary metadata/strings, runtime config,
  installer allowlist, and preparation scripts.
- Determine whether the model is machine-scoped, project-scoped, downloaded on
  first use, or an omitted production prerequisite.
- Do not launch the Provider or contact the network.

### Stage B — source and hash closure

- Locate only an already authorized local source; record relative symbolic
  source, destination, version, license/provenance and SHA-256.
- If no authorized source exists, stop with `ENVIRONMENT_INCOMPLETE`.
- Do not fabricate a model, hand-write authority, or copy from an unknown
  cache.

### Stage C — optional child-local staging

- Requires a separate explicit user grant naming the source and destination.
- Copy exact bytes only under the repository-local task evidence root; preserve
  source and destination hashes and a frozen manifest.
- No machine installation, project runtime mutation, or product-code change.

### Stage D — one bounded readiness observation

- Requires Stage C completion and a separate execution grant.
- Use the original production coordinator/provider command shape and the exact
  child-local config.
- Observe `initialize`, `tools/list`, provider stderr and exit identity once.
- Stop on first failure; no retry under an unchanged closure.

## Stop conditions

- model/runtime asset source, ownership or hash is unknown;
- a proposed step needs network acquisition, machine installation, fallback,
  hidden compatibility or a new authority;
- a process cannot be attributed to the task root and owner identity;
- readiness fails before a complete closure exists;
- the next action would modify product code or reopen S31-B's uninstall scope.

## Definition of Done

- Required evidence: frozen input manifest; source/destination/hash records (or
  an explicit missing-source record); exact config/model path check; one
  readiness result if Stage D was authorized; preserved failure logs.
- Success: `PROVIDER_READY` with `initialize` and required `tools/list` proven
  under a complete child-local closure.
- Non-success: `ENVIRONMENT_INCOMPLETE` or `BLOCKED` with the precise missing
  prerequisite and no product-failure claim.
- Deferred risks: real machine availability, real Unity behavior, S31-B native
  stop/uninstall, release and human acceptance remain separate gates.

## Handoff

- Current task: Provider readiness prerequisite for S31-B.
- Current status: ENVIRONMENT_INCOMPLETE / BLOCKED — SOURCE_REQUIRED.
- Next notification: current parent Planner/User.
- Next action: provide an authorized model source, or defer this task.
- Human decision required before Stage C/D: explicit source/destination and
  child-local staging/readiness envelope.

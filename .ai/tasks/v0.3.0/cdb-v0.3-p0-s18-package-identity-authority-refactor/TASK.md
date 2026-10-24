# Task: cdb-v0.3-p0-s18-package-identity-authority-refactor

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Workflow: codedb-workflow-v2
- Workflow revision: 2.2
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep
- Review mode: RELEASE
- Execution mode: DURABLE_SESSION
- Execution profile: v0.3.coder.deep
- Delegation authorization: STANDING_WORKFLOW
- Session policy: REUSE_ONLY
- Requirement source: S18 external consumer blocker and Workflow v2 Identity Authority Gate

## Objective

Create one authoritative, cross-language Package identity contract route and a
successor-generation release path so that package version, payload sequence,
generation id, pointer, generation manifest, and instance validation cannot
drift independently. The independently acceptable outcome is a
commit-derived successor Package whose real external Configure Dependencies
path reaches the declared terminal state without the observed identity
mismatch.

## Scope

- In scope:
  - Canonical generation identity contract and read-only PowerShell/Node
    loaders.
  - Generation materialization and successor-generation production for the
    failed `poc.38` snapshot.
  - Package/payload/current-pointer/generation/instance identity closure.
  - Package-boundary and materializer tests that inspect direct runtime
    consumers and reject duplicated identity literals.
  - One commit-derived successor local Package and its bounded external golden
    path after all source/package gates pass.
- Out of scope:
  - Editing or repairing immutable `poc.38` bytes in place.
  - Reinterpreting historical transition records as runtime authority.
  - Provider redesign, Supervisor ownership changes, Manager UI changes, or
    unrelated Unity lifecycle behavior.
  - Silent deletion of the external project's existing provisioning instances.
- Change allowlist:
  - `com.rice.ai-codedb/package.json` only if successor Package identity
    requires it.
  - `com.rice.ai-codedb/Payload~/payload-manifest.json`
  - `com.rice.ai-codedb/Payload~/host-current.json`
  - `com.rice.ai-codedb/Payload~/Generations/poc.39/**` (successor generation;
    exact files frozen after the read-only inventory)
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `com.rice.ai-codedb/Tools~/install-codedb-provider.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-provider-installer.ps1`
  - One directly coupled generation-contract loader/materializer path only if
    the inventory proves it is required; any expansion requires Planner/User
    route approval before editing.
- Read-only dependency closure: DIRECT_REFERENCES_ONLY | generation loaders,
  package boundary assertions, materializer entry points, and the protected
  external failure evidence.
- Protected state:
  - All `poc.38` Package/generation bytes and commit-derived artifact evidence.
  - Accepted commit `7bd3eaca0243b17fbc60cd3d3a624f755846408b`.
  - External consumer manifest/lock and its nine `PROVISIONING` instance
    directories; no cleanup without a separate human authorization.
  - Inherited workflow, task, validation-project, and verification changes.
- Snapshot binding: required before GUARDED/RELEASE review.
- Identity authority route: canonical generation contract plus read-only
  PowerShell/Node loaders; no consumer-owned identity literals.
- Generation transition: `poc.38` protected -> successor `poc.39`; Package
  identity must be successor-identified rather than mutating preview.4 bytes.
- Identity closure: package version, payload version/sequence, generation id,
  generation manifest hash, current pointer, worker identity, instance
  manifest, and direct runtime consumers.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE
- Coder actions: inventory first; freeze exact successor allowlist; implement
  contract route and generation materialization; update only direct boundary
  tests; produce one commit-derived local Package after acceptance.
- Evidence scenarios:
  - canonical contract agrees with package/payload/pointer/generation;
  - PowerShell and Node loaders consume the same contract;
  - generation-owned scripts contain no independent identity literals;
  - a fresh instance manifest validates against the successor contract;
  - external Configure Dependencies reaches the terminal state once.
- L0 tests: `test-codedb-package-boundary.ps1`; focused
  `test-codedb-host-payload-materializer.ps1` generation/contract filter;
  targeted Node syntax/contract consumer checks.
- Affected L1 tests: only direct Package materializer and generation consumer
  tests selected by the frozen inventory.
- Explicitly not run: full repository regression, unrelated Provider tests,
  Unity MCP, hidden/background Unity, automatic external retries, process
  probes, and cleanup of external provisioning directories.
- Test rationale: this defect crossed JSON, PowerShell, Node, generation
  materialization, and external Package acceptance; source-only or Unity-only
  evidence is insufficient.
- Package identity gate: required before any Unity or external gate.
- Direct identity consumers: frozen inventory recorded in RESULT.md before
  implementation.
- Forbidden duplicated literals: package/payload/generation/sequence values in
  runtime consumers outside the canonical contract and historical transitions.
- Mechanical corrections per scenario: 2
- Corrected semantic attempts per local evidence scenario: 2
- Independent product causes before reassessment: 1
- Active time budget: DEEP_60M
- Output budget: V2_DEFAULT
- Broad search/full diff/full regression: FORBIDDEN | bounded identity inventory
  only before the allowlist is frozen.
- EditMode authorization: NOT_REQUESTED | separate human gate after Package
  identity PASS.
- Side-effect authorization: NONE | external cleanup/reinstall and golden path
  require separate human authorization.
- Stop conditions: any identity drift, second independent contract authority,
  attempt to edit `poc.38`, failed successor closure, or repeated external
  retry request before a passing artifact gate.
- Escalation triggers: allowlist expansion, need to mutate protected runtime,
  inability to derive all consumers from one contract, or any new external
  blocker after the successor artifact gate.
- Mode-promotion triggers: DEFAULT_V2_1 plus architectural ambiguity or
  successor-generation transition.
- Structural escalation guard: repairs 0/2; independent causes 0/2;
  diagnostic-only checkpoints 0/3; immediate structural triggers apply.
- Model escalation: HUMAN_APPROVED

## Definition Of Done

- Expected result: one successor Package identity route with no runtime
  identity drift and a successful bounded external golden path.
- Required evidence: frozen authority/consumer inventory, source/static checks,
  Package-boundary PASS, materializer PASS, successor identity hashes,
  independent RELEASE Verifier PASS, and one human-owned external result.
- Deferred risks: cleanup/reinstall of the nine failed external provisioning
  instances, full regression, and remote publication unless separately
  authorized.

## Handoff

- Current task: cdb-v0.3-p0-s18-package-identity-authority-refactor
- Current status: READY / HUMAN_DISPATCH_PENDING
- Next notification: UnityCodeDB v0.3 Planner
- Next action: Planner freezes the read-only consumer inventory and dispatches
  the continuous task to `v0.3.coder.deep`.
- Human decision or authorization required: Coder dispatch, later Verifier,
  successor Package export, external cleanup/reinstall, and publication.

## Planner Freeze - 2026-09-22

The user authorized freezing this continuous authority-refactor task. The
frozen baseline is:

- Branch: `codex/v0.3.0-legacy-workflow`
- HEAD: `7bd3eaca0243b17fbc60cd3d3a624f755846408b`
- Accepted predecessor: `0.3.0-preview.4 / poc.38`
- Protected external evidence: Configure Dependencies exit `4`, automatic
  convergence exit `6`, and the deterministic payload sequence mismatch.
- Protected external residue: nine `PROVISIONING` instance directories;
  cleanup remains a separate human-owned operation.

Frozen baseline SHA-256 values:

- `com.rice.ai-codedb/package.json`:
  `e7264016ce7e7f1c1d0777d2ebb48539ba52eaa87b8575491acef5343d00bdb7`
- `com.rice.ai-codedb/Payload~/payload-manifest.json`:
  `ce84b9ac6e009024eb757ef815215c848042dbc3714883a2a3cd9fb7338e366a`
- `com.rice.ai-codedb/Payload~/host-current.json`:
  `29bc2bb14e06885253146594472060cc3847e062978c1301f1505379b133cea3`
- `com.rice.ai-codedb/Payload~/Generations/poc.38/generation-manifest.json`:
  `b176c13aeb19d183e388290c6617567e19b61ade9b467dca7160310d00424638`
- `com.rice.ai-codedb/Payload~/Generations/poc.38/scripts/codedb-project-common.ps1`:
  `1eaa3c0fe1e0ccd1b935d2cfe4e71ebd711831ff02d82d263091b47bfd668843`
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`:
  `9cd8534eb81f5b54b3632af0fe21d6c9ac2e186f8d45f17f19e68d6e878cbeaa`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`:
  `45ef052a61b1fc88d380982b4593babe8e4a9806895721dcfc4ed86dd883354a`

No successor files exist yet. Coder's first bounded operation is a read-only
direct-consumer inventory and exact allowlist proposal. No production edit,
Package export, Unity run, external cleanup, or Verifier routing is implied by
this freeze.

Current status: `FROZEN / CODER_INVENTORY_PENDING`.
Next actor: UnityCodeDB v0.3 Planner.
Next action: dispatch `v0.3.coder.deep` for the frozen inventory and authority
route proposal.
Human decision or authorization required: Coder dispatch is authorized by the
freeze; implementation, external cleanup/reinstall, commit, export, Verifier,
and publication remain separate gates.

## Inventory Decision And Implementation Authorization - 2026-09-22

The user chose `REFACTOR` continuation after the bounded inventory. The
successor identity is frozen as `0.3.0-preview.5 / poc.39 / sequence 39`.
The change allowlist is expanded by exactly:

- `com.rice.ai-codedb/Tools~/install-codedb-provider.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-provider-installer.ps1`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` (one
  test-only fixture path normalization; no production behavior)
- `com.rice.ai-codedb/Tests/Editor/OwnerIdentityV2Status.json` (one
  test-only successor runtime-contract hash binding; no production behavior)

The installer correction must remove its independent Package-version pin and
validate/use the canonical caller-supplied version; replacing a preview.4
literal with a preview.5 literal is forbidden. No Supervisor, Manager, Bridge,
C# Editor, Provider artifact/manifest, external runtime, or cleanup expansion
is authorized.

Current status: `REFACTOR_AUTHORIZED / IMPLEMENTATION_READY`.
Next actor: `v0.3.coder.deep`.
Next action: implement the canonical authority route, successor generation,
and bounded L0 evidence on the frozen baseline.
Human decision or authorization required: later Verifier, commit, export,
external cleanup/reinstall, external retry, and publication.

## Baseline Fixture Correction Authorization - 2026-09-22

The user authorized a single test-only correction for the inherited fixture
literal `C:\\fixture-supervisor.exe` that blocks the Package-boundary sanitizer.
The correction is restricted to path normalization in synthetic test data. No
production code, identity contract, payload, generation, Provider installer,
external runtime, or `poc.38` bytes may change.

The Coder may run only the corrected Package-boundary L0 and one final scoped
diff check for this checkpoint. Unity, external cleanup/retry, commit, export,
push, and Verifier routing remain deferred.

## Successor Fixture Hash Correction Authorization - 2026-09-22

The user authorized one additional test-only correction after the bounded
Package-boundary run found `OwnerIdentityV2Status.json` still carrying the
predecessor `runtime_contract_sha256`. The Coder may update only that fixture
hash (and a directly coupled `.meta`/provenance file if the read-only
inventory proves one exists). No C# source, production code, Package identity,
generation, Provider installer, `poc.38`, or external runtime may change.

After this correction exactly one Package-boundary L0 and one final scoped
diff-check are permitted. A new independent product cause or any further
allowlist request requires route reassessment.

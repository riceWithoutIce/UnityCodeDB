# Task: cdb-v0.3-p0-s20-package-release-closure-gate

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Workflow: codedb-workflow-v2
- Workflow revision: 2.3
- Status: FROZEN / CODER_DISPATCH_PENDING
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep
- Review mode: RELEASE
- Execution mode: FAST_SUBAGENT
- Execution profile: v0.3.coder.deep
- Delegation authorization: STANDING_WORKFLOW
- Session policy: SPAWN_BOUNDED
- Requirement source: Package Release Closure Gate and S19 external failure

Planner routing update: the user selected the bounded child-agent workflow for
S20. One depth-one Coder child owns implementation; a later Verifier child may
start only after Coder stops and Planner freezes the accepted snapshot.

## Objective

- Produce one commit-derived local Package whose extracted bytes pass complete
  source-hash, cross-identity, and single-root closure validation. The known
  invalid S19 artifact must remain preserved as failure evidence. Unity and
  external consumer acceptance are downstream gates and are not implied here.

## Scope

- In scope:
  - Read-only inventory of the release/export route and every
    `payload-manifest.files[*]` entry.
  - One canonical generator/validator route for generation manifest,
    `host-current.json`, and `payload-manifest.json`.
  - Repair of the directly coupled Package metadata, release helper, and
    Package-boundary tests required by the inventory.
  - Export from a frozen commit, extraction of the exact archive, and complete
    closure validation on the extracted single-root Package.
- Out of scope:
  - Editing, overwriting, or deleting the observed invalid S19 artifact.
  - UnityValidationProject files, Unity/MCP/EditMode, external cleanup or
    reinstall, Provider redesign, runtime behavior changes, tag/push, and
    publication.
- Change allowlist:
  - `com.rice.ai-codedb/Payload~/payload-manifest.json`
  - `com.rice.ai-codedb/Payload~/host-current.json`
  - `com.rice.ai-codedb/Payload~/Generations/poc.39/**` only after the exact
    source inventory freezes the required files.
  - `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-package-release-closure.ps1`
    (new focused closure validator).
  - `com.rice.ai-codedb/Tests~/export-codedb-package.ps1`
    (new commit-derived export helper).
  - No broad artifact-tree allowance; package/generation metadata may change
    only when the validator proves the change is generated from one authority.
- Read-only dependency closure: DIRECT_REFERENCES_ONLY | package metadata,
  payload/generation loaders, release/export helper, closure tests, and the
  preserved S19 artifact evidence.
- Protected state:
  - `poc.39` source bytes unless a successor transition is explicitly frozen.
  - The S19 artifact directory and ZIP under `.artifacts/`.
  - UnityValidationProject and all inherited dirty files.
- Snapshot binding: required before implementation and RELEASE handoff.
- Identity authority route: canonical generation contract plus the one release
  generator/closure validator selected by inventory.
- Generation transition: preserve observed S19/poc.39 evidence; successor only
  if the frozen inventory proves the immutable generation cannot be admitted.
- Identity closure: package version, payload sequence, generation id,
  generation-manifest hash, current pointer, runtime target hash, and every
  declared payload source hash.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE
- Coder actions: inventory first; freeze exact paths and identity; implement
  the closure route; run focused source/package checks; export and extract one
  commit-derived artifact; record compact evidence.
- Evidence scenarios:
  - all declared payload sources exist and their actual SHA-256 values match;
  - generation and host-current hashes agree across all authorities;
  - known S19 mismatch is detected before repair;
  - frozen-commit export extracts as a single-root Package and passes the same
    validator byte-for-byte;
  - artifact identity and SHA-256 are recorded for downstream gates.
- L0 tests: `test-codedb-package-boundary.ps1`; a focused release-closure
  validator; materializer checks only when directly required by the closure.
- Affected L1 tests: none before the closure gate passes.
- Explicitly not run: Unity, Unity MCP, EditMode, external Configure
  Dependencies, Provider tests, runtime/process probes, cleanup, publication,
  tag, push, and full regression.
- Test rationale: the failure is an artifact-internal hash closure defect;
  source-only or Unity-only evidence cannot prove the consumed bytes.
- Package identity gate: required.
- Package release closure gate: required before any Unity or external gate.
- Canonical generator/closure validator: freeze during inventory; no manual
  independent hash edits.
- Commit-derived artifact and extracted-package paths: relative `.artifacts/`
  paths recorded in RESULT.md after export.
- Cross-hash assertions: full `payload-manifest.files[*]` enumeration,
  generation-manifest hash, host-current hash, runtime target hash, and
  package/payload/pointer tuple.
- Unity/external acceptance ordering: downstream only after closure PASS.
- Direct identity consumers: frozen inventory in RESULT.md; current source
  closure contains 46 declared sources and 0 worktree mismatches.
- Forbidden duplicated literals: package/version/sequence/generation/hash
  values outside the canonical contract and historical transitions.
- Mechanical corrections per scenario: 2
- Corrected semantic attempts per local evidence scenario: 2
- Independent product causes before reassessment: 1
- Active time budget: DEEP_60M
- Output budget: V2_DEFAULT
- Broad search/full diff/full regression: FORBIDDEN | bounded release inventory
  and exact extracted-artifact closure only.
- EditMode authorization: NOT_REQUESTED
- Side-effect authorization: NONE | export is local and must be from a frozen
  commit; no external installation or cleanup.
- Stop conditions: identity drift, any attempt to mutate protected evidence,
  second generator authority, incomplete source enumeration, or a closure
  mismatch after the allowed correction envelope.
- Escalation triggers: new generation transition, release-helper allowlist
  expansion, or any Unity/external failure after closure PASS.
- Mode-promotion triggers: DEFAULT_V2_1 plus release-artifact transition.
- Structural escalation guard: repairs 0/2; independent causes 0/2;
  diagnostic-only checkpoints 0/3; immediate structural triggers apply.
- Model escalation: HUMAN_APPROVED

## Definition Of Done

- Expected result: one valid commit-derived Package artifact passes complete
  closure validation without changing the observed invalid artifact.
- Required evidence: frozen inventory, source enumeration, cross-hash PASS,
  extracted archive PASS, artifact hash, commit source, scoped diff check, and
  explicit Unity/external NOT RUN boundary.
- Deferred risks: Unity/EditMode, external consumer retry, Provider/runtime
  acceptance, publication, and cleanup remain separate human-owned gates.

## Handoff

- Current task: cdb-v0.3-p0-s20-package-release-closure-gate
- Current status: FROZEN / CODER_DISPATCH_PENDING
- Next notification: UnityCodeDB v0.3 Planner
- Next action: dispatch the continuous implementation task to
  `v0.3.coder.deep` using the frozen allowlist and evidence envelope.
- Human decision or authorization required: Coder dispatch, exact allowlist
  freeze, implementation, commit-derived export, Verifier, and downstream
  Unity/external acceptance.

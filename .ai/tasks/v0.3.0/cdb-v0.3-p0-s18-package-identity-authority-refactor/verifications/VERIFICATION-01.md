# Verification: cdb-v0.3-p0-s18-package-identity-authority-refactor

## Outcome

- Verdict: `FAIL / P1_SUCCESSOR_OWNER_IDENTITY_FIXTURE_GENERATION_DRIFT`
- Workflow: `codedb-workflow-v2`
- Workflow revision: `2.2`
- Review mode: `GUARDED / RELEASE`, read-only except for this report.
- Frozen HEAD: `7bd3eaca0243b17fbc60cd3d3a624f755846408b` (`PASS`).
- Reviewed result: `Successor Closure Regeneration Checkpoint 05`, recorded as
  `COMPLETE / PACKAGE_BOUNDARY_PASS`.

The Package, pointer, generation, and payload hash chain is internally aligned,
but the portable Owner Identity fixture still declares predecessor generation
`poc.38` while carrying the successor preview.5 payload-manifest hash. This is
a mixed identity and prevents acceptance of the successor consumer closure.

## Frozen Evidence

- Current successor tuple is consistently declared by `package.json`,
  `Payload~/payload-manifest.json`, `Payload~/host-current.json`, and
  `Payload~/Generations/poc.39/generation-manifest.json` as
  `0.3.0-preview.5 / poc.39 / sequence 39 / bootstrap protocol 1`.
- Current payload-manifest SHA-256:
  `1359b3e14d9415b7929f263b3806027052e6ee8fb4f7543fb985d2bd7ba7a8e1`.
- Current generation-manifest SHA-256:
  `1baee3b9239ac5eb9ec6fb46451d7037d19d1142a097f2bd899c3ba345c5b4b2`.
  `host-current.json` and the payload-manifest generation entry both declare
  that exact value.
- Checkpoint 05 blobs match the observed snapshot:
  - payload manifest: `a5c2acd3201dadde4ac18a8edb8e3079422c789e`
  - Owner Identity fixture: `7f9bcc6e8af9869acf79d1209f51d9f287f8032f`
- All 22 successor generation file SHA-256 entries observed in
  `generation-manifest.json` match their current files. The 23-path successor
  closure and current pointer are represented by matching payload-manifest
  hashes.
- The PowerShell common contract and Node host-use gate load their sibling
  generation manifest and project the tuple from it. The Node instance worker
  validates instance identity against the shared generation contract. The
  Provider installer requires the caller-supplied Package version rather than
  pinning preview.4 or preview.5 as a second production authority.
- Reused Coder evidence: one Package-boundary L0 passed with exit `0` and one
  final scoped `git diff --check` passed. No test was rerun by Verifier.

## One-Time Finding

### P1 - The successor Owner Identity fixture remains bound to `poc.38`

`Tests/Editor/OwnerIdentityV2Status.json` currently declares all of these as
`poc.38`:

- `status.generation_id`
- `status.target_generation_id`
- `status.selected_generation_id`
- `status.operational_readiness.target_generation_id`
- `status.operational_readiness.selected_generation_id`

At the same time, both fixture `runtime_contract_sha256` fields were updated to
the preview.5 payload-manifest SHA
`1359b3e14d9415b7929f263b3806027052e6ee8fb4f7543fb985d2bd7ba7a8e1`.
The fixture therefore combines predecessor generation identity with the
successor runtime contract.

This is not an intentional trusted-previous scenario. The sole named consumer,
`SupervisorProtocol_ConsumesNodeProducedOwnerIdentityV2Status`, reads the
current Package runtime contract and explicitly requires fixture selected and
target generation IDs to equal `contract.Target.GenerationId`. The current
Package target is `poc.39`. The same test then invokes the production status
parser with expected target and selected generation `poc.39` and expects a
`Connected / CoreReady / CURRENT` snapshot. With the observed fixture bytes,
the explicit generation assertion fails before that positive successor path
can be accepted.

Checkpoint 05's Package-boundary PASS does not close this mismatch. Its
Owner Identity fixture assertions compare only the two runtime-contract SHA
fields to the payload-manifest file hash; they do not compare fixture target,
selected, or operational generation fields to the canonical successor
generation. Consequently the PASS is valid for the hash correction it ran,
but insufficient for the task's required Package/payload/pointer/generation/
consumer identity closure.

Recommended Planner/User disposition: `FIX`. A bounded correction should make
the complete portable fixture generation identity agree with the canonical
successor and add direct Package-boundary assertions for both top-level and
operational target/selected generation fields. Verifier does not authorize or
perform that correction.

## Boundaries

- Tests rerun by Verifier: `none`.
- Materializer L0, Provider-installer L0, targeted Node contract execution,
  C# compile, focused EditMode, full EditMode, PlayMode, Unity, Unity MCP/CUA,
  protected runtime/process inspection, external consumer retry, commit,
  Package export, tag, push, publication, promotion, and full regression remain
  `NOT RUN / DEFERRED` for Checkpoint 05.
- Immutable `poc.38` bytes and the external project's nine protected
  `PROVISIONING` directories were not read or modified by this review.
- No production or test source was modified, no Coder was contacted, and no
  repair was dispatched.

## Handoff

- Current status: `FAIL / SUCCESSOR_FIXTURE_IDENTITY_CLOSURE_REQUIRED`
- Next notification: `Planner/User`
- Next action: decide `FIX | DEFER | STOP`; `ACCEPT` is not supported for the
  current frozen snapshot.
- Any correction, fresh bounded evidence, Verifier re-review, commit, export,
  Unity/external retry, or publication requires its own authorization.

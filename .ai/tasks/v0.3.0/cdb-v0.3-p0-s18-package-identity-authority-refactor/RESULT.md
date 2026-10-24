# Result: cdb-v0.3-p0-s18-package-identity-authority-refactor

## Outcome

- Status: `ROUTE_REASSESSMENT_REQUIRED`
- Workflow: `codedb-workflow-v2`
- Workflow revision: `2.2`
- Phase: `INVENTORY`
- Execution mode/profile: `DURABLE_SESSION / v0.3.coder.deep`
- Delegation authorization used: `STANDING_WORKFLOW`
- Frozen HEAD: `7bd3eaca0243b17fbc60cd3d3a624f755846408b`
- Changed files: this `RESULT.md` only
- Outcome summary: the direct identity-authority inventory is complete. The
  `poc.38` failure is a Package-internal authority drift, and a second exact
  Package-version authority in the Provider installer requires a two-path
  allowlist expansion before successor implementation can safely start.

## Frozen Admission

The frozen HEAD and all seven TASK baseline SHA-256 values matched:

- `package.json`: `e7264016ce7e7f1c1d0777d2ebb48539ba52eaa87b8575491acef5343d00bdb7`
- `Payload~/payload-manifest.json`: `ce84b9ac6e009024eb757ef815215c848042dbc3714883a2a3cd9fb7338e366a`
- `Payload~/host-current.json`: `29bc2bb14e06885253146594472060cc3847e062978c1301f1505379b133cea3`
- `poc.38/generation-manifest.json`: `b176c13aeb19d183e388290c6617567e19b61ade9b467dca7160310d00424638`
- `poc.38/scripts/codedb-project-common.ps1`: `1eaa3c0fe1e0ccd1b935d2cfe4e71ebd711831ff02d82d263091b47bfd668843`
- `test-codedb-package-boundary.ps1`: `9cd8534eb81f5b54b3632af0fe21d6c9ac2e186f8d45f17f19e68d6e878cbeaa`
- `test-codedb-host-payload-materializer.ps1`: `45ef052a61b1fc88d380982b4593babe8e4a9806895721dcfc4ed86dd883354a`

No `poc.39` path existed at admission. Inherited task/workflow,
validation-project, and verification changes were preserved.

## Direct Consumer Inventory

### Canonical and projected data

The proposed single authority route is:

1. `Payload~/payload-manifest.json` is the Package runtime-contract authority
   for the current tuple: `package_version`, `payload_version`,
   `payload_sequence`, `generation_id`, and `bootstrap_protocol`.
2. `package.json.version` is artifact metadata and must equal the canonical
   `package_version`; it is not an independent runtime authority.
3. `Generations/<id>/generation-manifest.json` is the immutable,
   hash-addressed generation projection of that tuple plus the generation file
   closure. `host-current.json` is the derived pointer to that manifest.
4. Instance manifests and current-instance selection are derived runtime
   evidence. Their generation-manifest and worker hashes bind them back to the
   immutable generation contract; they never introduce new version literals.

`materialize-codedb-host-payload.ps1` already reads the payload manifest,
requires exact identity equality in the generation manifest and pointer,
verifies the generation file closure, and emits instance identity from the
validated manifest. It does not require a production edit for this route.

### Confirmed drift and duplicated literals

The protected `poc.38` generation contains a deterministic contradiction:

- `generation-manifest.json` declares package `0.3.0-preview.4`, payload and
  generation `poc.38`, sequence `38`, protocol `1`.
- `scripts/codedb-project-common.ps1` independently declares the same package
  and payload but sequence `35`, then rejects instance manifests whose
  `payload_sequence` differs from that literal.
- `shared/codedb-host-use-gate.mjs` independently declares
  `GENERATION_ID = "poc.38"`.
- `wrapper/codedb-project-instance-worker.mjs` independently compares the
  instance generation to `"poc.38"` and writes `"poc.38"` into instance
  leases. It also owns a local bootstrap-protocol literal.

The Package-boundary test missed the sequence defect because it validates the
JSON tuple across payload manifest, generation manifest, and current pointer,
then validates the generation file hashes. It only inspects the host-use gate
for one expected generation literal. It never parses or loads the three
PowerShell identity constants and never rejects the worker's generation
literal. A wrong literal can therefore be hash-authenticated as part of an
otherwise valid generation closure.

### Loader boundaries

- PowerShell: `poc.39/scripts/codedb-project-common.ps1` should perform one
  strict, bounded, read-only load of its sibling generation manifest via the
  generation root. It must validate schema/owner, directory leaf against
  `generation_id`, the complete five-field tuple, and supported protocol, then
  populate the existing script-scoped values from that object. Remove the
  package, payload, and sequence literals. All generation PowerShell entry
  points already dot-source this common file.
- Node: `poc.39/shared/codedb-host-use-gate.mjs` should load the same sibling
  generation manifest from `import.meta.url`, validate it fail-closed, and
  export a frozen generation contract and derived `GENERATION_ID`. The
  coordinator already imports from this module. The instance worker should
  import the same contract, validate the instance's package, payload,
  sequence, generation, and protocol against it, and derive lease identity
  from it. No new loader file is required.
- C#: `AICodedbPackageRuntimeContractStore.Read` already loads the canonical
  target tuple from `payload-manifest.json` without candidate literals.
  `AICodedbHostGenerationStore` already validates Package pointer, manifest
  hash/identity/file closure, installed pointer/manifest, and instance
  selection against that contract. No Editor/C# modification is proposed.
- Stable wrapper: the flat wrapper remains a hash-bound selector of the
  selected instance and generation worker. Its fixed worker-relative path is
  structural, not a release identity literal.

## Successor-only Proposal

The proposed candidate is `0.3.0-preview.5 / poc.39 / payload_sequence 39`,
with `poc.38` added as an exact historical bootstrap transition. Every
`poc.38` byte remains protected.

`poc.39` should contain exactly the existing 23-path generation closure:

- `codedb-mcp.runtime.example.toml`
- `codedbignore.example`
- `coordinator/codedb-watch-coordinator.mjs`
- `generation-manifest.json`
- `scripts/build-codedb-project-text-adapter.ps1`
- `scripts/check-codedb-project-freshness.ps1`
- `scripts/clear-codedb-project-index.ps1`
- `scripts/codedb-project-common.ps1`
- `scripts/emit-codedb-mcp-registration-draft.ps1`
- `scripts/manage-codedb-project-watch.ps1`
- `scripts/prepare-codedb-project-runtime.ps1`
- `scripts/prepare-codedb-project-watch-config.ps1`
- `scripts/probe-codedb-project-index.ps1`
- `scripts/probe-codedb-project-text-adapter.ps1`
- `scripts/refresh-codedb-project-if-stale.ps1`
- `scripts/refresh-codedb-project.ps1`
- `scripts/run-codedb-project-text-adapter-worker.ps1`
- `scripts/show-codedb-project-provider-guidance.ps1`
- `scripts/validate-codedb-mcp-project-config.ps1`
- `scripts/verify-codedb-project.ps1`
- `shared/codedb-machine-provider-contract.ps1`
- `shared/codedb-host-use-gate.mjs`
- `wrapper/codedb-project-instance-worker.mjs`

The 22 implementation files start from the protected `poc.38` closure. Only
the common PowerShell loader, host-use-gate Node loader, instance worker, and
generated manifest are expected to differ. Hash changes flow into the
generation manifest, payload manifest, and current pointer; no predecessor is
rewritten.

Runtime consumers outside the canonical JSON contract and historical
transition records must contain no candidate package version, payload version,
payload sequence, generation id, or bootstrap-protocol identity literals.
Structural schema versions, relative paths, and historical transition
identities remain permitted.

## Required Evidence Contract

Package-boundary L0 must assert:

- `package.json.version == payload-manifest.package_version`, with URLs derived
  from that value rather than a second expected-version constant;
- exact payload/manifest/pointer tuple equality and manifest-hash/file closure;
- generation PowerShell and Node consumers load the manifest contract and
  contain no successor identity literals;
- the worker validates all five identity fields and derives instance lease
  identity from the shared contract;
- negative fixtures for sequence, generation, package, protocol, worker hash,
  and generation-manifest hash mismatch fail closed;
- the Provider installer contains no exact candidate Package-version
  authority.

Focused materializer L0 must prove a fresh successor instance carries the
exact five-field identity, generation-manifest hash, and worker hash, and that
a tampered generation/sequence contract is rejected before a READY instance
or current selection is published. Targeted Node syntax/contract checks cover
the gate, coordinator import, and worker consumer.

## Allowlist Proposal And Route Reassessment

The original implementation allowlist remains necessary:

- `com.rice.ai-codedb/package.json`
- `com.rice.ai-codedb/Payload~/payload-manifest.json`
- `com.rice.ai-codedb/Payload~/host-current.json`
- `com.rice.ai-codedb/Payload~/Generations/poc.39/**` limited to the exact
  23 paths above
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

Inventory proves one additional directly coupled production/test pair is
required before implementation:

- `com.rice.ai-codedb/Tools~/install-codedb-provider.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-provider-installer.ps1`

The installer currently defaults and separately pins
`0.3.0-preview.4`, then rejects a caller-supplied Package version that differs
from that pin. The Package-boundary test explicitly requires both literals,
and the installer fixture supplies the same literal. A preview.5 successor
would therefore fail Configure Dependencies before reaching the corrected
generation route. The correction should validate and use the canonical
caller-supplied Package version while retaining preview/distribution checks;
it must not replace the old literal with a new literal.

No Supervisor, Manager, Bridge, C# Editor, Provider artifact/contract,
materializer production, external runtime, or cleanup expansion is required
by the inventory. The two installer paths require Planner/User approval before
any implementation edit.

## Evidence And Boundaries

The inventory used bounded `Get-Content`, `Get-FileHash`, and direct-reference
`rg`/`Select-String` reads only. No source/static test, L0/L1, Unity,
Configure Dependencies, Provider/MCP action, protected runtime read, process
probe, external cleanup, commit, export, tag, push, publication, or Verifier
contact was performed. Production, Package metadata, `poc.38`, tests, and the
nine external `PROVISIONING` directories were not modified.

## Handoff

- Current task: `cdb-v0.3-p0-s18-package-identity-authority-refactor`
- Current status: `ROUTE_REASSESSMENT_REQUIRED / INVENTORY_COMPLETE`
- Next notification: UnityCodeDB v0.3 Planner
- Next action: approve or reject the exact two-path Provider-installer
  allowlist expansion, then freeze the successor identity and implementation
  evidence budget before redispatching this same continuous task.
- Human authorization required: expanded implementation allowlist and later
  tests, commit, export, external cleanup/retry, Verifier, and publication.

## Implementation Checkpoint 01

The approved successor route was implemented on frozen HEAD
`7bd3eaca0243b17fbc60cd3d3a624f755846408b` without changing `poc.38` or
inherited dirty files. A new `poc.39` 23-file closure was created for
`0.3.0-preview.5`, sequence `39`, bootstrap protocol `1`.

Changed scope is limited to the approved package metadata, `poc.39` closure,
Package-boundary/materializer/provider-installer tests, and the Provider
installer. Common PowerShell, host-use gate, and instance worker now derive
the package/payload/sequence/generation/protocol tuple from their sibling
generation manifest. The installer now requires and validates the caller's
PackageVersion and has no second ProviderPackageVersion authority. The payload
adds the reviewed `poc.38` transition and retired closure while preserving all
`poc.38` bytes.

Evidence: PowerShell AST and Node syntax checks passed (exit 0). The first
Package-boundary L0 stopped before successor assertions on an inherited,
unchanged fixture in `Tests/Editor/AICodedbEditorLifecycleTests.cs`: its
synthetic escaped `C:\\fixture-supervisor.exe` text triggers the existing
machine-local absolute-path guard. This file is outside the S18 allowlist;
no workaround or source change was attempted. Materializer and Provider L0,
scoped diff-check, Unity, Unity MCP, runtime/process probes, commit/push, and
Verifier routing were not run. Current status is
`BLOCKED / INHERITED_PACKAGE_BOUNDARY_FIXTURE` pending Planner disposition;
the snapshot is not ready for Verifier.

## Baseline Fixture Correction Authorization - 2026-09-22

The user authorized one bounded test-only allowlist expansion for the inherited
`Tests/Editor/AICodedbEditorLifecycleTests.cs` fixture containing
`C:\\fixture-supervisor.exe`. The correction may only normalize that synthetic
path so the Package-boundary sanitizer can execute. Production code, package
identity, `poc.38`, `poc.39`, Provider installer, and external runtime remain
protected.

Current status: `FIX_AUTHORIZED / BASELINE_FIXTURE_PENDING`.
Next actor: `v0.3.coder.deep`.
Next action: apply the one-file test-only normalization, run Package-boundary
L0 once, and run one final scoped diff check.

## Successor Fixture Hash Correction Authorization - 2026-09-22

The user authorized one additional test-only correction for
`Tests/Editor/OwnerIdentityV2Status.json`, whose `runtime_contract_sha256`
still referenced the predecessor payload contract. Only that fixture hash and
any directly coupled provenance/meta file may change. The Coder may then run
exactly one Package-boundary L0 and one final scoped diff-check; no further
repair or allowlist expansion is implied.

## Test-Only Correction Checkpoint 02

The authorized single-file correction changed the synthetic lifecycle fixture
from escaped `C:\\fixture-supervisor.exe` to the relative
`fixture-supervisor.exe` placeholder. No production, generation, installer,
payload, or identity file was changed by this correction.

The one Package-boundary L0 then stopped at the next independent fixture
mismatch before successor assertions: `Tests/Editor/OwnerIdentityV2Status.json`
still records the predecessor payload-manifest SHA-256. Current payload hash:
`77648f179d0a9440e6af465fbf6a6dc053e65649bbcb69553a0364411b0c1af4`;
fixture value:
`ce84b9ac6e009024eb757ef815215c848042dbc3714883a2a3cd9fb7338e366a`.
That fixture is outside the authorized allowlist and was not modified. No
retry or repair was attempted. The one final allowlisted scoped
`git diff --check` passed (exit 0; JSON/package CRLF-to-LF warnings only).
Correction file identity is HEAD blob
`249085ebf6fe287175704c2e56f938305a063ad3` -> current blob
`dc1d992b50447b4bb71ad6127c9277591666a004`.

Materializer/Provider L0, Unity, Unity MCP, runtime/process probes, commit,
push, and Verifier remain NOT RUN/DEFERRED. Final status:
`BLOCKED / SECOND_INDEPENDENT_FIXTURE_MISMATCH`; Planner must decide whether
to authorize the exact OwnerIdentityV2Status.json correction or reassess the
task boundary. The snapshot is not Verifier-ready.

## Test-Only Correction Checkpoint 03

The separately authorized fixture correction updated both
`runtime_contract_sha256` fields in `Tests/Editor/OwnerIdentityV2Status.json`
to the current payload-manifest hash
`77648f179d0a9440e6af465fbf6a6dc053e65649bbcb69553a0364411b0c1af4`.
Its `.meta` file was inspected and has no coupled provenance/hash field, so it
remained unchanged. The one Package-boundary L0 then stopped at a new
independent failure before later successor assertions:
`Generation lease identity closure mismatch. Expected '1', got '0'.` No retry,
diagnostic expansion, or further repair was attempted. The one final scoped
`git diff --check` passed (exit 0; JSON/package CRLF-to-LF warnings only).

Frozen HEAD remains `7bd3eaca0243b17fbc60cd3d3a624f755846408b`; OwnerIdentity
fixture blob changed from `9f886fb1ad532f41cb6d42f04b982c2d06706d9c` to
`81fc7e2783f8c7361bbe32a071d94ace239fbd4c`. Materializer/Provider L0, Unity,
Unity MCP, runtime/process probes, commit, push, and Verifier remain
NOT RUN/DEFERRED. Final status is
`BLOCKED / THIRD_INDEPENDENT_BOUNDARY_FAILURE`; the snapshot is not
Verifier-ready and requires Planner/user disposition before any further work.

## Test-Only Contract-Alignment Checkpoint 04

The authorized test-only assertion was changed so the Package-boundary test
requires `codedb-host-use-gate.mjs` to read `generation-manifest.json`, use
`GENERATION_CONTRACT`, and contain no static successor `GENERATION_ID` export.
No production, generation, Provider, `poc.38`, or other test file changed.

The one authorized Package-boundary L0 stopped at a new independent payload
closure failure: `payload-manifest.json` records
`b176c13aeb19d183e388290c6617567e19b61ade9b467dca7160310d00424638` for
`Generations/poc.39/generation-manifest.json`, while the actual file hash is
`1baee3b9239ac5eb9ec6fb46451d7037d19d1142a097f2bd899c3ba345c5b4b2`.
No production metadata repair or retry was attempted. The one final scoped
`git diff --check` passed (exit 0; CRLF-to-LF warnings only). Test blob changed
from `8f24f576fbda9d2d2a9d81993c80bc463c4584a0` to
`c62128e166f74dff1eb9ca321767219ef43d40bc`.

Materializer/Provider L0, Unity, Unity MCP, runtime/process probes, commit,
push, and Verifier remain NOT RUN/DEFERRED. Final status:
`BLOCKED / FOURTH_INDEPENDENT_BOUNDARY_FAILURE`; Planner/user disposition is
required before any further action. Snapshot is not Verifier-ready.

## Successor Closure Regeneration Checkpoint 05

Under the separately authorized closure regeneration, only the stale
`Generations/poc.39/generation-manifest.json` entry in
`Payload~/payload-manifest.json` was updated from
`b176c13a...` to the actual file hash
`1baee3b9239ac5eb9ec6fb46451d7037d19d1142a097f2bd899c3ba345c5b4b2`.
The resulting payload-manifest byte hash was computed from the actual file as
`1359b3e14d9415b7929f263b3806027052e6ee8fb4f7543fb985d2bd7ba7a8e1`, and
only the two `OwnerIdentityV2Status.json` runtime-contract fields were
synchronized to that value. No production, generation, Provider, `poc.38`,
or other test file changed.

The one authorized Package-boundary L0 passed: exit 0,
`[OK] Standalone CodeDB package boundary passed.` The one final scoped
`git diff --check` also passed (exit 0; CRLF-to-LF warnings only). Frozen HEAD
remains `7bd3eaca0243b17fbc60cd3d3a624f755846408b`; payload manifest blob is
`a5c2acd3201dadde4ac18a8edb8e3079422c789e`, and OwnerIdentity fixture blob is
`7f9bcc6e8af9869acf79d1209f51d9f287f8032f`.

Materializer/Provider L0, Unity, Unity MCP, runtime/process probes, commit,
push, publication, and Verifier remain NOT RUN/DEFERRED. This checkpoint is
`COMPLETE / PACKAGE_BOUNDARY_PASS`; Planner may now perform frozen-snapshot
review and decide whether to route the exact snapshot to the child Verifier.

## Verifier P1 Bounded Fix 01

The sole `VERIFICATION-01` P1 was repaired within the authorized two test
files. `OwnerIdentityV2Status.json` now binds its top-level generation,
target, and selected generation plus its operational-readiness target and
selected generation to canonical `poc.39`. Both runtime-contract hashes remain
unchanged at
`1359b3e14d9415b7929f263b3806027052e6ee8fb4f7543fb985d2bd7ba7a8e1`.
The Package-boundary test now directly compares all five fixture generation
fields to `payloadManifest.generation_id`; no second successor constant was
introduced.

The one authorized Package-boundary L0 passed (exit 0):
`[OK] Standalone CodeDB package boundary passed.` The one final two-file plus
RESULT scoped `git diff --check` passed with exit 0 and no output. Frozen HEAD
remains `7bd3eaca0243b17fbc60cd3d3a624f755846408b`. Fixture blob changed from
`7f9bcc6e8af9869acf79d1209f51d9f287f8032f` to
`30e4be96ffa431959f91a7857cba1dca0548dead`; Package-boundary test blob changed
from `c62128e166f74dff1eb9ca321767219ef43d40bc` to
`3d87676dd0f531ef0d4871cbe11d525962c0ae52`.

Production, payload/generation manifests, Provider, `poc.38`, and other tests
were unchanged by this FIX. Materializer/Provider L0, Unity, Unity MCP,
runtime/process probes, commit, push, publication, and Verifier re-review were
NOT RUN/DEFERRED. Status: `COMPLETE / VERIFIER_P1_FIXED`; next action is Planner
review and an explicitly authorized targeted Verifier re-review of this exact
snapshot.

## Planner/User Disposition - 2026-09-23

The targeted FIX review in `verifications/VERIFICATION-02.md` returned
`PASS / ORIGINAL_P1_CLOSED` with no findings. The user accepted the current
S18 Package Identity Authority Refactor snapshot.

Final task disposition: `ACCEPTED / BOUNDED_SCOPE_COMPLETE`.

This acceptance covers the canonical `0.3.0-preview.5 / poc.39 / sequence 39`
identity authority, successor closure, Package-boundary L0, and the closed
Owner Identity fixture finding. It does not infer results for the separately
deferred Materializer/Provider L0, C# compile, Unity, Unity MCP, external
consumer retry, commit, export, tag, push, publication, promotion, or broader
regression gates. Those actions remain separately authorized follow-up work.

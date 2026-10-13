# Task: S29 immutable generation alignment and historical removal

## Metadata

- Product/version: UnityCodeDB v0.3.0 / existing S29.
- Workflow: codedb-workflow-v2 revision 2.6.
- Status: DELIVERY_AUTHORIZED / EXACT_COMMIT_EXPORT_SWITCH_ACTIVE.
- Planner: current parent; Coder: /root/retained_disposition_coder;
  Verifier: /root/retained_disposition_verifier, after stable Coder termination.
- Review mode: GUARDED; independent historical-removal/identity review required.
- Execution mode: DURABLE_SESSION, because the objective crosses identity and
  historical-removal authority. Default session policy REUSE_ONLY.
- Delegation authorization: TASK_SPECIFIC. User explicitly approved this task's
  existing Coder -> Verifier reuse and routing exception on 2026-10-12.
  Previous task grants/FAST_SUBAGENT standing authority are not its authority.
- Requirement source: user's approved alignment diagnosis, existing project
  integration/reinstall contract and workflow Package Identity Authority Gate.
- Source baseline: 61408bc7e43a63edf2f717d299ee5da868a62894.

## Objective

One bounded source/synthetic outcome: a distinct successor runtime can coexist
with the exact original installed poc.42; the existing historical removal
route can authenticate that original selected-v2 integration independently of
successor readiness, and controlled logical removal admits a fresh successor
installation without adopting or overwriting predecessor bytes.

## Frozen identities and scope

- Target: 0.3.0-preview.5 / poc.43 / sequence 43 / bootstrap protocol 1,
  derived by the existing generator's next-sequence rule. No Package version
  bump, new control version or user-facing automatic Upgrade flow.
- Historical predecessor: original poc.42 manifest
  2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026,
  original coordinator 5a61242e336fac40ac5ce94729d71c676272f65510993481c80a0ee71651ed00,
  from the frozen s29-post-install-ui-poc42 Package, never copied from live S29.
- Corrected successor input: exact retained-disposition-74c4db0 Package with
  coordinator 928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09.
  Preserve this previously observed, different poc.42 artifact as historical
  delivery evidence. Do not silently overwrite either observed snapshot.
- In scope: canonical successor production, exact predecessor declaration,
  selected-v2 removal authentication and directly coupled fresh-install evidence.
- Out of scope: actual migration/removal/Install, cleanup, reconstructed old
  action identity, shutdown-hang repair, Provider/Supervisor redesign, automatic
  instance Upgrade, arbitrary historical versions and release acceptance.

## Allowed implementation and evidence paths

Relative to com.rice.ai-codedb:

- Tools~/codedb-instance-engine.ps1: historical selection/activation removal
  binding and directly coupled retained-intent/fresh-install readers only.
- Tools~/materialize-codedb-host-payload.ps1: existing RemoveIntegration routing,
  owner authentication and Package-declared predecessor identity only.
- Tests~/test-codedb-package-release-closure.ps1: extend/reuse the canonical
  generator for independently bound successor input and original predecessor;
  preserve existing byte/admission gates.
- Tests~/test-codedb-host-payload-materializer.ps1: one new focused switch/batch
  for this historical selected-v2 removal and successor fresh-install outcome.
- Tests~/test-codedb-package-boundary.ps1: directly affected identity assertions
  only if current fixture assumptions prevent the new canonical identity.
- Candidate projection only: Payload~/payload-manifest.json, host-current.json,
  original Generations/poc.42 closure, new Generations/poc.43 closure and
  Tests/Editor/OwnerIdentityV2Status.json. Exact generated-file inventory and
  raw hashes are mandatory at stable handoff.

Do not write projected Payload/fixture changes over the dirty working-tree
versions. Build a new repository-local .artifacts/tests/s29-generation-alignment
child from the frozen source/Packages; overlay only allowlisted changes.
For later accepted delivery, return an exact projected-file manifest, generator
recipe and source patches. No staging/commit/export is included here.

Read closure: named functions' direct callers/readers, existing runtime-contract
loaders in C#/PowerShell/Node, canonical generator, boundary/closure validators,
test-workspace contract and attributable frozen Package inputs. Additional
production reader edits or new serialized fields require scope reassessment.
The first source-stage action is to freeze the exact entry/authority/consumer map
in RESULT before modifying authentication. Do not assume a generation bump alone
solves old runtime-contract or activation context mismatches.

Protected: all real S29/other projects, refs, selected/desired/control records,
receipts, old candidate/intents, installed immutable generations, previous
artifacts/backups and unrelated dirty/untracked bytes. Capture scoped baseline
hashes before editing and compare at terminal handoff. No reset or broad staging.

## Required behavior and consumer map

| Boundary | Required authority and evidence |
| --- | --- |
| Successor writer -> manifest/pointer/loaders -> new instance | One canonical five-field tuple and actual hash closure; no independent runtime literals. |
| Predecessor Package -> historical generation selection | Exact declared old files/manifest/worker/wrapper; original and corrected poc.42 cannot be conflated. |
| Original selected-v2 -> historical operation/activation -> owner | Exact project, instance, epoch, committed transaction and runtime-contract bindings under historical authority; no current-readiness requirement. |
| Existing removal entry -> durable removal intent | Revalidate owned paths/configuration/holders; preserve unrelated/unknown bytes and original outcomes. |
| Authenticated Uninstalled/retained closure -> fresh successor Install | Existing next-change validation, distinct generation path, new candidate/activation; retained predecessor cannot be adopted. |
| Backend preflight -> Manager removal presentation | Existing authenticated preflight token and RequiresReinstall routing remain authoritative; no forced Install button or cached permit. |

Prefer the existing historical activation reader; keep runtime CURRENT validation
strict. Do not trust a self-declared old hash without Package-bound predecessor
and cross-record authentication. If existing declarations cannot establish the
necessary historical runtime authority, return the exact contract gap before
adding schema fields, loaders or alternative authentication services.

## Execution envelope

- User grants: "同意 开始" after the diagnosis, then "批准本任务复用 Coder →
  Verifier（推荐）" in the concrete source/focused-test/review routing question.
  Continue all named source stages; no real-environment/delivery authority.
- Proposed source stages: single Coder -> terminal stable source/candidate ->
  parent snapshot admission -> independent read-only Verifier -> combined user
  disposition. Source ACCEPT remains a separate user decision.
- Canonical generator/validator: Tests~/test-codedb-package-release-closure.ps1
  -RepairCanonicalMetadata -SuccessorGenerationId poc.43, applied only to the
  isolated candidate. Its predecessor binding must reflect the original frozen
  Package; mere copying of corrected poc.42 would reproduce the current failure.
- L0: changed PowerShell syntax, canonical five-field/hash closure and production
  ValidatePayload admission against a test-owned logical root; native VerifyOnly
  only. No export, compiler toolchain download or native launch.
- Affected L1: one focused synthetic production batch using test-owned roots,
  production record writers/readers and actual preflight/removal/install paths.
  Stub only external process/Provider boundaries where an existing reviewed
  seam supports it; record the seam and do not label it live readiness.
- Cases: selected-v2 original42 + successor43; unchanged original manifest and
  generation bytes; committed historical activation with different runtime hash;
  wrong generation/hash/project/epoch/operation; undeclared predecessor,
  same-sequence changed content; foreign/ambiguous holder refusal; invalid or
  changed managed configuration; preserved inert retained closure; successful
  logical removal/fresh successor publication or exact classified remaining gap.
- Before freeze: scoped diff check, existing -PathProvenanceOnly gate, full
  candidate payload closure/admission, exact producer/reader evidence and hashes.
  Test root authority and cleanup/failure preservation follow test-workspace-contract.
- Explicitly not run: unchanged full backend suites, Unity/EditMode/Manager,
  live preflight/Probe/MCP/Provider, process control, actual Install/Uninstall,
  package export, reference switch, cleanup, commit/push/publication/release.
- Evidence/attempt budgets: Coder DEEP_60M, Verifier DEEP_30M; initial plus two
  causally corrected attempts per declared scenario; mechanical corrections 2;
  default output budgets, no broad audit/full diff/full regression. Report any
  truncation; do not claim retrospective budget compliance.
- Identity/path risk or evidence gap beyond these paths: stop dependent work,
  preserve stable evidence and return a concrete route decision. No automatic
  new parser, schema, transport or architecture expansion.

## Completion and proposed execution route

The stable snapshot, focused evidence, and independent FIX2 review are complete.
The original handoff blocker and its adjacent direct-entry evidence gap are
closed at the bounded source/synthetic level. User accepted this snapshot on
2026-10-13. Live/delivery gates remain separate; S29/release stay PARTIAL.

Explicitly user-approved transport exception: reuse the terminal task-scoped
retained_disposition_coder, then retained_disposition_verifier for this frozen
DURABLE_SESSION source envelope, without creating/rebinding any durable chat.
Depth one, single writer, no recursive delegation. This is a task-only exception
to the workflow's default execution-mode routing, not standing FAST_SUBAGENT
authorization. Parent stays active, consumes questions and confirms terminal
completion of each child, as the user requires. No model override is proposed.

- Current task: S29 generation alignment/historical removal.
- Current status: FIX2 Verifier terminal PASS_WITH_LIMITS; User accepted the
  source/synthetic snapshot and authorized delivery preparation. Historical
  identity, predecessor closure, handoff enforcement, three removal gates,
  ordinary strictness and direct consumer compatibility pass within their
  stated evidence limits. Protected OwnerIdentity drift remains preserved.
- Next notification: return the exact prepared delivery scope to User.
- Next action: User replied `批准` to FIX2-DELIVERY-PREPARATION.md's exact
  grouped sequence on 2026-10-13. Execute its bounded local commit, export,
  reference switch and human checklist steps after their preconditions pass;
  real Remove/Install remains a further separate gate.
- Human authorization required: expanded schema/reader/architecture scope,
  later source disposition or real/delivery operations only.

## Approved contract expansion — 2026-10-12

INSTALLED-GENERATION-ALIGNMENT-CONTRACT-PROPOSAL.md is the approved precise
addition to this frozen task. Permit source_runtime_contract_sha256 and its
canonical producer/PowerShell loader/removal-only historical semantics within
the existing allowlist. Include all three actual RemoveIntegration next-change
gates, preflight/entry token continuity and commit-time revalidation. New field
compatibility must reach real C#/Node readers; production edits to those readers
remain unapproved unless a concrete incompatibility is returned. Keep ordinary
Uninstall/CURRENT/Install authentication strict. No other schema expansion.
Reuse original Coder and later Verifier; no new agent or model override.

## Finding disposition — 2026-10-12

User explicitly selected `fix` after the consolidated implementation review.
The Coder's direct consumer map shows that repairing the missing
preflight-to-durable-removal authority/token continuity requires two C#
production consumers and a CLI argument/output transport beyond the original
PowerShell-only allowlist. This is recorded as a pending scope decision before
any such source edit. Preserve the original review and failed evidence.
Existing source allowlist and protected bytes remain in force; if a production
consumer outside that allowlist or new serialized transport is required, return
the concrete minimum scope before editing it. Do not reinterpret FIX as real
removal, Install, Unity, commit, export, reference switch or cleanup authority.
The protected OwnerIdentityV2Status drift is a separate limitation, not a repair
target; capture current protected state without erasing the original mismatch.

## Approved consumer scope and FIX2 — 2026-10-12

User explicitly approved the prior minimum extension: Editor/
AICodedbHostPayloadMaterializer.cs, Editor/AICodedbActions.cs, the existing
materializer PowerShell/focused test paths, and the new dedicated Editor/
AICodedbHostPayloadMaterializerPreflightHandoffTests.cs. This records existing
authorization; it does not extend protected ManagerUi tests or real operations.

After FIX review returned F1 (UNINSTALLED early-entry bypass) and F2 (missing
direct refusal evidence), User requested read-only alignment and then agreed
to the presented three-part repair. Only enforce the existing handoff at the
durable function boundary, make the existing UNINSTALLED entry follow it, and
cover valid/missing/expired/authority/config drift at the real changed entry.
Preserve existing authentication, terminal-state semantics and original
failed evidence. Record terminal no-authority cases distinctly from mutation;
return any concrete contract conflict before inventing another token schema
or recovery route. No Unity, real Remove/Install, commit, export, reference
switch, cleanup or additional architecture authority is included.

## Source acceptance and delivery-preparation authorization — 2026-10-13

User replied `同意授权` after the FIX2 `PASS_WITH_LIMITS` result. Interpreted
within the stated boundary, this accepts the FIX2 source/synthetic stage and
authorizes delivery preparation. The current five-file source snapshot matches
`INSTALLED-GENERATION-ALIGNMENT-PREFLIGHT-HANDOFF-FIX2-SOURCE-SHA256.txt`; the
isolated candidate is `fix2-a4` and its focused evidence is 35-case synthetic
PASS.

This authorization does not itself execute commit, export, Package reference
switch, Unity launch, real Remove/Install, cleanup, or release acceptance. The
earlier retained-disposition delivery grant was bound to its prior accepted
source hashes and prior delivery result; FIX2 requires a fresh exact delivery
grant if those operations are requested. Preserve the existing dirty working
tree and the `OwnerIdentityV2Status.json` protected drift until that grant.

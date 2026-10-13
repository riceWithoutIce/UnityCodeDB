# S29 installed generation alignment — Coder entry map and contract gap

Date: 2026-10-12. Status: CONTRACT_GAP / SOURCE_UNMODIFIED.
Source baseline: 61408bc7e43a63edf2f717d299ee5da868a62894.
Task-specific Coder reuse and read-only Verifier route were approved. This record
freezes the entry/authority/consumer map before any authentication changes.
Parent directed terminal stop after documenting this gap. No candidate was made.

## Frozen entry / authority / consumer map

| Boundary | Existing production authority and reader | Required outcome / observed gap |
| --- | --- | --- |
| Canonical successor writer | test-codedb-package-release-closure.ps1 New-CanonicalSuccessorGeneration, line 155 | Writer currently conflates corrected runtime source and predecessor Package. Separate original42 binding is required; original generation bytes must remain exact. |
| Manifest -> current runtime | materialize-codedb-host-payload.ps1 Read-PayloadManifest, lines 1237-1285 and 1344-1361; AICodedbPackageRuntimeContract.cs line 227; codedb-project-supervisor.mjs line 3133 | Five-field identity and current payload raw SHA256 are authoritative. CURRENT validation must remain strict. C#/Node transition readers consume existing transition identity/wrapper fields; compatibility for a new field is not verified. |
| Package predecessor -> selected-v2 closure | codedb-instance-engine.ps1 Get-InstanceGenerationPackageIdentity, line 3575; materializer Get-ValidatedRemoveIntegrationSelection, line 10281 | Exact transition tuple plus Package-retained generation manifest/worker/wrapper authenticates the generation. Same-sequence different content is rejected. Transition has no original payload-manifest SHA256 authority. |
| Selected-v2 -> owner | materializer Assert-RemoveIntegrationOwnerRecord, line 10367, v2 branch line 10476 | State and lock must match project, instance, epoch, control contract and process identity. V2 currently additionally demands successor target generation/runtime hash, rejecting the original installed owner. |
| Selected-v2 -> historical committed activation | materializer Get-RemoveIntegrationActivationState, line 10754; instance engine New-InstanceActivationContractContext, line 476 and Get-InstanceActivationContractState | Historical reader takes runtime hash from activation.json itself, then authenticates operation/activation and exact selection. Cross-record equality alone does not independently establish the original Package runtime hash. |
| Removal entry -> intent | RemoveIntegrationPreflight dispatch line 12154 -> Get-RemoveIntegrationAuthority line 10556 -> selection/owner/holders/historical activation; Invoke-RemoveIntegration line 11417 | Require authenticated historical context, dead/unambiguous holders, managed-config/path revalidation and durable removal intent; successor readiness is not the removal authority. No production preflight was executed. |
| Ordinary Uninstall | codedb-instance-engine.ps1 Get-CurrentProjectRemovalAuthority, line 5147 | Current selection and current activation context are strict. Do not weaken this entry to bypass the historical route. |
| Removed / retained -> fresh successor | Existing retained-intent/next-change validation and immutable-generation publication | Preserve inert original42 and publish distinct poc.43, never adopt original42 or overwrite immutable bytes. This outcome has not yet been tested. |
| Backend preflight -> Manager presentation | Existing authenticated preflight result and RequiresReinstall routing | No forced Install button, cached permit or Editor/UI change is proposed. |

## Exact authority gap

RuntimeContractSha256 is the raw SHA256 of payload-manifest.json, not of
generation-manifest.json. Verified original frozen Package payload hash:
538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d.
Corrected delivery hash from frozen diagnosis:
24bc8da5c9fb1914113b0d9270ecbb77285b09a7ce9f31841a6ac58906863604.

Existing bootstrap transition declaration/parser includes the exact five-field
tuple, marker/gate/lease versions, flat file count/closure and stable-wrapper
hash. RetiredTargetMap holds path membership; retained generation files establish
generation closure. None binds the predecessor payload manifest raw hash.
Therefore an original42 generation declaration plus successor43 naming cannot
prove that historical activation runtime hash 538c... is Package-authorized.
Accepting any matching self-declared state/lock/activation/operation hash would
leave this specific authority unbound. Keeping current hash validation instead
rejects the legitimately installed predecessor. Neither meets the frozen task.

## Minimal contract recommendation — not implemented

Reassess a narrowly scoped optional `source_runtime_contract_sha256` declaration
on the exact bootstrap transition. The canonical generator must derive it from
the independently supplied, validated, frozen predecessor Package's original
payload-manifest bytes; never from live activation/owner records or reserialized
metadata. It must independently preserve the exact original generation closure
and copy corrected runtime input only into successor43.

For historical selected-v2 removal only, require one exact predecessor tuple and
Package-retained closure, and require this declared hash to match all historical
state/lock/activation/operation records. Build activation context from that
Package-declared hash and original generation closure, rather than activation's
self-declared hash. Bind original target generation and epoch consistently; keep
current runtime/ordinary Uninstall validation unchanged. Old transitions without
the field remain usable for their existing reviewed purposes but fail closed for
this new selected-v2 historical runtime admission.

This adds a persisted declaration/loader responsibility and therefore needs
User/Planner scope reassessment under the task's explicit stop rule. C#/Node
reader compatibility must be checked before deciding whether their source paths
need an expanded allowlist; no additional reader edits are assumed authorized.
Focused cases should include absent/malformed/wrong declared runtime hash,
correlated record tampering, wrong tuple/project/epoch/operation, original closure
preservation and post-removal distinct successor publication. Existing holder,
configuration, undeclared-predecessor and same-sequence refusal cases remain.

## Evidence and protection

INSTALLED-GENERATION-ALIGNMENT-PROTECTED-BASELINE.jsonl records eight scoped roots
with file counts and SHA256 over newline-delimited, sorted relative-path/raw-hash
inventory entries. It covers working Payload/fixture, both frozen Package inputs,
actual S29 AIWork/refs, project action index and successful receipt closure.
Source SHA256 manifest records all five allowlisted files; their initial diff
against HEAD was empty. No source, Package, protected state or projected payload
write occurred. Terminal recomputation passed: all eight protected root inventories
and all five source hashes are unchanged. This is scoped byte evidence, not a live
readiness/holder authentication claim or a blanket audit of all prior artifacts.

No changed-source parse, canonical generation/closure/admission, native
VerifyOnly, focused synthetic batch or path-provenance gate was run: there is no
implementation/candidate to validate. No Unity/MCP/CUA/BatchMode, process control,
actual Install/Uninstall/Remove/Preflight/Probe, commit/export/ref switch or
cleanup occurred. Source stage is not PASS or ACCEPT; S29/release remain PARTIAL.

Read-only command limitations: two batched outputs and one broad git-status
output were truncated; exact authority functions/schema were subsequently read
in bounded ranges. One Windows wildcard rg path and one absent Runtime directory
search failed mechanically, without writes or operational attempts. No claim of
retroactive output-budget compliance is made. No test attempts were consumed.

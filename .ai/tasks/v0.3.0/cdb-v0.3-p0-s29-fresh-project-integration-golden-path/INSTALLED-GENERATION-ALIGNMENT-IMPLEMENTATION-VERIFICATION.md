# S29 installed generation alignment — implementation verification

Date: 2026-10-12.
Verdict: **BLOCKED** — the historical Package authority and all three
removal-only next-change gates are source-consistent, but the approved
preflight-to-removal authority/token continuity contract is not implemented or
covered by the supplied focused evidence.

Verifier: `/root/retained_disposition_verifier`.
Review mode: one guarded, read-only implementation review of the frozen
generation-alignment scope. No tests, Unity, CLI preflight, process control,
Install/Uninstall/RemoveIntegration, export, reference switch, commit, push,
publication or cleanup was run.

## Snapshot and projection admission

- The five declared implementation source hashes match
  `INSTALLED-GENERATION-ALIGNMENT-IMPLEMENTATION-SOURCE-SHA256.txt` exactly.
- The candidate projection is isolated under
  `.artifacts/tests/s29-generation-alignment/implementation-a2`.
- Candidate `poc.42` contains 30 files and has zero raw-hash differences from
  the frozen `s29-post-install-ui-poc42` predecessor closure.
- Candidate `poc.43` contains 30 files; each file hash agrees with its
  generation manifest. The candidate payload hash is
  `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- The `poc.42` transition declares
  `source_runtime_contract_sha256=538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d`,
  which matches the raw SHA256 of the independently frozen predecessor
  `Payload~/payload-manifest.json`.
- The projection manifest's sorted relative-path/raw-hash inventories for the
  payload manifest, host-current, OwnerIdentity fixture, and both generations
  recompute to their declared values.

These checks establish the predecessor/successor projection and source
snapshot; they do not establish live Unity, runtime, or release acceptance.

## Source checks that pass

`Get-InstanceGenerationPackageIdentity` now resolves historical identity from
the exact Package transition and returns the declared predecessor runtime hash.
`Get-RemoveIntegrationRuntimeContext` rejects a missing or malformed historical
hash and uses the Package-declared value, while current identity continues to
use the current manifest runtime contract.

`Get-RemoveIntegrationActivationState` replaces the self-declared activation
runtime hash with that Package-bound context for Owner Identity v2 and retains
selection, generation, epoch, committed activation and operation checks.
`Assert-RemoveIntegrationOwnerRecord` keeps the current/ordinary path strict
and compares historical v2 owner records against the Package predecessor
context.

`Invoke-RemoveIntegration` passes `-HistoricalRemoval` at all three required
`Assert-InstanceNextChangeAdmission` sites: entry, after authority lookup, and
the pre-mutation callback. The returned fingerprint is rechecked before
mutation, and the owner fingerprint/instance identity is re-read before the
transaction. Holder, configuration, effect, journal, immutable closure and
commit-time checks remain present.

The C# and Node transition readers continue to accept the optional extra field
without requiring production reader edits; no direct consumer in those readers
needs the field for ordinary routing.

Old transitions without the field remain parseable, but the historical v2
runtime-context path fails closed when it needs a Package-declared predecessor
runtime hash.

## Blocking finding — preflight authority/token continuity is absent

The approved contract explicitly requires the existing
`RemoveIntegrationPreflight` dispatch to return the same historical authority
or token that the durable RemoveIntegration entry consumes. The implementation
does not provide that handoff:

- `Tools~/materialize-codedb-host-payload.ps1:12194-12201` calls
  `Get-RemoveIntegrationAuthority` and the managed-config plan, then emits only
  `[REMOVAL_PREFLIGHT] AVAILABLE`.
- `Editor/AICodedbHostPayloadMaterializer.cs:197-210` authenticates only that
  single boolean output; no authority fingerprint, historical token, or durable
  binding is returned.
- `Invoke-RemoveIntegration` at `11476`, `11495`, and `11540` re-reads its own
  historical authority/fingerprint. This is a useful safety revalidation, but
  it does not consume a token produced by the preflight dispatch.
- The focused synthetic batch's “preflight” assertion directly invokes
  `Get-RemoveIntegrationAuthority` and therefore does not cover the CLI
  preflight dispatch or a preflight-to-removal handoff.

The current design can still refuse state drift safely, but it does not satisfy
the frozen continuity contract and leaves the Manager's cached boolean
preflight separate from the durable removal authority. This is an in-scope
contract gap, so source acceptance cannot be recommended from this snapshot.

## Protected-state observation

Seven of the eight inventories in
`INSTALLED-GENERATION-ALIGNMENT-PROTECTED-BASELINE.jsonl` recomputed unchanged.
The protected working-tree file
`com.rice.ai-codedb/Tests/Editor/OwnerIdentityV2Status.json` does not: its
current inventory hash is `8a904b50a9446dd183fdbf3f6115f7d4ef78e0bb207d7f8922a5e4419765296b`
versus the recorded `4c0761b6c58e98ec49f8c05a056d63c3be875fc8287dfed7b9e01e568cc51038`.
It is already dirty and outside the five-file implementation allowlist; this
review does not attribute or modify that drift. It remains a separate
protected-state limitation that must be reconciled before any delivery claim.

## Limits and disposition

Coder-reported `ValidatePayload`, native `VerifyOnly`, 27-case synthetic
production batch and Node syntax checks are retained as Coder evidence and
were not rerun here. No live preflight, real removal, fresh Install, Unity
EditMode, runtime readiness, package export, commit or release gate is proven.

The historical Package identity, predecessor closure and three removal gates
are ready for a new bounded review after the preflight authority/token handoff
is implemented and its direct dispatch/consumer path is covered. User/Planner
must decide whether to repair that gap or explicitly revise the frozen
contract; this Verifier does not dispatch a repair.

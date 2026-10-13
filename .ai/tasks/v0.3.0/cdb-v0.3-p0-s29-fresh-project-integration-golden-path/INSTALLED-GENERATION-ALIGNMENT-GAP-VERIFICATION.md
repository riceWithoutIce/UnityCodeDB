# Installed generation alignment contract-gap verification

Date: 2026-10-12.
Verdict: **CONTRACT_GAP_CONFIRMED / NOT SOURCE PASS**. The diagnosis is
consistent and may proceed to a narrowly reviewed contract expansion, subject
to a new User/Planner scope decision. No implementation was accepted.

## Identity and review limits

- Read the complete frozen `INSTALLED-GENERATION-ALIGNMENT-TASK.md` and
  `INSTALLED-GENERATION-ALIGNMENT-RESULT.md`.
- `INSTALLED-GENERATION-ALIGNMENT-RESULT.md` SHA256 matches the declared
  `0b8636193d66ee457ae2195b719a9d3c7d857fe7690827e5cda70ab48bacd4ea`.
- All five unchanged source hashes in
  `INSTALLED-GENERATION-ALIGNMENT-SOURCE-SHA256.txt` match. Working source is
  unmodified for this task. The protected baseline is a scoped inventory, not a
  blanket live-state audit; no protected bytes were written.
- This was one read-only direct-reference review. No tests, Unity, CLI
  preflight, process control, package export, reference switch, or real removal
  / Install ran. No Coder was contacted and no other agent was started.

## Confirmed authority gap

The frozen original `poc.42` Package payload manifest hash is
`538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d`; the
corrected retained-disposition `poc.42` input is independently observed as
`24bc8da5c9fb1914113b0d9270ecbb77285b09a7ce9f31841a6ac58906863604`. Their
coordinator bytes also differ (`5a61242e...` versus `928a58b3...`). Therefore a
successor transition cannot infer the historical runtime contract from the
working Package or from activation records.

The current transition contract binds the predecessor tuple, marker/host-use/
lease versions, flat closure and stable wrapper. The C#, PowerShell and Node
readers all require and validate those fields, but no transition field binds the
predecessor `payload-manifest.json` raw SHA256. The current historical reader
(`Get-InstanceGenerationPackageIdentity`) can validate retained generation and
worker/wrapper closure, while `Get-RemoveIntegrationActivationState` currently
adopts `runtime_contract_sha256` from `activation.json`. Cross-record equality
does not establish Package authority for the original runtime hash.

Thus the proposed optional `source_runtime_contract_sha256` on the exact
bootstrap transition is necessary for this historical selected-v2 route. It is
also appropriately limited if the canonical successor writer computes it from
the separately supplied, validated frozen predecessor Package bytes. It must not
be derived from live activation, owner, or reserialized JSON. The declaration
must stay bound to the exact predecessor tuple, original generation closure and
successor's immutable output.

## Direct consumer review and required scope correction

The proposal must include the following directly coupled PowerShell consumers;
otherwise it would be structurally incomplete:

1. `Get-InstanceGenerationPackageIdentity` must read and verify the new
   predecessor declaration and return the Package-authorized historical runtime
   hash alongside generation/worker/wrapper identity.
2. `Get-RemoveIntegrationActivationState` and its caller
   `Get-RemoveIntegrationAuthority` must construct historical activation context
   from that Package-declared hash, while preserving exact project, selected
   instance, generation, epoch, committed operation/activation and holder checks.
   A self-declared activation hash must no longer be the sole historical source.
3. `Assert-RemoveIntegrationOwnerRecord` must have a removal-only historical
   comparison against the Package predecessor authority. The current `VERSIONED_V2`
   check at its `target_generation_id` / `runtime_contract_sha256` boundary is
   intentionally current-owner validation and must remain strict for ordinary
   paths.
4. `Invoke-RemoveIntegration` has three direct next-change gates (before
   authority lookup, after lookup, and immediately before commit):
   `Assert-InstanceNextChangeAdmission` currently reads the successor Manifest
   and calls current activation readers. A selected original-v2 project can be
   rejected at these gates even after historical owner authentication is fixed.
   The expansion must define a removal-only historical context or an equivalent
   narrowly authenticated bypass that still checks all instance/path/effect
   fingerprints and revalidates immediately before mutation. It must not weaken
   `Get-CurrentProjectRemovalAuthority` or ordinary `Uninstall`/current
   `Install` routes globally.
5. The existing RemoveIntegration preflight dispatch must return the same
   historical authority/token and the durable remove entry must consume it;
   no Manager/UI change or cached permit is needed. Existing removal-intent
   writer and terminal-state readers remain coupled consumers.

The canonical successor generator must be changed only in its allowlisted test
route to preserve exact original predecessor input and emit the new declaration.
The C#/Node transition parsers currently use required known fields but do not
reject an additional field; they do not independently authenticate historical
removal. Compatibility should be tested and recorded, but extra production C# /
Node edits are not justified unless a direct reader must expose the new field.
The focused host-materializer batch must cover missing/malformed/wrong declared
hash, tuple/project/epoch/operation tampering, same-sequence changed predecessor,
foreign/ambiguous holder refusal, intact old closure, and distinct successor
publication. This is the minimum contract/reader list, not a broad hardening
request.

## Disposition boundary

The diagnosis is sufficient to request approval for a new contract expansion
covering the two production PowerShell readers/entry gates and the canonical
generator plus focused fixtures. It does not authorize that expansion, add a
schema field, change runtime readers, remove the installed integration, or claim
source/runtime/release PASS. Existing old transitions without the declaration
must remain usable under their existing reviewed behavior and fail closed for
the new historical selected-v2 admission if they cannot prove the predecessor
runtime authority.

Review stops here. Findings are returned once to User/Planner; no Coder repair
was requested and no source/test/fixture file was modified.

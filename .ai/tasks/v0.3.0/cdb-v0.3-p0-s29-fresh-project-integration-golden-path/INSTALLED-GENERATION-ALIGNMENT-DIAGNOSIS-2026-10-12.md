# S29 installed generation / Package alignment — read-only diagnosis

Date: 2026-10-12. Status: DIAGNOSIS_COMPLETE / ROUTE_DECISION_PENDING.
User grant: "同意 我们继续" after the three-question read-only proposal.
Scope: exact generation difference, existing removal authentication, route
recommendation. No source repair, backend preflight execution or real mutation.

## Confirmed identities

- HEAD: 61408bc7e43a63edf2f717d299ee5da868a62894; exact Package source 74c4db0.
- S29 references the retained-disposition-74c4db0 exact extraction.
- Manifest/lock hashes remain c723ee546d1166dd8cec9274a804d57817dc0f544db3c7bd2560abb708db6046
  and 7defc8f775e20094fd9555711a68c78b224dd967b04a2c2cb289246df242b570.
- Desired state INSTALLED; selected instance d620abbab0334a2d9c49e59888c1ef55.
- Instance manifest actual SHA256 matches selection:
  664d0a7d99ce67c32f4537fecae076c3efcd0ac4e2aee8260957d4269302df62.
- Installed generation manifest actual and instance-recorded SHA256:
  2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026.
- Package generation manifest actual SHA256:
  944fab7055368870ab3a1fb4c5940e1d4b1ebe6b772a7e52d1bef728272af27f.
- Both identities use package 0.3.0-preview.5, payload/generation poc.42,
  sequence 42 and bootstrap protocol 1.
- Installed activation and operation are COMMITTED, bind the selected instance
  and old generation hash, and declare runtime contract
  538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d.
- Current delivery runtime-contract hash is 24bc8da5c9fb1914113b0d9270ecbb77285b09a7ce9f31841a6ac58906863604
  per the exact delivery record; current activation is not rewritten to it.

## Difference and provenance

Compared all 29 declared file entries: paths/count agree, and only
coordinator/codedb-watch-coordinator.mjs differs. All 29 installed files match
their own generation manifest. This is declared-file hash evidence, not full
path/ownership/holder authentication or a no-extra-files assertion.

Installed coordinator: 5a61242e336fac40ac5ce94729d71c676272f65510993481c80a0ee71651ed00.
Package coordinator: 928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09.

The complete coordinator diff is the accepted readiness repair: timeout cleanup
of the start-owned coordinator plus provider_start_phase observation. Git commit
1618d17 changed that file; 4cabfb9 changed its manifest entry from the old hash
to the new hash without changing generation identity. The earlier frozen
s29-post-install-ui-poc42 extraction contains the old entry and old manifest hash.
COORDINATOR-READINESS-REPAIR-TASK.md explicitly excluded generation/version
changes. Its delivery closed new-Package integrity, not installed-generation
handoff. Reference switching does not replace a selected immutable runtime.

Thus the installed declared files are internally consistent; the demonstrated
gap is two different immutable closures under one generation identity. This
diagnosis does not invalidate the accepted repair's focused source evidence or
claim that the corrected coordinator executed in the selected S29 runtime.

## Existing entry behavior — static evidence from exact Package

1. UninstallPreflight calls Get-CurrentProjectRemovalAuthority, then
   Get-InstanceSelectedInstance -> Get-ValidatedCurrentInstance ->
   Assert-InstanceGenerationClosure. Get-InstanceGenerationPackageIdentity treats
   matching version/sequence/generation fields as current, takes the Package
   manifest hash, and rejects the recorded/actual old hash as not Package-owned.
2. RemoveIntegrationPreflight calls Get-RemoveIntegrationAuthority ->
   Get-ValidatedRemoveIntegrationSelection -> Get-ValidatedRetiredInstance ->
   the same generation closure validator. It encounters the same hash mismatch.
   The separate historical activation reader already exists, but the earlier
   selection validation fails before that route can authenticate this case.
3. Ordinary activation validation also builds context from current Package
   authority and requires matching runtime-contract and target generation hash.
   Fixing only generation naming does not establish historical activation
   admission; historical context and record bindings must be covered together.
4. Manager requires RemovalPreflightPassed before offering either ordinary
   Uninstall or RequiresReinstall's Remove Integration entry. SAFE historical
   retained classification is not this preflight and does not authorize Install.
5. Publish-ImmutableGeneration reuses an existing generation directory only
   after Assert-GenerationDirectoryMatchesManifest passes. Retaining the old
   poc.42 after logical removal cannot permit new, different poc.42 bytes to be
   installed at the same immutable path.

These are deterministic source comparisons with actual recorded hashes, not a
claim that a live backend preflight was executed. No actual removability/holder
gate PASS is established. Unknown state and external holders remain protected.

Source anchors in the exact extraction:
- Tools~/codedb-instance-engine.ps1:2320, 2382, 3279, 3575, 3690, 5147.
- Tools~/materialize-codedb-host-payload.ps1:7492, 7548, 10281, 10556,
  10754, 12154, 12167.
- Editor/AICodedbManagerWindow.cs:2348, 2360.

## Recommended next bounded outcome — proposal only

Correct immutable identity and prove the controlled removal/fresh-install route,
without adding automatic in-place Upgrade or arbitrary historical migration:

- Preserve the original installed poc.42 closure from an attributable frozen
  Package as historical authority; do not copy/trust arbitrary live bytes merely
  because their own manifest matches.
- Put the corrected runtime in a distinct successor generation and sequence,
  with exact predecessor declaration and preserved historical bytes. Resolve
  the successor identity through the existing canonical generator contract;
  no number is selected or generation produced by this diagnosis.
- Reuse the existing removal entry and historical activation authentication,
  with explicit binding of Package-declared predecessor closure, selection,
  committed operation/activation, control contract, configuration and holders.
  Confirm the ordinary/historical entry routing before selecting implementation
  files; do not weaken CURRENT validation or runtime availability checks.
- Focused evidence must cover the actual selected-v2 predecessor, runtime/hash
  change, wrong/unknown/same-sequence identities, foreign/ambiguous holders,
  preserved inert predecessor and distinct new generation publication. A new
  generation alone is not proof of a working recovery route.
- Only after source review/acceptance and separately authorized delivery and
  operational gates: authenticated Remove -> Uninstalled -> current-Package
  fresh Install -> new activation -> real readiness observation.

Current Package removal/reinstall, reverting project references, overwriting
the old runtime, manually changing recorded hashes, cleanup, stopping processes
and replaying Install are not authorized alternatives. A reference rollback
alone would not solve the later same-path collision if old bytes are retained.
General cross-version Upgrade remains deferred. Old isolated candidates/history
cleanup and shutdown hang observation stay outside this proposed repair.

## Limits and handoff

No child agent, Unity launch/test, native/backend CLI, preflight, Probe, source
edit, install/removal, payload generation, export, reference switch, commit,
push, process control or cleanup was performed. Only this diagnosis record was
added. Existing dirty state remains protected. Git no-index diff exit 1 denotes
the observed coordinator difference, not failed validation.

Next: return the combined diagnosis to the user and align a bounded identity/
historical-removal task contract before implementation. This proposal expands
beyond the previous no-generation-change source envelope and is not execution
authority. S29/release remain PARTIAL; shutdown hang is user-deferred observation.

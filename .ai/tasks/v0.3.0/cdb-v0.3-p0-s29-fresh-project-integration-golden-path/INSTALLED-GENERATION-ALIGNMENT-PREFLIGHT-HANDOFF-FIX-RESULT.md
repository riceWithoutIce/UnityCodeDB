# S29 preflight to durable removal handoff — bounded fix scope

Date: 2026-10-12. Status: `SCOPE_GAP_CONFIRMED / SOURCE_UNMODIFIED`.
The user selected FIX for the single Verifier finding. This Coder pass mapped
the actual producer/consumer/handoff and stopped because the minimum repair
requires production C# and a new CLI transport outside the frozen five-file
allowlist. No workaround or synthetic shortcut was added.

## Actual producer and consumer chain

`materialize-codedb-host-payload.ps1 -Action RemoveIntegrationPreflight`
authenticates `Get-RemoveIntegrationAuthority`, validates managed config, and
prints only `[REMOVAL_PREFLIGHT] AVAILABLE`. `AICodedbHostPayloadMaterializer`
(`Editor/AICodedbHostPayloadMaterializer.cs:163-210`) invokes that CLI and
`HasAuthenticatedRemovalPreflight` accepts exactly one boolean line.

`AICodedbEditorLifecycle.WithRemovalPreflight` caches only the bool and diagnostic
into `AICodedbProductStatus.RemovalPreflightPassed`. The Manager confirmation
calls `AICodedbActions.RunRemoveIntegrationCodeDBAsync`, which checks the cached
bool and current integration/migration/instance state, then calls the parameterless
`RunRemoveIntegrationAsync`. That method builds a fresh `RemoveIntegration`
command without any preflight authority identity. The durable PowerShell entry
re-reads its own historical authority and fingerprint, so safety revalidation
exists, but the entry cannot consume the authority/token that admitted the UI.

## Minimum repair proposal — not implemented

1. `materialize-codedb-host-payload.ps1` should emit one authenticated,
   Package-bound preflight handoff document or token alongside AVAILABLE. The
   token must bind project identity, selected instance/generation/epoch,
   historical runtime-contract hash, owner fingerprint, managed-config plan
   fingerprint, and a bounded expiry/operation nonce. It must be test-owned in
   synthetic fixtures and consumed once by durable RemoveIntegration; no new
   persisted product schema is implied.
2. `AICodedbHostPayloadMaterializer.cs` must parse and expose that handoff from
   the preflight result, then append it to `RemoveIntegration` CLI arguments (or
   a test-owned handoff file path). Its existing boolean check remains for UI
   presentation.
3. `AICodedbActions.cs` must pass the cached handoff through the confirmed
   action while preserving its current project/migration/instance recheck.
   Durable PowerShell must compare the handoff against freshly recomputed
   historical authority at all existing entry/authority/pre-commit gates and
   reject absent, expired, foreign, consumed or drifted handoffs. Existing
   holder/config/effect/journal/fingerprint checks remain mandatory.

This necessarily edits two production C# files and adds a serialized CLI
transport/consumer contract. Those files are outside the approved source
allowlist; the task requires returning this concrete minimum scope before any
outside edit.

## Focused test closure needed after scope approval

- Extend the existing allowlisted
  `Tests~/test-codedb-host-payload-materializer.ps1` to exercise the actual CLI
  `RemoveIntegrationPreflight` output and `RemoveIntegration` handoff argument:
  valid continuity, absent/malformed/expired/foreign/consumed token, project/
  instance/generation/epoch/runtime/config/owner drift, and commit-time drift.
- Add a dedicated C# Editor test file
  `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs` (or an
  explicitly approved existing test file) to cover the real C# parser,
  `BuildRuntimeScriptArguments`, and `AICodedbActions` consumer. The protected
  `AICodedbManagerUiTests.cs` must remain untouched.
- Repeat only the original finding and adjacent regression cases after repair;
  do not rerun broad suites.

## Protection and limits

The eight original protected inventory hashes recompute unchanged. The current
dirty protected `com.rice.ai-codedb/Tests/Editor/OwnerIdentityV2Status.json`
hash is `3cdf6ac436264ff391acafd77999b8aa62966f5295b7481cb0c004ee3afcf6a7`,
which differs from the original recorded baseline; this pass neither attributes
nor modifies it. Existing implementation source hashes remain:

`7ee8ab147cd593028f68f0efe384308379a830d469831bd88b1bcaccc926e159`
`fceddf844adc38cbdea89893a551d497ee7197d5b411633c82d51742847acede`
`162d4a4c1c9fa0aaa144d74c12f877a8952e1fc26657a08a41ab32adb1d3ca38`
`3edfb9bf1506dfe9ff8b9eb1df6aa4e3a14917fd0b750ec15e923687d0428eb4`
`9f368e6f675243d8391d1df272423f40afa0e000c6412d23169ffcf662689323`.

No source, candidate, real project, Unity, CLI operation, process, commit,
export, cleanup or package/reference state was changed. The existing candidate,
implementation result, projection manifest and Verifier finding remain intact.

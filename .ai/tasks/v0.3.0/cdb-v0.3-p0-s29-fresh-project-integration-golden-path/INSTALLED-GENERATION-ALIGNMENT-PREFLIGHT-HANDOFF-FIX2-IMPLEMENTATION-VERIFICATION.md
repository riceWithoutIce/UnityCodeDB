# S29 preflight-to-durable-removal handoff FIX2 — implementation verification

Date: 2026-10-12. Review mode: guarded, read-only. Verifier verdict:
**PASS_WITH_LIMITS**.

This review is limited to the prior F1 durable-entry bypass, F2 direct-entry
evidence gap, and their nearest regressions. No source, project, payload,
receipt, Unity state, or protected baseline was modified. No Unity, live CLI,
process control, real Remove/Install/Uninstall, export, reference switch,
commit, push, publication, or cleanup was run.

## Snapshot admission

- Candidate: `.artifacts/tests/s29-generation-alignment/fix2-a4/com.rice.ai-codedb`.
- All five source/test hashes match
  `INSTALLED-GENERATION-ALIGNMENT-PREFLIGHT-HANDOFF-FIX2-SOURCE-SHA256.txt`.
- `focused-a4.log` matches the projection manifest: SHA256
  `12ec4821ab97703753ec11413d75056fe686c3410c2a98acbcc59dedaf8d32f2`,
  6569 bytes.
- The retained result is `GENERATION_ALIGNMENT PASS cases=35
  native_children=0 PocFixture=true external_process_observation=synthetic`.
- PowerShell AST parsing reports zero errors. The supplied Coder `git
  diff --check` result is retained as evidence. These checks admit the source
  snapshot and synthetic evidence; they do not establish Unity, live runtime,
  or release acceptance.

## F1/F2 closure

`Invoke-RemoveIntegration` now consumes `PreflightHandoff` at its own durable
boundary. Before failed-candidate recovery, lock recovery, or empty-directory
cleanup it resolves `Get-RemoveIntegrationAuthority -AllowMissing`, rejects a
missing authority with an explicit no-cleanup/no-recovery conflict, requires a
non-empty handoff, and validates it against the current authority and managed
configuration. After the materializer lock is acquired, it repeats authority,
configuration, and handoff validation before historical admission, recovery,
cleanup, or mutation. The pre-mutation callback retains the existing
historical next-change fingerprint and owner/instance revalidation.

The `UNINSTALLED` early route now passes `-PreflightHandoff` into the durable
function (`materialize-codedb-host-payload.ps1:12114-12117`). A no-authority
`UNINSTALLED` state fails closed before cleanup or recovery, and the focused
fixture verifies the project digest is unchanged. The durable direct-entry
fixture covers valid removal, missing handoff, expired handoff, authority
drift, configuration drift, and the no-authority terminal case. The prior
29-case alignment evidence is retained and the new run reaches 35 cases.

No blocker or material follow-up finding remains in the reviewed F1/F2 scope.

## Preserved contract checks

Static review and retained focused evidence confirm that Package-declared
historical runtime authority remains separate from successor `poc.43`, the
original `poc.42` immutable bytes remain retained, and a fresh successor
instance is published at a distinct identity/path. The three historical
`Assert-InstanceNextChangeAdmission -HistoricalRemoval` gates remain in the
durable removal path (lock-entry, operation admission, and pre-mutation
callback). Ordinary current-strict Uninstall and generic next-change admission
still reject the historical activation mismatch. C# preflight parsing and
argument propagation continue to require and forward exactly one handoff.

## Protected state and limits

The protected working-tree `OwnerIdentityV2Status.json` remains drifted from
its recorded baseline (`3cdf6ac436264ff391acafd77999b8aa62966f5295b7481cb0c004ee3afcf6a7`
versus `4c0761b6c58e98ec49f8c05a056d63c3be875fc8287dfed7b9e01e568cc51038`).
This drift is outside FIX2, was neither attributed nor changed, and remains a
delivery limitation. The focused run is synthetic and reports
`external_process_observation=synthetic`; C# compilation, Unity EditMode,
Manager UI, live readiness, real removal, fresh real installation, package
export/reference switching, and release gates remain unrun. Therefore this is
`PASS_WITH_LIMITS` for the bounded source/synthetic repair only; S29 and
release acceptance remain PARTIAL until their separately authorized gates are
completed.

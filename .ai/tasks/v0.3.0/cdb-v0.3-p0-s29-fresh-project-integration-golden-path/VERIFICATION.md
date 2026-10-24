# S29 historical handoff capability — Verifier report

Date: 2026-10-13  
Role: read-only Verifier; review limited to the five Coder allowlisted files and direct evidence named by the frozen task.  
Verdict: **PASS_WITH_LIMITS** for terminal snapshot integrity; the `RequireReady` wording issue remains a `FOLLOW-UP`, and deferred runtime/release gates remain outside this review.

## Admission and integrity

- Base SHA in the task, route reassessment, RESULT, and terminal SHA record is `9eac17cfdb741f89d33a4b7c2ddf6261abcb9566`; `git rev-parse HEAD` matches it.
- The changed path set is exactly the five allowlisted files recorded in RESULT: `AICodedbProjectIntegrationState.cs`, `AICodedbEditorLifecycle.cs`, `codedb-instance-engine.ps1`, `AICodedbEditorLifecycleTests.cs`, and `test-codedb-host-payload-materializer.ps1`. No sixth changed path was found in the Base-to-HEAD diff for this set.
- All five updated terminal SHA-256 entries match the current files exactly, including `AICodedbEditorLifecycle.cs` at `c0ac0acf5f28726940f59b5baa51dec3cbe35b31b9538112eb8b95c851704a24`. The superseded `a8712d0be...` value is retained in the SHA record only as historical evidence for the intended `DeleteEditorLease` correction.

### Snapshot integrity — PASS_WITH_LIMITS

Evidence: the updated `HISTORICAL-HANDOFF-CAPABILITY-SOURCE-SHA256.txt` records the Base and five terminal hashes, and the live read-only hash check matched all five. `git rev-parse HEAD` remains the recorded Base SHA. The five allowlisted source files are still the only changed production/test paths in the scoped Base-to-HEAD check. This closes the prior snapshot-integrity blocker; no source repair or hash rewrite was performed by Verifier.

## Scoped semantic review (conditional observations)

The current diff is directionally consistent with approved outcome A:

- `AICodedbProjectIntegrationState.cs` makes `TrustedPrevious` unable to publish an Editor lease (`CanPublishEditorLease => IsCurrent`) and changes its detail to controlled removal/reinstall.
- `AICodedbEditorLifecycle.cs` has an early `TrustedPrevious` branch that clears the automatic-start and lease-prerequisite flags, deletes the lease, projects removal preflight, and records blocked convergence. `BackendNeedsReconcile` returns false for `TrustedPrevious`, so repeated scheduled reconciliation does not select a Deploy/Upgrade convergence plan. Missing and current paths and the existing v1 obsolete branch are unchanged in the Base diff; generic activation/Upgrade validation is outside the changed files.
- The dedicated `poc.33` test now asserts `TrustedPrevious`, `CanPublishEditorLease == false`, an empty lease path, `ShouldPublishEditorLeaseForInstance == false`, and `Blocked` convergence (`AICodedbEditorLifecycleTests.cs:3717-3754`). The fixture writes the v2 owner/activation fields when `legacyOwnerIdentity` is false; it is synthetic classification evidence, not Unity/runtime proof.
- The PowerShell fixture removes the deferred Upgrade/drain mutation and checks the retained historical instance/generation/lease bytes remain unchanged. The normal Probe marker now describes controlled removal/reinstall and says automatic handoff is unavailable.
- `WithRemovalPreflight` remains the only path used to project removal availability for this branch; no removal button/permit is opened from historical identity alone.

These observations remain limited because the Coder RESULT records semantic compile/PowerShell syntax only. The focused runner stopped at its pre-existing `RetainedDispositionOnly` prerequisite and GenerationAlignmentOnly stopped at its fixture-binding assertion; Unity/NUnit, live Probe/Provider, lease/reopen behavior, and real Remove/Install/Upgrade were not run.

## FOLLOW-UP — stale `-RequireReady` Probe error wording

`Tools~/codedb-instance-engine.ps1:5420-5433` emits the new controlled-removal marker, but the same `TrustedPrevious` branch still throws `Current instance availability probe requires handoff from the trusted previous generation.` when `-RequireReady` is set (`:5430-5432`). The direct Probe dispatch passes `-RequireReady` (`Tools~/materialize-codedb-host-payload.ps1:12211-12229`, read-only context). Thus a failing previous-v2 Probe can still expose the superseded handoff wording even though its normal status marker is corrected. This is a wording/diagnostic consistency issue, classified FOLLOW-UP because it does not by itself grant lease, start, Deploy, Upgrade, or removal authority.

## Limits and deferred gates

No Unity, MCP, BatchMode, CUA, Provider/IPC, live Probe, process control, real mutation, Install/Upgrade/Remove/Uninstall, package export, commit, or cleanup was performed. Source/static evidence cannot establish C# compilation in Unity, focused NUnit execution, reopen stability, runtime/provider behavior, consumer acceptance, or release acceptance. The current report therefore does not convert the Coder's L0 PASS claims into S29 or release acceptance.


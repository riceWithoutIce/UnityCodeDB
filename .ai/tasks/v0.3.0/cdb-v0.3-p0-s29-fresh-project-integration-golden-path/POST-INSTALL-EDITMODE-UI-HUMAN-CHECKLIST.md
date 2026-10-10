# S29 post-install human validation

2026-10-10. Source commit 954384d0e8a6f338b68ce181bc4882099412cb34. Package: `.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb`. ZIP SHA256 `179aef72ff1dface2455773e7e5d0c69a870b1a553a670b0fc16bb170759ce3f`. S29 manifest/lock already select this exact extraction. Compilation, standalone/source checks and original successful installation are different evidence classes.

## Human steps

1. Open UnityFreshInstallValidationProjectS29 and wait for import/compilation. Report any C# error or new relevant warning; no Install or Uninstall click is needed.
2. In EditMode Test Runner, filter and run these six methods in AICodedbProjectSettingsTests (eight cases total):
   - ManagerActionJournal_SuccessWithCleanupPendingReleasesExactIndexAndRetainsTrace
   - ManagerActionSession_ReleaseFailureRetainsSpecificAuthenticationDetail
   - CachedEditModeProductStatus_DoesNotClaimPlayOrNewVerification
   - LifecycleRetirement_UsesNewReadinessObservationInsteadOfCleanupOutcome (two cases)
   - RetainedFreshWrapperHandoff_AcceptsProducerNullAndRejectsUnboundPreimage
   - UserActionStatus_NoStageOutputKeepsIndeterminateActivityUntilTerminal (two cases)
3. Open Manager, remain in EditMode for approximately two minutes, and reopen it once. Check there is no false Play explanation. A current authenticated Ready observation should remain distinct from historical cleanup Pending; if current availability genuinely fails or evidence expires, its specific status/detail must remain visible. Report repeated Ready/unconfirmed/NeedsAttention transitions and their displayed reason rather than accepting an unconditional Ready label. Old failed/unknown actions may remain visible as history.
4. Report whether the successful action dc72675b... still appears to block new changes. Parent will perform the read-only receipt/index comparison after your report to establish actual matching terminal recovery/release. Do not manually delete records or click an operation to test admission.

## Limits

The tests prove progress presentation states, not native animation. No new real Install/Uninstall is requested solely to create a progress screenshot. Native running-operation animation stays unverified until an otherwise necessary separately confirmed operation supplies that evidence. Do not repeat the previous long actual-PowerShell fixture for this scope; its prior evidence is retained and the new handoff reader was independently exercised on cloned actual receipts.

No manual PowerShell, Windows restart, process termination, history cleanup or Codex session rebinding is required for this gate. Opening Unity can run its existing authenticated maintenance/recovery; parent does not substitute automation for human Unity validation. S29 remains PARTIAL until the declared human evidence is recorded.

# S29 compact receipt layout - one human validation cycle

Status: READY / HUMAN_NOT_RUN. Source ACCEPT is not Unity or integration PASS.
Project: G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29.
Package: .artifacts/s29-receipt-layout-poc40/review/com.rice.ai-codedb.
Commit: df91ef6a279ba0ffd3387ff00369137a5878df04.
Version0.3.0-preview.5 / poc.40. Both project references already switched after
human-confirmed closure and artifact gates PASS. No uninstall/reinstall required.

## One opening, focused EditMode evidence

1. Open the S29 project normally and wait for import/compile. Require zero C#
   compile errors; if any occur, stop and provide the first complete error.
2. Open Test Runner -> EditMode. Run the methods below (34methods/80cases).
   Search by method name; if the whole class includes unrelated tests, select
   only listed methods. Keep Unity open while collecting results.
3. Record passed/failed/total for the selected set. For any failure provide its
   full method/case name and first exception/stack. Do not repeat unchanged tests
   or manually create/delete scratch paths. Do not run unrelated full suites.
4. After test success, open CodeDB Manager, allow the existing checking pass to
   settle, switch tabs and close the Manager window. Report display/Console errors
   and whether switching/closing behaves normally. Existing real integration
   failure/PENDING history may remain; this task does not promise Ready or unlock.
5. No Install, Remove, Redeploy, Configure, recovery/replay or other mutation
   buttons during this cycle. Human may close Unity normally after observations
   and report closure. No Codex restart/rebind or Windows restart is required.

## AICodedbProjectSettingsTests:24methods /68cases

| Method | Cases |
| --- | ---: |
| ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory |4|
| ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects |7|
| ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain |11|
| ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate |4|
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage |8|
| ManagerReceipt_ConflictWithoutAuthenticatedContextLabelsOriginalUnavailable |1|
| ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown |3|
| ManagerActionJournal_RestoresOriginalIdAfterFullExitAndPackageReplacement |1|
| ManagerActionJournal_CorruptOrConflictingIndexFailsClosed |1|
| ManagerActionRecovery_ClaimWithoutTerminalStaysUnknownAndStartFailureIsDistinct |1|
| ManagerActionJournal_HistoricalUnknownMarkerReleasesOnlyBoundPendingStage |1|
| ManagerReceipt_CompactMissingOrWrongLayoutIsConflict |6|
| ManagerReceipt_DuplicateOrPrefixCollisionCannotReplaceAdmission |2|
| ManagerReceipt_CompactFullIdentityAndLocationsFailClosed |4|
| ActionContext_FlowsCapturedProjectAndPackageToWorker |1|
| ManagerActionSession_RejectsOverlapAndRetainsResultAcrossWindowInstances |1|
| ManagerActionSession_ReloadRestoresUnconfirmedOutcomeWithoutRetry |1|
| ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission |1|
| ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation |5|
| ManagerActionSession_ProviderSuccessKeepsCommandAndNeedsAttentionSeparate |1|
| ManagerActionSession_WindowCloseWithCommandRetainsResultWithoutClaimingReady |1|
| ManagerActionSession_WindowCloseWithoutCommandKeepsRecoveryAdmissionBlocked |1|
| ManagerActionSession_MissingCommandResultCannotReleaseAdmission |1|
| ManagerActionSession_UnconfirmedTransportFailureKeepsRecovery |1|

## AICodedbTestWorkspaceTests:10methods /12cases

| Method | Cases |
| --- | ---: |
| TestWorkspace_OwnedRootUsesActualProjectAndProbesCapabilities |1|
| TestWorkspace_ProbesS29DepthUsingProductionPaths |1|
| TestWorkspace_ExclusiveCollisionPreservesExistingOwner |1|
| TestWorkspace_OverlongComponentReportsExactPathWithoutFallback |1|
| TestWorkspace_UnavailableCapabilityFailsBeforeBodyWithoutFallback |3|
| TestWorkspace_CleanupRejectsOutsideTargetAndChangedOwnership |1|
| TestWorkspace_ReparseBoundaryIsRejectedBeforeTraversal |1|
| TestWorkspace_PrimaryFailureRestoresRegisteredScope |1|
| TestWorkspace_PrimaryAndCleanupFailuresRemainSeparate |1|
| TestWorkspace_CleanupOnlyFailureCannotPass |1|

The original FIX01 result/verification define these authored counts. Compile and
test results are pending; artifact closure and PS writer12/12 are separate evidence.

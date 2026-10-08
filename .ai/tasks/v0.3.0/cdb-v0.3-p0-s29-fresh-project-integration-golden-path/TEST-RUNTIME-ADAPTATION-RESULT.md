# S29 test runtime adaptation - Coder result

2026-10-08. Stable source snapshot ready for parent admission and bounded independent
review. HUMAN_COMPILE_DISCOVERY_TEST_PENDING. Latest human acceptance remains failed;
source checks do not resolve S29 integration or release acceptance.

## Changes

Only three allowed test files changed. Shared workspace now uses the actual Unity
project's Library/cdt/<8 lowercase hex>, retaining the full32hex owner, exclusive
parent reservation, one allocation attempt, no adoption and bounded owned cleanup.
No previous test directories were migrated or removed.

The explicit default capability is Compact. CompactAndLegacy additionally probes
all four old record names using production helpers with null layout and the full
Project24/Package24/Action32/Stage64 hierarchy. Only the two existing legacy receipt
tests opt into it before their bodies. Their business assertions are unchanged;
ManagerUiTests diff is exactly two profile-selection lines.

Compact probes retain actual production record, temp and journal paths. Legacy
probes do not append unused writer temp suffixes or run a historical writer.
Every probe performs actual System.IO create/read/delete when later run in Unity.
Newly created probe directories are tracked and only those empty owned directories
are removed before the body. Errors include profile/layout, operation, full path
and length; outer setup includes the detail, restores receipt scope and retains
existing primary/cleanup failure handling. No numeric product admission gate or
alternate root is introduced.

Two distinct parameterless UnityTest IEnumerator entries replace the parameterized
Task-returning entry. Both call the same original async helper, yield while its Task
is incomplete, then GetAwaiter().GetResult() only after completion to propagate fault
or cancellation. Workspace capture remains before the first await on the Editor
thread. The Task.Run/await assertion body is byte-for-byte unchanged after newline
normalization; the separate identity-reset context test stays in the same class.
No async void, blocking wait, framework/asmdef change or assertion suppression.

## Evidence and limits

- One PathProvenanceOnly run: PASS, including existing helper projection checks.
- One scoped git diff --check: PASS.
- Source consistency: two explicit legacy callers; original async body unchanged.
- Merged manifest below independently counted from source:39 methods /88 cases.
- All nine baseline hashes matched FIX01. Final identity shows exactly three test
  changes and six unchanged production/script files. HEAD and index unchanged.

Unity import/compile, Test Runner discovery, all88 test executions and actual Unity
System.IO measurements are NOT RUN. No C# substitute, Unity/MCP/CUA/BatchMode or
process probe. Prior writer12/12 remains evidence at unchanged script hashes;
neither writer nor parser batch was rerun. No live project/reference, production
code, scripts, package/generation, old artifacts, commit or export was modified.

The frozen S29 project arithmetic is legacy admitted247/start-failure252, a13-char
reduction from the previous260/265. The new profile test uses the actual run root
when already at least85 characters; shorter test projects get an explicitly owned
representative root of at least85. It checks all four exact legacy paths including
start-failure and logs actual maximum path/length. Compact profile requires at
least191 there; the retained older compact-only204 representative test stays.
These are authored assertions and calculations, not measured Unity results.

New tests: profile selection and deepest paths (2 cases); legacy create/read/delete
failure diagnostics, fail-before-body, scope restoration and cleanup (3 cases).
The existing default-root test additionally proves default compact does not probe
legacy. Existing ownership, collision and primary/cleanup tests remain.

## Exact merged human manifest:39 methods /88 cases

The original34/80 is retained. The earlier2 async cases are renamed into2 wrapper
methods, plus the existing identity-reset case:37/83. Two new workspace methods
add5 cases:39/88. All entries below are NOT RUN.

### AICodedbProjectSettingsTests -24 methods /68 cases

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

### AICodedbTestWorkspaceTests -12 methods /17 cases

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
| TestWorkspace_ProfileProbesFullPathsBeforeBodyAndRemovesProbeDirectories |2|
| TestWorkspace_LegacyCapabilityFailureReportsExactPathAndRestoresScope |3|

### AICodedbS29ExecutionContextTests -3 methods /3 cases

| Method | Cases |
| --- | ---: |
| LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait_Terminal |1|
| LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait_Nonterminal |1|
| ActionContext_NewIdentityResetsStageAndRestoresOuterScope |1|

## Identity and procedure

HEAD:df91ef6a279ba0ffd3387ff00369137a5878df04; branch:
codex/v0.3.0-legacy-workflow. Git index SHA256:
DB534FC6FA1C87089AA41937D3F941A8129BF11BF9807CF7DA488ADDD093BFA0.
TEST-RUNTIME-ADAPTATION-IDENTITY.json captures all nine baseline/final SHA256 values.

Initial task-card read emitted101 lines, exceeding the80-line bound; one combined
source command returned93 lines although each slice was at most80. No truncation;
these are recorded breaches, not retroactive compliance. An initial read-only hash
command had a PowerShell pipeline syntax error before executing; its corrected
command then captured baseline. Planned checks each ran once, no unchanged rerun.

Stopped at the stable three-file snapshot. Parent owns checklist/docs and any later
delivery. Independent review remains limited to these two failure classes and
immediate regressions; human compile/discovery/execution remains a separate gate.

# S29 compact receipt layout - Coder result

2026-10-08. Stable source snapshot ready for parent admission and independent
source review. HUMAN_COMPILE_TEST_PENDING. No Unity, C# compiler, MCP, CUA,
real Host/Provider invocation, live receipt/journal access, package export,
reference switch, commit or push was performed.

## Snapshot and scope

Base/final HEAD: `332c7ffd510daebb6da6a386d66783d4aabf6bd6` on
`codex/v0.3.0-legacy-workflow`. Git index SHA256 unchanged:
`C23240C3B59C82E0E7F794A030D47DF1A8E68657A553AA308AC60F456B07FD65`.
RECEIPT-LAYOUT-IDENTITY.json records exact baseline/final hashes for all nine
existing allowed files and the eight changed source/test paths. Lifecycle tests
need no changed caller: their existing context API remains compatible; file is
byte-identical. Coder also owns these two result/identity artifacts.

Parent corrected the initial nonexistent AICodedbManagerActionSession.cs entry:
Session is embedded in ManagerWindow.cs, and its existing layout-binding allowance
now applies there. No extraction or additional implementation file was introduced.
Inherited dirty docs, real projects, historical artifacts and machine state were
not edited by this Coder. This is edit-scope evidence, not a full protected-tree
byte comparison against a separately captured protected baseline.

## Implemented behavior

- AICodedbPaths owns Action32/Stage16.kind.json derivation; full64 Stage and full
  project/Package identity remain in records. New records use storage_layout
  compact-v1; schema meanings remain unchanged. Absence is accepted only through
  explicit legacy record/path handling; unknown or compact-missing layout fails.
- Project journal stays lookup/admission authority, retains original context and
  layout, and addresses resolved compact actions directly. Legacy discovery stays
  project-scoped. Old/new location conflicts fail; no machine-wide action scan.
- Admission publishes action.json exclusively under journal ownership, then
  publishes stages using no-overwrite atomic moves. Existing stages cannot replay;
  complete-stage prefix collisions are reported. Concurrent failed publication
  observing existing evidence stays unconfirmed, never proves no effects.
- Recovery reads compact and explicit legacy stages, including pending and special
  historical schema2 evidence. Manifest/full identity mismatches fail. Existing
  business result and failed-INSTALL/PENDING classification remains in its original
  recovery route. Compact enumeration is bounded to32 stages/129 files.
- PowerShell ReceiptPath now requires the exact compact admitted FILE. It validates
  machine-root confinement, manifest, full identities and command binding before
  claim/launch, and publishes claim/results exclusively. Legacy/directory arguments
  are refused. No arbitrary-root CLI seam was added.
- Unity fixtures use one12-hex workspace, full32-hex owner, exclusive parent
  reservation and no receipts-GUID wrapper. The entry probes actual production
  path shapes with System.IO create/read/delete. Cleanup ownership, primary failure
  preservation and separate cleanup failures remain explicit. Direct legacy tests
  retain legacy layout while moving their scratch into the owned workspace.
- Focused PowerShell fixtures copy the writer into an owned checkout-local Package.
  Only child ProcessStartInfo receives private LOCALAPPDATA/TEMP/TMP. Synthetic
  child lifetime and bounded cleanup stay owned; no parent/user environment change.

## Executed evidence

Windows PowerShell5.1 parser: both touched scripts PASS, zero parse errors.
PathProvenanceOnly PASS, including existing three helper projections and direct
PS/Node instance-contract bindings. Scoped git diff --check PASS.

ManagerActionWriterOnly final batch PASS12/12:
success, failure, timeout, overflow, inherited-output-handle, start-failure,
identity-rejected, replay, full-identity-collision, wrong-layout, deepest-path,
legacy-argument. Every command is synthetic. Rejected scenarios preserve existing
claim/evidence and do not launch a business child. Final script hash is in IDENTITY.

Attempt history is retained here: initial batch stopped before writer launch when
the deep-probe array expression combined paths incorrectly (NotSupportedException,
path format unsupported). One parentheses correction produced12/12 PASS at196
characters. The final authorized corrected batch strengthened the dedicated deep
root and passed12/12 at227 characters. No unchanged rerun; first scenario had at
most initial+two corrected attempts, later scenarios at most two executions.
Owned fixture trees/reservations were removed by each batch's scoped cleanup.

No C# code, Editor test, runtime integration or S29 acceptance was executed.
PowerShell and source checks are not Unity or release PASS.

## Path accounting

Let R be the full authorized receipt-root length. Action32 adds33 characters.
The following values include separators; test-root98 is the observed S29 shape.

| Path | Added to R | S29 calculated length |
| --- | ---: | ---: |
| action.json |45|143|
| action.json + C# .GUID32.tmp |82|180|
| Stage16.admitted.json / terminal.json |64|162|
| Stage16.claim.json |61|159|
| Stage16.start-failure.json |69|167|
| longest evidence + C# .GUID32.tmp |106|204|
| Action32/r.GUID32.tmp (PowerShell) |72|170|
| project24/current-action-Action32.json |78|176|
| project24/resolved-action-Action32.json |79|177|
| project24/index.lock |36|134|
| root/index-GUID32.tmp (actual journal publication) |43|141|

Journal temps are already at the receipt root, not appended to current/resolved
filenames. Actual isolated PS System.IO maximum227; actual Unity System.IO maximum
is NOT RUN. The authored S29-depth Editor test requires at least204 and uses the
production required-path helper; a256-character component exercises actual API
failure reporting without a fallback. No arbitrary200/240 product limit, OS
setting, alias, privilege or Unity patch requirement was introduced. Production
preflight resolves every required complete path through the runtime Path API and
reports the exact failed path and length; file publication failures precede launch.

## Immutable-generation and historical closure

Package remains0.3.0-preview.5; active generation remains poc.40. Payload manifest
has52 file entries and generation manifest25; neither directly references Tools~
or invoke-codedb-manager-action. Tools writer is outside immutable generation.
Package/payload/generation/pointer and historical materializer were not changed.
The materializer's Get-HistoricalUnknownActionEvidence and its directly coupled
fixture still bind historical Action3049af7.../Stage b571e3... to the old project24/
Package24/Action32/Stage64 admitted+claim pair. That narrow legacy reader remains
unchanged and was inspected, not executed or silently converted.

## One later human Editor cycle:34 methods /80 cases

All below are authored/retained, NOT RUN. Methods except TestWorkspace_* are in
AICodedbProjectSettingsTests (ManagerUiTests.cs); workspace methods are in
AICodedbTestWorkspaceTests. Preserve original business assertions.

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

## Procedure notes and handoff

Early read commands exceeded the200-line command cap: combined contracts304 lines,
one combined declaration/journal read220, and one reader slice207. No tool output
was truncated; these breaches are not retroactively compliant. Subsequent reads
were narrowed. Parent explicitly increased the cumulative Coder read-output budget
to256KiB for the nine-file closure; no write/test/live scope was expanded.

No architecture/allowlist expansion remains requested. Stop at this attributable
snapshot. Parent admits it; independent Verifier reviews this contract and adjacent
regressions only. Human compile/test and any later packaging remain separate gates.

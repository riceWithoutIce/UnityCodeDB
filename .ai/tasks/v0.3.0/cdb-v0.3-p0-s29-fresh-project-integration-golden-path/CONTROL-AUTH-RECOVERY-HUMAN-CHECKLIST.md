# S29 control authentication recovery: human Unity checklist

2026-10-10. Commit `7c82ff46997417a82ccceedcf0f846afd8dcda93`.
Project: `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.
Manifest/lock already select `.artifacts/s29-control-auth-recovery-7c82ff4/review/com.rice.ai-codedb`.
ZIP SHA256: `24034e4e90b28c3fdfddfae0f07d0e9924d13abf9f4ea78958158eae5b4a3888`.
Prior Unity results belong to earlier packages; do not relabel them as this run.

## Human steps

1. Open this existing S29 project and wait for import/compilation. Report C#
   errors or new relevant warnings. Do not click Install, Uninstall or Reinstall.
2. In EditMode Test Runner, run these 14 focused methods (30 parameterized cases
   in the standalone runner). Search across the package's Editor test fixtures;
   the methods are not all in AICodedbProjectSettingsTests:

   - Read_ClassifiesLiveTransportSeparatelyFromInvalidAuthority
   - ControlAuthenticationRetry_PublishesBoundedRecoveryWithoutAdmittingProbe
   - ControlAuthenticationRetry_CancellationAndInvalidEvidenceStopRetries
   - SupervisorResponse_TimeoutProvenanceSurvivesConversion
   - TerminalConvergenceFailure_RejectsTransientMissingAndOlderEvidence
   - TerminalConvergenceFailure_ClearsOnlyForNewerAuthenticatedReadyEvidence
   - ControlContractMigration_UsableStatesPreserveAutomaticConvergenceWithoutAdmissionDryRun
   - ControlContractMigration_TrustedIndependentPrerequisiteMapsBlockedStateWithoutCoordinatorProbe
   - ControlContractMigration_ColdStartMissingPrerequisiteTakesPriorityWithoutReinstall
   - ControlContractMigration_UninstalledKeepsInstallSemanticsWithoutAdmissionDryRun
   - ControlContractMigration_InvalidIntegrationKeepsExistingAttentionWithoutAdmissionDryRun
   - ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence
   - ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal
   - ManagerReadyFreshness_SharedAcrossDisplayCacheAndExpiry

3. Open Manager, remain in EditMode for about two minutes, and note readiness
   transitions and their diagnostics. Close and reopen Manager once; observe
   for about another minute. Report whether it returns to authenticated Ready
   and whether NeedsAttention repeats or Starting persists. A brief Starting
   transition while authentication is pending is allowed. Exhausted retries must
   show a temporary authentication-unavailable diagnostic; malformed/foreign
   contract evidence must still be rejected. Do not expect stale Ready to stay
   pinned, and do not require continuous Ready when live availability fails.
4. Close Unity normally once and report whether a crash recurs. If a relevant
   failure or crash occurs, preserve its screenshot/log/time and stop this run;
   no automatic retry or extra repair is part of this checklist.

The five full-worker regression cases are standalone harness evidence, not five
additional discoverable Unity NUnit methods. No fault injection into the real
project, real receipt mutation or manual PowerShell operation is requested.

## Return and read-only follow-up

Report compile result, focused test counts/failures, Manager transitions before
and after reopen, normal-close result, and approximate local observation times.
After that report, parent performs bounded read-only receipt/index and lifecycle/
Supervisor log checks, attributing evidence to this exact package/session.
Human UI evidence and durable IPC/lease evidence remain distinct; idle Manager
does not validate running Activity animation or all release requirements.
S29/release closure requires a later explicit acceptance assessment.

# S29 Manager admission — prepared human Unity checklist

Date: 2026-10-12. Status: FOCUSED_HUMAN_GATE_PASS_WITH_LIMITS / shutdown confirmed.
Results are recorded in MANAGER-ADMISSION-HUMAN-RESULT-2026-10-12.md; this is
the completed checklist, not a request to rerun the gate.
The earlier session-recovery failure is recorded in
MANAGER-ADMISSION-HUMAN-FAILURE-2026-10-12.md. This checklist applies to the
new repaired package below; if any listed check fails, stop and preserve the
failure without retrying an operation.

Latest exact package for the next gate:

- Source commit: `3077ee61d6124bacc1e4989cff9f4c50cf0db466`.
- Package reference after the separately authorized switch:
  `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-manager-admission-3077ee6/review/com.rice.ai-codedb`.
- ZIP SHA256:
  `fb0688bd1b759021812435427decce2c64e6903286c4ab47fd4aab1fcacb56d6`.

The previous package remains recorded historically. The S29 project was closed,
the two package references were switched once, and the new target was verified.
Do not repeat the switch.
The authorized delivery preparation and reference switch are complete. The human
controls the Unity acceptance session; this checklist does not authorize package
operations or automated Unity execution.

## Exact target

- Project: `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.
- Source: `3077ee61d6124bacc1e4989cff9f4c50cf0db466`.
- Package reference:
  `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-manager-admission-3077ee6/review/com.rice.ai-codedb`.
- ZIP SHA256: `fb0688bd1b759021812435427decce2c64e6903286c4ab47fd4aab1fcacb56d6`.

The user confirmed S29 was closed. The parent backed up manifest.json /
packages-lock.json under `.backups/s29-manager-admission-3077ee6`, switched only
the CodeDB reference in both files, and verified both references and the exact
package. The switch must not be repeated. The human now controls Unity launch
and all tests; no MCP/CUA/BatchMode replacement.

## Minimal human checks after the switch

1. Open the same S29 project and wait for import/compile. Confirm no new C# errors
   and the resolved Package path matches the exact target above.
2. In EditMode, run only the nine methods below in AICodedbProjectSettingsTests
   (21 cases total, including the new domain-reload regression). Record pass/fail
   separately from compilation.
3. Open Manager. Confirm history recovery explains the existing ownership
   ambiguity rather than calling a valid 32-character instance directory invalid.
   Candidate `330b7a972a7649259409fbce4de8ca56` has origin action `73c9...`, whose
   attribution remains unproved. New changes should stay blocked; Install may
   correctly remain hidden. Ready status alone is not mutation permission.
4. Close/reopen Manager once, observe about one minute, and verify the conflict
   explanation remains coherent. Record any new reason or unexpected state
   change; sustained Ready is not required while current readiness is unproved.
5. Switch the usual Manager tabs, then close Unity normally. Record exceptions,
   compilation failures or crash. On a key failure, stop and preserve evidence;
   do not retry an operation.

Focused methods:

- ManagerActionJournal_ValidInstanceIdsPreserveCurrentAndLegacyAdmission (4 cases)
- ManagerActionJournal_InvalidInstanceDirectoryStillFailsClosed (3 cases)
- ManagerActionJournal_UnownedProvisioningCandidateBlocksHistoryRecovery (1 case)
- ManagerActionJournal_CurrentIndexWithUnownedCandidateStaysConflict (1 case)
- ManagerActionSession_DurableRetainedResultReplacesStaleRecoveringSession (1 case)
- ManagerActionSession_DurableRetainedResultClearsPendingAfterDomainReload (1 case)
- DirectCandidateArguments_BindActualActionBeforeAdmission (3 cases)
- CandidateArguments_RequireManagerActionAttribution (6 cases)
- LifecycleUpgradeArguments_PreserveDirectBootstrapAttribution (1 case)

Do not run ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession
in this minimal gate: it launches the complete PowerShell producer fixture and
belongs to a separate bounded validation scope.

## Operation boundary and follow-up

Do not click Install, Uninstall, Remove Integration or Configure in this gate.
Do not rewrite receipts/candidates/control/cleanup state or stop external holders.
The existing old-project orphan is not a button-restoration acceptance target.

After the human report, the parent performs bounded read-only log/journal checks
as needed to attribute the observed conflict and record results against this
exact package. Basic UI PASS does not prove complete retained producer behavior,
real install/removal/reinstall or release. S29 / release remain PARTIAL.

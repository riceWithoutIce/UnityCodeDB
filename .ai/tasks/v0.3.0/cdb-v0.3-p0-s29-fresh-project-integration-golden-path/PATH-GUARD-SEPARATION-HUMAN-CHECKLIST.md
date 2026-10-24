# S29 path-guard separation — human checklist

Use the already switched project:

`G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`

Use the exact local Package selected in the delivery result. Do not run Install,
Uninstall, Remove Integration or Configure for this focused gate.

1. Open the project and wait for compilation/import to finish.
2. Run only these focused EditMode groups:
   - `ManagerActionJournal_ValidInstanceIdsPreserveCurrentAndLegacyAdmission`
     (four cases: READY/PROVISIONING × current/legacy)
   - `ManagerActionJournal_UnownedProvisioningCandidateBlocksHistoryRecovery`
   - `ManagerActionJournal_CurrentIndexWithUnownedCandidateStaysConflict`
   - `ManagerActionJournal_InvalidInstanceDirectoryStillFailsClosed`
     (three cases)
3. Open Manager and confirm the previous
   `Manager action index escapes its user-local root` message is absent.
   A clear historical ownership or generation warning may remain, and Install
   may remain hidden because fail-closed admission is still intentional.
4. Close and reopen Manager once; confirm the warning/reason does not change
   into the old user-local-root error. Check tab switching.
5. Close Unity normally and report whether it exits without a crash.

Record the exact visible reason if the project remains `Needs Attention`.
This checklist is a human Unity gate; source, package and export evidence do
not substitute for it.

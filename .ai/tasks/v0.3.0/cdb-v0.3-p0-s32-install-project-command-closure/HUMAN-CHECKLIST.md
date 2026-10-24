# S32 focused human Unity acceptance

Status: HUMAN_REPORTED_PASS_WITH_LIMITS / see HUMAN-RESULT.md.

User reported all Test Runner tests passed, Manager open-close normal and Unity
exit normal. Tab switching/standalone compilation were not separately reported.
No repeat run is requested here; the original requested scope follows.

Open existing `UnityFreshLifecycleValidationProjectS30` with Unity 2022.3.62f3.
Both Package references already point to the exact extraction from commit
`b0462ed07b6a14be64bddf848e67609d9143fa71`:
`.artifacts/s32-install-command-b0462ed/review/com.rice.ai-codedb`.
No reinstall or manual Package replacement is needed.

## Focused EditMode tests

In Test Runner, run these methods under `AICodedbProjectSettingsTests` (namespace
`Rice.AI.Codedb.Editor.Tests`), including all five parameterized cases of the
first method:

- `InstallEntryAndManager_RequireConfirmedCompleteSuccess`
- `InstallEntry_MissingOrMalformedResultDoesNotReconcile`
- `ManagerActionSession_ReloadRestoresUnconfirmedOutcomeWithoutRetry`
- `ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission`

Do not run the whole suite. `AICodedbS32InstallTests.ProjectInstall_OriginalWriterFailureAndOfflineRecovery`
requires the explicit child-local harness and ordinarily reports Ignored; it is
not required in human Test Runner. Its exact Package route/result evidence and
the internal producer/PowerShell admission scenarios already passed separately.

## UI and closure

1. Confirm compilation has no errors.
2. Open Manager, close/reopen once and switch its tabs. Report actual displayed
   state, warnings and any Console error. Existing pending/unconfirmed state may
   remain; do not force Ready or use a lifecycle action to clear it.
3. Close Unity normally and report whether it exits. Previous CleanupMono/shutdown
   observations remain deferred and are not investigated in this task.

Do not click/confirm Install, Uninstall or Remove. The protected old S30 action
and missing-disposition history remain separate from current-source acceptance.
This checklist validates compilation/tests/UI only, not successful reinstall,
Provider, Ready or historical recovery. If a listed method is unavailable or
fails, preserve its exact name/error and stop that path for analysis.

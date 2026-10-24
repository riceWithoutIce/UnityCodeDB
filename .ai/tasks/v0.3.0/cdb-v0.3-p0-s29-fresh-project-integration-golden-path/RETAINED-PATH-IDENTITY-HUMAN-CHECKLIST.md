# S29 path correction minimal human validation

2026-10-09. All authorized pre-human tasks complete. S29 project references
the verified s29-retained-path-poc41 Package, source commit9330930. Exact
export/PS writer39cases/C# extracted reader32checks passed; Unity gate pending.

## One session with actual emitted proof

Use the prepared launcher instead of opening through Hub without the proof:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "G:\RiceProgram\UnityCodeDB\.artifacts\delivery\s29-path41\open-human-validation.ps1"
```

This opens UnityFreshInstallValidationProjectS29, validates Package reference
and emitted-proof context hash, and passes RICE_CODEDB_RETAINED_EFFECTS_PROOF
only to that child. No persistent environment setting. Another installed Editor
can be selected with -UnityEditor; Unity2022.3.x is recommended, exact patch
not required. This launcher has not been executed by the agent in this delivery.

## Required checks

1. Wait for import/compile; confirm zero C# errors. Stop on compilation failure.
2. Run these three EditMode methods; all must be PASS, not ignored/skipped:
   - AICodedbProjectSettingsTests.RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot
   - AICodedbProjectSettingsTests.ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession
   - AICodedbS29ExecutionContextTests.RetainedCandidateUninstalledPresentationUsesWorkerPreflightWithoutDispatchOnCancelledWorker
3. Open/close/reopen Manager; confirm no exception or frozen UI. Uninstalled
   state can lack other tabs; no tab switching required there. Historical
   failed Install/NeedsAttention is not a newly dispatched Install failure.
4. Report compile, three methods and Manager observation. No full suite rerun,
   Codex/session/Windows restart or manual proof preparation is required.

The actual emitted proof test covers complete journal/session restore, original
failed/incomplete outcome, same-root representations, independent wrong-root
and wrong-hash refusals while restoring test-owned bytes. Exact extracted
reader evidence does not replace its execution in Unity/Mono.

Do not click Install, Remove CodeDB Integration, Configure Dependencies or
other recovery action in this gate. Real recovery/retained-candidate safety
and fresh Install remain separately scoped after this boundary passes.

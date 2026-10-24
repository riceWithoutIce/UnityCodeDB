# S29 retained recovery - human C# and Manager observation

2026-10-09. Prerequisites complete. This gate is compile/focused tests/observation,
not real recovery or Install. Project UnityFreshInstallValidationProjectS29;
commit915a21b8c09aa126bdf757711baa80632c537137, Package0.3.0-preview.5/poc.41.
Manifest/lock already select .artifacts/s29-retained-recovery-poc41/review/
com.rice.ai-codedb. The project was confirmed normally closed before switching.

## Open once with actual emitted test evidence

In PowerShell, run the prepared human launcher:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "G:\RiceProgram\UnityCodeDB\.artifacts\delivery\s29-rc41\open-human-validation.ps1"
```

The launcher opens this project using installed Unity2022.3.62f3 and passes
RICE_CODEDB_RETAINED_EFFECTS_PROOF only to that Unity child. Another installed
Editor can be selected with -UnityEditor; exact2022.3 patch is not a product gate.
No user/machine environment edits. The agent has not launched Unity.
Use this launcher for this session so the cross-language test actually runs;
opening through Hub without its evidence variable can cause that test to skip.
The script checks the selected Package reference and actual proof-context hash.

The repository-local short input was emitted by actual Package reader/writer/
convergence functions with synthetic native identities. Original archive and
Package source stay unchanged. Its maximum existing file path is250characters.
No receipt/candidate from the real project is used or modified by this fixture.

## Required focused checks

1. Wait for import/compilation; confirm zero C# errors. On compile failure, stop
   and provide the complete error text.
2. In Test Runner -> EditMode, run these two methods individually:
   - AICodedbProjectSettingsTests.
     ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession
   - AICodedbS29ExecutionContextTests.
     RetainedCandidateUninstalledPresentationUsesWorkerPreflightWithoutDispatchOnCancelledWorker
   Both must show passed, not skipped/ignored. The first also performs the three
   wrong-hash refusal assertions and preserves original failed/incomplete output.
3. Open CodeDB Manager, observe the displayed state and existing action/menu,
   close and reopen it; confirm no exception/frozen UI. If this Uninstalled state
   has no other tabs, tab switching is inapplicable. Historical failed Install,
   Uninstalled/NeedsAttention or retained warning is not a new Install failure.
4. Report the compile result, the two test results and Manager observation. A
   screenshot of the final state is useful. Unity can remain open for reporting.

Do not click Install, Remove CodeDB Integration, Configure Dependencies or any
recovery action in this observation gate. Those real state transitions require
the next concrete recovery authorization after the current C# boundary passes.
No Codex/session/Windows restart is needed for these compile/test observations.
The unresolved early OLD wrapper fixture and broader suites are not requested.

# S29 native-launch Package - one human observation session

Candidate commit8b2061d45504da551b626714a877176051a43fe1,
Package0.3.0-preview.5 / generationpoc.41.
Package path: G:/RiceProgram/UnityCodeDB/.artifacts/s29-native-launch-poc41/review/com.rice.ai-codedb/package.json.
Project: G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29.

Status: READY_FOR_HUMAN / NOT RUN. User confirmed the project closed; Planner has
switched and verified both CodeDB Package references. Other dependency content
is unchanged. The human may now open this project for the checks below.

1. Open the same S29 project after reference-switch confirmation. Wait for Package
   import/C# compilation; confirm0C#compile errors and no new import exceptions.
   Verify the CodeDB local dependency resolves to the exact candidate path above.
2. Open CodeDB Manager once. Record the settled status and any full error text.
   Earlier failed Install/PENDING state may still be visible; preserved history
   is not proof that this new Package install has failed. Do not infer READY from
   successful package import or the isolated artifact tests.
3. Switch existing Manager tabs, then close Manager; confirm no new exception,
   stuck activity or obvious UI problem. The earlier missing progress indicator
   was not included in this source change and remains a separate follow-up.

No historical full Editor-suite replay is required by default: Editor C# is
unchanged, while the new Host execution path has exact-artifact isolated evidence.
If a compile/UI error appears, retain its full message and stop this observation
sequence. Do not keep pressing Install to diagnose it.

This session does not authorize Install, Remove CodeDB Integration, Configure
Dependencies, cleanup, candidate adoption or history deletion. The retained failed
candidate requires the existing precisely scoped recovery/reinstall plan before
a real mutation. Human report of compile/observation PASS closes only this gate;
S29 and real installation remain PARTIAL. No additional Unity restart is requested
just for reporting these observation results.

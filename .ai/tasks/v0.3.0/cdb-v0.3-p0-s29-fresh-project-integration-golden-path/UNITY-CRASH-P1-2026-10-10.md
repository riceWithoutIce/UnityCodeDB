# Unity crash P1 — 2026-10-10

## Triage result

Unity Crash Reporter produced `Crash_2026-10-10_031602735` for `UnityFreshInstallValidationProjectS29`. The crash log contains a native fatal boundary during Editor shutdown:

`GetManagerFromContext: pointer to object of manager 'MonoManager' is NULL`
`Cancelling DisplayDialog because it was run from a thread that is not the main thread: Fatal Error!`
`Cleanup mono` → `Crash!!!`

The stack is attributable to CodeDB shutdown completion handling:

`AICodedbLifecycleEvidence.EmitWorkerCheckpoint` (`AICodedbLifecycleEvidence.cs:1034`)
`AICodedbLifecycleEvidence.RecordShutdownDisposition` (`AICodedbLifecycleEvidence.cs:1008`)
ThreadPool continuation from `AICodedbEditorLifecycle.QueueOwnedSupervisorShutdown` (`AICodedbEditorLifecycle.cs:2548`).

The Supervisor shutdown response completed after Unity's `EditorApplication.quitting` boundary. The continuation called `Debug.Log` from a ThreadPool thread after `MonoManager` had been destroyed. This is the proven crash cause for this report.

## Narrow repair

`RecordShutdownDisposition` still updates the thread-safe shutdown counter and observation fields, but no longer emits `Debug.Log`/`SessionState` evidence from the asynchronous shutdown continuation. The normal main-thread `editor_quitting` evidence remains unchanged. This prevents Unity API access after shutdown while preserving the bounded shutdown disposition and Supervisor observation data in the in-memory counter.

Changed file: `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`.

## Evidence and limits

- Crash log: `C:/Users/admin/AppData/Local/Temp/Unity/Editor/Crashes/Crash_2026-10-10_031602735/Editor.log`, 4,965 lines, `Crash!!!` at line 1,362.
- The current `C:/Users/admin/AppData/Local/Unity/Editor/Editor.log` is locked by the running Unity process; bounded text inspection reproduced the same fatal boundary and CodeDB shutdown frames.
- The crash directory contains only `Editor.log`; no native dump or separate crash report was available for this incident.
- Unity process inspection shows the running Editor is `F:/unity/unity-2022.3.62f3/Editor/Unity.exe` for `G:/work/miniGame_int`, not the S29 project. No Unity process was stopped or restarted by Codex.
- The S29 source/package reference and existing dirty state were preserved. No Install, Uninstall, package export, commit, push, publication, Unity/MCP/CUA/BatchMode launch or external process control was performed.
- The existing standalone verifier command reached its prior real-reader fixture limitation after semantic compilation reported zero errors; it is not a Unity crash regression run. Human Unity verification is required after the user decides when to reopen the affected project.

## Disposition

This is a P1 source finding because the normal Unity shutdown path can crash the Editor. The repair is intentionally limited to the proven post-shutdown Unity API call. Status oscillation work is paused behind this incident and needs fresh evidence after the repair is reviewed.

## Human follow-up clarification

The human reopened/used the Unity project and reported that no new crash occurred. This is useful live evidence, but it does not yet validate this source repair: the project still selects the previously exported `poc.42` review package, while the repaired source file remains only in the working tree. The subsequent Editor.log still contains the old `RecordShutdownDisposition` → `EmitWorkerCheckpoint` stack from that package, with zero new `Crash!!!` markers in the inspected current log. Therefore the P1 fix remains **implemented but delivery/runtime-unverified** until a package containing this change is exported, selected by the project, and closed once by the human without a crash.

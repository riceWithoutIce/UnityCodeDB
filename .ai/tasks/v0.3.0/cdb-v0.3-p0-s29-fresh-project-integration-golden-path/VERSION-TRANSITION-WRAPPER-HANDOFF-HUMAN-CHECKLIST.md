# S29 historical wrapper handoff — human Unity checklist

Use the already switched project:
`G:\RiceProgram\UnityCodeDB\UnityFreshInstallValidationProjectS29`

1. Open the project in Unity 2022.3.62f3 and wait for import/compile to finish.
2. Confirm there are no compile errors.
3. In Test Runner, run
   `AICodedbProjectSettingsTests.ManagerVersionTransition_ProductionObservationKeepsIdentityAndSafetySeparate`.
   It must execute as 1 passed / 0 failed; `Ignore` means the fixture environment
   was not inherited and does not count.
4. Open CodeDB Manager, close it, reopen it once, and switch its tabs.
5. Observe the Manager's retained-effects message. The historical predecessor
   may remain NeedsAttention or blocked by prerequisites; do not require Ready
   while the installed predecessor is still selected.
6. Close Unity and report whether it exits or exhibits the already deferred
   `Application.Shutdown.CleanupMono` block.

Do not click Install, Remove, Upgrade, Configure Dependencies, or perform manual
history/index cleanup during this acceptance. Report the exact test count and
any Manager or shutdown error text.

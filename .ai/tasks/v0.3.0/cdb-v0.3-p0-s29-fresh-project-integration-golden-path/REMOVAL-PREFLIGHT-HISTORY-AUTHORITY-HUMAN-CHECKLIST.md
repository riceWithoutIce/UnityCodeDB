# S29 removal history authority — Unity human checklist

Source commit: `5b52c017e8415bb061f33a8380b3dcec2916411a`.
Project: `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.
Expected Package:
`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-history-authority-5b52c01/review/com.rice.ai-codedb`
ZIP SHA256:
`7e39a1ab41fbe5da5417cc73557ec8e7f4bc5837a52180ed40caaace35183d32`.

1. Open the same S29 Unity project and wait for compilation. Report whether
   there are new compile errors.
2. In EditMode Test Runner, run these ordinary tests:

   - `RemovalPreflight_LifecycleRefusesIncompleteAndMalformedPermits`
   - `RemovalPreflight_RequiresOneAvailableLineAndHandoff`
   - `RemovalPreflight_RejectsMissingOrDuplicateHandoff`
   - `RemovalIntegrationArguments_RequireHandoff`

   Do not run `RemovalPreflight_ConsumesIsolatedProductionNamespaceRefusal`
   unless the explicit isolated fixture is configured. If selected accidentally,
   record it as unconfigured rather than treating it as a product failure.
3. Open Manager, close and reopen it once, and switch its tabs. Report visible
   behavior and any refusal text. A retained removal block is expected and is
   not a test failure.
4. Close Unity normally and report whether it exits. If CleanupMono recurs,
   record it separately; do not expand this task or force a repeated sample.

This gate does not require Ready or an Install button. Do not click Install,
Remove or Upgrade, stop processes, edit history, or use Unity automation. Report
compilation, each Test Run group, Manager close/reopen, tab switching and Unity
close separately. User-visible acceptance is separate from the source/isolated
evidence in DELIVERY-RESULT.md.

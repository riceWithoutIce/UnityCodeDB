# S29 Upgrade call-site fix — human Unity checklist

Date: 2026-10-13. Status: HUMAN_UNITY_PENDING.

Exact source commit: `34b3a65c8c3f136ccb052ba52bb10a8476676546`.
Exact Package:
`G:/RiceProgram/UnityCodeDB/.artifacts/s29-upgrade-callsite-fix-34b3a65/review/com.rice.ai-codedb`.
Project: `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.
The S29 manifest and lock now reference this Package. The failed d127a45
Package remains preserved in its original artifact directory.

## Human steps

1. Open the project yourself and wait for Package import and C# compilation.
   Report whether the previous CS7036 error is gone and record any compiler
   errors. Do not use MCP, BatchMode, CUA or an automated Unity launch.
2. In EditMode Test Runner, run only
   `Rice.AI.Codedb.Editor.Tests.AICodedbHostPayloadMaterializerPreflightHandoffTests`:
   - `RemovalPreflight_RequiresOneAvailableLineAndHandoff`
   - `RemovalPreflight_RejectsMissingOrDuplicateHandoff`
   - `RemovalIntegrationArguments_RequireHandoff`
3. Open Manager, close/reopen it once, and switch its tabs. Record exceptions,
   missing content and every readiness transition with its displayed reason.
   A final Ready state alone does not prove stable readiness.
4. Close Unity normally. If it hangs, record approximate duration and whether
   it exits or requires manual intervention. Shutdown remains observation only.

Stop dependent acceptance on compilation or focused-test failure and preserve
the complete error/test name/stack trace. Do not click Install, Remove
Integration, Uninstall, Configure or any other mutating action.

## Boundary

This gate proves the repaired Package's import/compile, focused handoff tests
and UI observation only. It does not prove Ready/Install-button visibility,
real historical removal, fresh successor Install, migration or release. Those
remain separate authorized gates; S29/release remain PARTIAL.

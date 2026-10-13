# S29 generation alignment FIX2 — human Unity checklist

Date: 2026-10-13. Status: HUMAN_COMPILE_FAILED / DEPENDENT_ACCEPTANCE_STOPPED.

The human reported CS7036 in this exact Package. Preserve the failed artifact;
do not continue the steps below until a repaired exact Package is separately
delivered. See INSTALLED-GENERATION-ALIGNMENT-FIX2-HUMAN-COMPILE-FAILURE.md.

This checklist is bound to source commit
`d127a45eafa62f04f25a4b578839e6056e46299a` and the exact Package:
`G:/RiceProgram/UnityCodeDB/.artifacts/s29-generation-alignment-d127a45/review/com.rice.ai-codedb`.
The project manifest and lock already reference this Package. Do not export,
switch references or install again for this gate.

## Human steps

1. Open `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`
   yourself. Wait for Package import and C# compilation; report any compiler
   errors. Unity execution belongs to the human; no MCP, BatchMode, CUA or
   automatic Editor launch substitutes for this gate.
2. In Test Runner, select EditMode and run only
   `Rice.AI.Codedb.Editor.Tests.AICodedbHostPayloadMaterializerPreflightHandoffTests`:
   - `RemovalPreflight_RequiresOneAvailableLineAndHandoff`
   - `RemovalPreflight_RejectsMissingOrDuplicateHandoff`
   - `RemovalIntegrationArguments_RequireHandoff`
   These three methods do not require the RetainedDispositionOnly fixture
   environment. No full suite or prior 26-case rerun is required here.
3. Open Manager in EditMode, close/reopen it once, and switch its tabs.
   Report exceptions, missing content, and any readiness transitions together
   with the displayed reasons. Final Ready alone is not stability evidence.
4. Close Unity normally. If it hangs, record the observation, approximate
   duration and whether it eventually exits or requires manual intervention.
   The earlier shutdown hang remains deferred observation; this gate does not
   authorize a shutdown repair or automatic process termination.

Stop dependent acceptance on compilation or focused-test failure and preserve
the complete error/test name/stack trace. Report which observations completed.

## Expected boundary

The installed historical poc.42 and this Package's distinct poc.43 remain
separate. This gate does not require Ready or an Install button to appear, and
does not prove live historical removal or fresh successor installation. Do not
click Install, Remove Integration, Uninstall, Configure or other mutating actions.
Any subsequent real Remove/Install needs its own concrete scope and authority.

After the human report, the parent performs bounded read-only reference,
receipt/control and relevant log attribution. Human compilation/EditMode/UI
evidence stays separate from synthetic, live-operation and release acceptance.
S29/release remain PARTIAL.

# S29 removal preflight namespace — human Unity gate

Status: HUMAN_REPORTED_PASS; see REMOVAL-PREFLIGHT-NAMESPACE-HUMAN-RESULT.md
for reported evidence and the still-blocked real removal preflight.
Source commit 39d79aeee1bd5525c6ed2eb1369f6c27334b9d07.
Project: G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29.
Both Package references are already switched to the exact
.artifacts/s29-removal-namespace-39d79ae/review/com.rice.ai-codedb Package.
No reinstall or environment/fixture launch setup is needed for these three tests.

1. Open this existing project in Unity 2022.3.62f3 and wait for import/compile.
   Confirm there are no compile errors.
2. In EditMode Test Runner, run these three exact parameterless tests:
   - AICodedbS29ExecutionContextTests.RemovalPreflightFailureDiagnostic_IsBoundedRedactedAndRetainsCause
   - AICodedbS29ExecutionContextTests.RemovalPreflightFailureCache_PreservesBackendReasonWithoutDispatch
   - AICodedbHostPayloadMaterializerPreflightHandoffTests.RemovalPreflight_LifecycleRefusesIncompleteAndMalformedPermits
   Expected: 3 passed / 0 failed / 0 ignored. The cache test exercises the existing
   native Unity workspace allocation/cleanup entry previously compiled but unrun.
3. Open CodeDB Manager, close/reopen once, and switch its tabs. Record any error.
   Observe removal availability and the concrete refusal detail, if any. A missing
   durable child identity, ambiguous historical ownership, live/unverifiable process
   or prerequisite blocker can still correctly block admission; Ready and a visible
   Install button are not this gate's required outcome. Share the Manager screenshot
   so the parent can attribute the actual remaining refusal.
4. Close Unity and report whether it exits normally. CleanupMono remains deferred;
   record recurrence without turning this gate into a shutdown repair.

Do not click Install, Remove, Upgrade or Configure Dependencies. No real mutation
is part of this gate. After your report, parent performs bounded read-only evidence
attribution; automated Unity/MCP/CUA/BatchMode is not a substitute.

RemovalPreflight_ConsumesIsolatedProductionNamespaceRefusal requires an explicit
TestContext parameter. It already passed in the exact-artifact isolated consumer
harness; it is not included in the three human tests. Running it without that
parameter yields Ignore, which is not native fixture consumer PASS. Full v1
transactions, real crash/restart and full Install/Uninstall remain unrun.

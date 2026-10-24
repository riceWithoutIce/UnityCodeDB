# S29 removal preflight test-root correction result

Date: 2026-10-14. Base: `ca316dba4a9567c754c92f0096d0b7a401a9a67d`.
Coder status: STABLE / READY_FOR_READ_ONLY_VERIFIER. Mandatory source gates: PASS.
This result does not confer source acceptance, delivery, Unity or removal acceptance.
Overall S29 remains PARTIAL; CleanupMono remains deferred.

## Frozen source change

Only `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` and
`com.rice.ai-codedb/Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs`
changed in this correction. The Unity cache test uses the existing
`AICodedbTestWorkspace.Run` and explicitly passes `workspace.Root` to
`AssertCachedRemovalFailure`. The repository fixture consumer passes its existing
explicit `root`. The helper derives simulated project/Package paths with
`Path.Combine(testRoot, "project")` and `Path.Combine(testRoot, "package")`.
Fixed drive-root literals were removed. All original assertions, production
behavior and cache `finally` restoration are unchanged.

Root map: Unity test entry -> existing native workspace allocator -> workspace.Root
-> helper -> child paths. Fixture entry -> explicit TestContext parameter
RemovalNamespaceFixtureRoot -> fixture consumer root -> helper -> child paths.
The isolated repository runner requires the existing task-owned root
`G:/RiceProgram/UnityCodeDB/.artifacts/tests/s29-removal-namespace/test-path-fix-a1/owned-fixture`.
There is no temp, environment, drive discovery or root-selection fallback.

## Immutable evidence and mandatory gates

Evidence root: `G:/RiceProgram/UnityCodeDB/.artifacts/tests/s29-removal-namespace/test-path-fix-a1`.
Package overlay: `com.rice.ai-codedb` beneath that root, copied from the accepted
`.artifacts/s29-removal-namespace-ca316db/review/com.rice.ai-codedb`, then overlaid
with only the two corrected test files. Dirty worktree Payload was not copied.

| Gate | Result | Artifact under evidence root |
| --- | --- | --- |
| Package Path ProvenanceOnly, before compilation/execution | PASS, exit 0 | path-provenance-a1.log |
| Original-byte production Editor C# compile | PASS, exit 0 | Rice.AICodedb.Editor-compile-a1.log; Rice.AICodedb.Editor.rsp |
| Original-byte full Editor.Tests C# compile, including native Unity workspace entry | PASS, exit 0 | Rice.AICodedb.Editor.Tests-compile-a1.log; Rice.AICodedb.Editor.Tests.rsp |
| Original extracted-member text equality | PASS, 13 members | exact-ast-binding.txt; extractor-a1.log; Seam.cs |
| Original NUnit diagnostic/cache/UI assertions and direct production fixture consumer | PASS, exit 0 | seam-run-a1.log; seam-compile-a1.log; Runner.cs; run-seam.ps1 |
| Full overlay/source equality and scoped diff check | PASS, 617 files, exactly two authorized differences | snapshot-check-a1.log; verify-snapshot.ps1 |
| Original assertions/cache restoration unchanged versus accepted baseline | PASS, exact authorized source transformations only | snapshot-check-a1.log |
| Direct root propagation source review and Unity entry AST binding | PASS | snapshot-check-a1.log; exact-ast-binding.txt |

Path gate command: `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass
-File <evidence-root>/com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1
-PathProvenanceOnly`. Other commands invoke `compile-exact.ps1`, then
`run-seam.ps1 -FixtureRoot <evidence-root>/owned-fixture`, then
`verify-snapshot.ps1`, with the same PowerShell flags. Each returned exit 0.
Source and tool/evidence hashes are frozen in
`REMOVAL-PREFLIGHT-TEST-PATH-FIX-SOURCE-SHA256.txt` beside this record.

The original cache helper was executed with both the fixed synthetic backend
failure input and the saved production fixture failure. Its original NUnit
assertions cover cached refusal, retained diagnostic/state, Uninstall refusal
and existing UI status-item detail. The diagnostic test retains redaction and
bounded-length checks; the directly coupled malformed/incomplete/timeout permit
checks and fixture success/output-drain refusal remain covered. The helper's
cache restoration remains its original `finally` block. No assertions were
rewritten or replaced.

Saved production fixture stdout/stderr were copied read-only from the prior
`scenario-a4/r-62aa9fb9`; this run did not replay production namespace/wrapper
scenarios or invoke live preflight. The harness uses exact original source
members and references the exact compiled production assembly. It does not
replace the native test workspace allocator or native initializer. The original
Unity cache entry is compiled in the full test assembly and source/AST-reviewed;
the repository harness calls the original helper with its explicit owned root.

## Evidence boundary and handoff

Full native `AICodedbTestWorkspace` execution: NOT_RUN, human Unity gate.
Focused path provenance does not replace the downstream full Package-boundary
release gate. No mandatory source gate is waived as PASS_WITH_LIMITS.

No production/framework source, existing artifacts, dirty Payload, real S29
project/runtime, environment or processes were modified by this repair.
No commit, export, reference switch, Unity launch, real Install/Remove/Upgrade,
cleanup, push or publication was performed. The prior blocked delivery artifact
and its grant remain unchanged. Parent may now verify snapshot completeness,
then reuse the authorized read-only Verifier for the original path finding and
direct caller regression. New user source acceptance is required before any
successor commit/export.

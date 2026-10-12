# S29 PRODUCER-ATTRIBUTION-REPAIR — Verifier result

## Verdict

`PASS_WITH_LIMITS` — the producer attribution boundary is correct in the
allowlisted snapshot. The focused producer fixture remains blocked by the
pre-existing `poc.42` payload source-hash mismatch, and Unity/real producer
gates were not run.

This was a strictly read-only review. No source, runtime, receipt, candidate,
package, Unity project, external process, Install, commit, or export was
modified.

## Snapshot / manifest

The allowlisted files match `PRODUCER-ATTRIBUTION-REPAIR-SOURCE-SHA256.txt`:

```text
26a73953659cf640801aee08b9f64613ffa1aba9e55ad501e2157cfa6e2448f4  com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs
ca16ddb8fd5068693dbc85532caa9130e10df426aed6922356d564c5b01dcef5  com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
```

`git diff --check` is clean for both slice files.

## Checks

1. Confirmed Manager Install/Reinstall attribution is fail-closed. In
   `BuildRuntimeScriptArguments`, Install and Reinstall require
   `AICodedbSupervisorProtocol.IsManagerActionId(CurrentActionId)`. Missing,
   empty, malformed, uppercase, and wrong-length ids throw
   `ArgumentException` before arguments are admitted. The caller wrappers catch
   this and return a failed command result, so no candidate-producing process is
   dispatched. No operation id is substituted for the action id.

2. A valid Manager context passes the actual Manager action id as
   `-OriginatingActionId` and generates a separate 32-hex operation id for
   `-OriginatingOperationId`. The source uses one generated operation id for
   both argument construction and ProcessRunner hashing; the focused regression
   asserts the action id and distinct operation id for Install and Reinstall.

3. Lifecycle's authorized empty-context Upgrade bootstrap remains admitted.
   `UseLifecycleExecutionContext` clears Manager action context; Upgrade keeps
   the operation-id fallback, and the regression asserts the generated
   operation id is used as both originating action and operation id and is
   distinct from the cleared Manager id. Install/Reinstall do not receive this
   fallback.

4. Source/result text boundaries agree. The source error is
   `Install and Reinstall require a valid Manager action id for candidate attribution.`
   and the regression asserts the stable `valid Manager action id` substring.
   No source path silently rewrites an invalid id or claims a candidate was
   attributed after rejection.

## Evidence

- Roslyn semantic compilation via `.artifacts/tests/s29-post-install-ui/Semantic.csproj`:
  `SEMANTIC errors=0` (only nullable-context warnings).
- Node v24.14.1 syntax checks passed for the `poc.42` instance-manifest
  contract and host-use gate.
- PowerShell parsing passed for the `poc.42` instance-manifest contract and
  `Tests~/test-codedb-host-payload-materializer.ps1`.
- Authored regressions cover valid Manager Install/Reinstall attribution,
  missing/invalid Install/Reinstall ids, and empty-context lifecycle Upgrade
  fallback (three methods, ten cases, as reported by Coder). NUnit/Unity
  execution was not performed.

## Limits / priority

The focused `-FirstInstallAttributionOnly` PowerShell fixture was attempted
once and stopped at the existing admission error:
`Payload source hash mismatch: Generations/poc.42/coordinator/codedb-watch-coordinator.mjs`.
No payload regeneration or hash correction was attempted. This is a fixture
blocker, not a source finding.

Unity EditMode, real producer execution, integration, runtime/IPC, device, and
release validation are **NOT RUN**. Historical orphan evidence remains outside
this prevention fix and was neither rewritten nor inferred.

- BLOCKER: none.
- P1/P2: none found in the reviewed attribution boundary.
- FOLLOW-UP: run the focused producer fixture after the pre-existing payload
  hash admission issue is separately resolved; then perform the human Unity
  gate.

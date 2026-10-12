# S29 producer attribution repair — Coder result

Date: 2026-10-12.

## Stable snapshot

- Base/HEAD: `9179d8a1a679056bef19b7e9246988510c3c9284`.
- Snapshot: working tree only; no new commit.
- This slice changes `Editor/AICodedbHostPayloadMaterializer.cs` and the producer
  regression methods in `Tests/Editor/AICodedbManagerUiTests.cs`.
- The test file also contains the preceding history aggregation repair. Those
  prior changes are preserved; its current complete-file hash supersedes the
  test-file hash in HISTORY-AGGREGATE-REPAIR-SOURCE-SHA256.txt for this snapshot.
- No Unity, MCP, Install/Uninstall, export, package/reference switch, receipt,
  candidate, runtime manifest, cleanup-state, or external-process mutation.

## Finding and change

The historical `poc.39` candidate `330b7a972a7649259409fbce4de8ca56`
declares originating action `73c9d6a0a8ba4df0898721265ec515d6`, which is not
the Manager receipt identity `d8c736504562495dbafdd673c6851efb`. The d8 INSTALL
admission arguments lack `-OriginatingActionId` and `-OriginatingOperationId`.
This historical evidence establishes the ownership break; it does not prove
that today's materializer source produced those old bytes.

The current materializer had an equivalent unsafe fallback: when Manager action
context was absent, it used a newly generated operation id as originating
action id. Confirmed Manager Install and Reinstall dispatches now require a
valid Manager action id before returning arguments for ProcessRunner admission.
Missing or invalid ids raise `ArgumentException`; no candidate-producing
subprocess is admitted through this boundary. A valid context still supplies
the real Manager action id and a separate new operation id. Lifecycle's
authorized empty-runtime Upgrade bootstrap retains its operation-id fallback.

The additional attribution constraint is limited to confirmed Manager
Install/Reinstall dispatches. Lifecycle's authorized empty-runtime Upgrade
bootstrap clears Manager action context by design and retains the prior
operation-id fallback; its regression verifies that this path remains admitted.
Probe, Redeploy, Repair, Sync, Remove and other existing direct/bootstrap
semantics retain their prior behavior. Existing orphan evidence is not rewritten
or inferred from timestamps, generation, or receipt proximity.

## Verification

- Roslyn semantic compilation via
  `.artifacts/tests/s29-post-install-ui/Semantic.csproj`: `SEMANTIC errors=0`.
- Node syntax checks passed for the `poc.42` shared instance-manifest contract
  and host-use gate.
- PowerShell parsing passed for the `poc.42` shared instance-manifest contract
  and `Tests~/test-codedb-host-payload-materializer.ps1`.
- `git diff --check` passed for the two slice files.
- The focused `-FirstInstallAttributionOnly` PowerShell fixture was attempted
  once and stopped at the existing admission error:
  `Payload source hash mismatch: Generations/poc.42/coordinator/codedb-watch-coordinator.mjs`.
  This is a blocked fixture, not a functional attribution PASS. No payload
  regeneration or hash correction was attempted.
- Authored regressions cover valid Manager attribution and missing/invalid
  context rejection for Install/Reinstall, plus the empty-context lifecycle
  Upgrade bootstrap (three methods, ten cases). Semantic compilation does not
  constitute NUnit execution. Unity/EditMode, real producer execution,
  integration and release validation were not run.

## Handoff

The exact two-file snapshot is frozen by
PRODUCER-ATTRIBUTION-REPAIR-SOURCE-SHA256.txt. Coder work stops here for the
independent read-only Verifier gate. Existing historical orphan recovery remains
a separate disposition; this prevention fix does not claim to restore the
currently hidden Install button by altering protected history.

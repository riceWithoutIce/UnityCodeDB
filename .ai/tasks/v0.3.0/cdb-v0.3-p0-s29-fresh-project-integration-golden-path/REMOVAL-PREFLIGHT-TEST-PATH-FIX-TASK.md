# S29 removal preflight test-root correction

Date: 2026-10-14. Base ca316dba4a9567c754c92f0096d0b7a401a9a67d.
User grant: `明白了，那我们继续 做修正`, following read-only cause alignment.
Status: SOURCE_ACCEPTED / DELIVERY_RESUMED. Review: GUARDED, original finding and
immediate caller regression only. Reuse the previously authorized sequential
Coder -> stable snapshot -> read-only Verifier within this S29 repair envelope;
parent stays active until both roles terminate. No new agents or sessions.

## Frozen outcome and responsibility

Remove fixed drive-root paths in the new removal-failure cache test helper.
Keep its production behavior, assertions and cache restoration unchanged.
Follow existing development-workflow.md Package Path Provenance Gate and
test-workspace-contract.md; missing mandatory source checks block snapshot
admission, never become PASS_WITH_LIMITS exemptions.

Unity Test entry owns its root through existing AICodedbTestWorkspace.Run.
Repository fixture entry owns its already explicit isolated fixture root.
Both pass that root to AssertCachedRemovalFailure; the helper derives project
and simulated Package child paths only from the supplied root. No machine
literal, OS temp, process environment, drive discovery or fallback root.

Writable source: Tests/Editor/AICodedbEditorLifecycleTests.cs and its direct
caller Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs,
relative to com.rice.ai-codedb. Shared workspace and production files read-only.
Task records and ignored exclusive test tools/evidence permitted. Preserve
prior ca316db ZIP, prior fixtures, dirty Payload and real S29 state.

## Mandatory evidence before review

- Exact overlay/source hashes, scoped diff and original-byte C# compile.
- Existing Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly PASS
  on the immutable Package overlay with these two test changes.
- Focused original NUnit cache/diagnostic/UI and direct fixture consumer checks,
  using an explicit owned repository fixture root, with cache restoration.
- Source review of Unity entry -> workspace root -> helper and fixture entry ->
  owned fixture root -> helper; no rewritten original test assertions.

Full native AICodedbTestWorkspace execution remains human Unity evidence.
No test substituting workspace selection claims native root allocation PASS.
No namespace/wrapper test replay unless the test caller change requires it.
Report each mandatory gate with artifact path and PASS/FAIL; failure/missing
source gate stops admission. Retain failed attempts unchanged.

## Stop and handoff

Coder freezes RESULT/SOURCE-SHA256 and terminates. Parent checks gate completeness
and snapshot, then reuses read-only Verifier; findings return once to the user.
New source acceptance is required before successor commit/export. Existing delivery
grant and blocked observed artifact stay recorded; this repair performs no commit,
export, reference switch, Unity, live reader/preflight, real Install/Remove/Upgrade,
environment change, process control, cleanup, push or publication. Overall S29
remains PARTIAL and CleanupMono remains deferred.

## Terminal review

Coder and read-only Verifier completed. Mandatory source checks all have PASS
artifacts; original fixed-path finding CLOSED, zero BLOCKER/FOLLOW-UP. Parent
rechecked both source hashes and empty index; HEAD remains ca316db. See
REMOVAL-PREFLIGHT-TEST-PATH-FIX-VERIFICATION.md. Native Unity workspace execution
remains NOT_RUN, separately from completed source gates. User disposition is
accepted on 2026-10-14 (`同意 accept`). Resume the existing approved delivery
sequence under REMOVAL-PREFLIGHT-NAMESPACE-DELIVERY-GRANT.md, with a successor
commit/artifact and all exact-package gates; preserve the blocked ca316db artifact.

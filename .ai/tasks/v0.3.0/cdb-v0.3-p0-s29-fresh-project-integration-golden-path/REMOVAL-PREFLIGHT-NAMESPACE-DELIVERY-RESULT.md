# S29 removal namespace delivery result

Date: 2026-10-14. User authorized the declared delivery sequence with
`授权开始`. Current result: DELIVERY_COMPLETE / HUMAN_REPORTED_PASS.
See REMOVAL-PREFLIGHT-NAMESPACE-HUMAN-RESULT.md for exact attribution: real removal
preflight still blocks on retained child-process proof and overall S29 is PARTIAL.
The blocked ca316db attempt below is retained as historical evidence.

## Successful successor delivery

After the user accepted the two-file runtime-root correction (`同意 accept`),
parent resumed the already authorized delivery. Correction commit:
39d79aeee1bd5525c6ed2eb1369f6c27334b9d07, `test: derive removal preflight cache
paths from owned roots`; exactly two accepted test files, 6 insertions/5 deletions.
Production namespace/recovery code remains the six-file ca316db snapshot.
No unrelated dirty state or Payload was staged; index is empty.

Exact Package: .artifacts/s29-removal-namespace-39d79ae/review/com.rice.ai-codedb.
ZIP: .artifacts/s29-removal-namespace-39d79ae/com.rice.ai-codedb.zip.
ZIP SHA-256: 0e7ecdf88999c4c6a08f936c5026b3d2b7d5e5389965829ad58dcc2c0f126da6.
617 files/entries; 13,186,196 uncompressed bytes. All 617 files equal the corrected
accepted immutable overlay byte-for-byte (zero differences). Generation remains
poc.43 and runtime contract hash remains 69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.

Evidence root: .artifacts/delivery/s29-removal-namespace-39d79ae.

| Exact artifact gate | Result / evidence |
| --- | --- |
| Commit-stage and exact ZIP byte closure and production payload admission | PASS, 60 sources/zero mismatches, native VerifyOnly; export-a1.log |
| Required Package PathProvenanceOnly | PASS; path-provenance-a1.log |
| Affected namespace/preflight/handoff/removal/recovery isolation | PASS54/native_children=0/copied_project_only=true; namespace-a1.log |
| Original-byte Editor and full included Editor.Tests compilation | PASS/exit0; consumer-a1.log and consumer-tools/*-compile-a1.log |
| Exact member diagnostic/cache/UI and emitted fixture consumer | PASS, 13 original members, original assertions; consumer-tools/exact-ast-binding.txt and seam-run-a1.log |
| S29 reference JSON, equality, existing Package and only-reference text transform | PASS; both references select the exact Package above |
| Protected state before/after | PASS2844, only two allowed reference files differ; protected-check-a1.log |

The exact affected production functions use the accepted synthetic prerequisite,
PocFixture verification and process-absence seams. No product native child or
live process inspection/IPC/real operation was executed. The consumer extractor
and runner reuse the accepted test tooling, changing only the extractor's Package
input to the exact review root; original member text equality is checked. Native
Unity initialization and workspace allocation/cleanup remain NOT_RUN. Full
Install/Uninstall entry execution and real crash/restart remain NOT_RUN; production
Manifest call shapes and isolated helper recovery are separate evidence.

Before switching, no S29 Unity process or Temp/UnityLockfile existed. Backup:
.backups/s29-removal-namespace-39d79ae/{manifest,packages-lock}.json.
New reference in both Packages files:
file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-namespace-39d79ae/review/com.rice.ai-codedb.
Post-switch SHA-256:
manifest 3167fe9057071161875621d22afc532987f1aec28160c4e672a68ddffb16a59f;
lock 4a86d28e96739a4baa1e63b671bae50d6a287ef6fd23ce2b1d9f486d62fa21d7.
Receipt/control/history/.codex/dirty Payload and previous exact Packages are
unchanged across delivery. No real Install/Remove/Upgrade, history cleanup,
process control, environment edit, Unity launch, push or publication occurred.

Human next gate: REMOVAL-PREFLIGHT-NAMESPACE-HUMAN-CHECKLIST.md. Actual button
availability, current readiness, live recovery, Unity and release acceptance
remain distinct; S29/release stay PARTIAL and CleanupMono remains deferred.

## Completed and attributable

Source commit: ca316dba4a9567c754c92f0096d0b7a401a9a67d.
Subject: fix: align removal preflight with retired supervisor namespace.
Exactly the six accepted source/test files were committed (473 insertions,
23 deletions); the staged index is empty. Unrelated dirty state and dirty Payload
were not staged. Target generation remains poc.43 with no payload change.

Exact export: .artifacts/s29-removal-namespace-ca316db/review/com.rice.ai-codedb.
ZIP: .artifacts/s29-removal-namespace-ca316db/com.rice.ai-codedb.zip.
ZIP SHA-256: 100b4883dfd4bcc2b71fa00ce793963c0e0ac4a2ac7c706f9dfbd4d484e12448.
617 files/entries, 13,186,089 uncompressed bytes. Commit-stage and exact ZIP both
passed production payload admission, native VerifyOnly and byte closure (60
sources, zero mismatches). Runtime contract remains
69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.
Raw export evidence: .artifacts/delivery/s29-removal-namespace-ca316db/export-a1.log.

## Failed gate and stop

The exact extracted Package's existing
Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly exited 1:
`Package contains a machine-local absolute path: Tests/Editor/AICodedbEditorLifecycleTests.cs`.
The new AssertCachedRemovalFailure context embeds C:/codedb-synthetic/project
and C:/codedb-synthetic/package at line 47. These paths breach the workflow's
runtime-derived test-root requirement; the synthetic label is no exemption.
The source RESULT disclosed that the final path-provenance check was not run,
and source acceptance retained limits. Exporter byte/admission PASS alone does
not close this additional delivery gate.

Raw failure: .artifacts/delivery/s29-removal-namespace-ca316db/path-provenance-a1.log.
The failed artifact is preserved, not reused or silently repaired. No retry,
reference switch, Unity operation, real Install/Remove/Upgrade, history cleanup,
process control, environment change, push or publication occurred. Initial
checks found no S29 Unity process or project lock. Both S29 Package references
still select s29-version-transition-wrapper-handoff-d88a10.

Exact affected consumer/compile gates and human Unity acceptance were not started
after this failure. S29/release remain PARTIAL; CleanupMono remains deferred.

## Historical proposed disposition (fulfilled)

Return to user for a narrow FIX: change only this new test context's path source
to an existing runtime-derived test-owned root; keep cache/diagnostic assertions
and production behavior unchanged. Run focused path provenance and the immediate
cache regression, then read-only review and new source acceptance. Commit and
export a successor artifact after acceptance; never modify the observed ZIP.
The user subsequently approved the repair and accepted its independently reviewed
snapshot. The original proposal created no authority by itself; its repair and
acceptance are recorded in REMOVAL-PREFLIGHT-TEST-PATH-FIX-TASK/ACCEPTANCE.

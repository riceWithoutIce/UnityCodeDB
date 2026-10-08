# S29 fixture physical-path closure reassessment

Date: 2026-10-08. READ_ONLY_DIAGNOSIS / ROUTE_REASSESSMENT_REQUIRED.
Latest artifact: .artifacts/0.3.0-preview.5-s29-test-workspace-poc40/review/
com.rice.ai-codedb, commit332c7ffd510daebb6da6a386d66783d4aabf6bd6.
Source ACCEPT and byte closure remain historical source evidence; human gate fails.

## New human evidence

ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory(False,False)
fails with DirectoryNotFoundException writing admitted.json in
ManagerReceiptFixture.Add at exported ManagerUiTests.cs:89. Workspace.Run and
Complete preserve/rethrow the original stack; the old Dispose access exception
is not present in the supplied error. Screenshot shows four visible cases failed;
global counters0 green/6 failed/716 gray do not establish all62 selected-case results.
No claim about other groups' success is justified by this screenshot.
Screenshot codex-clipboard-296603a0-7fe6-4cd6-9663-d952d12a9460.png SHA256:
48EEF26B2AE76E0F07EC0474CAC552441277DAA91A58991815C0537CD43C3EFD.

Exact reported path length326 UTF-16 characters, parent directory312:
actual project + Library/CodeDB/Tests + run-GUID(36) + receipts-GUID(41) +
project physical key24 + Package physical key24 + action32 + stage64 + admitted.json13.
These lengths were calculated from the supplied string without touching live
directories or rerunning Unity. Production fixture code creates stageRoot before
writing; therefore a missing CreateDirectory call is not established.

## Cause boundary and missing design constraint

The full path exceeds legacy Windows MAX_PATH260 and traditional directory
creation limits. Unity/Mono long-path handling is the leading hypothesis for the
observed failure, not independently reproduced or proven as the sole cause.
No ACL/lock/process/registry/long-path-policy probe was performed.

The entry's capability test only uses capability-probe/probe.txt directly under
the run root. It does not exercise the actual nested receipt writer shape.
Consequently a successful shallow probe cannot establish deepest consumer-path
usability. Root ownership was corrected, but end-to-end physical-path length
closure was missing from both the frozen contract and its test/review coverage.
The already-existing production physical-key24 truncation comment explicitly
mentions legacy path length; it accounts for a different root and does not prove
every longer test-root composition is safe. Do not change real receipt identities
or truncate action/stage IDs to repair a fixture.

## Recommended coherent next route (not implemented)

Preserve actual-project Library ownership and isolated fixtures. At the test
workspace authority, plan compact owned physical paths across root and direct
consumers; eliminate redundant per-layer GUID expansion while retaining full
ownership tokens and exclusive directory allocation. Compute the longest required
file path (including direct temporary/publication names when applicable) before
body execution, and probe representative deepest create/read/delete operations
through the same Unity APIs. Boundary failures report exact length and operation,
without Temp fallback, drive substitution, privilege/registry changes, project
relocation requests, production identity rewrites or swallowed failures.

Define realistic successful and over-budget-root coverage in the same focused
fixture envelope. This should close physical path composition, not merely change
one constant or add a generic error. Other original business failures remain
unattributed until the human suite can execute. No blanket all-tests cause claim.

Review caught logical/root ownership, but missed physical-path feasibility at the
real consumer depth. Record this gap rather than relabeling source review as
runtime validation. Consolidate the two fixture failures before another source
repair/package/human rerun cycle; do not automatically redispatch a patch.
Next: User/Planner agrees the path-closure correction and evidence scope.
No source edits, tests, live filesystem cleanup, Unity control, export or commit.

## Human layout agreement - 2026-10-08

After discussing naming responsibilities, human approved the concrete r7k2/a9f3/
s01.admitted.json example. Documentation~/manager-receipt-storage-layout.md records
the canonical proposal, one test isolation root and shared production/test receipt
layout. Full identities remain record content; sample short names are not an
allocation algorithm. Locator uniqueness/recovery, index/discovery, legacy-record
policy and implementation closure are still pending. This supersedes a fixture-
name-only route as the proposed direction, without authorizing production changes
under the old test-only allowlist. No Coder dispatch or runtime migration yet.

## Refined rules approved and recorded - 2026-10-08

User approved retaining full Action IDs, prefix16 Stage file locators with full
identity collision refusal, short exclusive test roots, existing journal lookup
and old-layout read-only preservation/new compact writes. Canonical layout doc
and workflow/workspace/Host Action links now reflect these decisions. Example
162-character admitted path/199 with current C# temporary suffix is calculated,
not runtime proof. Exact schema, atomic allocation, journal format binding,
active-old-writer policy and cross-language change/evidence scope still require
implementation planning. No code, tests, migration or Coder dispatch authorized
by this document-only instruction.

# S29 retained-disposition refactor — review disposition

Date: 2026-10-12.
Status: USER_SOURCE_ACCEPTED / REFERENCE_SWITCH_COMPLETE / HUMAN_GATE_PENDING.

## Original stages (historical snapshot)

- Coder /root/retained_disposition_coder: terminal PASS_WITH_LIMITS; stable
  working-tree snapshot based on b76957a9dbcae9b00eff73775a97c4e8f33ae785.
- Verifier /root/retained_disposition_verifier: terminal BLOCKED, two P1/BLOCKER
  findings returned together. No further developer work or review is running.
- Eight frozen file hashes match SOURCE-SHA256.txt; seven allowlisted files
  changed, ProcessRunner unchanged. Scoped diff check passes.
- Parent verified 17 bounded protected-state hashes unchanged, including S29
  package references, desired/selection/candidate/intents/markers and protected
  payload declarations. This is not a whole-worktree immutability claim.
- Coder evidence: backend 47 checks PASS, native children=0; semantic errors=0;
  isolated consumer 13 cases PASS. Independent review did not rerun these tests.
  Those cases do not cover the actual admission post-publication or Window
  attachment paths found below.

## Original findings (closed by FIX review)

1. F1/P1: TryAdmit reads with SAFE retained observation before publishing the
   new index, then omits it in the mandatory identity re-read. The unchanged
   absent-origin retained candidate returns Conflict; dispatch is refused while
   the new pending index already exists. Exact action release reads are the
   nearest lifecycle regression and require a coherent observation policy.
2. F2/P1: SAFE aggregate legitimately clears the stale session; Window
   AttachCurrentActionSession returns on null without clearing its old
   in-flight/status projection, so the entry remains disabled.

Full independent evidence: RETAINED-DISPOSITION-ADMISSION-VERIFICATION.md.
Original source/synthetic evidence remains in the Coder RESULT; its passing
cases do not supersede these deterministic source contradictions.

## Approved FIX envelope

- Change only AICodedbManagerActionJournal.cs, AICodedbManagerWindow.cs and
  Tests/Editor/AICodedbManagerUiTests.cs within the already approved refactor.
- F1: keep the same attributable fresh classification through exact index
  admission/identity checks and immediate release regressions; retain journal
  locking, exact action ownership and confirmed backend revalidation. Do not
  turn cached UI evidence into a permit or erase unexpected ownership.
- F2: clear/rederive this Window's session projection when its same-project
  session is gone, without mutating foreign/running session or old outcomes.
- Focused evidence must reach actual TryAdmit with production-emitted SAFE
  observation, validate the new exact index and adjacent action lifecycle;
  reach Window attached recovering state -> SAFE aggregate -> current usable
  presentation. Cover unresolved/foreign owner refusal and repeated attachment.
- Preserve all other source and current runtime; no new generation migration,
  framework, cleanup, real operation, Unity, export, reference switch or commit.
- After one stable Coder FIX result, a read-only repair review checks F1/F2 and
  their nearest regressions only. No new comprehensive audit.
- If the narrow lifecycle correction cannot preserve authority within these
  paths, stop and return the specific gap rather than expanding this envelope.

## Human disposition

FIX approved by the user's latest "同意" on 2026-10-12 after both findings were
returned together. This approval covers the three-file repair and sequential
stable Coder snapshot -> read-only F1/F2 repair review, including only their
nearest regressions. Source acceptance was subsequently granted below;
delivery remains separately gated.

Reuse the stopped Coder, then the stopped Verifier. Parent remains active,
consumes questions/blockers and confirms each terminal completion. Preserve the
original BLOCKED review and SOURCE-SHA256.txt; record this correction separately
in RETAINED-DISPOSITION-ADMISSION-FIX-RESULT.md,
RETAINED-DISPOSITION-ADMISSION-FIX-SOURCE-SHA256.txt and
RETAINED-DISPOSITION-ADMISSION-FIX-VERIFICATION.md. No unchanged backend suite
rerun or additional live/delivery authority is granted.

The actual INSTALLED S29 generation/package mismatch remains a separate deferred
route even after these findings are closed. Unity/source/package/runtime/release
acceptance remain distinct; S29/release PARTIAL. Current exact human package and
references still point to b76957a; no real state was changed by this source stage.

## F1 lifecycle policy clarification within the approved envelope

The Coder proposed, and Planner confirmed, preserving the same fresh observation
for pre-publication and post-publication admission identity reads. Exact terminal
or pre-effect release authenticates the original action/index/history identity;
it does not act as a next-operation resource permit. A private release read mode
may omit origin-only candidate resource scanning while preserving journal lock,
receipt/marker authenticity and exact action/package/storage identity. New
admission must still obtain fresh owner observation and reject unresolved or
foreign ownership. The FIX result must identify the release call boundaries and
provide the directly adjacent refusal/ownership regressions. This clarification
does not authorize broader readers, backend mutation or actual release of real
history.

## FIX snapshot admission

Coder returned terminal PASS_WITH_LIMITS and stopped. New FIX RESULT and complete
eight-file FIX-SOURCE-SHA256 snapshot are attributable to base b76957a. Parent
checked new Journal/Window/tests hashes, seventeen protected-state hashes
(unchanged), and the scoped three-file diff check (PASS). Coder reports semantic
errors=0 and fifteen focused managed cases PASS; parent does not rerun them.
The original review/result/hash records remain separate. The stopped Verifier
was reused for the authorized F1/F2-only read-only repair review and returned
PASS_WITH_LIMITS with no remaining P1/P2/blocker.

## Source acceptance — 2026-10-12

User explicitly confirmed "同意 accept" after receiving the completed FIX and
independent repair review. Accepted source identity is the complete eight-file
snapshot in RETAINED-DISPOSITION-ADMISSION-FIX-SOURCE-SHA256.txt, based on
b76957a9dbcae9b00eff73775a97c4e8f33ae785. Parent rechecked all eight hashes at
acceptance: 8/8 match. F1/F2 are closed within the declared source/static and
synthetic evidence limits; both child stages have stopped.

This is source acceptance only. Next step is to align a bounded delivery scope
for local commit, exact export/closure and project reference switch, followed
by focused human Unity validation. None of those actions is authorized by this
acceptance record. Actual installed-generation mismatch remains a separate
deferred route; S29/release remain PARTIAL. Original failed review and all
result/hash records are preserved.

## Subsequent delivery disposition

User explicitly authorized commit -> exact export -> project reference switch ->
human Unity validation. Source commit 74c4db0 and its exact ZIP passed closure;
S29 manifest/lock now select the matching extracted review Package. See
RETAINED-DISPOSITION-DELIVERY-GRANT.md and RETAINED-DISPOSITION-DELIVERY-RESULT.md.
The focused human checklist is ready; native Unity and release remain unproved.

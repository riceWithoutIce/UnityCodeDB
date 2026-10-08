# S29 operation result semantics - independent verification

Date: 2026-10-08. Result: SOURCE_REVIEW_PASS / CSHARP_UNITY_EXECUTION_PENDING.
No actionable finding in the frozen source repair and adjacent regressions.
This is not C# compilation, executed C# semantic closure, human acceptance,
completed cleanup, product Ready, or S29 real integration acceptance.

## Reviewed identity and scope

Authority: RESULT-SEMANTICS-REVIEW-PACKET.md and
RESULT-SEMANTICS-IMPLEMENTATION-PLAN.md; the approved S29 Operation Result
Semantics Agreement in Documentation~/v0.3.0-p0-host-action-execution.md.
Coder had stopped before review. The review read the full packet, plan, Coder
result and identity, then the five frozen diffs and directly named dependencies.

HEAD independently matched `3b09859045d0d4547d9ba2cef332a550e8530f99`.
The Git index remained empty. All five changed-file SHA-256 values and lengths,
plus the unchanged production writer SHA-256 and length, independently matched
RESULT-SEMANTICS-IDENTITY.json. Journal, ManagerWindow and the production
materializer have no diff against HEAD. Planner's admitted seven-file protected
baseline check covers the payload/pointer and live project Package references;
this reviewer did not reopen live project state.

Read-only review except this report. No tests or harness reruns, live receipts,
Unity/MCP/BatchMode, process probes, installation/removal/replay, source edits,
commit/export, package-reference changes, delegation or Coder requests occurred.
Inherited work was preserved.

## Findings and reasoning

No BLOCKER, fix-required finding or additional follow-up was identified within
this bounded review. The diagnosed FAILED-only mismatch is closed at source:

- `ClassifyHistoricalNonSuccess` rejects absent authority, zero or mismatched
  exit, timeout, overflow, incomplete drain, malformed results and unsupported
  outcomes. It recognizes only BLOCKED/FAILED INSTALL + CANDIDATE + exact two
  scopes + PENDING, or UPGRADE + PREFLIGHT + empty scopes + COMPLETE. The strict
  parser still rejects duplicate or invalid scopes and schema violations.
- Both affected consumers call that shared entry. Existing three-stage count,
  authenticated script/arguments, terminal flags and identity checks remain.
  Recovery returns the original Install result object; Upgrade COMPLETE cannot
  replace its PENDING effects. Single-stage handling is unchanged.
- Journal and session restoration still interpret command termination separately
  from success. The historical warning retains original Package context and
  PENDING. Recognition does not dispatch a command or request Install reconcile;
  removal confirmation, presentation preflight and backend admission remain.
- The updated positive fixture covers FAILED and BLOCKED, single and three-stage
  results, pending and resolved history. Its sanitized DryRun now represents
  NEEDS_ATTENTION instead of synthetic UPGRADE_READY. Adjacent negative cases
  cover result contradictions plus missing/malformed/unbound/extra/duplicate
  stages, incomplete evidence and a mutating Upgrade.

Reason codes are preserved and asserted in representative output, rather than
treated as substitute identity/admission evidence, consistent with the agreement.

## Production writer and consumer evidence

The focused PowerShell branch parses the sibling production materializer and
imports its actual five function bodies and nine default initializers. It does
not dot-source or execute the materializer top-level entry, and returns before
the ordinary test harness executes. The inspected writer closure only emits the
result under supplied fixture context; it does not touch project state.

The authored Editor test resolves its own Package, invokes that Package's focused
script, and feeds original output lines into the production C# strict parser,
shared classifier and Actions predicate. Its default BLOCKED Install/Upgrade
outputs then traverse fixture-bound ProcessRunner, Journal and session recovery.
This tests a producer-to-consumer boundary instead of a copied JSON serializer.
The separate handwritten history fixtures preserve the relevant historical
field relationships and exercise retained effects/removal boundaries.

The child PowerShell uses the existing owned `Library/cdt/<8hex>` workspace for
working directory and TEMP/TMP; it introduces no system TEMP fallback. Execution
is bounded to 15 seconds with a 5-second drain wait. Timeout termination targets
only the Process object just created by the test. Output is drained concurrently;
the expected six records are checked and stdout length is capped by an assertion.
The fixed reviewed writer emits bounded output. Existing workspace cleanup and
session isolation are reused. Test entries are synchronous NUnit Test/TestCase,
with fully qualified PackageInfo; the earlier parameterized-async and attribute
compatibility failures are not reintroduced by these edits.

Executed evidence remains Coder-attributed: Windows PowerShell writer 6/6 and
scoped diff check passed. This reviewer did not rerun them. Source inspection
supports the authored 5-method / 45-case inventory. The six writer scenarios
inside one Editor test are not six additional NUnit cases.

## Required next evidence

Retain the human-owned C# compilation and 45 focused Editor cases as pending,
including `MaterializerResults_ProductionWriterFeedsHistoricalRecoveryAndSession`.
Check the exact extracted artifact under the existing delivery workflow: byte
closure cannot replace this pending real C# consumer execution. Manager observation
and separate real-project acceptance remain distinct; no real Install/Remove or
history rewrite follows from this source review.

The bounded independent review is complete. No expanded audit or additional
source fix is requested. Return the result to Planner/User for the normal source
acceptance and subsequent authorized delivery/human-validation stages.

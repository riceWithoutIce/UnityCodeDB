# S29 startup authentication boundary — frozen review packet

Date: 2026-10-13. Review mode: GUARDED. Scope: original repair and nearest regressions.
User authorized repair with “同意修复” and this task-scoped read-only Verifier
with “批准” after the concrete five-file review proposal. Delegation:
TASK_SPECIFIC, one depth-one Verifier, no further delegation.
This explicit review route applies only to this repair; it changes no standing
workflow or durable-session policy. Parent remains active until terminal completion.

## Frozen objective

1. Historical retained closure accepts authenticated historical selection without
   demanding the current Package's operational Editor lease.
2. Supervisor owner authentication stays distinct from operational readiness;
   foreign/malformed authority stays fail-closed.
3. TrustedPrevious historical removal reaches the existing independent removal
   preflight, never granting bootstrap, Ready or removal permission on identity alone.
4. A proven unrelated older unowned candidate may become historical information;
   related/current, active-holder or ambiguous candidates remain fail-closed.

## Stable inputs

Base/current HEAD: 04e9a6bd49ae46f5c10989f6e4c6efddc479ad24.
Branch: codex/v0.3.0-legacy-workflow. Uncommitted stable Coder snapshot.
Read STARTUP-AUTH-BOUNDARY-REPAIR-RESULT.md and
STARTUP-AUTH-BOUNDARY-REPAIR-SOURCE-SHA256.txt in this directory.

Five files, full paths relative to repository:

- com.rice.ai-codedb/Editor/AICodedbControlContract.cs
- com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs
- com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
- com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs

Review the diff against the base SHA and narrowly necessary adjacent readers,
contracts and recorded harness evidence. Preserve all unrelated dirty state.
No whole-repository audit, added requirements, historical cleanup or source edits.

## Evidence and outcome

Coder declares current-source Roslyn 34-file zero-error semantic compilation;
seven focused methods / 51 standalone cases PASS; actual S29 source reader
returns Empty journal and TrustedPrevious selection; four protected hashes
unchanged. Native Unity/lifecycle, UI, live IPC, real mutation and release are
not claimed. Review evidence attribution and the explicit limits; do not rerun
unchanged tests, build harnesses, start Unity/MCP/BatchMode/CUA, execute product
scripts or Probe/Ensure/Install/Upgrade/Remove, or control any process.

Verifier owns only STARTUP-AUTH-BOUNDARY-REPAIR-VERIFICATION.md in this directory
and may write that consolidated report with apply_patch. It must verify source
hash admission once, return material findings together and stop. It may send
questions to the parent; it must not contact a Coder, assign repairs, spawn
agents, commit, export, switch references, push or publish.

BLOCKER is limited to normal user-path unavailability, data/configuration damage,
possible external-process interference or an unsupported key release promise.
Theoretical hardening, rare races, style/refactoring and undeclared requirements
are FOLLOW-UP. An unrun native gate already explicitly deferred is not itself a
new source blocker. Review budget: standard, up to 15 active minutes; one scoped
batch, bounded outputs. Report PASS_WITH_LIMITS or findings supported by concrete
paths/lines and causal reasoning. Source ACCEPT remains the human's decision.

## F-01 repair and targeted re-review grant

Human approved “定向修正这处文件名，再只复核该 finding 和紧邻回归”
with “同意” after the first Verifier returned PASS_WITH_LIMITS / F-01 FOLLOW-UP.
Reuse the completed same-task Verifier under the existing TASK_SPECIFIC grant;
parent remains active until terminal completion. This is no new broad review.
Read STARTUP-AUTH-BOUNDARY-REPAIR-F01-RESULT.md and
STARTUP-AUTH-BOUNDARY-REPAIR-F01-SOURCE-SHA256.txt for the replacement snapshot.
Previous result/hash/review remain historical evidence, not current byte admission.
Review only the corrected coordinator filename, its isolated case, and adjacent
holder/history behavior. Other three source hashes are unchanged. Do not rerun
tests, compile or perform live operations. Verifier owns only the new report
STARTUP-AUTH-BOUNDARY-REPAIR-F01-VERIFICATION.md; preserve the first review.
Stop when F-01 disposition and nearest regression conclusion are recorded.

## Source acceptance — 2026-10-14

Human “同意 accept” accepts the final five-file F01 hash snapshot after F-01
was closed by targeted independent review. All five current hashes matched at
acceptance. See STARTUP-AUTH-BOUNDARY-REPAIR-ACCEPTANCE.md for the authoritative
disposition and remaining gates. Source repair/review are complete; this grant
does not authorize commit, export, reference switching or a real operation.

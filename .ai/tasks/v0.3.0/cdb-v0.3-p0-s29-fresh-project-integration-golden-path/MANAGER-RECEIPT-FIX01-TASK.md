# S29 Manager receipt B-MR-01 correction

Date: 2026-10-08. User chose FIX (`同意`) after the independent report.
This continues the same semantic-closure task; it is not a broader audit or a
new architecture. Original task, diagnosis, Coder result and review are retained.

## Frozen scope

Close B-MR-01: recognize the actual supported Redeploy stage chain through the
existing receipt authority so successful work does not become Indeterminate.
Preserve authenticated stage validation, original failed-INSTALL/PENDING semantics,
strict unknown/conflict rejection, lifecycle isolation and original-context UI.
Recognizing a declared stage chain is not permission to skip arbitrary nonterminal
stages or select the latest receipt. The original invariant against additional
mutations means unrecognized effects, not the legitimate named Redeploy mutation.

Base HEAD 651f9b3b4a8af3108823036107f1d76bc450f760; stopped nine-file identity in
MANAGER-RECEIPT-REPAIR-RESULT.md is the fix baseline. Branch unchanged. Mode
FAST_SUBAGENT / TASK_SPECIFIC / GUARDED; depth one and single writer. Reuse stopped
Coder, then stopped independent Verifier only after a stable handoff. Inherit
model/effort, max 60m Coder / 30m Verifier. No recursive delegation/Coder contact
from Verifier. Parent owns this task, children own their result/review records.

## Write and read closure

Same nine source/test/contract paths as MANAGER-RECEIPT-REPAIR-TASK.md; change only
what B-MR-01 and its immediate regressions require. Preserve all prior edits and
the original dirty contract prefix. Expected edits: ProcessRunner recovery,
shared Redeploy stage declarations only if directly needed, focused Manager
tests and bounded contract correction. Do not alter unrelated accepted behavior.
Coder writes MANAGER-RECEIPT-FIX01-RESULT.md. Verifier writes
MANAGER-RECEIPT-FIX01-VERIFICATION.md; original reports remain immutable.
Read prior finding B-MR-01 and named source/test callers, not cumulative TASK,
history or whole-repo logs. Scope follows existing producer -> reader -> journal
-> session admission, including resolved marker after Package replacement.

## Required evidence

- Production-reader fixtures for real Manager four-stage Redeploy and supported
  three-stage worker path, through immediate session admission and resolved marker.
- Explicitly preserve meaning of each nonterminal stage and the unique legitimate
  terminal. Check existing early-failure behavior of these same stages; do not
  erase mutation/failure evidence or turn missing final evidence into success.
- Adjacent rejection cases: extra/unknown mutation, wrong terminal attribution,
  malformed or unbound stages, incomplete chain; retain original historical
  failed-INSTALL/PENDING tests. No generalized historical recovery engine.
- One focused source consistency batch, scoped diff-check and final nine-path
  SHA256 manifest. Tests are authored, NOT RUN: no existing pure harness applies;
  do not create external compilation or Unity substitute infrastructure.
  List exact new/changed human test methods and cases. Earlier 19 tests were also
  NOT RUN and must not be relabeled. No repeat old 48/11/201 suites.

Non-Unity initial + up to two causally justified corrections per scenario, two
mechanical pre-effect corrections. No unchanged reruns. Read slices preferably
<=40 lines/4KiB; command <=200 lines/32KiB, rg <=50 matches/16KiB, cumulative
<=128KiB. Prior output breaches remain disclosed; use symbol-local reads, no
repeat large source batches. Result <=16KiB. Stop at unresolved scope/authority
expansion or budget; one consolidated handoff rather than command approvals.

No Unity/MCP/CUA/BatchMode, live process or journal probe, artifact/generation/
project reference edits, real Install/Remove/replay, commit/export/push. Unity
remains human-owned. Whole S29 is PARTIAL. F-IMC-01/P3 remains DEFERRED.

## Review and handoff

Coder implements, records actual evidence and exact snapshot, then stops.
Planner verifies identities; independent Verifier checks only original B-MR-01
and immediate regressions without tests or comprehensive audit. Findings once
to user; no automatic corrective dispatch. Source PASS is not Unity acceptance.

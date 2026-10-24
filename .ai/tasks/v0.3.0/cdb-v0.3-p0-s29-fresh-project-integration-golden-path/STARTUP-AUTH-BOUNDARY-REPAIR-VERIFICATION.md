# S29 startup authentication boundary — independent verification

Date: 2026-10-13. Mode: GUARDED, one scoped static review.
Verdict: **PASS_WITH_LIMITS**, with one non-blocking FOLLOW-UP below.
Human source ACCEPT, follow-up disposition and delivery/live gates remain pending.

## Admission and authority

Read the frozen TASK, Coder RESULT and SOURCE-SHA256 packet completely before
source review. One SHA256 admission check matched all five recorded files:
AICodedbControlContract.cs, AICodedbEditorLifecycle.cs,
AICodedbManagerActionJournal.cs, AICodedbEditorLifecycleTests.cs and
AICodedbManagerUiTests.cs. HEAD matches the declared base
`04e9a6bd49ae46f5c10989f6e4c6efddc479ad24`.
The reviewed source is the stable uncommitted snapshot, not an exported or
referenced installed Package. The index/dirty workspace was inspected without
alteration; unrelated dirty documents, payload and projects were preserved.

Only the five-file base diff and directly necessary selection, integration,
Supervisor protocol/readiness, lease producers and recorded harness source
were inspected. No tests, compilation, product scripts, Unity/MCP/BatchMode/CUA,
Probe/Ensure/Install/Upgrade/Remove, process control, commit, export, reference
switch or cleanup ran. This report is the only Verifier write. No agent was
dispatched and no repair was requested from a Coder.

## Frozen claims and nearest regressions

| Claim | Static conclusion and evidence |
| --- | --- |
| Historical retained closure accepts authenticated selection without operational lease | PASS. Journal lines 605–624 accept Current or TrustedPrevious, reject the retained instance itself, and retain the fresh INSTALL origin check. Desired-state/project checks, Package-mismatch handling and applicable committed-handoff checks remain. CurrentInstanceStatus.EditorLeaseRelativePath and CanPublishEditorLease remain separate; the historical-selection fixture explicitly asserts no lease capability. |
| Supervisor authentication is distinct from operational readiness | PASS. ControlContract lines 1834–1915 accept protocol-defined state/reason and failure-category domains while retaining exact readiness fields and project/runtime/selection/target/contract/owner/epoch/PID binding. The prior owner/process-response checks remain. Foreign or invalid responses still throw into InvalidOrAmbiguous; transport uncertainty remains transient. This migration classification grants no product Ready: the separate lifecycle terminal-success predicate at lines 3644–3658 still requires successful command, current product layers, authenticated terminal observation and CoreReady. |
| Historical removal reaches independent preflight despite operational migration failure | PASS. Lifecycle lines 956–958 avoid the operational-auth retry for an authenticated TrustedPrevious selection; lines 975–1006 route before lease admission and the fast path. TryRouteHistoricalRemoval lines 1549–1588 still requires Installed + TrustedPrevious, blocks operational admission first, respects cancellation/context validity, rejects untrustworthy/missing prerequisites and calls the existing preflight only after trustworthy current prerequisite evidence. WithRemovalPreflight lines 1636–1664 obtains HasAuthenticatedRemovalPreflight from the backend result; identity alone does not set the permit or Ready. Invalid/obsolete/transient migration now reaches that route, rather than authorizing backend mutation. |
| Unrelated older unowned candidate is informational; related/active/unknown holder is blocking | PASS_WITH_LIMIT below. Journal lines 1033–1145 require project/instance/path/generation/worker closure, a Package-declared older predecessor, independently Installed/committed selected records, a different instance/generation and no observed lease holder. Current/related generation, broken identity/closure and incomplete selected-control proof return Conflict. Lines 1205–1372 validate Editor/instance/generation lease identities and treat recent heartbeat, extant PID or unknown process lookup as blocking; only valid stale leases with absent PID are ignored. These lease checks match the inspected production lease fields. Runtime-state presence guard has the filename mismatch recorded as F-01. |

Read/exception paths continue to convert classification failures into Conflict;
the classifier does not delete candidates, rewrite original receipts, release
an index, or infer success from an unknown historical action.

## Consolidated finding

**F-01 — FOLLOW-UP (non-blocking): the coordinator runtime-state guard names a
different file from the producer.**

- Consumer: `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs:1271–1275`
  checks `watch/coordinator/state.json`, `watch/state.json` and `retiring.json`.
- Producer: `com.rice.ai-codedb/Payload~/Generations/poc.39/coordinator/codedb-watch-coordinator.mjs:16`
  defines `STATE_FILE = "coordinator-state.json"`; line 108 joins that name to
  the coordinator runtime. The inspected poc.42 producer uses the same name at
  lines 17 and 109. Its existing PowerShell reader uses
  `watch/coordinator/coordinator-state.json` in
  `com.rice.ai-codedb/Payload~/Generations/poc.42/scripts/codedb-project-common.ps1:658`.
- Trigger: otherwise independently authenticated unrelated older unowned
  PROVISIONING candidate, no active/unknown lease holder, but the real
  `watch/coordinator/coordinator-state.json` remains. This includes a stale
  lease with absent owner PID and an unexamined coordinator state record.
- Effect: that state file does not trigger "unresolved runtime authority";
  the candidate can become a historical warning and the journal can be Empty.
  Therefore the broad Coder statement that runtime authority always remains
  blocking needs this qualification. This is a source-derived branch result,
  not an executed fixture or a finding about the present S29 project's state.
- Severity: FOLLOW-UP under the frozen user boundary. Active/unknown generation
  lease checks still block before this guard, and the production coordinator
  acquires its watcher generation lease (poc.39 line 656; poc.42 line 674).
  This review has not established an active holder bypass, a normal user-path
  failure, data/configuration damage or external-process interference.
  Independent removal/backend gates were not executed or bypassed by this
  classifier. User decides repair, defer or accept; no source repair was made.

No BLOCKER was established. No new full-audit or validation requirement is
introduced by this review.

## Evidence attribution and limits

The seven focused methods have 51 declared TestCase inputs (15/4/11/3/6/4/8),
matching the Coder result and standalone dispatcher. The harness source uses
the current Editor/test files; Semantic.cs parses unmodified source with C# 9
and Unity managed references; Standalone.cs explicitly adapts native/static
Editor dependencies and assertions, and RuntimeTests.cs invokes the seven
methods plus the read-only actual-reference journal/selection diagnostic.
Assertions still apply resolved NUnit constraints and throw on failure.

The recorded 34-file zero-error semantic compilation and 51-case PASS are
**Coder-reported execution evidence**, not rerun or independently reproduced
by this Verifier. This review confirms their declared source/harness scope and
the exact five-file admission, not a new compilation/test PASS. The retained
fixture invokes the changed private validator rather than independently
replaying the entire retained-effects producer chain. Lifecycle delegate cases
prove routing/order, cancellation and preflight refusal, not native lifecycle
or real removal. The current-source real-reference read does not prove that
the referenced installed Package contains this repair.

Native Unity import/EditMode/lifecycle/UI, live Supervisor IPC, sustained
readiness, real mutation/removal, delivery and release acceptance are NOT RUN.
The reported protected-state hashes and real-project Empty/TrustedPrevious
diagnostic remain attributed to the Coder packet; they were not rerun here.
S29/release remain PARTIAL. This concentrated review ends with the above
follow-up returned together for human disposition.

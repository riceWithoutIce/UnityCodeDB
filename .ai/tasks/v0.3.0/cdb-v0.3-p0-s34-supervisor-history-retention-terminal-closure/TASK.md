# Task: cdb-v0.3-p0-s34-supervisor-history-retention-terminal-closure

## Metadata

- Product/version: UnityCodeDB v0.3, current-version lifecycle repair.
- Workflow: codedb-workflow-v2 revision 2.6.
- Status: DELIVERY_AUTHORIZED / COMMIT_PENDING.
- Planner: current parent. Coder: one task-scoped implementation role, pending.
- Verifier: one subsequent independent targeted read-only role, pending.
- Review mode: GUARDED.
- Execution mode: FAST_SUBAGENT, user-approved task-local exception to the
  cross-layer persistent-evidence DURABLE_SESSION default on 2026-10-19.
- Execution profile: deep, Coder 60 minutes / Verifier 30 minutes;
  inherited parent model/reasoning, user-approved, no model override.
- Delegation authorization: TASK_SPECIFIC; user `批准` on 2026-10-19.
- Session policy: SPAWN_BOUNDED, sequential Coder then Verifier.
- Requirement source: S33 normal uninstall -> same-version Install refusal;
  user `好的 同意` on 2026-10-19 accepts the bounded two-part repair proposal.

## Objective and frozen contract

Routine Supervisor maintenance history must converge without blocking normal
reinstall solely through accumulated inert records. A request invalidated before
execution must have truthful, complete terminal semantics shared by producer and
consumer. Preserve execution attribution and unknown/live-execution refusal.

Cause record and design authority: S33 HISTORY-CONVERGENCE-PROPOSAL.md and
REINSTALL-RESULT.md in the sibling S33 task. The 5301-record history contains
3532 completed Probe, 1767 completed Upgrade, one completed Uninstall and one
failed/invalidated Probe. The latter is the canonical record and has UNKNOWN
disposition; lowering the count alone is not a completed repair.

1. Bound routine historical retention at the owning producer/maintenance boundary
   using existing serialization, without racing active writes or partial removal.
   Protect current/active operations, Manager action map references, instance
   origins, retirement/removal references and incomplete/unknown evidence.
   Classify complete attributable execution before retention; labels or age alone
   never establish that a child did not run. Keep map/operation references closed.
2. Specify one complete pre-execution invalidation result. NO_CHILD is allowed
   only at a boundary where the producer knows execution has not started. The
   shared helper also handles admission publication failures: distinguish them
   from queued cancellation and running/unknown execution. Keep reason codes,
   honest timing, result flags and matching consumer interpretation.
3. Keep resource bounds; do not solve by raising/removing 4096, selecting only
   recent N before classification, ignoring failed history, or changing UNKNOWN
   to NO_CHILD on reads. Preserve original failure and immutable result evidence.
4. Existing S33 canonical UNKNOWN is a separately reported compatibility limit.
   Do not backfill, rewrite, delete or archive it to bypass admission. Report the
   exact remaining baseline disposition needed after source repair; do not claim
   new-producer tests repair existing evidence or complete S33 reinstall.
5. Use the same producer/reader contract for directly affected Install and removal
   paths. Do not duplicate authority or add a new history database/recovery engine.

## Scope and ownership

Change allowlist relative to com.rice.ai-codedb, necessary hunks only:

- Tools~/codedb-project-supervisor.mjs
- Tools~/codedb-instance-engine.ps1
- Tools~/materialize-codedb-host-payload.ps1
- Tests~/test-codedb-project-supervisor.mjs
- Tests~/test-codedb-host-payload-materializer.ps1

Coder additionally owns this task's RESULT.md. Planner owns TASK.md; Verifier
owns VERIFICATION.md only. No concurrent implementation/review write phases.

Read-only closure: direct references from those paths; existing Manager journal/
Supervisor Bridge operation readers, runtime-contract path loaders, instance
origin and retirement/removal records, and their nearest existing test helpers.
Read workflow entry/modules and isolation spec before test execution. If another
consumer requires editing or the contract needs broader migration, stop and
return that concrete dependency rather than widening the allowlist.

Protected: all incoming dirty hunks; active source engine has incoming changes
(15 additions/9 deletions) that belong to the prior work and must be preserved.
S33/S30/S29 runtime/config/history, machine receipts, delivered b0462ed extraction,
all payload generations and existing artifacts/backups stay unchanged. Never
export the current dirty checkout or edit an imported Package extraction.

Snapshot binding: before Coder edits, preserve attributable allowlisted source
hashes/scoped diff under a fresh repository-local .artifacts/tests/s34-history/
run directory. No checkout/reset/stash/commit. Record final hashes and touched
hunks for admission, retaining the incoming source baseline.

## Execution envelope

- Approved scope: bounded implementation, same-cause repair, focused local
  evidence and consolidated result under the accepted proposal. User `批准`
  approves the task-scoped Coder -> read-only Verifier pipeline and route/model
  inheritance exception. Continue the authorized stages without another start
  or review-stage confirmation; parent monitors through terminal completion.
- Delivery authorization: NONE. No commit/export/reference switch/publication.
- Artifacts: fresh repository-local .artifacts/tests/s34-history/<run-id>/;
  path escape/redirect checks and no overwrite of old evidence. No system temp
  fallback, machine paths in durable records or new Unity project.
- L0: syntax and actual producer behavior for explicit queued NO_CHILD terminal,
  unknown/running preservation, and retention decisions/reference preservation.
- Affected L1: actual Node-produced operation records consumed by PowerShell
  Install/removal validators; repeated routine history beyond the former bound;
  pinned records; unknown/malformed/incomplete records; retention interruption.
  Exercise retained evidence through existing production helpers in a synthetic
  project. No Provider/model acquisition or real project process is needed.
- Add narrow selectors to the existing harnesses if necessary. Do not execute
  their unfiltered whole suites. Prefer production-path behavior assertions over
  source-text checks or a test that only changes the maximum-count constant.
- Explicitly not run: Unity/EditMode/MCP/BatchMode, real Install/Uninstall,
  S33 maintenance, process termination, model/provider work, full regression.
- One initial focused L0 and affected L1 batch; at most two same-cause corrected
  semantic attempts per scenario, plus two mechanical corrections. Stop on an
  independent third cause or wider architecture/authority requirement.
- Active budgets: Coder DEEP_60M, Verifier 30M; test maximum wait 300 seconds,
  bounded commands/output and escalation follow workflow. No repeat unchanged
  tests; Verifier does not rerun Coder's passed batch.
- Local fixture writes only. Launch any fixture-owned child only if required by
  the selected test and isolation contract; no live runtime/process operation.
- Stop for uncertain references/ownership, inaccessible needed evidence, wider
  consumer changes, history migration, or a second historical recovery branch.

## Definition of done and handoff

Source result closes both coupled causes with preserved uncertain execution and
focused cross-language evidence. Stable final snapshot precedes independent
Verifier review, limited to this contract, its changed files and nearest regressions.
Findings return together to User; no direct Verifier-to-Coder repair requests.
Passing local evidence is source evidence only. S33 remains reinstall-failed
until a later separately approved delivery, baseline disposition and real attempt.
Console log reduction and Manager reopen UX remain deferred.

Current task: S34 supervisor history retention and terminal closure.
Current status: READY / EXECUTION_ROUTE_AUTHORIZED.
Next notification: task-scoped Coder, by current Planner.
Next action: bounded preflight, implementation and focused local evidence;
then Planner snapshot admission and independent Verifier review.
Human decision or authorization required: none inside this frozen envelope;
source acceptance, delivery and live operations retain separate decisions.

## Coder and Verifier consolidation - 2026-10-19

Coder returned COMPLETE / PASS with focused CONTRACT_ISOLATED evidence; see
RESULT.md. The stable five-file snapshot was admitted after final SHA correction
for the existing engine hunk. Independent read-only Verifier returned PASS with
no frozen-scope blocker; see VERIFICATION.md. It confirmed fail-closed
NO_CHILD/running/unknown semantics, bounded identity-safe retention, reference
preservation, hash recheck and unchanged 4096 reader bound.

Source acceptance is now the only pending decision for this task. Acceptance does
not authorize commit, export, Package reference switching, real S33 history
maintenance or another Install. The existing S33 canonical UNKNOWN record,
Console noise and Manager reopen UX remain separately recorded limitations.

## Source acceptance - 2026-10-19

User explicitly accepts the stable S34 source snapshot after Coder PASS and
independent Verifier PASS. This closes source acceptance only. Commit, exact
Package export, S33 reference switching, real history maintenance and the next
human Install remain separate delivery/acceptance gates.

## Delivery authorization - 2026-10-19

User `同意授权` authorizes the bounded group: exact commit of the accepted S34
source/test snapshot and task records, commit-derived Package export and closure
核对, then S33 Package reference switch while S33 Unity is closed. This does not
authorize real history cleanup, Install, Unity launch, process control or commit
of unrelated dirty files. After the reference switch, human Install -> Ready is
a separate acceptance action.

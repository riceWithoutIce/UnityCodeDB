# Task: cdb-v0.3-p0-s32-install-project-command-closure

## Metadata

- Product/version: UnityCodeDB v0.3
- Workflow: codedb-workflow-v2, revision 2.6
- Status: SOURCE_ACCEPTED / DELIVERED / HUMAN_REPORTED_PASS_WITH_LIMITS
- Planner: current parent; Coder: one task-scoped implementation role
- Verifier: required independent targeted read-only role
- Review mode: GUARDED
- Execution mode: FAST_SUBAGENT; user-approved task-local exception to the
  cross-layer DURABLE_SESSION default, 2026-10-17
- Execution profile: bounded lifecycle repair, inherited model settings;
  task-local route as approved, no model escalation
- Delegation authorization: TASK_SPECIFIC
- Session policy: SPAWN_BOUNDED; one Coder, then one read-only Verifier
- Requirement source: v0.3 roadmap current-version lifecycle; user-approved
  Install responsibility split and subsequent `同意批准` on 2026-10-17

## Objective

New Manager Install requests use the existing controlled project-level writer
and installation engine without first starting an instance-dependent Supervisor.
First Install and Install after normal logical uninstall share this route.
Preserve initialization, ownership/admission, result integrity, and independent
post-install readiness. Do not solve reinstall by deleting normal history.

Cause/evidence: S30 REINSTALL-ACCEPTANCE-RESULT-2026-10-17.md under
`../cdb-v0.3-p0-s30-current-version-lifecycle-acceptance/`.
The delivered S31-D Package is diagnosis authority; implementation is based on
the active source with the incoming dirty hunks preserved, not by editing that
immutable extraction.

## Frozen Behavior And Consumer Closure

1. New Install execution deliberately enters the existing direct writer and
   materializer. No Supervisor-start-then-fallback, broadened bootstrap exception,
   instance-less resident Supervisor, duplicate executor or result store.
2. Reuse existing confirmed Manager admission, action/project/Package/command
   identity, writer claim, project lock and locked next-change revalidation.
   Establish whether these close competing Supervisor/runtime execution as well;
   a file's absence is not proof that execution is absent. Add only the bounded
   coupled checks needed for this supported route. Existing attributable completed
   uninstall history is not by itself an active-owner conflict. Live, unknown or
   conflicting execution must not be admitted, ignored or terminated.
3. Preserve original install initialization, prerequisites, candidate verification,
   activation and configuration behavior. Already-installed requests cannot bypass
   existing desired-state checks. Preserve Uninstall and other action routing.
4. Manager normal result and reopen consume the actual admitted execution route.
   Do not merely reclassify all old Install titles as direct-only or lose competing
   direct/Supervisor authority detection. Old insufficient records remain unknown;
   no backfill, blanket migration or auto-retry. Existing new S30 pending action
   is not recovered or released by this task.
5. Trusted complete writer success/failure ends the exact command accordingly;
   retained effects separately constrain later mutations. A proved pre-effect
   refusal uses exact authenticated evidence; exit codes/error strings alone do
   not prove no dispatch. Claimed/dispatched execution without complete terminal
   remains Unknown and must not unlock/retry. Success does not itself mean Ready.
6. Post-command reconcile and Supervisor connection use existing policy after
   activation. Test the existing cleanup/readiness distinction; do not weaken a
   readiness rule just to obtain Ready. An independent readiness defect is returned
   for disposition, not absorbed into this task.

Coder question clarified within this envelope: bounded read-only process
identity observation under the existing project lock is part of execution
admission, not permission for process control or a general collector. Reuse
existing retirement/identity helpers, scope observations to relevant project
execution, and do not turn inaccessible/unattributable metadata into a claim
of global process absence. A new route marker must close through the existing
journal/action-manifest producer and normal/reopen readers; legacy dual-route
records and same-action competing authority checks remain intact. If existing
claim/retirement authority cannot establish safety, return that boundary.

## Scope

Change allowlist relative to `com.rice.ai-codedb/` (only directly needed hunks):

- `Editor/AICodedbActions.cs`
- `Editor/AICodedbHostPayloadMaterializer.cs`
- `Editor/AICodedbManagerWindow.cs`
- `AICodedbManagerActionSession` is contained in `Editor/AICodedbManagerWindow.cs`;
  do not create a separate duplicate session implementation
- `Editor/AICodedbManagerActionJournal.cs`
- `Editor/AICodedbProcessRunner.cs`: Install admission/evidence only; preserve
  incoming durable-writer timeout changes
- `Editor/AICodedbSupervisorBridge.cs`: bounded read-only ownership/evidence
  helpers only; no weakening Supervisor startup/selection or replaying commands
- Optional dedicated `Editor/AICodedbInstallAdmission.cs` and `.meta`, solely
  for this entry's shared admission/route validation
- `Tools~/codedb-instance-engine.ps1`: Install admission/locked execution only;
  incoming repeated-Uninstall idempotence hunk is protected
- `Tools~/invoke-codedb-manager-action.ps1`: coupled Install authentication only;
  incoming transaction timeout/termination hunks are protected
- `Tests/Editor/AICodedbManagerUiTests.cs`
- `Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Optional dedicated `Tests/Editor/AICodedbS32InstallTests.cs` and `.meta`
- `Tests~/test-codedb-host-payload-materializer.ps1`: focused scenario/entry only
- `Tests~/test-codedb-project-supervisor.mjs`: focused conflict fixture/entry only
- `Documentation~/v0.3.0-p0-host-action-execution.md`: dated append of this
  responsibility contract only, preserving incoming documentation edits
- Coder-owned `RESULT.md`, task-local `run-focused.ps1` and fixture source helpers

Read closure: DIRECT_REFERENCES_ONLY, including existing paths/strict JSON,
Supervisor protocol/terminal evidence, action metadata, command status parsers,
materializer locks/identity and test workspace. No repository-wide audit.

Protected: incoming dirty files/hunks; all Payload generations/manifests; S29;
S30 project/config/runtime, failed action `6b9678672d3744f0ab052e521ae42ad6`,
its pending index, prior baseline archive/backups; all delivered Packages and
previous evidence; Provider/model assets; all external processes. Baseline HEAD
is `97471f537749eba97171f6756a29112dd552a22b`; BASELINE-SHA256.md binds
incoming allowlisted bytes. Do not reset, stage, clean, or export dirty source.

Out of scope: Provider/S31-B, historical recovery, PID termination, physical
cleanup, pending-index archival, shutdown/CleanupMono diagnosis, UI redesign,
payload/generation change, real lifecycle operations, Unity, delivery/release.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE
- Approved grant: user `同意批准` approves the preceding concrete proposal for
  this bounded source repair, isolation and Coder -> read-only Verifier pipeline,
  including task-local child routing. Parent remains active through completion.
- Delivery authorization: NONE. No commit, export, reference switch, push or publish.
- Coder actions: bounded preflight; implement the frozen vertical route; focused
  same-scope correction; produce stable final hashes, changed-hunk ownership and
  consolidated evidence/limits. Do not return only a plan/ACK.
- L0: original affected Editor/test source compilation using existing local
  compiler/reference bindings; focused route/result classification and script syntax.
- Affected L1: actual Manager entry -> existing writer/admission -> real receipt
  reader -> Manager/session/journal recovery in task-owned fixtures. Exercise
  normal-uninstall topology with retained operation history, not merely an empty
  runtime. For engine safety, invoke original bounded admission/locked functions;
  do not emulate a successful production install with fabricated result strings.
- Scenarios: first Install reaches controlled writer; normal uninstall then Install
  is not routed to missing-selection Supervisor; repeated/live/unknown/conflicting
  authority refuses without dispatch; complete failure, pre-effect refusal, missing
  terminal and success stay distinct; reopen does not dispatch/retry and preserves
  conflict checks; initialization and post-install reconcile policy remain unchanged.
- Evidence level: CONTRACT_ISOLATED or HARNESS as actually established. Real
  Provider startup/full installation and human Ready remain DEFERRED. If original
  production dependency closure is missing, classify ENVIRONMENT_INCOMPLETE once;
  do not acquire models, download tools or widen isolation to a whole machine.
- Existing tools: bindings from `.artifacts/tests/s31c-f1-20261017-a/manifest.json`
  and `.artifacts/tests/s31b-r2/build/editor.rsp`; prior S31-D driver is reusable
  reference. No Unity launch or new Editor/tool discovery/install.
- Output roots: fresh children of `.artifacts/tests/s32-install/`; all fixture,
  receipt, runtime, temp and child-local storage roots must be derived and verified
  repository-local, non-redirected, and declared before writers start. Keep tool
  hashes, redirects, network policy and child roles in the evidence manifest.
- Path provenance: admitted context/canonical production contracts, no machine
  literals or fixture-specific product branches. Keep tracked records repo-relative.
- Generation transition: NONE; Package export/closure gates deferred to delivery.
- Explicitly not run: full regression, Unity/MCP/BatchMode, live Supervisor/backend,
  actual Install/Uninstall, external config/process changes, real S30 recovery.
- Test rationale: routing defect spans C# command admission, PowerShell execution
  and C# result recovery; syntax or clean-bootstrap-only tests do not close it.
- Mechanical corrections per scenario: 2
- Corrected semantic attempts per scenario: 2
- Independent product causes before reassessment: 2
- Active time budget: STANDARD_30M for Coder, STANDARD_15M for Verifier
- Output budget: V2_DEFAULT
- Broad search/full diff/full regression: FORBIDDEN
- EditMode authorization: NOT_REQUESTED; Editor compatibility level NONE
- Side effects: only source allowlist and task-owned fixtures/output, existing
  bounded compiler/test children. No external process termination or network.
- Stop: objective/authority/allowlist expansion; unknown path/process ownership;
  missing dependency changes evidence class; repeated isolation repair; budget
  exhaustion; full ownership closure needs broader Supervisor redesign.
- Mode-promotion: default workflow triggers beyond this approved route design.
- Structural guard: repair iterations 0/2, independent product causes 1/2,
  diagnostic-only checkpoints 0/3; immediate structural triggers apply.
- Model escalation: NONE

## Definition Of Done

Stable attributable active-source snapshot and final hashes; incoming dirty hunks
preserved; one focused declared evidence batch with exact limits; targeted
independent Verifier report on routing, ownership and terminal/reopen integrity.
Return all findings together for User ACCEPT/FIX/DEFER/STOP. Do not claim real
reinstall, initialization/Provider readiness, Unity or release acceptance.

## Handoff

- Current task: S32 Install project-command closure
- Current status: SOURCE_ACCEPTED / HARNESS PASS_WITH_LIMITS
- Next notification: User/current parent Planner
- Next action: align bounded real lifecycle acceptance and baseline
- Human decision required: next real route and protected historical-state
  disposition; no automatic recovery or retry

### Stable Snapshot Admission — 2026-10-17

Coder reported terminal completion and stopped. Parent verified all 11 final
product/test/meta hashes, 262 frozen manifest tool/reference/source inputs,
driver hash, four declared unchanged allowlist-source hashes and all ten
protected parent-baseline hashes. HEAD remains the bound source commit and
staged index is empty. Scoped diff check passes; no unchanged tests were rerun.
Review is admitted for the exact RESULT snapshot and its explicit HARNESS
limitations. No complete production L1, Unity, real reinstall or delivery claim
is admitted. The engine safety fixture mocks process inventory/validated retained
closure; runtime producer/reader evidence starts at original ProcessRunner,
not a live Unity Actions call. Existing pending S30 remains protected.

Final consolidation: independent Verifier completed and stopped with two scoped
P1/BLOCKER findings in the new Install admission guard. F1: unrelated shell/Node
rows with inaccessible metadata are treated as project conflicts before project
relevance is established. F2: terminal labels/child absence are accepted without
complete terminal-result validation. Route/result closure has no additional
findings. Parent confirmed the 11 frozen source hashes and ten protected inputs
remain unchanged after review. No tests were rerun and no repairs were assigned
to Coder. See DECISION.md; user disposition is pending.

### User-approved F1/F2 repair amendment — 2026-10-18

User `ok 同意 我们继续` approves the concrete convergence plan discussed after
VERIFICATION.md. This supersedes the initial machine-wide same-name process
blocking and exhaustive history-directory admission strategy. It authorizes
same-task F1/F2 source/fixture correction and targeted independent repair review,
not delivery, real lifecycle execution, index reconciliation or process control.
Existing child handles are not available in this session; the approved task-scoped
Coder -> Verifier pipeline may use replacement depth-one roles with the same
frozen packet, inherited settings and single-writer separation.

Frozen repair decisions:

- Determine execution relevance from this project's current action/writer,
  Supervisor, operation, instance and retirement bindings. A machine-wide row
  named PowerShell/Node with inaccessible metadata alone is not a project blocker.
  Known-related live/unknown identity remains refused. Do not claim global absence.
- Examine history referenced by current state and unclosed execution evidence;
  do not make exhaustive historical audit a prerequisite. Project-local unbound
  or conflicting execution evidence cannot be silently ignored. Separate active
  execution authority from inert history without introducing a cleanup/migration.
- Before relying on bounded project evidence, verify the original production
  entry points establish attributable authority before managed side effects.
  Trace direct writer admission/claim and Supervisor owner/operation/child
  publication. If an existing gap prevents safe scoped admission, return the
  specific boundary; do not widen ownership infrastructure or silently drop scans.
- A record used as completed-execution proof must close the existing compatible
  terminal contract (schema, identity, timestamps, result and completeness).
  Missing/malformed/timed-out/output-incomplete evidence stays unknown; complete
  failure stays failure and existing retained-effect checks remain authoritative.
- Preserve project lock, route marker, direct/legacy readers, exact release,
  initialization, readiness and existing unknown/repeat-request behavior.

Repair write scope narrows to the new Install admission code in
`Tools~/codedb-instance-engine.ps1`, directly coupled S32 tests/task drivers,
and only a directly necessary correction to the S32 contract append. Existing
allowlisted route readers may be read, not opportunistically rewritten.
`RESULT.md` is appended by Coder with repaired hashes and evidence; original
`VERIFICATION.md` is immutable; Verifier owns new `VERIFICATION-F1-F2.md`.
No changes to Supervisor producers or unrelated historical code are authorized.

Focused repair evidence: unrelated inaccessible process does not block;
project-bound live/unknown execution still blocks; PID reuse follows existing
identity rules; complete retained uninstall permits execution admission;
referenced missing/malformed/timeout/output-incomplete/conflicting execution
refuses; complete failure remains distinguishable. Add source-backed coverage
of the original pre-effect authority publication ordering. Use original production
functions under task-owned lock/fixtures, with honest HARNESS limitations.
Run only changed F1/F2 scenarios and their immediate route/result regression,
not a new full suite or unchanged full batch. Preserve all previous attempts.

Incoming repair snapshot: the 11 hashes in RESULT.md matched on parent preflight;
HEAD unchanged and staged index empty; ten parent protected hashes matched.
Budgets remain initial plus two mechanical corrections and two causally justified
semantic corrections per changed scenario, Coder 30 minutes / Verifier 15 minutes.
Starting repair iteration 1/2; independent causes 2/2, diagnostic checkpoints 0/3.
Any independent new cause or broader authority need stops for disposition.
Parent stays active through terminal Coder completion and subsequent review.

Current handoff: approved bounded repair in progress; source not accepted.
Next: stable Coder result -> parent admission -> F1/F2-only Verifier -> User.

Repair admission — 2026-10-18: replacement Coder is terminal and stopped, no
test sessions remain running. Parent verified all 11 final hashes using the
two RESULT overrides, final repair manifest source/tool/reference/build inputs,
both repair driver hashes and ten protected baseline inputs. Original
VERIFICATION.md and original frozen manifest hashes are unchanged; HEAD remains
the original baseline, staged index empty, scoped diff check passes. Attempts
and the consumed correction allowances are recorded in RESULT. No unchanged
tests were rerun. Admit one F1/F2-only independent repair review, including
the source-backed producer-order prerequisite and declared HARNESS limits.

Repair review consolidation: VERIFICATION-F1-F2.md closes F1 and the original
unsafe F2 terminal acceptance, but retains an adjacent normal-path blocker:
original successful ensure/reconcile can persist child:null without spawning;
new discovery refuses it before current/inert selection. Parent verified the
producer and unchanged frozen/protected hashes. Both roles stopped. No further
repair/test loop is started; repair iteration and correction limits reached.
See ROUTE-REASSESSMENT.md for the bounded producer/consumer semantics decision.
Source remains not accepted; no delivery or real retry authorization exists.

### Approved execution-disposition refactor — 2026-10-18

User `批准` approves the minimum existing operation producer/consumer proposal
and Coder -> targeted read-only Verifier. This is the explicit bounded REFACTOR
disposition for ROUTE-REASSESSMENT.md, not automatic continuation of its exhausted
patch allowance. Read DISPOSITION-REFACTOR-PLAN.md as this task's new frozen
execution envelope. It supersedes only the prior no-producer-edit restriction
and old exhausted test budget for the newly approved contract. Same task and
objective; old snapshots/reviews stay immutable. All real-state/delivery exclusions
continue. Parent remains active through terminal Coder and Verifier completion.

Disposition snapshot admission: Coder is terminal/stopped with no test sessions.
Parent verified all 14 cumulative final source/test/meta hashes from RESULT
with latest overrides, the disposition-b source/tool/reference manifest inputs,
three driver hashes and ten protected baseline inputs. Original reviews and
prior evidence remain preserved. HEAD unchanged, staged empty, scoped diff
check passes. No unchanged tests rerun. Admit one independent disposition/F2
nearby review; evidence is original producer/serializer -> actual locked PS
reader with mocked status/process/retained inputs, honestly HARNESS. No C#
source changed; direct C# readers retain existing spawned-Uninstall semantics.

Disposition review consolidation - 2026-10-18: independent Verifier completed
and stopped. VERIFICATION-DISPOSITION.md returns PASS_WITH_LIMITS and no scoped
findings. Original F1 and F2 complete-result corrections remain closed; explicit
new NO_CHILD producer evidence closes the adjacent no-child normal-path blocker.
Legacy UNKNOWN, failed capture, hidden unfinished execution and relevant
live/unknown identity still refuse. Parent confirmed all 14 frozen source hashes,
ten protected inputs, unchanged HEAD and empty staged index; scoped diff check
passes. No tests were rerun. Both roles are terminal. Source ACCEPT is the next
user decision; no commit/export/reference switch, pending-action recovery or real
lifecycle retry is authorized. HARNESS evidence does not establish real Install,
initialization, Provider, Ready or Unity acceptance.

### User source ACCEPT - 2026-10-18

User `同意 accept 我们继续` accepts the final RESULT snapshot and
VERIFICATION-DISPOSITION.md's PASS_WITH_LIMITS. Source review is closed.
Continue into reversible precise delivery preparation only. Existing incoming
dirty hunks and Payload remain protected; a concrete commit/export/S30 reference
switch proposal requires explicit group authorization under workflow coordination.
No real Install/Uninstall, pending-action recovery, Unity or process control is
authorized by source acceptance.

Precise delivery preparation completed: see DELIVERY-PLAN.md. Local 623-file
candidate has exactly 14 task files (ten exact source, four task-only projections),
all non-task bytes equal committed base/poc.43. Candidate Editor/test compilation
and path provenance pass; three existing warnings unchanged. Source hashes and
ten protected inputs match, HEAD unchanged, index empty. No distributable export
or semantic-test replay. Request one bounded grant for the exact projections,
precise commit -> exact artifact gates/focused extracted checks -> S30 reference
switch. Real pending-action/history handling and lifecycle retry remain excluded.

User `授权` on 2026-10-18 approves DELIVERY-PLAN.md's exact candidate/projections
and complete bounded delivery group. Execute without repeated stage approval.
Only 14 candidate blobs may enter the commit. Preserve incoming working state;
stop dependent delivery at a failed exact-artifact gate. S30 runtime/history/
pending action, real Install/Uninstall, Unity launch and process control remain
outside the grant.

Authorized group delivery completed on 2026-10-18: precise 14-file commit
b0462ed07b6a14be64bddf848e67609d9143fa71; exact ZIP byte/identity/production
admission/native/path checks and focused extracted route/result/admission/
disposition evidence all pass. S30 was closed; backed-up Package references now
agree on the exact extraction, all other fields preserved. See DELIVERY-RESULT.md.
Human Unity is pending via HUMAN-CHECKLIST.md. No real Install/Uninstall, old
pending-action/history recovery or process control occurred or is implied.

Human result - 2026-10-18: user reports Test Runner all passed, Manager open-close
and Unity exit normal. Screenshot retains the protected old Install unknown
outcome and current uninstalled status, as expected; no new Install is inferred.
Read-only follow-up confirms references/ZIP/original 623 Package hashes and
eight remaining protected inputs; S30 process/lock absent, HEAD/index unchanged.
One additional import-generated test .meta is preserved and recorded separately.
Tab switching/standalone compilation were not separately reported. See
HUMAN-RESULT.md for precise evidence and limits. No repeat run, source repair,
real lifecycle action or historical recovery follows automatically.

# Task: S29 historical identity / automatic handoff capability separation

## Metadata

- Product/version: UnityCodeDB v0.3.0 / existing S29.
- Workflow: codedb-workflow-v2 revision 2.6.
- Status: READY / NARROWED_OUTCOME_AUTHORIZED.
- Planner: current parent; Coder and Verifier: task-scoped roles, not dispatched.
- Review: GUARDED, limited to this route and adjacent regressions.
- Execution mode: DURABLE_SESSION by the workflow's cross-layer authority rule.
- Session policy: REUSE_ONLY by default. No reusable child handles are present
  in the current agent inventory; no durable session was created or contacted.
- Delegation: TASK_SPECIFIC. User's `同意，继续` accepts the proposed source
  task and Coder -> stable snapshot -> Verifier chain; subsequent `批准`
  explicitly approves the new bounded-child transport exception below.
  Previous task-only routing exceptions do not transfer.
- Profiles: deep budgets (Coder 60 minutes / Verifier 30 minutes). Proposed
  exception keeps the current session's model/reasoning by inheritance; record
  the actual settings and catalog mismatch, without silently selecting another
  model. Model/profile override is not requested.
- Requirement source: current user-approved responsibility separation,
  STARTUP-READINESS-ROUTING-DIAGNOSIS-2026-10-13.md, existing S29 golden path
  in the active roadmap, and the historical-removal contract proposal.
- Base SHA: 9eac17cfdb741f89d33a4b7c2ddf6261abcb9566.

## Objective

An exact Package-declared predecessor establishes historical identity, not
automatic Upgrade permission. Prevent the selected-v2 predecessor with a
different runtime authority from entering automatic Upgrade on initialize,
reconcile or reopen. Expose the existing controlled removal/reinstall route
through authenticated preflight; preserve supported automatic-handoff cases
only where their independent authority is proven.

This is one source/synthetic outcome. General historical Upgrade remains out
of scope; strict backend activation validation must stay intact.

## Scope and producer / consumer map

Use existing canonical records and APIs. No new serialized field, persistence
file, protocol, generic parser or generation declaration is authorized.
The already approved optional source_runtime_contract_sha256 may be projected
and validated by the C# transition reader as historical evidence; its presence
alone is never an Upgrade or removal permit.

| Boundary | Responsibility / focused evidence |
| --- | --- |
| Package payload-manifest bootstrap_transitions -> C# runtime transition loader | Project existing predecessor runtime evidence with lowercase hash validation and compatible absent-field semantics; preserve duplicate/identity/closure checks. |
| Exact historical closure -> current-instance status | Keep historical trust distinct from automatic-handoff capability. Unknown/malformed/conflicting evidence fails closed. Classification may recommend removal; only backend preflight authenticates removal. |
| Current-instance status -> lifecycle admission/scheduled reconcile | Ineligible previous-v2 takes reinstall-required handling before automatic Deploy/Upgrade and before publishing an operational lease based solely on historical trust. Reopen/reconcile cannot repeat this unsupported Upgrade. |
| Previous-instance status -> Probe output -> actual C# product reader | Retain existing tags/parser compatibility and remove the unsupported automatic-handoff promise for this route. NeedsAttention retains a clear next action and no fabricated Ready. |
| Lifecycle -> removal preflight -> Manager action presentation | Existing authenticated handoff/result controls Remove Integration visibility; unavailable/foreign/stale evidence keeps it closed. Do not force Install/Uninstall or cache a new permit. |
| Supported handoff and ordinary current/first-install paths | Existing strict generic next-change/activation rules remain authoritative; no historical-removal context enters general Upgrade. Preserve only demonstrated supported behavior. |

Implementation allowlist, relative to com.rice.ai-codedb:

- Editor/AICodedbPackageRuntimeContract.cs — existing optional predecessor
  runtime evidence projection only, no schema addition or identity redesign.
- Editor/AICodedbProjectIntegrationState.cs — historical/capability distinction
  and accurate existing status/detail; no admission bypass.
- Editor/AICodedbEditorLifecycle.cs — affected admission, convergence,
  scheduled-repeat and existing removal-preflight routing only.
- Editor/AICodedbHostPayloadMaterializer.cs — directly affected existing
  product attention/reinstall projection only if needed for the same route.
- Tools~/codedb-instance-engine.ps1 — corresponding previous-instance Probe
  observation/classification output only. Strict next-change, activation,
  Upgrade/removal authorization and transaction writers are protected.
- Tests/Editor/AICodedbEditorLifecycleTests.cs — production routing and
  existing removal-preflight/Manager-facing projection evidence.
- Tests/Editor/AICodedbHistoricalHandoffCapabilityTests.cs — dedicated focused
  producer/real-reader/classifier tests, if existing tests cannot isolate them.
- Tests~/test-codedb-host-payload-materializer.ps1 — one isolated focused
  switch/batch for the changed Probe output and its direct refusal cases.

Coder owns HISTORICAL-HANDOFF-CAPABILITY-RESULT.md and
HISTORICAL-HANDOFF-CAPABILITY-SOURCE-SHA256.txt. Verifier owns only
HISTORICAL-HANDOFF-CAPABILITY-VERIFICATION.md. Planner owns this card/disposition.
No other production/test edits are authorized. New adjacent reader changes,
serialized capability or a newly required architecture go back to Planner/User.

Read closure: named functions' direct callers/readers, existing Package runtime
contract, control/activation authentication, Manager removal presentation,
product parser, test workspace owner and reusable compiler/fixture harness.
Node runtime-contract readers and canonical generator are read-only references
if needed to prove unchanged field compatibility. No broad repository audit.

## Frozen source and protected state

The working-tree Payload/OwnerIdentity fixture is dirty and does not represent
the accepted delivered identity. Use the exact upgrade-callsite-fix-34b3a65
Package as immutable input for a new owned candidate under
.artifacts/tests/s29-historical-handoff-capability/. Overlay only allowlisted
source/tests; do not rebuild Payload or overwrite a previous artifact. Source
edits may be applied to clean allowlisted tracked files; capture hashes first.

Target input: successor43 generation hash
55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5;
runtime authority 69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.
Preserved predecessor42 hash
2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026;
declared source runtime hash
538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d.
These are evidence bindings, never production hard-coded exceptions.

Protect all real projects and Package references, current/desired/activation/
operation records, machine receipts/indexes, old candidate/intents, running
processes, installed immutable generations, earlier artifacts/backups and all
inherited dirty/untracked state. No reset, clean, whole staging or cleanup.
Generation transition: NONE; no Payload bytes or generation identity change.

## Execution envelope

- User grant: `同意，继续` after the source-task and Coder/Verifier proposal.
  Covers bounded source repair, focused evidence and consolidated review once
  the transport route is approved. Source acceptance remains a later decision.
- Delivery and external side-effect authorization: NONE. No Unity, MCP,
  BatchMode, CUA, live Probe/Ensure, process stop, Install/Upgrade/Remove/
  Uninstall, reference switch, export, commit/push/publication or history cleanup.
- Coder starts with one scoped state/hash check, then records the exact
  supported-handoff and removal-only decision map before editing. Do not infer
  Upgrade eligibility from the predecessor tuple or hash equality alone.
- Test ownership: derive the repository-local isolated run root from checkout
  context; follow test-workspace-contract.md, preserve failures and restoration.
  Pure test seams cannot touch real S29/machine journals or launch a Provider.
- L0: changed PowerShell syntax, actual C# Editor/test compilation using the
  existing approved installed compiler/harness without launching Unity, and
  the focused Package PathProvenanceOnly gate on the isolated source overlay.
- Affected L1: one tightly coupled C# production-reader/lifecycle projection
  batch and one production PowerShell Probe-output batch in owned fixtures.
  Reuse existing Mono test execution for pure methods; no assertion/source
  rewriting to manufacture PASS. External Provider/IPC/process effects remain
  explicit test seams, never substituted live evidence.
- Required scenarios: exact predecessor-v2 plus different runtime hash;
  demonstrated compatible handoff; missing/malformed/conflicting predecessor
  evidence; wrong closure/foreign identity; unchanged missing/current/legacy-v1
  routing; initial/repeated reconciliation with no unsupported Upgrade; supported
  Upgrade still selected where proven; authenticated removal-preflight PASS
  versus unavailable/refused evidence; actual changed Probe output consumed by
  the production C# product parser; Ready cannot be inferred from old Provider
  state or a historical outcome.
- Evidence is derived from the diff. No unchanged full backend/Editor suite,
  actual selected runtime activation or live historical-removal execution.
- Compatibility field projection and changed output need actual producer bytes
  through real consumers. Record source/artifact bindings and any seams once.
- Before freeze: allowlisted whitespace/diff summary, source hashes, scoped
  protected-state comparison, named evidence results and exact deferred gates.
  Do not run a repository-wide diff/check or regenerate dirty Payload metadata.
- Budgets: initial plus two causally corrected semantic attempts per declared
  batch; two mechanical corrections; workflow V2_DEFAULT output/time limits.
  Coder 60 minutes, Verifier 30 minutes. Preserve failed output, report truncation.
- Stop on required scope/schema/reader expansion, unprovable supported handoff,
  conflicting architecture, protected-byte overlap, missing compiler/fixture
  prerequisite or exhausted evidence budget. Return concrete minimum scope.
- Structural guard: this route is the user-approved responsibility-separation
  response to the known semantic conflict; no extra compatibility hole is
  authorized. Starting repair iterations 0/2, independent causes 1/2,
  diagnostic-only checkpoints 1/3. New structural signals require reassessment.

## Independent review and completion

After Coder terminal completion, parent admits result/Base SHA/file hashes and
protection evidence once, then dispatches one read-only Verifier. Parent remains
active through both child stages, consumes questions/blockers and confirms
terminal status. Coder and Verifier never run concurrently; neither delegates.
Verifier reviews this frozen routing/capability contract, direct consumer
evidence and nearest regressions only; no unchanged test reruns or broad audit.
All findings return together to User for ACCEPT/FIX/DEFER/STOP.

Done: stable bounded source/synthetic snapshot, no unsupported automatic
Upgrade for removal-only predecessor, preserved supported routes and strict
backend validation, accurate removal-preflight presentation, declared focused
evidence and independent review. Real Unity reopen, controlled removal/fresh43
Install, continuous Ready, latest unexplained NONZERO_EXIT, CleanupMono and
release remain deferred separate gates. S29/release remain PARTIAL.

## Approved execution transport — 2026-10-13

Use one newly created depth-one bounded Coder, then one newly created read-only
Verifier, for this task only. This is an explicit exception to the normative
DURABLE_SESSION/REUSE_ONLY route because the former child handles are unavailable.
It does not create/rebind a durable chat, expand source/operations, override the
model or authorize another task. Parent waits through terminal completion.
User replied `批准` to this exact task-only route proposal. Dispatch and the
named source/focused-test/review stages are now authorized; no further stage
confirmation is required inside this frozen envelope.

Current task: S29 historical-handoff capability separation.
Current status: COMPLETE / SOURCE_ACCEPTED_WITH_LIMITS.
Next notification: Planner/User, delivery decision for the accepted snapshot.
Next action: if requested, prepare a concrete commit -> exact Package export ->
reference-switch proposal; do not execute any of those actions implicitly.
Human decision or authorization required: separate authorization for named
delivery actions, then separate human Unity acceptance. The accepted source
snapshot still has the `RequireReady` wording FOLLOW-UP and unrun Unity,
Provider, real Remove/Install/Upgrade and release gates.

## Source disposition — 2026-10-13

User explicitly replied `accept` after the Coder result and independent
Verifier `PASS_WITH_LIMITS`. This accepts the bounded five-file
removal-only source snapshot and its stated focused evidence limits. It does
not accept the FOLLOW-UP wording as fixed, and it does not authorize commit,
export, Package reference switching, Unity launch, real Remove/Install/Upgrade,
cleanup, push or release publication.

## Approved narrowed compatibility boundary — 2026-10-13

User replied `同意` to the exact recommendation A in
HISTORICAL-HANDOFF-CAPABILITY-ROUTE-REASSESSMENT.md. This amendment overrides
the earlier requirement to demonstrate/preserve selected-v2 previous-generation
automatic Upgrade and supersedes that now-resolved stop condition.

Exact Package-authenticated previous-v2 is removal/reinstall-only in this task.
Preserve its historical identity and diagnostic bindings; route it to existing
reinstall-required handling before operational lease, Coordinator startup and
automatic Deploy/Upgrade. Initial/repeated reconcile, an existing lease and
later lease-refresh helpers must honor that same boundary. Backend removal
preflight remains the sole removal eligibility evidence; unavailable/foreign
evidence cannot open a button. Generic activation/Upgrade authentication stays
unchanged. No new read-only admission schema or automatic Upgrade observation
is authorized. Do not project the optional historical runtime field merely to
deny unsupported automatic Upgrade.

Missing/current convergence, obsolete-v1 refusal and existing flat routes remain
unchanged. Selected-v2 automatic previous-generation Upgrade is explicitly
DEFERRED; older schema-1 fixtures do not prove that capability. Update only the
directly coupled fixture expectations justified by this approved decision and
retain actual producer/reader and removal-preflight evidence in the existing
focused batches. All other frozen allowlists, protected state and exclusions
remain in force. Original scope-stop evidence stays in RESULT with an appended
implementation outcome; its original unchanged hashes remain attributable.

Continue the already approved bounded Coder -> stable snapshot -> read-only
Verifier transport without another stage confirmation. Test attempts consumed
before this amendment: 0. No commit, export, reference switch, Unity or real
Remove/Install/Upgrade action is authorized.

## HH-01 FIX authorization — 2026-10-13

User replied `同意 fix` to the bounded repair proposal in
HISTORICAL-HANDOFF-CAPABILITY-DELIVERY-PREPARATION.md. This authorizes repair
of HH-01 and its nearest regressions, followed by reuse of the stopped task
Coder and then stopped read-only Verifier. It does not authorize delivery or
new operational effects. Preserve the previously accepted five-file baseline
and original acceptance/evidence; changed bytes require a new source disposition.

Additional edits are limited to Editor/AICodedbEditorLifecycle.cs and
Tests/Editor/AICodedbEditorLifecycleTests.cs, plus
Tests~/test-codedb-host-payload-materializer.ps1 only if necessary to correct
the existing changed-Probe fixture binding. Other accepted source files are
read-only in this fix. Coder appends one correction outcome to RESULT and
refreshes SOURCE-SHA256 while retaining baseline bindings. Verifier writes the
task-designated HISTORICAL-HANDOFF-CAPABILITY-VERIFICATION.md; preserve the
prior report at VERIFICATION.md without overwriting it again.

Frozen evidence: actual worker/directly consumed production routing seam for
no lease first/repeated reconcile and existing lease; before lease/start/Probe
and before backend no-reconcile returns; valid authenticated removal preflight
versus refused/unavailable evidence; preserved prerequisite/migration/invalid/
uninstalled/cancellation guards; unchanged current/missing routing. Also close
the existing changed Probe producer -> real C# product reader scenario and
focused Package PathProvenanceOnly on an isolated immutable-Package overlay.
No source/assertion rewriting in a generated harness to manufacture PASS.
Non-Unity semantic compiler/test adaptation may use existing documented seams;
keep native/Unity/Provider/IPC effects synthetic and declared. No new schema,
generic admission weakening or unchanged full suite.

Budgets do not reset: one initial semantic attempt was already consumed for
each original C#/PowerShell L1 scenario; at most two causally corrected semantic
attempts remain per scenario. Newly required HH-01 adjacent routing cases join
that focused C# batch. PathProvenanceOnly has no recorded attempt. Record actual
commands, source/Package bindings, owned log locations and consumed attempts.
Coder deep 60 minutes / Verifier deep 30 minutes. Stop and report concrete
prerequisites if a required unavailable environment/reader or larger allowlist
is needed; do not quietly drop evidence or repeat an unchanged failing run.

Use a new owned overlay under .artifacts/tests/s29-historical-handoff-capability/
from s29-upgrade-callsite-fix-34b3a65; never overlay dirty Payload or mutate a
frozen artifact. Follow the existing test workspace owner/isolation contract.
Preserve real projects, receipts, history, references and processes. No Unity,
MCP, BatchMode, CUA, live Probe/Ensure, Provider launch, Install/Upgrade/Remove,
process control, cleanup, commit/export/reference switch, push or publication.
RequireReady wording, automatic selected-v2 Upgrade and CleanupMono stay deferred.

Current task: S29 historical-handoff capability separation / HH-01.
Current status: DELIVERED / HUMAN_TEST_UI_CLOSE_PASS / PRODUCT_AUTH_UNRESOLVED.
Next notification: User, consolidated source/evidence result.
Next action: align remaining product authentication; do not replay delivery.
Human decision required: new source ACCEPT after consolidated targeted review;
delivery remains separately unauthorized. Parent remains active through children.

Coder and designated Verifier previously reached terminal completion. User has
now replied `同意` to the concrete limited evidence-completion proposal at the
end of HISTORICAL-HANDOFF-CAPABILITY-DELIVERY-PREPARATION.md. This renews only
the declared evidence budget and the one additional test-file allowlist for
E-01/E-02/E-03; it does not reset prior attempts or authorize production
changes, Unity, operational actions or delivery. Parent remains active through
the reused Coder and subsequent read-only Verifier terminal states.

## Evidence continuation terminal disposition — 2026-10-13

The renewed Coder and targeted read-only Verifier both reached terminal state.
HH-01 source ordering is CLOSED. E-01 original-byte Editor/Tests compile and
E-02 producer-to-original-Editor.dll reader are CLOSED WITH LIMITS. E-03 remains
BLOCKED on the unchanged outside-allowlist ManagerUiTests.cs:1845 fixed path.
The workspace-bound preflight test is compiled but NOT EXECUTED because its
Unity main-thread boundary is human-owned. Earlier invalid harness/log history
and RequireReady FOLLOW-UP remain preserved. Overall PACKAGE_PATH_GATE_NOT_PASS;
no new source ACCEPT or delivery authorization is claimed.

## E-03 FIX authorization — 2026-10-13

User replied `同意批准` to the exact pending recommendation. This authorizes
only the pure `RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot`
test-path repair in `Tests/Editor/AICodedbManagerUiTests.cs`, its original-byte
focused compilation, and one PathProvenanceOnly evidence attempt with at most
two causally corrected attempts. Derive the base path and variants from the
existing test-owned workspace context; preserve same-root/case/separator
acceptance and relative/different-root/malformed rejection. Do not weaken or
change the production comparator. Do not rerun unchanged HH-01 cases, alter
other fixed paths, execute Unity, or perform commit/export/reference switching.
Use a new immutable overlay and distinct logs; parent remains active through
Coder and targeted read-only Verifier terminal completion.

## E-03 terminal disposition — 2026-10-13

The authorized E-03 slice is complete. The named fixture derives its root from
the existing workspace owner; production comparison logic and refusal/acceptance
assertions remain unchanged. Affected original-byte Tests compilation is
CLOSED WITH LIMITS (exit 0/errors 0). The pure comparator method is
HUMAN-UNITY-PENDING because its workspace owner requires
UnitySynchronizationContext/Application.dataPath. PathProvenance still fails
only on the next outside-allowlist literal in
Tests~/test-codedb-retained-entry-routing.ps1:181. Overall status remains
PACKAGE_PATH_GATE_NOT_PASS. No further per-file repair is authorized by this
slice, and no commit/export/reference switch has occurred.

## E-04 FIX authorization — 2026-10-13

User replied `同意` to the recommendation to repair only the remaining
`Tests~/test-codedb-retained-entry-routing.ps1:181` fixture literals. This
authorizes one narrow test-fixture correction, original-byte focused script/
Tests compilation and PathProvenanceOnly evidence with the existing bounded
attempt policy. Derive invalid samples from the existing owned fixture context
or use a test-owned path construction that preserves malformed/different-root
rejection; do not weaken production path validation or remove the rejection
cases. Do not modify any other fixed path, rerun HH-01, execute Unity, or do
commit/export/reference switching. Parent remains active through reused Coder
and targeted read-only Verifier terminal completion.

## E-04 terminal disposition — 2026-10-13

Both reused child roles reached terminal completion. E-04 fixture correction is
CLOSED; original-byte Tests compilation is CLOSED WITH LIMITS; PathProvenance
is PASS and the original E-03 Package path blocker is CLOSED. HH-01 and
E-01/E-02 remain closed within their declared source/isolated evidence classes.
Parent verified eight terminal source hashes against the latest record with
zero mismatches; HEAD remains 9eac17cfdb741f89d33a4b7c2ddf6261abcb9566 and the
ordinary staged index is empty. No new finding was returned by targeted review.

Current source is ready for user ACCEPT WITH LIMITS, not already accepted.
The workspace-owned comparator and preflight Unity tests remain NOT RUN /
HUMAN_UNITY_PENDING; actual lifecycle, lease IO, Provider and real actions are
not proved by the pure seam. RequireReady wording and CleanupMono remain
deferred. Historical invalid attempts and overwritten-log limits are preserved.
No commit, export, reference switch, process control, real Remove/Install/Upgrade,
Unity launch, push or release has occurred. S29/release remain PARTIAL.

## Source disposition — 2026-10-13

User replied `同意 accept`. This accepts the current eight-file source/test
snapshot with the recorded focused-evidence limits. It does not accept the
Unity comparator/preflight behavior, authorize Unity launch, or authorize
commit, export, Package reference switching, real actions, push or publication.
The next step is delivery preparation only.

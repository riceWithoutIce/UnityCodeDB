# S29 version-transition observation and historical authority

Date: 2026-10-14, Asia/Shanghai.

## Metadata and authority

- Product: UnityCodeDB v0.3.0 / existing S29.
- Workflow: codedb-workflow-v2 revision 2.6.
- Status: DELIVERY_COMPLETE; exact package/reference switch complete, human Unity gate pending.
- Planner: parent. Proposed Coder: completed historical_handoff_coder;
  proposed Verifier: completed startup_auth_boundary_verifier, after Coder stops.
- Review mode: GUARDED; original problem and nearest regressions only.
- Execution mode: DURABLE_SESSION. Proposed exception: reuse the existing
  task-scoped Coder then Verifier for this task only, without creating a chat,
  rebinding a durable profile, changing model settings or recursive delegation.
- Profiles: v0.3.coder.deep / v0.3.verifier.deep budgets; existing session settings.
- Delegation authorization: TASK_SPECIFIC. User explicitly approved
  "批准复用 Coder → Verifier（推荐）" for this task's proposed route.
- Session policy: REUSE_ONLY. Parent remains active, consumes questions and
  verifies terminal completion of each child.
- Requirement source: user agreement with the 2026-10-14 diagnosis and proposal
  to complete version-transition classification and combination tests.
- Delivery authorization: NONE. Source acceptance remains a later user decision.

## Objective and frozen meaning

An authenticated installed predecessor and a different target Package must be
classified consistently through production retained observation, Manager journal,
session and UI. Runtime admission remains strict. Historical ownership and
removability are independent decisions, never inferred from readiness failure.
No successful result is promised for real recovery or removal without evidence.

| Decision | Required rule |
| --- | --- |
| CURRENT / Ready | Exact target identity and contract/hash closure, plus existing operational availability checks. |
| Historical selection and retained-effects observation | Package-declared predecessor identity and its own cross-bound activation/operation, project, instance, generation and immutable hashes. Identity grants no runtime or mutation capability. |
| Historical removal | Existing independent authenticated preflight and confirmed operation; preserve holder, configuration, handoff and commit-time validation. |
| Original action history | Original failed/unknown outcomes stay unchanged; report current relevant effects separately. |

## Attributable baseline and confirmed cause

HEAD: c6c2f036aa3c5d08a2334118d9049eff9dd3b875.
Branch: codex/v0.3.0-legacy-workflow.
Production evidence is the exact referenced Package:
`.artifacts/s29-startup-auth-boundary-c6c2f03/review/com.rice.ai-codedb`.
Its target is poc.43. Actual selected installation remains poc.42, instance
d620abbab0334a2d9c49e59888c1ef55, epoch 2f8b2a509a1e4086af4a4457e618d037.
Historical runtime hash is 538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d;
target runtime hash is 69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.
These are evidence bindings, not replacement authority literals in production.

Confirmed static chain in that Package:

1. ManagerWindow restore/refresh obtains materializer ReadStatus (DryRun), then
   passes parsed retained observation into ManagerActionJournal.Read.
2. materializer line 12082 emits Get-InstanceRetainedEffectsObservation.
3. instance-engine lines 3394-3399 use current Manifest activation/recovery
   context and ordinary next-change admission. Recovery uses that same runtime
   authority; it does not authenticate the predecessor.
4. Journal lines 921-934 turn any unsafe observation detail into historical
   candidate ambiguity, including a current-runtime contract mismatch.

The removal route already uses Get-RemoveIntegrationActivationState with
Package-bound predecessor runtime authority. Its screenshot exit 4 is a separate
unresolved diagnosis; do not assert the above observation cause proves it.
The existing RetainedDisposition installed fixture only changes desired state to
INSTALLED; it does not establish this selected-predecessor/target combination.

## Scope and ownership

Single Coder owns only necessary changes in:

- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1: retained observation and
  directly necessary read-only authentication/admission helpers.
- com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs: truthful projection
  of the independently classified production observation; only if necessary.
- com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1: focused
  production predecessor/target observation and adjacent refusal fixtures.
- com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs: directly coupled
  production output -> journal/session/UI combination evidence.
- Task-local VERSION-TRANSITION-OBSERVATION-RESULT.md and SOURCE-SHA256.txt.

Read closure: named functions' direct producers/callers/consumers, existing
historical removal context, activation/selection/retention readers, Manager
session/UI classifiers, test workspace contract and exact old/new Package inputs.
Inspect the independent removal-preflight chain only to return an attributable
cause or remaining evidence gap. A separately discovered production fix outside
this allowlist requires reassessment before editing.

Protected: real S29 and other projects, package references, selected/desired/
activation/operation records, receipts/indices, candidates/intents, immutable
installed generations, previous evidence/backups, dirty Payload and
OwnerIdentityV2Status fixture, unrelated dirty/untracked source/docs.
Capture bounded baseline hashes and prove preservation at stable handoff.
No historical-content cleanup or broader orphan classifier redesign.

## Execution and evidence envelope

Continue diagnosis -> scoped implementation -> focused isolated evidence ->
stable Coder snapshot -> separately authorized read-only Verifier -> consolidated
User disposition. Route approval must precede child dispatch; no repeated
command-level permission inside the approved envelope.

- Freeze the direct authority/consumer map in RESULT before authentication edits.
- Use existing Package-bound historical readers; never trust a record's old
  runtime hash alone, rewrite historical bytes to target identity, weaken
  CURRENT/Ready/ordinary Install admission or treat observation as removal permission.
- Prefer existing observation fields/contracts. New serialization fields,
  independent authority services, additional production readers or changed
  mutation behavior require a concrete scope decision before implementation.
- Build an isolated fixture from the exact delivered Package and exact original
  predecessor authority under a new repository-local .artifacts/tests child.
  Do not regenerate/copy dirty working-tree Payload into that fixture.
- L0: changed PowerShell syntax, scoped source diff/hash binding, affected C#
  semantic compilation if changed, existing relevant path-provenance admission.
- L1: production observation -> emitted/parsed observation -> journal/session/UI
  for a real fixture selected-v2 original42 + successor43 + retained effects.
  Include Current same-version control; wrong runtime/generation/project/epoch/
  operation/immutable hash; undeclared predecessor; pending activation;
  live/unknown holder; foreign observation context; and unchanged strict ordinary
  next-change refusal. Reuse existing focused cases where they prove these claims.
- Required positive meaning: authenticated historical ownership is distinguishable
  from operational mismatch, without granting Ready, fresh Install over INSTALLED,
  index release, removal or process control. Genuine relevant conflict remains
  blocked with its actual reason. A safe historical identity alone cannot clear
  unrelated unresolved effects or safety gates.
- Tests must drive existing production code, not replace it with prebuilt SAFE
  output or fake historical authentication. Stub external processes only at a
  declared existing fixture seam; this is synthetic evidence, not live IPC.
- Within that synthetic envelope, exact Roslyn extraction of production
  Parse/Journal/ActionSession/UI-classifier bodies may use a test-owned memory
  adapter for Unity SessionState storage. Record symbol/body integrity and the
  adapter boundary. Do not rewrite production authentication/method bodies,
  reuse NativeBoundaryRewrite, or claim native Unity execution from this seam.
- Explicitly NOT RUN: Unity/EditMode/BatchMode/MCP/CUA, real product reader/Probe/
  Ensure/Install/Remove/Uninstall/Upgrade against S29, process stop, generation
  migration, cleanup, commit/export/reference switch/push/publication/release.
- Budget: Coder DEEP_60M, Verifier DEEP_30M; initial plus two causally corrected
  semantic attempts per scenario, two mechanical corrections, at most two
  independent product causes before reassessment. Bounded output; no full audit,
  full unchanged suites or duplicate unchanged verification runs.

## Completion and review

Coder returns stable diff/files/hashes, base/head, exact fixture inputs, causal
result, executed evidence and explicit limitations. Parent verifies admission
once. Verifier remains read-only, owns only VERSION-TRANSITION-OBSERVATION-
VERIFICATION.md, reviews frozen behavior and nearest regressions, and returns
findings together to User. No direct reviewer work requests to Coder.

Complete only when the classified production chain and negative guards have
attributable focused evidence or an exact remaining gap is returned. Do not
claim S29 recovery, sustained Ready or release completion from source tests.

## Terminal stage disposition

Both authorized children stopped. Four scoped hashes match the stable Coder
snapshot and exclusive overlay; HEAD remains c6c2f036aa3c5d08a2334118d9049eff9dd3b875
and staged index is empty. Captured 2845 protected entries match before/after.
Independent review: SCOPED_SOURCE_REVIEW_PASS_WITH_LIMITS, no source BLOCKER.
Existing final PowerShell fixture records 24 synthetic Check assertions PASS;
path-provenance PASS and original-byte C# compilation are bounded evidence.

One FOLLOW-UP is returned to User: the complete blocked Journal -> Session -> UI
consumer chain has no attributable execution PASS. Later partial assertions and
Unity internal-call failure are Coder declarations without a preserved final raw
runtime log. The retained-current-index message branch has static review only.
Do not repeat unchanged checks or broaden standalone native adaptations.

Source acceptance and follow-up disposition remain User-owned. No commit,
export, reference switching, Unity gate or real recovery/removal is authorized
by completing this source/review envelope. Screenshot removal preflight exit 4
remains a separate unresolved cause; source accept does not close it or S29.

## Human source acceptance — 2026-10-14

User replied `同意 accept` after the consolidated scoped review and disclosed
limits. All four frozen hashes matched at acceptance; HEAD and empty staged
index were unchanged. See VERSION-TRANSITION-OBSERVATION-ACCEPTANCE.md for the
authoritative snapshot and retained follow-up. This closes the source/review
disposition only; no delivery or real-environment operation grant is inferred.

## Delivery preparation — 2026-10-14

User requested continuation after source acceptance. The parent prepared
VERSION-TRANSITION-OBSERVATION-DELIVERY-PROPOSAL.md: exact four-file local commit,
commit-bound export/closure gates, backed-up S29 reference switch, and human
fixture-aware acceptance instructions. Accepted hashes, current references and
closed-project process preflight matched. No delivery mutations were performed;
the concrete grouped delivery grant remains pending.

## Delivery completion — 2026-10-14

User granted the grouped delivery actions. Commit, exact package export and S29
manifest/lock reference switch completed as recorded in
VERSION-TRANSITION-OBSERVATION-DELIVERY-RESULT.md. Human Unity steps are in
VERSION-TRANSITION-OBSERVATION-HUMAN-CHECKLIST.md. No real Install/Remove or
history cleanup was included.

## Human disposition — shutdown observation deferred

The human accepted the focused version-transition test result and normal
Manager interactions, then explicitly decided that the Unity
`Application.Shutdown.CleanupMono` blocking sample is deferred and out of scope
for this task. Preserve it as observation evidence only; do not attribute it to
the version-transition source change or open a shutdown repair from this task.

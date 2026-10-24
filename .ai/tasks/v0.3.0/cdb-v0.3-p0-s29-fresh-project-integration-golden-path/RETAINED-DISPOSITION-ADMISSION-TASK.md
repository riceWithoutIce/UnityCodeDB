# Task: S29 retained-disposition admission refactor proposal

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0 / existing S29
- Workflow: codedb-workflow-v2, revision 2.4
- Status: HUMAN_TESTS_UI_PASS / NO_TEST_CLOSE_PASS / SHUTDOWN_HANG_DEFERRED_OBSERVATION
- Planner: current parent
- Coder: /root/retained_disposition_coder; task-specific source stage
- Verifier: /root/retained_disposition_verifier; independent read-only stage
- Review mode: GUARDED
- Execution mode: DURABLE_SESSION; current parent prepares the contract,
  no durable session creation/rebinding is authorized
- Execution profile: v0.3.coder.deep / v0.3.verifier.deep (proposal only)
- Delegation authorization: TASK_SPECIFIC; user approved the proposed REFACTOR
  and sequential Coder -> stable snapshot -> read-only Verifier on 2026-10-12.
  Approval applies to this source/synthetic envelope, not live or delivery gates.
- Session policy: REUSE_ONLY; stopped Coder then Verifier may be reactivated
  for the approved F1/F2 FIX and targeted repair review
- Requirement source: current user direction, CodeDB Responsibility Contract,
  reinstall contract and RETAINED-DISPOSITION-ROUTE-REASSESSMENT.md

## Objective

One independently acceptable outcome: Manager distinguishes original execution
history from independently validated retained candidate effects and derives
current recovery presentation consistently with backend authority. An inert
authenticated predecessor is historical information rather than an automatic
blocking recovering action. Unresolved relevant effects remain explained and
blocked; multiple failed actions do not force selection of one representative.

## Scope

- In scope: existing backend read-only retained-effects classification,
  Manager history aggregation/session restoration, Install recovery presentation,
  and directly coupled producer/reader/session/UI regression evidence.
- Out of scope: reconstructing 73c9…=d8c…, history/runtime cleanup, payload
  regeneration, actual generation materialization, broad Host/Supervisor redesign,
  real Install/Uninstall/Configure/Remove, Unity automation or release acceptance.
- Proposed implementation/test allowlist:
  - com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1
  - com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1
  - com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs
  - com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs
  - com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
  - com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
  - com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
  - com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
- Planner records: this task and route packet. Coder result/hash manifest:
  RETAINED-DISPOSITION-ADMISSION-RESULT.md / SOURCE-SHA256.txt; Verifier record:
  RETAINED-DISPOSITION-ADMISSION-VERIFICATION.md. No other documentation edits.
- Read-only dependency closure: DIRECT_REFERENCES_ONLY of allowlisted symbols
  and existing contracts/templates/harnesses; real-state reads limited to the
  previously recorded S29 candidate/intents/selection evidence, not fixtures.
- Protected state: real S29 and other Unity projects; all current receipts,
  intents/candidates/runtime, references, ignored outputs/backups and unrelated
  dirty/untracked state. Real project data is never a mutating test target.
- Snapshot binding: source b76957a9dbcae9b00eff73775a97c4e8f33ae785;
  attributable frozen Coder hashes required before independent review.
- Identity authority route: existing package runtime contract and backend
  removal/activation readers; separate project/user-local path guards and
  instance/action/package key contracts remain intact.
- Generation transition: NONE in this source/evidence proposal.
- Identity closure: no new version literals, receipt/persistence schemas,
  original outcome rewrites or manufactured action/instance associations.

## Frozen Responsibility And Behavior

1. Journal authenticates action history and actual active/pending ownership.
   Original failed/unknown results stay unchanged and separately displayed.
2. Backend remains the owner of present retained effects classification. Reuse
   its existing intent identity/fingerprint, manifest/generation/effects,
   holder and wrapper/activation validation. Manager must not establish a
   second weaker resource admission rule based on origin ID or file existence.
3. Provide classification through an existing asynchronous read-only observation
   route, without invoking mutation/probe/cleanup as a query. No new service or
   persistent permit. The precise transient output/parser mapping must be
   recorded before implementation; unavailable evidence remains unavailable.
4. Aggregate all relevant histories/effects; current eligible presentation may
   not depend on failedInstallCount == 1 or the newest failure. Preserve explicit
   reasons for active/pending actions and any unsafe/unknown effect.
5. Safe retained history does not become IsRunning/IsRecovering merely because
   its original outcome is unknown. Actual active ownership and evidence conflict
   still prevent new dispatch; reopening/reload rederives the same classification.
6. Install recovery eligibility uses the current product/package context plus
   the validated complete effects classification, not one old action result.
   Ready, Install, removal and migration retain distinct meanings. A historical
   safe disposition cannot grant Ready or bypass generation mismatch.
7. A user-confirmed action still follows the original single execution route and
   backend resource revalidation. Do not retain UI classification as a reusable
   write permission. Unavailable/changed backend evidence refuses safely.

## Execution Envelope (Pending User Route Decision)

- Mode: CONTINUOUS_WITHIN_SCOPE after explicit activation.
- First source-stage requirement: consolidate exact existing producer entry,
  output/parser, journal/session/UI consumers and resource-owner checks into
  one bounded implementation map in RESULT. If the existing observation route
  cannot meet the read-only contract within the allowlist, return the specific
  design gap before adding APIs/services or widening scope.
- L0: parse changed PowerShell, semantic C# compile and touched diff checks.
- Affected L1: synthetic production backend classification -> actual parser ->
  journal/session -> action label/callback; no boolean-only UI fixture PASS.
- Evidence scenarios:
  - absent old Manager action with valid inert retention and distinct current
    instance: historical warning, no false recovering block;
  - two or more historical failures, all relevant effects safely retained:
    derived eligible recovery, no latest-result selection;
  - mixed safe retention and unresolved candidate or running/pending action:
    blocked with the specific relevant reason;
  - no intent; wrong project/instance; effect/hash/fingerprint drift; duplicate
    authority; selected/activating candidate; live/ambiguous holder or unbound
    shared wrapper: fail closed;
  - current package/generation mismatch remains setup/recovery context,
    not authenticated Ready or presumed safe full backend operation;
  - reopen/domain reload, stale SessionState and classification refresh:
    stable derivation and no resurrection/clearing of a foreign active owner;
  - changed evidence at confirmed backend dispatch: existing refusal retained.
- Test rationale: these cover the repeated user entry failure and its actual
  authority boundaries, rather than implementation-shaped helper tests.
- Synthetic fixtures/harness outputs: fresh repository-local .artifacts/tests
  child dedicated to this slice; never overwrite a frozen prior output.
- Path provenance/package identity pre-freeze gate: bounded existing validators
  for directly touched path consumers. Record current dirty payload limitation;
  use commit-derived canonical payload inputs for synthetic evidence. No export.
- Package release closure gate / canonical generator: later standard committed
  exporter and payload closure validators, NOT AUTHORIZED or RUN by this task.
- Commit-derived artifact / extracted-package paths: NOT_CREATED; future delivery
  must bind the accepted source and all coupled identity/hash nodes.
- Cross-hash assertions: fixture intent/effect/instance/generation identities
  and source snapshot; existing real protected identities stay untouched.
- Unity/external ordering: stable source -> independent review -> user disposition
  -> separately aligned delivery -> focused human exact-package gate.
- Explicitly not run: Unity/NUnit, real backend CLI/preflight, real history
  reconciliation, Install/removal/reinstall, generation switching, export,
  process control, GitHub Project update, commit/push/publication.
- Mechanical corrections per scenario: 2; corrected semantic attempts: 2.
- Active time budget: DEEP_60M Coder / DEEP_30M Verifier.
- Output budget: V2_DEFAULT; broad search/full diff/full regression FORBIDDEN.
- EditMode authorization: NOT_REQUESTED.
- Side-effect authorization: NONE outside allowlisted source/tests and isolated
  synthetic repository-local evidence; no real persistent product-state writes.
- Stop conditions: scope/authority expansion, inability to reuse the owner
  classification, unavailable mandatory evidence or workflow budget trigger.
- Structural guard: prior same-path repair history persists; this is the
  explicitly proposed structural correction, not a reset of patch counters.
- Model escalation: NONE.

## Definition Of Done

- Stable attributable source/test snapshot and single causal/result map.
- Required semantic/synthetic production-path cases pass; missing evidence is
  labeled rather than replaced with a fake original command success.
- Independent review covers only this refactor and immediate regressions.
- UI distinguishes harmless historical retention from a relevant unresolved
  block; confirms revalidation still belongs to the backend.
- Deferred: current real generation/package alignment; full holder/activation
  proof in the actual project; continuous Unity golden path; release; post-stability
  cleanup/archive. Source acceptance does not close any of those gates.

### In-envelope operation eligibility clarification — 2026-10-12

Coder confirmed the existing Install backend entry requires a genuine first
Install or authenticated UNINSTALLED state. The actual S29 desired state is
INSTALLED; SAFE retained effects alone cannot admit Install under a different
Package generation. Parent directed preservation of that existing semantic.
This slice must report the distinct operation-eligibility limitation, not expose
an executable Install solely because retained classification is SAFE. Synthetic
first-install/UNINSTALLED eligibility stays in the accepted evidence envelope.
No new Upgrade execution entry, desired-state change or generation handoff is
authorized by this clarification; installed-generation handoff stays deferred.

## Handoff

- Current task: S29 retained-disposition/admission.
- Current status: user explicitly accepted the FIX source with "同意 accept"
  on 2026-10-12. F1/F2 closed; targeted Verifier PASS_WITH_LIMITS. All eight
  FIX snapshot hashes rechecked and match. Seven total refactor files changed;
  ProcessRunner unchanged. Both Coder and Verifier are terminal/stopped.
- Accepted identity: RETAINED-DISPOSITION-ADMISSION-FIX-SOURCE-SHA256.txt,
  based on b76957a9dbcae9b00eff73775a97c4e8f33ae785. Original evidence preserved.
- User disposition: on 2026-10-12, user deferred the shutdown hang for observation
  during subsequent tests because the sample is too small to attribute it to
  this development. Preserve the failed AppHang and successful comparison.
- Next action: continue aligning the remaining S29 route; no dedicated shutdown
  investigation, source fix or extra Unity attempt at this stage. The hang is an
  unresolved deferred observation item, not a current slice blocker or a proven
  CodeDB defect. See SHUTDOWN-NO-TEST-CONTROL-2026-10-12.md and human result.
- Delivery grant: user's explicit commit -> exact export -> reference switch ->
  human Unity request; recorded in RETAINED-DISPOSITION-DELIVERY-GRANT.md.
  Local source commit, both package closure gates and reference switch complete.
  Human controls Unity; parent only performs subsequent bounded read-only checks.
  Actual installed-generation mismatch stays deferred; S29/release PARTIAL.

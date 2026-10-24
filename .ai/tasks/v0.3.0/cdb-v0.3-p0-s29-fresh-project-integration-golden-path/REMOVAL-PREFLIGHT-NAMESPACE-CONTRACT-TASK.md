# S29 removal-preflight namespace contract alignment

Date: 2026-10-14, Asia/Shanghai.

## Metadata and authority

- Product/version: UnityCodeDB v0.3.0, existing S29.
- Workflow: codedb-workflow-v2 revision 2.6.
- Status: SOURCE_ACCEPTED / DELIVERY_COMPLETE / HUMAN_REPORTED_PASS / S29_PARTIAL.
- Planner: parent; proposed Coder/Verifier: completed historical_handoff roles.
- Review: GUARDED, one stable outcome and nearest safety regressions.
- Execution mode: DURABLE_SESSION. Proposed task-specific route exception:
  reuse the existing task-scoped Coder then independent read-only Verifier,
  without creating a chat, profile rebinding, recursive delegation or model change.
- Delegation: TASK_SPECIFIC; user replied `同意` to the concrete REFACTOR and
  Coder -> read-only Verifier approval question for this task.
- Session policy: REUSE_ONLY; parent receives questions and waits for terminal
  Coder completion, admits hashes, then dispatches Verifier and waits for completion.
- Requirement: user approved the prepared six-file REFACTOR source envelope,
  isolated evidence and task-specific route exception. Continue all declared
  stages without another start approval. The original implementation grant had
  no real-operation/delivery authority; later delivery grant is recorded below.
- Delivery: subsequently authorized by `授权开始`; see DELIVERY-GRANT and
  DELIVERY-RESULT. Real-operation and automated Unity authorization: NONE.

## Single outcome

Align removal preflight with the actual Supervisor-owned namespace lifecycle:
authenticate historical effects and operation termination independently of
operational readiness, allow only proven-safe retired-v2 removal preflight,
preserve historical evidence, and show precise refusal reasons in Manager.
This is one vertical outcome, not separate tasks per filename or screenshot.

## Baseline and read closure

HEAD d88a101f15d21f916cbee9578ab887aa1ea862cd, branch
codex/v0.3.0-legacy-workflow; current scoped source and staged index are clean.
Canonical input is the exact delivered Package
.artifacts/s29-version-transition-wrapper-handoff-d88a10/review/com.rice.ai-codedb.
Predecessor is .artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb.
Actual installed selection remains poc.42, target Package poc.43. Package-bound
predecessor identity, immutable generation/instance hashes, selected epoch and
paired committed activation/operation remain canonical identity authority.

Read closure: the six allowlisted files below; exact Tools~/codedb-project-
supervisor.mjs and its Tests~/test-codedb-project-supervisor.mjs operation,
takeover, termination and ownership functions; directly invoked strict JSON,
instance/activation, provenance, config-plan, handoff, transaction and holder
helpers; existing task diagnosis/result/hash and fixture/compile helpers.
Read selected real-state bytes only to capture protected baseline or bounded
sanitized fixture input; never execute a product reader against the real project.
Use exact Package payload; preserve dirty working-tree Payload, all previous
artifacts and unrelated documentation/source/project state.

## Proposed change allowlist

Paths below relative to com.rice.ai-codedb:

1. Tools~/materialize-codedb-host-payload.ps1: bounded namespace classification,
   retired-v2 authority, handoff/fingerprint, transactional targets and terminal
   invariants directly coupled to that authority.
2. Tools~/codedb-instance-engine.ps1: only historical removal's immediately
   coupled intent/wrapper admission/revalidation path where required by this
   committed-predecessor scenario. No ordinary Ready/Install loosening.
3. Editor/AICodedbEditorLifecycle.cs: precise bounded removal-preflight failure
   projection/cache; no general lifecycle, startup, lease or shutdown rewrite.
4. Tests~/test-codedb-host-payload-materializer.ps1: isolated production-function
   namespace/preflight/handoff and copied-project removal/revalidation scenarios.
5. Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs: precise
   refusal/handoff consumer evidence using production emitted fixture output.
6. Tests/Editor/AICodedbEditorLifecycleTests.cs: directly coupled failure projection
   and cache/availability assertions, in the existing isolated scope fixture.

Task-local contract/result/hash/review records and unique ignored evidence
artifacts are permitted outputs. Producer mjs, Payload generations, schemas,
global process runner, Manager layout and additional helpers are read-only.
Need for another writable file or producer/schema migration stops that dependent
path for Planner/User decision; no silent allowlist expansion.

## Frozen contract requirements

Before code, Coder records the responsibility mapping and accepted/rejected
states in a task-local contract. Producer source defines emitted operation,
history and quarantine formats; use exact field/phase semantics and existing
identity/process proof rather than filename-only terminal inference.

- Known operation-history and stale quarantine have bounded count/bytes/depth,
  safe paths and strict JSON/ownership bindings. Unknown entries, redirects,
  malformed/foreign records, incomplete ambiguous pairs and inconsistent
  terminal evidence fail closed. No recursive ignore or arbitrary extension
  whitelist. Old irrelevant records cease to block only once their relevance,
  identity and present effects are proved by the frozen contract.
- Completed/failed operation is distinct from active/pending operation. A
  completed_at field or failed phase alone never proves admitted children/effects
  stopped. Authenticate the operation evidence and exact associated process
  identities; live, unknown, reused/ambiguous ownership remains blocked under the
  existing conservative process rules. Do not trust event text as sole authority.
- Normal Supervisor retirement removes current state/lock. A complete committed
  v2 selected identity may establish installation authority independently of
  those operational records, but holder/child/configuration safety remains
  separate. One present canonical state/lock without its pair is not normal
  retirement. Missing or invalid committed identity is not relabeled v1.
- Separate proof inventory from deletion targets. Existing Inventory is consumed
  by Invoke-RemoveIntegration as Delete entries: do not append history/quarantine
  into it merely to admit their presence. Historical outputs and original failed
  outcomes are preserved. Any retained evidence must be included in relevant
  fingerprints and terminal-state expectations so a retained namespace does not
  become unknown or usable current authority after removal.
- Preflight is read-only and authorizes no Remove by itself. Confirmed removal
  retains entry handoff, configuration snapshot, lock-time and before-mutation
  authority/fingerprint checks, before-commit and recovery/terminal invariants.
  Test the declared source removal behavior only on an exclusive isolated copy.
- Shared historical identity/effects validation may serve observation and
  historical removal when explicitly scoped; no second readiness authority,
  broad failure fallback or independently invented Package/runtime hash literal.
  Ordinary CURRENT/Ready/Install/ACTIVATING safety remains strict.
- Manager failure diagnostic preserves the concrete bounded backend refusal
  alongside the command summary; timeout, incomplete output, malformed/duplicate
  handoff and cancellation never produce an Available permit. Keep displayed
  details bounded and omit auth tokens/handoff secrets from user copy/logs.

## Execution envelope after approval

Stages: contract mapping -> scoped implementation -> isolated evidence -> stable
Coder result/hash -> independent read-only Verifier -> consolidated user findings.
User approves the entire declared source envelope once; no per-command start
confirmation within it. Source acceptance and delivery are later independent gates.

L0: PowerShell syntax, scoped diff-check, exact overlay path provenance; original
byte C# semantic compile for changed Editor/tests using existing isolated tooling.
No tests that only repeat implementation conditions. Retain attempts and raw logs.

L1 must cover:

1. Realistic retired selected42/target43: producer-shaped operation history,
   terminal failed canonical operation matching history, stale pairs, absent
   current owner/state, committed activation and clear synthetic holders.
   Production preflight/authority/handoff PASS and read byte digest unchanged.
2. Terminal success/failure, active/pending or incomplete operation, live/unknown
   child/owner, conflicting canonical/history identity or terminal result,
   malformed/foreign history or stale pairs, reparse/unknown/over-budget entries.
   Concrete BLOCKED reasons and no handoff/Install/Ready permit.
3. Normal current/v1 controls and existing wrapper ORIGINAL/before-install
   historical observation remain valid; ordinary target-strict refusal stays.
4. Copied-project confirmed-removal transaction: exact preflight handoff, safe
   configuration preservation, scope of actual removal targets, protected history
   retained; changes in evidence/config/selection between preflight, lock and
   mutation reject; terminal/recovery assertions hold. No real removal claim.
5. Production emitted preflight failure -> C# failure detail/cache/availability
   -> existing UI diagnostic consumption. Synthetic/source coverage is explicitly
   separate from human Unity. Preserve raw evidence of each executed chain.

Synthetic process/prerequisite/native seams must be enumerated. Zero real native
children, external IPC or supervised processes. If meaningful child proof cannot
be represented using existing seams, stop with a concrete evidence/contract gap;
do not start real processes to fill it without authorization.

Generation transition NONE; no Payload regeneration or package version bump.
Path/identity provenance must remain from the exact accepted Package. Review
hashes and protected snapshots include actual S29 manifest/lock/desired/current/
activation, histories/receipts and dirty Payload; preserve original evidence.

Budget: DEEP_60M per role, V2_DEFAULT bounded output, DIRECT_REFERENCES_ONLY,
two mechanical corrections and up to two corrected semantic attempts per local
scenario, at most two independent product causes before route reassessment.
No broad full regression or full repo diff. New competing authority, schema
migration, unresolved evidence ambiguity or out-of-scope cause returns to Planner.
Earlier S29 route counters are preserved by reference; this task does not reset
the blocked user path's historical counts. The new REFACTOR disposition, if
approved, resolves the already-recorded structural trigger for this envelope.

Explicitly not run: Unity/MCP/CUA/BatchMode, live reader/Probe/Ensure/IPC, actual
Remove/Install/Upgrade or migration, external process stop/start, manual history
or candidate cleanup, user/environment settings, commit/export/reference switch,
push/publication. CleanupMono remains deferred; prior MissingPrerequisite cause
remains unattributed. Tests run only under unique repository-local ignored roots.

## Definition of done and handoff

Done: one consistent bounded Supervisor namespace/retired-v2 removal contract;
declared positive and safety-negative scenarios complete; original histories and
real protected state unchanged; stable attributable hash/log/result; Verifier
returns consolidated findings. No claim of real removal, target readiness or
overall S29 completion from isolated evidence.

Next action: Coder and independent read-only Verifier have completed the frozen
envelope and the user-authorized narrow Manifest-forwarding repair. The original
production recovery blocker is closed (see REMOVAL-PREFLIGHT-MANIFEST-RECOVERY-
VERIFICATION.md); six final source hashes remain attributable through the initial
four unchanged hashes and the follow-up two hashes. User accepted the combined
PASS_WITH_LIMITS source snapshot on 2026-10-14 (`同意 accept`); see
REMOVAL-PREFLIGHT-NAMESPACE-CONTRACT-ACCEPTANCE.md. The subsequently authorized
delivery and accepted test-root correction are complete; see DELIVERY-RESULT.
Human result: REMOVAL-PREFLIGHT-NAMESPACE-HUMAN-RESULT.md. Real preflight remains
blocked by historical child-process proof. No real Install/Remove/Upgrade,
process control, new repair or automated Unity authority is inferred.

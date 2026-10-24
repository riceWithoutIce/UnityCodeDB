# Task: S29 v2 removal process identity classification

## Metadata

- Product/version: UnityCodeDB v0.3.0 / existing S29.
- Workflow: codedb-workflow-v2 revision 2.6; status: COMPLETE (source envelope);
  SOURCE_ACCEPTED / DELIVERY_COMPLETE / HUMAN_REPORTED_PASS / S29_PARTIAL.
- Planner: parent; Coder: reused historical_handoff_coder;
  Verifier: reused independent historical_handoff_verifier.
- Review: GUARDED; execution mode: DURABLE_SESSION, task-specific approved
  transport exception reusing the existing task-scoped Coder -> Verifier roles.
  No new chat, profile/session rebinding, model change or recursive delegation.
- Delegation: TASK_SPECIFIC; session policy: REUSE_ONLY.
- Requirement: REMOVAL-PREFLIGHT-PROCESS-IDENTITY-PLAN.md, including its later
  authorization addendum. User replied `好的 批准` to the concrete three-file
  source/isolated-evidence and Coder -> read-only Verifier proposal.

## Objective and scope

One outcome: classify the recorded Supervisor process correctly in v2 removal
and expose precise refusals, without granting permission from process identity
alone. Known PID reuse must not be treated as the original process still alive.
Missing child and unknown identity remain explicit refusals. This phase does
not promise to unblock real removal or reconstruct incomplete historical runs.

Base HEAD: 39d79aeee1bd5525c6ed2eb1369f6c27334b9d07, branch
codex/v0.3.0-legacy-workflow. These three paths are clean at dispatch; base hashes
(SHA256, relative to com.rice.ai-codedb):

| Writable path | Base SHA256 |
| --- | --- |
| Tools~/materialize-codedb-host-payload.ps1 | 1bc989195aa14def596e16231cc2876afcedfbab4a5f342ca1384f9567de695a |
| Tests~/test-codedb-host-payload-materializer.ps1 | e014f3399bb83b97b69c7f4454d000fa6b2dd69db860e9644ce2cd2e066d2ba8 |
| Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs | 52d8945d5398eaca37120e17cae128cf5b956036f09a847a9876ed75b094587a |

Coder may edit only these paths, its PROCESS-IDENTITY-RESULT.md and
PROCESS-IDENTITY-SOURCE-SHA256.txt records (full prefix below), and unique ignored
evidence/helper files under .artifacts/tests/s29-removal-process-identity/.
Planner owns this task and plan; Verifier owns only its verification record.

Read-only closure: the plan; development-workflow.md and test-workspace-contract.md;
exact accepted .artifacts/s29-removal-namespace-39d79ae/review/com.rice.ai-codedb;
its predecessor package identified in the prior namespace task/result; Supervisor
process evidence producer/matcher and operation lifecycle in
Tools~/codedb-project-supervisor.mjs; directly invoked materializer/instance
identity, holder, namespace, handoff and transaction helpers; existing lifecycle
refusal projection and its directly coupled tests; existing namespace/path-fix
result/hash/fixture and exact C# compiler/seam helpers. DIRECT_REFERENCES_ONLY.
No broad audit, runtime history/process census or unrelated full regression.

Protected: all real S29 project/runtime/configuration/receipts/history, user dirty
Payload/docs/old validation project, previous artifacts, global settings,
HEAD/index and all source outside the allowlist. Canonical base is the exact
accepted package; do not regenerate or consume dirty worktree Payload. Capture
and compare relevant protected file digests read-only using existing baseline
helpers; no real product reader/preflight or external process inspection.

## Frozen identity contract

Applicable consumers: VERSIONED_V2 removal history child, paired stale owner,
and current owner, plus their existing revalidation paths. legacy/v1 behavior
does not change. Generic inspector and generation-lease semantics stay unchanged.

- Process definitively absent/exited: original process absent; continue other gates.
- PID visible with matching production-compatible start identity: original live;
  BLOCKED with role and bounded attributable record identity.
- PID visible with definitely different valid start identity: reused; do not
  claim, attach to or stop the current process; continue other relevant gates.
- Query failure, missing/unreadable current start identity or unsupported identity
  comparison: unknown; BLOCKED with a distinct reason.
- Missing child or invalid recorded evidence: distinct BLOCKED reason, never absent.

Windows Supervisor producer uses UTC ticks truncated by ticks%10. Match that
precision exactly, validate comparability, and do not reuse Unix milliseconds
with a +/-2s lease tolerance or infer identity from process name/path. No new
cross-platform compatibility fallback, serialized schema or ownership authority.

Existing strict schema/project/runtime/selection/activation/immutable closure,
path/reparse limits, canonical-history equality, fingerprints, terminal/active
rules, configuration preservation, selected/LKG holder safety and all original
lock/before-mutation/before-commit/terminal invariants remain. Holder clear does
not replace missing-child proof. Retained history bytes and failed outcomes stay
unchanged; no new delete target or ordinary Ready/Install eligibility relaxation.
Process classification is derived, not itself a removal/termination permit.

Diagnostics distinguish live original, unknown identity and missing child;
identify bounded operation_id or owner role. Reuse existing bounded redacted
Manager projection. Do not display full argv, tokens or handoff secrets. No
automatic process start/stop, attach, retries, machine census or history repair.

## Execution envelope

CONTINUOUS_WITHIN_SCOPE: scoped implementation -> isolated evidence/local same-
scope corrections -> stable Coder result/hashes -> parent snapshot admission ->
one independent read-only Verifier review -> consolidated user disposition.
No repeated start approvals inside these stages. Delivery authorization: NONE.
User source accept and any commit/export/reference switch remain later gates.
Human owns Unity. EditMode authorization: NOT_REQUESTED.

L0: syntax for changed PowerShell; scoped diff-check; mandatory
Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly PASS before freeze;
original-byte directly affected Editor/Editor.Tests semantic compilation using
existing exact-package tooling. Paths come from caller-owned repository-local
test roots; read test-workspace-contract.md before changing test writers.

Affected L1, one initial scenario family with causally justified corrections:

1. Existing isolated RemovalNamespaceOnly production-call-chain fixture under a
   unique exact-package overlay, with only allowlisted source/test replacements.
   PID absent, original live, reused valid identity (including same executable),
   inspection failure/start unavailable, matching producer precision and invalid
   stored identity; check all three v2 consumers and strict v1 exclusion.
2. Reuse does not bypass active/invalid/foreign history, missing child, unknown
   ownership or live/ambiguous related holders. Existing positive history proof,
   preservation/fingerprint and copied transaction safety remain valid.
3. Relevant observations change between preflight and existing locked/effect
   revalidation: no stale permit bypass. Exercise original terminal/recovery
   entry consumers as directly affected; no added general replay facility.
4. Saved production refusal output -> original C# fixture consumer/cache/UI seam
   as directly coupled; exact source-member binding, redaction and unavailable
   permit assertions. Preserve original assertions and cache restoration.

All product process observations are synthetic seams; zero real supervised
native children/IPC. Local shell/compiler test hosts are permitted. No live
preflight/Install/Remove/Upgrade/Probe, Unity/MCP/CUA/BatchMode, native workspace
execution, process control, cleanup, environment changes or delivery. Preserve
per-attempt evidence and distinguish source/isolated PASS from human/real gates.
Check overlay equality against the exact accepted package (only three scoped
changes) and protected-state equality before freeze. Do not waive missing
mandatory source gates under PASS_WITH_LIMITS.

Budgets: Coder DEEP_60M, Verifier deep 30m; V2_DEFAULT bounded output;
DIRECT_REFERENCES_ONLY; initial plus two mechanical corrections and up to two
causally corrected semantic attempts per local scenario. This new phase starts
with zero source repair/review rounds and one identified process-classification
cause; missing-child closure is explicitly deferred, not a new repair target.
Earlier S29 route counts remain in prior reassessment records and are not reset.
Two independent in-scope product causes, unresolved contract ambiguity, expanded
file/evidence/side-effect scope, unavailable mandatory evidence or structural
trigger -> stop the dependent path and return exact gap to Planner/User.
No child may self-expand, create sessions or delegate. No model escalation.

## Definition of done / handoff

Stable three-file outcome, mandatory source gates and declared isolated consumer
evidence complete, hashes attributable, real/dirty protected state unchanged,
Verifier findings consolidated to User. No claim of unlocked real removal,
target Ready, human Unity PASS for these new bytes or release completion.
Missing-child history and CleanupMono remain explicit deferred boundaries.

Record names in this task folder:
REMOVAL-PREFLIGHT-PROCESS-IDENTITY-RESULT.md,
REMOVAL-PREFLIGHT-PROCESS-IDENTITY-SOURCE-SHA256.txt,
REMOVAL-PREFLIGHT-PROCESS-IDENTITY-VERIFICATION.md.
Completed: reused Coder reached terminal stable completion; parent admitted its
three source hashes before dispatching the independent read-only Verifier.
Verifier has also reached terminal completion: SOURCE_AND_ISOLATED_PASS,
0 BLOCKER / 0 FOLLOW-UP within the frozen scope. Parent rechecked the stable
source hashes, unchanged HEAD/empty index and verification-report hash
d8fb9ae6c5f2ef6bfdeb26685110bb291dc9c1af5d64b99f1abbf88d0420125e.
Mandatory source gates, isolated PASS141, exact C# consumer/cache/UI seam and
4174 protected-state entries are documented in RESULT and VERIFICATION.
User disposition: `同意 accept`. Parent rechecked the frozen source and review
hashes and recorded REMOVAL-PREFLIGHT-PROCESS-IDENTITY-ACCEPTANCE.md.
No further source work or test rerun is pending inside this envelope.
Subsequent separate delivery grant: `授权`. Parent committed exactly the three
accepted files as 544be4f7e339acefb47137b188cdc85e22483efb, exported and verified
the exact artifact, then switched only S29's two Package references with Unity
closed. See DELIVERY-GRANT/PLAN/RESULT and HUMAN-CHECKLIST with this prefix.
Human Unity acceptance and post-human read-only checks are complete; see
REMOVAL-PREFLIGHT-PROCESS-IDENTITY-HUMAN-RESULT.md. Subsequent read-only diagnosis
is in REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-DIAGNOSIS-2026-10-15.md. No new source
work, real Install/Remove/Upgrade, process
control or automated Unity is authorized. S29/release remain PARTIAL.

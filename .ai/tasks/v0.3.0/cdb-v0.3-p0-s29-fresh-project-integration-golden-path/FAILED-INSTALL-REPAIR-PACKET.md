# S29 Failed Install Recovery - Authorized Source Envelope

Date: 2026-10-07. Status: SOURCE_IMPLEMENTED / SCOPED_SOURCE_REVIEW_PASS.
Base HEAD: 13bf5fd16c15c42e1379ce35a06e49c20753195f.
Branch: codex/v0.3.0-legacy-workflow.
Mode: FAST_SUBAGENT, depth one, sequential Coder then read-only Verifier.
Authority: human `同意开始` accepted FAILED-INSTALL-REASSESSMENT.md and
the announced child pipeline; STANDING_WORKFLOW remains active. Necessary
source/isolated prerequisites proceed without repeated permission. Real-project
mutation, Unity, commit/export/release are outside this source envelope.

## Objective and frozen decisions

Complete one coherent failed-first-Install recovery path: admitted invocation
identity -> original failed result -> confirmed integration removal -> explicit
fresh Install. No new recovery service, button, executor or machine-wide scan.
The retained PROVISIONING candidate is not a verified predecessor.

1. Bind direct materializer action/operation IDs before receipt argument hashing.
   Reuse the actual Manager action context and one operation identity for an
   invocation; preserve it across allowed Supervisor/direct fallback. Standalone
   calls may mint their own identity once. Never relabel the historical backend
   GUID as the historical Manager action ID. No protocol field change is needed.
2. Use the existing authoritative-success/no-retained-admission policy at the
   action entry points. Failed, missing, unknown, or pending Install results must
   not request Upgrade/replay; cache-only observation may report the original
   failure. Keep successful behavior and explicit user retry intact.
3. Extend existing Uninstall/RemoveIntegration preflight and execution with one
   FAILED_PREPARATION classifier. It applies only to one exactly bound
   PROVISIONING instance, verified_at_utc empty, valid original INSTALL origin,
   authenticated project/manifest/old-generation closure, no current/LKG/active
   activation or conflicting Supervisor authority. Validate registration and
   holder/effect state independently of runtime readiness. A missing selection
   alone never proves removal authority. Reject unknown or conflicting records.
4. Reuse the existing project lock, transaction publication/recovery and removal
   intent location. Publish intent before effects. Authenticate UNINSTALLED only
   after selected/active/registration authority is absent or deactivated.
   Keep failed candidate and authenticated host/bootstrap closure inert and
   PENDING; physical deletion of that closure is not required in this repair.
   This deliberately avoids recursive retirement deletion as an ownership rule.
   Unknown content or live/ambiguous executors must never be removed. Valid
   lease-bound inert content may remain PENDING under the established contract.
5. Explicit fresh Install can preserve that exact removal closure and create a
   different verified candidate. It must not require invented COMMITTED evidence
   for the never-activated candidate, adopt it as LKG, sweep retained bytes or
   report cleanup COMPLETE. Host/bootstrap residue is validated and bound as part
   of this same intent, not ignored merely because instance selection is absent.

## Serialized contract and actual consumer map

Authority: project-integration-reinstall-contract.md plus this frozen amendment.
Keep instance.json/origin, desired-state.json, command-result and activation
record schemas unchanged. Preserve installed-removal intent schema v1.

Failed-preparation removal uses schema v2 at the existing location
`AIWork/.runtime/codedb/control/removal-intents/<state_id>.json`:

- Common retained fields: schema_version (2), managed_by, project_root,
  project_identity, state_id, operation_id, authority_fingerprint,
  retained_instance_id, retained_instance_manifest_sha256,
  retained_generation_id, retained_generation_manifest_sha256,
  retained_wrapper_sha256. Existing string/identity/hash rules apply.
- authority_kind is exactly FAILED_PREPARATION. state_id and operation_id are
  the new removal operation identity, not fabricated original Manager identity.
- retained_effects is a bounded, deterministic array of exact project-relative
  entries: relative_path (string), kind (FILE or DIRECTORY), sha256 (64 lowercase
  hex for FILE, empty string for DIRECTORY). Include candidate manifest, known
  editor lease, ancestor directories and owned host/bootstrap effects. Reject
  traversal/reparse, duplicate or unexpected entries. Bound inventory to 512
  entries and record size to 128 KiB; no unrelated project traversal.
- Omit selection_sha256, activation_sha256 and activation_operation_sha256 for
  v2: a never-activated candidate has no such authority. Do not use empty/fake
  selected evidence to satisfy the v1 reader. Fingerprint binds the deterministic
  snapshot and identity; revalidate bytes and live safety at effect boundaries.

| Boundary | Producer / actual consumers | Evidence |
| --- | --- | --- |
| Direct origin arguments | HostPayloadMaterializer/Actions action context -> ProcessRunner admitted arguments -> materializer parameters -> engine origin writer; Supervisor route already forwards origin | authored C# action/argument tests, source receipt-order check, existing PS writer/readers |
| v2 removal intent | engine removal writer -> Get-InstanceRemovalIntent/Get-InstanceRemovalIntents -> next-change admission, Uninstall cleanup, fresh Install preflight/handoff, operation recovery; materializer RemoveIntegration/preflight uses same classifier | emitted production bytes through real PS readers and production transaction/entry flow |
| desired-state and command-result | existing engine/materializer writers -> Editor ProjectIntegrationState/ProductStatus/Manager plus existing runtime consumers | unchanged schemas; authored UI tests and production status output assertions |
| instance/generation/lease records | existing production decoders used by classifier, including old manifest shape | observed-shape synthetic fixture with runtime-derived roots and real readers |

Repository search found no C# or Node reader of removal-intents; they consume
unchanged desired-state/status projections. Package-owned engine/materializer
own v2 interpretation. Do not add a generation change or weaken old readers.
If actual call-chain discovery contradicts this map, stop with the exact gap
before out-of-envelope edits; do not silently omit a consumer.

## Exact write allowlist

Paths below are relative to com.rice.ai-codedb; change only needed members.

- Editor/AICodedbHostPayloadMaterializer.cs
- Editor/AICodedbActions.cs
- Editor/AICodedbProcessRunner.cs
- Editor/AICodedbManagerWindow.cs
- Editor/AICodedbEditorLifecycle.cs
- Tools~/codedb-instance-engine.ps1
- Tools~/materialize-codedb-host-payload.ps1
- Tests/Editor/AICodedbManagerUiTests.cs
- Tests/Editor/AICodedbEditorLifecycleTests.cs
- Tests~/test-codedb-host-payload-materializer.ps1

Coder additionally owns only FAILED-INSTALL-REPAIR-RESULT.md and
FAILED-INSTALL-REPAIR-IDENTITY.txt in this task directory. Planner owns this
packet, TASK and contract disposition. Verifier owns only
FAILED-INSTALL-REPAIR-VERIFICATION.md. No shared document edits by Coder.
Direct referenced declarations in Editor, Tools~, Payload~/AIWork/codedb and
the existing focused tests may be read in bounded slices; immutable generation
metadata may be read to establish old closure, never edited or executed.

## Focused evidence and limits

Use one new focused FailedPreparationRecoveryOnly switch in the existing PS
harness; actual production writers/readers/transactions/entry methods must be
exercised, not replaced by mock validators. Native Provider/watcher/Supervisor
startup and process observation may use explicit fixture seams. No live service
or real candidate access. Include:

- valid observed pre-fix shape: PROVISIONING + matching editor lease, no control,
  retained old host/bootstrap, no invented direct historical receipt link;
- confirmed logical removal, PENDING retention and fresh Install using different
  identity; source/manual-only evidence is insufficient for PS transition;
- selection/activation conflict, wrong project/hash/path, live/ambiguous holder,
  unexpected mutable bytes; preserve refusal-state bytes;
- interrupted intent/transaction finalization and one explicit recovery replay;
- old installed-removal v1 reader remains accepted;
- failed/missing/unknown/pending Install does not request reconcile; success does;
  direct admitted arguments include the stable action/operation identity.

Run one scoped syntax/static/diff batch and one focused PS family, each <=300 s.
At most two causal corrections within this envelope, no unchanged reruns; stop
and return stable partial evidence on structural gap or third failure. Coder
working window <=60 minutes; independent Verifier <=30 minutes. Normal output
<=32 KiB/200 lines, rg/log <=16 KiB/50 matches, cumulative <=128 KiB. Truncated
reads are not complete evidence; narrow the next necessary inspection.
C# tests are authored/source-reviewed only: Unity compile/EditMode NOT RUN.
Do not repeat previous 48-case human PASS, old manifest family or full regression.

Record base/head, ordered raw SHA256 hashes of every allowlisted file, changed
paths and binary patch identity; assert all generation bytes unchanged, index
untouched and unrelated initial dirty content preserved. Stable Coder handoff
precedes independent Verifier; findings return once to User for disposition.

## Protected state and handoff

All Unity projects, real candidate/receipt paths, exported artifacts, machine
Provider, MCP configs and every immutable generation (including poc.39/poc.40)
are protected. No Unity/MCP/CUA/BatchMode, external process probe, real Install,
cleanup, background service, commit, push, export or remote task update.
F-IMC-01 / P3 remains DEFERRED; do not repair it here.
Prior reassessment remains historical evidence. This packet supersedes its
SOURCE_REPAIR_DECISION_REQUIRED next-action pointer only.

## Planner Continuation 01 - Same Authorized Scope

The first Coder window ended PARTIAL / OUTPUT_BUDGET_EXCEEDED before product
edits or tests. Its initial RESULT/IDENTITY evidence remains historical and
must be preserved. Ten allowlisted files, HEAD/index and all 358 generation
files were unchanged. This is an inspection-process failure, not a failed
implementation or an expanded design request.

Under the user's explicit source repair and standing prerequisite authority,
Planner authorizes one same-scope continuation with a fresh 128 KiB output
window. Reuse existing baseline and source observations. Do not emit baseline
inventories or repeat completed discovery. Return only count/digest summaries;
each source excerpt <=100 lines and each response <=8 KiB. If a baseline needs
rechecking, compute comparisons in the shell and return mismatch counts/names
only. The implementation/evidence limits and protected state remain unchanged.
Append completion to existing result/identity rather than erase the partial
attempt. Coder may now resume; Verifier stays unstarted until stable source.

Identity interpretation: preserve actual Manager action across pre-admission
Supervisor fallback. When no Supervisor operation was admitted, mint the direct
operation once before direct receipt hashing; never invent a server operation.

## Planner In-Scope Correction 01 - Preserved Generation Authority

The initial focused family reached the real old-generation reader and failed:
poc.39 has one exact Package bootstrap transition and Package-preserved immutable
manifest/worker files, but has no entries in RetiredTargetMap. That map therefore
cannot be the sole authority for the frozen never-activated failure fixture.
This is an in-allowlist classifier/reader correction, not permission to edit
metadata or historical generations. Initial failure stays recorded.

Admit an explicit FAILED_PREPARATION-only internal route through
Get-ValidatedRetiredInstance / Assert-InstanceGenerationClosure /
Get-InstanceGenerationPackageIdentity. It must require PROVISIONING, empty
verified_at_utc, valid original INSTALL origin, the unique exact declared
Package transition and safe Package-preserved manifest/worker paths. Compare
the project's manifest/worker and every declared generation file to the trusted
Package generation closure. Bind that proof into the v2 intent and revalidate
its consumer paths. Missing/ambiguous transition, redirected/missing Package
files, mismatched generation identity/hash or active/verified candidates refuse.
Default installed/retired readers retain their current RetiredTargetMap check.
No broad skip-validation switch, current-version demand or arbitrary generation
discovery is authorized. Add focused positive/rejection/default-route evidence
to the same family; this uses causal correction 1 of 2, not a new test budget.

## Planner Reassessment / Continuation 02 - Shared Wrapper Handoff

Continuation 01 stopped correctly after three failing family runs. Preserve
all evidence and its stable 9-path partial patch identity
fc7fa2a594201bc76b3be433333ea032dbaa48cf82588a6f21bc021c79d5044c.
The last run proved 41 assertions through actual logical removal and recovery,
but NOT fresh Install. Do not route that partial snapshot to Verifier.

The remaining contradiction is inside the approved objective: immutable failed
candidate retention was conflated with the existing shared stable launcher
which fresh Install publishes. User's continuous repair and prerequisite grant
covers this same-file contract correction. No real effect authority is added.
Freeze the following clarification, superseding only earlier wrapper retention:

1. Exclude stable wrapper from retained_effects immutable FILE entries. Keep
   candidate, old generation and other recorded bootstrap files byte-exact.
   retained_wrapper_sha256 records the actual authenticated wrapper at removal;
   empty string means absent. This v2-only rule never changes v1 semantics.
2. Before removal/Install, accept only that exact original hash or absence.
   Keep strict path/type/reparse and unknown-content refusal. Fresh Install
   preflight obtains desired wrapper bytes only from current trusted Package.
3. Existing activation transaction binds INSTALL, a different candidate and
   wrapper original existence/pre-image plus canonical desired hash. During
   publication only this fully bound journal permits original/desired states;
   ambiguous/interrupted authority uses existing recovery or refuses.
4. After commit, wrapper authority belongs to the different READY selection,
   its matching COMMITTED activation and authenticated generation wrapper hash.
   Later normal activation uses its current committed authority. Preserve old
   intent's original observation forever; do not rewrite historical hashes or
   claim the failed candidate activated. Low-level existing record decoders
   must avoid recursively calling removal readers/admission/cleanup.
5. Legal wrapper publication may create only its missing fixed ancestor dirs;
   it does not authorize mutation of other retained bootstrap effects.

Same ten-file allowlist, existing record consumer map and protected state.
No new schema family, executor, generation, external operation or UI route.
Focused family adds old/absent/current wrapper cases, exact journal publication
interruption/recovery, unknown bytes/binding rejection and post-Install PENDING
retention. Complete the previously unreached new-candidate and v1 assertions.

Authorize one bounded 25-minute implementation/evidence continuation, one
initial family plus at most one causal correction; no unchanged rerun. Output
window <=64 KiB, per read <=8 KiB/100 lines. Reuse baseline and prior reads.
Record all runs separately and append final identity. Stop on further structural
gap or exhausted budget with an exact handoff; do not self-renew. Stable source
and passing agreed evidence are required before independent Verifier.

## Planner Continuation 03 - Complete Interruption Fixture Only

Continuation 02 froze partial patch SHA256
369fd10eb27648527392eb7bc300f6d328fea20eadaecab395f7417791605f81.
All three CURRENT/ABSENT/OLD complete transitions passed; final execution reached
193 assertions including real ACTIVATING journal publication. Remaining failure
was the fixture digest reading its own exclusively held materialize.lock, before
the remaining wrong-binding/interruption/recovery assertions. No product failure
was established at that point. Historical partial evidence stays unchanged.

Under the same human source/prerequisite authority, complete this isolated
evidence in one 15-minute fixture-only window. Only
Tests~/test-codedb-host-payload-materializer.ps1 and Coder result/identity may
change. All product implementation bytes are frozen at Continuation 02.

- Exclude only the exact harness-owned currently held materialize.lock path
  from its refusal digest; all authority/effect files and every other lock-like
  path stay covered. No broad filename/directory exclusion or relaxed decoder.
- Inspect remaining interruption assertions together; correct test mechanics
  only, preserving production semantic expectations and refusal-byte checks.
- A focused interruption-only selector in the existing harness is allowed, so
  the unchanged three complete-transition cases need not repeat. Reuse their
  exact product-snapshot evidence. Run only remaining affected fixture, parse and
  scoped diff checks. Up to three bounded runs (each <=300 s), correcting only
  diagnosed harness mechanics; no unchanged rerun or product repair.
- Output <=32 KiB total, <=8 KiB/read. Record initial and corrective outcomes.
  If a product contradiction appears, preserve it and stop for Planner rather
  than changing expectations. End with current ordered identity and declaration
  that all previously tested product bytes remained unchanged.

When remaining assertions pass, Coder may classify combined isolated evidence
complete while explicitly identifying reused versus newly executed scenarios.
Then stop for targeted independent Verifier. Unity remains NOT RUN.

Continuation 03 made no edits/runs and stopped on an oversized initial read.
Planner replaced that stopped child with a fresh, minimal-context fixture Coder
under FAILED-INSTALL-FIXTURE-COMPLETION.md. Product scope remains frozen; this
replaces the failed inspection window, not the source contract or human grant.

## Final source handoff

The replacement fixture Coder completed the remaining 51 assertions in 43.514 s
with exit 0 and stderr 0, changing only the harness. Independent Verifier then
admitted the latest ten-file snapshot and accepted combined isolated evidence;
SCOPED_SOURCE_REVIEW_PASS, no actionable finding in the frozen claims. See
FAILED-INSTALL-REPAIR-VERIFICATION.md. Earlier failed windows remain historical.
Both Coder roles and Verifier stopped. C# compilation/Unity/live integration and
real candidate recovery remain NOT RUN. Source disposition is ready for User;
no source ACCEPT, commit, export or actual recovery is inferred from review PASS.

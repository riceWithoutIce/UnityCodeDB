# Task: cdb-v0.3-p0-s18-preview-release-acceptance-closure

## Metadata

- Product: UnityCodeDB
- Version: `v0.3.0`
- Workflow: `codedb-workflow-v2`
- Candidate version: `0.3.0-preview.1`
- Status: `ROUTE_REASSESSMENT_REQUIRED / REFACTOR_AUTHORIZED`
- Planner: `UnityCodeDB v0.3 Planner`
- Coder: `v0.3.coder.deep`
- Verifier: `v0.3.verifier.deep` after one stable complete result and Planner
  routing
- Review mode: `RELEASE`
- Execution profile: `v0.3.coder.deep`
- Session policy: `REUSE_ONLY`
- Predecessor: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
  (`ACCEPT`, commit `eb21a7a`)
- Roadmap position: Runtime Release Gate, Delivery Sequence item 10 closure
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance/DECISION.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance/RESULT.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance/verifications/VERIFICATION-01.md`

## Objective

Close one independently acceptable release outcome against the exact committed
`0.3.0-preview.1` candidate:

1. prove the normal runtime-isolation path in the tracked development
   validation project;
2. after a separate human publication authorization, bind one exact published
   artifact to the accepted commit and candidate identity;
3. prove that exact artifact in one clean, repository-external, Package-only
   Unity project and one real new Codex task; and
4. obtain one independent, claim-bounded Verifier decision.

This is one continuous task with human-gated phases, not S18a/S18b/S18c and not
a task per command, UI transition, test, or local defect. Diagnosis, in-scope
repair, adjacent evidence, and consolidation remain in this Task ID while the
objective and authority envelope remain unchanged.

## Frozen Starting State

- Branch: `codex/v0.3.0-legacy-workflow`.
- Committed HEAD:
  `eb21a7a5d28548e0369db35ee0cac1c0d626183c`.
- Local Package candidate: `0.3.0-preview.1`.
- Immutable current generation: `poc.35`.
- Reviewed Provider artifact: `0.5.0-28e3912-c2`.
- Provider protocol/capability contract:
  `codedb-cli-v1` / `codedb-search-tools-v1`.
- Accepted S17 Phase A candidate identity:
  `af645f364fb41202ef3b56d7113b5d29aa6aef32`.
- Accepted S17 terminal-evidence six-path identity:
  `970b95b826a5aefa7130a17a813a5fc3240337cb7d616f0fc2459ec517095a04`.
- `UnityValidationProject` is human-confirmed closed at task creation.
- Existing `UnityValidationProject/ProjectSettings/ProjectSettings.asset`,
  `UnityValidationProject/.codex/`, and `UnityValidationProject/AIWork/` state
  is inherited and protected. It is not candidate source or release evidence.
- Existing untracked S14/S14r task records are inherited, protected, and outside
  this task's identity and commit scope.
- No `v0.3.0-preview.1` tag, push, Package publication, release promotion, or
  third-party Package-only acceptance is implied by the committed candidate.

## Fixed Product And Ownership Boundaries

1. Unity Bridge and Manager remain cached clients. Unity's main thread must not
   perform CodeDB filesystem, hash, process, lock, PowerShell/Node, synchronous
   IPC, indexing, or full-status work.
2. The project-local Supervisor remains the only operational-readiness and
   maintenance-queue authority. Lifecycle, Snapshot, Manager, PowerShell, and
   the wrapper consume authenticated, revision-bound evidence rather than
   recreating readiness rules.
3. Runtime and process ownership remains project-local. No user-global CodeDB
   registration, global daemon, repository runtime, alternate wrapper, or
   manually injected configuration may make the third-party scenario pass.
4. `poc.35` and all earlier generations are immutable. Any required payload
   byte change requires a route reassessment and a separately authorized
   successor generation; it must never modify `poc.35` in place.
5. Editor version is observed release evidence, not an environment-variable or
   hard-coded executable-path gate. Only the Package's declared compatibility
   contract may reject an Editor line.
6. Coder and Verifier do not launch, create, select, reconnect to, or terminate
   Unity, Unity Hub, a third-party project, or a Codex client. The human owns
   those transitions.
7. Publication is a separate high-risk human decision. This task card may
   prepare an exact publication proposal but does not authorize tag, push,
   registry mutation, Package publication, or promotion.

## Scope

### Phase A - Local Runtime-Isolation Gate

After one separate phase authorization, the human opens
`UnityValidationProject`. Use one continuous, human-operated scenario against
the frozen candidate:

1. Complete compilation with zero current C# errors. Record warnings without
   converting an already dispositioned non-blocking warning into a new blocker.
2. Reach a stable supported cold state without deleting runtime data, editing
   configuration, stopping a process, repeatedly refreshing, or using
   Reinstall as a normal-path prerequisite. Indefinite `Checking`, an
   unsupported dead end, or terminal failure without a valid action fails the
   gate.
3. Enter Play before opening Manager, return to Edit Mode, and observe one
   ordinary Domain Reload/reconnect without duplicate Supervisor, Coordinator,
   Provider, adapter, or maintenance work.
4. Open Manager, allow normal repaint/cache/tab activity, then close it. The
   terminal evidence must show all prohibited main-thread work counts and the
   violation count at zero, with no refresh left in flight.
5. Confirm that query-first ordering and stale/missing-index behavior remain
   consistent with the accepted focused evidence. Do not manufacture a second
   maintenance operation merely to repeat an already-covered assertion.
6. Close Unity normally. Shutdown must not require closing a stuck Manager
   first, exceed the declared wait, stop an external client, or leave an
   authenticated Package-owned runtime in an unresolved state.

The human supplies visible terminal evidence and reports the exact failed step
if the scenario stops. Coder records and interprets that evidence; it does not
substitute CUA, Unity MCP, BatchMode, process probes, protected runtime reads,
or repeated UI attempts when the human observation is available.

### Phase B - Exact Publication Gate

Phase B is `NOT_AUTHORIZED` at task creation. After Phase A passes, Planner
prepares one proposal containing the exact commit, candidate identity, tag,
remote, Package source, artifact hash plan, and rollback boundary. The user
must explicitly authorize the exact external mutations.

If authorized, publish only the accepted candidate. Record the resulting tag,
artifact identity, and source in sanitized form. A local file reference, copied
Package directory, repository checkout, direct wrapper probe, or mutable
workspace cannot substitute for the published artifact.

If publication is not authorized or the publishing prerequisite is absent,
retain this Task ID and record `DEFERRED / PUBLICATION_AUTHORIZATION_REQUIRED`;
do not create a publication micro-task.

### Phase C - Third-party Package-only And Real Codex Gate

Phase C is `NOT_AUTHORIZED` until Phase B produces one exact published artifact
and the human provides a clean standalone Unity project outside this repository.
The human creates, opens, operates, and closes that project.

One continuous scenario must prove:

1. Package Manager installs the exact published `0.3.0-preview.1` artifact;
   the recorded source and artifact identity match Phase B.
2. Compilation completes with no current C# error and without repository-local
   or user-global CodeDB fallback.
3. Immediate Play before Manager, Edit return, one Domain Reload/reconnect,
   stable project-local runtime ownership, Manager cache-only behavior, and
   normal shutdown follow the same Phase A acceptance contract.
4. One real new Codex task rooted at the standalone project exposes the expected
   project-local CodeDB namespace, returns a usable `codedb_status`, and
   completes one bounded read-only query.
5. No repository development payload, direct wrapper probe, global MCP
   registration, fake Git root, manual runtime cleanup, Reinstall, or second
   CodeDB action is used to make the golden path pass.

### Phase D - Independent Release Review

After Phases A-C produce one stable result, Planner may route the frozen
snapshot once to `v0.3.verifier.deep`. Verifier performs one targeted read-only
RELEASE review, reuses valid Coder and human evidence, reports all in-scope
findings once, and returns to Planner/User for
`ACCEPT / FIX / DEFER / STOP`. Verifier does not rerun unchanged tests or
dispatch repairs.

## Change And Read Boundaries

The task is evidence-first. At creation, only this task's `RESULT.md` and later
Verifier report are writable. If a concrete Phase A or Phase C product defect
is demonstrated, the same Coder dispatch may diagnose and repair it only inside
this conditional vertical allowlist:

- `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

Read-only dependency closure is limited to direct symbols and exact manifests
needed to classify the failed acceptance step. No repository-wide search,
whole-file dump, full diff, broad history scan, full regression, or unrelated
task replay is permitted.

A required change outside this allowlist, any immutable generation change,
Provider contract change, Package metadata/version change, global
configuration change, or new external side effect returns
`ROUTE_REASSESSMENT_REQUIRED` before editing.

## Execution Envelope

- Mode: `CONTINUOUS_WITHIN_SCOPE`.
- Active role budget: Coder deep `60 minutes`; Verifier deep `30 minutes`.
- Mechanical corrections per local evidence scenario: up to `2`.
- Corrected semantic attempts per local non-Unity evidence scenario: up to `2`.
- Independent product causes before route reassessment: up to `2`.
- Local repair iterations before route reassessment: up to `2`.
- Unity/external scenario attempts: no implicit attempt; each phase
  authorization declares one initial continuous scenario and at most one
  cause-corrected scenario.
- Coder does not return to Planner for each command failure, fixture correction,
  or in-allowlist defect. It diagnoses, repairs, runs only adjacent evidence,
  and consolidates one result while budgets and authority remain valid.
- Reuse S17 Phase A, scoped diff-check, human compile, and affected EditMode
  evidence while their source/contract identity remains unchanged.
- After a source repair, run only the directly affected focused L0 or affected
  EditMode filter. Do not rerun unchanged evidence or a full suite.
- Unity, Unity MCP, CUA, BatchMode, publication, network mutation, third-party
  project use, and real Codex-client actions remain unauthorized until their
  named phase receives explicit human authorization.
- Stop immediately for protected-state access, identity drift, ambiguous
  external-process ownership, attempted global fallback, data/configuration
  corruption risk, or an action that could stop an unrelated process.
- Enter route reassessment when the objective, architecture, allowlist,
  immutable generation, Provider contract, evidence class, or side-effect
  authority must expand; after two local repair iterations; after more than two
  independent product causes; or when the active role budget is reached.

## Explicitly Out Of Scope

- Roadmap item 11 query-corpus and `rg` comparison harness.
- List/glob, symbol, outline, callers, dependency traversal, explore, semantic
  context, batch expansion, Shader/HLSL freshness, and dependency-lane work.
- Performance/completeness/ambiguity corpus runs and the ten-task no-`rg` trial.
- Two-project concurrency, cross-elevation, historical upgrade matrix, broad
  Editor-version matrix, and unrelated release hardening.
- Cleanup, staging, or commit of inherited S14/S14r records or any
  `UnityValidationProject` runtime/generated state.

## Definition Of Done

The task is complete only when:

1. Phase A passes on the exact committed candidate with a stable normal path,
   zero prohibited Unity-main-thread work, reconnect, and owned shutdown.
2. The exact authorized artifact is published and cryptographically bound to
   the accepted candidate.
3. Phase C passes in a clean external Package-only project and a real new Codex
   task without repository/global fallback.
4. One deep Verifier review admits the final identities, reports all findings
   once, and returns `PASS` with deferred matrices explicit.
5. Planner/User records `ACCEPT`; commit, tag, push, publication, and promotion
   remain distinct decisions unless explicitly named by the applicable gate.

## Handoff

- Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`
- Current status: `ROUTE_REASSESSMENT_REQUIRED / REFACTOR_AUTHORIZED`
- Next notification: `v0.3.coder.deep`
- Next action: Coder executes the route-reassessed cleanup-contract separation
  recorded in `ROUTE-REASSESSMENT.md`, runs its one consolidated focused
  evidence batch, and records one terminal result while Unity remains closed.
- Human decision or authorization required: the route continuation is
  authorized; renewed Phase A Unity scenario, Phase B publication, Phase C
  third-party/Codex scenario, Verifier routing, and final disposition remain
  separate decisions.

## Current Route Overlay - 2026-09-15

This overlay supersedes the active routing fields in Metadata and Handoff; it
does not alter the frozen `0.3.0-preview.1 / poc.35` evidence or any historical
result. The full decision is recorded in `ROUTE-REASSESSMENT.md` under
`Fresh-install-only Owner Identity v2 Redesign`.

- Current route:
  `REDESIGN / FRESH_INSTALL_ONLY_OWNER_IDENTITY_V2 / SUCCESSOR_GENERATION_REQUIRED`
- Successor target: `0.3.0-preview.2 / poc.36`; `poc.35` and every earlier
  generation remain immutable.
- Compatibility: v1 Owner Identity is not migrated or handed off. Recognized
  v1 evidence is `REINSTALL_REQUIRED`; missing v2 evidence is `MISSING`;
  partial, malformed, conflicting, unknown, or unverifiable evidence is
  `INVALID_OR_AMBIGUOUS`.
- Current admission: only a complete canonical v2 state/lock pair plus an
  authenticated owner-bound pipe and `core_ready` operational observation may
  produce `CURRENT`.
- Recovery UX: `Remove CodeDB Integration` is explicit, idempotent, limited to
  proven Package-owned project-local integration state, preserves user
  Assets/indexes/data, never stops processes, and is blocked for live, unknown,
  or ambiguous ownership. Unity Package Manager remains responsible for
  removing the Package itself.
- Task shape: continue as one S18 unit. Do not split field, fixture, capture,
  UI, or generation work into micro-task cards.
- Current authorization: documentation and GitHub Project synchronization
  only. Source/test implementation, Unity, Verifier, commit, tag, push,
  publication, and promotion are not authorized by this overlay.
- Next notification: `UnityCodeDB v0.3 Planner`.
- Next action: freeze one exact continuous implementation allowlist and
  bounded evidence budget, then obtain human authorization before routing to
  `v0.3.coder.deep`.

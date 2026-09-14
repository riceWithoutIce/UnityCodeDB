# Task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance

## Metadata

- Product: UnityCodeDB
- Version: `v0.3.0`
- Candidate version: `0.3.0-preview.1`
- Status: `READY / PHASE_A_PROVIDER_CONTRACT_REFACTOR_DISPATCH_AUTHORIZED`
- Planner: UnityCodeDB v0.3 Planner
- Coder: `v0.3.coder.deep`
- Verifier: `v0.3.verifier.deep` after a stable complete result and Planner
  routing
- Review mode: `RELEASE`
- Execution profile: `v0.3.coder.deep`
- Session policy: `REUSE_ONLY`
- Predecessor: `cdb-v0.3-p0-s16-manager-cache-runtime-isolation`
  (`ACCEPT`, commit `5587f47`)
- Roadmap position: Runtime Release Gate, Delivery Sequence item 10
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-supervisor-runtime-recovery.md`
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s14-coordinator-operational-ready-closure/ROUTE-REASSESSMENT.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s14r-operational-readiness-authority-refactor/TASK.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s14r-operational-readiness-authority-refactor/RESULT.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s16-manager-cache-runtime-isolation/DECISION.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance/ROUTE-REASSESSMENT.md`

## Objective

Close one continuous release outcome: form one exact local
`0.3.0-preview.1` candidate, prove its runtime-isolation contract in the
development validation project, then prove the exact published prerelease in
one clean third-party Package-only project.

This is one task with gated phases, not a family of command-, assertion-, UI-,
or failure-level subtasks. Same-outcome diagnosis and coherent repair stay in
this task and append to one `RESULT.md`. A structural authority conflict uses
`ROUTE-REASSESSMENT`; an unavailable human environment uses a checkpoint or
`DEFERRED` state without creating S17a/S17b/S17c.

The task does not claim success merely because the UI fails closed. Completion
requires a usable exact-preview normal path and the declared independent
third-party evidence.

## Frozen Starting State

- Branch: `codex/v0.3.0-legacy-workflow`.
- Committed HEAD:
  `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Package metadata still declares `0.2.5-preview.5`; no `v0.3*` tag currently
  exists. `0.3.0-preview.1` is reserved by the user for this candidate but is
  not yet a tag, commit, published artifact, or accepted release.
- `Payload~/payload-manifest.json` still declares package version
  `0.2.5-preview.5`, payload/generation `poc.34`, and remains the authoritative
  Package runtime contract.
- Inherited uncommitted production input:
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` with canonical
  single-path binary diff identity
  `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- The S14 and S14r task directories are read-only provenance inputs. Their
  records are not accepted source snapshots and must not be rewritten or
  silently included as S17 evidence.
- The validation project contains pre-existing human/generated dirty state:
  `UnityValidationProject/ProjectSettings/ProjectSettings.asset`,
  `UnityValidationProject/.codex/`, and `UnityValidationProject/AIWork/`.
  Preserve it; do not read, clean, reset, stage, or claim byte identity for the
  protected runtime directories.
- Current human-visible Manager observation is
  `Needs attention / Control contract migration: Review required`; the
  sanitized detail states that a live Supervisor PID does not match the
  recorded start or executable identity. This is valid fail-closed behavior,
  but it is not a healthy release-acceptance state. Screenshot evidence alone
  does not identify stale evidence, PID reuse, executable drift, or another
  root cause.
- S16 accepted the Manager cache/main-thread boundary only. It does not promote
  operational readiness, exact-preview packaging, Codex tool injection, or
  third-party Package-only behavior to PASS.

## Fixed Architecture And Release Boundaries

1. The Supervisor is the sole runtime operational-readiness authority.
   PowerShell may authenticate and consume its versioned decision but must not
   independently recreate a competing Coordinator/Provider/adapter readiness
   predicate.
2. Bridge, lifecycle, status, and Manager consume one authenticated,
   revision-bound observation. `NONE` means no cached startup failure; it does
   not independently prove runtime Ready.
3. `MISSING`, `STARTING_OWNED`, `LIVE_AUTHENTICATED`, `STALE_PROVED`, and
   `INVALID_OR_AMBIGUOUS` remain distinct. Ambiguous evidence is fail-closed and
   is never silently deleted, treated as missing, or used to stop a process.
4. Manager remains cache-only and performs zero prohibited CodeDB filesystem,
   hash, process, lock, synchronous IPC, PowerShell/Node, indexing, or
   full-status work on Unity's main thread.
5. Runtime, selected-instance, activation, retirement, lease, and external
   process ownership remain project-local. No global daemon or user-level
   CodeDB registration may participate in acceptance.
6. Published immutable generations are never edited in place. Initial Phase A
   did not authorize modifying `Payload~/Generations/poc.34/` or allocating a
   successor generation. Its bounded admission returned
   `IMMUTABLE_GENERATION_TRANSITION_REQUIRED`. Planner/User continuation
   authorization on `2026-09-11` permits creating only successor generation
   `poc.35`; every `poc.34` byte remains protected and unchanged.
7. Candidate metadata may be prepared locally, but commit, tag, push, registry
   publication, package publication, and release promotion are independent
   human-authorized transitions.
8. Unity Editor compatibility is a supported line/contract question, not a
   hard-coded executable path or environment-variable requirement.
9. Provider compatibility is owned by an exact Provider artifact identity plus
   versioned protocol/capability contract. Package semantic version is not a
   Provider capability and must not be used as the active v0.3 Provider
   admission boundary. Historical schema-1 Provider contracts remain immutable.

## Scope

### Phase A - Closed-project Candidate Consolidation

1. Require human confirmation that `UnityValidationProject/` is closed before
   source or Package metadata edits. Coder does not inspect processes to prove
   this precondition.
2. Perform one bounded admission over the frozen HEAD, the inherited engine
   identity, the named S14/S14r terminal records, and direct source/test paths.
   Do not run a repository-wide diff, log scan, history scan, or reload every
   predecessor checkpoint.
3. Reconcile what S14/S14r implementation is already present in committed HEAD
   with the remaining engine patch. Preserve the patch as input; do not revert
   or blindly accept it. Record one compact authority/consumer table before
   editing.
4. Close the normal operational-readiness path coherently from Supervisor
   authority through PowerShell validation and C# presentation. The recorded
   invalid/ambiguous state is an admission symptom, not permission for manual
   runtime cleanup or a special PID bypass.
5. Update local candidate metadata to `0.3.0-preview.1` only after the code and
   contract are internally coherent. Keep `package.json`,
   `Payload~/payload-manifest.json`, and `CHANGELOG.md` consistent.
6. Run only the focused lower-cost evidence below. Freeze one candidate source
   identity and return to Planner. Do not enter Unity, create a package release,
   or contact Verifier in Phase A.

### Authorized Phase A Continuation - Successor Generation

The initial bounded admission is closed. The user authorized one continuation
of this same S17 Phase A on `2026-09-11` with the following exact scope:

1. Bind the continuation to committed HEAD
   `5587f4739426f11fa859ced02e5e6164b0429a63` and inherited engine binary-diff
   identity `c702a5e5c4748136cf292f962eebadb899fdef9b`. The previous task literals
   were malformed metadata, not evidence of source drift.
2. Create immutable successor generation `poc.35` for package
   `0.3.0-preview.1`, payload/generation `poc.35`, and payload sequence `35`
   from the reviewed `poc.34` closure. Change only bytes required by the
   authorized candidate identity and reviewed runtime closure, and recompute
   every affected manifest hash. Do not edit, replace, or normalize any
   `poc.34` byte.
3. Update `Payload~/payload-manifest.json` and `Payload~/host-current.json` to
   bind `poc.35`, retain `poc.34` as the exact reviewed predecessor/retired
   generation, and keep the strict Package/generation/pointer identity checks.
   Do not relax a validator to admit a mismatch.
4. Update `package.json` and `CHANGELOG.md` for the exact local
   `0.3.0-preview.1` candidate and update only directly coupled fixtures.
5. Pass the current authenticated Supervisor operational-readiness observation
   into recovered materializer `Verify` exactly as the ordinary admitted path
   does. Recovery must not introduce a second readiness authority.
6. Use the renewed bounded evidence budget below, freeze one final candidate
   identity, append the result, and return to Planner. This authorization does
   not include Unity, a later phase, Verifier routing, commit, tag, push,
   publication, or release promotion.

The continuation above stopped during admission before production/test changes
or evidence execution because the schema-1 Provider range rejects
`0.3.0-preview.1`. Its implementation authorization is superseded by the
Provider route reassessment below.

### Route-Reassessed Phase A - Provider Contract Schema 2

The user selected `REFACTOR` and separately authorized one Coder dispatch on
`2026-09-11`. The same S17 Phase A must:

1. Implement the exact schema-2 Provider contract and side-by-side Rice
   distribution `0.5.0-28e3912-c2` frozen in `ROUTE-REASSESSMENT.md`. Reuse the
   exact reviewed upstream executable identity; do not alter or overwrite the
   historical `0.5.0-28e3912` directory contract.
2. Remove active Package-semver comparison from Provider prerequisite
   admission. Authenticate exact artifact identity, `codedb-cli-v1`, and
   `codedb-search-tools-v1`; retain the authenticated runtime tool-surface
   proof rather than trusting the manifest alone.
3. Migrate the Package-owned distribution descriptor, development installer,
   flat Provider contract, direct callers/guidance, and focused fixtures as one
   vertical contract. The installer may verify its own Package candidate but
   must not recreate a Provider-supported Package range.
4. Create `poc.35` and the exact `0.3.0-preview.1` Package/payload/pointer
   closure using schema 2. Preserve every historical generation and schema-1
   Provider identity byte-for-byte.
5. Close recovered materializer `Verify` observation forwarding within the
   same candidate and run only the bounded Phase A evidence below.

### Phase B - Fresh Local Exact-candidate Gate

Phase B is part of this Task ID but is `NOT_AUTHORIZED` at creation. After a
stable Phase A result, Planner/User may authorize one human-operated scenario
using the tracked development project and the exact local candidate snapshot.

The human owns opening, transitions, Console evidence selection, and closing.
Coder and Verifier must not launch, create, select, reconnect to, or terminate
Unity or Unity Hub.

The one continuous scenario must cover, as applicable to the accepted Phase A
result:

- script compilation with no current C# error;
- cold admission to a stable usable state without manual internal cleanup;
- immediate Play before opening Manager, return to Edit Mode, and one proved
  Domain Reload/reconnect without duplicate backend startup;
- Manager open/repaint/tab/cache observation with all prohibited main-thread
  counters remaining zero;
- query-first behavior while one bounded maintenance transition is pending;
- authenticated normal shutdown that preserves unrelated/external clients.

If the current project remains `INVALID_OR_AMBIGUOUS`, stays indefinitely in
`Checking`, exposes no supported next action, or cannot reach the declared
normal path, stop with the exact visible state and one consolidated product or
environment classification. Do not ask the human to delete runtime files,
edit configuration, stop a process, or repeatedly click Refresh/Reinstall.

### Publication Gate

Passing Phase B yields `CANDIDATE_READY_FOR_PUBLICATION`, not third-party PASS.
Planner must present the exact commit/path set, candidate identity, tag, remote,
and Package publication action for separate human authorization. No session may
infer publication permission from this task card or from Phase B success.

Local source, a copied package directory, a direct wrapper probe, or a file
reference cannot replace released-artifact evidence.

### Phase C - Third-party Package-only Acceptance

Phase C is `NOT_AUTHORIZED` until an exact `0.3.0-preview.1` artifact is
published through the separately approved publication gate and the human
provides one clean standalone Unity project outside this repository.

- The human creates/opens/closes the third-party project and initiates UPM
  installation. Coder/Verifier do not create or launch it.
- Install only the exact published candidate identity; record a sanitized
  Package source identity, Editor compatibility line, and artifact hash/tag
  without machine/user absolute paths.
- Use no global CodeDB registration and no repository-local development runtime
  as acceptance input.
- Enter Play immediately before opening Manager, then prove one stable
  project-local Supervisor/selected instance, no duplicate backend, one
  Domain Reload/reconnect, Manager cache-only behavior, and normal shutdown.
- Create a real new Codex task rooted at the third-party project and prove the
  expected project-local tool namespace, usable `codedb_status`, and one
  bounded read-only query.
- Do not invoke diagnostic scripts, manual runtime cleanup, Reinstall, or a
  second CodeDB action during the normal golden path.
- Two-project concurrency, cross-elevation, upgrade-from-historical-artifact,
  and broader environment matrices remain explicitly `DEFERRED` unless later
  frozen by a separate roadmap item.

### Phase D - Independent Release Review

After Phases A-C produce one stable result, Planner may route the same frozen
snapshot once to `v0.3.verifier.deep`. Verifier performs targeted read-only
RELEASE review, reuses valid evidence, reports findings once, and returns to
Planner/User for `ACCEPT / FIX / DEFER / STOP`. Verifier does not dispatch
repairs.

## Allowed Files

Writable in Phase A only when directly required by the coherent outcome:

- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Tools~/install-codedb-provider.ps1`
- `com.rice.ai-codedb/Tools~/codedb-provider-distribution.json`
- `com.rice.ai-codedb/Editor/AICodedbControlContract.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Editor/AICodedbProjectSettings.cs`
- `com.rice.ai-codedb/Editor/AICodedbActions.cs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-provider-installer.ps1`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- `com.rice.ai-codedb/package.json`
- `com.rice.ai-codedb/Payload~/payload-manifest.json`
- `com.rice.ai-codedb/Payload~/host-current.json`
- `com.rice.ai-codedb/Payload~/AIWork/codedb/shared/codedb-machine-provider-contract.ps1`
- `com.rice.ai-codedb/Payload~/AIWork/codedb/scripts/codedb-project-common.ps1`
- `com.rice.ai-codedb/Payload~/AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1`
- `com.rice.ai-codedb/Payload~/Generations/poc.35/**`
- `com.rice.ai-codedb/CHANGELOG.md`
- `com.rice.ai-codedb/README.md`
- `com.rice.ai-codedb/Documentation~/index.md`
- `com.rice.ai-codedb/Documentation~/provider-installation-contract.md`
- this task's `RESULT.md` and `CHECKPOINT-NN.md` only for a real external
  interruption, publication/human handoff, or unavailable prerequisite

The allowlist is a ceiling, not a requested change list. Do not rewrite
unchanged files to make the candidate appear comprehensive. A required change
outside it returns to Planner before editing.

## Protected And Out Of Scope

- All existing `Payload~/Generations/*/` content is immutable and read-only.
  Only creation of the previously absent `Payload~/Generations/poc.35/` is
  allowed; `poc.31` through `poc.34` remain protected.
- The existing Provider distribution identity `0.5.0-28e3912`, its schema-1
  manifest contract, and installed machine directory are historical and
  immutable. Do not inspect or mutate the real machine directory in Phase A.
- S14, S14r, S15, and S16 task records are read-only provenance.
- Do not enumerate, read, edit, stage, clean, or make byte claims about
  `UnityValidationProject/.codex/` or `UnityValidationProject/AIWork/`.
- Preserve all validation-project source/configuration changes unless a later
  separately frozen validation-fixture repair explicitly authorizes one.
- Do not create/copy/substitute a Unity project, install/resolve an Editor,
  create an Editor path alias, inspect the registry, or search drives.
- Do not use Unity MCP as a substitute when its declared surface is unavailable.
- Do not inspect or publish raw process command lines, tokens, user-profile
  paths, machine-absolute paths, or protected runtime documents.
- Discover Read implementation, query corpus, list/glob/symbol/callers,
  semantic context, dependency lane, performance, and the ten-task no-`rg`
  trial remain later roadmap work.
- No commit, tag, push, package publication, release promotion, global
  configuration change, process termination, or cleanup is authorized during
  Phase A implementation.

## Focused Evidence Plan

### Phase A Evidence

```text
Static/source:
  One bounded contract/ownership batch over actual changed paths.

L0:
  One consolidated stop-on-first-failure batch containing only the directly
  affected Supervisor and/or materializer/package-boundary cases.

C# L1/EditMode:
  NOT_REQUESTED at task creation. Request one affected filter only if the
  actual Phase A C# changes cannot be admitted by lower-cost evidence.

Candidate contract:
  Structurally parse package.json and payload-manifest.json, verify exact
  candidate version agreement and immutable-generation closure, then capture
  one final scoped binary identity.

Explicitly not run:
  Full regression, broad EditMode/PlayMode, Unity, Unity MCP, real Codex,
  third-party project, publication, performance, query corpus, or later
  Discover Read gates.
```

Reuse accepted predecessor evidence where its source and contract remain
unchanged. Do not rerun S11-S16 tests merely to restate historical PASS.

### Budgets And Stop Conditions

- Read `TASK.md` once; inspect only named paths and direct references.
- Normal captured output: maximum `64 KiB`; logs/broad searches: maximum
  `16 KiB` or `120` lines; cumulative working-window output: `256 KiB`.
- Normal non-test wait: warn at `60 s`, stop waiting at `120 s`.
- Focused test or human transition wait: warn at `120 s`, stop waiting at
  `300 s`; timeout never authorizes process termination.
- Command construction permits the initial attempt plus at most two mechanical
  corrections before side effects. Record errors without dumping commands or
  logs.
- Phase A static/source batch: `1/1`; one same-cause corrected attempt only
  after Planner authorization.
- Phase A focused L0 batch: `1/1`; one same-cause corrected attempt only after
  a concrete repair and Planner authorization.
- The initial and successor-generation admissions stopped before either Phase A
  evidence batch ran. After explicit dispatch, the route-reassessed Provider
  refactor continuation receives one static/source batch `1/1`, one
  consolidated focused L0 batch `1/1`, one candidate contract parse `1/1`, one
  final scoped diff check `1/1`, and one final candidate identity calculation
  `1/1`. No automatic retry is added.
- Phase B visible scenario: `1/1`, separately authorized; no automatic retry.
- Phase C third-party scenario: `1/1`, separately authorized; no automatic
  retry.
- Final scoped status/diff check and candidate identity: `1/1` each over actual
  task paths; no repository-wide diff or repeated identity calculation.
- Starting structural repair count: `0/2`. Starting consecutive
  diagnostic-only checkpoint count: `0/3`. Duplicate authority, a required
  immutable-generation mutation, or repeated patching triggers immediate
  route reassessment.
- Stop on identity drift, protected-state access, unexpected file, unavailable
  human/publication prerequisite, sensitive output, unowned process impact,
  or evidence that the normal path requires manual internal cleanup.
- No automatic model/profile change. Do not create a replacement session when
  the deep binding is busy, unknown, or unavailable.

## Result Contract

`RESULT.md` is one consolidated chronological record. At each handoff it must
state:

- current phase and `PASS / FAIL / BLOCKED / DEFERRED`;
- exact changed paths and one stable candidate identity;
- authority/consumer contract and whether inherited engine input was accepted,
  changed, or left outside the candidate;
- candidate package, payload, and immutable-generation identities;
- commands/tests actually run, exit codes, waits, batch/retry counts, and first
  failure;
- human evidence as sanitized structured values, never machine paths or full
  logs;
- `NOT RUN / DEFERRED` boundaries without promoting another evidence class;
- next role and exact action, with all remaining human authorizations.

Coder does not contact Verifier, commit, tag, push, publish, clean, or start the
next phase. Planner does not poll after dispatch.

## Definition Of Done

- One immutable, internally coherent `0.3.0-preview.1` candidate is frozen and
  its Package/runtime identities agree.
- The operational-readiness decision has one authority and the normal current
  instance path reaches a stable usable state without manual internal cleanup,
  identity bypass, or duplicate owner.
- Fresh local exact-candidate evidence closes cold start, immediate Play,
  reconnect/Domain Reload, Manager main-thread zero-I/O, query-first
  maintenance, and authenticated shutdown.
- One clean external project installs the exact published prerelease and proves
  the normal Package-only Unity and real new-Codex-task path.
- Every excluded matrix remains explicit; no local source or wrapper probe is
  substituted for released-artifact or third-party evidence.
- `v0.3.verifier.deep` returns one independent RELEASE verdict on the stable
  snapshot, after explicit Planner routing.
- User records `ACCEPT`; commit/tag/push/publication state is reported exactly.

## Handoff

- Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
- Current status:
  `READY / PHASE_A_PROVIDER_CONTRACT_REFACTOR_DISPATCH_AUTHORIZED`
- Human precondition: `UnityValidationProject/` was reported closed by the
  human on `2026-09-11`; Coder must not independently inspect process state.
- Route decision: the user selected the same-S17 Provider schema-2/capability
  refactor and separately authorized one dispatch to the existing
  `v0.3.coder.deep` binding on `2026-09-11`.
- Next notification: existing `v0.3.coder.deep` binding by manual transfer.
- Next action: manually transfer this updated task once to the existing
  `v0.3.coder.deep` binding. Coder executes one bounded Phase A continuation
  and returns its stable result to Planner.
- Human decision or authorization required: any corrected retry; affected
  EditMode; Phase B Unity scenario; real Provider installation;
  candidate commit/tag/push/publication; Phase C third-party scenario; Verifier
  routing; final acceptance and release promotion.

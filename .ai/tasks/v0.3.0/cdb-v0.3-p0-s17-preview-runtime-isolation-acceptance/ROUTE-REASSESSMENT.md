# Route Reassessment: S17 Provider Compatibility Authority

## Trigger

- S17 Phase A must form one exact `0.3.0-preview.1` Package candidate and new
  immutable generation `poc.35` while retaining every `poc.34` byte.
- The admitted Provider artifact is `0.5.0-28e3912`, upstream commit
  `28e3912d5cd67ff3499734984f3e3d626a204796`, executable SHA-256
  `38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7`,
  and protocol `codedb-cli-v1`.
- Its schema-1 manifest and Package-owned consumers require Package range
  `>=0.2.5-preview.5,<0.2.6`. `0.3.0-preview.1` is therefore rejected before
  the normal runtime path can start.
- The range is repeated in the distribution descriptor, installer, flat
  machine contract, immutable instance worker, fixtures, and installed
  manifest. Expanding only one copy would create conflicting compatibility
  authorities.
- S17 stopped before creating `poc.35` or changing production/test bytes. Its
  renewed static, L0, contract, diff-check, and candidate-identity budgets are
  unused.

This is a structural compatibility-authority conflict, not permission to widen
one semantic-version literal. S17 is `ROUTE_REASSESSMENT_REQUIRED` until the
route below is selected and separately dispatched.

## Frozen State

- Branch: `codex/v0.3.0-legacy-workflow`.
- Committed HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Inherited engine binary-diff identity:
  `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- `poc.34` is the immutable `0.2.5-preview.5` generation and has zero scoped
  worktree diff. `poc.35` does not exist.
- Existing Provider distribution `0.5.0-28e3912` and its schema-1 manifest are
  immutable historical inputs. They must not be edited or replaced in place.
- The development installer retrieves the exact reviewed upstream executable
  and constructs the installed Provider manifest. A manifest-contract change
  therefore does not imply a changed executable, but it does require a new
  Rice distribution identity and machine directory.
- No real Provider installation, external Provider read, network retrieval,
  Unity operation, publication, or process action is authorized by this
  reassessment.

## Causal Summary

### Security facts that remain required

1. Provider ID, Rice distribution identity, upstream commit, executable name,
   executable SHA-256, source, path/reparse closure, and protocol remain strict
   fail-closed checks.
2. The Package must not follow `latest`, infer compatibility from upstream
   semantic version, accept an arbitrary machine binary, or mutate an existing
   Provider directory in place.
3. Runtime admission must still prove the required Provider tool surface using
   the authenticated initialize/`tools/list` handshake and bounded probes.
4. A failed candidate install preserves every existing Provider directory and
   project/runtime state; no process is stopped.

### Coupling to remove

- Package semantic version is a release identity, not a Provider protocol or
  capability. A Package-only lifecycle/UI change must not require a new
  Provider binary merely because `0.2.5` became `0.3.0`.
- Requiring the Package and Provider to repeat an identical semver interval
  makes compatibility a duplicated declaration. It blocks a known executable
  even when its protocol, hash, and required tool surface are unchanged.
- Silently ignoring the existing schema-1 interval is also invalid because it
  would reinterpret an immutable Provider manifest after installation.

## Selected Route

Disposition: `REFACTOR`.

S17 remains one continuous release task. Its next Phase A continuation owns the
Provider-contract migration, successor generation, recovered-Verify closure,
and exact candidate identity together; no S17r microtask is created.

### Provider contract schema 2

1. Allocate Rice distribution identity `0.5.0-28e3912-c2`. The `c2` suffix
   identifies Provider contract schema 2. It uses the same reviewed upstream
   version `0.5.0`, commit, executable bytes, executable SHA-256, protocol, and
   source as the historical distribution, but installs into a distinct
   versioned machine directory.
2. The strict installed Provider manifest schema is exactly:
   - `schema_version` = `2`;
   - `provider_id` = `killop/codedb-mcp`;
   - `version` = `0.5.0-28e3912-c2`;
   - `commit` = the frozen upstream commit;
   - `executable` = `codebase-mcp.exe`;
   - `sha256` = the frozen executable SHA-256;
   - `protocol` = `codedb-cli-v1`;
   - `capability_contract` = `codedb-search-tools-v1`;
   - `source` = `https://github.com/killop/codedb-mcp`.
3. Schema 2 contains no supported-Package semver fields. Machine prerequisite
   admission does not receive or compare a Package version. It authenticates
   the exact Provider artifact and declared protocol/capability contract.
4. `codedb-search-tools-v1` requires the reviewed Provider search surface:
   `codedb_search`, `codedb_text_search`, and `codedb_find`. Static declaration
   does not replace the existing authenticated runtime tool-surface proof.
5. The Package-owned development distribution descriptor also moves to schema
   2 and the new Rice distribution identity. It may reuse the frozen upstream
   executable bytes, but it generates a new schema-2 manifest and installs it
   beside, never over, `0.5.0-28e3912`.
6. The Package-owned installer may continue to verify that it was invoked for
   its exact Package candidate. That self-consistency check is not Provider
   compatibility and must not reintroduce a Provider-supported Package range.

### Generation and migration boundary

1. `poc.31` through `poc.34`, their schema-1 Provider contracts, manifests,
   transitions, and Provider directory identities remain byte-for-byte
   historical state.
2. New `poc.35` and the flat v0.3 payload bind only Provider distribution
   `0.5.0-28e3912-c2`, schema 2, protocol `codedb-cli-v1`, and capability
   contract `codedb-search-tools-v1`.
3. A machine containing only the schema-1 Provider is classified as a missing
   or incompatible prerequisite for the v0.3 candidate, with the existing
   supported `Configure Dependencies` path. It is not deleted or overwritten.
4. Package, payload, generation, pointer, Provider contract, and all file hashes
   must close over the same exact `0.3.0-preview.1`/`poc.35` candidate.

### Evidence boundary

The continuation uses one coherent stop-on-first-failure Phase A evidence
budget. It must prove:

- strict schema-2 property allowlists and rejection of schema, artifact,
  commit, hash, source, protocol, and capability mismatches;
- absence of Package semver from active Provider compatibility admission;
- preservation of the historical schema-1 Provider and all `poc.34` bytes;
- side-by-side, fail-closed, idempotent fixture installation of the schema-2
  development Provider without real download or machine mutation;
- `poc.35` immutable closure and exact candidate metadata/pointer agreement;
- recovered materializer `Verify` consumes the same authenticated Supervisor
  observation as the ordinary path;
- one final scoped diff check and one final candidate identity.

C# L1/EditMode is requested only if actual affected C# changes cannot be
admitted by the bounded static/L0 evidence. Unity, Unity MCP, real Provider
installation, network retrieval, Phase B/C/D, publication, Verifier, commit,
tag, push, and release promotion remain separately authorized transitions.

## Rejected Alternatives

- Widen `>=0.2.5-preview.5,<0.2.6` locally while leaving the installed manifest
  unchanged.
- Reuse the versioned directory `0.5.0-28e3912` for different manifest bytes.
- Treat the schema-1 range as advisory or silently ignore it for v0.3.
- Keep `0.2.5-preview.5` inside `poc.35` to satisfy the old check.
- Change `poc.34` or another published generation in place.
- Build or adopt an unreviewed newer Provider merely to obtain a wider version
  range.
- Split each descriptor, installer, payload, generation, or recovery update
  into separate command-level tasks.

## Human Decision

- Disposition: `REFACTOR`.
- Decision date: `2026-09-11`.
- Decision owner: user.
- Selected envelope: schema-2 capability compatibility, new side-by-side Rice
  distribution identity, same reviewed executable, and one continuous S17
  Phase A candidate continuation.
- This decision authorizes Planner documentation only. It does not authorize
  Coder dispatch, source changes, tests, Unity, Provider installation,
  publication, commit, tag, or push.

## Handoff

- Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
- Current status: `ROUTE_REASSESSMENT_COMPLETE / REFACTOR_SELECTED`.
- Next notification: UnityCodeDB v0.3 Planner.
- Next action: Planner obtains explicit dispatch authorization, then manually
  transfers the updated S17 task to the existing `v0.3.coder.deep` binding.
- Human decision or authorization required: Coder dispatch; any corrected
  evidence retry; affected EditMode; Phase B/C/D; real Provider installation;
  Verifier routing; commit, tag, push, publication, promotion, and acceptance.

Current S17 Provider route reassessment is complete. The next action is an
explicit user decision on Coder dispatch; no next role is contacted
automatically.

## Dispatch Authorization

- Authorization date: `2026-09-11`.
- Decision owner: user.
- Authorized action: one manual transfer of the updated S17 Phase A Provider
  contract refactor to the existing `v0.3.coder.deep` binding.
- The dispatch does not authorize an automatic retry, Unity, Unity MCP, real
  Provider installation, Phase B/C/D, Verifier routing, commit, tag, push,
  publication, or release promotion.

Current status: `REFACTOR_SELECTED / CODER_DISPATCH_AUTHORIZED`.
Next notification: existing `v0.3.coder.deep` binding by manual transfer.
Next action: Coder executes the bounded continuation once and returns its
stable result to Planner without contacting another role.

# Route Reassessment: S17 Phase B Terminal Evidence Authority

This section preserves the earlier Provider-contract reassessment above as
historical Phase A provenance. It records the later Phase B route independently
and supersedes the earlier handoff only for the current active route.

## Trigger

- Blocked acceptance path: after `Configure Dependencies` completed
  successfully, the exact local candidate did not complete the automatic
  `poc.34` to `poc.35` handoff and did not reach `Ready`.
- Repair iterations: `0/2`.
- Independent product causes: `1/2`.
- Consecutive diagnostic-only checkpoints: `2/3`.
- Immediate structural signal: a concrete terminal layer failure was projected
  as `Needs attention`, then compressed to generic `Inactive / Not evaluated`
  rows. The UI-referenced runtime evidence was absent at the later authorized
  exact-file read, so the concrete cause could no longer be authoritatively
  diagnosed or routed.

The numeric threshold is not being consumed for another small diagnostic. The
loss of authoritative terminal evidence independently triggers route
reassessment under Workflow v2.

## Frozen State

- Branch: `codex/v0.3.0-legacy-workflow`.
- Committed HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Phase A candidate: Package `0.3.0-preview.1`, generation `poc.35`, Provider
  distribution `0.5.0-28e3912-c2`.
- Canonical Phase A candidate identity:
  `af645f364fb41202ef3b56d7113b5d29aa6aef32`.
- Phase A closure: exact six-path generation delta, final scoped diff check,
  and candidate identity all passed. Historical `poc.34` remained protected.
- Phase B Artifact A:
  `codex-clipboard-ab03102e-bc0c-41a5-94fb-bd7ca5c954d8.png`, 1466x871,
  165042 bytes, SHA-256
  `39f07e13fe88f8b9acd8c4d1b8e2fab933dde9fa5186a764f634eebf46057413`.
- Phase B Artifact B:
  `codex-clipboard-a64aca34-a651-410d-9f70-29587c1182ca.png`, 1466x871,
  166511 bytes, SHA-256
  `0a6b09f2f5cae1b1affea54de08cc22696ed10dce55f6c80b541ee93790d1250`.
- Last acceptance state:
  `BLOCKED / PHASE_B_AUTOMATIC_CONVERGENCE_FAILURE` followed by
  `BLOCKED / EVIDENCE_INSUFFICIENT` for the exact cause.
- The exact relative evidence file
  `UnityValidationProject/AIWork/.runtime/codedb/payload-materializer/mcp-availability.json`
  was absent at the single authorized read. Its bytes, schema, producer, and
  reason were not available.
- The installed Provider and current Unity project remain human-owned external
  state. No cleanup, reinstall, process action, further Unity operation, or
  continued open-project state is required or authorized by this record.

## Causal Summary

- Established facts:
  - Provider configuration completed with exit code `0`; the expected Provider
    executable and project MCP configuration were visibly found.
  - Automatic lifecycle convergence is a distinct later Supervisor
    Upgrade/Probe path.
  - That path ended in `Needs attention`; MCP availability was visibly
    `Unavailable`, but its exact runtime cause was not preserved.
  - A later state-only Manager projection retained the coarse terminal header
    while replacing the concrete layer diagnostics with generic unknown rows.
- Authority defect:
  - The durable product state retains a coarse disposition but not the complete
    authenticated terminal failure envelope needed by the cache-only Manager.
  - The detailed layer evidence can be transient. Once absent, Manager has no
    authoritative details and synthesizes generic rows.
  - Manager presentation therefore outlives the evidence that justified it.
    This is an incomplete authority handoff, not permission for Manager to
    probe runtime state or infer a new cause.
- Uncertainty and deferred evidence:
  - The exact MCP handshake or convergence root cause remains unproved.
  - No evidence supports choosing wrapper, Provider, generation, timing, or
    another runtime condition as that root cause.
  - Phase B Play, Domain Reload, Manager-interaction counters, query-first
    maintenance, shutdown, Phase C, and Phase D remain `NOT RUN / DEFERRED`.

## Route Recommendation

- Recommended disposition: `REFACTOR`.
- Task identity: continue the same S17 release task. Do not create one subtask
  for evidence retention and another for each later runtime symptom.
- Coherent target boundary:
  1. Define one validated, version/revision-bound terminal failure envelope for
     lifecycle convergence. It carries the terminal disposition, stable
     reason/error identity, evidence producer, operation/generation binding,
     and the layer values needed for user-visible diagnosis.
  2. Lifecycle owns acceptance and replacement of that envelope. A newer
     authenticated terminal success or failure may replace it; `Starting`,
     missing evidence, state-only fallback, repaint, or tab/window transitions
     must not erase it.
  3. `AICodedbStatusSnapshot` projects the accepted envelope without inventing
     a second policy authority. `AICodedbManagerWindow` remains cache-only and
     renders that projection without direct runtime reads.
  4. Host-materializer or Supervisor result translation may carry the envelope
     into lifecycle ownership, but may not create a second readiness policy.
  5. One focused fixture covers Configure success, automatic Upgrade/Probe
     failure, a subsequent cache-only Manager presentation, and byte-for-byte
     preservation of the actionable terminal reason/layer values.
  6. After the code/fixture gate passes, one separately human-authorized Phase
     B continuation observes the durable reason. If the actual convergence
     cause is inside the predeclared adjacent repair surface, repair and
     re-evaluate it continuously; otherwise return one scope-expansion request.
- Proposed change allowlist for the contract refactor:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
  - `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Direct read-only closure, not automatically writable:
  - `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
  - `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
  - `com.rice.ai-codedb/Editor/AICodedbActions.cs`
- If source evidence proves that translation bytes must change, Planner must
  explicitly add the exact translation file to the change allowlist before
  editing. This does not authorize runtime or Provider changes.
- Rejected patch-only alternatives:
  - Preserve only the `Needs attention` title while allowing diagnostic rows to
    become unknown.
  - Cache a second Manager-local copy of the last error.
  - Extend a transient evidence file's lifetime and keep it as the only reason
    authority.
  - Add an MCP-unavailable special case without proving the runtime cause.
  - Ask the human to repeat Configure, Refresh, Reinstall, cleanup, or runtime
    inspection to reconstruct lost evidence.

## Human Decision

- Disposition: `REFACTOR`.
- Decision date: `2026-09-14`.
- Decision owner: user.
- Authorized envelope at this step: Planner documentation and route freezing
  only. Source/test edits, evidence execution, Unity/EditMode, Phase B retry,
  Provider/runtime operations, Verifier routing, commit, tag, push,
  publication, and release promotion remain separately gated.

## Handoff

- Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
- Current status: `ROUTE_REASSESSMENT_COMPLETE / REFACTOR_SELECTED`.
- Next notification: UnityCodeDB v0.3 Planner/User.
- Next action: align and authorize one closed S17 refactor execution envelope;
  then dispatch it once to the selected idle Coder profile.
- Human decision or authorization required: refactor implementation dispatch,
  focused evidence, affected EditMode, later Phase B continuation, Verifier,
  Phase C/D, commit, tag, push, publication, promotion, and final acceptance.

The S17 Phase B route reassessment is complete. No Coder or Verifier is
contacted automatically.

## Refactor Execution Envelope

Frozen by Planner after the user's `REFACTOR` decision on `2026-09-14`.

### Objective And Acceptance Contract

- Objective: make one lifecycle-owned terminal convergence-failure envelope
  remain authoritative and actionable across the next state-only snapshot and
  cache-only Manager presentation.
- The envelope must retain a stable reason/error identity, producer identity,
  operation/generation or equivalent revision binding, terminal product
  disposition, and the layer values that justified that disposition.
- An authenticated newer terminal success or failure may replace the envelope.
  Missing/transient evidence, `Starting`, repaint, tab/window transitions, and
  state-only fallback must not erase it or replace it with generic unknown
  rows.
- `AICodedbStatusSnapshot` projects the lifecycle-owned value.
  `AICodedbManagerWindow` remains cache-only and must not read runtime state,
  reconstruct the cause, or own a second copy of readiness policy.
- No result may claim `Ready` from the retained failure envelope. Existing
  fail-closed behavior remains intact.

### Closed Scope

- Workflow: `codedb-workflow-v2`.
- Execution profile: `v0.3.coder.deep`.
- Mode: `CONTINUOUS_WITHIN_SCOPE`.
- Change allowlist:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
  - `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Direct read-only closure:
  - the six change-allowlist paths above;
  - `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`;
  - `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`;
  - `com.rice.ai-codedb/Editor/AICodedbActions.cs`.
- `AICodedbEditorLifecycleTests.cs` already contains inherited S17 candidate
  changes. Preserve all unrelated hunks; do not normalize or rewrite them.
- A required change to a translation/read-only file is a scope-expansion gate,
  not implicit permission to edit it.

### Implementation And Evidence

1. Reuse existing lifecycle/status types and ownership where possible. Add an
   abstraction only if it is required to express one immutable validated
   envelope; do not introduce a second readiness classifier or Manager cache.
2. Update the two direct test files as one assertion family. At minimum cover:
   - terminal layered `NeedsAttention` survives a later state-only projection;
   - reason, producer/binding, and affected layer values remain unchanged;
   - repaint/tab/window or equivalent cache-only presentation cannot erase it;
   - authenticated newer terminal evidence replaces it;
   - `Starting`, missing evidence, or an older/mismatched revision does not;
   - Manager remains cache-only and no false `Ready` is created.
3. The existing
   `CachedNeedsAttentionSnapshotIsTerminalAndDoesNotClaimChecking` expectation
   currently encodes generic `Not evaluated` rows. Replace that accepted-old
   behavior as part of the same test-family update; do not create a separate
   fixture-fix task.
4. L0: none applicable. Do not invent an inline parser, source-marker harness,
   or unrelated standalone compile project for this C# state contract.
5. Affected L1/EditMode: update the direct tests now, but do not run Unity or
   EditMode in this dispatch. Return the exact minimal future test filters for
   one separately authorized run against
   `<repository-root>/UnityValidationProject`.
6. Run one final `git diff --check` restricted to the six change-allowlist
   paths. Do not run a full diff, full status, Package-boundary suite, Phase A
   evidence, or another candidate identity calculation.
7. Append one consolidated refactor result of at most `6 KiB` to the existing
   S17 `RESULT.md`; do not create a checkpoint or reproduce command logs.

### Budgets And Stops

- Active Coder time: `60 minutes` maximum. At the limit, finish only the
  current bounded non-side-effecting operation, start no new work, and return
  the stable result.
- Mechanical command corrections: initial attempt plus at most `2` corrections
  per evidence scenario; they do not count as product repairs.
- Structural repair: this implementation becomes iteration `1/2` once source
  bytes change. At most one same-envelope correction may follow a later
  focused test finding; do not consume it in this dispatch without that test.
- Independent product cause remains `1/2`. A newly proven independent cause,
  duplicate authority, compatibility exception, or need for a seventh writable
  path stops the task for Planner reassessment.
- Searches must name one of the nine closed paths and a symbol/pattern, with at
  most `50` matches or `16 KiB`. Use line-ranged reads; no whole-file dumps.
- Normal command output: at most `32 KiB` or `200` lines. No repository-wide
  search, full diff, full regression, or historical task scan.
- Stop immediately before any Unity/EditMode, CUA, Unity MCP, BatchMode,
  process/network/registry action, runtime/Provider/validation-project state
  read, persistent configuration change, or operation outside the closed
  files.
- No commit, tag, push, publish, cleanup, Phase B retry, Phase C/D, Verifier
  routing, or direct message to another implementation/review role.

### Required Handoff

- Terminal success:
  `COMPLETE / IMPLEMENTATION_READY_FOR_AFFECTED_EDITMODE` with changed paths,
  concise contract explanation, direct test names, scoped diff-check result,
  deferred evidence, and the exact next human authorization.
- Terminal stop: one consolidated `PARTIAL`, `BLOCKED`, or
  `ROUTE_REASSESSMENT_REQUIRED` result with the first boundary crossed; do not
  substitute repeated diagnosis or a new microtask.
- Next notification in all cases: `UnityCodeDB v0.3 Planner`.

## Refactor Dispatch Authorization

- Authorization date: `2026-09-14`.
- Decision owner: user.
- Authorized action: freeze the envelope above and dispatch it once to the
  existing idle `v0.3.coder.deep` binding.
- This authorization includes the bounded source/test implementation and its
  scoped non-Unity handoff evidence. It does not authorize EditMode, Unity,
  runtime inspection, Phase B retry, Verifier, commit, tag, push, publication,
  or release promotion.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `REFACTOR_SELECTED / CLOSED_ENVELOPE_DISPATCH_AUTHORIZED`.
Next notification: existing `v0.3.coder.deep` binding.
Next action: execute the frozen refactor envelope once and return one stable
result to Planner.

## Planner Review And FIX 01 Authorization

- Review date: `2026-09-14`.
- Decision owner: user.
- Disposition: `FIX`.
- Task continuity: remain in
  `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`; do not create a new
  task or checkpoint task.
- Input snapshot: the uncommitted terminal-evidence refactor recorded by the
  latest `RESULT.md` entry. Preserve all inherited and unrelated bytes.

### Confirmed Findings

1. `P1 / AUTHORITY_EPOCH_REVISION_ORDERING`: terminal failure replacement and
   authenticated Ready clearing currently compare only Package fingerprint and
   numeric observation revision. The envelope retains `supervisor_id` and
   `owner_epoch`, but a newly authenticated authority whose revision sequence
   restarts below the previous authority can remain blocked by the old failure.
   Existing direct tests keep one fixed authority and exercise only revisions
   `6`, `7`, and `8`.
2. `P1 / UNINSTALLED_RETAINS_TERMINAL_FAILURE`: an authoritative Uninstalled
   reconcile result bypasses old-failure projection but does not clear the
   lifecycle-owned in-memory envelope. Completion then persists that old
   envelope next to the Uninstalled state. A later display-only restore reads
   the envelope first and projects `NeedsAttention`, hiding the Uninstalled /
   Install user path. The existing cached-Uninstalled test supplies no prior
   terminal failure.

### Frozen Correction Contract

1. Keep Lifecycle as the only terminal-evidence authority. Snapshot and
   Manager remain projection/cache-only consumers and must not add ordering,
   clearing, filesystem, hash, runtime, or Supervisor logic.
2. Make terminal observation ordering authority-aware after the observation
   has already been authenticated and bound by the existing
   `BindProductStatusToSupervisorObservation` contract:
   - for the same `supervisor_id` and `owner_epoch`, require a strictly newer
     revision to replace a failure or clear it with authenticated Ready;
   - a different authenticated Supervisor/owner epoch is a new authority and
     must not be rejected only because its local revision is lower;
   - preserve Package-fingerprint validation, terminal observation validation,
     fail-closed handling of transient/missing/malformed evidence, and rejection
     of stale revisions within the same authority;
   - `observation_id` identifies an observation, not an authority epoch.
3. When the lifecycle has authoritatively classified the project as
   `Uninstalled`, clear both the in-memory and persisted terminal failure before
   the state is exposed or persisted. Do not weaken terminal failure retention
   for `Starting`, missing evidence, malformed evidence, or stale evidence.
4. Add direct regression coverage for:
   - old authority high revision -> new authenticated authority low-revision
     failure replacement;
   - old authority high revision -> new authenticated authority low-revision
     Ready clearing;
   - same-authority older/equal revision remains rejected;
   - authoritative Uninstalled clears a seeded terminal envelope and the
     display-only persisted/cache projection remains Uninstalled with no
     terminal failure;
   - the Install/Uninstalled presentation is not replaced by stale
     `NeedsAttention`.

### Scope And Evidence

- Writable correction paths:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Existing modified paths that must remain byte-preserved in this correction:
  - `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- Existing allowlisted unchanged path that must remain byte-preserved:
  - `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- Read-only direct dependency:
  - `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- A need to modify any other production/test path, move ordering authority into
  Snapshot/Manager, or change the Supervisor protocol is an immediate
  `ROUTE_REASSESSMENT_REQUIRED` stop.
- L0: none applicable.
- Update the affected EditMode tests but do not run them in this dispatch.
- Run exactly one final `git diff --check` restricted to the same six refactor
  paths. Do not run a full diff/status, candidate identity calculation,
  compile, EditMode, Unity, Unity MCP, Phase A/B/C/D, runtime inspection, or
  regression suite.
- Append one consolidated FIX result of at most `4 KiB` to the existing
  `RESULT.md`. Do not rewrite earlier evidence.

### Budgets And Handoff

- Active Coder time: `30 minutes` maximum.
- Mechanical command corrections: at most `2`; they do not consume semantic
  repair budget.
- This correction consumes structural repair iteration `2/2` once source bytes
  change. Any remaining same-envelope semantic failure returns to Planner for
  route reassessment; do not start a third repair.
- Independent product cause remains `1/2`; do not investigate a new cause in
  this dispatch.
- No commit, tag, push, publish, cleanup, Verifier contact, or next-role
  dispatch.
- Terminal success:
  `COMPLETE / FIX_READY_FOR_AFFECTED_EDITMODE` with changed paths, exact direct
  test names, scoped diff-check result, and deferred evidence.
- Terminal stop: one consolidated `BLOCKED` or
  `ROUTE_REASSESSMENT_REQUIRED` record at the first semantic/scope boundary.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `FIX_01 / CLOSED_ENVELOPE_DISPATCH_AUTHORIZED`.
Next notification: existing `v0.3.coder.deep` binding.
Next action: implement the two confirmed findings as one bounded correction and
return one stable result to Planner.

## Planner FIX 01 Review

- Review date: `2026-09-14`.
- Review mode: targeted read-only review of the two original P1 findings and
  their adjacent tests only.
- Coder result reviewed: `COMPLETE / FIX_READY_FOR_AFFECTED_EDITMODE`.
- Evidence reused: the recorded six-path scoped `git diff --check` exit `0`.
  No test, compile, Unity, runtime, identity, or broad Git command was run by
  Planner.

### Disposition

1. `P1 / AUTHORITY_EPOCH_REVISION_ORDERING`: `CLOSED` by source review.
   Same `SupervisorId` plus `OwnerEpoch` requires a strictly higher revision;
   a different already-authenticated authority is not ordered by the old
   authority's local revision. Direct tests cover cross-authority low-revision
   failure replacement and Ready clearing, plus same-authority stale rejection.
2. `P1 / UNINSTALLED_RETAINS_TERMINAL_FAILURE`: `PARTIALLY CLOSED`.
   The completion path now clears the in-memory envelope and persists the empty
   envelope before the Uninstalled product state, so display-only restoration
   after a reload can recover Uninstalled correctly. However, on the ordinary
   path where the migration contract is already usable, the Uninstalled worker
   result does not call `RememberLifecycleProductStatus`. Its completion block
   clears only `_cachedTerminalConvergenceFailure`; it does not atomically set
   `_cachedLifecycleProductStatus` to Uninstalled, set
   `_hasCachedLifecycleProductStatus`, clear the cached Supervisor observation
   as appropriate, or increment `_cachedHostStatusRevision`. An already-open
   Manager accepts cache changes only when that revision advances, so it can
   continue presenting the prior `NeedsAttention` snapshot until a later
   reopen/reload or unrelated cache publication.
3. The added Uninstalled tests exercise the pure envelope resolver and then
   manually construct an Uninstalled snapshot. They do not seed the lifecycle
   cache, publish an authoritative Uninstalled completion, and verify the cache
   revision/product-status handoff consumed by Manager. The immediate user path
   therefore remains without direct coverage.

This is not a new product cause or a request for broader testing. It is the
unclosed immediate-cache half of the original Uninstalled P1. Because the
authorized structural repair budget is now `2/2`, Planner does not dispatch a
third source correction or authorize EditMode/Verifier from this result.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `ROUTE_REASSESSMENT_REQUIRED / FIX_01_INCOMPLETE`.
Next notification: user.
Next action: user decides whether to reopen the same S17 structural envelope
for one atomic lifecycle-cache publication correction, or stop/defer S17.
Human decision or authorization required: `FIX / DEFER / STOP`; affected
EditMode and Verifier routing remain not ready.

## Route Reassessment Decision - Atomic Cache Closure

- Decision date: `2026-09-14`.
- Decision owner: user.
- Decision: reopen the same S17 envelope for one and only one atomic
  lifecycle-cache publication correction.
- Accounting: structural repair remains exhausted at `2/2`. This explicit
  route-reassessment exception is `atomic cache closure 1/1`; it does not reset
  or enlarge the ordinary repair budget. Any remaining semantic issue stops
  S17 for `DEFER` or a new architectural route.

### Required Behavior

1. The authoritative Uninstalled completion must publish one coherent
   lifecycle cache revision under the existing cache authority. A subsequent
   `TryGetCachedLifecycleStatus` read must observe all of the following from
   that same publication:
   - `hasProductStatus == true`;
   - product state is `Uninstalled`;
   - terminal convergence failure is `null`;
   - no prior terminal Supervisor observation is exposed as current
     Uninstalled evidence;
   - cache revision is strictly newer than the preceding terminal-failure
     revision.
2. The empty terminal envelope must still be persisted before the Uninstalled
   product-state handoff. Reopen/domain-reload restoration must remain
   Uninstalled with no retained terminal failure.
3. An already-open cache-only Manager must be able to consume the new revision
   immediately and retain the existing Install/Uninstalled presentation. It
   must not require a window reopen, domain reload, filesystem read, runtime
   query, or unrelated cache publication.
4. Keep Lifecycle as the sole publication and ordering authority. Reuse or
   consolidate the existing cache publication path; do not add another cache,
   Manager-side exception, Snapshot-side state precedence rule, or Supervisor
   protocol behavior.
5. Preserve the closed authority-epoch behavior and every non-Uninstalled
   terminal-retention rule from FIX 01.

### Scope And Evidence

- Writable paths:
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Byte-preserved paths for this correction:
  - `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Read-only direct consumer: `AICodedbManagerWindow.TryApplyCachedLifecycleStatus`.
- Add one direct lifecycle regression that seeds a terminal cache publication,
  applies the same authoritative Uninstalled publication path used by
  reconcile completion, and proves the product status, terminal failure,
  Supervisor snapshot, and revision tuple above. Reuse the existing Manager
  presentation test; do not create another fixture family.
- L0: none applicable. Update the affected EditMode source but do not run
  compile, EditMode, or Unity in this dispatch.
- Run exactly one final six-path scoped `git diff --check`, reusing the path set
  recorded by FIX 01. Do not run full diff/status, identity calculation, other
  Git inspection, Phase A/B/C/D, runtime inspection, or regression suites.
- Append one consolidated closure result of at most `3 KiB` to `RESULT.md`.
  Preserve all prior entries.

### Stops And Handoff

- Active Coder time: `20 minutes` maximum.
- Mechanical command corrections: at most `2`; semantic/source correction:
  exactly this `1/1` closure.
- A need for another writable path, another authority, protocol change, or a
  second semantic source correction stops immediately as
  `ROUTE_REASSESSMENT_REQUIRED`.
- No Unity, Unity MCP, CUA, process/runtime/log/Provider access, commit, tag,
  push, publish, Verifier contact, or next-role dispatch.
- Terminal success: `COMPLETE / ATOMIC_CACHE_CLOSURE_READY_FOR_EDITMODE`.
- Terminal stop: one consolidated `BLOCKED` or
  `ROUTE_REASSESSMENT_REQUIRED` result; no follow-on patch.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `ATOMIC_CACHE_CLOSURE_1_OF_1 / DISPATCH_AUTHORIZED`.
Next notification: existing `v0.3.coder.deep` binding.
Next action: close the remaining immediate-cache half of the original
Uninstalled P1 and return one stable result to Planner.

## Planner Review - Atomic Cache Closure

- Review date: `2026-09-14`.
- Review mode: targeted read-only re-review of the original
  `UNINSTALLED_RETAINS_TERMINAL_FAILURE` finding and its adjacent Manager
  cache handoff only.
- Coder result reviewed: `COMPLETE / ATOMIC_CACHE_CLOSURE_READY_FOR_EDITMODE`.
- Frozen identity was carried from the prior route record; no identity
  calculation or broad Git inspection was run. Coder's recorded six-path
  `git diff --check` remains the reused evidence (`exit 0`).

### Disposition

1. `UNINSTALLED_RETAINS_TERMINAL_FAILURE`: `CLOSED` for the bounded source
   contract. The authoritative completion now publishes, under one cache lock,
   `hasProductStatus=true`, `Uninstalled`, null materializer result, null
   terminal failure, null Supervisor snapshot, and one strictly newer cache
   revision. It then clears the persisted envelope before persisting the
   Uninstalled product state.
2. The unchanged Manager consumer accepts a cache publication only when its
   revision advances and projects the published product status without a live
   read. The new direct regression seeds the prior terminal tuple, applies the
   same publication helper, and verifies the complete tuple plus exactly one
   revision increment. The earlier authority-epoch replacement/Ready-clearing
   coverage remains intact.
3. No new blocker or follow-up finding was identified within the authorized
   review boundary. Persisted-state I/O ordering beyond the specified
   clear-before-state contract, concurrent domain reload timing, and real
   Manager/EditMode behavior remain evidence boundaries rather than inferred
   passes.

### Next Gate

- Current task status: `EDITMODE_AUTHORIZATION_READY`.
- No source or test file was modified by Planner in this review.
- Compile, C# L1, EditMode, UnityValidationProject, Unity MCP, runtime,
  Verifier, commit, push, and publication remain `NOT RUN / DEFERRED`.
- Next notification: user.
- Next action: user decides whether to authorize the named affected EditMode
  tests for S17; do not route Verifier or perform a commit before that gate.

## Human Compile Gate - Missing Overload Closure

- Evidence date: `2026-09-14`.
- Evidence source: human-opened `<repository-root>/UnityValidationProject`;
  screenshot artifact
  `codex-clipboard-bf6c81db-5c08-4ea1-96e6-6edb1c9d7f41.png`.
- Exact compiler result:
  `Editor/AICodedbManagerWindow.cs(320,45): error CS1501: No overload for method
  'TryGetPersistedProductState' takes 3 arguments`.
- Classification: `BLOCKER / AFFECTED_CSHARP_COMPILE_FAILED`.
- Confirmed cause: Manager's terminal-envelope restoration calls
  `TryGetPersistedProductState(string, out AICodedbProductState, out
  AICodedbTerminalConvergenceFailure)`, while Lifecycle currently exposes the
  two-argument display helper and the five-argument published-identity helper,
  but omitted the matching three-argument forwarding overload.
- Human precondition: `UnityValidationProject` was closed before dispatch.

### Authorized Compile Closure

1. Continue the same S17 task and preserved uncommitted snapshot. This is a
   compile integration correction for the already accepted terminal-envelope
   API, not a new architecture task or another product-cause investigation.
2. Add exactly the missing internal overload in
   `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`:
   - inputs: `string projectRoot`, `out AICodedbProductState state`, and
     `out AICodedbTerminalConvergenceFailure terminalFailure`;
   - behavior: forward to the existing five-argument overload using the
     lifecycle-published `_projectRoot` and `_projectIdentity`, matching the
     existing two-argument overload's cache-only identity boundary;
   - do not derive/hash project identity, read files, or add another cache or
     authority.
3. Preserve `AICodedbManagerWindow.cs` byte-for-byte. Its existing call is the
   compile contract. Preserve all tests and every other source path
   byte-for-byte; no new test is required for an overload whose missing symbol
   is directly covered by the human compile gate and whose forwarded behavior
   is already covered through the five-argument helper.
4. Writable source path:
   `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` only. `RESULT.md` may
   receive one bounded evidence append; `ROUTE-REASSESSMENT.md` is input only.
5. Run one `git diff --check` restricted to the single writable source path.
   Do not run compile, EditMode, Unity, Unity MCP, L0, runtime inspection,
   identity calculation, full diff/status, or any broader test.
6. Append at most `2 KiB` to `RESULT.md`, including the exact signature added,
   scoped diff-check result, and explicit deferred human recompile.

### Budget And Handoff

- Human-authorized compile closure: `1/1`.
- Active Coder time: `10 minutes` maximum.
- Mechanical command corrections: at most `2`; semantic alternatives or a
  need for another writable path stop as `ROUTE_REASSESSMENT_REQUIRED`.
- Structural repair accounting remains `2/2`; atomic cache closure remains
  completed at `1/1`.
- No commit, tag, push, publish, Verifier contact, or next-role dispatch.
- Terminal success: `COMPLETE / READY_FOR_HUMAN_RECOMPILE`.
- Terminal stop: one `BLOCKED` or `ROUTE_REASSESSMENT_REQUIRED` result; do not
  attempt an alternative interface design.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `COMPILE_CLOSURE_1_OF_1 / DISPATCH_AUTHORIZED`.
Next notification: existing `v0.3.coder.deep` binding.
Next action: add the exact forwarding overload and return the stable snapshot
to Planner for human Unity recompilation.

## Planner Review - Human Compile Closure

- Review date: `2026-09-14`.
- Result: `PASS / READY_FOR_HUMAN_RECOMPILE`.
- The exact three-argument overload is present and delegates directly to the
  existing five-argument implementation with lifecycle-published
  `_projectRoot` and `_projectIdentity`. It introduces no identity derivation,
  I/O, cache, or authority behavior.
- Coder's recorded single-path `git diff --check` exit `0` is reused. Planner
  did not run compile, tests, Unity, Git diff, or identity commands.
- No new finding was identified in this compile-closure boundary.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `HUMAN_RECOMPILE_REQUIRED`.
Next notification: user.
Next action: human opens `<repository-root>/UnityValidationProject`, waits for
compilation to finish, and reports the Console compile result. Do not begin
affected EditMode or Verifier review until this compile gate passes.

## Human Recompile Result

- Evidence date: `2026-09-14`.
- Evidence source: human-opened `<repository-root>/UnityValidationProject`;
  screenshot artifact
  `codex-clipboard-02637d07-b698-4d50-aa01-f739b39aa243.png`.
- Compiler errors: none visible. The prior `CS1501` is closed.
- Compiler warnings: one visible `CS0414` at
  `Editor/AICodedbManagerWindow.cs(119,21)` because
  `_transientStatusRefreshAttempts` is assigned but never read.
- Classification: `FOLLOW-UP / NON_BLOCKING_DEAD_RETRY_COUNTER`.
  The current Manager path repeatedly consumes lifecycle cache after a bounded
  delay and does not use this counter as an admission or safety condition.
  `MaximumTransientStatusRetries`, the field, and its reset assignments are
  adjacent obsolete bookkeeping. Removing them is a no-behavior cleanup to be
  folded into a later code-freeze cleanup, not a separate S17 repair.
- The visible `CODEDB_S12_EVIDENCE` and unauthorized-device messages are log
  entries, not C# compiler errors. They are outside this compile-warning
  disposition.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `AFFECTED_EDITMODE_AUTHORIZATION_READY`.
Next notification: user.
Next action: user decides whether to authorize the named affected EditMode
tests while the validation project remains human-opened. The `CS0414` warning
does not block that gate; Verifier and commit remain deferred.

## Affected EditMode Authorization

- Authorization date: `2026-09-14`.
- Decision owner: user.
- Human precondition: `<repository-root>/UnityValidationProject` is open,
  compilation completed with zero visible errors, and the one visible `CS0414`
  warning is an accepted non-blocking follow-up.
- Mode: `EVIDENCE_ONLY / VISIBLE_HUMAN_OPENED_UNITY`.
- Source and test writes: forbidden. This dispatch validates the current
  snapshot and cannot repair a failure.

### Exact Test Set

Run only these seven EditMode tests:

1. `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.TerminalConvergenceFailure_PreservesAuthenticatedLayersAndRoundTrips`
2. `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.TerminalConvergenceFailure_RejectsTransientMissingAndOlderEvidence`
3. `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.TerminalConvergenceFailure_ClearsOnlyForNewerAuthenticatedReadyEvidence`
4. `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.TerminalConvergenceFailure_AuthoritativeUninstalledClearsEnvelope`
5. `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.AuthoritativeUninstalledCompletion_PublishesCoherentCacheRevision`
6. `Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.CachedUninstalledSnapshot_PreservesInstallStateWithoutLiveScan`
7. `Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.CachedNeedsAttentionSnapshotRetainsTerminalEvidenceAndDoesNotClaimChecking`

### Execution Envelope

- Use only the visible Unity Test Runner in the already-open validation
  project. Do not launch, restart, close, or terminate Unity.
- The seven exact tests form one continuous scenario. Up to four UI selection
  batches are permitted solely because they span two classes and distinct name
  filters; this is not permission to run either whole class, the package test
  assembly, all EditMode tests, or any PlayMode test.
- Before each run, verify the visible selection contains only authorized test
  names. If an exact selection cannot be formed, stop as
  `BLOCKED / EXACT_TEST_SELECTION_UNAVAILABLE` rather than broadening it.
- Semantic retry: `0`. On the first test failure, record the exact test name
  and visible failure text, stop the remaining scenario, and return
  `BLOCKED / AFFECTED_EDITMODE_FAILED`. Do not diagnose or modify code.
- UI/mechanical corrections before a semantic test launch: at most `2`. They
  cannot authorize a test rerun or a broader selection.
- Active time: `15 minutes`; maximum wait for any one launched batch:
  `180 seconds`. A timeout stops the scenario without terminating Unity.
- Do not open or operate CodeDB Manager, enter Play Mode, trigger compilation,
  use Unity MCP, BatchMode, CLI test launch, alternate endpoints, process/log/
  runtime inspection, or device tooling.
- Do not run Git commands, L0, compile commands, Phase A/B/C/D runtime
  scenarios, consumer/release tests, or full regression.
- Append one sanitized evidence record of at most `3 KiB` to `RESULT.md` with
  exact tests attempted, passed/failed/skipped counts, batch count, elapsed
  time when available, and the visible terminal result. No other file may be
  changed.
- No commit, tag, push, publish, Verifier contact, or next-role dispatch.

### Handoff

- Success: `COMPLETE / AFFECTED_EDITMODE_PASS` only if all seven exact tests
  pass and no additional test was run.
- Stop: `BLOCKED` with the first boundary or failure; no retry or repair.
- Next notification: `UnityCodeDB v0.3 Planner`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `AFFECTED_EDITMODE / DISPATCH_AUTHORIZED`.
Next action: execute the seven-test visible EditMode scenario once and return
the stable evidence to Planner.

## Affected EditMode Tooling Disposition And Human Fallback

- Disposition date: `2026-09-14`.
- Coder result: `BLOCKED / EXACT_TEST_SELECTION_UNAVAILABLE` before any test
  launch.
- Exact tooling error on initial UI initialization and one recovery attempt:
  `failed to write kernel assets: system cannot find the specified path
  (os error 3)`.
- Product-test accounting: attempted `0`, passed `0`, failed `0`, skipped `7`,
  UI batches `0/4`, semantic retry `0`. This is a local CUA/tooling failure,
  not an EditMode or product failure; the authorized seven-test semantic
  scenario remains unused.
- Planner decision: do not retry CUA, create another Coder task, use CLI,
  BatchMode, Unity MCP, or broaden the selection. Use one human Test Runner
  fallback under the existing seven-test authorization.

### Human Test Runner Steps

In the already-open `<repository-root>/UnityValidationProject`, open
`Window > General > Test Runner`, select `EditMode`, and use `Run Selected`
only. Do not use `Run All`.

Run these four selection batches in order:

1. Search `TerminalConvergenceFailure_`. Confirm exactly these four methods are
   selected, then use `Run Selected`:
   - `TerminalConvergenceFailure_PreservesAuthenticatedLayersAndRoundTrips`
   - `TerminalConvergenceFailure_RejectsTransientMissingAndOlderEvidence`
   - `TerminalConvergenceFailure_ClearsOnlyForNewerAuthenticatedReadyEvidence`
   - `TerminalConvergenceFailure_AuthoritativeUninstalledClearsEnvelope`
2. Search and run only
   `AuthoritativeUninstalledCompletion_PublishesCoherentCacheRevision`.
3. Search and run only
   `CachedUninstalledSnapshot_PreservesInstallStateWithoutLiveScan`.
4. Search and run only
   `CachedNeedsAttentionSnapshotRetainsTerminalEvidenceAndDoesNotClaimChecking`.

Before every launch, confirm no other test is selected. On the first failure,
stop without rerun and provide a screenshot with the exact failure text. If
all four batches pass, provide the visible pass result/counts. Do not operate
CodeDB Manager, enter Play Mode, run other tests, or close/restart Unity as
part of this scenario.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `HUMAN_AFFECTED_EDITMODE_REQUIRED`.
Next notification: user.
Next action: human executes the four exact Test Runner selection batches and
returns the visible terminal evidence to Planner.

## Planner Disposition - Human Affected EditMode

- Evidence date: `2026-09-14`.
- Result: `PASS` based on the user's report that all seven exact tests listed
  in the human fallback passed.
- Counts: attempted `7`, passed `7`, failed `0`, skipped `0`.
- Evidence boundary: human attestation only; screenshot, per-test duration,
  total duration, and independent UI observation are unavailable and are not
  inferred.
- The prior CUA initialization failure remains a non-product tooling record.
  It consumed no semantic test attempt and does not weaken the human result.
- The two original terminal-envelope P1 findings, the atomic Uninstalled cache
  closure, the missing-overload compile blocker, and their named affected
  EditMode tests are now closed within the frozen S17 scope. No new finding was
  reported.
- Full EditMode, PlayMode, Phase B runtime convergence, consumer/release
  acceptance, Unity MCP, and publication remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`.
Current status: `VERIFIER_ROUTING_READY`.
Next notification: user.
Next action: user decides whether to route the unchanged S17 snapshot to
Verifier for targeted read-only acceptance. Verifier should reuse the human
7/7 EditMode evidence and must not rerun tests.

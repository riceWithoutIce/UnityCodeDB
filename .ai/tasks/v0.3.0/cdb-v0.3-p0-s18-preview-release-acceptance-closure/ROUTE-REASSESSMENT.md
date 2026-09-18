# Route Reassessment: cdb-v0.3-p0-s18-preview-release-acceptance-closure

## Trigger

The S18 local handoff path reached the Workflow v2 structural stop boundary.
The first bounded repair added the missing trusted-previous `CURRENT` marker.
The second bounded repair separated owner-free legacy retirement from the
activation path, but its single focused `UpgradeOnly` run returned:

`v0.2.4 owner-free instance Upgrade command-result cleanup state mismatch.
Expected 'COMPLETE', got 'PENDING'.`

At this point S18 has used two local repair iterations and two independent
product causes. The result is not Phase A readiness and must not be routed to
Verifier or retried through Unity.

## Route Decision

- Decision: `REFACTOR / CLEANUP_CONTRACT_SEPARATION`
- Decision owner: `UnityCodeDB v0.3 Planner / User`
- Decision date: `2026-09-15`
- Keep the existing S18 Task ID and its continuous outcome. Do not create an
  S18a/S18b micro-task for the command, assertion, or pointer symptom.
- Preserve the current uncommitted snapshot as the diagnostic baseline. Do not
  claim `HUMAN_PHASE_A_RETRY_READY`, Phase A PASS, publication readiness, or
  Verifier readiness from the failed evidence.

## Contract To Restore

1. A successful activation transaction owns candidate publication and selection
   (`current`/last-known-good) and may publish a coherent `UPGRADED` result
   before old closure cleanup is finished.
2. Retired legacy cleanup is asynchronous. `CLEANUP_STATE=PENDING` is a legal
   successful activation result when the new candidate is selected and its
   safety/ownership checks pass; `COMPLETE` is the opportunistic fast path.
3. Cleanup must never gate, undo, or relabel a successfully selected candidate
   as an activation failure. Its next action must state that authenticated
   holders will be rechecked and cleanup retried by the existing maintenance
   authority.
4. Legacy pointer switching belongs to the activation/selection transaction;
   removal of old files and markers belongs to the cleanup authority. The two
   responsibilities must not be repaired by forcing one synchronous result
   value.
5. Live, invalid, ambiguous, or unprovable flat/generation/Editor/Coordinator
   ownership remains preserved and fail-closed. No external or unrelated
   process may be stopped, and no evidence may be treated as missing.
6. The trusted-previous `CURRENT` marker correction remains part of the same
   contract and must continue to identify `INSTANCE=TRUSTED_PREVIOUS` and
   `PRODUCT_STATE=NEEDS_ATTENTION` before handoff.
7. Direct evidence must cover both legal cleanup outcomes: owner-free
   convergence may return `COMPLETE`, while a retained holder/unknown closure
   may return `PENDING`; in either case the selected candidate and safety
   invariants are asserted. A later existing maintenance/convergence pass must
   be the authority for eventual `COMPLETE`.

## Authorized Continuation Envelope

The user authorizes one coherent same-S18 structural continuation under the
existing conditional allowlist:

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- the S18 `RESULT.md` and this route record only for evidence/hand-off text

The materializer path may be edited only if direct symbol tracing proves it is
part of the same cleanup-result contract. No Package metadata, Provider
contract, global configuration, `UnityValidationProject`, immutable `poc.35`,
historical generation, or unrelated source/test path may change.

Fresh route evidence is deliberately compact:

- one bounded static/source ownership batch;
- one consolidated focused `UpgradeOnly` L0 covering activation selection,
  legal `PENDING`/`COMPLETE` cleanup semantics, and the nearest holder-retain
  regression;
- at most one same-cause corrected semantic attempt if the first run exposes a
  mechanical or directly coupled assertion defect;
- one final scoped `git diff --check`.

No third product repair, new independent cause, full regression, Unity,
Unity MCP/CUA, BatchMode, process/runtime probe, publication, commit, push, or
Verifier routing is authorized by this route. If the contract requires a new
authority, a changed immutable generation, a broader allowlist, or another
external side effect, stop and return `ROUTE_REASSESSMENT_REQUIRED` again.

## Required Handoff

If the consolidated L0 proves the refactored contract, return
`HUMAN_PHASE_A_RETRY_READY` and wait for the human to repeat the one local
Phase A scenario. If it does not, record the exact first failure and preserve
the snapshot; do not reinterpret `PENDING` as failure without the declared
contract evidence.

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`
Current status: `ROUTE_REASSESSMENT_REQUIRED / REFACTOR_AUTHORIZED`
Next notification: `v0.3.coder.deep`
Next action: execute this one structural continuation and append a consolidated
result to `RESULT.md`; do not contact Verifier.

## Availability Authority Decision

The cleanup-contract continuation reached a focused assertion that corrupted
the selected instance's `logs/mcp-availability.json` and then required the
product result to become `NEEDS_ATTENTION`. A bounded Planner trace classified
that expectation as inconsistent with the accepted S14-S18 ownership model:

- `Get-InstanceCurrentReadiness` keeps MCP registration ownership separate
  from operational availability and does not consume the instance availability
  document as final product-state authority.
- A valid, fresh, identity-bound Supervisor operational observation with state
  `core_ready` is the only evidence in this path that may produce
  `MCP_AVAILABLE=CURRENT` and `PRODUCT_STATE=READY`.
- Missing, malformed, stale, mismatched, starting, stopping, or degraded
  Supervisor evidence remains fail-closed or transitional through the existing
  validation path.
- The instance availability document remains candidate/probe evidence. Its
  isolated corruption must not independently downgrade an authenticated
  Supervisor observation or make PowerShell recreate Supervisor readiness.

The corrected focused run therefore exposed a fixture-contract mismatch, not
evidence for a third production authority repair.

### Route Decision

- Decision: `FIXTURE_CONTRACT_CORRECTION / SUPERVISOR_AUTHORITY_PRESERVATION`
- Keep the existing S18 Task ID and the current uncommitted cleanup-contract
  snapshot. Do not create another task or checkpoint card.
- Production authority and cleanup behavior are frozen for this continuation.
  `codedb-instance-engine.ps1` and
  `materialize-codedb-host-payload.ps1` must remain byte-unchanged.
- Only the directly conflicting assertions and fixture setup in
  `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` may be
  corrected, plus append-only evidence in S18 `RESULT.md`.
- The corrected fixture must explicitly establish a valid Supervisor
  observation bound to the selected candidate. With that observation present,
  corrupting the lower-level availability document must retain
  `CONFIGURED=CURRENT`, `MCP_AVAILABLE=CURRENT`, and `PRODUCT_STATE=READY`.
- The fixture must not depend on an ambient inherited readiness environment.
  It must restore the prior environment value after the scenario.
- Existing direct coverage that absent, malformed, stale, mismatched, or
  degraded Supervisor evidence cannot produce Ready must remain intact. It need
  not be rerun as a separate unchanged suite.
- The subsequent Probe recovery must retain the selected immutable instance
  and restore valid candidate/probe evidence without changing the authority
  boundary.

### Renewed Bounded Evidence

This is one coherent same-S18 correction, not a new product repair:

- one bounded static/source batch covering explicit Supervisor observation
  setup, authority-result assertions, environment restoration, and unchanged
  production files;
- one consolidated focused `UpgradeOnly` L0;
- at most one same-cause corrected attempt for a mechanical fixture defect;
- one final three-path scoped `git diff --check`.

No production repair, new authority, extra focused suite, full regression,
Unity, Unity MCP/CUA, BatchMode, runtime/process probe, immutable-generation or
Package/Provider change, publication, commit, push, or Verifier routing is
authorized. If the fixture cannot express the established Supervisor contract
without a production change or broader path, stop with
`ROUTE_REASSESSMENT_REQUIRED`.

If the consolidated `UpgradeOnly` L0 passes, return
`HUMAN_PHASE_A_RETRY_READY` to Planner and wait. Do not contact Verifier or
start Unity.

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`
Current status: `ROUTE_REASSESSMENT_REQUIRED / FIXTURE_CORRECTION_AUTHORIZED`
Next notification: `v0.3.coder.deep`
Next action: correct the one availability-authority fixture contract on the
same frozen snapshot and append one consolidated outcome to `RESULT.md`.

## Lease-holder Harness Evidence Unblock

The availability-authority continuation reached the existing active-holder
fixture, but `Start-LegacyHostUseLeaseProcess` failed before any holder, lease,
cleanup, or production behavior was exercised. Planner's bounded read-only
diagnosis confirmed that command resolution returned more than one Node
application and the fixture stored all resolved paths in `$nodePath`.
Assigning that array to `ProcessStartInfo.FileName` formed one invalid launch
target. Changing the holder working directory could not correct this failure.

This is classified as `EVIDENCE_HARNESS_FAILURE`, not a product finding or a
new architecture route. The user authorizes one independent evidence-unblock
attempt inside the same S18 task:

- Keep branch `codex/v0.3.0-legacy-workflow`, frozen HEAD
  `eb21a7a5d28548e0369db35ee0cac1c0d626183c`, and the current uncommitted S18
  snapshot.
- Only `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  may change, plus append-only evidence in S18 `RESULT.md`.
- Resolve one scalar Node executable deterministically from normal command
  precedence, validate that the selected value is a single existing file, and
  do not hard-code or record a machine-specific absolute path.
- Do not change holder lease semantics, lifetime, shutdown, active-owner
  assertions, availability-authority assertions, or production behavior.
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` must remain at
  `725902bdfdbeaaa5198b1268b7339b1823eea404` and
  `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` must remain at
  `89410db933769ccfe1f000d01da2b77288c30ecf`.

Evidence is limited to one bounded static/source check, one consolidated
focused `-UpgradeOnly` L0 invocation with no retry, and one final three-path
scoped `git diff --check`. Do not run another suite, full regression, Unity,
Unity MCP/CUA, BatchMode, C# L1/EditMode, protected runtime/process probes, or
publication actions. Do not contact Verifier and do not commit or push.

If the focused L0 passes, return `HUMAN_PHASE_A_RETRY_READY` to Planner. If it
fails, record the exact first failure and stop without another correction or
route expansion.

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`
Current status: `BLOCKED / LEASE_HOLDER_HARNESS_FIX_AUTHORIZED`
Next notification: `v0.3.coder.deep`
Next action: perform the single test-only harness repair and consolidated
evidence attempt, append the terminal result, and return to Planner.

## Fresh-install-only Owner Identity v2 Redesign

Decision date: `2026-09-15`.

Current route:
`REDESIGN / FRESH_INSTALL_ONLY_OWNER_IDENTITY_V2 / SUCCESSOR_GENERATION_REQUIRED`.

This section is the active route overlay for S18. It supersedes the execution
and handoff directions above, but it does not rewrite or invalidate their
historical evidence. In particular, the failed human Phase A result remains
`CONTROL_CONTRACT_IDENTITY_ADMISSION`, and no current release PASS is implied.

### Trigger And Product Boundary

The Phase A failure exposed a cross-language Owner Identity boundary rather
than a reason to add another discriminator to the legacy contract. The
Package currently accepts a live process only when persisted owner evidence
can be compared across Node, PowerShell, and C#. The existing v1 evidence can
encode process-start identity differently depending on its Windows capture
path, so a live process may be represented consistently inside one producer
while remaining unverifiable by another consumer.

The product will not preserve or migrate Owner Identity v1. v0.3 will use one
new Owner Identity v2 contract and require a fresh project-local integration.
There is no v1 Supervisor handoff, transparent v1-to-v2 state conversion,
WMIC/CIM-format inference, or relaxed live-owner comparison. The old
`0.3.0-preview.1` / `poc.35` snapshot remains historical evidence and must not
be rewritten to carry this contract.

### Compatibility Classification

Classification remains explicit and fail-closed:

- A recognized v1 state/lock pair is `REINSTALL_REQUIRED`. It is not
  `CURRENT`, and it cannot authorize handoff, signaling, deletion, or process
  termination.
- No current v2 state/lock and no recognized legacy evidence is `MISSING`.
- A partial pair, malformed document, conflicting pair, unknown contract, or
  unverifiable owner is `INVALID_OR_AMBIGUOUS`. The product must not guess a
  migration or owner.
- `CURRENT` requires a complete v2 state/lock pair, the same canonical Owner
  Identity v2 in both records, an authenticated pipe bound to that owner and
  epoch, and an operational observation whose terminal state is `core_ready`.
- A live PID, matching path, parseable document, or reachable pipe in
  isolation is never sufficient for `CURRENT`.

Missing prerequisite remains a distinct higher-priority product condition. It
must not be converted into Reinstall and must not mutate project integration.

### Owner Identity v2 Vertical Contract

The successor implementation must freeze one schema and use it end to end in
the trusted Package manifest, Node Supervisor, PowerShell materializer, C#
classifier/lifecycle, Manager cache, and their direct tests. At minimum, the
same identity binds:

- explicit Owner Identity contract version `2`;
- project and control-contract identity;
- selected instance, generation, activation epoch, and owner epoch;
- PID plus one canonical process-start identity;
- canonical executable identity and reviewed command identity;
- state/lock publication phase; and
- authenticated pipe identity and readiness observation.

On Windows, process-start identity is one decimal UTC `DateTime` ticks value
normalized to the existing 10-tick (microsecond) comparison boundary. DMTF
digits, locale text, raw WMIC values, and capture-provider-specific shapes are
not valid persisted v2 identities. A producer that cannot obtain the canonical
form fails closed instead of publishing another representation. Capture may
use a supported OS API internally, but consumers never branch on whether WMIC
or CIM supplied the value.

The acceptance fixture must cross the actual language boundary: Node-produced
v2 state/lock is consumed by the C# classifier, and malformed, v1, mismatched,
stale, unauthenticated, and non-`core_ready` variants are rejected. A
producer-only round trip is not sufficient evidence.

### Explicit Removal And Fresh Installation

The Manager may expose `Remove CodeDB Integration` as the bounded recovery
action before the user removes or reinstalls the Package through Unity Package
Manager. It is not an unconditional cleanup operation:

- it removes only independently proven Package-owned project-local control,
  runtime, and generated configuration for the admitted integration;
- it preserves user `Assets`, project source, indexes, and other user data;
- it is blocked while an owner is live, unknown, ambiguous, or cannot be
  authenticated as safe to leave untouched;
- it never kills a process, clears an unverifiable lease, or deletes ambiguous
  evidence; and
- Package code never tries to delete itself. Package removal remains a Unity
  Package Manager action owned by the user.

The action must present a terminal result and be idempotent. A failed or
blocked removal leaves the evidence intact and tells the user why a fresh
installation cannot proceed safely.

### Successor Release Identity

The current repository contract is `0.3.0-preview.1 / poc.35`. Because the v2
contract changes immutable payload bytes and release semantics, the successor
target is frozen as `0.3.0-preview.2 / poc.36`:

- every `poc.35` and earlier byte remains immutable;
- `poc.36` receives its own generation manifest and complete hash closure;
- Package metadata, payload manifest, current pointer, Provider compatibility,
  and generated contract fixtures must agree on the successor identities; and
- publication, tag, push, and release promotion remain separate human
  decisions after local and external acceptance.

### Continuous S18 Boundary And Gates

This remains one continuous S18 redesign and release-closure task. Do not
create S18a/S18b micro-tasks for individual fields, capture APIs, fixtures, or
Manager labels. Before source implementation, Planner must freeze one exact
allowlist covering the vertical v2 contract, successor `poc.36` closure,
explicit removal UI/operation, and direct cross-language tests. Coder and
Verifier remain bounded by that allowlist and the Workflow v2 route budget.

The next implementation gate must prove, in order:

1. static schema/authority ownership and exact successor identity agreement;
2. direct cross-language v2 owner admission and rejection fixtures;
3. bounded fresh-install, blocked-removal, and idempotent-removal L0 evidence;
4. immutable `poc.36` and Package-boundary closure; and
5. only after those pass, a newly authorized human Unity Phase A scenario.

No legacy handoff matrix, WMIC/CIM discriminator probe, Unity retry, Unity MCP,
publication, commit, push, or Verifier routing is authorized by this document
update. A required destructive cleanup, process termination, user-data
deletion, compatibility exception, or edit outside the later frozen allowlist
returns `ROUTE_REASSESSMENT_REQUIRED`.

### Current Handoff

- Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`
- Current status:
  `REDESIGN / FRESH_INSTALL_ONLY_OWNER_IDENTITY_V2 / SUCCESSOR_GENERATION_REQUIRED`
- Next notification: `UnityCodeDB v0.3 Planner`
- Next action: freeze one continuous S18 implementation allowlist and evidence
  budget for `0.3.0-preview.2 / poc.36`, then request human authorization
  before routing it to `v0.3.coder.deep`.
- Human authorization required: source/test implementation, any Unity phase,
  Verifier routing, commit, tag, push, publication, or promotion.

## Frozen S18 Implementation Envelope - Owner Identity v2

Freeze date: `2026-09-15`. Planning baseline: branch
`codex/v0.3.0-legacy-workflow`, HEAD
`e93a204384f4b9a5915b579c7133eed3b9727265`. This is a planning freeze,
not a source snapshot identity or an authorization to edit. The current
`0.3.0-preview.1 / poc.35` candidate and the failed human Phase A evidence
remain historical. The successor target is `0.3.0-preview.2 / poc.36`.

### One Observable Outcome

On a fresh project-local integration, Node publishes one Owner Identity v2
contract that PowerShell and C# consume without an alternative identity
authority; the selected owner reaches authenticated `core_ready`. A recognized
v1 pair never becomes current or authorizes a handoff. A user can explicitly
remove only proven Package-owned integration state when all ownership gates
admit removal, then reinstall through the normal Package Manager and fresh
installation flow. The successor Package/payload/generation closure must bind
the same contract without modifying `poc.35`.

Freeze the v2 wire shape in one place before creating any v2 state: declare
`owner_identity_version = 2` separately from the payload sequence, and bump
the trusted `v0.3-control` contract version from `1` to `2` to derive a
disjoint Supervisor namespace. Keep the control-contract identity schema
version `1` unless its own structure changes; compute its canonical SHA-256
from the declared id/version/schema, never copy the v1 digest. Exact state,
lock, pipe, and readiness fields must be mutually bound, not inferred from a
generation id or the installed Unity Editor version. No independent current
policy may be added in Manager, PowerShell, or wrapper.

### Exact Editable Paths

Only direct v2 identity, cached presentation, confirmed removal, and
successor-closure edits are permitted in these existing paths:

```text
com.rice.ai-codedb/Editor/AICodedbPackageRuntimeContract.cs
com.rice.ai-codedb/Editor/AICodedbControlContract.cs
com.rice.ai-codedb/Editor/AICodedbSupervisorLauncher.cs
com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs
com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs
com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs
com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs
com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs
com.rice.ai-codedb/Editor/AICodedbActions.cs
com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1
com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1
com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1
com.rice.ai-codedb/package.json
com.rice.ai-codedb/Payload~/payload-manifest.json
com.rice.ai-codedb/Payload~/host-current.json
com.rice.ai-codedb/Payload~/Generations/poc.36/** (new files only)
```

The `poc.36/**` exception authorizes only the successor's immutable closure:
copy the reviewed `poc.35` structure as needed, update exact successor-owned
identities and directly changed runtime bytes, and build one new generation
manifest/hash closure. It is not a wildcard for older generations or other
payload paths. These S18 `TASK.md`, `ROUTE-REASSESSMENT.md`, and `RESULT.md`
are writable only for append-only authorization, evidence, and handoff text.
No new C# file, automatic `.meta` churn, unrelated test fixture, or other
new source path is preauthorized. If a directly coupled file outside this
list is necessary, stop and request a single allowlist reassessment before
editing it; do not create a symptom-level task card.

### Protected State And Authority

- `com.rice.ai-codedb/Payload~/Generations/poc.35/**` and all earlier
  generations are read-only; historical transition identities remain intact.
- The flat Provider contract, installed machine Provider, external manifests,
  and global Codex configuration are not editable. The reviewed schema-2
  Provider artifact remains the prerequisite authority; do not infer
  compatibility from the new Package version or widen a Provider contract
  without a separately reviewed artifact/allowlist decision.
- `UnityValidationProject/**`, user Assets/indexes, external MCP clients,
  unrelated TOML fields, and project runtime/control evidence remain
  protected during implementation. No test may use this live project as a
  disposable removal fixture.
- The explicit remove path must revalidate the exact Package-owned scope,
  owner/lease evidence, reparse and path boundaries before any mutation.
  Live, unknown, or ambiguous ownership blocks the command without deletion
  or process termination. Removing the Unity Package remains a human Package
  Manager action, not a PowerShell/C# self-delete.
- Unchanged query-first Supervisor scheduling and cache-only Manager behavior
  remain direct neighbor contracts; do not add synchronous Manager I/O or a
  second maintenance queue to implement removal.

### Focused Evidence Envelope

One consolidated Coder result may cover the complete v2 vertical contract,
with these distinct, bounded classes in dependency order:

1. One static/source and syntax batch: owner/version authority, schema and
   exact successor metadata agreement, Node syntax, PowerShell AST parse,
   and a source-boundary check. Capture only the first actionable failure.
2. One focused Node Supervisor L0 invocation for v2 state/lock publication,
   authenticated pipe/`core_ready`, live-current, stale, v1, mismatched,
   malformed, and unknown-owner fail-closed behavior. Extend the existing
   Supervisor harness with one named v2 filter instead of running its full
   unrelated suite.
3. One focused PowerShell materializer L0 invocation covering the Node v2
   fixture's strict read/admission and one disposable fresh-install/explicit
   removal scenario. It must prove blocked live/unknown/ambiguous removal,
   only-owned deletion, user-data/lease/sentinel preservation, idempotent
   retry, and success only after exact safe ownership; use a named focused
   mode in the existing harness, not the complete materializer matrix.
4. One Package-boundary L0 invocation for `preview.2 / poc.36`, v2 namespace,
   Provider identity, immutable closure, pointer and metadata agreement.
5. One direct C# cross-language consumer scenario: C# must consume actual
   Node-produced v2 documents and reject v1/ambiguous/mismatched evidence.
   Source-only equivalence and synthetic dead PIDs cannot be reported as this
   gate PASS. If a standalone non-Unity harness cannot run the direct C#
   scenario, mark it `DEFERRED` and request a separately authorized focused
   affected EditMode check in `UnityValidationProject`; no Unity startup is
   implicit in this planning envelope.

Before handoff, run one scoped `git diff --check` and record the exact edited
paths, result, reason, next owner, and deferred classes. Coder deep has a
`60-minute` active budget, at most `2` causally distinct local repair
iterations and `2` independent product causes before route reassessment.
Each non-Unity focused scenario has one initial attempt and at most `2`
causally justified corrected semantic attempts; mechanical command
construction corrections follow Workflow v2 and never authorize a blind
rerun. Unchanged suites are reused, not repeated. Time/output budgets and
stop signals are those of `development-workflow.md`.

Fresh Unity Phase A is not authorized by this freeze. It waits for the L0
closure and the actual cross-language C# consumer gate (or separately
authorized affected EditMode). Then the human may authorize one continuous
Unity scenario on the exact successor snapshot. Full EditMode, consumer
Package-only, real Codex, publication, and release review remain independent
gates, not implications of the focused L0 result. Verifier deep performs at
most one targeted read-only RELEASE review only after stable handoff and
Planner routing; it does not rerun unchanged evidence or dispatch repair.

### Handoff After Freeze

- Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`
- Current status: `IMPLEMENTATION_ENVELOPE_FROZEN / DISPATCH_NOT_AUTHORIZED`
- Next notification: `UnityCodeDB v0.3 Planner / User`
- Next action: request one explicit authorization to route this same S18
  vertical implementation to `v0.3.coder.deep`; Coder then records a single
  bounded `RESULT.md` and returns the stable snapshot to Planner.
- Human authorization required: Coder implementation, affected C# EditMode,
  fresh Unity Phase A, Verifier review, commit, tag, push, publication, and
  promotion are all separate decisions.

## Owner Identity v2 FIX 01 Authorization - 2026-09-16

The human approved `FIX` after Planner's targeted review of the completed
implementation handoff. This authorizes one bounded continuation of the same
S18 vertical implementation, not a new route, task card, or release decision.
The preceding implementation failure remains valid historical evidence.

### Baseline And Finding

- Branch: `codex/v0.3.0-legacy-workflow`.
- HEAD: `e93a204384f4b9a5915b579c7133eed3b9727265`.
- Coder-recorded 42-path implementation identity:
  `174bfc6519eca196809eff35bbe1705cc24da455`.
- Candidate: `0.3.0-preview.2 / poc.36`, fresh-install-only Owner Identity v2.
- Original failure: `verifyOwnerEvidenceAndSingleStarter` rejected the second
  starter with `Supervisor pipe responded with a different owner identity.`

Planner's source review found a possible same-owner snapshot inconsistency:
`inspectExistingSupervisor` reads durable state before requesting pipe status,
while `authenticatedStatusMatches` also requires equality of mutable readiness
observation IDs and revisions. `publishOperationalReadiness` advances those
values during normal refresh. The reported error therefore does not, by
itself, prove an owner conflict. This is a candidate cause to classify, not a
permission to ignore a real mismatch or an assertion that the cause is proven.

### Repair And Acceptance Boundary

1. Classify the failed comparison through targeted source reads and, if
   necessary, sanitized diagnostics in the existing disposable Node fixture.
   Report stable-owner comparison and readiness-snapshot comparison separately;
   do not emit tokens, raw runtime documents, machine paths, PID values or argv.
2. Repair the confirmed cause within the existing `Exact Editable Paths`.
   Expected repair paths are `Tools~/codedb-project-supervisor.mjs` and
   `Tests~/test-codedb-project-supervisor.mjs` beneath the Package. Any other
   already-allowlisted edit must be proven directly coupled to this finding;
   it is not authority for unrelated refactoring or a new product policy.
3. Preserve state/lock equality, live process and reviewed invocation evidence,
   owner epoch, activation/selection, project/control/runtime identity,
   authenticated pipe, readiness schema/binding/freshness and fail-closed
   negative cases. Separate mutable observation consistency from stable owner
   identity only through a coherent authenticated snapshot rule.
4. Do not make the test pass by serializing the concurrent starters, removing
   authentication or readiness validation, suppressing refresh, fixing IDs to
   constants, or treating an arbitrary newer observation as trusted.
5. Nearest evidence must show that the same owner remains admissible across
   the relevant normal refresh window, concurrent starters still yield exactly
   one `STARTED`, and genuine owner/selection mismatch stays fail-closed. Keep
   the existing named v2 filter's adjacent negative coverage intact.
6. Preserve every `poc.35` and earlier byte, unrelated implementation changes,
   `UnityValidationProject`, user data, leases/sentinels and Provider/global
   configuration. Do not run protected project/process probes. Use only the
   existing disposable fixture's process lifecycle and cleanup boundaries;
   never discover, signal or stop external holders as part of the repair.

### Continuous Evidence And Budget

This continuation has one `60-minute` active envelope. Retain all previous
attempt and cause records; do not reset their counters or invent unavailable
timing evidence. FIX 01 is one local repair iteration for the original Node
cause, not authorization for another independent product repair.

- One targeted static/source/syntax batch for the repair and nearest tests;
  reuse the unchanged previously passing static metadata/closure evidence.
- Run the existing `owner-identity-v2` Node filter once after classification
  and repair. This consumes one of the two originally unused corrected
  semantic attempts. At most one further corrected attempt is permitted for
  that same established cause with a concrete explanation; no blind rerun.
- Only after the Node gate passes, run the still-unused focused PowerShell
  `-OwnerIdentityRemovalOnly` and Package-boundary L0 in dependency order.
  Their original bounded attempt rules remain in force; a new independent
  product failure must be reported, not repaired under this authorization.
- One final scoped `git diff --check` for this continuation's delta, and one
  final implementation identity using the same documented path/blob manifest
  scheme. Record the serialization and exact path set for later handoff.
- Direct Node-produced-v2-to-C# consumer remains `DEFERRED` unless an already
  authorized non-Unity harness can run it. This grant does not authorize a new
  harness, Unity startup, C# compile, affected EditMode or full regression.

Stop on an unclassified corrected failure, new independent product cause,
allowlist expansion, new authority, protected-state dependency or exhausted
budget. Preserve the snapshot and report the exact first failure and remaining
budgets as `BLOCKED / ROUTE_REASSESSMENT_REQUIRED`; do not add another task.

### Consolidated Handoff

Append one consolidated FIX 01 result to `RESULT.md`, including classification,
actual edits, final identity, commands/results, cause/attempt ledger, deferred
classes and next role. If all three non-Unity focused gates pass, report
`COMPLETE / FIX_01_NON_UNITY_CLOSURE_PASS / CSHARP_CONSUMER_DEFERRED` when the
C# gate is still deferred; do not claim Unity, Verifier or release readiness.

- Current status: `FIX_01_AUTHORIZED / CODER_DEEP / NON_UNITY_CONTINUATION`.
- Next notification: the existing `v0.3.coder.deep` to execute this grant.
- After completion: notify `UnityCodeDB v0.3 Planner` to review the stable
  result and seek the next separately gated C# consumer/Unity decision.
- Still prohibited: Unity/Unity MCP/CUA/BatchMode, external Provider mutation,
  protected live runtime reads, direct Verifier dispatch, commit/tag/push,
  publication and promotion.

## Owner Identity v2 Test-only Fixture Closure Authorization - 2026-09-16

The human approved a test-only closure after Planner's focused FIX 01
re-review. The original owner/readiness comparison finding is closed by the
recorded focused evidence and reviewed source; the complete Node filter is
still failing. Preserve both facts and their history. Do not create a new
task or reopen the original product repair.

### Frozen Input And Test-only Scope

- Branch: `codex/v0.3.0-legacy-workflow`.
- HEAD: `e93a204384f4b9a5915b579c7133eed3b9727265`.
- Coder-recorded 42-path identity:
  `50c3c015a7021eda1951db550aeb23e397fc4f5b`.
- Frozen production Supervisor blob:
  `2e361d3ec0bfb51dcf51c0a1cc75de5068fd5c07`.
- Input Supervisor harness blob:
  `4336234e01b226c1805f104108bc79c3c264f033`.

Only `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs` may change,
plus append-only authorization/evidence/handoff text in the three S18 records.
All other implementation, metadata and payload paths remain byte-unchanged.
This includes the FIX 01 production repair, all immutable generations,
Provider/global configuration, user data and `UnityValidationProject`.

The observed `verifyProvenStaleOwnerTakeover` fixture changed the top-level
state/lock PID and owner-evidence PID to its synthetic dead PID but left the
readiness observation bound to the original PID. Strict v2 reading therefore
correctly rejected the incoherent document before the stale-owner branch.
Correct the fixture's intended coherent identity, not the production reader.

Targeted preflight may inspect identity mutations in that scenario and its
direct v2 neighbors in the named filter. Changes are restricted to missing
fixture-field synchronization and direct consistency assertions required for
the intended scenario. Preserve deliberately malformed/mismatched evidence,
PID-reuse/live-owner fail-closed assertions, concurrent-starter behavior,
freshness/ordering rules, quarantine assertions and fixture cleanup semantics.
Do not convert negative scenarios into positive fixtures or accept an earlier,
unrelated rejection as proof that the intended stale/PID-reuse path ran.

### One Continuous Evidence Closure

This is one bounded test-only continuation with at most `30 minutes` of
active work. Preserve all existing cause/attempt history; the remaining Node
attempt is consumed, not reset. The permission is explicit and does not
require another approval between the following dependency-ordered steps:

1. Once, perform targeted harness syntax and fixture-consistency checks.
   Reuse unchanged production/static evidence; do not rerun the prior broad
   static batch or add a new harness.
2. Once, run the existing `owner-identity-v2` Node filter after correcting the
   fixture. This is corrected semantic attempt `2/2` overall, with no further
   Node retry. Keep the original owner-refresh/concurrent/negative assertions.
3. Only after Node PASS, run the still-unused focused PowerShell
   `-OwnerIdentityRemovalOnly` once. Only after its PASS, run the still-unused
   Package-boundary L0 once. This grant does not permit production changes or
   corrections to those other harnesses if either gate fails.
4. Once, run the final scoped `git diff --check` for this continuation's
   changed paths, and record one final 42-path implementation identity using
   the documented sorted path + tab + blob ID, LF-terminated manifest scheme.
   Task Markdown stays excluded from that implementation identity.

Stop on the first failed semantic invocation, identity drift before admission,
needed production/other-harness edit, allowlist expansion, protected-state
dependency or exhausted budget. Preserve evidence and remaining budgets;
report the exact failure once. Do not start a later gate or blindly rerun.
Mechanical command construction corrections must follow Workflow v2 and must
not rerun an invocation that already executed. Waiting on the same running
test session is not permission to launch a second invocation.

### Handoff And Exclusions

Append one consolidated fixture-closure entry to `RESULT.md`: actual test
edits, reached branches, commands/exits/timing, global Node attempt count,
removal/Package-boundary outcomes, final identity and deferred classes.
When all three focused gates pass, report
`COMPLETE / FIX_01_NON_UNITY_CLOSURE_PASS / CSHARP_CONSUMER_DEFERRED`;
otherwise report `BLOCKED` with the exact first unclosed gate.

Direct Node-produced-v2-to-C# consumer, C# compile/EditMode, Unity/Unity MCP/
CUA/BatchMode, protected runtime/process probes, real Provider/Codex/consumer
acceptance, full regression, Verifier dispatch, commit/tag/push, publication
and promotion remain NOT RUN/DEFERRED or separately gated. Existing disposable
fixture process lifecycle and cleanup may run only within the approved tests;
external holders must not be discovered, signaled or stopped.

- Current status: `FIX_01_FIXTURE_CLOSURE_AUTHORIZED / CODER_DEEP / TEST_ONLY`.
- Next notification: the existing `v0.3.coder.deep` to execute this closure.
- After completion: notify `UnityCodeDB v0.3 Planner` for stable-result review
  and the next separately authorized C# consumer/Unity decision.

## FAST_SUBAGENT Metadata Closure Route - 2026-09-16

Planner classified the removal preflight failure as one bounded candidate-data
correction suitable for Workflow v2.1 `FAST_SUBAGENT`, not a removal-product
repair or a new task. The unique `poc.35` transition is not duplicated; its
`source_flat_closure_sha256` is truncated to `63` hexadecimal characters. The
same truncated value is encoded in the Package-boundary expectation.

Using the production `Get-InstalledFlatClosureSha256` serialization over the
frozen `poc.35` marker contract and its `22` Package flat files yields exactly:

```text
132c09b1c2d63b1e8425479b8774addd41bbe363bf598294b923699778563ba4
```

The same calculation was cross-checked against the historical `poc.34`
transition and reproduced its recorded hash exactly. Therefore the correction
is limited to the manifest value and its direct Package-boundary expectation.
Do not weaken the materializer's 64-hex validation, change removal behavior,
rewrite immutable `poc.35`, or rerun the already passing Node gate.

Frozen admission:

- HEAD `e93a204384f4b9a5915b579c7133eed3b9727265`;
- 42-path identity `cb71834b72000088059db32ea18d67813bdcc3f6`;
- input manifest blob `13048c8ee830a46243a52847837dcef3ffc632d9`;
- input Package-boundary blob `c2f0b65f0900ca95b03df65bbcd774cdf7fffd87`;
- final Node harness blob `2154a3fdf02910715527cbd5646e58010782b858`;
- frozen production Supervisor blob
  `2e361d3ec0bfb51dcf51c0a1cc75de5068fd5c07`.

The exact execution envelope, evidence order, stop conditions, deferred classes,
and handoff are recorded in `TASK.md` under `FAST_SUBAGENT Metadata Closure
Authorization - 2026-09-16`. Current route:
`FAST_SUBAGENT / STANDING_WORKFLOW / v0.3.coder.standard`. Planner owns the
later Verifier decision; Coder may not recursively delegate.

## Workflow v2.1 Fast-Mode Promotion Decision - 2026-09-16

The bounded child returned after the first post-correction removal assertion.
Metadata consistency passed, then `-OwnerIdentityRemovalOnly` returned the
expected rejection exit code `4` for the first live-owner scenario but did not
contain the expected ownership message.

Direct source tracing establishes the immediate admission cause without a test
rerun:

- `Invoke-Materializer` adds `-PocFixture` unless `-OmitPocFixture` is supplied;
- every current Owner Identity v2 removal scenario also supplies
  `-ConfirmedProjectMutation`;
- production explicitly rejects `PocFixture + ConfirmedProjectMutation` as
  mutually exclusive before `Get-RemoveIntegrationAuthority` reaches the live
  owner predicate; and
- the production live-owner branch still throws `Remove CodeDB Integration is
  blocked while the Supervisor owner PID is live or unverifiable.`

The next repair is therefore expected to be test-harness admission alignment,
not production weakening. However, the cumulative same-path repair sequence
now exceeds Workflow v2.1 fast-mode convergence limits. Disposition:

- Recommended execution mode: `DURABLE_SESSION`.
- Recommended profile: `v0.3.coder.deep` only after a stable durable envelope
  is authorized.
- Same task: yes; the independently acceptable S18 objective has not changed.
- Immediate source authorization: none from this disposition.
- Rejected route: spawning another fast child to patch the next symptom.
- Preserved changes: corrected manifest blob
  `432eb0a4a2ac797e3a7837dc51a27ad46c4860d5` and corrected Package-boundary
  blob `7a865bc306be868c95232f69ddd1f22a11c65bdb`.
- Unclosed gates: removal L0, Package-boundary L0, final diff/identity, direct
  C# consumer, Unity, Verifier, and release gates.

Current status: `MODE_PROMOTION_REQUIRED / DURABLE_SESSION_DECISION`.
`STANDING_WORKFLOW` authorizes eligible child creation only and does not
authorize this durable transition, scope expansion, Unity, commit, publication,
or release.

## Durable Session Route Authorized - 2026-09-16

The human accepted the recommended mode promotion for the same S18 objective.
The active route is now:

- execution mode `DURABLE_SESSION`;
- profile `v0.3.coder.deep`;
- delegation `TASK_SPECIFIC`;
- session policy `REUSE_ONLY` with capacity one; and
- branch/HEAD `codex/v0.3.0-legacy-workflow` /
  `e93a204384f4b9a5915b579c7133eed3b9727265`.

The current 42-path input identity is
`1d4f44a8a206faf96ffd6073b2f865c217cb9013`. The materializer harness input
blob is `4ef181af7f2f5a13bd946cd4b1dc19d1f55ca223`; the preserved corrected manifest
and Package-boundary blobs are `432eb0a4a2ac797e3a7837dc51a27ad46c4860d5`
and `7a865bc306be868c95232f69ddd1f22a11c65bdb`.

The only writable implementation/test path is
`com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`, limited
to aligning confirmed Owner Identity v2 removal scenarios with the non-POC
fixture admission contract. Production, other tests, the two preserved
metadata/fixture paths, protected runtime state, and the validation project are
read-only. The expected narrow correction is correctly scoped
`-OmitPocFixture`; it must not weaken production admission or erase intentional
POC/negative coverage.

Run one targeted AST/source/fixture check, one corrected
`-OwnerIdentityRemovalOnly`, then on PASS one Package-boundary L0, one scoped
three-path diff check, and one final canonical 42-path identity. Reuse the Node
v2 PASS. The exact stop conditions and deferred classes are frozen in the
latest TASK authorization. A missing/busy/incompatible durable binding is
`BLOCKED`; do not spawn another child or create a replacement session.

Current status: `DURABLE_SESSION_AUTHORIZED / DISPATCH_PENDING`.
Next notification: resolve the existing `v0.3.coder.deep` binding once and
dispatch this exact packet, or report the binding unavailable.

### Durable Binding Admission - BLOCKED

The single permitted binding check could not inventory a durable Codex session.
It returned `apps=[]`, `browsers=[]`, and
`unsupported Codex auth method: apikey`. This is a routing-surface failure, not
evidence that `v0.3.coder.deep` is absent, busy, or incompatible. Its current
binding status is therefore `UNKNOWN`.

Per `REUSE_ONLY`, no replacement session, new child, interruption, silent
downgrade, or alternate-role dispatch was attempted. The authorized packet and
frozen identity remain valid.

Current status: `BLOCKED / DURABLE_BINDING_UNRESOLVED`.
Next action: the human manually forwards the latest TASK packet to the existing
`v0.3.coder.deep` session, or separately provisions/rebinds that durable lane.

## Durable Harness Result Reassessment - 2026-09-16

The manually routed durable Coder matched the frozen input and added
`-OmitPocFixture` to all eight confirmed-removal calls, but the first live-owner
assertion still failed. Planner performed a targeted read-only review without
rerunning the test.

The blanket mode conversion is not a viable final harness design. Two later
scenarios require production-declared fixture-only controls:

- the unverifiable-owner scenario passes
  `-TestProcessIdentityUnavailableForPid`, which production rejects whenever
  `-PocFixture` is absent; and
- the interrupted-removal scenario passes `-TestCrashAfterMutation`, which
  production likewise permits only in fixture mode.

Therefore those scenarios cannot both use the confirmed non-POC path and reach
their intended fault branches. The first live-owner result also recorded only
the outer assertion text, not `$live.Text`, so its actual pre-owner rejection
is still unknown. No removal-product defect is established by this result.

Planner-observed stable snapshot after the Coder edit, for reassessment only:

- HEAD `e93a204384f4b9a5915b579c7133eed3b9727265`;
- harness blob `bffee28c74582e36f17b09b2d74c1fa90c682ddd`;
- preserved manifest blob `432eb0a4a2ac797e3a7837dc51a27ad46c4860d5`;
- preserved Package-boundary blob
  `7a865bc306be868c95232f69ddd1f22a11c65bdb`;
- Planner-observed canonical 42-path identity
  `5c918e1648c6da4b98662dec1047bf214afc580c`.

The identity above is a read-only reassessment observation, not a replacement
claim that the Coder completed its deferred final evidence gate.

Recommended next route is one coherent same-S18 test-harness redesign:

1. keep confirmed non-POC coverage for ordinary live, ambiguous, safe removal,
   idempotence, and orphan admission;
2. keep fault-injected unverifiable and interruption/recovery coverage in the
   explicitly owned POC fixture lane;
3. record the full first failing command output before any semantic repair;
4. allow up to two causally related test-only fixture corrections in one
   durable working window; and
5. on removal PASS, complete Package-boundary L0, scoped diff check, and final
   42-path identity without rerunning the accepted Node gate.

Production remains frozen. If this separation cannot close the focused removal
gate without a production change, stop once with the exact product boundary and
request one allowlist reassessment.

Current status: `FIX_RECOMMENDED / ROUTE_REASSESSMENT_REQUIRED`.
Next action: human authorizes or rejects the coherent same-S18 harness redesign;
do not route Verifier yet.

## Durable Scenario-Lane Redesign Authorized - 2026-09-17

The human authorized the recommended same-S18 continuation. The route remains a
single `DURABLE_SESSION` using the existing `v0.3.coder.deep` binding with
`REUSE_ONLY`; no new child or replacement session is permitted.

Frozen dispatch admission:

- branch/HEAD: `codex/v0.3.0-legacy-workflow` /
  `e93a204384f4b9a5915b579c7133eed3b9727265`;
- current 42-path identity: `5c918e1648c6da4b98662dec1047bf214afc580c`;
- materializer harness blob: `bffee28c74582e36f17b09b2d74c1fa90c682ddd`;
- preserved manifest and Package-boundary blobs:
  `432eb0a4a2ac797e3a7837dc51a27ad46c4860d5` and
  `7a865bc306be868c95232f69ddd1f22a11c65bdb`.

The only writable implementation/test path is the materializer harness. The
Coder must split ordinary confirmed-removal scenarios from fixture-only fault
scenarios: `-OmitPocFixture` plus confirmation for ordinary cases, default POC
fixture without confirmation for unverifiable-owner and crash/recovery cases.
It must preserve negative/POC coverage and capture complete first-failure text.

One static/fixture-lane check and one focused removal invocation are the initial
evidence envelope. Up to two same-cause test-only corrections are allowed in
the same durable window; after removal PASS, run Package-boundary L0, scoped
diff check, and final 42-path identity. Reuse the accepted Node PASS. Any new
product cause or scope/identity drift stops the route. Unity, C#, Verifier,
commit and publication remain separately gated.

Current status: `DURABLE_FIX_AUTHORIZED / DISPATCH_PENDING`.
Next action: resolve the existing `v0.3.coder.deep` binding once and send this
exact packet; if unavailable, record `BLOCKED / DURABLE_BINDING_UNRESOLVED`.

## Durable Scenario-Lane Redesign Dispatch - 2026-09-17

The existing compatible `v0.3.coder.deep` durable binding accepted the exact
same-S18 packet. `REUSE_ONLY` was honored: no new child or replacement session
was created, and no concurrent role was started.

Current status: `DISPATCHED / WAITING_FOR_CODER_RESULT`.
Next notification: the existing `v0.3.coder.deep` returns one consolidated
result to `UnityCodeDB v0.3 Planner`.
Next action: Planner reviews that stable result once delivered; do not poll,
duplicate dispatch, or route Verifier before review.

## Production PID Automatic-variable Collision - 2026-09-17

Planner's human-authorized read-only trace classified the complete first
failure from the durable scenario-lane result. The blocker is in production
`Assert-RemoveIntegrationOwnerRecord`, not in the newly separated fixture
lanes. That function declares local `$pid`; PowerShell resolves it as the
read-only automatic `$PID` variable because variable names are
case-insensitive. The assignment fails while parsing the validated owner record,
before the live-owner liveness predicate. This explains the nested read-only or
constant PID error and the recorded `mutated_scopes=[]` result.

`Write-OwnerIdentityV2RemovalAuthority`,
`New-OwnerIdentityV2RemovalFixture`, and
`Invoke-OwnerIdentityRemovalScenarios` pass `$ProcessId` or read `$PID`; they do
not perform the prohibited assignment. `Get-MaterializerProcessIdentity` also
accepts `$ProcessId`. No test-only repair is appropriate.

The smallest coherent repair is already inside the original S18 exact
allowlist but outside the latest harness-only working grant: reopen only
`com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`, rename that
one local and its same-function references, preserve all behavior, and use the
existing focused removal harness as the regression. After a corrected removal
PASS, continue the pending Package-boundary L0, scoped diff check, and final
42-path identity. Reuse all unchanged Node and fixture-lane evidence.

Current status: `PRODUCTION_FIX_RECOMMENDED / HUMAN_AUTHORIZATION_REQUIRED`.
No source/test byte was changed and no test was run by this reassessment.

Next action: the user explicitly authorizes or rejects this exact same-S18
production `FIX 02`. Until then, do not dispatch Coder or Verifier and do not
open Unity or any release/publication gate.

## Human Authorization - Production PID Collision FIX 02 - 2026-09-17

The human authorized the exact bounded production repair on the same S18
snapshot. The route remains `DURABLE_SESSION / v0.3.coder.deep` with
`REUSE_ONLY`; the existing compatible durable Coder binding is the only target.

Frozen admission is branch `codex/v0.3.0-legacy-workflow`, HEAD
`e93a204384f4b9a5915b579c7133eed3b9727265`, and current 42-path identity
`5c918e1648c6da4b98662dec1047bf214afc580c`. The materializer and harness blobs
are `d51e7990520e90e5ff5e4e85918e3b2c5e91ca29` and
`9a700fd03b0c42f6cca555a60ba23f365b35c55b`.

Only `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` is
writable. The Coder must rename the local `$pid` in
`Assert-RemoveIntegrationOwnerRecord` and its same-function references so it
does not alias automatic `$PID`; no behavior or validation policy may change.
The harness and every other source, metadata, generation, and project path are
frozen.

The bounded sequence is one AST/source check, one corrected
`-OwnerIdentityRemovalOnly`, then (only on PASS) Package-boundary L0, scoped
diff-check, and final 42-path identity. Reuse accepted Node and fixture-lane
evidence. A new independent failure, identity drift, second-path requirement,
or scope expansion stops the route. Unity, C#, Verifier, commit, push,
publication, and promotion remain closed.

## Planner/User Disposition - 2026-09-18

Disposition: `ACCEPT` for the bounded focused consumer review. No finding was
left open. The accepted claim remains limited to Route A provenance,
test-owned binding/freshness, focused EditMode evidence, and the guarded
Verifier review. Broader Unity/runtime/release/publication work remains
deferred and requires separate authorization. No commit, push, or promotion
was performed.

## Human Focused EditMode Evidence - 2026-09-18

The supplied screenshot shows the named focused EditMode test passing with
`1 passed / 0 failed`. This is bounded evidence for the S18 consumer fixture
path only. Unity version is not visible and remains unrecorded; no broader
runtime or release conclusion is made. Human closure of the validation project
is still required before Verifier routing.

## Human Closure And Verifier Readiness - 2026-09-18

The human confirmed the validation project is closed. The focused consumer
gate is ready for one bounded read-only Verifier review against HEAD
`e93a204384f4b9a5915b579c7133eed3b9727265`, 42-path identity
`0bb8d82535ef70548b917425598e7d1bdd1cca1f6a582ae7e6755ea3f2405f06`,
and ordered four-path identity
`a4d53ec0ae5a61c62dd2f988f354c4147481a4abdb9a198cde487a4e05c5ca4e`.

Verifier scope must remain limited to the original fixture provenance and
consumer failures plus adjacent negative identity regressions. It must reuse
recorded evidence, remain read-only, and leave full Unity/runtime/release and
publication gates deferred. Human authorization is still required before
dispatch.

## Verifier Completion - 2026-09-18

The guarded Verifier review completed `PASS` with no findings and no identity
drift. It reused the bounded Coder evidence and human focused EditMode result,
and wrote only `verifications/VERIFICATION-01.md`. Unity version, broader
runtime/release, and Git publication remain deferred. Planner/User disposition
is now required.

## Verifier Authorization - 2026-09-18

The human authorized one guarded read-only Verifier review. The only writable
path is `verifications/VERIFICATION-01.md`. No test rerun, Unity action,
Coder contact, source edit, commit, push, publication, or release promotion is
authorized. The Verifier returns once to Planner/User with `PASS` or `FAIL`,
one-time findings, reused evidence, identity admission, deferred boundaries,
and the next actor.

## Structural Fixture Binding Repair Completion - 2026-09-18

The authorized test-only repair completed without widening into production,
Package, generation, Node harness, fixture data, or Unity state. Only the C#
focused consumer test changed. It structurally rebinds exactly the eight
environment path/identity leaves to the existing `_projectRoot`; exact
cardinality checks prevent mutation of the remaining Node evidence. No fixed
fixture root is created and production root validation remains unchanged.

One source/static check and one affected four-path `git diff --check` passed.
The frozen Node/JSON/.meta blobs remained stable. Updated identities are
42-path `665355fe662ac3e083fa9b677a219066bf2145d1acf241e36aaad577ca462b1a`
and ordered four-path
`ed900a734e6eb75b8537c995e3a40140f6025b141ba35c2d2486713e435b16a9`.

Current status: `STRUCTURAL_FIX_COMPLETE / HUMAN_EDITMODE_PENDING`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: admit the frozen repair and decide the separately gated human
focused EditMode run. Unity, Verifier, commit, push, publication, and
promotion remain closed.

## Structural Fixture Binding Type FIX Stop - 2026-09-18

The authorized type-only correction was applied in the C# test helper and
matches the strict JSON API. The sole static/source attempt stopped because
the inline check used a CRLF-sensitive marker; this is a check-construction
failure, not a reported C# semantic failure. The bounded diff-check and
identity steps were intentionally not started.

Current status: `BLOCKED / STATIC_CHECK_MARKER_CONSTRUCTION_FAILURE`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: decide whether to authorize one corrected static/source check;
keep Unity, EditMode, Verifier, commit, push, and publication closed.

## Structural Fixture Binding Type Evidence Completion - 2026-09-18

The corrected newline-tolerant source check passed once, followed by one
affected four-path diff-check and one identity calculation. The minimal C#
type correction is now evidenced; Node/JSON/.meta remain unchanged. Identities
are 42-path `654e348ee20ef301effd03ac582a1836fde77ba1812ab585da7492ebb293f134`
and ordered four-path
`723824b0e02348317793db83a65746fa00242e0132c0c0a9a488f8212562aaa0`.

Current status: `TYPE_FIX_EVIDENCE_COMPLETE / HUMAN_EDITMODE_PENDING`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: review/admit the frozen type-fix snapshot and decide the separate
human focused EditMode run. Unity, Verifier, commit, push, publication, and
promotion remain closed.

## Structural Fixture Timestamp Adapter Completion - 2026-09-18

The authorized C# test-only timestamp adapter completed without touching the
Node fixture or any production/Package/Unity file. It dynamically binds the
unique operational readiness observation timestamp to current UTC while
preserving all existing environment bindings and evidence fields.

Source/static check and four-path diff-check passed once each. New identities:
42-path `0bb8d82535ef70548b917425598e7d1bdd1cca1f6a582ae7e6755ea3f2405f06`;
ordered four-path `a4d53ec0ae5a61c62dd2f988f354c4147481a4abdb9a198cde487a4e05c5ca4e`.

Current status: `TIMESTAMP_ADAPTER_COMPLETE / HUMAN_EDITMODE_PENDING`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: admit the timestamp-adapter identity and decide the separate
human focused EditMode run. Unity, Verifier, commit, push, publication, and
promotion remain closed.

## Planner Admission After Type Fix - 2026-09-18

Admission passed with HEAD
`e93a204384f4b9a5915b579c7133eed3b9727265`, 42-path identity
`654e348ee20ef301effd03ac582a1836fde77ba1812ab585da7492ebb293f134`, and
ordered four-path identity
`723824b0e02348317793db83a65746fa00242e0132c0c0a9a488f8212562aaa0`.
The C# helper type fix is the only source change in this continuation. The
human-owned focused EditMode handoff is ready; Verifier and Git actions remain
closed.

## Planner Admission After Structural Binding - 2026-09-18

Admission passed with HEAD
`e93a204384f4b9a5915b579c7133eed3b9727265`, 42-path identity
`665355fe662ac3e083fa9b677a219066bf2145d1acf241e36aaad577ca462b1a`,
and ordered four-path identity
`ed900a734e6eb75b8537c995e3a40140f6025b141ba35c2d2486713e435b16a9`.
No evidence was rerun. The human-owned focused EditMode handoff is ready;
Verifier, commit, push, and publication remain closed.

## Runtime-Contract Fixture Binding Route - 2026-09-18

Decision: `ACCEPT STRUCTURAL TEST-ONLY BINDING`.

The sanitized `C:/codedb-fixture/project` value remains a template only. The
focused C# test must materialize no fixed drive path; it must bind the
environment-specific path, identity, runtime, namespace, pipe, and
operational-readiness leaves to its existing temporary Unity-like root.
Production `ValidateProjectRoot` remains unchanged and continues to reject
missing or incomplete roots.

The Node runtime-contract provenance and Route A identities remain frozen. A
new bounded repair authorization is required before modifying the C# test or
running the affected EditMode case. Verifier, commit, push, and publication
remain closed.

## Planner Admission After Route A - 2026-09-18

Read-only admission passed with no identity drift. HEAD is
`e93a204384f4b9a5915b579c7133eed3b9727265`; Package and fixture runtime
contract SHA agree at
`a3cbc22b0b3fd2394a5cbdcca4acd37b142a4a81df122d6b48bccda1c593bf68`.
The admitted identities are 42-path
`06775b1319ea1c60ed2bb4100300897f0344903822dfd8a5f27acb874e074a68` and
ordered four-path `a3370be9a5a09949ac10ac1ebc4a01820e6b715130705142d253eab3d026d323`.

Next actor is the human owner. Reopen relative `UnityValidationProject`, wait
for compilation, run only the named focused EditMode consumer test, record the
Unity version/result, and close the project. Do not route Verifier or perform
Git publication before that report.

Current status: `FIX_02_AUTHORIZED / DISPATCH_PENDING / CODER_DEEP`.
Next action: dispatch once to the existing deep Coder and await its consolidated
result for Planner review.

## Production PID Collision FIX 02 Dispatch - 2026-09-17

The exact authorized FIX 02 packet was sent once to the existing compatible
`v0.3.coder.deep` durable binding. `REUSE_ONLY` was honored; no new child,
replacement, interruption, downgrade, or alternate-role session was used.

Current status: `FIX_02_AUTHORIZED / DISPATCHED / WAITING_FOR_CODER_RESULT`.
Next action: Planner reviews the single consolidated Coder result. Verifier,
Unity, C#, commit, push, publication, and promotion remain closed.

## Mature Activation Namespace FIX 03 - 2026-09-17

The human authorized one same-S18 bounded correction of the independent failure
recorded after FIX 02. The nested `RemoveIntegration` returned exit `4`,
`BLOCKED / PREFLIGHT`, and `mutated_scopes=[]` at the dead-owner case:
`Activation contract namespace contains unexpected entry: supervisor`. No
deletion or ownership decision was made; removal and dependent gates remain
unproved.

Targeted source review classified this as a validator allowlist defect, not an
incorrectly co-located Supervisor or a test-only fixture error.
`Get-InstanceActivationContractPaths` deliberately derives both activation
records and `supervisor/` from the same versioned contract root. The removal
hierarchy validator recognizes `supervisor/`, and the dedicated Supervisor
inventory then validates its complete state/lock pair and bounded child files.
But `Assert-InstanceActivationContractNamespace`, used by mature reads and
recovery, rejects that known sibling. Moving the Supervisor path would change
the cross-language wire identity and immutable successor closure, which this
failure does not justify.

Frozen branch/HEAD: `codex/v0.3.0-legacy-workflow` /
`e93a204384f4b9a5915b579c7133eed3b9727265`. Planner-observed input blobs:
engine `3eaff8020888d8504e7edb24ee4d4339b794c557`, materializer
`24968ad4c57760c916435b6113da067ce54d858f`, harness
`9a700fd03b0c42f6cca555a60ba23f365b35c55b`. No post-FIX-02 canonical
42-path identity has yet been computed.

The authorized writer is the existing `v0.3.coder.deep` durable session,
`REUSE_ONLY`. Only the engine's mature namespace validation and directly
adjacent harness assertions may be edited; the materializer, Package metadata,
generation, Provider, and protected validation project remain read-only. Accept
only the exact known `supervisor` directory at the mature root. Do not weaken
the fresh namespace, unknown/wrong-type/reparse rejection, activation
cardinality, retirement proof, Supervisor inventory, owner liveness or removal
transaction boundaries. One targeted check and one corrected removal L0 precede
the dependent Package-boundary L0, scoped four-path diff-check, and final
canonical 42-path identity. One explained same-cause correction is available;
new independent causes stop for reassessment. Node PASS is reused, not rerun.

Current status: `FIX_03_AUTHORIZED / DISPATCH_PENDING / CODER_DEEP`.
Next action: dispatch once to the existing deep Coder, then review its stable
result. No Unity, C#, Verifier, commit, push or release action is implied.

## Package-boundary Bridge Authority Reassessment - 2026-09-17

FIX 03's focused removal L0 is accepted as PASS. Its dependent
Package-boundary L0 then stopped once on
`Project Supervisor bridge still classifies or routes through current-instance
storage.` Planner performed only the authorized direct source review and did
not edit or rerun anything.

The assertion is contract-bearing. The Bridge currently invokes
`AICodedbCurrentInstanceStore.Read` while authenticating Supervisor state. That
store performs selected-instance and immutable-generation hashing, Package
generation classification, stable-wrapper validation, and trusted-previous
policy. This makes Bridge a second selected-instance authority rather than the
bounded authenticated Supervisor client frozen by the roadmap. The correct
boundary is not to remove identity checks: Bridge must still bind the Package
control contract, project/root/runtime, Owner Identity version, activation
epoch, selected identity, canonical pipe, and status response to one
authenticated Supervisor observation. It must simply not recreate the
Supervisor/materializer's selection classification.

Direct call/definition inspection also found one stale three-argument
`ReadSupervisorRuntimeIdentity` call against its four-argument definition and
one legacy eight-argument `TryEnsureCurrentSupervisorProtocol` call against its
current four-argument definition. This is a deterministic source-level C# call
shape defect in the same incomplete Bridge migration; C# compilation itself
remains `NOT RUN`.

Recommended same-S18 FIX 04 opens only the Bridge and its directly coupled
Package-boundary / Editor assertions. Remove the full selection-store read and
selection-policy comparisons, retain state-to-Package and state-to-authenticated
pipe/status binding, retain the existence-only fail-closed bootstrap gate, and
align the two stale calls. Then run one targeted source/signature batch and one
corrected Package-boundary L0. Reuse Node and removal PASS; on success complete
the deferred scoped diff-check and canonical 42-path identity. Unity, C#
compile/EditMode, Verifier, commit, push, publication, and promotion remain
separate gates.

Current status: `FIX_04_RECOMMENDED / HUMAN_AUTHORIZATION_REQUIRED`.
Next action: the user explicitly authorizes or defers FIX 04 before any Coder
dispatch. The stable FIX 03 snapshot remains preserved and not Verifier-ready.

## Package-boundary Bridge Authority FIX 04 Authorization - 2026-09-17

The human authorized the recommended coherent same-S18 correction. Execution
remains `DURABLE_SESSION / v0.3.coder.deep / REUSE_ONLY` and must use the
existing compatible durable binding once. Frozen admission is branch
`codex/v0.3.0-legacy-workflow`, HEAD
`e93a204384f4b9a5915b579c7133eed3b9727265`, with Planner-observed input blobs
Bridge `433e9166a5ac376a37cb963ed634f568f1867522`, Package-boundary fixture
`7a865bc306be868c95232f69ddd1f22a11c65bdb`, and direct Editor test
`0325d68dbf4d53ef4fdb702e2b819b15e32b1233`.

Only `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs` and, if directly
required, coupled assertions in
`com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1` and
`com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` may change,
plus append-only S18 result evidence. Remove the Bridge's duplicate full
current-instance classification and finish its two stale helper calls, while
preserving Package-contract, namespace/pipe, state, owner, project/root/runtime,
authenticated response, bootstrap, reparse, empty-runtime, and fail-closed
bindings. No v1 handoff, second selection authority, unauthenticated-state
trust, or protocol expansion is permitted.

Run exactly one targeted source/signature batch and one Package-boundary L0.
Reuse, rather than rerun, accepted Node v2 and FIX 03 removal evidence. On PASS
only, perform the pending scoped diff-check and canonical 42-path identity.
Stop on a new independent cause, additional path, identity drift, protected
state, or broader authority. C# compile/EditMode, Unity, Verifier, Git
publication, and release gates remain closed.

Current status: `FIX_04_AUTHORIZED / DISPATCH_PENDING / CODER_DEEP`.
Next action: send this exact continuation once to the existing deep Coder and
review its consolidated result before any downstream routing.

## Bridge Authority FIX 04 Dispatched - 2026-09-17

The authorized packet was sent once to the existing compatible
`v0.3.coder.deep` durable binding under `REUSE_ONLY` (thread
`01a06059-5707-7091-8164-1a0a2ea4367e`, host `local`). No new or replacement
session was created, and no other role was started.

Current status: `FIX_04_AUTHORIZED / DISPATCHED / WAITING_FOR_CODER_RESULT`.
Next action: Planner reviews the single consolidated Coder result; Verifier,
Unity, C#, Git publication, and release gates remain closed.

## Stale Durable Packet Reconciliation - 2026-09-17

The existing binding consumed the historical line-486 harness continuation.
Its identity-drift stop was correct: current harness blob
`b2e0abb5df2f575f00b588269b0b20c6178f4f42` did not match that old packet's
`4ef181af7f2f5a13bd946cd4b1dc19d1f55ca223`. No file, process, test, or budget
was changed or consumed by this stale replay. It is not a new production
finding and is superseded by the current Bridge FIX 04 route.

Reconcile by sending one unambiguous, no-line-number FIX 04 packet to the
same `v0.3.coder.deep` durable binding. Keep the exact frozen HEAD, three input
blobs, three-path conditional allowlist, evidence order, and fail-closed stop
conditions already authorized. Do not redispatch the historical harness lane,
create a session, add a retry, contact Verifier, or open Unity.

Current status: `FIX_04_AUTHORIZED / ROUTE_CORRECTION_PENDING / CODER_DEEP`.
Next action: deliver the correction once and await the consolidated Bridge
result before any downstream route.

## Bridge Authority FIX 04 Route Correction Dispatched - 2026-09-17

The current no-line-number FIX 04 packet was sent once to the existing
`v0.3.coder.deep` durable binding under `REUSE_ONLY` (thread
`01a06059-5707-7091-8164-1a0a2ea4367e`, host `local`). The historical
line-486 harness packet is superseded and must not be executed again. No new
session or role was created.

Current status: `FIX_04_AUTHORIZED / DISPATCHED / WAITING_FOR_CODER_RESULT`.
Next action: Planner reviews the single current Bridge result; Verifier,
Unity, C#, Git publication, and release gates remain closed.

## Package-boundary Confirmation Contract Reassessment - 2026-09-17

The current Bridge FIX 04 result closed its original authority and signature
findings at source level. The dependent Package-boundary L0 then stopped on the
first new assertion: `RemoveIntegration` is present in production's mutation
confirmation contract but absent from two frozen fixture markers (the
`ValidateSet` expectation and the AST dispatch-gate marker). Direct inspection
confirms the production gate calls `Assert-MutationConfirmation` for that
action, so this is a narrowly scoped fixture-contract omission rather than a
Bridge or materializer policy failure.

Recommended route is one same-S18 adjacent test-only correction in
`Tests~/test-codedb-package-boundary.ps1`, adding `RemoveIntegration` to both
markers and preserving their production order. No production source or other
test path may change. Run one targeted marker/AST check, then one corrected
Package-boundary L0; reuse Node v2 and FIX 03 removal PASS. On PASS, complete
the deferred scoped diff-check and canonical 42-path identity once. Any new
cause, identity drift, extra path, protected state, or authority expansion
stops the route. Unity, C#, Verifier, Git publication, and release remain
closed.

Current status: `FIX_04_ADJACENT_ASSERTION_RECOMMENDED / HUMAN_AUTHORIZATION_REQUIRED`.
Next action: await explicit human authorization before another Coder delivery.

## FIX 04 Transport Reconciliation - 2026-09-17

The first corrected delivery failed at the Codex transport layer with
`429 Too Many Requests` before any Coder response or tool action. No source,
test, command, or evidence budget was touched, so the historical line-486
packet remains stale and superseded.

Exactly one unchanged transport resend was delivered to the same
`v0.3.coder.deep` binding. This does not constitute a semantic test retry or
expand the FIX 04 budget. A second pre-execution transport failure is a hard
`BLOCKED / DURABLE_TRANSPORT_UNAVAILABLE`; no replacement session or alternate
route is allowed. Once execution begins, the existing FIX 04 evidence order is
unchanged.

## Current Route Pointer - 2026-09-17

This final pointer supersedes earlier pending/dispatched transport statuses.
FIX 04 has executed; its Bridge source/signature evidence passed. The only
active proposal is the one-file Package-boundary fixture correction described
above, adding `RemoveIntegration` to the two stale confirmation markers.

Current status: `FIX_04_ADJACENT_ASSERTION_RECOMMENDED / HUMAN_AUTHORIZATION_REQUIRED`.
Next action: await explicit human authorization. Do not redispatch historical
packets or contact Coder/Verifier before that decision.

## Package-boundary Confirmation Marker FIX 05 Authorization - 2026-09-17

The human authorized one same-S18, test-only correction for the two stale
Package-boundary confirmation markers. Route remains
`DURABLE_SESSION / v0.3.coder.deep / REUSE_ONLY`, using the existing binding
once. Frozen branch/HEAD is `codex/v0.3.0-legacy-workflow` /
`e93a204384f4b9a5915b579c7133eed3b9727265`; Bridge blob is
`e49f6ebae4ab17b4916d8cc519f57f319ce50041`, production materializer blob is
`24968ad4c57760c916435b6113da067ce54d858f`, Package-boundary fixture input is
`7a865bc306be868c95232f69ddd1f22a11c65bdb`, and direct Editor test input is
`0325d68dbf4d53ef4fdb702e2b819b15e32b1233`.

The only writable source/test path is
`com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`. Add
`RemoveIntegration` to the two exact markers (mutation `ValidateSet` and AST
dispatch-gate marker), preserving production order; no production or other
test path may change. Run one marker/AST check and one corrected
Package-boundary L0, reusing accepted Node v2, FIX 03 removal, and FIX 04
Bridge evidence. On Package-boundary PASS only, perform the pending scoped
diff-check and one canonical 42-path identity. Any new cause, identity drift,
extra path, protected state, or expanded authority stops the route. Unity, C#,
Verifier, and Git publication remain closed.

Current status: `FIX_05_AUTHORIZED / DISPATCH_PENDING / CODER_DEEP`.
Next action: send the exact packet once to the existing deep Coder and review
its consolidated result before downstream routing.

## Package-boundary Confirmation Marker FIX 05 Dispatched - 2026-09-17

The authorized one-file test-only FIX 05 packet was sent once to the existing
`v0.3.coder.deep` durable binding under `REUSE_ONLY` (thread
`01a06059-5707-7091-8164-1a0a2ea4367e`, host `local`). Historical packets are
superseded; no new session or role was created.

Current status: `FIX_05_AUTHORIZED / DISPATCHED / WAITING_FOR_CODER_RESULT`.
Next action: Planner reviews the single current result. Verifier, Unity, C#,
Git publication, and release gates remain closed.

## Planner FIX 05 Non-Unity Gate Disposition - 2026-09-17

The one-file fixture correction and focused Package-boundary L0 passed. The
Coder also recorded a scoped diff-check PASS and canonical 42-path identity
`f6faa70ece7e2030070c26079565c9b873deacbe`; Node v2, FIX 03 removal,
and FIX 04 Bridge evidence were reused. Planner checked HEAD and four
neighboring blobs without rerunning evidence or recomputing the full identity.
No new in-scope finding is identified. This closes the focused non-Unity gate
only; it is not C#, Unity, consumer, Verifier, or release acceptance.

Recommended next route is one grouped affected C# consumer/compile gate on
the frozen snapshot. A non-Unity harness may be used if available; otherwise
return for a separate, human-owned focused EditMode authorization in
`UnityValidationProject`. No Unity launch, verifier dispatch, publication, or
commit is implied by this recommendation.

Current status: `NON_UNITY_FOCUSED_GATE_PASS / CSHARP_L1_AUTHORIZATION_REQUIRED`.
Next action: await human decision on the grouped affected C# gate.

## Fixture Sanitization Correction Authorization - 2026-09-18

The human authorized one new bounded same-S18 test-only correction after the
real Node v2 consumer pre-Unity attempt stopped on an independent sanitization
cause. The partial Node harness is preserved at blob
`f993b7140e494874dd63a19498760d51157142e2`; no durable sample or C# test was
accepted. The exact correction is to normalize `status.last_event_detail`,
check decoded string leaves for local paths and sensitive identities, and run
one fresh `owner-identity-v2-csharp-fixture` invocation without retry. On PASS,
the already-authorized sanitized fixture/C# closure may continue inside the
same test-only allowlist; otherwise stop and return the new cause.

Current status: `FIXTURE_SANITIZATION_CORRECTION_AUTHORIZED / DISPATCH_PENDING`.
Route: existing `v0.3.coder.deep` under `REUSE_ONLY`; no replacement session,
Unity, Verifier, commit, or publication. The current Planner transport cannot
send cross-session messages, so the packet may require human forwarding.
Next action: Coder executes once and returns one consolidated result; Planner
reviews it before the human-owned EditMode handoff.

## Fixture Sanitization Correction Human-Forward Handoff - 2026-09-18

The Planner transport cannot send cross-session messages in this thread. The
existing deep Coder page was opened with the current TASK.md, but no dispatch
or execution is claimed. The exact authorized packet requires one manual
forward; historical packets and replacement sessions are prohibited.

Current status: `FIXTURE_SANITIZATION_CORRECTION_AUTHORIZED / HUMAN_FORWARD_PENDING`.
Next action: human forwards the current packet, then Coder returns one
consolidated result to Planner before any Unity/EditMode or downstream gate.

## Workflow v2 FAST_SUBAGENT Transition - 2026-09-18

The human requested the task-scoped child-agent route for the current bounded
fixture correction. Use `FAST_SUBAGENT / v0.3.coder.standard` with
`STANDING_WORKFLOW` delegation and `SPAWN_BOUNDED` policy. One depth-1 Coder
child is the only writer; recursive delegation, durable-session replacement,
Verifier, Unity, commit, and publication remain closed. The exact existing
allowlist and one-fresh-filter stop condition are unchanged.

Current status: `FAST_SUBAGENT / CODER_CHILD_DISPATCH_PENDING`.
Next action: child returns one consolidated result; Planner reviews it before
any human-owned EditMode handoff.

## Workflow v2 FAST_SUBAGENT Dispatch - 2026-09-18

One depth-1 Coder child is now active under `FAST_SUBAGENT /
v0.3.coder.standard`. It is the sole writer for the authorized fixture
sanitization correction; no durable-session replacement, recursive child,
Unity, Verifier, commit, or publication is active.

Current status: `FAST_SUBAGENT / CODER_CHILD_ACTIVE`.
Next action: wait for the child's consolidated result, then Planner reviews
the exact evidence and routes only the next authorized gate.

## Pre-Unity Consumer Contract FIX Route - 2026-09-18

The fixture-sanitization child completed, but Planner and an independent
read-only child found two pre-Unity admission gaps. The named C# test accepts
the real Node v2 sample without independently fixed owner expectations and
without the required adjacent v1 or owner/activation mismatch rejection. In
addition, the recorded `d1bd9a80...` identity cannot be reproduced by the
documented 42-path algorithm; the current reproducible pre-fix value is
`d504c7d960d27e69013ac40657f7fb6312bc0dc9`. The new JSON and `.meta` also
need an explicit test-only closure identity.

The route remains the same S18 objective and four-path test-only allowlist.
Use one `FAST_SUBAGENT / v0.3.coder.standard` depth-1 Coder under
`STANDING_WORKFLOW / SPAWN_BOUNDED`. Only the Editor test may change; the Node
harness and fixture bytes stay frozen. Add independent expectations plus v1
and activation-mismatch fail-closed assertions, run no Node command, then run
one bounded source/fixture check, one four-path diff-check, and freeze both the
historical 42-path implementation identity and a separate four-path consumer
closure identity. Stop before Unity or Verifier.

Current status: `PRE_UNITY_CONSUMER_FIX_AUTHORIZED / CODER_CHILD_DISPATCH_PENDING`.
Next action: bounded Coder child returns one consolidated result; Planner
reviews before any human-owned focused EditMode handoff.

## Pre-Unity Consumer Contract FIX Result - 2026-09-18

The single depth-1 Coder correction completed within the frozen four-path
test-only allowlist. Only the Editor consumer test changed. Its positive
Node-v2 path now binds to independent root/runtime, selected-instance,
activation, owner-version, and Supervisor-PID expectations; adjacent v1 and
activation-mismatch responses are asserted `Blocked` with
`SUPERVISOR_IDENTITY_MISMATCH`. No production parser or fixture byte changed.

Evidence was bounded to one source/fixture check (`PASS`, exit `0`) and one
scoped four-path `git diff --check` (`PASS`, exit `0`). Node, C# compile,
EditMode, Unity, Verifier, publication, and Git actions were not run. The
reproducible canonical 42-path identity is
`6f6e870748cc2c58eafc283c4c7d2f8490faa09b`; the ordered four-path closure
identity is `8ef380fd4d1c5c1a72da27e9679547f037ab28c4`.

Current status: `PRE_UNITY_CONSUMER_FIX_PASS / EDITMODE_HUMAN_HANDOFF_PENDING`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: review this exact frozen snapshot and decide whether to request the
already bounded human-owned focused EditMode run in `UnityValidationProject`.
Do not route Verifier or publish before that decision.

## Consumer FIX Evidence Invalidation - 2026-09-18

The handoff review identified that the prior negative-case replacement markers
did not match the spaces in the pretty-printed fixture. The test-only correction
was made inside the existing Editor allowlist and adds explicit mutation
assertions. No evidence was rerun after this source change; the prior PASS and
its identities therefore cannot be used for admission.

Current status: `BLOCKED / FRESH_EVIDENCE_REQUIRED`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: decide whether to authorize one new bounded source/fixture check,
one four-path diff-check, and matching identity calculations. Unity, Verifier,
commit, and publication remain closed.

## Fresh Consumer FIX Evidence Completion - 2026-09-18

The human-authorized fresh pass is complete on the corrected same-S18
test-only snapshot. The source/fixture check (`PASS`, exit `0`, 315.28 ms)
verified the exact spaced replacements and both real mutations; the sole
four-path `git diff --check` also passed. No Node rerun or Unity/C# action was
performed. The canonical 42-path identity is
`23b9e99d1ac393005ad395d03189fd156dcb1f30`; the ordered four-path closure
identity is `17e6e37153a77bb212ca82bdab556a4027966d85`; fixture SHA and blobs
are in `RESULT.md`.

Current status: `PRE_UNITY_CONSUMER_FIX_PASS / EDITMODE_HUMAN_HANDOFF_PENDING`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: review this exact identity and decide whether to request the
already bounded human-owned focused EditMode run in `UnityValidationProject`.
Do not route Verifier or perform Git publication before that decision.

## Fresh Consumer FIX Evidence Route - 2026-09-18

The human authorized one evidence-only pass on the corrected Editor test.
This is not a new code repair: the four-path test-only snapshot is frozen and
the existing `v0.3.coder.standard` child remains the sole actor. It may run
one source/fixture check, one four-path `git diff --check`, and matching 42-path
and four-path identity calculations. Node, Unity, C# compile/EditMode,
Verifier, Git publication, and release actions remain closed.

Current status: `FRESH_CONSUMER_FIX_EVIDENCE_AUTHORIZED / CODER_CHILD_PENDING`.
Next action: receive the consolidated evidence result and perform Planner
identity admission before any human-owned focused EditMode handoff.

## Fresh Consumer FIX Evidence Final Pointer - 2026-09-18

The authorized evidence pass completed on the corrected frozen test-only
snapshot. Source/fixture and four-path diff-check both passed; identities are
`23b9e99d1ac393005ad395d03189fd156dcb1f30` (42-path) and
`17e6e37153a77bb212ca82bdab556a4027966d85` (four-path closure). Node, C#,
Unity, Verifier, and Git publication were not run.

Current status: `PRE_UNITY_CONSUMER_FIX_PASS / EDITMODE_HUMAN_HANDOFF_PENDING`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: perform identity admission and decide on the bounded human-owned
focused EditMode gate in `UnityValidationProject`.

## Planner Identity Admission And Human Handoff - 2026-09-18

The latest four-path child snapshot passed read-only identity admission. The
42-path implementation identity is
`23b9e99d1ac393005ad395d03189fd156dcb1f30`; the separate four-path consumer
closure identity is `17e6e37153a77bb212ca82bdab556a4027966d85`. The four input
blobs and fixture SHA-256 match the Coder result. No evidence was rerun.

Current status: `EDITMODE_HUMAN_HANDOFF_READY`.
Next action: human opens relative path `UnityValidationProject`, runs only
the named focused EditMode consumer test after compilation, records version and
result, and closes the project. Unity MCP/CUA/BatchMode, substitute processes,
Verifier, and Git publication remain closed until that handoff returns.

## Runtime-Contract Fixture Drift Route - 2026-09-18

The actual human EditMode result is `FAIL` before negative-case execution:
the current Package runtime-contract SHA-256 is
`a3cbc22b0b3fd2394a5cbdcca4acd37b142a4a81df122d6b48bccda1c593bf68`, while
the Node-produced fixture carries older `95cd77c6833ef392311a11c7d76e751b3dc01dcd5bbb55ee9b06b8a87327d554`.
The human authorized a bounded fixture-provenance correction. It cannot begin
until the human closes `UnityValidationProject`.

After confirmation, reuse one `FAST_SUBAGENT / v0.3.coder.standard` child.
It may generate one current fixture and write only JSON/.meta, then execute
one direct source/fixture check and one four-path diff-check, freeze identities,
and return to Planner. No production/package metadata edit, Unity operation,
Verifier, Git publication, or automatic second EditMode attempt is authorized.

Current status: `RUNTIME_CONTRACT_FIXTURE_REGEN_AUTHORIZED / HUMAN_CLOSE_PENDING`.
Next action: await human closure confirmation, then dispatch the bounded child.

## Runtime-Contract Fixture Drift FIX Attempt - 2026-09-18

The one Node fixture-generation attempt was consumed but the surrounding
PowerShell collector matched the bracketed fixture marker with wildcard
semantics, so it failed to retain the output sample. No fixture write or
post-generation evidence occurred; no retry is available in this attempt.

Current status: `BLOCKED / MARKER_COLLECTOR_CONSTRUCTION_FAILURE`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: decide whether to authorize a new bounded generation attempt with
literal marker parsing before any Unity/EditMode retry, Verifier, or Git action.

## Runtime-Contract Fixture Drift FIX Retry - 2026-09-18

The literal-marker retry reached the Node output and decoded its sample, but
the generated runtime-contract SHA remained stale `95cd77c6...`, not the
current Package manifest SHA `a3cbc22b...`. The attempt stopped before writing
JSON/.meta; no post-generation evidence ran and no retry remains.

Current status: `BLOCKED / NODE_FIXTURE_RUNTIME_CONTRACT_PROVENANCE_MISMATCH`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: reassess the reviewed Node/Package authority before further
fixture generation or any Unity, Verifier, or Git action.

## Route A - Human Decision and Authorization - 2026-09-18

Decision: `ACCEPT ROUTE A`.

The current Package `Payload~/payload-manifest.json` is the sole runtime
contract authority. The Node harness may stage/read that reviewed manifest and
directly required generation files for the temporary fixture, while continuing
to normalize only environment-specific identity leaves. The stale synthetic
contract path is not an acceptable source for the C# fixture.

Authorized files:

- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests/Editor/OwnerIdentityV2Status.json`
- `com.rice.ai-codedb/Tests/Editor/OwnerIdentityV2Status.json.meta`

One bounded continuation is authorized: implementation, one focused Node
generation, one source/fixture check, one three-path diff-check, and one
canonical identity calculation. Stop on any new independent cause or scope
expansion. No Unity, EditMode, Verifier, commit, push, publication, or release
action is authorized by this route.

## Route A Completion - 2026-09-18

The one authorized Route A continuation completed without a new cause or
scope expansion. The allowlisted Node harness now derives the temporary
fixture runtime contract from the reviewed Package manifest and stages its
Package-owned stable wrapper; no synthetic manifest is authored. Only the
three allowlisted paths were in scope, and the `.meta` bytes remained stable.

Evidence completed exactly once: Node fixture generation `PASS`, bounded
source/fixture check `PASS`, three-path `git diff --check` `PASS` with no
output, and canonical identity calculation. Package/fixture runtime-contract
SHA is `a3cbc22b0b3fd2394a5cbdcca4acd37b142a4a81df122d6b48bccda1c593bf68`;
fixture JSON SHA-256 is
`9448aac81361b6c27486176094c08b5ddef78f3722ae167225e93a301f380aef`.
Identities are 42-path
`06775b1319ea1c60ed2bb4100300897f0344903822dfd8a5f27acb874e074a68` and
ordered four-path `a3370be9a5a09949ac10ac1ebc4a01820e6b715130705142d253eab3d026d323`.

Current status: `ROUTE_A_COMPLETE / PLANNER_REVIEW_REQUIRED`.
Next actor: `UnityCodeDB v0.3 Planner`.
Next action: review/admit this frozen identity and decide the separate
human-owned focused EditMode handoff. Unity, Verifier, commit, push,
publication, and promotion remain closed.

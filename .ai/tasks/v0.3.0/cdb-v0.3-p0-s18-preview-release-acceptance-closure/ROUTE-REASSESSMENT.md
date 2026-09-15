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

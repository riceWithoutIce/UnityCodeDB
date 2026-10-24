# Coder stable result: removal preflight namespace contract

Date: 2026-10-14. Disposition: PASS_WITH_LIMITS / STABLE_FOR_READ_ONLY_VERIFIER.
Base d88a101f15d21f916cbee9578ab887aa1ea862cd. No commit or delivery.
Six source/test files changed, 467 insertions / 21 deletions; index remains empty.
Dedicated SOURCE-SHA256 file binds all six to the exact-Package evidence overlay.

## Result and contract

VERSIONED_V2 now authenticates bounded terminal operation-history, exact matching
canonical operation and paired stale-owner quarantine independently of current
operational owner files. Missing both current owner records is admitted only with
existing immutable selected identity and paired COMMITTED activation. One current
owner record, unknown paths, redirects, malformed/foreign/conflicting operation or
owner evidence, missing child identity, timeout, and live/reused/unverifiable PID
remain blocked. No Ready/Install authority is added. Legacy/v1 helper stays strict.

Preserved proof is separate from Inventory/Delete targets, included in handoff
fingerprints and existing durable intent authority_fingerprint. Normal transaction
checks original preserved bytes before commit and after commit; restart terminal
validation recomputes the extant namespace proof. REMOVEINTEGRATION COMMITTED
journal recovery now requires Package authority and terminal validation before
journal cleanup. Missing whole namespace with only legacy schema1 intent and no
in-memory inventory is explicitly BLOCKED, not a preservation PASS. Parent
approved retaining this ambiguity without schema expansion.

Lifecycle caches a concrete bounded/redacted backend refusal beside command
summary. It rejects incomplete output and malformed handoff before Available.
Existing action backend remains final handoff identity/time authority. UI
consumption is the existing StatusSnapshot migration-detail path; layout unchanged.

## Evidence executed

Evidence root: .artifacts/tests/s29-removal-namespace/coder-a1.

- PowerShell syntax for all three changed scripts and scoped git diff --check PASS.
- Exact source/overlay hashes match all six. Payload is copied only from delivered
  d88a10 Package; predecessor is exact post-install poc42 Package. No dirty Payload
  generation or mutation. Overlay canonical Package retains original payload.
- Original-byte Unity csc Editor and Editor.Tests semantic compilation PASS, exit0.
  Logs Rice.AICodedb.Editor-compile-a1.log and Tests equivalent; successful compile
  logs were refreshed during source-test completion. No compiler failure occurred.
- scenario-a4.log: PASS52, retained fixture scenario-a4/r-62aa9fb9. Production
  functions and exact extracted production preflight handler exercised retired
  selected42/target43, current/default helper controls, safe success+failed history,
  duplicate-key/malformed/foreign/conflicting/history/count/byte-budget refusal,
  absent child, timeout, live/reused/unknown PID, partial stale/current pairs,
  unknown entries/nested directory and junction refusal. Read-only digest stable.
- Exact handoff producer/consumer; evidence/config/selection drift, lock-time and
  before-mutation drift reject; injected first-write fault rolls back. Copied
  confirmed removal reaches UNINSTALLED/PENDING, all five original history/stale
  files retain identical hashes; terminal drift rejects, whole namespace absence
  after restart blocks; COMMITTED recovery drift preserves journal, valid recovery
  clears transaction journal only.
- wrapper-original-a1.log PASS27; wrapper-before-install-a1.log PASS32. Both
  previous historical observation routes preserve original failed intent bytes.
- Roslyn exact-member binding audit + seam-run-a1.log PASS: original NUnit
  assertions, production emitted refusal -> precise Lifecycle diagnostic/cache ->
  existing UI StatusSnapshot item detail; malformed/incomplete/timeout permit
  refusal and production handoff consumption. Exact extracted-method scope only:
  no native initializer rewrite or assertion replacement. Full native Lifecycle
  / Unity EditMode execution remains NOT_RUN.
- protected-before.txt equals protected-after.txt across 2844 entries: real S29
  Packages/.codex/AIWork, local Manager receipts, dirty Payload, owner fixture and
  exact old/target Packages. Zero protected differences.

Synthetic seams: prerequisite result, explicitly listed process identity PID,
PocFixture candidate verification. Native product runner throws. Copied fixtures
only; native product children=0, no actual process inspector/IPC/Unity operation.
Harness PowerShell/csc/Roslyn/Mono processes are test tooling, not product children.

## Attempts, limits and unrun gates

scenario-a1 attempted under PS7 and stopped before scenario execution at strict
payload JSON decoding (`payload manifest must contain one JSON object`); its
redirected log is empty, the exception is retained in tool transcript. One
mechanical routing correction used Windows PowerShell5.1, matching prior evidence.
scenario-a2 PASS42, a3 PASS46 and a4 PASS52 are separate preserved logs/fixtures;
later attempts add declared safety/consumer coverage, not repair a product failure.
No independent new product cause or failing semantic scenario occurred.

A bounded read of real history metadata accidentally printed all entries once and
the tool truncated output. This is an output-envelope breach, not complete history
validation. It performed no writes/reader execution/process observation. No claim
of actual history admission is based on it.

Not all real historical files are demonstrated safe: child=null blocks; records
bound to other selected instances/generations block. Actual history count/aggregate
may hit bounds. No cleanup or broad ignore was added. Therefore isolated PASS does
not assert the actual Manager removal button is now available.

Full v1/partial-v1 production transaction regression, explicit stale-pair count
overflow, and committed recovery after a real crash are NOT_RUN. Existing strict
v1/default inventory controls ran; existing implementation was not broadened.
Before-install wrapper observation control ran, but copied removal with that
additional failed-before-install intent was not separately executed. A final broad
path-provenance script was not run; exact overlay/source equality and existing
immutable selection/activation reads supplied the bounded provenance evidence.
These limits are handed to Verifier, not silently labeled full-suite PASS.

NOT RUN: Unity/MCP/CUA/BatchMode, live product reader/preflight/Probe/Ensure/IPC,
real Remove/Install/Upgrade/migration, real child/owner start or stop, cleanup,
environment settings, commit/export/reference switch/push/release. Source accepted
state, target readiness, real removal and overall S29 completion are not claimed.
CleanupMono deferred, earlier MissingPrerequisite unattributed.

Coder terminates at this stable snapshot. Parent admits hashes, dispatches the
already-approved independent read-only Verifier, receives questions and waits for
its terminal result. Consolidate findings once for user ACCEPT/FIX/DEFER/STOP.

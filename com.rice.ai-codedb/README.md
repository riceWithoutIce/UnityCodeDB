# Rice AI CodeDB

<p align="center">
  <img src="Documentation~/images/codedb-icon.svg" width="96" alt="Rice AI CodeDB icon">
</p>

<p align="center"><sub>"Memes Comment Reply" icon by <a href="https://streamlinehq.com">Streamline</a>, licensed under <a href="https://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>.</sub></p>

`com.rice.ai-codedb` is an Editor-only Unity Package Manager package for the
reusable CodeDB Manager, project-local indexing workflow, Shader/HLSL adapter,
and bounded MCP discovery surface. The `0.2.5-preview.3` / `poc.30` validation
prerelease targets Unity `2022.3` on Windows; stable remains `0.2.4`.

Install the validation prerelease from the repository subfolder with
`https://github.com/riceWithoutIce/UnityCodeDB.git?path=/com.rice.ai-codedb#v0.2.5-preview.3`.
Use `#main` only when intentionally validating unreleased development changes.

The `0.2.5-preview.3` package keeps a tracked stable wrapper and byte-exact
v0.2.2 compatibility files under `AIWork/codedb/`, then materializes immutable
implementation generations under ignored
`AIWork/.runtime/codedb/host/generations/`. An atomic `current.json` selects the
active generation. Generated provider binaries, configs, indexes, logs,
watcher state, generation leases, and rollback evidence remain under ignored
`AIWork/.runtime/`. The external `killop/codedb-mcp` provider and Node.js are
prerequisites and are not bundled.

`Payload~`, `Tools~`, and `Tests~` contain a 43-target host-payload
materialization POC. Its canonical payload is intentionally limited to the
shared PowerShell helper, runtime preparation and TOML template, the
project-neutral watch coordinator, watch-config generator and watch manager,
the Shader/HLSL adapter builder and persistent worker, and the project-neutral
MCP wrapper for the bounded Discover Read surface. A shared host-use gate gives
the wrapper and watcher daemon PID-bearing leases. It also includes the ignore
template plus project-neutral provider guidance, verification, refresh, and
controlled index-clear entries, provider and Shader/HLSL probes, the read-only
freshness check, owner-selective refresh-if-stale, MCP registration draft
emission, and project-config validation. The tool defaults to
read-only `DryRun`. `Repair`, `Sync`, and `Remove` require the Manager's
second-level project mutation confirmation. `-PocFixture` retains the fixed
run-id, fixture-marker, and reparse-point constraints used only by the test
suite. Production actions do not accept version-control metadata or an
authorization document. They reject unowned or drifted files and use a
deterministic UTF-8, LF-only payload ownership marker.
The schema-2 marker owns only tracked `AIWork/codedb/` files; ignored generation
files and `current.json` are validated from their runtime manifests and pointer
instead of being inferred from tracked adoption. Schema-1 markers remain
readable for upgrades. Semantically valid but non-canonical marker JSON is stale
and Sync rewrites only that marker to the canonical serialization. Sync and Remove
publish a durable transaction journal before their first host mutation, recover
interrupted transactions in a new process, reject recovery over third-state
external changes, and use same-volume atomic replacement for existing managed
files. Lower payload sequences and same-sequence payload identity or hash
collisions are conflicts for both Sync and Remove.
Before recovery or planning, strict Sync and Remove publish a
materializer-active marker, hold existing watcher management locks, prune only
dead host-use leases, and reject live MCP, coordinator, provider,
adapter-worker, or adapter-build PIDs. Owned lower-version Upgrade uses a
separate generation path: it verifies byte ownership, publishes an immutable
generation, switches the pointer at a request boundary, and rolls back the
selection and watcher if readiness fails. A completely empty managed scope is
eligible for automatic first adoption; unknown same-name content still blocks
with zero writes.
Published flat payloads that predate the live generation transition can instead
report `REDEPLOY_REQUIRED`. The Manager's `Redeploy host` action refreshes owner
status, accepts only the reviewed `poc.9`, `poc.16`, and `poc.20` identities,
gracefully stops a recognized legacy watcher, and re-verifies every owned byte
before using the same durable Sync transaction to publish the current flat
payload, immutable generation, pointer, and marker.
External MCP clients remain user-owned and are never terminated. Repair
classifies their immutable-generation leases against the exact planned mutation
paths: non-conflicting current or historical generations remain pinned for the
existing session, while an intersecting or unprovable closure blocks before the
related write. The workflow regenerates the ignored runtime config but preserves
Provider binaries, indexes, adapters, MCP registration, unowned host files, and
unrelated project content.

`Repair CodeDB` is the end-user recovery path. One confirmation runs the
Package-owned preflight, bounded Host reconstruction or quarantine, pointer and
rollback repair, watcher handoff, policy preservation, project MCP registration
merge, and verification. It changes only `[mcp_servers.<project-slug>]`, keeps
unrelated TOML content and line endings, and creates a recoverable backup before
rewriting an existing config. Invalid TOML, duplicate or ambiguous target
tables, path escapes, unknown Host content, and managed drift fail closed.
Results are `REPAIRED`, `PARTIALLY_REPAIRED`, or `BLOCKED`; a repaired
registration applies to new client sessions and does not claim hot reload.
Retaining a valid non-conflicting MCP generation is still `REPAIRED` and does
not require the user to wait for drain or click Repair again.

Unity supplies the Package's resolved physical location. The Editor and
materializer do not inspect installation URLs or assume a writable embedded
directory. Cached, local, embedded, and registry-backed Packages use the same
payload-relative logic, and the Package source is never mutated. Likewise,
DryRun, automatic Upgrade, Repair, Verify, advanced Sync, and Remove do not
detect or invoke a project version-control system.

The package materializer is wired into the Manager Setup tab for read-only
status/DryRun, strict Verify, controlled legacy Redeploy, confirmed advanced
Sync/Remove, and the single user-facing `Repair CodeDB` recovery action. Manager
status distinguishes `INSTALLING`, `SWITCHING`, `CURRENT`, `DRAINING`,
`ROLLBACK`, `SETUP_REQUIRED`, `UPDATE_REQUIRED`, `REDEPLOY_REQUIRED`, conflict,
active host-use blockers, and check-failed outcomes. It shows selected/watcher generations,
bootstrap protocol, legacy session count, and all active owners. The Index view
separates the persistent `Start with Unity Editor` policy from Start, Stop, and
Restart commands associated with the Editor cohort present when they are
issued; automatic host updates have an independent persistent policy. DryRun
reports every active MCP or watcher owner before a confirmed mutation is
attempted. Existing runtime,
index, watch, and probe actions continue to resolve the materialized host paths.
This package still does not include the external CodeDB provider, host
acceptance probes, MCP client configuration, generated project data, or any
host-owned compatibility entry. Those ownership boundaries remain unchanged.
The standalone fixture contains assertions for a disabled formal watch config,
interactive Editor-owned
post-Setup startup, persistent startup policy, explicit Start/Stop/Restart
command-time Editor-cohort ownership,
same-project Editor lease sharing, final-lease shutdown, wrapper read-only
attachment, read-only provider guidance, ignored-runtime
verification, formal `--no-watch` refresh, generated ignore parity, and
index-only cleanup against an isolated runtime-built provider executable. It
also checks that wrapper-local C#/Shader reads return only the requested line window,
cap one read at 200 lines, reject resolved paths outside the Unity root, and
limit every tool or error text response to 64 KiB with explicit truncation. It
normalizes the legacy `path` search alias to `path_glob`, filters Provider hits
again at the wrapper boundary, and verifies no-language directory searches
merge Provider and Shader lanes with deduplication and one global limit. It
appends a bounded, machine-readable `[TIMING]` footer to every tool response,
including coordinator queue, Provider process/core, adapter, merge, local-read,
attempt-count, end-to-end, and uncapped-body byte metrics. The footer remains
present when the body is truncated to the 64 KiB response ceiling. It also
routes Provider searches through the ready project coordinator's persistent
MCP process using a token-authenticated, 64 KiB-limited local pipe request.
The coordinator exposes only the three read-only search tools. Disabled,
Editor-offline, starting, stale, or unavailable states return a stable reason
without starting a Provider; wrappers never call `Ensure` or use a one-shot
fallback. The shared path serializes distinct Provider work and joins identical
in-flight tool/argument keys without implicit batching. Timing identifies the
Provider route, whether work was shared, actual execution attempts, and real
queue wait. It also
validates provider and adapter status/search/read probes, hit/no-hit
reporting, `OK`/`STALE`/`UNKNOWN` freshness, exact fresh no-op behavior, and
independent provider-only or adapter-only refresh. It also verifies copy-only
project-level registration guidance and read-only project-config validation
without changing `.codex/config.toml` or any other fixture file. The fixture
suite also checks hard-crash recovery and concurrent readers observing only
complete old or new file hashes. The v0.2.3 coverage adds immutable generation
publication, request leases, same-transport Unity offline/reopen behavior,
v0.2.2 migration with live legacy owners, watcher handoff rollback, automatic
journal recovery, PID-reuse handling, manual state, and exact candidate/LKG
Remove cleanup. It also checks active MCP and watcher refusal for strict
mutations, legacy watcher-state refusal, normal lease cleanup, hard-kill stale
lease recovery, legacy adoption confirmation, interrupted recovery,
downgrade/sequence collision refusal, and exact LF-versus-CRLF conflict
behavior. Payload hashes remain byte exact and
no payload-file EOL normalization occurs in the materializer. Ownership markers
are serialized canonically as LF-only JSON. The first reviewed tracked-host
adoption is recorded in the host handoff; real tracked-host Remove/rollback
also passed with exact host restoration. v0.2.2 completed real Unity import,
74/74 package EditMode tests, and wide/minimum/docked visual acceptance.
The `0.2.5-preview.2` coverage retains the exact poc.21 coordinator-state
handoff, makes package-reload reconciliation independent from watcher policy,
treats legacy-session drain as ready and non-blocking, and validates direct or
skipped upgrades from the published `poc.22` through `poc.28` generations. It
also accepts canonical stale prior-generation coordinator paths during Editor
startup while rejecting paths outside that generation, and keeps failed
automatic-upgrade status and retry guidance visible in the Manager. It adds the
legacy Redeploy path for published `poc.9`, `poc.16`, and `poc.20` flat
payloads, including Manager-owned watcher shutdown, while preserving Provider
and index state.
The `0.2.5-preview.3` validation prerelease adds tracked-adoption recovery for schema-1 and
schema-2 markers with absent runtime, accepts a fully validated `poc.29` as a
usable previous generation during automatic handoff, rejects partial,
unmanifested, or invalid runtime candidates without writes, and gates Host
commands on validated generation readiness. Its direct and skipped materializer
matrix extends through published `poc.29`. It also covers one-click Repair,
project MCP merge/refusal, identical action outcomes with no VCS metadata or
Git/SVN metadata, zero VCS command invocation, and cached/local/embedded
read-only Package layouts. Local Unity EditMode and Manager UI acceptance passed;
third-party Package-only acceptance for preview.3 remains a separate release gate.
An earlier representative third-party project passed no-click upgrade,
same-transport Editor restart,
manual lifecycle controls, Domain Reload, Play Mode, normal-permission queries,
and BatchMode isolation. Live two-project concurrency and Elevated Unity with
a NotElevated MCP client are accepted deferred validation risks tracked in the
v0.2.5 roadmap; this release does not claim those two matrices passed.

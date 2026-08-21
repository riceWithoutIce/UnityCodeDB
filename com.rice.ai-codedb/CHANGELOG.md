# Changelog

## 0.2.5-preview.5 - 2026-08-14

- Added explicit `INSTALLED -> CONFIGURED -> MCP_AVAILABLE -> READY` product
  layers. Automatic convergence, confirmed Reinstall, and Install now run a
  Package-owned wrapper probe from the Unity project working directory and
  require MCP initialize, the exact bounded tool list, a usable project status
  from `codedb_status`, and a successful bounded `codedb_text_search` before
  reporting Ready.
- Added a shared mutation preflight for Node.js `22.x` or `24.x` and the
  reviewed machine Provider `0.5.0`. Its strict manifest binds the Provider
  commit, executable hash, protocol, source, and supported Package range;
  missing or incompatible prerequisites stop before project writes and do not
  enter an automatic Repair loop.
- Added versioned readiness snapshots and mutating command results with one
  outcome, phase, reason code, broad mutation-scope list, cleanup state, and
  next action. Lifecycle and Manager readiness continue to require all product
  layers rather than inferring success from an installed Host alone.
- Reduced the ordinary Manager surface to `Starting`, `Ready`,
  `Needs attention`, and `Uninstalled`, with at most one contextual primary
  action. Recovery is labeled `Reinstall CodeDB`; project Uninstall remains in a
  separately confirmed secondary menu, while generation and process controls
  remain diagnostics.
- Moved Manager actions and lifecycle materializer work off synchronous UI and
  Play-transition paths. Compilation, Package update, and Play entry defer
  convergence instead of waiting for PowerShell, Node, locks, or a complete
  status scan.
- Fixed schema-1 Host-use lease classification so a PID reused by an unrelated
  process is proved stale from process start identity and reclaimed without
  inspecting the process name or terminating that process. Unavailable or
  ambiguous identity remains fail-closed.
- Kept genuine external MCP sessions alive and preserved their exact immutable
  execution closure while Reinstall publishes a disjoint current generation and
  registration for future sessions. Deferred closure cleanup is reported as
  `REINSTALLED / PENDING` and completes automatically after leases drain.
- Added the confirmed user-level `Uninstall CodeDB from Project` workflow. It
  persists `UNINSTALLED` before cleanup, preserves the target MCP namespace as
  state-bound inert TOML comments, removes proved-owned Host/runtime state, and
  prevents lifecycle or Package reload from reinstalling CodeDB. Custom keys,
  `tools.*`, comments, BOM/EOL, unrelated configuration, and active external MCP
  sessions remain preserved.
- Added one confirmed `Install CodeDB` action for an uninstalled project. It
  clears the desired-state override only after the shared instance path restores
  and verifies Host plus MCP registration under the same materializer lock.
  Automatic cleanup rechecks the same persisted state identity, records a
  terminal `COMPLETE` state, and cannot delete a successfully installed Host.
  Repeated Uninstall, automatic cleanup, crash/retry, and Install are covered as
  idempotent and deterministic concurrent transitions.
- Advanced the unpublished candidate to immutable generation `poc.33` with the
  reviewed Provider distribution `0.5.0-28e3912` at upstream commit
  `28e3912d5cd67ff3499734984f3e3d626a204796`. Preserved `poc.31`/`poc.32` and
  earlier closures remain byte-immutable for lease drain, rollback, and
  reviewed upgrade coverage.
  The Package-owned probe does not replace the still-required new Codex Desktop
  task and standalone third-party Package-only acceptance.

## 0.2.5-preview.4 - 2026-08-13

- Fixed `Repair CodeDB` MCP registration merge for standards-compliant target
  descendant tables such as `[mcp_servers.<project>.tools.<tool>]`, including
  parent-first, child-first, and child-only declarations.
- Limited CodeDB ownership to the target server table's direct `command`,
  `cwd`, `args`, and `startup_timeout_sec` keys. Custom direct keys and
  descendant tables remain byte-preserved with comments, order, BOM, and line
  endings, while real target or managed-key namespace conflicts still fail
  closed without Host or MCP configuration writes.
- Reused the published immutable `0.2.5-preview.3` / `poc.30` Host closure.
  Preview.4 changes Package-owned materializer behavior and UPM metadata only;
  it does not fabricate a new Host generation or rewrite published hashes.

## 0.2.5-preview.3 - 2026-08-13

- Split tracked project adoption from ignored Host runtime ownership with a
  schema-2 marker. Existing schema-1 markers remain readable, while missing or
  valid previous runtime generations can now be reconstructed automatically
  without being misclassified as tracked-file drift.
- Added validated `Previous` generation state, target-correlated upgrade
  history, full last-known-good validation, and a centralized readiness gate
  that prevents every Host command from resolving or launching an unavailable
  script path.
- Added one confirmed `Repair CodeDB` workflow that reconstructs or quarantines
  only reviewed Host state, preserves Provider/index/adapter/config/policies and
  classifies active MCP leases against exact mutation paths. Non-conflicting
  current or historical immutable generations, leases, and processes are
  retained without Stop while intersecting or unprovable closures block before
  recovery writes. Repair atomically merges only the current project MCP table
  with recoverable backup and fail-closed TOML validation.
- Removed version-control metadata, commands, and authorization JSON from the
  current materializer and Editor contracts. Empty-scope adoption, Upgrade,
  Repair, Verify, advanced Sync, and Remove now behave identically with no VCS,
  Git metadata, or SVN metadata and with VCS executables absent from `PATH`.
- Resolve Package tools from Unity's loaded Package location and payloads
  relative to the Package-owned materializer. Cached, local, and embedded
  read-only layout fixtures verify Package source immutability.
- Advanced the immutable Host generation to `poc.30`, retained the published
  `poc.29` closure, and extended direct and skipped upgrade coverage through
  `v0.2.5-preview.2`.

## 0.2.5-preview.2 - 2026-07-31

- Made `Redeploy host` a complete Manager workflow for supported flat legacy
  Hosts. Each click refreshes owner status, gracefully stops a recognized legacy
  watcher, revalidates ownership immediately before mutation, and completes the
  generation/config transition without asking the user to run project scripts.
- Kept external MCP clients fail-closed and user-owned: connected MCP sessions
  receive focused disconnect guidance and are never terminated by the Manager.
- Advanced the immutable Host generation to `poc.29`, retained the published
  `poc.28` closure, and extended direct/skipped upgrade coverage through
  `v0.2.5-preview.1`.

## 0.2.5-preview.1 - 2026-07-31

- Added a controlled `Redeploy host` action for byte-exact package-owned flat
  payloads from published `poc.9`, `poc.16`, and `poc.20` releases that cannot
  use the live generation-upgrade path. Redeploy requires all MCP and watcher
  owners to stop, rejects drift and staged ownership paths, publishes the
  current generation transactionally, and regenerates only the ignored runtime
  config while preserving Provider binaries, indexes, adapters, registration,
  and unrelated project files.
- Advanced the immutable Host generation to `poc.28`, retained the published
  `poc.27` closure for generation upgrade and rollback safety, and extended
  direct/skipped upgrade coverage through stable `v0.2.4`.

## 0.2.4 - 2026-07-30

- Promoted the automatic package-reconciliation, same-transport Editor restart,
  explicit manual lifecycle controls, truthful upgrade status, and complete
  Package-version header validated throughout the v0.2.4 preview line.
- Advanced the immutable Host generation to `poc.27` so stable package identity
  does not rewrite published `poc.26` bytes, and extended supported direct and
  skipped generation upgrades through `poc.26`.
- Recorded the live two-project concurrency matrix and Elevated Unity with a
  NotElevated MCP client as explicit `v0.2.5` deferred validation risks. Stable
  `0.2.4` does not claim those two environment-dependent checks passed.

## 0.2.4-preview.4 - 2026-07-30

- Recovered automatic Editor startup from a dead prior-generation coordinator
  whose recorded generation adapter paths still point to its immutable
  generation. Canonical project-local paths are accepted; mismatched roots,
  runtime identity, adapter configuration, and out-of-generation paths remain
  fail-closed.
- Advanced the immutable host generation to `poc.26` and extended direct and
  skipped automatic-upgrade coverage through the published `poc.25`
  generation without stopping Unity, Codex, MCP, or active generation leases.
- Kept the native Unity tab title at `CodeDB Manager`, moved the complete
  Package version to a right-aligned header row, and made current persisted
  `INSTALLING`, `SWITCHING`, `ROLLBACK`, and `CHECK_FAILED` phases take
  precedence over generic `UPGRADE_READY` guidance. Failed updates expose an
  explicit `Retry update` action while in-progress phases suppress duplicate
  update commands.

## 0.2.4-preview.3 - 2026-07-29

- Restored no-click generation-to-generation upgrades by declaring the exact
  package-owned `poc.22`, `poc.23`, and `poc.24` immutable target closure in
  the payload retirement allowlist.
- Kept prior generation files and live leases intact during automatic pointer
  handoff, while preserving strict reviewed cleanup through Remove after lease
  drain.
- Added direct and skipped-upgrade regression coverage for `poc.22`, `poc.23`,
  and `poc.24` to `poc.25`, including a live `poc.23` generation lease.

## 0.2.4-preview.2 - 2026-07-29

- Reconciled owned host generations automatically after package compilation
  and script reload, independently from manual watcher Start/Stop policy.
- Deferred reconciliation while Unity is compiling or updating packages, then
  retried through the normal single-writer lifecycle path.
- Kept `DRAINING` fully usable and non-blocking, with no requirement to close
  legacy MCP sessions. The Manager now observes automatic upgrades and lease
  drain asynchronously without requiring `Update now` or manual refresh.
- Advanced the immutable host generation to `poc.24` for a real no-click
  `preview.1` to `preview.2` third-party upgrade test.

## 0.2.4-preview.1 - 2026-07-29

- Fixed automatic watcher handoff from the real v0.2.2/poc.21 coordinator
  state, whose legacy schema has no `generation_id`. The selected generation
  now classifies that state as legacy, skips nonexistent generation leases,
  and switches under the materializer handoff lock.
- Suppressed repeated automatic retries after a deterministic `CHECK_FAILED`
  for the current generation. Manual `Update now` remains available, and a
  newer package generation automatically clears the suppression boundary.
- Added exact legacy-schema handoff coverage and advanced the immutable host
  generation to `poc.23` without changing the stable v0.2.3 bootstrap wrapper.

## 0.2.3 - 2026-07-29

- Added immutable project-local host generations and atomic `current.json`
  selection. Owned v0.2.2 installations can upgrade automatically while
  existing MCP sessions drain, with durable rollback evidence and no process
  termination of Unity, Codex, or the MCP client transport and no manual lease
  cleanup. Watcher handoff gracefully stops the old backend after its request
  leases drain.
- Kept the stable MCP stdio bridge alive while Unity is offline. Tool calls pin
  one generation, acquire generation-scoped leases, and reattach to the
  Editor-owned backend after Unity reopens in the same client session.
- Split persistent `Start with Unity Editor` policy from Start, Stop, and
  Restart commands scoped to the Editor cohort present when they are issued.
  Added an independent automatic-host-update policy, multi-owner diagnostics,
  generation status, draining state, and last-known-good/upgrade-state
  visibility in the Manager.
- Hardened multi-Editor upgrade election, watcher handoff, crash recovery,
  PID-reuse handling, legacy watcher identity checks, and transactional Remove
  cleanup for current, candidate, and last-known-good generations.

## 0.2.2 - 2026-07-28

- Made Ready coordinator queries reliable across Windows elevation boundaries
  by treating permission-denied PID probes as indeterminate, confirming health
  over the authenticated pipe, retrying short connection races, and returning
  bounded unreachable/timeout/protocol diagnostics without Provider fallback.
- Validated existing generated Provider configs before reuse. Missing or
  invalid `[logging].flush_interval_ms` now reports `UPDATE_REQUIRED` without
  rewriting runtime state; regeneration remains an explicit `-Force` action.
- Split Manager host-payload truth into `SETUP_REQUIRED`, `UPDATE_REQUIRED`,
  conflict, and active host-use blocker outcomes, including pre-Sync PID
  guidance from read-only DryRun.
- Added a dedicated padded tab icon and sourced the window title version from
  Unity Package Manager metadata with a versionless refresh fallback.

## 0.2.1 - 2026-07-28

- Pinned project MCP registrations to
  `cwd = "."`, making the installed wrapper path authoritative for Unity-root
  resolution, validating Unity markers before host-use writes, rejecting
  direct Provider registration, and preserving Provider `regex` arguments.
- Made interactive Unity Editor sessions the sole backend demand owners through
  heartbeat leases. The final valid lease stops the coordinator, Provider, and
  adapter; BatchMode stays inactive and manual disablement remains persistent.
- Removed Manager and wrapper lifecycle side effects. Offline status observes
  stale leases without reclaiming them; wrappers no longer call `Ensure` or
  launch one-shot Providers, and disabled, Editor-offline, or starting states
  return stable reason codes with zero Provider attempts.
- Moved Editor PID start-identity checks off the coordinator event loop and
  added bounded Windows retries for atomic state replacement during concurrent
  status reads.
- Validated automatic startup, persistent Pause/Start, Domain Reload continuity,
  cold restart, and final-Editor shutdown in Unity 2022.3.20; the package
  EditMode suite now passes 74/74 tests.

## 0.2.0 - 2026-07-26

- Added the attributed Streamline Plump Free brand icon to the Manager window,
  package documentation, and repository presentation without adding a runtime
  vector-graphics dependency.
- Made project-local automatic refresh the normal post-Setup state. Manager and
  MCP wrapper use now ensure the coordinator is ready, repair stale indexes
  before startup, preserve lifecycle ownership during recovery, and expose a
  persistent Pause/Resume workflow while the formal provider config remains
  `watch=false`.
- Enforced wrapper-local bounded reads for C# and Shader/HLSL source. Reads now
  resolve inside the Unity root, honor an exact requested window capped at 200
  lines, and all tool or surfaced error text is capped at 64 KiB with explicit
  truncation.
- Normalized search `path` aliases to `path_glob`, parsed the Provider's native
  search/text-search/find formats, reapplied scope filtering in the wrapper,
  and merged no-language directory results across Provider and Shader lanes
  with deduplication and one global limit. Context now consumes the same hits.
- Added a bounded machine-readable timing footer to every wrapper tool response.
  It separates one-shot queue, Provider process/core, Shader adapter, merge,
  local-read, attempt-count, end-to-end, and uncapped-body byte evidence while
  preserving the footer inside the existing 64 KiB response ceiling.
- Extended the existing watch coordinator with a token-authenticated read-only
  query proxy for search, text-search, and find. Ready wrappers now reuse the
  coordinator-owned persistent Provider MCP process, while paused, starting,
  stale, or unavailable states retain the one-shot fallback.
- Added project-level single-flight query ownership. The coordinator serializes
  distinct Provider calls, joins identical concurrent tool/argument keys, and
  reports route, shared-work, execution-attempt, and real queue-time evidence.
  Graceful Stop now drains query sockets by terminating the Provider before
  awaiting connection closure.

## 0.1.0 - 2026-07-26

- Prepared the reusable Editor assembly for standalone Git URL installation.
- Moved the CodeDB EditMode tests into the package test layout.
- Kept host acceptance, process tooling, runtime data, and project MCP config
  outside the package.
- Added an isolated host-payload materialization POC with explicit
  dry-run, verify, sync, conflict, rollback, ownership, and remove behavior.
- Integrated host-payload status, DryRun, Verify, and explicitly authorized
  Sync/Remove into the Manager Setup tab without generating or persisting
  production authorization.
- Added EditMode coverage for current, not-installed, stale, conflict, and
  failed materializer status plus read-only and mutation argument boundaries.
- Expanded the canonical POC payload with the project-neutral watch coordinator.
- Added the Shader/HLSL adapter builder and persistent worker to the canonical
  POC payload with host-path execution coverage.
- Added the project-neutral MCP wrapper with fixture coverage for tool discovery,
  Shader search/read, exclusion policy, and disabled-watch startup behavior.
- Expanded the canonical payload to nine files with the project-neutral
  watch-config generator and watch manager.
- Added an isolated runtime-built provider fixture covering formal
  `watch=false`, opt-in `watch=true`, Start/Status/Stop, lifecycle ownership,
  wrapper recovery, and final `DISABLED / STOPPED` behavior.
- Expanded the canonical payload to fourteen files with the ignore template,
  provider guidance, project verification, refresh, and controlled index clear.
- Added fixture coverage for read-only guidance, ignored-runtime verification,
  formal `--no-watch` refresh, generated `.codedbignore`, manifest creation,
  WhatIf preview, and index-only cleanup that preserves adjacent runtime owners.
- Expanded the canonical payload to eighteen files with provider and
  Shader/HLSL probes, a read-only freshness check, and owner-selective
  refresh-if-stale.
- Added fixture coverage for provider/adapter `OK`, `STALE`, and `UNKNOWN`
  states, exact fresh no-op behavior, provider-only and adapter-only refresh,
  and provider/adapter hit and no-hit probes.
- Hardened single-file and single-line PowerShell collection handling and made
  provider probe exclusions relative to the host Unity project root.
- Expanded the canonical payload to all twenty audited files with MCP
  registration draft emission and project-level config validation.
- Added fixture coverage proving the draft and validator use the
  project-neutral wrapper shape, preserve relative project paths, and do not
  modify `.codex/config.toml` or any other host file.
- Restricted POC mutations to explicit Git-ignored fixtures and constrained
  marker ownership to the audited production target allowlist.
- Added fixed fixture identity and reparse-point guards for mutation and test
  cleanup boundaries.
- Added durable fixture transaction journals and fail-closed next-process
  recovery for interrupted Sync and Remove operations.
- Replaced direct overwrite copies with same-volume atomic publication and
  added concurrent-reader coverage proving complete old-or-new file visibility.
- Expanded the canonical payload to twenty-one files with a shared host-use
  gate used by the MCP wrapper and watcher daemon.
- Added race-safe materializer exclusion through an active marker, PID-bearing
  MCP/watcher leases, watcher management locks, and legacy coordinator-state
  PID checks before recovery or planning.
- Added explicit `-ConfirmLegacyMcpStopped` adoption/upgrade confirmation and
  marker protocol versioning for the first transition from pre-gate wrappers.
- Added fixture coverage for active MCP and watcher Sync/Remove refusal,
  hard-kill stale-lease pruning, lease-free legacy watcher refusal, and exact
  host snapshot preservation across rejected gate attempts.
- Added active-Git-index inspection for the exact managed payload and ownership
  marker scope. DryRun reports staged conflicts; Verify, Sync, Remove, and
  interrupted recovery refuse them without blocking unrelated staged files.
- Made payload sequence monotonic for all mutations: older manifests cannot
  Sync or Remove newer installations, and same-sequence payload identity or
  file-hash collisions fail closed while package-only metadata updates remain
  valid.
- Fixed the tracked-host migration policy to byte-exact LF payload ownership.
  Added fixture evidence that CRLF host content is neither normalized nor
  adopted automatically.
- Added mutually exclusive tracked-host mutation authorization alongside the
  existing fixture mode. Authorization files are ignored, untracked, bound to
  one project root, Git HEAD, action, and complete payload manifest identity.
- Added an isolated nested-Git acceptance path covering missing, ambiguous,
  misplaced, tracked, malformed, and mismatched authorizations plus exact
  authorized Sync, read-only Verify, and authorized Remove.
- Reserved the fixed authorization directory outside transaction recovery while
  retaining fail-closed handling for every other unknown runtime artifact.
- Made ownership-marker serialization deterministic across operating systems:
  UTF-8 without BOM, LF-only line endings, one trailing LF, and automatic Sync
  repair for semantically valid non-canonical marker JSON.

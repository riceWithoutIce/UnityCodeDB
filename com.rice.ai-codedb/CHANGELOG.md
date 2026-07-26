# Changelog

## Unreleased

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

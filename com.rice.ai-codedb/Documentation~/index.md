# Rice AI CodeDB

<p align="center">
  <img src="images/codedb-icon.svg" width="96" alt="Rice AI CodeDB icon">
</p>

<p align="center"><sub>"Memes Comment Reply" icon by <a href="https://streamlinehq.com">Streamline</a>, licensed under <a href="https://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>.</sub></p>

Rice AI CodeDB is an Editor-only package for setting up and operating a
project-local CodeDB index from the Unity Editor.

The implemented post-setup automatic-refresh and shared-query baseline is
recorded in the [v0.2.0 roadmap](v0.2.0-roadmap.md). The Editor-owned lifecycle
and correctness release is recorded in the
[v0.2.1 roadmap](v0.2.1-roadmap.md). The Windows query, upgrade, and Manager UI
patch is tracked in the [v0.2.2 roadmap](v0.2.2-roadmap.md). Automatic host
generation upgrades, same-client Unity restart recovery, and explicit manual
controls were introduced in the `0.2.3` release. Stable `0.2.4` makes
package-reload upgrades and
transient Manager status observation automatic while keeping legacy sessions
usable, restores trusted migration from the published `poc.22` through
`poc.26` generations, and safely recovers canonical stale coordinator state
from a prior generation. The Manager keeps its native tab title compact,
shows the full Package version in the header, and presents a failed automatic
upgrade as `CHECK_FAILED` with a `Retry update` action.
The `0.2.5-preview.2` validation release makes controlled redeployment complete
inside the Manager for byte-exact `poc.9`, `poc.16`, and `poc.20` flat Hosts.
It refreshes owner status on click, stops a recognized legacy watcher safely,
keeps external MCP clients user-owned, and advances the immutable generation to
`poc.29` without changing the accepted deferred validation risks.
The `0.2.5-preview.3` / `poc.30` validation prerelease separates tracked
adoption from ignored runtime ownership, reconstructs absent or valid previous
runtime automatically, gates Host commands on a validated generation, and adds
one confirmed `Repair CodeDB` action for Host plus project MCP recovery. Package
behavior no longer depends on project version control or installation source.
The underlying design and stable acceptance decision are tracked in the
[v0.2.3 roadmap](v0.2.3-roadmap.md). Live two-project concurrency and Elevated
Unity with a NotElevated MCP client were explicitly deferred without being
marked passed; they remain in the
[v0.2.5 validation roadmap](v0.2.5-roadmap.md). Approved future work continues in the
[v0.3.0 bounded Discover Read expansion](v0.3.0-roadmap.md).

## Supported Environment

- Unity `2022.3`
- Windows Editor
- Windows PowerShell 5.1
- Node.js
- External `killop/codedb-mcp` / `codebase-mcp` provider

The package does not bundle or redistribute the external provider.

## Installation

Add the published package tag to the Unity project's
`Packages/manifest.json`:

```json
{
  "dependencies": {
    "com.rice.ai-codedb": "https://github.com/riceWithoutIce/UnityCodeDB.git?path=/com.rice.ai-codedb#v0.2.5-preview.3"
  }
}
```

Production projects should stay on stable `v0.2.4` until this validation
prerelease is accepted. The `#main` revision is reserved for intentional
validation of unpublished development changes.

## Manager

Open `Tools/Rice AI/Codedb/Manager`. The Manager provides five focused views:

- Overview: package, runtime, index, MCP, and watcher health.
- Setup: Host status, one-click recovery, and advanced payload diagnostics.
- Index: provider and Shader/HLSL refresh, probes, and watcher lifecycle.
- MCP: project registration guidance and validation.
- Policy: the active read-only and project-ownership boundaries.

## Project Layout

The package owns reusable code under the installed package path. The consuming
Unity project owns:

```text
AIWork/
  codedb/                         Tracked operational files
  .runtime/codedb/<provider>/     Ignored generated runtime
  .runtime/codedb/host/           Ignored generations, pointers, and leases
.codex/config.toml                Optional project-level MCP registration
```

The Manager can inspect package-owned host files without mutating the project.
When a byte-exact published flat payload is too old for live generation
migration, Setup reports `REDEPLOY_REQUIRED`. `Redeploy host` requires all MCP
and watcher owners to stop, then transactionally replaces only the recognized
`poc.9`, `poc.16`, or `poc.20` Host closure, publishes the current generation,
and regenerates the ignored runtime config. Provider binaries, indexes,
adapters, MCP registration, unowned files, and unrelated project content remain
outside that action. `Repair CodeDB`, advanced Sync, and Remove use a
second-level Manager confirmation scoped to the manifest-closed CodeDB paths.
No authorization document or version-control state is required.

## Safety Boundaries

- After Setup completes, interactive Editor sessions own project demand and
  start the backend asynchronously. `Start with Unity Editor` is persistent;
  Start, Stop, and Restart are immediate commands associated with the Editor
  cohort present when they are issued. Closing the final Editor stops the
  backend without changing persistent policy. BatchMode does not auto-start
  CodeDB.
- Owned, byte-exact lower generations can be installed and selected
  automatically while generation-scoped leases protect active requests.
  An empty managed scope can be adopted automatically. Confirmed Repair handles
  safe first adoption when needed; downgrade, drift, and unknown same-name
  content retain their fail-closed review gates.
- Opening or refreshing the Manager is read-only. MCP wrappers attach only to
  an Editor-owned ready coordinator and never start a one-shot Provider.
- The tracked provider config remains `watch=false`; the coordinator owns a
  generated watch-enabled config and the Shader/HLSL adapter lifecycle.
- Provider watch and the Shader/HLSL adapter have separate ownership.
- Generated indexes, provider binaries, logs, and watcher state remain ignored.
- `Repair CodeDB` updates only the current project's MCP server table, preserving
  unrelated TOML content and publishing a recoverable backup. It refuses
  invalid, duplicate, or ambiguous configuration without writes and never
  edits global client configuration.
- DryRun, automatic Upgrade, Repair, Verify, advanced Sync, and Remove neither
  inspect nor invoke a version-control system. Unity's resolved Package path is
  read-only input for cached, local, embedded, and registry-backed installs.
- Strict Sync and Remove fail closed on drift, active watchers or MCP requests,
  interrupted transactions, downgrade, and payload collisions. Automatic
  generation upgrades use a separate owned-upgrade path with durable rollback
  and never kill Unity, Codex, or MCP processes.
- Controlled legacy Redeploy also rejects drift and active owners. It never
  terminates processes and cannot be used for first adoption, unknown payload
  identities, or current/foreign generations.

## Discover Read Bounds

- `codedb_read` is enforced by the wrapper against the resolved project-local
  source file instead of trusting a Provider's returned file body.
- Snake-case and camel-case line aliases must agree. A read returns only its
  requested range, capped at 200 lines, and reports when that cap is applied.
- Lexical paths and resolved real paths must both remain under the Unity root;
  generated/excluded scopes and binary files remain unreadable.
- Every tool result and surfaced tool error is capped at 64 KiB of UTF-8 text.
  Truncated output carries an explicit `[TRUNCATED]` marker.
- Search scope aliases are canonicalized to `path_glob`; an existing or
  path-like directory becomes `<directory>/**`, and conflicting aliases fail.
- Without an explicit language, directory scopes search both Provider and
  Shader/HLSL lanes. Parsed native results are filtered again by the wrapper,
  merged by file/range, deduplicated, and then subject to one global limit.
- `codedb_context` uses those same unified hits and wrapper-local bounded reads,
  so context cannot bypass scope, deduplication, read, or output limits.

Host-only lifecycle acceptance code is not part of the package. The package
assembly remains independent, with an optional friend-assembly declaration for
host extensions that does not reverse the dependency direction.

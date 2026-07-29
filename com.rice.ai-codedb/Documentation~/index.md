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
controls are planned in the [v0.2.3 roadmap](v0.2.3-roadmap.md). Approved
future work continues in the
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
    "com.rice.ai-codedb": "https://github.com/riceWithoutIce/UnityCodeDB.git?path=/com.rice.ai-codedb#v0.2.2"
  }
}
```

Production projects should pin a release tag. The `#main` revision is reserved
for intentional validation of unreleased development changes.

## Manager

Open `Tools/Rice AI/Codedb/Manager`. The Manager provides five focused views:

- Overview: package, runtime, index, MCP, and watcher health.
- Setup: host payload inspection and explicitly authorized materialization.
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
.codex/config.toml                Optional project-level MCP registration
```

The Manager can inspect package-owned host files without mutating the project.
Sync and Remove require a separately reviewed authorization document tied to
the exact project root, Git HEAD, action, and payload identity. The package
does not generate, persist, infer, or delete that authorization.

## Safety Boundaries

- After Setup completes, interactive Editor sessions own project demand and
  start the backend asynchronously. Pause is explicit and persistent until
  Resume; closing the final Editor stops the backend without changing that
  preference. BatchMode does not auto-start CodeDB.
- Opening or refreshing the Manager is read-only. MCP wrappers attach only to
  an Editor-owned ready coordinator and never start a one-shot Provider.
- The tracked provider config remains `watch=false`; the coordinator owns a
  generated watch-enabled config and the Shader/HLSL adapter lifecycle.
- Provider watch and the Shader/HLSL adapter have separate ownership.
- Generated indexes, provider binaries, logs, and watcher state remain ignored.
- MCP guidance is project-level first; global client configuration is never
  silently modified.
- Host mutations fail closed on drift, staged managed files, active watchers or
  MCP wrappers, interrupted transactions, downgrade, and payload collisions.

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

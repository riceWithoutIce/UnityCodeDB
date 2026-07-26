# Rice AI CodeDB

Rice AI CodeDB is an Editor-only package for setting up and operating a
project-local CodeDB index from the Unity Editor.

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
    "com.rice.ai-codedb": "https://github.com/riceWithoutIce/UnityCodeDB.git?path=/com.rice.ai-codedb#v0.1.0"
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

- Watch is disabled by default and starts only through an explicit action.
- Provider watch and the Shader/HLSL adapter have separate ownership.
- Generated indexes, provider binaries, logs, and watcher state remain ignored.
- MCP guidance is project-level first; global client configuration is never
  silently modified.
- Host mutations fail closed on drift, staged managed files, active watchers or
  MCP wrappers, interrupted transactions, downgrade, and payload collisions.

Host-only lifecycle acceptance code is not part of the package. The package
assembly remains independent, with an optional friend-assembly declaration for
host extensions that does not reverse the dependency direction.

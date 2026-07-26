# UnityCodeDB

<p align="center">
  <img src="com.rice.ai-codedb/Documentation~/images/codedb-icon.svg" width="96" alt="Rice AI CodeDB icon">
</p>

<p align="center"><sub>"Memes Comment Reply" icon by <a href="https://streamlinehq.com">Streamline</a>, licensed under <a href="https://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>.</sub></p>

UnityCodeDB is an Editor-only Unity Package Manager package for project-local
CodeDB setup, indexing, health checks, automatic refresh, and bounded source
discovery from Codex or another MCP client.

The first release targets Unity `2022.3` on Windows. It keeps every generated
index, provider binary, log, and watcher state inside the consuming Unity
project's ignored runtime instead of sharing state across projects.

## Package

- Package name: `com.rice.ai-codedb`
- Latest release: `v0.1.0`
- Unity: `2022.3` or newer within the `2022.3` compatibility line
- Editor menu: `Tools/Rice AI/Codedb/Manager`

## Installation

Add the package to the Unity project's `Packages/manifest.json`:

```json
{
  "dependencies": {
    "com.rice.ai-codedb": "https://github.com/riceWithoutIce/UnityCodeDB.git?path=/com.rice.ai-codedb#v0.1.0"
  }
}
```

Production projects should pin a published version tag. Use `#main` only when
intentionally validating unreleased development changes.

## Requirements

- Windows Editor and Windows PowerShell 5.1
- Node.js for the project-local MCP wrapper and Shader/HLSL adapter worker
- A separately acquired `killop/codedb-mcp` / `codebase-mcp` provider

The provider is an external process dependency. This repository does not
vendor its source or redistribute its binary.

## First Setup

1. Open `Tools/Rice AI/Codedb/Manager`.
2. Use Setup to inspect the package-owned host payload before any mutation.
3. Materialize the reviewed host files only through the explicit authorization
   flow described in the package README.
4. Prepare the project-local runtime and provide the external provider.
5. Generate and review project-level MCP registration guidance.
6. Automatic refresh starts after Setup completes. Use Pause when the project
   must remain stopped; Resume clears that persistent pause.

## Ownership Boundaries

- The package owns reusable Editor UI, validation, adapters, templates, and
  payload tooling under `com.rice.ai-codedb/`.
- Each Unity project owns tracked operational files under `AIWork/codedb/`.
- Generated runtime stays under ignored
  `AIWork/.runtime/codedb/<project-provider-slug>/`.
- MCP registration is workspace-local or project-level first. The package does
  not silently edit global client configuration.
- Provider watch and the Shader/HLSL text adapter remain separate owners.
- `codedb_read` resolves a project-local real file, returns at most 200
  requested lines, and all wrapper text responses are capped at 64 KiB.
- Search `path` aliases are normalized to `path_glob`; directory queries without
  a language merge Provider and Shader hits under one deduplicated global limit.

See [the package README](com.rice.ai-codedb/README.md) and
[package documentation](com.rice.ai-codedb/Documentation~/index.md) for the
full safety and materialization model.

## Repository Layout

```text
com.rice.ai-codedb/
  Editor/          Unity Editor implementation
  Tests/Editor/    Unity EditMode tests
  Payload~/        Audited host-project payload
  Tools~/          Host payload materializer
  Tests~/          Standalone materializer fixture
  Documentation~/ Package documentation
```

## Validation

Run the standalone package boundary and materializer fixtures from the
repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1
```

## License

UnityCodeDB is released under the [MIT License](LICENSE). Third-party tools are
not bundled and remain governed by their own licenses.

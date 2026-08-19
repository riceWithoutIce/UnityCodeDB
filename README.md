# UnityCodeDB

<p align="center">
  <img src="com.rice.ai-codedb/Documentation~/images/codedb-icon.svg" width="96" alt="Rice AI CodeDB icon">
</p>

<p align="center"><sub>"Memes Comment Reply" icon by <a href="https://streamlinehq.com">Streamline</a>, licensed under <a href="https://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>.</sub></p>

UnityCodeDB is an Editor-only Unity Package Manager package for project-local
CodeDB setup, indexing, health checks, automatic refresh, and bounded source
discovery from Codex or another MCP client.

The current release targets Unity `2022.3` on Windows. It keeps every generated
project index, runtime config, log, and watcher state inside the consuming Unity
project's ignored runtime. The separately installed Provider is machine-scoped
under `%LOCALAPPDATA%\Rice\CodeDB\providers\<version>` and is never copied into
the project by the Package.

<p align="center">
  <img src="com.rice.ai-codedb/Documentation~/images/meme.png" width="256" alt="RG versus CodeDB meme">
</p>

## Package

- Package name: `com.rice.ai-codedb`
- Latest stable release: `v0.2.4`
- Latest validation prerelease candidate: `v0.2.5-preview.5` / `poc.31`
- Unity: `2022.3` or newer within the `2022.3` compatibility line
- Editor menu: `Tools/Rice AI/Codedb/Manager`

## Installation

For the current third-party validation, add the preview package to the Unity
project's `Packages/manifest.json`:

```json
{
  "dependencies": {
    "com.rice.ai-codedb": "https://github.com/riceWithoutIce/UnityCodeDB.git?path=/com.rice.ai-codedb#v0.2.5-preview.5"
  }
}
```

Production projects should remain pinned to stable `v0.2.4` until the preview
is accepted. Use `#main` only when intentionally validating unpublished changes.

## Requirements

- Windows Editor and Windows PowerShell 5.1
- Node.js `22.x` or `24.x` for the project-local MCP wrapper and Shader/HLSL adapter worker
- The reviewed `killop/codedb-mcp` `0.5.0` Provider and schema-1 manifest under
  `%LOCALAPPDATA%\Rice\CodeDB\providers\0.5.0`

The provider is an external process dependency. This repository does not
vendor its source or redistribute its binary.

## First Setup

1. Install the reviewed Node.js and machine Provider prerequisites. If either is
   missing, invalid, hash-mismatched, or incompatible, Unity reports one
   `Missing prerequisite` state before project mutation and does not enter a
   Repair/retry loop.
2. After Unity resolves the Package, an empty safe CodeDB scope converges to the
   current Host generation asynchronously without requiring the Manager. This
   behavior is independent of the project's version-control system and the
   Package installation source, and it does not block a cold Editor entering
   Play.
3. The Manager reports only `Starting`, `Ready`, `Needs attention`,
   `Uninstalled`, or `Missing prerequisite` on its ordinary surface. `Ready` requires Package-owned Host
   files, a safe project registration, and a real project-context wrapper probe
   that completes MCP initialize, `tools/list`, and `codedb_status`.
4. If recovery is needed, click `Fix CodeDB` and confirm its exact project-local
   scope. That one action repairs the Host runtime and only the four
   CodeDB-managed direct keys in the current project's MCP server table, then
   verifies the wrapper handshake. Custom direct keys and descendant tables
   such as `tools.*` are preserved; the action does not require an authorization
   file, copied registration snippet, manual TOML edit, or a second CodeDB
   action. Advanced diagnostics are not part of installation or recovery.
5. After setup completes, each interactive Unity Editor session publishes
   project demand and starts CodeDB asynchronously. `Start with Unity Editor`
   controls the persistent policy; Start, Stop, and Restart control the Editor
   session cohort present when the command is issued without silently changing
   that policy.
6. Closing the final Editor session stops that project's backend without
   changing its preference. BatchMode sessions do not auto-start CodeDB.

The Package-owned wrapper probe is an implementation gate, not a substitute for
release acceptance in a newly created Codex Desktop task. That real new-task
tool exposure and the standalone third-party Package-only golden path remain
separate validation gates for the unreleased candidate.

To remove the project integration while leaving the UPM Package installed,
open Setup, expand `Danger zone`, choose `Uninstall CodeDB from Project`, and
confirm the exact project-local scope. The action removes only CodeDB-managed
MCP registration and proved-owned Host/runtime state. The target MCP namespace
is preserved as state-bound TOML comments, so custom keys, `tools.*`, comments,
BOM/EOL, ordering, and unrelated configuration remain recoverable without
leaving an active project server. Provider binaries, indexes, adapters, custom
runtime settings, policy, and business files are also preserved. A genuine
external MCP session is never stopped;
its immutable closure is retained until the lease drains and cleanup then
completes automatically. A persisted `COMPLETE` cleanup state prevents further
periodic cleanup runs. The uninstalled Manager view exposes one confirmed
`Install CodeDB` action, which restores the exact preserved target namespace and
the four managed launch keys before clearing `UNINSTALLED`.

## Ownership Boundaries

- The package owns reusable Editor UI, validation, adapters, templates, and
  payload tooling under `com.rice.ai-codedb/`.
- Unity's resolved Package location is read-only input. Cached, local, embedded,
  and registry-backed installations use the same project state machine.
- Each Unity project owns tracked operational files under `AIWork/codedb/`.
- Generated runtime stays under ignored
  `AIWork/.runtime/codedb/<project-provider-slug>/`.
- Immutable host generations, their atomic pointer, and generation leases stay
  under ignored `AIWork/.runtime/codedb/host/`.
- MCP registration is workspace-local or project-level first. The package does
  not silently edit global client configuration.
- Provider watch and the Shader/HLSL text adapter remain separate owners.
- `codedb_read` resolves a project-local real file, returns at most 200
  requested lines, and all wrapper text responses are capped at 64 KiB.
- Search `path` aliases are normalized to `path_glob`; directory queries without
  a language merge Provider and Shader hits under one deduplicated global limit.
- Ready MCP wrappers share the project coordinator's persistent Provider. The
  v0.2.3 bridge stays dormant with zero Provider attempts while Unity is
  offline and reattaches after Unity returns without recreating the MCP session.
  Identical concurrent searches join one execution; distinct work is queued
  without implicit batching. Disabled, Editor-offline, and starting states do
  not launch a Provider and return a stable reason instead.

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

Run the standalone package boundary fixture from the repository root. During
development, select the materializer slice that matches the changed behavior:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -McpConfigOnly
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -RepairOnly
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -TransactionOnly
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -PortabilityOnly
```

The materializer selectors are mutually exclusive. After the implementation
tree is stable, run the complete fixture once as the release-candidate gate:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1
```

## License

UnityCodeDB is released under the [MIT License](LICENSE). Third-party tools are
not bundled and remain governed by their own licenses.

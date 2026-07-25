# Rice AI CodeDB

`com.rice.ai-codedb` is an Editor-only Unity Package Manager package for the
reusable CodeDB Manager, project-local indexing workflow, Shader/HLSL adapter,
and bounded MCP discovery surface. Version `0.1.0` targets Unity `2022.3` on
Windows.

Install from the repository subfolder with
`https://github.com/riceWithoutIce/UnityCodeDB.git?path=/com.rice.ai-codedb#main`.
Pin a published version tag instead of `main` for production projects.

The current `0.1.0` release materializes reviewed process tooling into the host
project. Manager actions resolve tracked scripts, wrapper files, and templates
under `AIWork/codedb/`, while generated provider binaries, configs, indexes,
logs, and watcher state remain under ignored `AIWork/.runtime/`. The external
`killop/codedb-mcp` provider and Node.js are prerequisites and are not bundled.

`Payload~`, `Tools~`, and `Tests~` contain a twenty-one-file host-payload
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
read-only `DryRun`. `Sync` and `Remove` require exactly one explicit mutation
mode. `-PocFixture` retains the fixed run-id, ignored-root, fixture-marker, and
reparse-point constraints used by the test suite. A tracked project instead
requires an absolute `-TrackedHostAuthorizationPath` naming a reviewed JSON
file under its own ignored materializer runtime. Both modes reject unowned or
drifted files and use a deterministic UTF-8, LF-only payload ownership marker.
Semantically valid but non-canonical marker JSON is stale and Sync rewrites only
that marker to the canonical serialization. Sync and Remove
publish a durable transaction journal before their first host mutation, recover
interrupted transactions in a new process, reject recovery over third-state
external changes, and use same-volume atomic replacement for existing managed
files.
When the host is in a Git worktree, plans inspect the active Git index and
reject staged changes to package-managed targets or the ownership marker;
staged files outside that exact ownership scope remain untouched and do not
block the operation. Lower payload sequences and same-sequence payload identity
or hash collisions are conflicts for both Sync and Remove.
Before recovery or planning, mutations publish a materializer-active marker,
hold existing watcher management locks, prune only dead host-use leases, and
reject live MCP, coordinator, provider, adapter-worker, or adapter-build PIDs.
Legacy or unowned wrappers require explicit `-ConfirmLegacyMcpStopped` before
their first gated adoption or upgrade.

A tracked-host authorization must be a direct child of
`AIWork/.runtime/codedb/payload-materializer/authorizations/`, must remain Git
ignored and untracked, and must have a lowercase 32-hex ID matching its file
name. Its closed schema is:

```json
{
  "schema_version": 1,
  "managed_by": "com.rice.ai-codedb",
  "purpose": "tracked-host-payload-mutation",
  "authorization_id": "<32 lowercase hex characters>",
  "project_root": "<absolute Unity project root>",
  "git_head": "<current repository HEAD>",
  "action": "Sync",
  "package_version": "0.1.0",
  "payload_version": "poc.9",
  "payload_sequence": 9,
  "payload_manifest_sha256": "<raw payload-manifest.json SHA256>",
  "target_count": 21,
  "acknowledgement": "I authorize com.rice.ai-codedb to mutate only its audited host payload scope."
}
```

`action` is exactly `Sync` or `Remove`. The Unity project markers must be
tracked, and the authorization must match the current project root, Git HEAD,
complete manifest identity, and target count. The materializer neither creates
nor deletes authorization files; the caller owns review and cleanup. Passing a
Sync authorization cannot authorize Remove, and the separate legacy MCP-stop,
active-process, staged-index, conflict, and transaction gates still apply.

The package materializer is wired into the Manager Setup tab for read-only
status/DryRun, strict Verify, and explicitly authorized Sync/Remove. Manager
status distinguishes installed/current, not-installed, stale, conflict, and
check-failed outcomes. It does not create, persist, infer, or delete production
authorization files; the selected path and optional legacy-MCP confirmation are
session-only and are cleared after each mutation attempt. Existing runtime,
index, watch, and probe actions continue to resolve the materialized host paths.
This package still does not include the external CodeDB provider, host
acceptance probes, MCP client configuration, generated project data, or any
host-owned compatibility entry. Those ownership boundaries remain unchanged.
The fixture validates disabled-by-default watch config, explicit Start/Status/
Stop ownership, wrapper recovery, read-only provider guidance, ignored-runtime
verification, formal `--no-watch` refresh, generated ignore parity, and
index-only cleanup against an isolated runtime-built provider executable. It
also validates provider and adapter status/search/read probes, hit/no-hit
reporting, `OK`/`STALE`/`UNKNOWN` freshness, exact fresh no-op behavior, and
independent provider-only or adapter-only refresh. It also verifies copy-only
project-level registration guidance and read-only project-config validation
without changing `.codex/config.toml` or any other fixture file. The
fixture suite also proves hard-crash recovery and concurrent readers observing
only complete old or new file hashes. It now also proves active MCP and watcher
refusal, legacy watcher-state refusal, normal lease cleanup, hard-kill stale
lease recovery, legacy adoption confirmation, staged-index refusal including
interrupted recovery, scoped unrelated-stage preservation, downgrade/sequence
collision refusal, and exact LF-versus-CRLF conflict behavior. It now also
validates tracked-host authorization refusal plus exact authorized Sync and
Remove in a separate nested Git project. Payload hashes remain byte exact and
no payload-file EOL normalization occurs in the materializer. Ownership markers
are serialized canonically as LF-only JSON. The first reviewed tracked-host
adoption is recorded in the host handoff; real tracked-host Remove/rollback
also passed with exact host restoration. Manager integration passes static
build, package-neutral, full materializer fixture, real Unity import, and 44/44
package EditMode tests. Wide, minimum-width floating, and docked Compact visual
acceptance also passes as recorded in the host handoff.

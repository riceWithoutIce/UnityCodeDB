# CodeDB Provider Installation Contract

Status: frozen development-baseline decision for v0.2.5-preview.5 (2026-08-20).
The Package includes a strict, Package-owned installer entry point and activates
this identity through immutable generation `poc.33`. The development installer
remains separate from release approval: a production descriptor still requires
the Rice artifact, license, hash, and signing review below.

## Decision

The preview.5 Provider identity is fixed to the reviewed upstream commit below.
The package does not follow an upstream `latest` branch and does not silently
upgrade the Provider when a newer upstream version appears. The upstream
semantic version and the Rice machine-distribution identity are recorded
separately so two same-version upstream artifacts can never share a directory.

```text
Provider ID:       killop/codedb-mcp
Provider version:  0.5.0
Rice distribution: 0.5.0-28e3912
Upstream commit:   28e3912d5cd67ff3499734984f3e3d626a204796
Protocol:          codedb-cli-v1
Package range:     >=0.2.5-preview.5 <0.2.6
Executable:        codebase-mcp.exe
```

A later upstream stable release or compatible version requires a separate
identity, compatibility, license, artifact, and regression review. It is not an
automatic update of this contract.

## Frozen Historical Development Baseline (2026-08-20)

The development baseline used by the original UnityCodeDB integration is the
exact upstream artifact at:

```text
Upstream commit:   28e3912d5cd67ff3499734984f3e3d626a204796
Rice distribution: 0.5.0-28e3912
Executable:        codebase-mcp.exe
Artifact size:     27852288 bytes
Executable SHA-256: 38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7
Required tools:    codedb_search, codedb_text_search, codedb_find
```

This is a byte-level historical decision, not a guess based on the Provider
version string. The same SHA-256 was found in a historical runtime, and its
coordinator/watch logs record successful `provider_ready`,
`codedb_search`, `codedb_text_search`, and `codedb_find` calls. The UnityCodeDB
wrapper and coordinator contract in the original `6a15987` package also
requires that search tool surface.

The later upstream commit `13de004783d21de631c4c85bf4803a4866de55e4` is a
different graph-first protocol surface. Its Windows artifact is
`d4aa19539a5a28d350598574e93ed06fcb3d571c7657236c069c3371a153552d` and does
not provide the required search tools. It must not be silently substituted for
the frozen development baseline.

The checked-in preview.5 development descriptor and active `poc.33` payload use
the frozen `28e3912` identity. The preserved `poc.31`/`poc.32` payloads continue
to describe the older `13de004` snapshot as immutable historical state. The
installer only activates `28e3912` after downloading and verifying the exact
Package-pinned executable bytes.

### No-Drift Rules

1. The commit and executable SHA-256 above are the authoritative identity;
   `0.5.0` alone is not sufficient evidence.
2. Do not resolve a branch, `latest`, an unreviewed mirror, or a newer upstream
   release in place of this identity.
3. Any Provider change requires a separate upgrade decision covering protocol
   compatibility, artifact hash, license/distribution authority, installer,
   readiness handshake, and focused regression evidence.
4. Published immutable generations are never rewritten to change Provider
   identity. A migration must publish a new generation and preserve older
   generation bytes and leases.
5. The preview.5 `poc.31`/`poc.32` snapshots and their `13de004` references
   remain immutable historical state. Active generation `poc.33` uses the
   `0.5.0-28e3912` machine directory; no older generation is rewritten or
   replaced in place.

## Distribution Boundary

The Git repository and the machine distribution have different ownership:

| Surface | Contents | Location |
| --- | --- | --- |
| Source repository | Provider contract, installer and verifier code, expected identity, artifact metadata, tests, and notices | `UnityCodeDB` Git tree |
| Development retrieval | Fixed upstream executable at the exact reviewed commit, verified by Package-pinned SHA-256 | Immutable `raw.githubusercontent.com` commit URL |
| Official distribution | Versioned Windows x64 archive, `codebase-mcp.exe`, `provider-manifest.json`, checksums, signature, and third-party notices | Rice-owned GitHub Release asset |
| Machine installation | Verified executable and manifest only | `%LOCALAPPDATA%\\Rice\\CodeDB\\providers\\0.5.0-28e3912` for the migrated baseline |
| Unity project | Host instances, indexes, adapters, leases, logs, and project registration | Project-local runtime; never a Provider copy |

The first distribution may use a Release asset attached to the
`riceWithoutIce/UnityCodeDB` repository. A separate Provider artifact
repository can be introduced later if Provider releases need an independent
cadence. A Provider executable is not committed to the Git tree or bundled in
the UPM Package by this contract.

## Source and Trust Gates

The upstream fixed commit is the source identity, not the final distribution
trust boundary. Before enabling a production end-user install action, Rice must
have:

1. Confirmed the upstream license and redistribution terms.
2. Produced or reviewed the Windows x64 artifact from the fixed commit.
3. Published a versioned archive through the Rice Release channel.
4. Added an independently reviewed archive SHA-256 and executable SHA-256.
5. Added an authentic release signature and a package-pinned verification key
   or equivalent trust anchor.
6. Included `provider-manifest.json` with exact schema, identity, protocol,
   supported Package range, executable name, and SHA-256.

The GitHub blob SHA of an upstream file is not an executable SHA-256 and is not
accepted as the Provider hash. The installer must hash the bytes it received.
The detached signature is a base64-encoded RSA-SHA256 signature over the exact
archive bytes; its encoding and algorithm are part of the pinned descriptor.
Mutable branch URLs, unreviewed mirrors, arbitrary user binaries, and a
manifest whose hash is trusted only because it arrived beside the executable
are not accepted sources.

## Installation Flow

The Manager exposes `Configure Dependencies` as the contextual primary action
when the product state is `Missing prerequisite` and the Provider is the
missing dependency. The same machine-scoped command remains available as a
secondary utility on Overview and Setup after verification, so a user can retry
or reinstall the pinned Provider without first deleting machine files. The
action does not modify the Unity project.

The implementation entry point is `Tools~/install-codedb-provider.ps1`, and its
Rice-pinned descriptor is `Tools~/codedb-provider-distribution.json`. Unity may
execute that exact Package-owned script outside the project only after the
resolved Package root and every path node have passed the same no-reparse and
exact-relative-path checks used for the Package materializer. Other external
scripts remain rejected by the Editor process runner.

Fixture-only source overrides are accepted only by an isolated temporary copy
of the installer used by `Tests~`; the Package-owned script rejects test mode.
The normal Manager entry point therefore cannot replace the checked-in
descriptor with a caller-supplied artifact or signing key.

```text
read-only prerequisite check
  -> download to an isolated temporary file
  -> development: verify exact commit URL and pinned executable SHA-256
     production: verify Rice release signature and pinned archive identity
  -> verify strict provider-manifest.json
  -> verify executable SHA-256 and path/reparse boundaries
  -> atomically install the versioned machine directory
  -> perform one bounded prerequisite recheck
```

Failure removes only the temporary candidate and leaves the existing Provider,
project files, `.codex/config.toml`, leases, processes, and user policy
unchanged. A valid existing Provider is never replaced in place until the new
artifact has passed all checks. Repeated installation of the same verified
artifact is idempotent.

Node.js remains a separate prerequisite. The Manager may link to the official
Node.js installation guidance, but preview.5 does not silently download or
install Node.js, alter PATH, or request an unrelated system upgrade.

## Manager State Contract

The normal surface shows only the product state and at most one contextual
primary action. The persistent machine dependency utility is secondary and does
not replace the project action selected by this state table:

| State | Dependency presentation | Primary action |
| --- | --- | --- |
| `Missing prerequisite` | Node.js and Provider rows show detected version/path and exact failure reason | `Configure Dependencies` when Provider is missing; official Node.js guidance when Node.js is missing |
| `Starting` | Verification or bounded recheck is in progress | None |
| `Ready` | Both machine prerequisites are verified and the project usable path is available | None |
| `Needs attention` | Existing project state needs normal recovery | `Reinstall CodeDB` |
| `Uninstalled` | Project integration is logically removed | `Install CodeDB` |

Source, commit, hash, signature, archive URL, and install path are available in
diagnostics. They are not hidden prerequisites for ordinary project use and do
not replace the single contextual action.

## Acceptance Gates

The focused installer and UI tests must prove:

- missing archive, missing manifest, malformed manifest, wrong identity,
  unsupported protocol or Package range, signature failure, and hash mismatch
  all remain `Missing prerequisite` with zero Unity-project writes;
- a valid fixed Provider installs to the exact machine path and survives a
  repeated idempotent install;
- a failed replacement preserves the previous valid Provider byte-for-byte;
- reparse points, path escapes, unexpected archive entries, and executable name
  changes fail closed;
- installing or validating the Provider never writes project MCP configuration,
  global Codex configuration, Host generations, leases, policies, or business
  files and never terminates a process;
- after a successful bounded recheck, the existing readiness gates still
  require initialize, exact `tools/list`, usable `codedb_status`, and bounded
  `codedb_text_search` before `Ready`.

Real Unity Manager interaction, a new Codex Desktop task, and third-party
Package-only acceptance remain separate release gates. A direct wrapper probe
does not prove tool injection into a new Codex task.

## Explicit Non-Goals

- No automatic Provider version discovery or silent upgrade.
- No automatic Node.js installation in preview.5.
- No Provider binary in the UPM Package or Git history.
- No claim that the development upstream-download descriptor satisfies the production license or Rice signature gate.
- No per-project Provider copy.
- No global MCP registration or user-level `.codex/config.toml` mutation.
- No use of Provider installation as a reason to weaken existing ownership,
  transaction, reparse, lease, or external-process safety boundaries.

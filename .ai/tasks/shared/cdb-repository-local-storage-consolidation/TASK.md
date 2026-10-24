# Task: cdb-repository-local-storage-consolidation

## Metadata

- Scope: shared repository housekeeping under Workflow v2.5.
- Authorization: the human requested consolidation of the two named external
  directories according to the agreed archive/migration policy on 2026-10-06.
- Review mode: NORMAL; no Coder/Verifier dispatch or product acceptance gate.
- Status: COMPLETE / RETAINED_BYTES_VERIFIED / EXTERNAL_ROOTS_REMOVED.

## Objective And Exact Mapping

Paths below are relative to the UnityCodeDB repository root. Preserve every
source byte; do not adopt residual source into the implementation.

| Authorized external source | Repository-local destination |
| --- | --- |
| `../UnityCodeDB-local-artifacts/` | `.artifacts/archive/local-artifacts-20261006/UnityCodeDB-local-artifacts.zip`, with the entire original tree inside one ZIP root and a per-file manifest alongside it |
| `../UnityCodeDB-worktree-residual-backup-20260902-210841/` | `.backups/worktree-residual-20260902-210841/`, retaining the original `tracked/` and `untracked/` layout; a per-file manifest is stored alongside the destination directory |

## Execution Envelope

- Use a task-owned helper under
  `.artifacts/maintenance/storage-consolidation-20261006/`.
- Validate the exact resolved source roots, contained destinations, and all
  existing ancestors; reject reparse points and destination collisions.
- Capture all relative file/directory paths, sizes, and SHA-256 hashes.
- Archive all historical output, including the original ZIPs and extracted
  contents. Verify a task-owned extraction against the complete source tree.
- Copy the residual backup and verify every file and directory against its
  source. Write no production/test bytes or consumer configuration.
- Record verified retained identities before removing either external source.
- Recheck source stability, retained identities, and declared consumer configs
  before native PowerShell removal of only the two exact external roots.
- On any failure, stop; retain original/retained data and record the result.
  Do not overwrite a destination or terminate a process to force completion.
- No machine-wide scan, runtime/MCP/process probe, Unity operation, product
  tests, Package export/rebuild, commit, push, publication, or remote-board write.

## Protected State And Completion

Existing unrelated dirty/staged/untracked data and all active `.artifacts`
Packages, including the S29 `306f329` human-validation Package, remain unchanged.
The known static consumer checks are not proof of complete project uninstall
or absence of every possible runtime/unknown-project reference.

Completion requires both retained trees to match their original byte identities,
both exact external directories to be absent, recovery paths recorded in
`RESULT.md`, and no changes to consumer references or Git HEAD/index.

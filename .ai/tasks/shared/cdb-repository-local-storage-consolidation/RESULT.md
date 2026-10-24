# Result: cdb-repository-local-storage-consolidation

Status: COMPLETE / RETAINED_BYTES_VERIFIED / EXTERNAL_ROOTS_REMOVED /
S29_INPUTS_UNCHANGED.

The human authorized consolidation of the two external directories named in
`TASK.md`. The earlier bounded static scan found no references to either root
in the declared consumer configurations or registered worktrees. Runtime and
unknown-project references were not probed; Package removal is not asserted to
be full CodeDB integration uninstall.

Full retained-copy/archive verification passed. At the pre-cleanup checkpoint,
both original external directories still existed. The retained identities below
were recorded before any removal of the original source directories.

No commit, publication, consumer-reference change, or Unity operation is part of
this housekeeping task. S29 human acceptance and product evidence are unchanged.

## Retained Identities And Full-Tree Verification

All paths in this record are repository-relative unless marked as an original
external source. The complete generated manifests contain every relative file
path, byte length, SHA-256 hash, and directory path, including empty directories.

| Original external source | Retained data | Verified original tree |
| --- | --- | --- |
| `../UnityCodeDB-local-artifacts/` | `.artifacts/archive/local-artifacts-20261006/UnityCodeDB-local-artifacts.zip` | 2,265 files; 415 directories; 55,421,694 bytes |
| `../UnityCodeDB-worktree-residual-backup-20260902-210841/` | `.backups/worktree-residual-20260902-210841/` | 32 files; 34 directories; 2,301,122 bytes |

Historical artifact retention:

- Every original ZIP and extracted Package file was archived unchanged; no
  attempt was made to select only successful candidates or repair old bytes.
- The archive has the single root `UnityCodeDB-local-artifacts/`. A task-owned
  exact-ZIP extraction matched every original file and directory; the temporary
  extraction was then removed. The verified retained ZIP is 20,116,614 bytes.
- Source-tree SHA-256:
  `8326ff22e1f0452f4c71ea331ed50025bb544c6d8b017a86f80974b146f77def`.
- Archive SHA-256:
  `b29d95485eff290de3a24855922f07879a16f75e962feb65bdd68dc9e01dba25`.
- Per-file manifest:
  `.artifacts/archive/local-artifacts-20261006/source-manifest.json`.
- Manifest SHA-256:
  `ac709bdc91f4555d31de3838f88e85cef787312dfa3ec786b39211fce4894cc3`.

Residual backup retention:

- The retained directory preserves the original `tracked/` and `untracked/`
  layout, including all unique historical records. No residual was restored to
  a production/source path.
- Every copied file and directory matched its source.
- Source/retained-tree SHA-256:
  `5ec30393dc62f3af92a7d9ec875bb28568ae223cc9f1daa395855eec916ed3ef`.
- Per-file manifest:
  `.backups/worktree-residual-20260902-210841.manifest.json`.
- Manifest SHA-256:
  `0d9640298f33ed03b200fda162e48686ae6b090511d7d36c5a30f9f3fb04eb6f`.

Both source trees were reread after archive/copy verification and still matched
their initial identities. The cleanup phase will recheck both source trees,
the retained archive/backup, resolved exact roots, and declared consumer configs
before removal. Any failure stops cleanup and preserves retained data.

## Recovery Route And Boundaries

To recover historical Packages, extract the retained ZIP into a separately
authorized recovery location, keep its single root, and verify the selected
files against `source-manifest.json`. This is preservation of old bytes, not
fresh release closure or product acceptance. Installing an old Package or
restoring its original external path/reference requires separate authorization.

To recover residual work, use the retained `tracked/` or `untracked/` subtree and
verify its file hash against the backup manifest. Restoring to normal source
paths is a separate authorized source change; do not bulk-merge the backup.

The original-path mapping and hashes remain in this concise versionable record.
The ZIP, backup copies, helper, and full generated manifests remain ignored by
Git and protected until an explicitly authorized retention decision.

## Final Consolidation Result - 2026-10-06

- Stage and final cleanup both completed with exit 0; no retry was needed.
- Immediately before cleanup, both source trees still matched their recorded
  identities; the retained backup matched every source file/directory and the
  ZIP still matched its fully verified archive hash. Exact resolved roots and
  declared consumer configurations were checked before each native PowerShell
  source removal.
- Only the two approved external original directories were removed from their
  old locations. Both are now absent. Every original file remains recoverable
  from the retained archive or backup at the mappings above.
- After cleanup, the retained backup tree was verified again. The archive and
  both per-file manifest hashes remained exactly the recorded identities.
- The current S29 ZIP and human-import `package.json`, all eight declared
  consumer manifest/lock files, and the three existing workflow/index/ignore
  files were unchanged: 13/13 pre/post file hashes matched.
- Git HEAD remained `306f329b8f51f82695dccc5e8de67c6bcea5320e`; the Git index
  byte hash was unchanged. No staging, commit, push, or publication occurred.
- The archive, full manifests, backup, and task-owned helper match the root Git
  ignore rules. This `TASK.md` and `RESULT.md` are concise uncommitted,
  non-ignored housekeeping records; no raw data tree was added to Git.
- No consumer Package reference, production/test source, machine installation,
  runtime/MCP/Unity state, remote board, or active acceptance gate was changed.
  Full project uninstall and global absence of references remain unclaimed.

Housekeeping is complete. S29 human validation continues on its existing exact
Package without a rebuild, import-path change, or repeated product test.

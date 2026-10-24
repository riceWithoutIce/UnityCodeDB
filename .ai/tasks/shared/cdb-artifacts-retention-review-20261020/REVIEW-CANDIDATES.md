# Artifact review candidates: four test groups

Status: `INVENTORY_COMPLETE / BATCH_01_REMOVED / BROADER_REVIEW_OPEN`.

This bounded review covers only the nine intermediate children identified in
the preceding read-only inventory. The exact file-level path, SHA-256, byte
count and byte-identical comparison path mapping is in
`.artifacts/maintenance/artifact-retention-review-20261020/review-candidates.json`.
Its SHA-256 is
`298ee842b3305ef1052a251c9f5563811086c6599a5de2dc273744bf944dbf28`.
The manifest is a navigation aid; the task results remain the authority for
source identity, outcomes and acceptance level.

All paths below are relative to `<repository-root>/.artifacts/tests/`.
`Identical` means a file with the same SHA-256 exists in the comparison root,
possibly under a different relative path. `Unique` means no byte-identical
file exists there. Neither designation grants removal authority.

| REVIEW source child | Comparison child | Files | Bytes | Identical | Unique | Unique bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `s31d-uninstall-terminal/attempt-b/` | `s31d-uninstall-terminal/attempt-c/` | 263 | 26,318,391 | 230 | 33 | 1,723,037 |
| `s32-install/c/` | `s32-install/frozen/` | 260 | 27,358,530 | 236 | 24 | 2,024,672 |
| `s32-install/final/` | `s32-install/frozen/` | 260 | 27,359,411 | 238 | 22 | 1,792,757 |
| `s32-install/final-2/` | `s32-install/frozen/` | 260 | 27,360,274 | 240 | 20 | 1,445,202 |
| `s32-install/repair-a/` | `s32-install/repair-e/` | 32 | 1,322,268 | 13 | 19 | 494,526 |
| `s32-install/repair-c/` | `s32-install/repair-e/` | 32 | 1,323,329 | 14 | 18 | 493,977 |
| `s32-install/repair-d/` | `s32-install/repair-e/` | 32 | 1,323,329 | 14 | 18 | 493,977 |
| `s29-removal-namespace/scenario-a2/` | `s29-removal-namespace/scenario-a4/` | 47 | 601,802 | 36 | 11 | 17,154 |
| `s29-removal-namespace/scenario-a3/` | `s29-removal-namespace/scenario-a4/` | 47 | 601,801 | 36 | 11 | 17,153 |
| **Total** | | **1,233** | **113,569,135** | **1,057** | **176** | **8,502,455** |

The comparison roots are the final or later accepted evidence named in the
S31-D `RESULT.md`, S32 `RESULT.md` and S29 namespace contract `RESULT.md`.
S31-D `attempt-b` passed before the final `attempt-c`; S32 `c`, `final` and
`final-2` passed then-current scenarios before `frozen`; S32 repair attempts
preceded `repair-e`; S29 namespace `scenario-a2/a3` precede `scenario-a4`.
Their recorded results and filenames are still historical references.

The 176 unmatched files include distinct compiled Editor/test binaries, exact
script versions, manifests, logs and generated fixture records. None of these
nine complete child directories has a byte-exact replacement. This is an
inventory fact, not a retention decision: differing intermediate bytes do not
by themselves require preservation. The source-tree SHA-256 of each child,
using ordinal relative path, TAB, lowercase file SHA-256, LF and UTF-8 without
BOM, is recorded in the JSON inventory.

Inventory generation checked for reparse points under every source and
comparison root. An independent pass rehashed all 1,233 source file entries
and 1,057 mapped comparison paths: zero mismatches. No Unity, tests, Package
export, runtime action, archive, move or deletion was performed.

Current policy disposition: these nine superseded children are candidates for
intentional deletion after each owning stage, final result, consumer reference
and rollback need is checked. No byte-for-byte replacement or new archive is
required for a confirmed intermediate. This review does not establish those
checks for every child and grants no cleanup authority. Before physical
cleanup, freeze exact targets, recheck file count/hashes, containment, reparse
safety, references and live holders, then record a deletion receipt and lost
recoverability. Any child with necessary unresolved-failure evidence must be
excluded or given a separately reviewed evidence disposition.

Subsequent disposition, 2026-10-20: the user authorized the exact first batch.
All nine test children in this inventory were removed after the frozen
per-file identities and execution gates passed. See `CLEANUP-BATCH-01-RESULT.md`
for the receipt. The comparison roots and all other test groups were excluded.

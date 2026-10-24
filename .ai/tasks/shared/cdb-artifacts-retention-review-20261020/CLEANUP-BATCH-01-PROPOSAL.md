# Cleanup batch 01 proposal: intermediate tests and S29 backups

Status: `PROPOSED / READ_ONLY / DELETION_NOT_AUTHORIZED`.

This proposal applies the current artifact lifecycle rule to 27 exact child
directories. It does not authorize cleanup, change historical task results, or
claim that the rest of `.artifacts/` and `.backups/` has been reviewed.

## Exact deletion candidates

All paths are relative to `<repository-root>`. Delete each named child only;
never clear either storage root or its parent task directory.

| Group | Exact child directories | Files | Bytes |
| --- | --- | ---: | ---: |
| `.artifacts/tests/s31d-uninstall-terminal/` | `attempt-b/` | 263 | 26,318,391 |
| `.artifacts/tests/s32-install/` | `c/`, `final/`, `final-2/`, `repair-a/`, `repair-c/`, `repair-d/` | 876 | 86,047,141 |
| `.artifacts/tests/s29-removal-namespace/` | `scenario-a2/`, `scenario-a3/` | 94 | 1,203,603 |
| `.backups/` | The 18 S29 children listed below | 36 | 218,570 |
| **Total** | **27 children** | **1,269** | **113,787,705** |

The nine test children have file-level path, length and SHA-256 identities in
`.artifacts/maintenance/artifact-retention-review-20261020/review-candidates.json`
(SHA-256 `298ee842b3305ef1052a251c9f5563811086c6599a5de2dc273744bf944dbf28`).
The owning records identify later/final evidence under `attempt-c/`, `frozen/`,
`repair-e/` and `scenario-a4/`. Their differing intermediate bytes do not
establish a continuing retention need. The S29 scenario children here belong
to the namespace-contract task; the history-authority task's similarly named
run is under a different evidence root.

The `.backups/` candidates, each containing only `manifest.json` and
`packages-lock.json`, are listed below. Their per-directory identities are in
`BACKUP-CANDIDATES-SHA256.txt` in this task directory.

```text
s29-control-auth-recovery-7c82ff4/
s29-coordinator-readiness-repair-427a424/
s29-generation-alignment-d127a45/
s29-historical-handoff-04e9a6b/
s29-manager-admission-1889abe/
s29-manager-admission-3077ee6/
s29-manager-admission-b76957a/
s29-path-compile-reference-20261009/
s29-path41-reference-20261009/
s29-rc41-reference-20261009/
s29-removal-history-authority-5b52c01/
s29-removal-namespace-39d79ae/
s29-removal-process-identity-544be4f/
s29-retained-disposition-74c4db0/
s29-startup-auth-boundary-c6c2f03/
s29-upgrade-callsite-fix-34b3a65/
s29-version-transition-observation-14444cf/
s29-version-transition-wrapper-handoff-d88a10/
```

S29 is archived, and its complete validation project was previously deleted
under a separate exact authorization. These pre-switch files no longer provide
a live rollback route for that project. Historical records that mention them
remain unchanged; a future deletion receipt must state that their old bytes
will no longer be recoverable from these backup paths.

## Outside this batch

Retain the four later/final test roots named above and all other `.artifacts/`
children. Do not include the retained S35 evidence, current Package deliveries,
validation evidence, release candidates or other test groups by parent-name
matching. The remaining `.backups/` children require separate review. In
particular, the worktree residual contains sole historical source records;
S30's baseline-reset backup contains a moved action index; and S34's backup
contains `protected-s33.xml`, an S33 historical evidence inventory. Their
disposition is not decided by this batch.

## Execution gate

Before any approved deletion, recheck the exact resolved targets against the
repository root, reparse entries, current file counts and per-file hashes,
declared consumer references, rollback needs and relevant live holders. Stop on
the first mismatch. Deliberate removal of these confirmed intermediates needs
no replacement archive. Append a deletion receipt with the exact removed
paths, file/byte counts, retained authoritative evidence and recovery limits.
No Unity launch, process termination, reference rewrite, commit or push is part
of this proposal.

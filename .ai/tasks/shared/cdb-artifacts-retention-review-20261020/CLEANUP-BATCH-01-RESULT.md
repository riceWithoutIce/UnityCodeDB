# Cleanup batch 01 result

Date: 2026-10-20.
Status: `COMPLETE / EXACT_TARGETS_REMOVED / BROADER_REVIEW_OPEN`.
Authorization: user `同意 开始清理` for `CLEANUP-BATCH-01-PROPOSAL.md`.

The authorized batch removed only the 27 exact child directories in the
proposal. The execution log is `CLEANUP-BATCH-01-EXECUTION.jsonl`, SHA-256
`45ffcc955ab96429e4df88803c82028bded43e3dae4738560c3008efa2c5e68e`.
It contains one preflight event, 27 per-target removal events and one complete
event. The proposed path list and the log together are the exact deletion
receipt; historical task/result records have not been rewritten.

| Storage | Removed children | Files | Bytes |
| --- | ---: | ---: | ---: |
| `.artifacts/tests/` | 9 | 1,233 | 113,569,135 |
| `.backups/` | 18 | 36 | 218,570 |
| **Total** | **27** | **1,269** | **113,787,705** |

The same full preflight passed in read-only mode and again immediately before
removal. The nine test children matched every path, length and SHA-256 in the
frozen JSON inventory. The 18 S29 backup children each contained only the two
declared Package configuration files and matched the frozen directory hashes.
All targets were within the intended repository storage roots, with no reparse
entries or nested Git state. Exclusive read opens succeeded for every file.
Three retained Package projects' parsed manifest/lock values and current
process command lines showed no reference to an exact target. S29's complete
validation project remained absent. This is a bounded consumer/process check,
not a claim about every possible external reference or file handle.

Postcheck parsed the log and confirmed 27/27 targets absent, with the recorded
file and byte sums above. The retained test roots `attempt-c/`, `frozen/`,
`repair-e/` and `scenario-a4/` still exist with their expected file counts.
The S35 project evidence and the excluded S30 baseline-reset, S34 history
inventory and worktree-residual backups still exist. `.backups/` now contains
18 directories, 79 files and 4,369,980 bytes; no S29 backup directory remains.

This was intentional deletion of intermediate bytes without replacement
archives. The earlier attempts and pre-switch S29 configuration bytes are no
longer recoverable from these paths. Their recorded outcomes and provenance
remain in the task records and prior review inventories; those records are not
substitutes for rerunning an old fixture. Other `.artifacts/` and `.backups/`
children remain for separate disposition. No Unity launch, process termination,
Package reference rewrite, commit or push was performed.

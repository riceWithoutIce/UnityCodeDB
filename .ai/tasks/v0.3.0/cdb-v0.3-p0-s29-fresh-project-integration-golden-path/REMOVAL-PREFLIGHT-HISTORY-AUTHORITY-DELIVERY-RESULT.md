# S29 removal history authority — delivery result

Date: 2026-10-15. Status: DELIVERY_COMPLETE / HUMAN_REPORTED_PASS / S29_PARTIAL.
Source commit: `5b52c017e8415bb061f33a8380b3dcec2916411a`.
Subject: `fix: separate removal history authority sources`.
User delivery grant: `同意授权` for commit, exact export, S29 reference switch and
human Unity acceptance.

## Exact Package

Package review root:
`G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-history-authority-5b52c01/review/com.rice.ai-codedb`

ZIP:
`.artifacts/s29-removal-history-authority-5b52c01/com.rice.ai-codedb.zip`

SHA256:
`7e39a1ab41fbe5da5417cc73557ec8e7f4bc5837a52180ed40caaace35183d32`

617 files / ZIP entries; 13,218,218 uncompressed bytes. Package version,
generation and runtime contract remain unchanged. Commit-staged and exact-ZIP
production admission, native closure and byte closure passed. Exact Package
PathProvenanceOnly passed. No Payload regeneration or generation transition.

## Commit and reference switch

Only the three accepted source/test files are in commit `5b52c01`; unrelated
dirty files were not staged. S29 project:
`G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.

Both `Packages/manifest.json` and `Packages/packages-lock.json` now select:
`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-history-authority-5b52c01/review/com.rice.ai-codedb`.

Post-switch hashes:

```text
f5c97a3380b59db8b9dab4e206f7e464894ab335b1ae5c2d87efe76cb136cda3  manifest.json
3a5c6b00dd9d20604086eb178bf3f0a8dfa82be2014a2198dadee78f80b0c452  packages-lock.json
```

The S29 Unity process was absent and its UnityLockfile absent before switching.
The pre/post protected snapshots contain 5680 entries and report zero unexpected
changes; only the two authorized Package reference files changed. A backup is at
`.backups/s29-removal-history-authority-5b52c01/`.

The first reused protected-snapshot helper had the wrong artifact directory
depth and stopped before creating a valid baseline; no product or project state
was changed. A corrected task-owned helper then produced the 5680-entry baseline
and the passing post-switch comparison. The mechanical error is retained in the
terminal evidence and is not a product-gate failure.

## Human gate and limits

Human checklist: REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-HUMAN-CHECKLIST.md.
Do not click Install, Remove or Upgrade. Do not run the separately parameterized
isolated fixture in Unity. No real removal, history repair, process control,
release or Ready/Install admission is claimed. Missing-child histories and
CleanupMono remain deferred. After the user report, only bounded read-only
attribution is allowed; do not repeat delivery.

Human result: REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-HUMAN-RESULT.md. The user
reported that Test Run passed and that the other operations had no abnormal
behavior. This closes the human smoke gate for this exact package; it does not
unlock real removal or change the declared S29/release partial boundary.

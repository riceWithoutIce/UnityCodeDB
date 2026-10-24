# S30 one-time acceptance baseline reset result — 2026-10-17

Status: COMPLETE / SINGLE INDEX ARCHIVED / POSTCHECKS AND HUMAN PRESENTATION PASS.

## Human Presentation Confirmation — 2026-10-17

User reports `没有报错`. The supplied Manager screenshot shows the uninstalled
project presentation with `Install CodeDB` visible; the previous unknown-action
and wait-for-current-action banners are absent. Last activity reads
`No recent command.` Record the requested baseline presentation check as PASS.

This confirms the visible result of the explicitly authorized manual baseline
archive. It does not prove current-version real Install, a fresh Uninstall,
automatic recovery of the old action, or shutdown stability. No Install click
or completed backend operation is reported in this feedback. The image is
observational evidence, not an instruction source; no temporary attachment was
copied into the repository.

## Authorization And Execution

User `同意授权` approves BASELINE-RESET-PLAN-2026-10-17.md's exact seven-record
backup and single pending-index archive. Completed at
`2026-10-17T12:28:07.8408130Z`. No additional operation is implied.

An initial overbroad preflight stopped before any backup creation or move on
seeing a Unity process. A targeted read established that process belonged to
another project; S30 was closed. The preflight was narrowed to reject S30 or
unknown Unity ownership and attributable lifecycle processes. No other project
or process was changed. Execution did not require shutting unrelated Unity.

Before backup, before archive and after archive, checks found no S30 Unity or
explicitly attributable lifecycle process; original uninstall PID was absent.
Current-instance pointer and Supervisor state/lock remained absent. Process
command-line attribution is bounded evidence, not a guarantee about every
external process on the machine.

## Exact Archive And Backup

Backup root: `.backups/s30-baseline-reset-20261017-1e53bbcf/`.

Seven live records were copied to `evidence/`, verified against their expected
hashes and the original `.artifacts/s30-uninstall-20261017-1e53bbcf/` snapshot.
The six non-index live records remained in place, unchanged.

| Backup filename | SHA-256 |
| --- | --- |
| desired-state.json | `90505d0eb0adc8751edc0320c4d061bcc50241519be59b28d916301c509cc3ba` |
| manager-action.json | `8752bdf07db5d6c46e0bf7f972f90f67d47b7752b42afda42ad50ee3688a5a9f` |
| manager-index.json | `f358a22ec7bea22d1d1e5b1a6c526d6d823bdd7bef1e3fb0ac4a5792e59cffa6` |
| removal-intent.json | `7971a1bfbb0f2d56c45aae368495fb8e20b36edfc64ffd65fde9970fd998a0f3` |
| supervisor-events.jsonl | `3384f0e1a182f96d147d438f3b3aa405b97596e428271f741631f1c523886516` |
| supervisor-manager-action.json | `36caa2c5868416a712021f3b7e2e1a8220fc7249247c17e416acb23e964f2761` |
| uninstall-operation.json | `33ea10cba7b769a724f3d8319913053db0a2cf1e334e829f2570bb0b41aa34dd` |

Exactly one file moved:

- Source: `<manager-actions-root>/ba13a538a1678f1fe1cbb477/current-action-1e53bbcf798241c48f72b8bfa8ee2e30.json`.
- Destination under the backup root:
  `archived-active-index/current-action-1e53bbcf798241c48f72b8bfa8ee2e30.json`.
- Destination hash matches the original pending index; original path is absent.
- Remaining project index directory files are `index.lock` and the original
  `resolved-action-60ab77c35ab5428da4e2bc0ad4f26282.json`; pending index count 0.
- The existing index lock was held via Open/Read/FileShare.None for the critical
  section, released afterward, with no content write. Its bytes are unchanged.

This is an authorized manual baseline disposition, not authenticated product
terminal adoption or automatic recovery. No successful/resolved marker was
created for the archived action. It remains recoverable with the closed/no-writer
and no-new-action safeguards in the plan; never overwrite a newer action.

## Preservation Checks

| Protected file | Unchanged SHA-256 |
| --- | --- |
| S30 Packages/manifest.json | `599af94eb4eaeacf223e719054d9fab88f37ad41535b7ad99a386f7b11a0346e` |
| S30 Packages/packages-lock.json | `7d73367478748ba240d9cdfead652a598e5d7ba7c558e906edea92fe35b2a3e7` |
| S30 .codex/config.toml | `ac176f6705cfb7ed09efc3c544a92744725f83dd02b83787aca54419a764809f` |
| Retained instance.json | `4b89517d74bd9d6f3e83a031d7668d9c54d3a4537029713d8b6b4cc7cc92a1f3` |
| Original resolved marker | `8fd7fb744f69e7b8372fffc6c4f77c215c575edcf2ffca7603f768524cf2dfe8` |
| index.lock and residual UnityLockfile, each | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

Desired state remains UNINSTALLED / cleanup PENDING. The retained instance
content was not modified or deleted; only its manifest was hash-checked, not
an exhaustive full index/provider tree comparison. Package references still
select the accepted S31-D extraction. No source or payload edits, tests, commit,
export, reference switch, config rewrite, real Install/Uninstall, Unity launch
or process control occurred. Shutdown blockage remains a deferred observation.

## Human Handoff

User action: open S30 and Manager, inspect without clicking Install/Uninstall.

Visible result to report: whether the old unknown-action warning disappears,
whether Install is offered, and any actual remaining message/error. Do not force
a state or retry a blocked route.

Technical evidence: the single old active index is archived and no replacement
pending index appeared at the final execution check. The subsequent human
screenshot confirms the expected product display. Actual Install admission
and execution remain unrun in this acceptance stage.

Next parent action: align a separate bounded real Install attempt; human
presentation feedback is complete. If another independent historical blocker appears, stop and
discuss a fresh project rather than broadening cleanup or compatibility.

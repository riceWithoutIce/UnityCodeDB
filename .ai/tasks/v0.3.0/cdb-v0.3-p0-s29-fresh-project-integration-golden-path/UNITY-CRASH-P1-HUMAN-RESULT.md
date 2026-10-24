# P1 repaired-package human result — 2026-10-10

Scoped result: HUMAN_NORMAL_CLOSE_PASS / READ_ONLY_LOG_CORROBORATED.
S29 overall acceptance remains PARTIAL. Manager readiness is unresolved.

## Human evidence

The user supplied Manager screenshot
`C:/Users/admin/AppData/Local/Temp/codex-clipboard-5d99abd3-5cf1-4055-bbd8-915202be6df0.png`
and explicitly reported that Unity closed without crashing. The screenshot
shows NeedsAttention with `The Supervisor IPC request timed out.`, reason
`COORDINATOR_OPERATIONAL`, and observation binding containing
`070d3698a9c745b2aac8c13790823658`, owner epoch
`b6e25d65d954454e9a904b3ef9787f46`, revision 84.

## Read-only corroboration

- Manifest and lock both select
  `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-unity-crash-p1-9a2ca41/review/com.rice.ai-codedb`.
- Exact ZIP SHA-256 remains
  `153816dd39868a104937f193147b1322d51f1645461684f22bfcf754a1f3b597`.
- Extracted repaired source SHA-256 remains
  `709a9ec78e05c3daa4d907cfbedc8b2fcebe6bf11fd4bd2c01d56a429d35e75f`.
- Shared Editor.log contains repaired-package frames and main-thread quitting
  checkpoints, then Input System shutdown and Cleanup mono (lines 632–651).
  It contains zero `Crash!!!`, `GetManagerFromContext`, or `Fatal Error` matches
  at inspection. No new crash directory was found; the retained incident is
  `Crash_2026-10-10_031602735`.
- No S29 Unity process was running at inspection. The unrelated miniGame_int
  Editor and import workers were left untouched. Shared Editor.log also contains
  unrelated application output; this is bounded corroboration of the attributed
  S29 session, not a claim that the entire file belongs to S29.
- `shutdown_completed` is absent as expected after removing that asynchronous
  Unity logging path. Quitting checkpoints show NOT_EVALUATED disposition;
  they do not prove final asynchronous shutdown command success.

## Separate readiness evidence

Supervisor operation `f1fc21ae529b494e96efd708041ccf28` is a completed maintenance
Probe from the repaired package: exit 0, not timed out, stdout PRODUCT_STATE
READY, observation ID matching the screenshot and revision 84. It completed at
2026-10-10T05:55:09.587Z (13:55:09 Asia/Shanghai).

Editor evidence records Ready followed by NeedsAttention. At
2026-10-10T05:56:42.499Z the Supervisor records retirement due to
`coordinator_offline`, followed by `The Supervisor owner epoch ended before the
queued query completed.` These shutdown-stage events establish sequence only;
they do not prove the cause of the earlier displayed IPC timeout.

Current selection remains instance `d620abbab0334a2d9c49e59888c1ef55`, generation
poc.42, activation epoch `2f8b2a509a1e4086af4a4457e618d037`, and manifest hash
`664d0a7d99ce67c32f4537fecae076c3efcd0ac4e2aee8260957d4269302df62`.
The successful INSTALL action dc72675b… has an existing resolved marker with
CommandTerminal disposition; historical failed receipts remain preserved.

## Disposition

The P1 repaired-package normal-close runtime check passes for this one human
attempt. This does not establish repeated shutdown reliability or whole S29
acceptance. Resume the separate IPC/readiness diagnosis from the evidence above;
do not mask timeout as Ready or conflate cleanup PENDING with install failure.

Only this task record was added. No source fix, Install/Uninstall, export,
reference switch, commit, process control, or Unity automation was performed
during this follow-up.

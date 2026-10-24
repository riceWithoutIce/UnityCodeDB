# S33 logical Uninstall result - 2026-10-19

Status: LOGICAL_UNINSTALL_PASS / CLEANUP_PENDING / REINSTALL_NOT_RUN.

## Human evidence

User reports `卸载成功了` and supplied screenshot ending
`codex-clipboard-76211923-0a00-4702-9f7d-a8910aae3a5f.png`. The Manager shows
`CodeDB is uninstalled from this project`, an available `Install CodeDB` entry,
and Last activity `Uninstall CodeDB from Project` with `Completed`, `Exit 0`.
The UI also says the command completed with warning; that warning is preserved
as a separate handoff/cleanup observation below.

## Exact operation evidence

- Manager action id: `bb9581b9872b419689da6eea91ff2ba8`.
- Exact operation id: `62fd5e331b76430983d23fd5611f9906`.
- Operation: `materialize:Uninstall`, state/phase `completed`.
- Started `2026-10-19T01:53:11.076Z`, completed
  `2026-10-19T01:53:20.676Z`.
- Writer exit code `0`; timed out `false`; output overflow and incomplete
  drain both `false`; stderr empty.
- Command result: `UNINSTALL / UNINSTALLED / COMPLETE /
  LOGICAL_UNINSTALL_COMPLETE`, mutated scope `instance_activation`.
- Project identity and selected instance in the operation match S33 and the
  pre-action baseline: instance `1f69a1ae6d4a4b3085c92c6bc1c56dd7`, generation
  `poc.43`, runtime contract `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.

## Postconditions observed read-only

- `desired-state.json` is `UNINSTALLED`, cleanup remains `PENDING`.
- `current-instance.json` is absent.
- `.codex/config.toml` has the prior owned MCP table retained as
  `rice-ai-codedb-uninstalled:<state_id>` comments; no unrelated content was
  observed in the file.
- Unity Package manifest/lock still reference the same local Package, as
  expected for logical project Uninstall.
- Operation result states: prior instance remains inert and pending; no external
  MCP process was stopped.
- Exact operation has `handoff_queued=true`, reason `selected_instance_changed`.
  This explains the UI warning and is a separate runtime handoff/cleanup fact;
  it does not invalidate the logical Uninstall terminal.

## Acceptance boundary

Logical Uninstall is PASS. Physical retained-content cleanup, external process
retirement and watcher drain are not claimed complete. No process was killed,
no retry or manual cleanup was performed, and no source/package/reference was
changed. Same-version reinstall is a separate confirmed action and remains
NOT RUN; it must not begin until this result is accepted and its own grant is
made.

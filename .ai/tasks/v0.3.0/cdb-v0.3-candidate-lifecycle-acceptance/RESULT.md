# Candidate close/reopen result — 2026-10-26

Outcome: `HUMAN_CLOSE_REOPEN_PASS / BASELINE_STABLE_PASS`.
Candidate: `11056964da1143955ed69a067361622799e3d6f2`.
Package: 0.3.0-preview.5; generation poc.44.

## Human result

After the instructed one-cycle normal close/reopen, the user reported:
"重开后没有编译报错 ready了".

Record as human-confirmed successful project reopening, no compilation errors
reported and Manager Ready. No automated Unity launch/stop or UI inspection
was performed. No exact shutdown/startup times or intermediate states supplied;
none invented. Window/project reopening does not prove full process/lease drain,
absence of retained MCP sessions or long-term stability.

## Permitted read-only baseline recheck

Captured 2026-10-26T02:14:13.189Z. All named bindings match the pre-cycle values:

| Input (project-relative) | Result |
| --- | --- |
| Packages/manifest.json CodeDB reference | `file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb` |
| Packages/packages-lock.json CodeDB reference | Same candidate reference |
| AIWork/.runtime/codedb/control/current-instance.json SHA-256 | `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a` |
| .codex/config.toml SHA-256 | `2d288afd9490ad2f51560f5a62658f12d2bb456326980e919b894035b3f0c2fd` |
| Assets/CodeDBValidation/CodeDBQueryProbe.cs SHA-256 | `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432` |

No consumer files, Package source, registration, pointer, probe, runtime state
or processes were changed by this development session. No tests/MCP calls,
log/lease/process scans, forced domain reload, install/repair/restart/uninstall,
extra human cycle or retry requested or executed. Existing dirty records and
isolated work retained; only this task's status/result records written.

## Closed slice and remaining gates

This same candidate's single human close/reopen flow is PASS, with stable
on-disk bindings. It joins the earlier source/export/delivery evidence, initial
human compile/Ready, bounded target-client status/query and F01 output snapshot.
Those earlier results remain separately attributed and are not repeated here.

Post-reopen real MCP query, response identity, shutdown ownership/process drain,
uninstall/fresh-install, crash recovery, other lifecycle permutations, continuous
stability, EditMode, performance and release are not established by this slice.
No commit/push, board update, new Package or release.

Next proposed slice: one normal user-initiated Manager Uninstall on this same
candidate, with a frozen pre-change baseline and explicit cleanup/result scope;
stop on its first actual anomaly. Do not manually stop retained MCP components
or remove runtime state to make the path pass. This is a proposal only, not an
Uninstall authorization or instruction to click now. Fresh Install and its
subsequent close/reopen follow only after the agreed prior-stage result.
Historical exit 6 is preserved context; no automatic retry or writer-policy
change follows from this success. Current slice stops here.

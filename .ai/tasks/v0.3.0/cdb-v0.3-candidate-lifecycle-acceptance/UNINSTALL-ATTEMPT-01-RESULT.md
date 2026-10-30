# Uninstall attempt 01 result — 2026-10-26

Candidate: `11056964da1143955ed69a067361622799e3d6f2`.
Action ID supplied by Manager: `ff2dc5eb61ad488186fd31a5556b5d40`.
Classification: `LOGICAL_UNINSTALL_REPORTED / CLEANUP_PENDING /
SUPERVISOR_HANDOFF_UNCONFIRMED`.
One human Manager action, no retry or agent-invoked mutation/MCP call.

## Human/UI and raw output

User reported "卸载成功". Attached Manager screenshot shows Uninstalled,
Completed, Exit 0, retained Package v0.3.0-preview.5, and "Command completed
with warning." The screenshot's collapsed output did not explain the warning;
the user then supplied the following complete Copy output text:

```text
Command completed with warning.

Exit Code: 0
Action ID: ff2dc5eb61ad488186fd31a5556b5d40

Output:
[CONFIRMED] Uninstall is scoped to CodeDB-owned paths in this Unity project.
[RESULT] UNINSTALLED
[CLEANUP_STATE] PENDING
[RETAINED] Cleanup remains pending; no external MCP process was stopped.
[NEXT] The prior instance remains inert and pending; use Install CodeDB to create a fresh integration.
[COMMAND_RESULT] {"schema_version":1,"managed_by":"com.rice.ai-codedb","action":"UNINSTALL","outcome":"UNINSTALLED","phase":"COMPLETE","reason_code":"LOGICAL_UNINSTALL_COMPLETE","mutated_scopes":["instance_activation"],"cleanup_state":"PENDING","next_action":"The prior instance remains inert and pending; use Install CodeDB to create a fresh integration.","exit_code":0,"detail":""}

Supervisor handoff warning:
[SUPERVISOR_HANDOFF_UNCONFIRMED] The uninstall command completed, but this recovered backend terminal does not confirm Supervisor handoff. A later action must pass its own ownership and admission checks.
```

This is supplied backend output, not an independently read authenticated terminal
receipt. No terminal file path was supplied; no action directory/process/lease
scan was substituted to discover one in this slice.

## Bounded post-action disk evidence

Snapshot at 2026-10-26T02:20:45.084Z:

- Selected current-instance pointer absent.
- Project registration file remains but changed to CodeDB uninstall-marker
  comments. Follow-up line interpretation found zero active target TOML sections
  and one commented target section: target registration is deactivated on disk.
- Prior selected instance.json retained, with unchanged SHA-256
  `61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced`.
  Its retained existence/READY content does not restore selection or prove an
  active process. No process/lease inference is drawn from that file alone.
- Package manifest and lock bytes unchanged; both still reference candidate
  `file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
  Project integration uninstall does not remove the UPM Package.
- Original fixed probe unchanged:
  `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.

Evidence:
`.artifacts/tests/cdb-v0.3-candidate-lifecycle-acceptance/uninstall-attempt-01/`
contains pre-click baseline/preimages, post-uninstall-snapshot.json and
registration-interpretation.json. The initial snapshot's
target_registration_entry_present=true was a literal substring match against
commented text, not a claim that an active registration survived. The explicit
follow-up distinguishes active TOML from retained uninstall comments; original
snapshot preserved without rewriting it.

## Separate outcomes and stopping point

| Aspect | Assessment |
| --- | --- |
| Human command completion | PASS, Exit 0 / Completed |
| Backend-reported logical uninstall | UNINSTALLED / LOGICAL_UNINSTALL_COMPLETE |
| Selected pointer removal | Confirmed by disk snapshot |
| Project registration deactivation | Confirmed active section absent; preserved as comments |
| Physical cleanup | PENDING as reported; full removal not asserted |
| Supervisor handoff | Explicitly UNCONFIRMED; not independently established |
| Fresh Install admission/readiness | NOT_RUN / NOT_ESTABLISHED |

The frozen contract permits inert retained content with logical
UNINSTALLED/PENDING; PENDING or retained bytes alone is not a defect or demand
to kill readers/delete files. Conversely, command exit 0 does not prove
Supervisor handoff/active-authority closure. Do not upgrade this to complete
lifecycle PASS or claim the next Install is safe merely from a missing pointer.
The recovered-terminal warning does not itself prove a live Supervisor or
product bug either. Preserve that uncertainty and attribute the next check.

Stop before Fresh Install. Next proposed work is bounded read-only attribution
of this Action ID's terminal/handoff evidence under a concrete direct-source
path plan, without runtime startup, forced holder drain, repair or replay. The
existing Install backend must still enforce its own admission; no override is
authorized. No new code issue/reconstruction or broad heartbeat investigation
is opened by this receipt.

No files/processes were changed by the development session outside task evidence.
No extra Uninstall, Install, Repair, Restart, cleanup, MCP, Unity action, commit,
push, board update or release. The earlier close/reopen PASS remains separate.

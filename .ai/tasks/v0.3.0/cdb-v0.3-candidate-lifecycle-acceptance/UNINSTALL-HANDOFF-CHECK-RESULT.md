# Exact-action uninstall warning attribution — 2026-10-26

Outcome: `EXACT_ACTION_TERMINAL_MATCH / NO_CONCRETE_CONFLICT_OBSERVED`.
Candidate: `11056964da1143955ed69a067361622799e3d6f2`.
Action: `ff2dc5eb61ad488186fd31a5556b5d40`.
Operation: `2ad3150d6b88440691092fe4f9e172e4`.
This closes the approved read-only attribution slice, not the lifecycle gate.

## Warning origin

`com.rice.ai-codedb/Editor/AICodedbSupervisorTerminalEvidence.cs` adds
`SUPERVISOR_HANDOFF_UNCONFIRMED` when its exact-action history reader returns a
successful recovered terminal. This expresses the reader's evidence limit;
it is not an assertion that a handoff failure was recorded.
`AICodedbSupervisorBridge.cs` retains that warning unless it receives explicit
handoff-complete evidence, or replaces it with an explicit handoff-failed result.
The supplied warning is the generic recovered-terminal variant.

`Tools~/codedb-project-supervisor.mjs` records `handoff_queued=true` after a
successful materialization changes the selected instance, and schedules natural
retirement. Queued retirement is separate from completed retirement.

## Direct-path evidence

Derived runtime from the candidate payload control contract and source producer:
`<external-test-root>/AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor`.
Read only this action's map, its single bound operation, exact Manager action
manifest and exact current/resolved index paths. No other action enumeration.
Supervisor state/lock existence was observed without reading their contents.

Snapshot UTC: `2026-10-26T02:29:21.200Z`.

| Evidence | Observed result |
| --- | --- |
| Action map | One operation, latest ID equals sole operation ID |
| Original project/Package/runtime/action binding | Matches named target and candidate |
| owner_epoch/request_id/instance/generation/contract | Map and operation agree |
| Selected instance/generation | `a492a5e936c14e4da3ed7e4cc7c8c16c` / `poc.44` |
| Runtime contract hash | `ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5` |
| Operation | `materialize:Uninstall`, maintenance, completed/completed |
| Started/completed UTC | `02:18:29.200Z` / `02:18:39.270Z`, 2026-10-26 |
| Child invocation | Exact expected Uninstall argv and argv SHA-256 match |
| Terminal | Exit 0; stderr empty; timeout/overflow/drain-incomplete all false |
| Backend output | Matches supplied `UNINSTALLED / LOGICAL_UNINSTALL_COMPLETE / PENDING` |
| Handoff | Queued, reason `selected_instance_changed` |
| Manager current index | Absent |
| Manager resolved index | Matching identity; `resolved / CommandTerminal` |
| Supervisor state/lock | Both absent at this snapshot |

The recovered operation binding and terminal result are consistent; the Manager
journal has resolved the action. This is an offline record check, not a rerun of
the live recovery reader: its pending current-index precondition no longer exists
after resolution. The prior uninstall snapshot already established pointer
removal and registration deactivation; that receipt is preserved separately.

## Evidence files and execution limits

Artifact root:
`.artifacts/tests/cdb-v0.3-candidate-lifecycle-acceptance/uninstall-handoff-check-01/`.

- `snapshot.json`: sanitized exact-path evidence and source-file hashes;
  SHA-256 `6d0cdf0c80aee0f03e8858b0ddc054cb198ada092692b486f01065324cec79a3`.
- `verification.json`: additional checks against the retained snapshot only.
  All 12 snapshot checks and 10 additional checks passed.
- Action map SHA-256:
  `9bf2719e8ad992a5afaf6ddef8643e34ccaa3db0d71af44fb985e5691a072689`.
- Operation history SHA-256:
  `ed588a34ca6310869a447846d6d599dcc5a9e4b59bd71bf1bf882f89d52fc170`.

`check-uninstall-handoff.cjs` is a task-local read/report helper, not Package code
or a runtime observer. It imports no product helper. The initial reporting pass
stopped before persistence because sanitization detected an additional machine
executable path. One permitted mechanical correction redacted it and repeated
the same exact-path reads. Two passes total, six JSON paths per pass (including
one absent path), within the 16-record budget; one persisted snapshot. Largest
record was the 63,048-byte payload manifest. This did not replay any runtime
action. A report patch context mismatch was corrected without external rereads.

## Decision and next route

Logical uninstall is supported by matching terminal and prior disk evidence.
Physical cleanup remains `PENDING`, permitted for retained inert content. The
generic warning and pending cleanup do not establish a defect requiring repair.
No concrete conflicting authority was found within this envelope.

State/lock absence is only a disk observation. Actual Supervisor process exit,
external MCP holder liveness and completed handoff were not independently proved.
Do not infer them from absence, and do not require a nonexistent retrospective
handoff certificate before every later action.

The legitimate next route is one separately human-confirmed **normal Manager
Fresh Install**, keeping the same candidate and natural retained-holder state.
Its existing ownership, convergence and admission checks remain authoritative;
this report neither bypasses them nor predicts success. Capture its action ID,
complete output, exit/outcome/cleanup state and any warning. On a blocked/failed
or unknown result, preserve it and stop without another click, repair, forced
drain or manual cleanup. Subsequent Ready, reopen and real-client checks remain
separate stages.

No Install, retry, RPC/MCP call, process/lease scan, log scan, component startup,
product-source edit, consumer/configuration mutation, Unity launch/stop, commit,
push, board sync or release was performed. Only task evidence was written.

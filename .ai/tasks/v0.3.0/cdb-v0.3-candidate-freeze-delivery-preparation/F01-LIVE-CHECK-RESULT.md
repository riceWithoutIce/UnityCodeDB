# F01 ordinary-Unity output check — 2026-10-26

Outcome: `BOUNDED_OUTPUT_OBSERVATION_PASS`. One read-only snapshot; no new
observer, callbacks, Unity/MCP call, lifecycle operation or runtime modification.

Candidate: `11056964da1143955ed69a067361622799e3d6f2`; current manifest/lock
references still resolve to that candidate's delivered directory. F01 source
SHA-256 reconfirmed:
`e939c8d8163ede9ca4a372a608fc5d7c66e24d83d230438e71db496048ea865e`.

## Observed results

| Check | Observed result |
| --- | --- |
| Pre-open transition sidecars | 0 at 2026-10-26T01:51:38.555Z |
| Snapshot transition sidecars | 0 at 2026-10-26T02:06:02.945Z; no additions or modifications |
| Editor log project attribution | Single command-line block, line 31; -projectpath line 33 explicitly resolves to the designated CodedbTest_2 |
| Full CODEDB_S12_EVIDENCE document prefix | 0 occurrences in the bounded snapshot |
| Candidate reference in compilation | Candidate-specific Manager source paths at lines 303/305/307 and 319/320/321 |
| Compile/build result | Tundra build success at line 318 |
| Domain reload evidence | Profiling sections at lines 236 and 338 |
| Log snapshot stability | Length and mtime unchanged during the read |

Log source is the standard `<LOCALAPPDATA>/Unity/Editor/Editor.log`, 39,905 bytes,
last written 2026-10-26T02:05:06.646Z. Snapshot SHA-256:
`2a09c9d103d37cb73621b9782d0f1edde90a2eaa6513b272f30121a4ad9c269b`.
No full raw log copy or machine paths persisted. The initial targeted display
was truncated because project-path matches included package listings; it was
not used as an absence oracle. Counts/line evidence above come from a separate
bounded complete file read and startup-identity check, without rerunning Unity.

Generated receipt:
`.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/f01-live-check-1105696/receipt.json`.
The pre-open baseline and original source/offline test records remain retained.

## Interpretation and limits

Current observations match the intended F01 effect: no new default transition
sidecars and no full evidence-document logging in this attributable Unity log.
The source default-off gate and prior extracted-body tests support the mechanism.
User-confirmed compilation/Ready and target-client functional PASS remain
separate evidence; this check did not repeat or replace them.

The Editor process diagnostics environment was not read. No exact loaded
assembly attribution, forced checkpoint coverage, explicit opt-in, shutdown,
Manager-close, fresh domain-reload or continuous long-term test was performed.
File timestamps bound this snapshot only; elapsed time since the baseline is
not a continuously observed stability interval. Nothing is inferred about
earlier overwritten/rotated log content or other Unity projects.

Incidental compiler warnings/Unity Search output in the same log were not
classified as F01 regressions or expanded into repairs. No suppression of real
product warning/error logging was requested or observed as part of this check.

F01's scoped ordinary-use output observation is complete; do not add a polling
loop, deeper environment attribution or repeated evidence merely to strengthen
an absolute absence claim. Next staged work can be the same candidate's human
close/reopen acceptance, then separately bounded uninstall/fresh-install steps.
Full lifecycle, performance and release remain open. No commit/push this turn.

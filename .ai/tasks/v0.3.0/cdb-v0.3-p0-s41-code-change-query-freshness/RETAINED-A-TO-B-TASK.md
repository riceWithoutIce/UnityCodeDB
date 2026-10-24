# S41 fresh retained-A-to-B observation after S42 delivery

Status: STOPPED_EXECUTOR_SYNTAX_ERROR_BEFORE_WRITE; see RETAINED-A-TO-B-RESULT.md.
The granted attempt is consumed; do not replay or resume this task.
The human agreed to the explained single A-to-B flow after the S42 real-client
status/fixed-query PASS. Executor: existing human-selected CodedbTest_2 chat.
No automatic messaging, new chat, subagent or model-setting change.

This is a fresh attempt using retained A, not a continuation or replay of the
original TASK.md. Its absent-file/create-A steps must not be executed. Preserve
the original stopped RESULT.md and all earlier evidence without reclassification.

## Frozen scope and budgets

Unity remains human-open, with the recently reported no-error / Manager Ready
starting state. If the human reports a newer conflicting state, stop. Do not
launch Unity or manipulate the existing target MCP connection.

Allowed source mutation: exactly one conditional A-to-B byte replacement in
<external-project>/Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs.
No file creation, restore, delete or .meta edit. Preserve all other bytes.
Unity's normal import/compiler/runtime outputs are allowed without intervention.

Maximum target codedb_text_search calls: 3, sequential and conditional.
Status calls: 0; other CodeDB calls: 0. Use only
mcp__codedb_codedbtest_2__codedb_text_search. No alternative service or manual CLI.
Exactly one 15-second wait after the B save if that step is reached. No baseline
wait, polling, extension, retry, refresh/rebuild/reconnect or recovery. Record
actual intervals including scheduling delays; 15 seconds is not a product SLA.

## 1. Bounded read-only preflight

Record actual cwd: must be the external CodedbTest_2 Unity root. Record a current
chat ID only if the host explicitly supplies one. Require the exact target tool
visible before any write or call; absence stops with zero mutation/calls.

Read target manifest/lock, project .codex/config.toml, selected pointer and its
instance manifest, retained A and protected original query probe only. Confirm:

- Both Package references: file:../../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb.
- Registration codedb-codedbtest-2, command node, cwd resolves to this project,
  args ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."], timeout 120.
- project_identity: sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c.
- instance_id: a492a5e936c14e4da3ed7e4cc7c8c16c.
- activation_epoch from pointer: 063aa347f49a4b9f955a5447f293a0ac.
- generation poc.44; Package 0.3.0-preview.5; instance state READY.
- Pointer SHA-256: 1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a.
- Instance manifest SHA-256: 61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced,
  matching the pointer's manifest hash. Do not require activation_epoch inside it.
- Retained A SHA-256: 2827d0f71db580099a13daad9c301407adeed331c8e4d0aa5413dfcebe2ce11c.
  File exists; line 5 is:
  internal const string Marker = "CODEDB_S41_FRESHNESS_A_20261022";
- Protected Assets/CodeDBValidation/CodeDBQueryProbe.cs SHA-256:
  d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432.

Retain exact A bytes in memory. On any mismatch stop; do not overwrite, repair,
rebaseline, inspect global configuration or widen to logs/processes/leases.

## 2. Establish A with one query, no mutation

Call exact target text_search once:
{"query":"CODEDB_S41_FRESHNESS_A_20261022","path_glob":"Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs","regex":false,"limit":5}.

Preserve full original response including isError/timing. Require exactly one
expected hit in this file at line 5 with A text. Missing/wrong hit, explicit
STALE, STARTING or host/tool error stops: A baseline NOT_ESTABLISHED, B NOT_RUN.
No B edit or additional call follows a failed baseline.

## 3. One edit, one wait, one B query

Only after A success, reread probe and require exact equality to preflight A.
Replace the unique literal CODEDB_S41_FRESHNESS_A_20261022 with
CODEDB_S41_FRESHNESS_B_20261022, preserving all other bytes and line positions.
Save exactly once. Record completed-save UTC, resulting bytes/hash and equality
to the expected replacement. Stop if the file changed independently.

Wait once for 15 seconds, recording wait start/end and actual duration. Then call:
{"query":"CODEDB_S41_FRESHNESS_B_20261022","path_glob":"Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs","regex":false,"limit":5}.

Require exactly the expected hit in the same file at line 5 with B text. Missing,
wrong, STALE or errored response stops; no A query or compensating action follows.
Record save-to-call interval and full original response, not just a summary.

## 4. One old-A absence query

Only after B success, immediately call the A query from step 2 once. Require a
successful zero-hit result for this scoped file. An old A hit, STALE or error
does not establish complete replacement. No further call follows any result.
The sequential B/A observations are not an atomic consistency guarantee.

## 5. Final evidence and stop

On success or first anomaly after preflight, finalize by rereading only the probe,
pointer and protected original probe. Compare to the expected terminal bytes and
starting hashes. If unavailable mark unverified, preserving the first failure.
No rollback/restore/delete. Leave A if no edit occurred; otherwise retain the
actual post-edit file, normally B. Do not edit/remove .meta.

Report actual cwd, human starting-state provenance, namespace, write/call counts,
complete raw responses in order, wait/save/call UTC and elapsed times, A/B hashes,
terminal sample state, pointer/old-sample stability and first failure separately.
Never invent a save time for retained A: its creation was in the earlier attempt.

PASS requires A baseline hit, B hit, old A absence, expected final probe bytes and
stable pointer/protected sample. Missing formal response identity fields remain
not provided, distinct from the scoped functional result. Distinguish NO HIT,
explicit STALE, old-content hit and tool/host error. Drift makes attribution
inconclusive, not permission to rebaseline. No product test suite is needed here.

This observation cannot establish convergence instant, 15-second SLA, complete
freshness signaling, heartbeat/timeout repair, performance or release readiness.
Stop when this envelope finishes. Any additional attempt or cleanup needs its
own human decision; never replay the original absent-file task.

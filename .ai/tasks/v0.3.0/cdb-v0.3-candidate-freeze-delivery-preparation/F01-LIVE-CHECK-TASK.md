# F01 bounded read-only live evidence — 2026-10-26

Status: COMPLETE / BOUNDED_OUTPUT_OBSERVATION_PASS. User "ok 继续" follows the proposed ordinary-Unity F01
output check before lifecycle acceptance. Same session; no new agent/worktree.

One snapshot only, no timed observer/retry or runtime action. Read closure:
pre-open diagnostic baseline, current target project's Library/CodeDB/Diagnostics
manager-ui-transition sidecars (names/hashes), target Package LifecycleEvidence,
manifest/lock bindings, the current standard Unity Editor.log only if the file
is bounded (<=64 MiB) and its own startup project identity can be checked.
Read only needed startup/domain/checkpoint lines; keep unrelated log content
out of summaries and do not persist a full log copy. The header project binding
must identify the intended CodedbTest_2 project before absence is attributable.
Use file times as supporting bounds only, not proof of per-line times or events.

Baseline at 2026-10-26T01:51:38.555Z had zero transition sidecars. User later
confirmed no compilation errors/Manager Ready; target-client reported one
successful status/query. These are separately attributed evidence, not proof
that new Editor code was loaded or diagnostics environment was unset.

Output under `.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/`
`f01-live-check-1105696/` only; this task directory's F01-LIVE-CHECK-RESULT.md.
No source/config/Unity state changes, global environment changes, process scan,
MCP, callbacks/reloads, new logs/observers, tests, lifecycle actions, cleanup,
commit/push or release. If attribution/log baseline is insufficient, record a
limited observation, not a test failure and not a reason to start an experiment.

Completion: separately classify observed sidecar delta, attributable document
log output, source default-off gate and remaining proof limits; then stop.

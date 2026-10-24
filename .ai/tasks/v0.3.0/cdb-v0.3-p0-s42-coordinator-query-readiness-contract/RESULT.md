# S42 result: coordinator query-readiness contract

Date: 2026-10-22. Outcome: SOURCE_CONTRACT_PASS / NOT_DELIVERED.

## Change and finding

The accepted Supervisor source could launch a Provider-only coordinator using
the ordinary config, then attach/publish Ready from Provider readiness alone.
The existing full watch route and immutable instance worker require watch config
and an enabled adapter worker. This establishes a source contract mismatch and
matches the later disk snapshot's service shape. It does not reconstruct the
S41 failure instant: that snapshot's coordinator started after the failed query.

Implementation is isolated at
`<repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract`,
branch `codex/coordinator-query-readiness`, based on accepted
`186aacf0371ba64e47114306170b449dbca261c9`. No commit was created.
Primary dirty source was not synchronized or imported.

Changed source paths (relative to isolated checkout):

- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`: derive watch config,
  builder, worker, manifest, legacy aliases and debounce from selected instance/
  generation. Keep ordinary providerConfig CLI assertions unchanged. Launch with
  complete adapter arguments; missing watch config refuses before child admission,
  with no fallback or new config writer. Compare authenticated existing service
  context before attaching. Incompatible config/adapter/generation/exclusive owner
  reports an explicit configuration mismatch using existing failure/reason enums;
  no stop or replacement owner is introduced. Operational Ready additionally
  requires complete component, lifecycle and process-presence facts compatible
  with the existing worker. Compatible pending/building is reusable. Thread
  context through observation production, retaining maintenance, revision and
  owner/activation binding.
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`: add separately
  selectable S42 scenario, adapt coupled S32 extraction and synthetic full-service
  defaults. Existing broad process-based harness was not run.

No changes to immutable poc.44, generation/package manifests, C# consumers,
registration, heartbeat timers, child admission or consumer runtime.

## Evidence

All commands ran from the isolated checkout. Node v24.14.1. No real child,
Supervisor, coordinator, Provider, Unity, MCP, PowerShell script or RPC started.
VM seams controlled admitted manifests, IPC/process observations and child launch.

| Check | Result |
| --- | --- |
| Node syntax, both changed files; scoped git diff --check | PASS |
| Required Package boundary `-PathProvenanceOnly`, added during delivery alignment | PASS; helper projections and direct admission/decoder bindings PASS |
| `node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs --query-readiness-contract-fixture .artifacts/tests/s42-readiness/final-01` | PASS, 7 scenario groups, CONTRACT_ISOLATED |
| `node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs --s32-disposition-fixture .artifacts/tests/s32-install/s42-final-01` | PASS, original producer/persisted attribution, HARNESS |

S42 executes actual buildContext, startup, compatibility and readiness functions;
the worker side executes original immutable getReadyWatchCoordinatorState with
controlled process probes. Scenarios cover complete derived launch arguments and
capture callback, missing watch-config refusal, watching/pending/building reuse,
incompatible config/adapter/schema/generation/path/exclusive-owner refusal without
second admission, lifecycle/missing-process Ready rejection, observation identity/
revision/maintenance, and timeout/launch/evidence/nonzero categories.
S32 preserves NO_CHILD attach, sticky pre-spawn admission, capture failure,
legacy unknown and refusal to admit again while prior identity is live/unknown.
The process probes are evidence seams, not proof of actual process ownership.

Two initial S42 harness loads failed before intended contract assertions because
the extracted context builder lacked isDirectory and filename constants. These
were the two mechanical fixture corrections; attempt-01/02 directories remain.
Attempt-03 passed. Final source review identified disabled adapter/worker states
as incompatible rather than normal startup; that same-cause correction was tested
in final-01, with S32 rerun because its imported producer changed. No live retry.

Canonical raw fixture evidence is in the isolated checkout:
`.artifacts/tests/s42-readiness/final-01/result.json` and
`.artifacts/tests/s32-install/s42-final-01/`. These are retained task evidence,
not cleanup candidates. No duplicate Package export or full diff was produced.
The required path-provenance check was omitted from the initial result and
completed during subsequent delivery alignment. Its command/output receipt is
`.artifacts/tests/s42-readiness/delivery-preparation-01/path-provenance.log`.
No product/test source changed after the final focused PASS. The earlier result
should not be read as having included this check before it was actually run.

SHA-256:

| Object | SHA-256 |
| --- | --- |
| Supervisor | `ac341b039f0840735801dc991e42a9ba7e313df0c82cca895d00dfc08a104fba` |
| Supervisor test harness | `7bf20ca426419905b34bb3297af2f164be2946d50a3e95a9850de09fb77f468e` |
| S42 final result.json | `9d720f760dca959f62ea8a034f4306b05b3d164e446fa1ccfd4e9a95a0d1d18d` |
| Unmodified poc.44 worker used by fixture | `5578c9baec9968402296351c86dbecd14691871488aa73539a99e98735a94ea1` |

## Delivery and safe recovery boundary

No Package delivery or consumer recovery was performed. CodedbTest_2 may still
have the old running Supervisor/coordinator. Changing source alone does not
change those processes. Do not infer recovery from this result or retry S41.

Existing bounded recovery mechanism: authenticated Supervisor `watcher:Stop`
can forward a reviewed `expected_lifecycle_id` to the immutable watch manager;
the coordinator authenticates the stop and refuses lifecycle mismatch. A later
authorized recovery must first establish the selected instance and attributable
live coordinator lifecycle, then perform one such expected-lifecycle stop and
the normal Supervisor retirement/Package activation boundary. With an active
Editor lease, the existing Start/Ensure route can establish the full watch lane.
That is a proposed sequence, not an executed or live-verified recovery receipt.

Do not use generic Manager Restart as an equivalent expected-lifecycle operation:
its current watch-script restart path issues stop without that explicit argument.
The existing materializer state admission also expects the watch config, so do
not assume reinstall can safely reconcile the incompatible old shape. If owner/
lifecycle attribution or normal operation admission fails, stop the recovery and
return that concrete decision; do not delete state, bypass admission or kill PIDs.
The protocol supports a bounded recovery request, but an operational entry and
real ownership precondition still need to be established before execution; this
source result alone does not prove a ready-to-run recovery procedure. See
DELIVERY-RECOVERY-PLAN.md for the staged decision and exact stop boundaries.

## Limits and follow-ups

Isolated source/contract evidence passes. Unity compile, complete broad harness,
real Provider/MCP, delivery, real query convergence, freshness A-to-B and release
acceptance are NOT_RUN. No performance/SLA conclusion. No independent review was
dispatched. Existing functional S40 acceptance remains unchanged.

Unconfirmed, Needs attention, compile/update heartbeat continuity and short-lived
child identity admission remain separately attributed open leads. This repair
does not prove those observations share this cause or resolve them all. S41 A
sample remains retained; a future bounded attempt must account for its presence.

Current task: S42 coordinator-query-readiness-contract.
Current status: SOURCE_CONTRACT_PASS / NOT_DELIVERED.
Next notification: user.
Next action: align exact Package delivery and one owned recovery/real-client gate.
Human authorization required: exact commit/export/reference switch and live
recovery/Unity/MCP acceptance; no implementation work remains in this envelope.

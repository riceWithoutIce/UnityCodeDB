# Event-triggered transition observer result 01

Date: 2026-10-22. Status: MAINTENANCE_OVERLAY_CAPTURED /
NO_BACKEND_DEGRADATION_OBSERVED.

Receipt:

`<repository-root>/.artifacts/tests/identity-handoff-heartbeat/transition-observation-2026-10-22T14-28-39-959Z-9a8eb3/result.json`

Receipt SHA-256:

`c723e2633759cacacfdd6f323893a5ed03dfa07cbc6b4e569ad504d00d2e53b4`

## Direct observation

- Observer exit code: `0`.
- Observer status: `TRANSITION_CAPTURED`.
- Window: `2026-10-22T14:28:39.959Z` to `2026-10-22T14:29:02.630Z`.
- First triggering event: `supervisor:rename`.
- Supervisor durable state changed from `core_ready` / `COORDINATOR_OPERATIONAL`
  to `maintenance` / `SUPERVISOR_MAINTENANCE`.
- The Supervisor `operational_readiness` remained `core_ready` /
  `COORDINATOR_OPERATIONAL`; its observation revision advanced from 5809 to
  5835 and received a fresh observation timestamp.
- Coordinator remained `core_ready`: Provider `ready`, adapter `watching`,
  adapter worker `ready`, desired state `enabled`, editor demand `online`,
  editor session count `1`.
- The operation changed from completed `materialize:Probe` with
  `CHILD_ADMITTED` to a newly running `materialize:Probe` with
  `execution_disposition=NO_CHILD`, phase `admitted`.
- Pointer identity stayed stable. The selected Editor lease remained the same;
  its heartbeat advanced from approximately 4.5 seconds old to approximately
  1.8 seconds old. Process liveness was intentionally not probed.

## Interpretation

This is evidence of a maintenance/action overlay while the underlying query
service remained operational. It does not demonstrate Provider loss,
Coordinator loss, heartbeat expiry, identity handoff or query unavailability.
The `materialize:Probe` operation and `SUPERVISOR_MAINTENANCE` state are a
strong lead for explaining a transient Manager presentation, but the Manager
UI was not read, so this cannot be labelled as a confirmed `Needs attention` or
`Unconfirmed` UI transition.

The reviewed Supervisor source has the same explicit split: `updateReadiness`
first publishes the operational observation, then sets the public
`readiness_state` to `maintenance` with `SUPERVISOR_MAINTENANCE` while a
Supervisor operation is running. This matches the captured tuple and explains
why public readiness can change while the authenticated operational observation
and Coordinator remain ready. It is a state-projection lead, not yet a UI
causal proof.

## Observer limitation

The event observer performed 1094 sanitized file reads across 182 event-driven
snapshots before the first captured change. No product state was mutated and no
MCP/process/log operation occurred, but this exceeds the intended one-read
per-source envelope and inflated the receipt to about 312 KB. The receipt is
retained as first evidence; it is not a basis for a performance claim.

Before any future observation, the observer must be mechanically tightened to
coalesce events and cap reads while preserving the same no-polling, read-only
boundary. The task-owned observer was then tightened: event classification now
reads only the Supervisor/Coordinator pair, coalesces notifications and caps
classification reads at 24; the full sanitized tuple is read only on a captured
transition. The change passed `node --check`; no rerun is authorized by this
result.

## Remaining uncertainty

- Whether the `materialize:Probe` operation is the exact producer of the UI's
  `Unconfirmed`/`Needs attention` text;
- whether the UI transition is an action override, cached observation expiry or
  a backend state projection;
- whether any separate heartbeat/identity issue occurs outside this captured
  maintenance interval.

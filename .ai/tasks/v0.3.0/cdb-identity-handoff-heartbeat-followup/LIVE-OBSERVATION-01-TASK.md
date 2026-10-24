# Live observation 01: Ready and readiness-transition window

Date: 2026-10-22. Status: AUTHORIZED_FOR_HUMAN_OBSERVATION /
SNAPSHOT_PENDING.

This is a bounded observation after the successful 61dcd26 real-client
status/query gate. It is intended to separate Manager display transitions from
backend readiness, heartbeat freshness and identity handoff. It does not grant
source edits, MCP calls, reconnects, refreshes or recovery actions.

## Human-owned observation

Use the existing external `CodedbTest_2` Unity project and its normal user
session. Do not create a new project. Do not close/reopen Unity to manufacture a
transition. Observe the naturally occurring window after the project is in
`Ready`.

Record, in local notes or a screenshot if already available:

1. UTC or local timestamp when Manager first displays `Ready`;
2. timestamp and exact text when it changes to `Needs attention`, `Unconfirmed`,
   `Starting`, or another state;
3. visible detail text, especially `checking status`, `MCP Pending`,
   `Supervisor operational observation`, `STARTING`, timeout stage or received
   byte count;
4. timestamp and exact text when it returns to `Ready`;
5. whether Unity reports a compile error and whether any user action occurred.

If no transition occurs during a normal short observation, report
`NO_WINDOW_OBSERVED` with the observation start/end times. Do not wait
indefinitely and do not force a transition.

## Development-session follow-up

After the human report, and only if the report identifies a usable state window,
the development session may perform one separately bounded, sanitized read-only
snapshot of selected pointer/instance, Coordinator state, Editor lease
heartbeat and existing Supervisor observation state. The snapshot must:

- read each permitted source once and record read timestamps;
- retain only safe positive fields, ages and state comparisons;
- exclude tokens, pipe names, command lines, raw errors and free-form output;
- finish with a pointer hash reread;
- use no RPC/MCP, process probe, log scan, polling, wait or recovery command.

If no usable transition is reported, stop with `NO_WINDOW_OBSERVED`; do not run a
snapshot merely because the project is Ready.

## Stop rules

Stop on any read or path mismatch, unexpected state mutation, user action that
changes the lifecycle, or evidence that the snapshot would require credentials,
raw process data or an additional source. Do not infer a shared root cause from
the UI label alone. This observation cannot establish an SLA, continuous
heartbeat health, formal MCP response identity or release readiness.

## Later gates

Any product edit, focused test change, Package export, consumer switch, Unity
reopen or real MCP query requires a separate authorization after the snapshot
result is reviewed.

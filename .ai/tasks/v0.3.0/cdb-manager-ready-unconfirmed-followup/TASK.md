# Manager Ready -> Unconfirmed -> Ready observation

Recorded: 2026-10-21 (Asia/Shanghai).
Status: DEFERRED / FOLLOW-UP / RECORD_ONLY.
2026-10-22 update: the user activated consolidated static diagnosis of the
collected UI/readiness/heartbeat feedback in the related task. See
[first static analysis](../cdb-identity-handoff-heartbeat-followup/ANALYSIS.md).
This historical observation remains unchanged; no reproduction or repair is
activated here and no shared cause has been established.
Scheduling: to be arranged separately by the user; no date or automation set.
Related later task: [identity handoff and heartbeat investigation](../cdb-identity-handoff-heartbeat-followup/TASK.md), recorded 2026-10-22 at the user's request. This observation keeps its independent cause/evidence classification; no shared cause or execution grant is inferred.
Origin: S39 CodedbTest_1 first Install, source delivery 237c72d.

## User observation and existing evidence

The user reports that shortly after Ready, Manager enters an Unconfirmed
checking state once, then returns to Ready. Exact delay, duration, frequency
and trigger have not been measured. The previous screenshot shows Ready; the
new screenshot captures the intermediate Unconfirmed state. Return to Ready
is a human report, not a timestamped transition trace.

Intermediate screenshot:
`.artifacts/tests/s39-unconfirmed-followup/20261021/unconfirmed.png`.

- Header: `CodeDB status unconfirmed`.
- Description: `The command completed. CodeDB status is still being checked.`
- Last activity: Install CodeDB / `Completed - checking status`, 17.41 s.
  This displayed operation duration is not the measured Unconfirmed duration.
- Host payload: Needs Setup / STARTING; detail says authenticated Supervisor
  operational observation is not available yet (visible text is truncated).
- Current instance: OK / poc.43, instance d442deda8b914a7bad6af7dd79e2d50c.
- Coordinator startup: OK / NONE, no cached startup failure.
- Host generation, Provider executable and project MCP config: OK.
- MCP availability: Needs Setup / Pending.
- Background cleanup: Inactive / In progress.
- Package: 0.3.0-preview.5.

## Future investigation boundary

When separately scheduled, align a bounded observation plan before execution.
Determine which refresh/lifecycle event changes the displayed state after Ready,
and correlate Manager observation freshness, authenticated Supervisor state and
MCP availability. Distinguish actual temporary unavailability from a UI
observation transition; no root cause is established by the screenshot.

Potential relation to previous periodic Checking observations is unverified.
Do not assume they share a cause or reopen an earlier accepted scope implicitly.
Decide expected user-visible behavior and focused regression criteria after
cause analysis; no implementation or acceptance criterion is frozen here.

## Current authorization and disposition

The user explicitly requested recording only, with resolution arranged later.
No source/config/runtime edits, reproduction, polling, additional Install,
MCP calls, Unity/process control, tracing, commit or delivery are authorized
by this card. No agent dispatch, reminder or scheduled run is created.

This observation is retained as FOLLOW-UP, not a new blocker for S39's pending
actual-client gate. There is currently no evidence here of a failed query or
configuration/data corruption. S39 Attempt 03 remains prepared/not dispatched;
recording this item neither executes nor grants a retry of that attempt.

# Task: cdb-identity-handoff-heartbeat-followup

## Metadata

- Product/version: UnityCodeDB v0.3 preview.
- Workflow: codedb-workflow-v2, revision 2.7.
- Status: PARTIAL / REPAIR_PLAN_ALIGNED; product implementation NOT_STARTED; snapshot grant consumed.
- Recorded: 2026-10-22 (user local date).
- Planner / static analyst: current development chat.
- Coder/Verifier: not assigned; no delegation authorized.
- Execution mode: DURABLE_SESSION; retain current model/reasoning; active budget 30 minutes.
- Requirement source: user explicitly requested recording identity-handoff and
  heartbeat concerns as a separate later task, with analysis deferred.
- Schedule: current bounded static pass activated by the user; no reminder or automation.

## Current activation — 2026-10-22

### Single snapshot authorization after static mapping

The user approved the proposed bounded read-only collection. This authorizes
one current disk snapshot in CodedbTest_2, clearly labelled CURRENT_SNAPSHOT:
there is no new contemporaneous human anomaly/UI confirmation. It does not
reconstruct the S41 failure. Read selected pointer/instance, selected-instance
lifecycle policy/manual marker and at most eight Editor leases, coordinator
state, and the existing v0.3-control/v2 Supervisor state/current operation.
Read each once, with a final pointer hash check; record read timestamps.
Do not use RPC/MCP, process probes, log/history searches, waits or polling.

Additional change allowlist: collect-state-once.mjs and SNAPSHOT-01-RESULT.md;
sanitized generated output goes to a new task-owned directory beneath
`<repository-root>/.artifacts/tests/identity-handoff-heartbeat/`.
Only positive safe-field projections are retained; connection tokens, raw
state, pipe names, command lines and free-form output/errors are excluded.
No configuration/runtime/project file writes. One collected snapshot consumes
this grant; another anomaly capture/time series requires a new bounded grant.

This section supersedes the historical record-only authorization below for
this bounded analysis stage only. The user explicitly selected eliminating
causes without refactoring and included all collected Ready/STARTING,
Unconfirmed, Needs attention and heartbeat/identity-transition feedback.
Do not assume these labels share a cause or that heartbeat is already faulty.

- Single outcome: map each observed symptom to its producer/consumer and
  decision conditions; separate established source behavior, incident causes
  and evidence gaps; propose the minimum next observation/repair envelope.
- Review mode: NORMAL; no independent review or subagent dispatch.
- Change allowlist: this TASK and a consolidated ANALYSIS.md only. Historical
  observation records stay intact. No product source/test changes.
- Read closure: this task's linked S39/S40 records, S41 TASK/RESULT; S36/S37
  directly relevant RESULT sections; accepted-candidate Editor lifecycle,
  Manager, StatusSnapshot, SupervisorBridge and direct status-builder/settings
  references; Supervisor child-admission/readiness code; poc.44 instance worker
  and coordinator heartbeat/query readiness; directly coupled existing tests.
  Existing sanitized retained incident snapshots may be read; no new live
  runtime/process/lease/log scan is authorized by this stage.
- Bind inspected source to delivery 186aacf where relevant. Use accepted bytes
  for any dirty dependency; do not activate unaccepted writer-lifetime WIP.
- Evidence scenarios: bounded static traces and existing-record correlation.
  L0/L1/EditMode/runtime/MCP/reproduction: NOT_RUN. No diagnostic log addition,
  heartbeat threshold change, validation weakening, reconnect, Unity/process
  operation, Install/Uninstall, refresh/rebuild, commit/export or cleanup.
- Structural/semantic repair budget: zero. Commands that fail before reading
  intended source may be corrected mechanically, at most twice per scenario.
- Stop when the symptom map and minimum missing evidence are clear; return
  remaining uncertainty instead of expanding into an exhaustive audit.
- Protect immutable generations, exact Package/consumer state, S41 A sample,
  original failure evidence and unrelated dirty changes. Do not dump raw state
  containing credentials/tokens. No scheduling or automatic task dispatch.

Current incident addition: S41 baseline text_search returned STARTING with
provider_attempts=0 / provider_route=none after the human's Ready starting
confirmation. See [S41 result](../cdb-v0.3-p0-s41-code-change-query-freshness/RESULT.md).
This query-unavailability observation increases investigation priority; it
does not prove a shared cause with the earlier Unconfirmed/reopen incidents.

## Objective

At a separately selected time, establish whether identity handoff, child
admission, heartbeat/liveness checks and observation freshness agree under
normal startup/reopen and ownership transitions. Identify evidenced causes and
minimal repairs before selecting any implementation. The concern that this
area contains multiple issues is the user's assessment, not an established
count of defects or proof of a common root cause.

## Known evidence and separate hypotheses

| Item | Established evidence | What is not established |
| --- | --- | --- |
| Reopen child admission | A real Probe failed with CHILD_ADMITTED, child=null and `Prior child admission has unresolved identity; another child is blocked.` Manager showed Needs attention, then returned Ready after about one minute with later successful Probe/readiness evidence. | Complete causal sequence, whether a child was live at the refusal, frequency and minimal repair. |
| Ready -> Unconfirmed -> Ready | Earlier separate human observation and screenshot are recorded. | Same cause as the reopen failure, actual query unavailability, timing or frequency. |
| Retained old MCP records | Old lease files persisted after uninstall/reinstall; post-action PIDs were absent or had a different start identity. | Faulty heartbeat production/consumption, unsafe ownership handling or a live matching old reader during the successful reinstall. Stale retained records alone do not prove a defect. |
| Response identity observability | Real status/query succeeded but omitted formal project_identity, instance_id and activation_epoch; disk and path correlations were recorded separately. | A heartbeat bug, identity corruption, or a requirement to redesign tool responses as part of this task. |

Keep these observations distinct until evidence connects them. Do not reopen
previously passed functional gates or infer root causes from similar UI labels.

## Evidence entry points (existing records only)

- [Reopen result](../cdb-v0.3-p0-s40-retained-mcp-install-admission/POST-REINSTALL-REOPEN-RESULT.md).
- [Child-admission static lead](../cdb-v0.3-p0-s40-retained-mcp-install-admission/REOPEN-CHILD-ADMISSION-FOLLOWUP.md).
- [Human Install and post-action holder limits](../cdb-v0.3-p0-s40-retained-mcp-install-admission/HUMAN-ACCEPTANCE.md).
- [Real target-client result and identity limits](../cdb-v0.3-p0-s40-retained-mcp-install-admission/CLIENT-POST-REINSTALL-RESULT.md).
- [Earlier Unconfirmed observation](../cdb-manager-ready-unconfirmed-followup/TASK.md).
- Preserved reopen evidence:
  `<repository-root>/.artifacts/tests/s40-retained-mcp-install/post-reinstall-reopen-diagnosis-a/`.

These are historical evidence with their declared provenance. Do not assume
their PID, epoch, heartbeat or Ready status is still current when work resumes.

## Future analysis outline, not an execution grant

1. Freeze the supported normal user scenarios and responsibility boundaries.
2. Trace identity/exit evidence production and consumption at child handoff;
   keep known exit, live execution and unknown execution distinct.
3. Trace heartbeat ownership, update/expiry rules and process-start identity
   checks. Compare heartbeat freshness with liveness evidence; neither is
   automatically equivalent to the other.
4. Trace the relationship between backend readiness, cache freshness and
   Manager states, distinguishing observation gaps from actual unavailability.
5. Return evidenced causes, independent issues, expected behavior and minimal
   repair/test proposals to the user before implementation or live observation.

The trace should initially use a bounded static dependency closure to be agreed
when activated. It is not authorization for a broad audit, protocol redesign,
exhaustive validation, new logging system or all historical recovery work.
Avoid adding validation that burdens the normal user flow without evidence.

## Authorization and protected state

Current approved stage: record this deferred task and cross-reference existing
evidence only. No further diagnosis, reproduction, tests, polling, tracing,
product/source/config/runtime changes, new logs, Install/Uninstall, MCP calls,
Unity/client/process operations, package delivery, commit, push or cleanup.
Do not create another Codex chat, dispatch an agent or schedule execution.

Preserve current Ready consumer state, immutable generations, candidate and
artifact identities, existing failed evidence and unrelated local changes.
Do not remove or weaken unknown/live-process admission guards, fabricate
leases, or activate earlier unaccepted writer-lifetime WIP through this record.

## Definition of done for this recording step

The concern has an independent deferred task, known facts are separated from
hypotheses, evidence links and future alignment boundaries are retained.
No defect fix or release/risk acceptance is claimed. The prior Install/query
PASS and qualified reopen convergence result retain their existing limits.

## Handoff

Current status: PARTIAL / REPAIR_PLAN_ALIGNED; product implementation NOT_STARTED.
Next action: review [REPAIR-PLAN.md](REPAIR-PLAN.md), then freeze the minimum
implementation envelope before product editing. No further live collection,
tests, product repair or restructuring is active; snapshot grant is consumed.

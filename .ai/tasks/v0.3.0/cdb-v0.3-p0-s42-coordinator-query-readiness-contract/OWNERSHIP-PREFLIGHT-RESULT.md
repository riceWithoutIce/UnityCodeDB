# S42 bounded ownership preflight result

Date: 2026-10-22. Status: COMPLETE_READ_ONLY / OWNERS_ESTABLISHED_AT_CAPTURE.
Retirement admission at capture: BLOCKED_ACTIVE_OPERATION. No stop dispatched.

## Evidence and scope

Human confirmed Unity open. Manager state was not supplied and was not inferred.
Single script execution, capture `2026-10-22T03:55:40.920Z` through
`03:55:42.238Z`. This is a new current observation, not an S41 failure-time replay.

Canonical safe report:
`<repository-root>/.artifacts/tests/s42-ownership/2026-10-22T03-55-40-920Z-88d5b5/report.json`.
SHA-256: `ed26067ea40400eafb9f20ee568d1af80377455fc09167ae343f8c622547d0f2`.
Task-owned script: `observe-ownership-once.mjs`; Node syntax check PASS.

The installed Supervisor source exactly matched accepted S40 Git blob
`186aacf0371ba64e47114306170b449dbca261c9`; SHA-256
`6a076ce6cfbf73c87f271ad42db85657d6793352f366b0adc2da63ad1ad122d8`.
Its original buildContext/owner validators, process-evidence and status functions
ran in a VM with filesystem writes denied, service spawning denied and IPC writes
restricted to status. Tokens/pipe/argv remained in memory. No production module
entry point was imported or started. No correction or second attempt was needed.

| Operation | Count |
| --- | --- |
| Authenticated Supervisor status through original owner inspection | 1 |
| Authenticated coordinator status | 1 |
| Read-only process identity probes (Supervisor and coordinator) | 2 |
| CodeDB status/query/other tools | 0 |
| Maintenance, start/stop/ensure/reconnect, commit/export/switch | 0 |

Status handlers may update existing observation records/counters. This is a
read-only request classification, not a claim that the server did no internal
bookkeeping or that runtime files remained globally byte-identical.

## Findings

1. **Current selected binding is unchanged.** Manifest/lock still reference
   `file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb`; Package is
   `0.3.0-preview.5`. Project identity, selected instance
   `a492a5e936c14e4da3ed7e4cc7c8c16c`, activation
   `063aa347f49a4b9f955a5447f293a0ac`, generation `poc.44`, instance manifest hash
   and existing Package validators passed. Pointer SHA-256 before/after remains
   `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.

2. **Supervisor owner is attributable now.** Original inspection returned
   LIVE_AUTHENTICATED after validating selected identity/state/lock, process start/
   executable/argv evidence and authenticated response ownership. PID 67220,
   owner epoch `7960ba8ac54541dcb54a1d767ae2fd16`, lifecycle `unity-bridge`.
   This is Supervisor owner evidence, not a formal target Codex-chat/MCP lease
   identity or ownership authorization that can be reused indefinitely.

3. **Coordinator is attributable now.** PID 45228, process start identity
   `639282355218671230`; actual executable and daemon argv matched the selected
   generation script, project/runtime, Provider/config, generation and lifecycle.
   Its authenticated status agreed on PID, lifecycle `unity-bridge`, generation,
   project/runtime and Provider/config. `exclusive_lifecycle=false`. This is
   stronger than the earlier disk-only snapshot; no Provider/worker PID process
   identity probe or real query was performed.

4. **Incompatible service shape is confirmed through current authenticated
   status.** Provider ready, adapter_enabled=false, adapter_state=disabled,
   worker_state=disabled and worker PID absent. Config is not the expected watch
   config; adapter manifest is not the expected manifest. Effective demand is
   enabled/online with one Editor session. Old Supervisor simultaneously reports
   operational core_ready/COORDINATOR_OPERATIONAL. This corroborates the concrete
   service-shape/Ready mismatch repaired in S42; it does not prove this coordinator
   was responsible for S41. Its recorded start remains later than that failure.

5. **No idle retirement window was established in this single capture.** Initial
   disk current-operation record showed a completed Probe (exit 0, with recorded
   child identity). The later authenticated Supervisor response reported a new
   running `materialize:Probe`, operation
   `07aa354f1b514f84831a0faba98ddb66`, started `03:55:41.127Z`. Top-level state was
   maintenance while operational observation was core_ready. These are different
   semantics and sample times, not contradictory proof of failed retirement.
   Public status omits child detail; its child=null does not establish an unknown
   child admission fault. No new child-handoff failure is asserted.

Manual-runtime file was absent; policy desired state enabled. This does not
freeze later lifecycle state or authorize stop. Operation completion/liveness
was not subsequently checked, and no stop was queued or polled.

## Decision and next stage

The one read-only grant is consumed. There is no need to repeat this observation
merely to reconfirm the known wrong service shape. Do not wait for a better sample,
force an idle state, stop a PID, or change runtime records under this grant.

S42 source remains uncommitted and undelivered. The next independent preparatory
stage can freeze the exact two-file commit/export grant and prepare a reviewed,
one-attempt authenticated retirement client. Such a client must use the existing
operation-admission/serialization boundary and an explicit coordinator lifecycle;
it must account for an active Probe rather than bypassing or misclassifying it.
If that protocol cannot safely admit the requested action, return the actual
rejection. Queueing/polling or sending that maintenance request requires its own
explicit operational envelope; none was exercised here.

Unity stays open, unchanged by this session. Closing/reopening Unity, Package
reference mutation and live restoration remain human-owned/separately authorized.
Source readiness PASS and current authenticated ownership do not imply recovery,
query/freshness PASS or resolution of all heartbeat/Unconfirmed feedback.

Current status: PREFLIGHT_COMPLETE / RETIREMENT_NOT_ATTEMPTED.
Next notification: user.
Next action: align exact commit/export and bounded authenticated retirement entry.
Human authorization required: commit/export, runtime retirement/restoration and
later closed-Unity consumer delivery/real-client acceptance.

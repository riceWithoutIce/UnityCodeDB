# S42 reopened consumer service shape result

Status: COMPLETE_READ_ONLY_QUERY_SHAPE_READY / OWNERS_ESTABLISHED_AT_CAPTURE.
One authorized invocation; no retry. Capture 2026-10-22T06:33:51.405Z through
06:33:53.622Z. Syntax check PASS; source matched frozen observer hash.

Safe report under <repository-root>:
.artifacts/tests/s42-reopen-service-shape/2026-10-22T06-33-51-405Z-1a8432/report.json.
SHA-256: 2a7009f448707ff71201433c95a9007648b0b5a1372f16bad73ac5d7994bfb92.

## Evidence

Installed manifest/lock reference matches 4589249-s42-codedbtest2. Supervisor
source matches commit 4589249564c7affb541634d61656c0cc895ca9d4, SHA-256
50260e1a355907a163e7841dc7a076e1917c0cec1e4b0d3f4f6f4a7186e59aca.
Selected instance a492a5e936c14e4da3ed7e4cc7c8c16c, activation
063aa347f49a4b9f955a5447f293a0ac and poc.44 match the existing baseline.
Pointer stable, SHA-256
1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a.

Supervisor PID 42020 is LIVE_AUTHENTICATED, owner epoch
aea7a12040af4dbba9289ccd2c42557f, lifecycle unity-bridge. Coordinator PID 59360
has matching current executable/daemon invocation and authenticated response;
process start identity 639282473099256030. These are service owner observations,
not target Codex-chat connection attribution.

Authenticated Coordinator reports Provider ready (PID 56624), adapter enabled /
watching, worker ready (PID 43836), enabled policy, online Editor demand and one
Editor session. All exact installed coordinatorServiceMismatch comparisons pass,
including watch config, adapter manifest, legacy/generation builder and worker
paths, debounce and lifecycle. Provider/worker PIDs were reported by Coordinator;
their process identities were not separately probed. No query was performed.

Supervisor operational_readiness reports core_ready / COORDINATOR_OPERATIONAL,
revision 472. Its top-level state is maintenance while materialize:Probe operation
3b280dc4f6cc4a319faae6577ac433de is running. Disk current operation records child
PID 69208; public operation projection omits child detail. No unknown-child fault
is inferred from the omitted public field, and no operation-completion wait was
performed. Active maintenance and operational readiness are distinct semantics.

Policy enabled; manual-runtime absent. Counts: Supervisor status 1, Coordinator
status 1, process identity probes 2; maintenance requests 0, CodeDB calls 0,
service control 0. Existing status bookkeeping may write server observations;
the diagnostic performed no explicit consumer mutation.

## Conclusion and limits

Current authenticated complete query service shape is established at capture.
The earlier Provider-only / adapter-disabled shape is absent in this sample.
This supports live deployment of the S42 shape fix, but does not prove the manual
watch-manager child-context repair was exercised: its failed Stop was not replayed.
Real target-client query availability and S41 freshness remain unverified.
Initial SUPERVISOR_IPC_TIMEOUT cause, heartbeat/Unconfirmed and formal response
identity remain open. Do not treat this later successful sample as a diagnosis
of the earlier timeout or a guarantee of future availability.

Next: one status and conditionally one fixed original marker query in the target
CodedbTest_2 chat, using TARGET-CLIENT-REVALIDATION-TASK.md. No live observation
grant remains active after this capture; no automatic recovery or polling.

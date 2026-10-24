# Frozen removal namespace contract

Date: 2026-10-14. Base: d88a101f15d21f916cbee9578ab887aa1ea862cd.

The selected immutable instance, Package-declared runtime transition and paired
COMMITTED activation establish v2 installation identity. Supervisor readiness is
not installation identity. Only VERSIONED_V2 receives the new namespace contract;
legacy/v1 admission stays unchanged. A single current state/lock is always blocked.

Producer mapping: persistOperation writes canonical operation.json and
operation-history/<operation_id>.json. Stale takeover emits paired
supervisor-state.json.stale.<milliseconds>.<32hex> and supervisor.lock with the
identical suffix. Normal retirement removes current state/lock only. These are
proof records, not logical-removal Delete targets. Existing events/error and any
current pair remain the original Delete inventory.

Bounds: 4096 history records, 32 stale pairs, 256 KiB per JSON, 32 MiB aggregate
history/quarantine proof; one history directory level; no unknown entries,
redirects, partial stale pairs or unbound records. Exact terminal canonical bytes
must equal their archived counterpart. Every operation is project/runtime/selected
instance/generation/runtime-contract bound; strict fields, terminal timestamps,
result and child shape are checked. queued/running and malformed records block.
Child=null blocks: producer finishOperation overwrites phase, and recovery can
publish failed after missing child identity. Therefore neither terminal phase nor
result proves an unrecorded admitted child's exit. Every recorded child and stale
owner PID must be provably absent; live, reused or unavailable PID blocks. No
native child or process inspector is executed by isolated tests.

Missing both current owner files is admitted only for exact selected v2 committed
authority. Stale owner records use the existing strict owner decoder. History
does not grant Ready, Install or mutation permission. Preserved evidence receives
a deterministic inventory fingerprint bound to immutable instance/generation and
the namespace. That fingerprint is the existing removal intent's authority field;
no schema change. Terminal validation recomputes preserved bytes from the retained
instance identified by the intent, so restart/recovery retains the same invariant.
Current owner files are never permitted in the terminal namespace. Read-only
handoff, entry/lock/before-mutation identity/config checks and transaction rollback
remain mandatory. Preserved records are checked again before commit and after it.

Lifecycle keeps a bounded redacted backend refusal beside the command summary in
its existing cache. No handoff line or auth-token value is displayed. Incomplete,
failed, timeout, cancelled or malformed handoff output never sets its Available
flag. Existing action backend remains the final handoff identity authority.

Only the approved six source/test files and task-local evidence may be edited.
Real Unity/runtime/config/history, dirty Payload and exact delivered Packages are
protected. No real preflight/Install/Remove/Upgrade/process/IPC or delivery action.
Tests use an exclusive ignored exact-Package overlay with synthetic prerequisites
and process observations, and retain every attempt. Source/isolated evidence is
distinct from human Unity and real removal acceptance.

# Client IPC failure diagnostics implementation slice

Status: EXACT_COMMIT_EXPORT_PASS / NOT_CONSUMER_DELIVERED.
Human agreed the client-only diagnostics scope and instructed continue after
progress alignment. NORMAL, no delegation. Source/offline evidence is in
IPC-FAILURE-DIAGNOSTICS-RESULT.md; exact handoff is in
IPC-FAILURE-DIAGNOSTICS-DELIVERY-RESULT.md.
Base/clean isolated HEAD: 4589249564c7affb541634d61656c0cc895ca9d4.
Checkout: <repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract.

Allowlist under com.rice.ai-codedb: Editor/AICodedbSupervisorBridge.cs and focused
Tests~/test-codedb-supervisor-ipc-diagnostics.ps1. Initial Bridge SHA-256:
c1b8d95b2867a773192f41b30ccbc0617a45b61c27af99ffecb9be0a0493782f.
Preserve primary dirty state/index, payload and all consumer files. No commit,
export, delivery, real service requests or reproduction in this grant.

Implementation: per-exchange local accumulator, connect/write/read/complete
stage, initial command vs operation poll, bounded safe command/action/IDs, UTC
start and monotonic elapsed, received bytes. Append one structured diagnostic
only to an existing timeout exception message, retaining original message as
prefix and original exception as inner. No new output file, polling, validation,
timeout changes, lifetime/ownership/readiness/UI change, service start or retry.

L0 tests: focused offline serializer checks for stage timing, command/poll context,
bounded fields, malformed sensitive input omission, unchanged message prefix and
TimeoutException category. Source checks bind initial command and operation-poll
call contexts to the actual paths. Diff/allowlist and whitespace checks.

Affected L1 tests: compile the exact transport methods and accumulator extracted
from the changed production file in the existing PowerShell Add-Type runtime,
with only protocol constants/exception dependency declarations. Exercise local
named-pipe successful exchange, partial-read timeout, connect timeout and
cancellation; deterministically exercise the actual pending-write wait method
with an expired deadline and verify pipe disposal / timeout classification.
No production script entrypoint or substitute service. This proves the isolated
transport boundary, not complete Unity compilation or scheduling behavior.

Harness closure: fresh task-owned fixture/temp root under repository .artifacts/
tests/s42-ipc-diagnostics, temporary environment redirected there, source/helper
hashes and runtime versions in receipt. Owned pipe names only; server tasks have
finite cancellation/joins. No network, downloads, global writes or product process.
One initial focused batch, at most two same-cause corrected attempts as workflow
permits; no unchanged rerun. Preparation syntax fixes before a batch are mechanical.

Explicitly not run: Unity EditMode, full suite, product runtime, real target MCP,
consumer compile or release checks. No independent agent requested. No live
consumer health claim. Exact commit/export and human reproduction are later gates.

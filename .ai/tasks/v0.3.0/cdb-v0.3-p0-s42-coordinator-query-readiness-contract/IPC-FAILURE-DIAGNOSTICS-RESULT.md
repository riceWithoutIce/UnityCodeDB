# Client IPC timeout diagnostics result

Date: 2026-10-22. Status: ISOLATED_SOURCE_AND_FOCUSED_OFFLINE_PASS / NOT_DELIVERED.
NORMAL, no delegation or independent Verifier. Implementation follows the
separately approved IPC-FAILURE-DIAGNOSTICS-TASK.md envelope.

## Snapshot and change

Base HEAD: 4589249564c7affb541634d61656c0cc895ca9d4.
Branch: codex/coordinator-query-readiness.
Checkout: <repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract.
HEAD is unchanged; the two allowlisted files are the entire isolated product diff:

| File under com.rice.ai-codedb | Final SHA-256 |
| --- | --- |
| Editor/AICodedbSupervisorBridge.cs | 8b021ead8de1716b6b9d36d631ca4c4a0aa3f543ff5dfc1d7be07d121e09e83e |
| Tests~/test-codedb-supervisor-ipc-diagnostics.ps1 | fe5c6c8a043ecade5bd38abbb841805a1ad85871f24fe5e9625333f014badc87 |

The Bridge keeps a local accumulator for each pipe exchange. Initial command
and accepted-operation polls supply their actual request IDs, original command/
action, and the known operation ID. Other existing callers retain their
three-argument source call shape and use an `other` diagnostic context.

On TimeoutException only, the original message remains the prefix, followed by
one same-line `[CODEDB_IPC_DIAGNOSTIC]` schema-1 JSON record; the original
exception is retained as inner. Keeping the suffix on the first line avoids
discarding it in existing first-line error summaries. The record carries
connect/write/read stage, UTC start, monotonic elapsed and stage durations,
received bytes and safe correlation fields. Successful calls emit no diagnostic.
Cancellation still exits through OperationCanceledException. IDs describe local
request context and do not prove server receipt or authority.

Command/action output is bounded to ASCII codes; IDs to lowercase hex32, with
missing/malformed fields replaced. No auth token, pipe address, project path,
raw body or source text is added. These checks restrict diagnostic output only;
they do not validate or reject a product request.

Connection and shared post-connect write/read budgets remain 1500 ms each.
The original wait, deadline, cancellation and disposal helper block is unchanged
from HEAD after line-ending normalization. No queue, ownership, lease, readiness,
UI reducer, automatic retry, service lifetime or payload changes were made.
Per-exchange allocation/timing and byte counting add diagnostic overhead; no
performance equivalence is asserted.

## Focused verification

One initial batch, zero failed batches or corrected reruns. Command from the
isolated root: `pwsh -NoProfile -File com.rice.ai-codedb/Tests~/test-codedb-supervisor-ipc-diagnostics.ps1`.
PowerShell 7.6.5 / .NET 10.0.11. Batch window UTC:
2026-10-22T08:07:56.5053000Z to 2026-10-22T08:08:02.6021629Z.

L0 and affected isolated L1 passed with 79 assertions across these boundaries:

| Boundary | Evidence |
| --- | --- |
| Safe serializer and caller wiring | Schema/UTC/timing, bounded and malformed fields, no injected private input, actual command/poll IDs wired, existing result codes retained |
| Successful local exchange | Original response preserved, complete stage, 12 received bytes including newline, client pipe closes |
| Partial response, initial command | Actual SendPipeRequest returns TimeoutException with original inner cause/prefix, read stage, 6 bytes; owned server observes client close |
| Partial response, operation poll context | Same transport timeout, distinct operation_poll kind and operation ID, read stage, 6 bytes |
| Absent owned-name pipe | Actual Connect timeout classified at connect, zero read/write time and received bytes |
| Cancellation while reading | OperationCanceledException retained, client pipe closes, no timeout suffix |
| Pending write waiter | Exact production waiter with an expired deadline disposes the owned pipe and retains original timeout; write-stage accumulator distinguished |
| Canceled pending write waiter | Cancellation takes precedence over expired deadline, owned pipe disposed |

The diagnostic class, transport methods, constants and message-limit exception
were extracted exactly from the production source and compiled with Add-Type.
Fixture dependency declarations and local test servers are not production
Supervisor substitutes. Only random task-owned local pipe names were used;
server tasks had finite cancellation, were joined and disposed. TEMP/TMP were
redirected to the unique retained test root and restored on exit.

The write fixture deterministically tests the actual wait helper plus stage
accumulator. It does not create OS buffer saturation or claim an end-to-end
write timeout was reproduced. Command/poll execution wiring is a source check;
the actual product operation queue was not started. No total-time SLA follows
from fixture timings. Whitespace, exact product allowlist and unchanged waiter
block comparisons also passed. Only the declared product files changed.

## Retained evidence

All paths below are relative to the isolated checkout:
`.artifacts/tests/s42-ipc-diagnostics/cf7f13f71215446c87f85bc7a6623b39/`.

| Artifact | SHA-256 |
| --- | --- |
| receipt.json | 4be9971fad15621b61ef0156d55017244e91dacf38a43444cd66d2c1037fc590 |
| extracted-transport.cs | 03182b40482452e15e1571c5e33c5cd89a590c05f5b371fe23419c0a7fa2a0aa |
| fixture.cs | 8bd1f94be7aa17ec7c39e45fcf663fdd4fb125060d55d3f05b55b24c982bbd9f |

Runtime executable SHA-256:
362a356ce7f0940ec74f73a8fc2c990a2cc24a38a11c90bbd8eca947110ad139.
Receipt records source/helper/runtime hashes and case observations; no retained
artifact was cleaned or replaced.

## Limits and next gate

Unity compilation, EditMode, full suite, live Supervisor/Coordinator, target MCP,
consumer operations, real reproduction, performance and release: NOT_RUN.
No commit, package export, consumer delivery, process scan, service start/stop,
reconnect, historical log rescan or live health check occurred. Primary dirty
source/index and consumer files were preserved. Existing S41 B remains the last
recorded retained state; it was not resampled here.

This closes the approved isolated implementation slice. It does not establish
the cause of the historical timeout or connect it to heartbeat, Unconfirmed or
identity handoff. A later exact source review/delivery gate and human Unity
compilation precede any separately bounded real observation. No new live run is
authorized by this result.

Subsequent NORMAL bounded self-review completed with no blocking findings and
no test rerun or source edit. See IPC-FAILURE-DIAGNOSTICS-REVIEW.md. A concrete
repository-only commit/export proposal is prepared in
IPC-FAILURE-DIAGNOSTICS-DELIVERY-PROPOSAL.md; not authorized or executed yet.

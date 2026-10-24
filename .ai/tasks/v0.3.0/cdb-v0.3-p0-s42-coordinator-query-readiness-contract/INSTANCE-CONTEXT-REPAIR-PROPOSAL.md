# Proposed minimal watch-manager instance-context repair

Status: APPROVED_AND_IMPLEMENTED_SOURCE_ONLY; see INSTANCE-CONTEXT-REPAIR-RESULT.md.
This proposal follows the completed offline
reproduction. It does not expand into heartbeat, ownership or Supervisor refactor.

## Concrete source change

Base: exact exported S42 commit 267b921dee0385962885e8e3142b4e4903ab711b.
Reuse its clean repository-local isolated checkout and existing branch; leave
the dirty primary checkout and all consumer projects unchanged.

Change exactly these product paths:

- com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
- com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs

At runWatchManager's existing runChild call, pass an explicit child-environment
object containing RICE_CODEDB_UNITY_ROOT from context.root and
RICE_CODEDB_INSTANCE_ROOT from context.selectedInstance.instanceRoot. Both come
from the existing validated context. Use the existing runChild environment merge
so these two selected values override inherited values while unrelated variables
remain available. Do not mutate process.env or change the generic runChild default.
No absolute machine paths, new protocol fields, extra global configuration or
additional runtime state validation are needed for this boundary.

Preserve existing child admission/capture, expected lifecycle forwarding, Stop's
Editor-session prerequisite, queue/serialization, timeout/output handling and
unknown/live ownership refusal. Do not edit immutable poc.44 scripts/manifests,
lease files, heartbeat intervals/TTL, Editor UI or the completed S42 ZIP.

## Focused verification proposed before editing

L0: syntax checks for the two changed JS files; scoped diff/allowlist check.

Affected L1: promote the diagnostic JS-launch-to-PowerShell-reader fixture into
the existing narrow Supervisor harness behind its own explicit fixture option.
For absent, matching and foreign inherited instance environments, all three
must select the validated instance and see its synthetic lease. Add the adjacent
case of an incorrect inherited Unity root. Assert unrelated environment and
parent environment are preserved, admission/capture still occur, expected
lifecycle is forwarded, and no real product child starts. Exercise the actual
consumer with no matching synthetic lease as a negative control; it must remain
empty rather than manufacture online Editor demand.

The fixture uses original source functions, synthetic paths/leases and controlled
process-start facts. It starts only its owned PowerShell probe, not the watch
manager entry point or any real service. One initial focused batch with at most
two same-cause mechanical corrections. No broad regression, Unity, MCP, live
Stop or performance evidence. Broaden only on a concrete adjacent regression.

## Completion and later boundaries

Record exact source/test hashes, focused result and limitations. Do not commit,
export, switch the consumer reference, replay Stop, or start/stop any live service
as part of this source repair. The historical Stop receipt and exported S42
Package remain retained evidence. Live recovery must be realigned separately:
the already running old Supervisor does not adopt an isolated source edit.

No need to keep sampling the consumer to reconfirm this deterministic defect.

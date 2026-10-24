# S39: human open result and migration blocker

Date: 2026-10-21. Status: HUMAN_REPORT_NO_COMPILE_ERROR /
INSTALLED_STATE_MIGRATION_BLOCKED / REAL_CLIENT_ACCEPTANCE_ON_HOLD.

The human opened CodedbTest_1 after delivery and reported no compilation error.
Two supplied Manager screenshots show Needs attention. The first shows previous
poc.43 and unavailable automatic handoff; the second shows previous-v2 identity,
removal required and a removal-preflight block for live or ambiguous ownership.
This is human compile/UI evidence, not an independently executed Unity test or
successful setup/query acceptance. Screenshot ordering/timing is not established
as a measured transition trace.

Read-only checks confirm the delivered Package host-current selects poc.44,
while the project's selected pointer and instance remain poc.43. Config and
pointer retain their delivery baseline hashes; config cwd remains `.`.
The old activation remains COMMITTED with runtime contract
`750f54d6bd187b51a436e28002ea2099b9ce0a21b9f9fe6543ecc4197269b84a`;
the delivered Package contract is
`ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5`.
No new activation or config repair is claimed.

Existing C# selection/lifecycle code classifies an exact Package-preserved
previous generation as TrustedPrevious and routes it to diagnostic-only
historical removal. The current backend explicitly requires controlled removal
and reinstall; automatic handoff is unavailable. The screenshot's previous-v2
wording refers to previous-generation Owner Identity v2, not CodeDB v0.2.

The selected instance has two MCP leases. At the bounded read, PID 43448 was
not returned by the PID-specific process query. PID 69152 was present as Node
running the project-wrapper relative argv; its matching project/instance lease
had heartbeat 2026-10-21T07:33:06.729Z. This is process/lease correlation, not a
fully authenticated process-start identity comparison or target-chat attribution.
It supports continued live-or-ambiguous ownership; it does not establish that
these are the only holders or substitute for the production removal preflight.

The removal predicate requires no invalid/live instance lease, editor lease or
coordinator evidence. Do not bypass it by deleting lease files or directly
changing selection/config/activation. Next, agree a normal client/holder release
sequence, then perform a separately bounded read-only removal-admission check.
Any actual uninstall/reinstall remains a distinct explicit action.

The legacy root `payload-materializer/mcp-availability.json` shown in one UI
detail was absent. The selected instance's own logs/mcp-availability.json exists
but is a historical AVAILABLE record from 01:47:49Z. It does not prove current
Package readiness or current client availability. No new availability probe ran.

All checks in this observation were reads. No file in the consumer project was
modified, no component started/retried/reconnected, no process stopped, and no
CodeDB/MCP tool called. Unconfirmed remains a separate deferred issue.

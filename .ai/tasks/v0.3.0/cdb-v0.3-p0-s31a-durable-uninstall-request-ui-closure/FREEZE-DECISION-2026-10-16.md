# S31-A freeze decision — 2026-10-16

## Decision

S31-A is frozen at `PARTIAL / NOT_ACCEPTED`.

The historical reconnect finding
`SupervisorBridge_MissingInstanceReturnsCachedDisconnectedStateWithoutWrites`
is deferred as a non-blocking FOLLOW-UP. It is outside the S31-A eight-file
allowlist and is not admitted as an S31-A source defect.

## Frozen boundary

- Keep the eight-file S31-A source/test allowlist unchanged.
- Do not modify `AICodedbSupervisorBridge` in S31-A.
- Do not retry the historical reconnect test in S31-A.
- Keep Install/Remove/Repair Editor regressions `UNRUN`.
- Do not infer full lifecycle acceptance from the focused PASS evidence.
- No commit, package export, package/reference switch, real
  Install/Uninstall, live process control, or Unity acceptance is implied.

## Future route

If reconnect remains a release requirement, open a separate narrow task that
owns the bridge dependency and synchronizes its fixture/test contract before
running new evidence. That future task is not created or authorized by this
decision.

## User alignment

The user explicitly confirmed freezing S31-A and deferring historical
reconnect; it is not a current blocker.

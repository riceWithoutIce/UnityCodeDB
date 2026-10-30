## Current route sync - 2026-10-30

This dated section supersedes older current-route statements while preserving
their historical evidence. The frontend/backend session redesign contracts are
frozen; Slice A has a reviewable implementation card and has NOT been authorized
or started. Design completion is not source, Unity, runtime, performance or release acceptance.

- V1 has one project Supervisor authority, Coordinator, Provider and watch/index.
  Concurrent client sessions share this project service rather than creating one backend each.
- An effective Unity Editor lease is required for online service. Without Unity,
  return EDITOR_OFFLINE; querying project code after Unity exits is deferred.
- Manager consumes published snapshots. Observation failures must not reset or stop
  a healthy backend. The new contract admits no legacy field/identity/authority fallback.
- The authority root is AIWork/.runtime/codedb/control/supervisor. Strict schemas,
  the single publication commit, migration journal/messages and Slice A boundaries
  are frozen. Real cross-process drain/archive effects remain later-slice gates.
- Test8 consumes the exact 3beb2c7 candidate. Human observations include Ready,
  Manager reopen and Play-to-Edit recovery, but long Unconfirmed/Starting delays
  and idle Ready-to-Unconfirmed changes remain unresolved UX evidence. These are
  observations of the old implementation, not acceptance of the redesign.
- Test2 retains four historically unresolved child-admission records. Test7 retains
  the migration/removal BLOCKED repro. Test8 observations close neither case.
- Environment preparation preserves all six checkouts' local changes and compact
  evidence snapshots for Test0-Test6 with their referenced Packages. Test7/Test8
  stay in place. The approved exact cleanup removed 165 generated-cache/stray-copy
  targets, 1,067,474,466 logical bytes; all nine project roots and protected
  configuration/diagnostics remain. Historical checkout retirement remains deferred.

Current local source HEAD: 3beb2c7ff35ce2159273a5f795b6f2e54ff427fb,
branch codex/install-quarantine-admission. Design documentation checkpoint:
52cf9bc8bfc82fb48f972abbf8987db110035171. Earlier primary-checkout evidence checkpoint:
d8f00c303daf57856b8824fdf4587ce37999be47. These commits are local and NOT pushed.
Housekeeping closeout is recorded separately in the primary checkout. Source paths within that
checkout: .ai/tasks/v0.3.0/cdb-v03-ready-observation-deadline/ and
.ai/tasks/shared/cdb-environment-preparation-20261030/ in the primary checkout.
No new implementation, Unity/MCP action, release or accepted performance follows from this sync.

# Reconnect follow-up route decision

## Decision

The `SupervisorBridge_MissingInstanceReturnsCachedDisconnectedStateWithoutWrites`
failure is accepted as a FOLLOW-UP finding caused by historical reconnect test
and control-contract dependency alignment. It is not admitted as an S31-A
source defect.

## S31-A boundary

- Keep the eight-file S31-A allowlist frozen.
- Do not modify `AICodedbSupervisorBridge` or widen the dependency closure.
- Do not retry the failed reconnect filter in this task.
- Keep the remaining Install/Remove/Repair filters `UNRUN` after the bounded
  first-failure stop.

## Future route

If reconnect behavior remains a release requirement, open a separate narrow
task that explicitly owns the bridge dependency and updates its fixture/test
contract before running new evidence. No such task or source authority is
created by this record.

## Gate status

S31-A remains `PARTIAL / NOT_ACCEPTED`. No commit, package export, reference
switch, real Install/Uninstall, or live process operation is authorized.

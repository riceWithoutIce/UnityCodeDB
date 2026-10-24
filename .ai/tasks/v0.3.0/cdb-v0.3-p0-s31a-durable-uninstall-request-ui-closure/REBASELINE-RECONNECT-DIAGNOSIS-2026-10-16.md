# S31-A reconnect failure diagnosis

## Observed behavior

The focused test
`SupervisorBridge_MissingInstanceReturnsCachedDisconnectedStateWithoutWrites`
expected `Disconnected/CURRENT_INSTANCE_UNAVAILABLE` but observed
`Degraded`.

## Read-only source alignment

- The failure is inside `AICodedbSupervisorBridge.ConnectWorker`, which is
  outside the frozen S31-A eight-file allowlist.
- Its source hash is identical between the active S31 checkout and the
  repo-local rebaseline snapshot.
- The same bridge file is unchanged in the rebaseline worktree; no S31-A
  source edit caused this result.
- The test itself is historical Supervisor-admission coverage. Its current
  assertion predates the later control-contract routing path that now reads
  the Package runtime contract before the synthetic project-root reconnect
  decision.

## Current interpretation

The `Degraded` result means the reconnect call did not complete the intended
missing-instance early-return path and instead entered the bridge's generic
startup/error classification. The available XML/log evidence does not identify
whether the synthetic fixture precondition was absent or the package/bridge
dependency rejected it before that branch. This is therefore a historical
fixture/dependency alignment finding, not yet a confirmed S31-A source defect.

## Boundary

No retry, source edit, dependency expansion, or broader test run is authorized
by this diagnosis. The remaining reconnect and Install/Remove/Repair filters
stay `UNRUN`; S31-A remains `PARTIAL / NOT_ACCEPTED` pending an explicit route
decision.

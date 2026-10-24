# S31-A rebaseline reconnect continuation failure

## Bounded attempt

The narrow startup/reconnect and Install/Remove/Repair regression set was
started against the accepted repo-local `s31a-rebaseline` snapshot. The first
test failed, so the bounded attempt stopped without retrying or running the
remaining filters.

## Failure

Filter:

`SupervisorBridge_MissingInstanceReturnsCachedDisconnectedStateWithoutWrites`

XML result:

`total=1, passed=0, failed=1, skipped=0`

Assertion:

`Expected: Disconnected; But was: Degraded`

The failure occurred inside the Editor test assertion after the project and
test assemblies loaded successfully. It is not a compiler or Unity launch
failure. The raw XML and log are retained at:

`.artifacts/tests/s31a-rebaseline/editor/rebaseline-supervisor-missing-instance.xml`

`.artifacts/tests/s31a-rebaseline/editor/rebaseline-supervisor-missing-instance.log`

## Stop boundary

The remaining reconnect, Install, Remove and Repair filters were not run. No
retry was attempted. No source, package, reference, or live project state was
modified. S31-A remains `PARTIAL / NOT_ACCEPTED`; this record does not
authorize a source fix.

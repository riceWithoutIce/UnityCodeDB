# S40 Coder result: retained MCP Install admission and cleanup accounting

Status: CODER_READY_FOR_REVIEW. Declared isolated evidence PASS; independent
GUARDED review, delivery and real lifecycle acceptance remain open.

## Stable source

- Base/HEAD: `c848049d90fbdf618905be25225580642d98d987`.
- Branch: `codex/retained-mcp-install-admission`.
- Checkout: `<repository-root>/.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission`.
- Uncommitted four-file source snapshot: SOURCE-SHA256.json, including new tests.
- Prior route result and hashes: RESULT-01-ROUTE-REASSESSMENT.md and
  SOURCE-SHA256-01.json. Earlier failed runs remain preserved.

## Resulting behavior

A separately confirmed same-Package Install can create a distinct instance while
positively identified MCP readers retain the normal-uninstalled READY instance.
The narrow admission classification requires authenticated removal evidence,
inactive registration, no current/LKG selection, matching process identity and
registered Node wrapper invocation, and no active Editor/coordinator writers.
Unknown identity, failed preparation and competing execution remain denied.

The approved amendment fixes final cleanup accounting. After versioned retirement
reports COMPLETE, Get-CombinedInstanceCleanupState now includes the existing
Get-InstanceCleanupState result as a read-only input. This additional call never
passes PerformCleanup. A normal-removal retained closure therefore keeps the
command and desired-state cleanup PENDING. No-retention activation still returns
COMPLETE. Existing versioned deletion order, holder-clear authorization, process
control, immutable worker and bootstrap protocol are unchanged.

## Focused evidence

Run paths are relative to
`<repository-root>/.artifacts/tests/s40-retained-mcp-install/`.

| Check | Outcome | Evidence |
| --- | --- | --- |
| Corrected full original-convergence harness, PowerShell 5.1 | PASS, 29 checks, exit 0 | `cleanup-accounting-ps51-a/result.json`, `run.log` |
| No-retention first activation | Command and desired cleanup COMPLETE | Same run |
| Retained MCP reinstall | Distinct instance/epoch; command and desired cleanup PENDING | Same run, `cleanup-observation.json` |
| Failure before candidate activation | UNINSTALLED preserved; no selection | Same run |
| Retained old instance | All old-instance file hashes and exact removal intent preserved; deletion holder-clear remains false | Same run |
| Existing admission negative controls | PASS, included in the 29 checks | Same run |
| PowerShell parse and diff whitespace | PASS for final amendment source | Focused source checks before execution |
| Prior S32 safety checks | PASS, 25; not rerun for accounting-only amendment | `s32-regression-a/run.log` |
| Prior original-worker request binding | PASS, 6; worker/test code unchanged by amendment | `l1-ps51-b/worker-result.json`, `worker-run-c.log` |

Final retained-state observation: versioned retirement COMPLETE, instance cleanup
PENDING, command cleanup PENDING, desired cleanup PENDING, old intent present,
old lease present. The aggregate now accounts for both retention mechanisms.

Evidence class: HARNESS / CONTRACT_ISOLATED. Original production functions and
serialized records were used with synthetic machine prerequisites, PID/start,
command inventory and PocFixture candidate verification. No real Provider,
external MCP client, Unity or IPC was executed. Prior worker evidence uses
original immutable worker functions in a VM. It does not establish real client
concurrency, query availability, or eventual physical cleanup after lease drain.
No unchanged worker/S32 scenario was rerun merely to refresh its PASS.

## Preserved failure evidence and limitations

The original full run `l1-ps51-b` failed because the command incorrectly returned
COMPLETE while normal-removal retention remained. The user approved the narrow
accounting amendment after that result; the original assertion was retained.
The first amendment run passed without a further correction or retry.

Prior mechanical fixture failures and corrections are recorded in
RESULT-01-ROUTE-REASSESSMENT.md and their unchanged logs. PowerShell 7.6.5 remains
NOT COMPLETED: an existing strict JSON return-type mismatch occurred before
admission assertions (`l0-ps7-a/run.log`). It was not repaired or rerun here.
This is a separate compatibility follow-up; no PS7 PASS is claimed.

The no-retention positive control uses original first-install convergence.
Cleanup after real holder release and repeated real-world lifecycle cycles were
not tested in this slice. No physical-cleanup-after-drain claim is made.

## Handoff

Coder changes and focused evidence are stable. Independent GUARDED review is
pending and no subagent was dispatched. A passing isolated Coder result does not
close S39 real lifecycle acceptance or authorize delivery.

Primary dirty state, other worktrees, immutable payloads and external
`CodedbTest_2` were preserved. No Unity launch, real Install/Uninstall, external
process stop, project configuration switch, cleanup operation, commit, export,
push or release occurred. Fixture mutations stayed in task-owned test outputs.
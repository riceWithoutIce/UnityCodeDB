# Verification: cdb-v0.3-p0-s15-query-first-lifecycle-maintenance-queue

## Verdict

`FAIL`

The frozen Supervisor queue implementation satisfies its narrow queue mechanics, but the S15 release contract is not closed. Two normal-path maintenance boundaries still bypass or fail to drive the sole queue/suspension authority.

## Admission And Frozen Identity

- Review mode: `RELEASE`, targeted read-only review.
- HEAD: `a60b92f36679834d1696e4133561bbbc770139be` - `PASS`.
- Ordered eleven-path binary diff identity: `e1c372816afb57450379fb0ec4fa5cf6dac38dcd` - `PASS`.
- The scoped name query returned the ten inherited/current modified paths represented by that identity; `AICodedbLifecycleEvidence.cs` is the eleventh fixed identity input and remains byte-identical to the S15 pre-edit value.
- All eleven observed SHA-256 values match the final table in `RESULT.md`.
- `RESULT.md`: non-empty, 18429 bytes, SHA-256 `897b9201b5bb0a5e4c12f5ab20219894249085a007c72e68e7e4f02db5cbbb21` at admission.
- Effective Coder result: `COMPLETE` after Evidence Checkpoint 01. The original static assertion failure remains preserved as historical harness evidence.

No identity drift was observed before review.

## Findings

### P1-01 - Manager maintenance still bypasses the sole Supervisor queue

The frozen contract requires one project-local Supervisor queue to own every heavyweight maintenance admission and result. The Manager still exposes normal user paths such as Refresh If Stale, Refresh Index, Build Shader Adapter, Clean Index, and Rebuild Index through `RunAction` (`AICodedbManagerWindow.cs:1457`, `1602-1606`, `2079`, `2093`). `RunAction` executes the supplied `AICodedbActions` delegate through an independent `Task.Run` lane (`AICodedbManagerWindow.cs:2239-2250`). The direct dependency then starts Package scripts with `AICodedbProcessRunner.RunPowerShellScript` (`AICodedbActions.cs:415-433`, `471-481`, `757-793`, `858-875`) rather than sending the work to Supervisor admission.

After those actions, Manager also invokes its own `AICodedbStatusSnapshot.RefreshAsync` (`AICodedbManagerWindow.cs:2327`), whose direct implementation performs a filesystem/hash/full-status pass (`AICodedbStatusSnapshot.cs:442-461`) instead of consuming one already classified lifecycle/Supervisor snapshot.

Impact: a Manager maintenance action can execute alongside a Supervisor-admitted lifecycle/materializer operation without the Supervisor queue's key coalescing, one-heavy-job limit, owner epoch, queued invalidation, or retirement ordering. This is a second maintenance execution path and contradicts both the sole-owner contract table and the Manager cache-only definition of done. The focused `request-queue` fixture exercises only Supervisor IPC requests, so its PASS cannot detect this bypass.

### P1-02 - Compilation and Asset Update do not suspend an in-flight maintenance generation

`OnEditorUpdate` derives only `playTransition` and passes only that value to both `BackgroundScheduler.SetMaintenanceSuspended` and `SupervisorIntentAdapter.SetMaintenanceSuspended` (`AICodedbEditorLifecycle.cs:391-414`). `EditorApplication.isCompiling` and `EditorApplication.isUpdating` are consulted when deciding whether to start initialization, reconcile, or reconnect (`AICodedbEditorLifecycle.cs:142-146`, `322-325`, `580-583`, `1702-1706`), but they never drive suspension or generation invalidation for work that is already active.

`OnBeforeAssemblyReload` eventually invalidates local waiters (`AICodedbEditorLifecycle.cs:555-565`), but that is later than compilation start and does not cover an Asset Update that completes without a reload. The direct tests prove the pure start-deferral predicate and generic adapter suspension, but do not connect compile/update transitions to `SetMaintenanceSuspended` (`AICodedbEditorLifecycleTests.cs:3016-3034`, `3955-3978`).

Impact: maintenance admitted immediately before compilation or Asset Update may continue across that transition, and an update-only boundary has no epoch change that rejects its late result. This does not satisfy the frozen compile/asset/Play/Domain Reload suspension and stale-result contract.

## Finding Summary

- `BLOCKER`: none.
- `P1`: 2.
- `P2`: none.
- `FOLLOW-UP`: none added in this bounded review.

Findings are returned once to Planner/User. Verifier did not contact Coder or request a repair.

## Confirmed Narrow Passes

The following source properties are present, but do not close the findings above:

- Supervisor owns a bounded 16-pending-query queue and one pending maintenance slot.
- Queries are drained before pending maintenance and remain eligible while one maintenance operation is active.
- Active and queued same-key maintenance requests are reused; distinct work fails closed when the pending maintenance slot is occupied.
- Maintenance keys cover every request field consumed by the current watcher/materializer runners.
- Queued operations bind `owner_epoch`; queued requests are invalidated on retirement and selected-instance handoff.
- Queued maintenance is memory-only and becomes durable only when admitted as active.
- The Unity intent adapter does not own runtime keys, priority, or coalescing, and rejects late local-generation results.
- Manager open/repaint and its explicit status-refresh request no longer launch the removed pre-lifecycle Probe fallback.
- Authenticated shutdown and unrelated-process preservation remain present in inherited source/tests; they were not independently executed in this review.

## Reused Coder Evidence

- Evidence Checkpoint 01 corrected static/source batch: `PASS`, exit `0`, in-script `908 ms`, tool-observed `2.3791987 s`.
- Fixed eleven-path `git diff --check`: `PASS`, no reported output.
- Focused Node `request-queue` L0: `PASS`, exit `0`, in-script `11173 ms`, tool-observed `12.4019224 s`, retry `0`.
- Pre/post HEAD and ordered eleven-path identity remained unchanged in the checkpoint.
- The original static batch `FAIL` is retained as a Coder-authored marker mismatch (`value.state = "queued";` versus the actual object initializer `state: "queued"`), not as a production parse/runtime failure.

The focused L0 proves the Supervisor fixture's active Probe, one queued Verify, duplicate reuse, queue-full rejection, query-before-pending-maintenance order, and owner-epoch field. It does not exercise the Manager bypass or compile/asset transition wiring identified above.

## Review Scope

Read-only review was limited to `TASK.md`, `RESULT.md`, the S14r consolidated handoff statements, the fixed S15 production/test paths, and direct `AICodedbActions` references needed to classify the Manager execution path. No protected validation-project or runtime state was read.

No source, test, task card, result, inherited dirty file, or protected state was modified. The only write is this verification report.

## NOT RUN / DEFERRED

- Coder's passing static/source and focused Node commands: reused, not rerun.
- Independent Node/PowerShell execution: `NOT RUN` because the blocking findings are established by the frozen source paths and duplicate execution would not close them.
- Affected C# L1/EditMode methods: `NOT RUN / DEFERRED`; no Unity authorization or approved Editor entry was provided.
- C# compile: `NOT RUN / DEFERRED`.
- Unity, Unity MCP, PlayMode, BatchMode, visible lifecycle acceptance: `NOT RUN / DEFERRED`.
- Real compilation, Asset Update, Domain Reload, reconnect, outage, shutdown, stale/missing-index, and external-client preservation acceptance: `NOT RUN / DEFERRED`.
- Full Node/PowerShell suites, full regression, consumer/third-party Package validation, release publication: `NOT RUN / DEFERRED`.

No missing evidence is inferred as PASS. S14r affected EditMode remains inherited `DEFERRED`.

## Residual Risk And Disposition

Because P1-01 leaves a second heavyweight maintenance path and P1-02 leaves two frozen transition boundaries unwired, the snapshot is not acceptable as the S15 release closure. Deferred runtime/Unity gates remain open independently of these source findings.

Next owner: `UnityCodeDB v0.3 Planner`.

Next action: Planner/User decides `ACCEPT / FIX / DEFER / STOP`. Verifier does not dispatch repair work, commit, push, or publish.

Current task: `cdb-v0.3-p0-s15-query-first-lifecycle-maintenance-queue`  
Current status: `FAIL`  
Next notification: `UnityCodeDB v0.3 Planner`  
Human decision or authorization required: `ACCEPT / FIX / DEFER / STOP`

---

# FIX Review 01 - Admission Blocked

## Verdict

`BLOCKED`

The targeted review of the two original P1 findings did not enter source review because the handed-off frozen identity could not be reproduced from the available task artifacts and scoped paths.

## Admission Evidence

- Expected HEAD: `a60b92f36679834d1696e4133561bbbc770139be`.
- Observed HEAD: `a60b92f36679834d1696e4133561bbbc770139be` - `PASS`.
- Expected 12-path identity: `a85b0012cb63d83494dbfdbf7aae3db5dd212f53`.
- The handoff did not enumerate the twelve paths. Using the prior fixed eleven production/test paths plus the direct dependency `com.rice.ai-codedb/Editor/AICodedbActions.cs`, the scoped HEAD-relative binary diff identity was `afae3d2bf8c95306920d032a2f9d7d1ba8e7debc` - `MISMATCH`.
- The same scoped query contained ten modified paths; `AICodedbActions.cs` and `AICodedbLifecycleEvidence.cs` contributed no HEAD-relative diff.
- Current `RESULT.md` remained the prior 18429-byte artifact, SHA-256 `897b9201b5bb0a5e4c12f5ab20219894249085a007c72e68e7e4f02db5cbbb21`. It contains Evidence Checkpoint 01 and the original eleven-path identity, but no record of this P1 fix snapshot, no authoritative 12-path list, no `a85b0012...` binding, and no new Coder evidence to reuse.

The first identity calculation was index-relative. One corrected calculation used `git diff HEAD --binary` over the same bounded candidate path list so staged content could not be omitted; it produced the same mismatch. No further identity guesses or searches were performed.

## Findings

No new code finding was issued because admission did not pass.

- Original `P1-01`: `NOT REVIEWED / NOT CLOSED`.
- Original `P1-02`: `NOT REVIEWED / NOT CLOSED`.

The identity mismatch is a handoff/admission block, not evidence of a source or test failure.

## Evidence Boundary

- Reused Coder test evidence: `NOT AVAILABLE FOR THIS FIX SNAPSHOT` in the current task artifacts.
- Source and adjacent regression review: `NOT STARTED` after identity mismatch.
- Tests, compile, Node, PowerShell, Unity, Unity MCP, EditMode, PlayMode, BatchMode, and manual lifecycle acceptance: `NOT RUN`.
- Source, tests, TASK, RESULT, protected state, and existing dirty files: `NOT MODIFIED`.
- Commit/push and Coder contact: `NOT PERFORMED`.

## Required Handoff

Next owner: `UnityCodeDB v0.3 Planner`.

Next action: reconcile the exact frozen 12-path list and identity with the current checkout, and provide the stable FIX RESULT/Coder evidence before routing this same bounded review again. Planner/User retains the `ACCEPT / FIX / DEFER / STOP` decision; Verifier does not contact Coder or dispatch repair work.

Current task: `cdb-v0.3-p0-s15-query-first-lifecycle-maintenance-queue`  
Current FIX review status: `BLOCKED_AT_ADMISSION`  
Next notification: `UnityCodeDB v0.3 Planner`  
Human decision or authorization required: reconcile handoff identity/evidence, then decide `ACCEPT / FIX / DEFER / STOP`.

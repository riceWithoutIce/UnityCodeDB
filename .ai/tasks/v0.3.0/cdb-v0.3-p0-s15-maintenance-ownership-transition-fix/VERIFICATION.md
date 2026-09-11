# VERIFICATION - cdb-v0.3-p0-s15-maintenance-ownership-transition-fix

## Verdict

`BLOCKED`

本次 `RELEASE / 定向只读` 验收在冻结身份 admission 阶段停止。当前 12-path identity 与任务声明的冻结 identity 不一致，因此不能把当前未提交快照视为已交接的审核对象，也不能将 Coder 的既有证据推断为当前快照的 `PASS`。

## Frozen identity

- Expected HEAD: `a60b92f36679834d1696e4133561bbbc770139be`
- Observed HEAD: `a60b92f36679834d1696e4133561bbbc770139be`
- HEAD check: `PASS`
- Expected 12-path identity: `a85b0012cb63d83494dbfdbf7aae3db5dd212f53`
- Observed 12-path identity: `afae3d2bf8c95306920d032a2f9d7d1ba8e7debc`
- 12-path identity check: `FAIL`

Identity was recomputed once, using the TASK-defined fixed path order and the scoped command:

```powershell
git diff HEAD --binary -- <TASK-defined 12 paths in fixed order> | git hash-object --stdin
```

Raw output:

```text
afae3d2bf8c95306920d032a2f9d7d1ba8e7debc
```

## Findings

### BLOCKER-01 - Frozen 12-path identity does not match

The exact review snapshot is not stationary under the declared identity. Because the release handoff cannot be bound to the current 12-path patch, review of P1-01, P1-02, and their adjacent regressions was not admitted.

No additional findings were produced. Per the bounded-review rule, source and test inspection stopped immediately after the identity mismatch.

## Review scope disposition

- Manager five-entry routing into the single Supervisor queue: `NOT REVIEWED / BLOCKED BY IDENTITY`
- Manager cache-only behavior and removal of the duplicate full-status lane: `NOT REVIEWED / BLOCKED BY IDENTITY`
- Compilation/Asset Update suspension, generation invalidation, and late-result rejection: `NOT REVIEWED / BLOCKED BY IDENTITY`
- Query-first, coalescing, owner-epoch, and unsupported-action adjacent regressions: `NOT REVIEWED / BLOCKED BY IDENTITY`

## Reused evidence

`RESULT.md` records the following Coder evidence, but none is promoted to Verifier `PASS` because the current patch identity does not match the frozen snapshot:

- Static/source checks: reported exit `0`, `338 ms`, retry `0`.
- Focused `request-queue` L0: reported exit `0`, `13.1565922 s`, retry `0`.
- 12-path scoped `git diff --check`: reported exit `0`, no output.

## NOT RUN / DEFERRED

- Source and direct-test semantic review: `NOT RUN` after admission stop.
- Coder static/source commands and focused request-queue L0: `NOT RERUN`.
- C# compile and EditMode: `DEFERRED`.
- Unity, Unity MCP, and manual lifecycle acceptance: `NOT RUN`.
- PowerShell materializer tests, full regression, and real business processes: `NOT RUN`.
- Repository-wide search, full diff, commit, push, and Coder contact: `NOT RUN`.

## Residual risk

Until Planner supplies or confirms a stationary snapshot whose 12-path identity matches the declared freeze, the two original P1 closures and their adjacent regressions remain unverified for release. The mismatch alone does not establish a source defect; it establishes that the handed-off evidence cannot be traced to the current review object.

## Next step

Planner should reconcile the declared and observed 12-path identities and provide one stable frozen handoff. Planner/User then decides `ACCEPT / FIX / DEFER / STOP`; this Verifier does not contact Coder or modify the snapshot.

当前 S15 RELEASE 定向只读验收已完成（身份 admission `BLOCKED`），下一步需要通知 Planner 汇总并确认冻结快照，由 Planner/User 决定 `ACCEPT / FIX / DEFER / STOP`。

---

## Canonical identity reconciled review

### Active verdict

`PASS`

本节是同一冻结快照在 identity 算法协调后的 `RELEASE / 定向只读` 复审结果。上方原始 `BLOCKED` 报告作为历史 admission 记录保留；本节的 `PASS` 是当前有效结论，仅覆盖原 P1-01、P1-02 及其紧邻回归。

- Verification profile: `v0.3.verifier.deep`
- Review date: `2026-09-11`
- Findings: `无`

### Admission identity

- Expected HEAD: `a60b92f36679834d1696e4133561bbbc770139be`
- Observed HEAD: `a60b92f36679834d1696e4133561bbbc770139be`
- HEAD: `PASS`
- Expected canonical 12-path identity: `afae3d2bf8c95306920d032a2f9d7d1ba8e7debc`
- Observed canonical 12-path identity: `afae3d2bf8c95306920d032a2f9d7d1ba8e7debc`
- Canonical identity: `PASS`

Canonical identity was computed once with the sole authorized method and the fixed TASK path order:

```powershell
git diff HEAD --binary -- <TASK-defined 12 paths in fixed order> | git hash-object --stdin
```

Raw output:

```text
afae3d2bf8c95306920d032a2f9d7d1ba8e7debc
```

`CHECKPOINT-01.md` records that `a85b0012cb63d83494dbfdbf7aae3db5dd212f53` was the historical `git patch-id --stable` result for the same diff stream, not the canonical snapshot identity. No production or test bytes changed during that reconciliation. The historical `BLOCKER-01` is therefore closed for admission by provenance correction, not by a source modification.

### P1-01 - Manager ownership

Verdict: `PASS`

1. All five frozen Manager paths use `RunSupervisorMaintenanceAction` with the closed action names:
   - `Refresh If Stale` -> `RefreshIfStale`
   - `Refresh Index` -> `RefreshIndex`
   - `Build Shader Adapter` -> `BuildShaderAdapter`
   - `Clean Index` -> `CleanIndex`
   - `Rebuild Index` -> `RebuildIndex`
2. `RunSupervisorMaintenanceAction` calls `AICodedbEditorLifecycle.RunSupervisorMaintenanceCommandAsync(action)` directly. None of the five paths references its former `AICodedbActions` script runner or the Manager's generic `RunAction` / `Task.Run` path. The generic lane remains only for unrelated, out-of-scope diagnostics and watcher controls.
3. The maintenance helper passes `refreshStatusAfterAction: false`; its completion therefore skips Manager-owned `RefreshStatusAsync` filesystem/hash/full-status work. It requests lifecycle reconcile instead. The synchronous `RefreshStatus()` used for presentation reads existing/persisted in-memory state and does not invoke the full-status path.
4. Lifecycle submits command `maintenance` through `AICodedbSupervisorIntentAdapter` and `AICodedbSupervisorBridge`; it records the returned observation without publishing a Supervisor-only Manager cache revision. The following lifecycle reconcile remains responsible for revision-consistent product/Supervisor cache publication.
5. The Supervisor exposes exactly the five-value `PROJECT_MAINTENANCE_ACTIONS` map. It rejects an unknown action with `INVALID_ARGUMENT` before `admitMaintenance`, derives the script and arguments from `context.selectedInstance.generationRoot`, and records the selected instance, selected generation, runtime contract, and owner epoch on the admitted operation.
6. All five actions enter the existing `admitMaintenance` path, `pendingMaintenance` bound, key reuse, and `activeOperation`; no second execution queue or caller-provided script authority is present in the reviewed path.

Direct source anchors:

- `AICodedbManagerWindow.cs`: lines 1451-1457, 1599-1606, 2068-2094, 2239-2357.
- `AICodedbEditorLifecycle.cs`: lines 1310-1340.
- `codedb-project-supervisor.mjs`: lines 67-72, 1358-1425, 1482-1490, 1851-1878.

### P1-02 - Compile/update boundary

Verdict: `PASS`

1. `OnEditorUpdate` combines `EditorApplication.isCompiling`, `EditorApplication.isUpdating`, and the Play suspension signal through `ShouldSuspendMaintenance`.
2. Both `BackgroundScheduler.SetMaintenanceSuspended` and `SupervisorIntentAdapter.SetMaintenanceSuspended` run before the five-second heartbeat early return. Compilation or Asset Update therefore invalidates active local maintenance without waiting for the heartbeat interval.
3. A suspension state transition advances the intent adapter generation, cancels maintenance entries, and rejects completion whose generation is obsolete. The background scheduler also cancels its active local maintenance tokens; it does not stop or assume ownership of an already admitted external Supervisor process.
4. Maintenance dispatch is rejected while suspended, while non-maintenance query/status/reconnect intent remains admissible. Direct adapter coverage exercises a new query during suspension and a late maintenance completion at the generation boundary.
5. The Play callback uses the same combined predicate. `RequestReconcile` also checks compile/update/Play suspension, so explicit reconcile cannot bypass the boundary. Reconnect remains a non-maintenance observation and retains its established lifecycle guards.

Direct source anchors:

- `AICodedbEditorLifecycle.cs`: lines 391-440, 485-525, 587-654, 1599-1635, 1700-1771, 3639-3722.
- `AICodedbSupervisorRequestQueue.cs`: lines 87-159 and 198-235.

### Adjacent S15 regressions

Verdict: `PASS`

- Query-first priority remains explicit: queued queries drain before pending maintenance and may run while a maintenance operation is active.
- Query and maintenance keys retain bounded coalescing/reuse; the local C# adapter does not introduce runtime key or admission policy.
- Queued query and maintenance entries remain bound to `ownerEpoch`; obsolete-owner work is rejected before or after execution.
- Maintenance operations retain one active operation plus one bounded pending maintenance request and the selected immutable generation binding.
- Reconnect still reuses an in-flight Bridge request, while authenticated shutdown validates lifecycle identity, invalidates pending requests, and does not introduce a second stop authority.
- The reviewed paths add no compatibility branch, Unity-version condition, second queue, or second maintenance authority.

Direct source anchors:

- `codedb-project-supervisor.mjs`: lines 1090-1210, 1284-1425, 1429-1524, 1947-1967.
- `AICodedbSupervisorBridge.cs`: lines 1091-1162, 1164-1195, 2189-2279.

### Reused Coder evidence

No evidence command was rerun. The following `RESULT.md` records are reused and remain traceable to the admitted canonical snapshot through `CHECKPOINT-01.md`:

- Static/source batch: exit `0`, `338 ms`, retry `0`; compact result:
  `manager_ownership=PASS cache_only_completion=PASS compile_update_suspension=PASS generation_invalidation=PASS node_syntax=PASS actions_unchanged=PASS`.
- Focused `request-queue` L0: exit `0`, `13.1565922 s`, retry `0`; it covers query-first ordering, bounded/coalesced maintenance, owner-epoch binding, all five maintenance mappings, and unsupported-action rejection.
- Fixed 12-path `git diff --check`: exit `0`, no output, retry `0`.
- `AICodedbActions.cs`: recorded byte-identical to HEAD and not used by the five repaired Manager flows.

The direct tests present in the snapshot cover the five Manager mappings, removal of their direct action calls, cache-only completion, lifecycle maintenance dispatch, compile/update/Play combination, pre-heartbeat suspension, generation-based late-result rejection, query eligibility, query-first/coalescing/owner-epoch behavior, the five Supervisor mappings, and unsupported action rejection. Their C# execution remains deferred as stated below.

### Findings

`无`。未发现原 P1-01、P1-02 或规定紧邻回归范围内的 `BLOCKER / P1 / P2`。没有将理论加固或范围外事项升级为本轮 finding。

### NOT RUN / DEFERRED

- Coder static/source batch, focused request-queue L0, and 12-path diff-check: `NOT RERUN`; evidence reused from `RESULT.md`.
- C# compilation and affected C# tests: `DEFERRED`.
- Unity EditMode and manual lifecycle validation: `DEFERRED`.
- Unity and Unity MCP: `NOT RUN`.
- PowerShell materializer/package-boundary tests and complete Node suite: `NOT RUN`.
- Full L0/L1, repository regression, and real business processes: `NOT RUN`.
- Protected validation-project/runtime state: `NOT READ / NOT MODIFIED`.
- Repository-wide search, full diff, source/test modification, Coder contact, commit, and push: `NOT PERFORMED`.

### Residual risk

The new C# route and Unity boundary behavior have source-level review and recorded static evidence, but no independently executed C# compile, EditMode, or live Unity transition evidence in this task. Dynamic evidence is limited to the Coder's focused synthetic Supervisor queue run. These are explicit deferred release boundaries and are not represented as `PASS`.

### Routing

Current task: cdb-v0.3-p0-s15-maintenance-ownership-transition-fix
Current status: PASS
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner/User disposition
Human decision or authorization required: ACCEPT / FIX / DEFER / STOP

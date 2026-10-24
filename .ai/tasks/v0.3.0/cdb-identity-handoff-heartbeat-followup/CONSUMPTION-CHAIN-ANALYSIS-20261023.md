# Supervisor 状态消费链静态分析

日期：2026-10-23  
范围：只读静态检查；未修改 Package、Unity 工程、MCP 注册或运行态。

## 结论

当前实现存在三条相互独立的状态来源，不能把 Manager 上看到的单个文案直接等同于心跳或身份交接失败：

1. Supervisor 的 `maintenance` 是公共 readiness 的操作叠加层。
2. Lifecycle 的 `ProductState` 来自 materializer 输出，再经过 operational observation 绑定。
3. Manager 的 `Unconfirmed`／`Needs attention` 还可能来自用户动作状态覆盖。

因此，应分别核对 operational observation 绑定、缓存时效、恢复和动作覆盖分支。公共 maintenance 与用户报告的 UI 波动尚未建立因果；仅凭 UI 文案也不能判定 lease heartbeat 失效。

## 消费链

### 1. Supervisor readiness

`codedb-project-supervisor.mjs` 先发布 Coordinator 的 operational readiness；当存在运行中的 operation 时，`updateReadiness` 将公共 `readiness_state` 改为 `maintenance`，原因码为 `SUPERVISOR_MAINTENANCE`。这不会改变已发布的 operational observation 本身，后者仍可为 `core_ready`。

`AICodedbSupervisorBridge.TryResolveReadiness` helper 把 Provider 已 ready、但 adapter/worker 正在准备的组合归为 `Maintenance`。但不能将这个 helper 的规则当作当前真实状态解析路径：`ParseSupervisorStatusResponse` 中的 `reportedReadiness` 取自 `operational_readiness.state`（当前源码约 3054 行），随后据此构造 Snapshot（约 3201 行）。公共 readiness 的 maintenance 叠加本身不能证明 Bridge Snapshot 也变为 Maintenance。

对应源码：

- `Tools~/codedb-project-supervisor.mjs:1827-1838`
- `Editor/AICodedbSupervisorBridge.cs:601-731`

### 2. Lifecycle 产品状态

`AICodedbStatusSnapshot` 和 Lifecycle worker 通过 `AICodedbProductStatusBuilder.Build` 读取 materializer 的产品层 marker。`READY` 需要四个产品层均为 `CURRENT` 且命令成功；未满足但没有明确阻断时会得到 `Starting`，失败、阻断或显式 `NEEDS_ATTENTION` 才得到 `NeedsAttention`。

`RememberLifecycleProductStatus` 随后调用 `BindProductStatusToSupervisorObservation`。它要求 materializer 中唯一的 `[SUPERVISOR_OPERATIONAL_READINESS]` marker 与 Bridge 的同一 `observation_id/revision/owner_epoch/supervisor_id/supervisor_pid` 完全匹配。Ready 结果缺 marker、marker 无法认证或 revision 不一致，会被转换为 `NeedsAttention`；Starting 结果缺 marker 则暂时保留 Starting。

这说明“Supervisor 仍然活着但观测没有配对”可以产生 Needs attention，而不是直接证明 Provider 已退出。

对应源码：

- `Editor/AICodedbStatusSnapshot.cs:55-105`
- `Editor/AICodedbHostPayloadMaterializer.cs:859-990`
- `Editor/AICodedbEditorLifecycle.cs:3486-3638`

### 3. Manager 显示边界

Manager 只消费 Lifecycle cache，不为绘制窗口自行发起后端检查。Ready 需要同时满足项目/Package/runtime/generation/contract、配对的 operational observation、`CoreReady` 和 30 秒 observation freshness。Ready 过期或不满足显示边界时可显示 Starting；但目前不能证明捕获到的公共 maintenance 使这些条件失效。此前“公共 maintenance → Bridge Maintenance → Manager Starting”的直接因果推断撤回。

已记录的观察器只证明公共状态曾为 `maintenance/SUPERVISOR_MAINTENANCE`，同时 operational readiness、Coordinator、Provider 和 Adapter 仍是 ready/operational。它没有读取 Bridge/Lifecycle 内存缓存或 UI，不能闭合 Manager 显示因果。

对应源码：

- `Editor/AICodedbEditorLifecycle.cs:2298-2312`
- `Editor/AICodedbManagerWindow.cs:743-801`
- `Editor/AICodedbManagerWindow.cs:1087-1094`
- `Editor/AICodedbManagerWindow.cs:3571-3629`

### 4. `Unconfirmed` 与 action overlay

`Unconfirmed` 不是 Supervisor readiness 枚举。它来自 Manager action session 的 `Recovery` 或完成后状态未确认：

- action 正在运行时显示 `CodeDB action in progress`；
- action 完成但状态仍需处理时显示 `Completed - needs attention`；
- action 结果未能得到新产品状态时，顶栏可显示 `CodeDB status unconfirmed`；
- 跨 Manager/Editor 边界后无法确认原动作结果时显示 `Outcome unconfirmed`，并阻止下一次动作。

对应源码：

- `Editor/AICodedbActivityPanel.cs:455-739`
- `Editor/AICodedbManagerWindow.cs:3475-3510`

### 5. Heartbeat 与 lease

Editor lifecycle 的 heartbeat tick 为 5 秒；正常路径在非维护状态下排队 lease refresh。`ShouldRefreshEditorLease` 明确不因 reconcile in flight 本身而禁止刷新。lease 消费端仍按独立的年龄、PID 和 process-start identity 规则判断有效性。

因此当前静态证据更支持“ready display/operation overlay 与 heartbeat 是分层的”。仍需现场时间序列才能判断 compile/update、domain reload、队列延迟或 lease 年龄是否真正跨过消费者阈值。

对应源码：

- `Editor/AICodedbEditorLifecycle.cs:21-31,420-470`
- `Editor/AICodedbEditorLifecycle.cs:3958-3970`

## 当前判定

- `maintenance` 与 `Starting`：属于不同层的状态，尚未证明本次二者存在直接转换关系；不能单独判定故障。
- `Needs attention`：只有在 materializer 明确失败/阻断、readiness 绑定失败、恢复尝试耗尽或保留的终态失败时才成立；需要现场 reason/detail 才能归因。
- `Unconfirmed`：属于动作结果确认链；静态上与 idle heartbeat 不是同一状态机。
- 心跳/身份交接：源码有独立生产、消费和身份绑定约束；当前没有同时刻 lease、Bridge observation、Coordinator state 与 Manager 文案的证据，根因仍未闭合。

## 下一步边界

下一步优先只读盘点已有诊断产物能否提供 Manager 产品状态、动作 phase、缓存观测时间/revision 和刷新失败原因，并核实第二次 materialize:Upgrade 的触发来源。若已有证据不足，再对齐最小自动关联观测；不重复执行仅观察后端的同类快照，不要求人工抓瞬间，不直接重构或调整心跳阈值。

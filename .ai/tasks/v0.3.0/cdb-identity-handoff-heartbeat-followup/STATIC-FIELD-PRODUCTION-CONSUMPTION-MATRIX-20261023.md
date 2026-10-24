# v0.3 状态字段生产与消费矩阵

日期：2026-10-23。状态：READ_ONLY_STATIC_MAPPING / NO_PRODUCT_CHANGE。

本轮只读取交付 Package `G:\RiceProgram\Test\CodedbTest\Packages\61dcd26-s42-ipc-compile-repair\com.rice.ai-codedb` 的 Editor 源码，并对照已有脱敏日志结论。没有修改产品代码、目标工程、配置或运行态文件，也没有调用 MCP、IPC、Unity API 或维护操作。

## 1. 字段层级

| 层级 | 主要类型/来源 | 生产位置 | 消费位置 | 当前边界 |
| --- | --- | --- | --- | --- |
| Supervisor readiness | `AICodedbSupervisorSnapshot.ReadinessState`, `ReasonCode`, `Detail` | `AICodedbSupervisorBridge.TryResolveReadiness`，约 602—733 行 | Lifecycle observation binding、Manager status boundary | 是后端运行态；`Maintenance` 可以与 Provider ready 并存，不等于 Product `NeedsAttention` |
| Product state | `Starting/Ready/NeedsAttention/...` | `AICodedbProductStatusBuilder.Build`、Lifecycle 分支、`CreateObservationBindingFailure` | Lifecycle cache、SessionState、StatusSnapshot、Manager overall title/state | 当前实例可用性与集成/前置条件的聚合结果 |
| Product detail | `Detail`, `DiagnosticDetail`, `AttentionReason` | `AICodedbProductStatus` 构造点、observation binding、迁移/认证分支 | StatusSnapshot description/items、移除动作禁用原因、terminal failure | 普通状态只在内存 cache 中保留完整值；`AttentionReason=None` 仍可表示 NeedsAttention |
| Command result | `AICodedbMaterializerCommandStatus` | `[COMMAND_RESULT]` 解析，`AICodedbMaterializerCommandStatusParser` | Terminal failure candidate、Retire 后 warning、Activity summary | 包含 `phase/reason_code/cleanup_state/next_action`，但不是独立 Product state |
| Cleanup result | `cleanup_state`、`mutated_scopes`、`next_action` | instance engine/materializer command result | Lifecycle `ResolveCurrentInstanceConvergencePlan`、desired-state更新、warning | 只有 `COMPLETE/PENDING` 两值；原因和 progress 没有上送为独立调度信号 |
| Lifecycle cache | product status + command result + Supervisor snapshot + terminal failure + revision | `PublishLifecycleStatusCache`，约 3449—3464 行 | `AICodedbStatusSnapshot.CreateCachedStatus`、Manager | 进程内一致 tuple，但没有持久化为完整跨轮诊断记录 |
| SessionState | last product state、Ready fingerprint、lease prerequisite、terminal failure | `PersistProductState`、`PersistLeasePrerequisite`、`PersistTerminalConvergenceFailure` | `TryGetPersistedProductState`、重载后的缓存显示 | 普通 Product state 只保存枚举；detail/reason/observation/operation 不随普通状态保存 |
| Manager action overlay | action phase/presentation/status label/detail | `AICodedbUserActionStatus.BuildPresentation`、`ResolveActionEvidenceAsync` | Manager header/overview/activity panel | 可能覆盖 Product status 的显示；`Unconfirmed` 是动作证据未确认的 presentation，不是 Product enum |

## 2. 关键生产链

### 2.1 Supervisor readiness

`TryResolveReadiness` 先检查 desired/editor/provider/adapter/worker 的枚举合法性，再按优先级返回 `Stopped`、`Degraded`、`Stopping`、`Starting`、`Maintenance` 或 `CoreReady`。

其中：

- Provider 不是 `ready` 时返回 `Starting`；
- Provider ready、adapter 正在准备时返回 `Maintenance`；
- Provider、adapter、worker 都满足条件时返回 `CoreReady`；
- 该方法只产生 Supervisor readiness，不直接产生 Manager 文案。

因此“公共 maintenance”与“Manager Needs attention”必须通过后续 Lifecycle/Manager 消费链关联，不能直接等同。

### 2.2 Product state

Lifecycle 在 `RunReconcileWorker` 中取得独立 prerequisite、Coordinator admission、Probe 和 current-instance convergence plan，然后通过 `RememberLifecycleProductStatus` 绑定 Supervisor observation 并发布 cache。

`CreateObservationBindingFailure` 在 Ready materializer output 缺少或无法认证 operational observation 时构造 `NeedsAttention`，但 `AttentionReason` 明确设为 `None`。这解释了为什么只看 `AttentionReason` 不能覆盖所有 NeedsAttention 原因。

`TryCreateTerminalConvergenceFailure` 只在满足认证终态条件时生成可持久化 terminal envelope。普通 transient/early-return NeedsAttention 不会自动获得同等持久证据。

### 2.3 Cleanup 与 Product state 的交叉点

Lifecycle 在当前实例为 Current、产品状态 Ready、cleanup Pending 时选择 `Retire`；执行 Upgrade 后再 Probe，并把重新观察结果作为本轮 product status 发布输入。这里 cleanup result 进入当前 Product 状态刷新路径，但 Cleanup 本身不是 Product state 的独立字段。

因此目前存在两条语义被压在同一轮：

```text
历史 cleanup 是否完成
        ↓
是否选择 Retire / Upgrade
        ↓
重新 Probe 与 observation binding
        ↓
当前 Product state
```

这证明存在耦合点，但不证明任何具体 NeedsAttention 必由 cleanup 产生。

## 3. 持久化与显示链

### 3.1 Lifecycle cache

`PublishLifecycleStatusCache` 在单一锁内更新：

- `_cachedHostStatusResult`
- `_cachedLifecycleProductStatus`
- `_cachedLifecycleSupervisorSnapshot`
- `_cachedTerminalConvergenceFailure`
- `_hasCachedLifecycleProductStatus`
- cache revision

这是进程内的原子组合，适合 Manager 同轮读取；但 `CODEDB_S12_EVIDENCE` 只记录累计计数和当前摘要，没有把该 tuple 的 epoch、UTC、reason、operation、observation age 持久化。

### 3.2 SessionState

`PersistProductState` 普通情况下只保存：

- `LastProductStateKeyPrefix + projectIdentity`
- Ready 时的 package fingerprint；其他若干状态清空 Ready fingerprint

`PersistLeasePrerequisite` 只保存布尔值；terminal failure 另行保存序列化 envelope。于是跨 Domain Reload 或 Manager 重开时，普通 `NeedsAttention` 的决定性 detail 不能从普通 Product state 恢复。

### 3.3 StatusSnapshot

`CreateCachedStatus` 读取 Lifecycle cache 中的 product status；`CreateCachedState`/`CreateCachedReady` 只生成显示用 fallback。

Cached Ready 路径将 Background cleanup 标为 `Not checked`，最多附带旧 `DiagnosticDetail`，明确表示当前缓存显示不重新检查 cleanup。这是显示层的边界，不是 cleanup 已完成的证明。

### 3.4 Manager action overlay

Manager header、overview title、overview description 和 displayed state 先调用 `TryGetActionStatusOverride`。只要 action 正在运行、已完成但 presentation 为 warning，或 action 失败且没有 fresh Product state，overlay 就覆盖 Product state 的显示。

映射结果：

- action running：`CodeDB action in progress`；
- completed warning 且 label 为 `Completed - needs attention`：`CodeDB needs attention`；
- 其他需覆盖的未确认动作：`CodeDB status unconfirmed`。

`ResolveActionEvidenceAsync` 在 direct/Supervisor terminal 缺失、冲突或 Pending 时构造 `UnconfirmedActionResult`。所以 `Unconfirmed` 来源是 Manager action evidence layer，不等于 Lifecycle Product state，也不等于 Supervisor readiness。

## 4. 当前暴露的契约缺口

### A. 状态结果与状态证据分离

Product state 可以发布 `NeedsAttention`，但普通持久化只保存枚举；决定该状态的 `source_stage/reason/detail/observation/operation` 未绑定到同一可恢复记录。

### B. 字段有效期没有 epoch 标记

`ResetPostAdmissionEvidence` 在 reconcile worker 中段调用，而 `CODEDB_S12_EVIDENCE` 是累计快照。早退或异常时，`post_admission_disposition/current_instance_convergence_plan` 可能反映上一次有效值。现有 1980 记录的 Retire + materializer delta 0 是这一风险的运行侧例子，但不是源码级确定的具体早退分支。

### C. Cleanup state 与 retry eligibility 合并

Command result 只有 `cleanup_state=PENDING`，Lifecycle 只据此判断是否继续 Retire；没有分类原因、progress fingerprint、last-change 或 retry eligibility。

### D. Action overlay 与 Product state 分层但诊断没有统一 tuple

Manager 可以显示 `Unconfirmed` 覆盖 Product state，而 Lifecycle/StatusSnapshot 只持有另一条 cache。两者的 action ID、Product cache revision 和 observation age 没有在同一日志记录中落盘，造成 UI 文案与后台状态难以精确关联。

## 5. 不应据此做出的结论

- 不能说所有 `NeedsAttention` 都是 heartbeat 失效；
- 不能说所有 `Unconfirmed` 都是身份交接失败；
- 不能说 Supervisor `Maintenance` 等价于 Manager `Needs attention`；
- 不能说 `cleanup=PENDING` 就代表旧进程仍存活；
- 不能用 Ready fingerprint 或磁盘 pointer 代替实时 MCP 身份响应。

## 6. 建议的最小诊断字段（不改变状态判定）

下一次实现或实验前，先冻结以下字段的定义：

```text
reconcile_epoch
started_at_utc / completed_at_utc
source_stage
product_state_before / product_state_after
reason_code / attention_reason
bounded_detail
request_id / operation_id (or explicit missing reason)
observation_id / observation_revision / observation_age
cleanup_state / cleanup_reason / progress_fingerprint / retry_eligibility
action_id / action_phase / action_evidence_kind
cache_revision_before / cache_revision_after
field_validity_epoch
```

该列表是诊断契约候选，不是本轮授权的实现清单；它不放宽认证、不增加删除权限、不改变 heartbeat 或 timeout。

## 判定

静态生产/消费矩阵已完成。当前最优先的局部问题是**证据 tuple 没有跨层统一，也没有明确字段有效期**；重复清理则是**cleanup 完成语义与 retry eligibility 未分离**。下一步应由用户决定是否授权：

1. 仅增加有界诊断字段；或
2. 先为现有 `Pending` 原因做只读分类函数/contract test；或
3. 暂不修改，接受现有诊断限制。

本轮不进入产品实现。

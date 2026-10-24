# 清理、Lifecycle 与状态发布：设计契约讨论

日期：2026-10-23。状态：READ_ONLY_DESIGN_REVIEW / NO_REFACTOR_AUTHORIZED。

本记录基于已保留 Package 日志、用户提供的 `CODEDB_S12_EVIDENCE`、交付源码静态检查和目标实例运行态文件；没有修改产品代码、运行配置或目标工程。结论分为已证实行为、设计风险和仍需运行证据，不把风险直接称为已确认缺陷。

## 已证实的调用关系

### A. 调度条件把 cleanup Pending 纳入周期性 reconcile

`AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence`（约 2366 行）规定：当前实例存在且为 Current 时，只要产品状态不是 Ready **或**项目 cleanup 为 Pending，就返回 true。`OnEditorUpdate` 的 heartbeat 每 5 秒运行，但 scheduled reconcile 的间隔为 30 秒；到点后 `BackendNeedsReconcile` 读取 integration/instance 状态并进入 reconcile。

### B. Ready + Pending 会选择 Retire

`ResolveCurrentInstanceConvergencePlan`（约 2412 行）规定：Current + Ready + cleanup Pending → `Retire`。RunReconcileWorker 随后（约 1394 行）执行 `materialize:Upgrade`，再执行 Probe 重新观察 readiness。代码注释明确当前实例仍可用，退休实例等待 owner drain；但调度器下一次仍会重新满足同一条件。

### C. Pending 是多来源聚合值

`Get-CombinedInstanceCleanupState` 组合 versioned retirement、普通 instance cleanup 和 legacy cleanup；任一部分 Pending 就返回 Pending。源码可见的来源包括：

- removal intent 仍引用旧实例，按权限边界保持保留；
- 旧实例/Editor lease/Coordinator 仍被判断为 live；
- 退休证据、身份、manifest 或 holder 读取无效；
- 清理函数异常后 catch 并返回 Pending；
- legacy cleanup 失败或仍有历史对象。

目前这些来源没有成为独立的产品状态或调度信号。Upgrade 的结构化结果只保留 `cleanup_state` 和通用 next action，不能告诉 Lifecycle 这次 Pending 是否有新进展。

### D. 状态缓存保存结果，不保存完整判定依据

`RememberLifecycleProductStatus` 会把产品状态、命令结果、Supervisor snapshot 和 terminal failure 一次性写入内存 cache 并推进 revision。`PersistProductState` 对 SessionState 只保存 `Ready/Starting/NeedsAttention/...` 枚举；detail、diagnostic、observation revision/age 没有随普通状态持久化。

观测绑定失败会创建 `NeedsAttention`，但 `AttentionReason` 设为 `None`，detail 只有内存中的 bounded 文本。只有满足认证终态条件的 terminal convergence failure 才会持久化 reason、detail、diagnostic、observation/revision 等完整 envelope。

Manager 的 Ready 显示还会检查同一 context、generation/contract、operational observation 和 30 秒 freshness；Manager action overlay 又是另一层显示来源。已有 `CODEDB_S12_EVIDENCE` 记录了最近状态和计数，但没有每条 reconcile 的 UTC、cache revision、observation age、attention reason 和动作覆盖。

## 可能的职责/耦合问题

### 1. 清理“结果语义”与调度“再次执行资格”没有分离

清理模块回答的是“现在是否完成”；Lifecycle 调度需要回答“现在是否值得再次尝试”。当前一个 `Pending` 同时承担两者，导致合法等待状态也满足 30 秒 scheduled reconcile，并反复触发 Retire/Upgrade/Probe。这个现象由源码和日志共同证实；但是否应改变调度策略仍需产品契约决定。

### 2. 历史清理与当前可用性收敛共用一轮工作

当前实例 Ready 时，历史清理仍进入同一 reconcile worker，并在 Upgrade 后重新 Probe、绑定 operational observation、发布产品状态。设计意图是保护当前实例不被历史问题覆盖；代价是历史清理的维护操作成为当前 Ready 证据刷新路径的一部分。若 Upgrade/Probe 或绑定短暂失败，当前产品状态可能被影响，尽管清理本身与当前实例可用性无关。

这只是耦合风险，不等于已经证明 `NeedsAttention` 由 Retire 造成。已有 7 条 NeedsAttention 中 6 条的 `current_instance_convergence_plan=NotEvaluated`，说明至少部分异常发生在选择清理计划之前。

### 3. 状态发布的证据粒度低于状态判断的证据粒度

Lifecycle 作出 NeedsAttention 时使用了命令结果、产品层、observation marker、revision、owner epoch 和 process identity；普通日志/SessionState 只留下最终枚举或累计计数。于是跨模块调试时只能看到结论，无法稳定回答“哪个判定失败、使用哪一份 observation、是否是动作覆盖”。这是证据契约缺口，不应先用更宽松的 Ready/NeedsAttention 判定来掩盖。

### 4. 身份变化计数不能作为职责失控证据

`TrackIdentity` 对第一次非空值建立基准，之后不同值会递增计数但不更新基准。因此 `supervisor_identity_change_count` 反映的是“与保存基准不同的观测数”，不是去重后的交接次数。这个实现缺陷影响诊断解释，但与 Pending 重复调度是独立问题。

## 候选接近方向（仍不实施）

1. **先把 Pending 分类只读化。** 输出有限枚举，例如 `WAITING_FOR_HOLDER`、`RETAINED_BY_INTENT`、`EVIDENCE_INVALID`、`CLEANUP_ERROR`、`LEGACY_PENDING`，并附 bounded progress fingerprint/last-change time。现有删除权限和身份校验保持不变。
2. **把 retry eligibility 与 cleanup state 分开。** 只有 Pending 原因允许重试且 progress fingerprint 变化、holder/lease 变化或 bounded backoff 到期时才进入完整 Retire；合法且无进展的保留状态可以只做轻量观测。需要先定义安全的 retry/backoff 合约，不能直接停止维护。
3. **把历史清理从当前 Ready 证据刷新中区分。** 讨论是否能在当前 operational observation 已认证且产品层仍 Current 时保持 Ready，同时把清理作为独立 maintenance overlay；失败时显示 cleanup detail，而不是让所有失败都重写当前产品状态。需要 focused contract test，不凭本次日志直接改。
4. **补齐状态发布证据。** 每次状态发布至少保留 bounded `reason_code/attention_reason`、source stage、cache revision、observation id/revision/age、operation id（如有）和 UTC；Manager 读取同一 tuple，区分 product state、maintenance overlay、action outcome。
5. **修正诊断计数语义后再评估身份交接。** 若要修复 `TrackIdentity`，先单独定义“变化事件去重/基准更新/进程 start identity”的契约；不得把它与 Pending 调度修复捆绑。

## 仍需对齐的问题

- 合法保留状态是否允许无限 Pending，还是必须在一段时间后转为明确的可行动状态？
- 无进展的 Pending 是否应继续触发 Upgrade，还是只刷新 holder/lease 证据？
- 当前 Ready 是否应完全独立于历史 cleanup，还是允许 cleanup failure 降级整个产品状态？
- `NeedsAttention` 的最小可持久化证据字段和脱敏上限是什么？
- `Unconfirmed` action overlay 与 Lifecycle product state 是否应继续独立，Manager 如何同时显示？

## 当前判定

已证实存在“Pending → 周期性 Retire/Upgrade/Probe”的重复路径和“多来源 Pending 聚合”契约；已证实普通状态记录不足以还原每次 NeedsAttention 的决定性原因。尚未证明某个单独模块违反其自身权限职责，也未证明该路径必然导致所有 UI 波动。

下一步应先对齐 Pending 分类、retry eligibility、Ready 与历史 cleanup 的边界，以及最小状态证据 tuple。只有这些契约明确后，才决定是局部修正调度、补结果字段、拆分状态发布，或接受现有行为。继续保持只读分析，不改心跳阈值、不删除旧实例、不自动重试 Install/Upgrade，不要求关闭 Unity。

# 既有记录时间线关联：清理前异常与清理后异常分流

日期：2026-10-23。状态：READ_ONLY_CORRELATION_COMPLETE / EXACT_CAUSE_OPEN。

## 执行边界与证据

仅提取已存在的目标实例 Lifecycle 日志、Supervisor events/operation history、desired-state、removal intent 和 pointer；未调用 CodeDB/MCP/IPC、加载产品脚本、查询或控制进程、重试维护操作、修改目标工程。没有开启观察器或等待新事件。新增任务自有离线提取脚本和分析文件。

提取窗口：2026-10-23T04:05:45.624958Z 至 04:05:45.831959Z。各文件依次读取，不构成跨文件原子快照。活动 history 只枚举一次，不补读消失文件。单文件上限 16 MiB，本轮未触及上限；history 枚举 201 项，未触及 512 项上限，读取/解析错误 0。

脱敏、字段白名单回执：

`<repository-root>/.artifacts/tests/identity-handoff-heartbeat/existing-timeline-20261023-01.json`

SHA-256：`6ca3b1980a9948c3a7c34baddeca3473697d90fc8915c385b93186a0d66b80fb`。

原始输入读取字节哈希保存在回执 sources 中。未复制完整 Editor.log 或 operation 的命令行/stdout/stderr；Lifecycle 仅保留精确目标 instance/generation，operations 额外要求 project_identity 一致。Supervisor events 来自目标工程专属目录，但事件自身没有逐条身份字段，不能独立证明每条都属于当前实例。

Editor.log 已含大量 NUL 字节；提取按 CODEDB_S12_EVIDENCE JSON 对象识别，不将空洞解释为产品故障或日志丢失原因。本文行号仅对应本次读取字节，不能作为活动日志永久地址。

## 1. Lifecycle 序列与异常分型

目标 instance `a492a5e936c14e4da3ed7e4cc7c8c16c` / generation `poc.44`，共 170 条连续 reconcile_completed 记录，序号 1918—2087：158 Ready、12 NeedsAttention。相邻完成计数和开始计数增量均为 1；这是该片段计数一致性，不代表整个运行历史完整。

| 分型 | reconcile 序号 | 当轮 materializer command 计数增量 | 证据解释 |
| --- | --- | --- | --- |
| 首次 Probe 阶段结束 | 1922、1927、1944、1950、1953、1954、2017、2025、2027 | 各 1 | disposition=InitialSupervisorProbeEvaluated，plan=NotEvaluated，四层均 Unknown；尚未走到清理计划选择 |
| Retire 路径后结束 | 1975、2042 | 各 3 | disposition=RetirementSelected，plan=Retire，记录的首次 Probe 四层均 Current；与 initial Probe → Upgrade → final Probe 路径相符，最终 NeedsAttention |
| 阶段字段可能残留 | 1980 | 0 | plan=Retire 且四层 Current，但本轮没有 materializer 调用计数增量；不能认定本轮执行了清理 |

这 12 条在后续序列均恢复 Ready；1953→1954 连续两轮异常，其余下一条就是 Ready。没有每轮 UTC，不能给出恢复秒数。

9 次首 Probe 异常只能定位到首次 Probe 的结果构建、observation 绑定及后续早退区域，不能单凭 Unknown 判定 IPC 超时、Provider 丢失、心跳过期或身份错误。绑定失败通常将 MCP 层置 Blocked；本片段四层 Unknown 不支持把它们直接认定为同一种绑定失败。

2 次 Retire 后异常说明初始层证据为 Current 时，后续流程仍可能最终发布 NeedsAttention。但缺少 final Probe/detail/绑定结果的当轮关联，不能判定具体是 Upgrade、final Probe、绑定，还是既存 terminal failure 的保留逻辑。

## 2. 新发现：诊断阶段字段缺少每轮边界

交付源码 `Editor/AICodedbLifecycleEvidence.cs`：RecordReconcileStarted 只增加计数（约 225 行）；ResetPostAdmissionEvidence 才清空 disposition、四层、current-instance 与 plan（约 339 行）。

`Editor/AICodedbEditorLifecycle.cs`：ResetPostAdmissionEvidence 在 RunReconcileWorker 中段才执行（约 1103 行），此前存在集成/认证等分支。于是早于重置点的结束可能携带上一轮 post-admission 字段。1980 的 Retire + 当轮调用增量 0 与此风险一致，尚不能确定该轮具体早退分支。

另一个计数语义限制：RecordMaterializerCommand 在 Bridge 返回后计数（约 2200 行），不是实际子进程启动计数；增量 3 应称为三次完成到计数点的调用，不能声称启动了三个独立进程。

该发现收紧此前解释：不能只因 plan=Retire 就归因于当轮清理；必须看当轮边界、调用增量和结果。后续诊断契约应给字段标记 epoch/validity，避免跨轮残留。

## 3. Supervisor 有时间序列，但不能与 reconcile 精确连接

当时可读 history 的 201 项中：

- 130 笔 completed Probe，exit 0；
- 64 笔 completed Upgrade，exit 0，全部 COMMAND_RESULT 为 CONVERGED / INSTANCE_CURRENT / cleanup PENDING；
- 3 笔 failed Probe、2 笔 failed Upgrade、1 笔 failed watcher:Stop 为保留的历史记录；
- 1 笔 running Upgrade，为读取时尚未完成，未追读终态。

本集合跨 2026-10-22 至 2026-10-23，轮换保留并不完整。不能计算整体错误率、不能把旧失败匹配到本轮 12 个异常。读取集合内没有 2026-10-23 的 failed operation，但这也不证明该日没有 RPC/读取/绑定失败：请求可能未形成 operation，operation 也可能已被轮换。

Lifecycle 没有每条 UTC、request/operation ID、cache revision 和 observation marker。Supervisor events 有 UTC/sequence/action，但没有 reconcile ID 或 operation ID。operation history 有 request/operation ID 和 observation marker，却缺少 Lifecycle 侧对应值。

因此三条序列无法做精确 join。不得按“第几个 Probe”或接近的文件时间强配：中间存在轮换、其他入口及失败于接纳前的请求。已保留的观察器 operation 可以按精确 ID 独立追踪，但仍不能据此认领某个 reconcile 序号。

## 4. Pending 进展核对的结果与边界

desired-state：INSTALLED / PENDING，state_id=`36e978df0f9f4167bdc37c168c21c99a`，updated_at_utc=`2026-10-22T02:08:32.4244293Z`。本轮字节 SHA-256 与此前记录可比，未取得每次 Upgrade 前后的 desired-state 快照。

removal intent `0efd158a637644e690c0fcae1d5cab15.json` 仍引用旧实例 `fe3b257859f34023a9e290db3b2ad457`。只核对记录归属，未调用生产验证器认证全部保留条件。

64 笔 Upgrade 的聚合结果保持 PENDING、mutated_scopes=[]。这证明对外报告没有收敛至 COMPLETE，不能证明内部没有做任何工作，也不能证明 holder 一直不变。现有历史缺少 per-operation holder/lease 清单、Pending 分支原因和 progress fingerprint，无法核实“每次都没有进展”。不以当前 holder 快照替代历史输入，也不为补证据而触发维护。

pointer 开始/结束逐字节相同，SHA-256 均为 `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`。这只证明提取窗口的选择稳定性，不是整个日志期间的连续身份保证。

## 5. 下一步边界

静态与现有记录已足够确认重复 Pending 调度路径和诊断关联缺口；继续反复读取同类 backend 快照不会补回缺失的历史字段。本轮不再扩展 live 观测。

建议先冻结一个最小诊断契约，暂不改变业务判断：

1. reconcile epoch、UTC、source stage 与字段是否在本轮有效；
2. 命令/RPC 的 request/operation ID（未接纳时允许缺失，保留缺失原因）；
3. 状态发布前后值、reason/detail 的有界脱敏内容、cache revision，以及 observation marker 与 Bridge snapshot 两侧的 ID/revision/age；
4. cleanup 的明确阻塞原因与轻量进展摘要，区分完成状态和重试资格；不新增删除权限或放宽身份认证；
5. Manager action overlay 与 Lifecycle 状态分开记录来源，仅在显示变更时记录实际解析结果。

只有决定性字段补齐并取得一轮有界证据后，才在局部调度修正、RPC/observation 修复或显示来源修正中选择。无需预先重构，也不调整心跳/超时阈值、不 pin 旧 Ready、不改 immutable poc.44。

## 最终判定

阶段分流取得实质进展；唯一根因、精确失败原因、Manager UI 因果和历史 holder 进展仍未建立。重复清理与 NeedsAttention 可能存在共同上游或放大关系，但不能合并成一个已证实根因。未进行 Unity/MCP 功能或发布验收。

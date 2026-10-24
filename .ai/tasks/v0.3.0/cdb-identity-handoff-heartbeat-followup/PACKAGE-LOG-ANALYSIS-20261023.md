# Package 相关日志分析：重复 Retire 与未收敛清理

日期：2026-10-23。状态：REPEATED_RETIREMENT_OBSERVED / UI_CAUSE_OPEN。

## 范围

用户授权检查其他相关日志后，改用实例 ID、project identity、Package 路径、CodeDB 前缀及 operation ID 关联。只读目标工程的 Package 运行态记录、默认 Editor.log 和相关交付源码；初步列举日志/动作记录位置。没有执行产品函数、组件、MCP/RPC、进程探测/控制、安装、恢复或新的观察器。新增本任务记录，不修改目标工程。

默认 Editor.log 每次仅读取打开时已存在的内容，单次上限 16 MiB，未 tail-follow。初步定位、字段核实及后续提取是分次读取，文件有增长，不能把它们视为同一快照。operation history 是活动保留目录，枚举后部分文件被产品轮换删除：本轮未恢复或重读缺失文件，不把该目录当完整历史。

初步日志位置枚举和标识定位覆盖过目标工程本地文件及已知 LocalAppData 日志/动作存储；后续正文核对集中于目标实例与精确 operation 目录。未输出其他工程日志正文、连接凭据或完整命令行。解析命令曾发生 PowerShell 管道语法错误，错误发生于执行前，修正后执行了只读检查；这不是产品重试或产品故障。

## 1. Editor.log 的有效关联

最后一次字段提取从默认日志解析到 60 条 CODEDB_S12_EVIDENCE，全部 selected_instance_id 匹配目标 `a492a5e936c14e4da3ed7e4cc7c8c16c`。较早一次读取为 59 条、起始 reconcile 1918、结束 1976；分次读取不可视为同一快照。首次字面工程名定位零命中并不排除这些记录。

其中 7 条 last_product_state=NeedsAttention，分别为：

| reconcile | convergence plan | 本次提取快照行号 |
| --- | --- | --- |
| 1922 | NotEvaluated | 2605 |
| 1927 | NotEvaluated | 2695 |
| 1944 | NotEvaluated | 3005 |
| 1950 | NotEvaluated | 3114 |
| 1953 | NotEvaluated | 3168 |
| 1954 | NotEvaluated | 3186 |
| 1975 | Retire | 3578 |

其余 53 条为 Ready。存在多条 RetirementSelected/Retire，包括用户贴出的 1919。此为 Lifecycle 产品状态变化证据，不是逐帧 Manager UI 或实际查询响应。行号只对本次活动文件快照有效。未提取并保留日志原文快照，也未取得各条独立 UTC，因此不能和 operation 按秒强行配对。

本次提取未匹配到 `[CODEDB_IPC_DIAGNOSTIC]` 或指定几种 CodeDB warning 前缀；这不排除缓存绑定失败、其他格式错误、未记录详情或其他时段的 timeout。6 次 NotEvaluated 表示在清理计划选择前已结束，不能把所有 NeedsAttention 都归因于 Upgrade 执行失败。

`supervisor_identity_change_count` 和保存 PID 的解释限制继续沿用 USER-LIFECYCLE-EVIDENCE-20261023.md：它们不能证明重启或交接频率。

## 2. 第二次观察中的 Upgrade 终态已找到

来源（相对目标工程）：

`AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor/operation-history/ecce35a6939244fbb8982fd3f84e1282.json`

读取字节 SHA-256：`535acb3e0dbcc050558f71798f83bab5e9b88f0abce2e387b520bab6b185cbb0`。

| 字段 | 值 |
| --- | --- |
| operation_id | ecce35a6939244fbb8982fd3f84e1282 |
| request_id | a3f42358099c4516b0f9f72ee1018834 |
| manager_action_id | 空字符串 |
| owner_epoch | 92f3d48b24b741739d6580bcd507da55 |
| selected instance/generation | a492a5e936c14e4da3ed7e4cc7c8c16c / poc.44 |
| name / state / phase | materialize:Upgrade / completed / completed |
| start UTC | 2026-10-23T02:25:13.816Z |
| completed UTC | 2026-10-23T02:25:25.407Z |
| exit_code / timed_out | 0 / false |
| stderr length / output_overflow / output_drain_incomplete | 0 / false / false |

项目 identity 与既有目标基线匹配。此文件把第二次观察中仍 running 的同一 operation 补到了终态；终态记录不反推运行中任意时刻的查询可用性。

其 stdout 的结构化结果为：

```json
{"schema_version":1,"managed_by":"com.rice.ai-codedb","action":"UPGRADE","outcome":"CONVERGED","phase":"PREFLIGHT","reason_code":"INSTANCE_CURRENT","mutated_scopes":[],"cleanup_state":"PENDING","next_action":"No action is required; the retired instance will be cleaned after authenticated holders drain.","exit_code":0,"detail":""}
```

**解释修正：** next_action 是通用产品提示，不能当作“已证明旧进程存活”的诊断结果。Get-CombinedInstanceCleanupState 存在多个 Pending 来源。

manager_action_id 为空支持非 Manager action 的调用路径线索，但没有高层调用入口 ID，不能独立证明是哪一处源码调用；结合 Lifecycle Retire 序列及事件模式后，自动历史清理成为优先候选。

## 3. 重复执行有独立事件证据

目标 Supervisor 的 supervisor-events.jsonl 中，在 UTC 02:23—02:27 窗口多次出现 Probe → Upgrade → Probe。该窗口 Upgrade 开始/完成如下：

| 开始 UTC（2026-10-23） | 完成 UTC |
| --- | --- |
| 02:23:39.968 | 02:23:49.283 |
| 02:24:14.950 | 02:24:25.070 |
| 02:24:41.454 | 02:24:52.966 |
| 02:25:13.841 | 02:25:25.572 |
| 02:26:16.212 | 02:26:24.816 |
| 02:26:42.565 | 02:26:51.146 |

事件日志 detail 只有 action 名、没有 operation ID；第二节终态按精确 ID 归属，不能只靠接近时间混合其他 operation。事件 timestamp 与 operation 自身字段略有差异，保留原值。这里只证明重复操作，不作性能/SLA 结论。

活动 history 提取还读到 42 笔目标实例 Upgrade 为 completed、exit 0、INSTANCE_CURRENT、cleanup PENDING。这是当时可读记录集合，目录轮换后不完整，没有全量成功率/失败率意义。

## 4. Pending 存在不依赖 holder 存活的保留条件

只读目标 control/desired-state.json：desired_state=INSTALLED、cleanup_state=PENDING、updated_at_utc=2026-10-22T02:08:32.4244293Z。它是读取时记录，不能代替每次 reconcile 的输入。

目标 control/removal-intents/0efd158a637644e690c0fcae1d5cab15.json 存在，project identity 匹配目标，retained_instance_id 指向旧实例 `fe3b257859f34023a9e290db3b2ad457`；该旧实例目录也存在。目标 v2 activation operation 文件 phase=COMMITTED，retirement_intent_path/sha256=null；未将这些字段升级为本轮完整契约认证。

交付 Package 源码（本轮仅读取，未加载/运行）：

- `Editor/AICodedbEditorLifecycle.cs:2412`：Current + Ready + cleanup Pending → Retire。
- 同文件 1394：Retire → materialize/Upgrade → Probe 重新观察。
- `Tools~/codedb-instance-engine.ps1:5310`：当前实例 Ready 的 Upgrade 进行组合清理；清理仍 Pending 时也可返回 exit 0 / CONVERGED / INSTANCE_CURRENT。
- 同文件 4584：组合清理含 versioned retirement、普通 instance cleanup、legacy cleanup，任一可返回 Pending。
- 同文件 4459—4477：Get-InstanceCleanupState 先读取 removal intents；旧实例被这些记录引用时设置 Pending 并跳过删除，之后才检查普通实例 holder。

因此存在一条能解释重复维护的具体候选链：旧实例被保留 → cleanup 长期 Pending → Ready 的自动 reconcile 继续选择 Retire → Upgrade 成功但 Pending 不变 → 下一轮再选 Retire。该保留机制有明确删除权限边界，不能通过删除 intent、旧实例或杀进程来试探。

本轮只读取 intent 关键字段及代码，没有调用完整生产验证器，因此不声称唯一 Pending 根因已通过运行时分支证据证明。即使 intent 无法通过校验，源码也有 catch 后返回 Pending 的路径；需要区分“有效保留”和“认证失败保留”。

## 5. 其他历史错误单列

历史目标实例 operation stderr 中还保存：

- 2026-10-22T09:51:02.969Z，Probe `aced7ec5f2ae426b826a66541a7f2b03`：Timed out after 30000 ms waiting for coordinator readiness。
- 2026-10-22T13:25:10.090Z，Upgrade `b5e149618d7444abb193b3ef6a325963`：EDITOR_OFFLINE，无有效 interactive Editor lease。
- 2026-10-22T13:25:11.915Z，Probe `3d964e5ddbd8443d98e69f3c0754b361`：相同 EDITOR_OFFLINE。

没有同一时刻的人工作业/关闭/编译/lease 证据，不能将这两笔 OFFLINE 判为 idle 心跳 bug，或把 readiness 30 秒超时与已知 IPC 约 1.5 秒 read timeout 混为同一故障。

## 当前结论与下一步

已确认：目标 Lifecycle 状态有 Ready/NeedsAttention 变化；自动历史清理重复选择有实证；指定 Upgrade 成功结束但 Pending 未收敛。未确认：各次 NeedsAttention 的 detail/attention reason、observation/cache 配对及 UI 文案、Unconfirmed 因果、清理 Pending 的唯一生产分支和实际 holder 状态。

下一步优先对齐“保留 cleanup Pending 与自动重复清理之间如何调度、为什么 NeedsAttention 的原因未被持久化”的最小排查/修复边界。先区分合法保留状态与真实故障，不降低身份认证、lease 或删除权限门槛，不重构状态机。需要新增诊断时只补决定性字段，避免继续重复后端状态观察。

本轮不宣称所有反馈同根或发布验收关闭，不自动修复、清理、杀进程、重试 Install，也无需关闭 Unity。

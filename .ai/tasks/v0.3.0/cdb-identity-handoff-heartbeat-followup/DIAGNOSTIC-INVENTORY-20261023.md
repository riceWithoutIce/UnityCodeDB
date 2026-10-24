# 状态波动：已有诊断能力与证据缺口

日期：2026-10-23。状态：READ_ONLY_INVENTORY_COMPLETE / ROOT_CAUSE_OPEN。

## 范围与版本

本轮只读核对已有源码、任务记录和已保留的三份磁盘采集产物；没有读取目标工程当前运行态、Unity 原生日志或用户级动作存储，也没有执行观察器、MCP/RPC、进程探测、测试或产品命令。只新增本任务文档。

以既有交付记录中的 `61dcd26383c42766763eca2b885b159725b2f7dc` 为源码参照，不声明当前消费工程已重新核验。本轮比较的 Lifecycle、LifecycleEvidence、ManagerWindow、ManagerActionJournal、HostPayloadMaterializer 五个 Editor 文件与该提交无 diff；Paths 仅作为当前源码的存储定位参考。主检出 Supervisor 与该提交存在差异，因此 Supervisor 的 operation 生产/持久化能力改按该提交的 `git show` 核实，不能用主检出行号冒充交付版本。

## 现有能力

| 来源 | 已有内容 | 对本问题的限制 |
| --- | --- | --- |
| Lifecycle `CODEDB_S12_EVIDENCE` | reconcile 计数、最近 product state、Manager 刷新成功/失败计数、post-admission disposition、convergence plan、实例/代际及进程标识；检查点写 SessionState 并 Debug.Log | 文档没有每条事件独立 UTC、配对 observation revision/age、Manager 最终文案/覆盖原因或失败详情；计数不等于异常时间线 |
| Lifecycle 内存 cache | product status/detail、command result、Supervisor snapshot、cache revision；Ready 另受显示 freshness 边界约束 | 现有磁盘观察器无法读取该内存快照；不能通过新一次 RPC 来替代当时缓存 |
| retained terminal failure | 某些认证终态失败可序列化 reason、detail、diagnostic、observation/revision 等到 SessionState | 仅覆盖满足条件的终态失败；不能保证记录普通 Starting、过期显示或动作 Unconfirmed |
| Manager action journal / stage receipts | 项目/Package 绑定、action/stage 标识、admitted/terminal/start-failure 等阶段证据 | 非连续 UI 日志；自动 Lifecycle reconcile 不保证有 Manager action；本轮未扫描实际用户级存储 |
| Supervisor operation（交付提交） | operation_id、request_id、manager_action_id、name、state/phase、execution disposition、起止时间及终态结果等；有 operation 持久化路径 | 字段存在不代表调用入口已归属；current operation 会变化，动作历史保留也有边界 |
| IPC timeout diagnostic | timeout 时在异常首行追加 command/action、request/operation ID、connect/write/read 阶段、UTC/耗时及接收字节数 | 成功不记录；ID 不证明服务端接收；不能独自说明服务端为何未响应 |
| 已保留磁盘采集 | Supervisor、Coordinator、operation、lease、pointer 的白名单快照 | 未采 UI/cache/action session；两次 event 回执 operation 白名单未包括 request_id、manager_action_id，缺失不代表原值为空 |

源码定位（均相对 Package 根；Supervisor 行号为交付提交）：

- `Editor/AICodedbLifecycleEvidence.cs:64,843,1028`。
- `Editor/AICodedbEditorLifecycle.cs:2298,3310,3486,3545,5195`。
- `Editor/AICodedbManagerWindow.cs:3571`。
- `Editor/AICodedbPaths.cs:301,405`。
- `Tools~/codedb-project-supervisor.mjs:1500,2186,2271`（交付提交）。
- 本任务 `observe-transition-once.mjs:165`。

## Upgrade 的静态候选入口

1. Manager 的 Host Payload Upgrade 动作：Manager → Actions → HostPayloadMaterializer。
2. Lifecycle 自动卸载残留清理：integration 已 Uninstalled 且 cleanup Pending 时发送 materialize/Upgrade。
3. Lifecycle 当前实例收敛：Retire 或 Deploy 分支发送同名 Upgrade。
   - Ready 且 cleanup Pending 可进入 Retire。
   - Missing 可进入 Deploy；Current 在 prerequisite Current、installed/configured 尚未 Current 的组合下也可进入 Deploy。
   - installed/configured 均 Current 而 MCP Unavailable/Pending 时另走 RecoverAvailability，不能把所有暂态都称为部署升级。

对应 `AICodedbEditorLifecycle.cs:1213,1394,1424,2412`；人工入口见 `AICodedbActions.cs:86`、`AICodedbManagerWindow.cs:1700`。

这解释了为何名为 Upgrade 的 operation 不一定意味着用户手动升级，也不证明 generation 或 pointer 必然切换。本轮没有本次调用前的产品层结果、cleanup state、配对动作标识及 operation 终态，不能从候选入口中选定实际入口。

第二次回执保存的 operation 为 `ecce35a6939244fbb8982fd3f84e1282`，起始 UTC `2026-10-23T02:25:13.816Z`，采样时 running/materializer_admitted/CHILD_ADMITTED。触发来源、完成状态与重复频率仍 UNKNOWN。

## 已有实证与未闭合项

`IPC-COMPILE-REPAIR-HUMAN-REOPEN-RESULT.md` 已记录一次修复 Package 重开后的人工现场：无编译错误，Needs attention，诊断可见 read_ms 约 1502.430、received_bytes=0，几分钟后自然 Ready。此为已观察到的客户端 read timeout 及恢复，服务端原因未知，不能推广为全部 idle 波动的根因。

历史 S41 STARTING 查询、后续发现并修复的启动形态/readiness 契约差异，和当前 UI/确认/心跳诊断应保留各自证据边界。本次没有回放历史失败，也没有证明新的 idle 波动再次出现相同后端形态。

两次 event observation 的 maintenance 与 operational core_ready 并存仍成立；没有同步 UI/cache，不能建立 maintenance → Manager Starting 的直接因果。

## 推荐后续顺序

1. 先对齐一次已有原生日志与动作记录的有界提取：仅确认归属 CodedbTest_2 的日志文件/会话，按上面已知 operation 时间及已记录的 timeout 窗口筛选 CodeDB 前缀和相关 ID。固定文件、窗口、字节预算；不读全局历史、不跟踪新增、不执行恢复或查询。无法归属则停止，不用其他 Unity 实例日志替代。
2. 看已有记录能否关联 reconcile checkpoint/disposition、IPC command/operation ID、operation 终态及动作回执。原生日志若无每条 UTC，只保留顺序和明确时间字段，不强行拼接同一时刻。
3. 若仍缺缓存/显示原因，再提出最小事件关联诊断：product state/attention reason、cache revision、operational observation ID/revision/age、action phase、显示判定原因及 UTC。方案另行对齐；不要求人工抓瞬间，不直接启动 UI 注入或读取进程内存。

本轮没有执行上述下一阶段提取或新增采集。无需关闭 CodedbTest_2；不改产品代码、注册、心跳、时序或 immutable generation，不做重构。当前结论是已定位证据缺口及一个真实 timeout 线索，根因尚未闭合。

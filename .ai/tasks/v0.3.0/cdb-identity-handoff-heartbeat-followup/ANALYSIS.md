# 状态、身份交接与心跳：第一轮只读汇总

日期：2026-10-22。状态：STATIC_MAPPING_COMPLETE / INCIDENT_CAUSES_PARTIAL。
本轮覆盖已汇总反馈，不实施重构或修复，不启动新实测。

## 结论边界

这些反馈值得一起排查，但目前不能合并为一个“心跳故障”。已确认的现象分别
落在命令完成后的状态确认、子进程身份准入、查询就绪检查，以及 Editor lease
生产/消费链路。静态代码能指出具体分支与衔接疑点，不能重建未采集的现场。

本轮读到的 ManagerWindow、ActivityPanel、StatusSnapshot、EditorLifecycle、
SupervisorBridge、Supervisor 及三份相关测试文件，Git blob 均与已交付
`186aacf0371ba64e47114306170b449dbca261c9` 对应文件一致。S41 静态映射已核对
poc.44 worker/coordinator；该映射用于本轮直接引用。主工作区整体仍有其他
未验收 WIP，未将其当成交付候选，未读取或激活其 writer-lifetime 行为。

历史 CodedbTest_1 的 Unconfirmed 来自较早的 237c72d / poc.43，不把当前
候选的实现直接当作该历史事件已证明的根因。S36/S37 记录只用于辨别既往修复
与当前证据，不把旧版同步阻塞结论重新宣称为当前未修复问题。

## 反馈清单与排除结果

| 反馈 | 已有证据 | 当前能排除或限定的解释 | 仍缺什么 |
| --- | --- | --- | --- |
| Ready → Unconfirmed → Ready | CodedbTest_1 人工报告及中间截图；文字为 `CodeDB status unconfirmed`、`Completed - checking status`；当时 Host STARTING、MCP Pending | 截图表示命令完成后状态尚未确认，不能据此断言进程死亡、心跳超时或查询失败；恢复时长/频率没有时间线 | 当时的命令结果、配对 operational observation、缓存时间及 UI override 的同步数据 |
| 重开后 Needs attention，约一分钟恢复 | S40 实际 Probe exit 1，`CHILD_ADMITTED` 且 child=null；明确 unresolved identity 错误；后续另一个 owner epoch 下 Ready | 不是仅有 UI 文案；存在真实操作失败。后续 Ready 不抹去原失败。也不能据此证明原子进程仍存活 | 第一段 child 的退出/捕获顺序及与下一次 admission 的关联证据 |
| Ready 起点后 S41 查询 STARTING | 目标真实调用 error，provider_attempts=0、provider_route=none；pointer/旧样本稳定 | 不是 NO HIT、索引旧内容或 Provider 搜索失败。wrapper 本次 lifecycle 判定 editorOnline=true；不支持“该次 wrapper 已将全部 Editor lease 判失效”的直接解释 | 同时刻 coordinator state 的安全字段、具体未通过的 readiness 条件及 Manager observation 时间 |
| 心跳、存活与身份交接疑虑 | 源码存在定期 lease 发布、过期规则、进程起始身份消费；曾保留旧 MCP 记录 | lease 文件残留不等于活进程；缺正式响应身份不等于心跳故障。当前无足够心跳时间序列证明生产或消费错误 | 有界的时间/身份/阶段关联，区分生产停顿、消费者拒绝、正常边界与误判 |

证据来源：同目录 TASK 的 S39/S40 链接，以及
`../cdb-v0.3-p0-s41-code-change-query-freshness/RESULT.md`。
用户泛称的 not confirmed 暂以现有证据中确切的 Unconfirmed 文案登记，不猜测
另有一个同名状态码。

## 四条不同的判定链

### 1. Manager 状态与命令结果

`Editor/AICodedbActivityPanel.cs:685-739` 将命令是否完成、完成后产品状态及
状态是否已刷新分别表达。默认完成态可以显示 `Completed - checking status`。
`Editor/AICodedbManagerWindow.cs:3478-3511` 的 action override 可将顶栏显示为
`CodeDB status unconfirmed`。因此 Unconfirmed 有明确的结果确认语义，不是
专门的心跳错误码，也不保证只是显示问题。

`AICodedbManagerWindow.cs:743-801,3571-3629` 从 lifecycle 配对缓存显示 Ready，
对 Ready operational observation 使用 30 秒显示新鲜度门槛；过期会撤下 Ready。
它不会为了绘制 UI 发起一次实时查询。Play 期间保留旧 Ready 的文案另有边界。
`AICodedbEditorLifecycle.cs:3545` 将命令中的 operational marker 与对应
Supervisor observation 绑定，不能随意用较新的 Bridge snapshot 补旧结果。

所以 Manager Ready 表示一个受身份/时间约束的已验证缓存，不是未来查询可用的
实时保证。30 秒不是 Editor lease 的 90 秒过期时间，更不是索引 freshness SLA。
S41 没有同时刻 UI/缓存记录，不能判定是否存在超龄显示或错误绑定。

### 2. Supervisor operational readiness 与查询 admission

`Tools~/codedb-project-supervisor.mjs:1831-1929` 根据 authenticated coordinator
状态生成带 observation_id/revision/time 的 operational readiness。
`requestCoordinatorStatus:2560` 通过现有认证 IPC 取状态；这与 wrapper 查询入口
直接读取 coordinator-state 的流程不同，采样时刻和判定条件也不同。

`Payload~/Generations/poc.44/wrapper/codedb-project-instance-worker.mjs:1575`
先解析 lifecycle，再调用 `getReadyWatchCoordinatorState:1756`。后者检查：

- coordinator 文件存在、可解析及 schema；
- Provider ready，desired enabled，Editor demand online、session count > 0；
- adapter 启用、状态在允许集合，worker ready；
- root、Provider/config/runtime/adapter 路径与 generation 匹配；
- coordinator/Provider/worker 的进程存在性等条件。

任一不满足即可返回 null。`createLifecycleUnavailableError:1993` 仅区分
disabled、Editor offline，剩余情况合并为 STARTING。这包括状态缺失、旧快照、
组件异常、路径/代际不匹配等；因此 STARTING 不证明只是正常启动等待。
policy 若解析为 unknown、Editor 仍在线，也可能落入该通用消息；消息中的
“enabled”不能单独替代已读取的 policy 事实。

S41 的确切 STARTING 分支意味着该次 lifecycle 判定 Editor 在线、desired
不是 disabled，但不能从错误文本确定所有其他条件。wrapper 与 coordinator
各自采样 lease，可能存在先后差异；尚无现场证明该差异实际发生。

### 3. Editor lease 心跳生产与消费

`Editor/AICodedbEditorLifecycle.cs:21,420-470` 的常规 heartbeat 回调间隔为
5 秒；后台 lease worker 执行写入。`ShouldRefreshEditorLease:3958` 不因
reconcileInFlight 本身阻止 lease 更新，已有单元测试对此作了断言。
Domain Reload 前的代码仅失效 Unity 侧等待/调度，不直接停止外部 Supervisor；
reload 后重新解析本 Editor session 的 lease 路径。

值得保留的静态线索：`OnEditorUpdate` 在 compile/asset-update 等维护暂停时
提前 return；其中只在 Play transition 情况显式 QueueLeaseRefresh。因此源码
没有证明所有长时间 compile/asset-update 场景仍持续按 5 秒刷新。已有队列是否
完成、实际暂停多久、lease 年龄是否跨阈值均未知，不能先认定为事件根因。

coordinator 每 2 秒扫描 lease，使用 90 秒过期、30 秒未来时钟容差，并检查
PID/start ticks。无有效 Editor lease 时可停止其后端。wrapper 的消费也检查
90 秒 lease 年龄，较新 lease 的进程起始身份查询策略与 coordinator 不完全
相同。记录这些差异是为了定位采样边界，不把不同策略直接定为缺陷或要求统一。

相关入口：worker `readActiveEditorSessionIds:1865`、coordinator
`inspectEditorLeases:278` 与 `scanEditorDemand:1280`。未运行这些方法，也未采集
当前 lease。S41 保存至调用约 24.689 秒本身不足以证明/否定 90 秒阈值曾被跨越，
因为没有保存前最后一次 heartbeat 的时间；但当次 wrapper 仍判定 Editor 在线。

### 4. 子进程身份交接

与 heartbeat/Manager 缓存独立的高优先级线索：

1. `Tools~/codedb-project-supervisor.mjs:1619` 的 Probe/Upgrade 在同一 operation
   里先 ensureCoordinatorWithAttribution，再 runMaterializer，可能依次创建两个 child。
2. `queueChildEvidenceCapture:2489` 在确认 ChildProcess 已退出且进程查询返回
   exists=false 时，允许正常返回，持久化 `child_exited_before_identity_capture`；
   此时 operation 仍可为 CHILD_ADMITTED / child=null。
3. `runChild:3096` 等待该 capture promise 后可按实际 close code 返回成功。
4. 下一次 `prepareOperationChildEvidence:2464` 遇到 CHILD_ADMITTED / child=null
   无条件拒绝，未消费上一段已观察退出的事实。

这是明确的生产/消费衔接疑点；不能通过删除 child/null 防线或假定无进程就成功
来修复。它能解释一种与已记录 Needs attention 相符的路径，但尚未证明那次
Probe 正是从此路径到达拒绝。已有 s32 fixture 检查未知/活 child 的拒绝、已识别
child 退出后允许下一次 admission；读到的场景没有建立“第一 child 短命未捕获、
同一 Probe 继续第二 child”的完整行为证据。本轮只读测试源码，未执行 fixture。

## 优先级与最小下一步

按用户可见影响与现有证据排序，不把所有条目定为 BLOCKER：

1. **查询实际不可用与 UI/backend 状态关联**：先区分 S41 STARTING 的具体条件。
2. **真实 Probe 子进程准入失败**：明确短命 child 的退出事实能否安全交接；保持
   unknown/live/crash 后缺证据时的拒绝，不触碰未验收 writer-lifetime WIP。
3. **心跳在 compile/reload/Play 的连续性**：在明确时间线后判断是否需要修复。
4. **Unconfirmed 的显示/确认时序**：后端原因与缓存时间确定后，再判断提示是否
   正常或存在反复失去确认，避免用隐藏 Warning 掩盖实际不可用。

下一观测方案建议（尚未授权/执行）：一个人工自然发生的异常窗口、单次读取
既有记录的安全字段。不为制造异常保存新 C#、重开 Unity、重连客户端或重试查询。

- 人工记录当时 Manager 文案、是否 compile/update/Play 及观察时间。
- 读取 selected identity；Editor lease 的 session/PID/start identity 与
  heartbeat timestamp；读取时记录 UTC，可得 age，必要时另行批准定点时间序列。
- coordinator 仅提取时间、lifecycle/generation、组件 state/PID、desired/demand、
  session count、last lease scan、last event/error；将路径比较投影为布尔值，
  不输出 token、pipe 全名或完整原始状态。
- Supervisor 仅提取 operational state/reason/observation time/revision、owner epoch、
  current operation id/phase/disposition 和 child 身份是否存在，不 dump raw state。
- 这些文件并非原子快照，记录各读取时间并复核 pointer；事后读取只能证明采样
  时的状态，不能冒充 S41 在 03:10:35Z 的现场或宣称“没复现所以不存在”。
- 本轮不假定已有日志保留了足够时间线。若缺少区分条件，先说明缺口，再对齐
  最小日志或定点观测，不先建新日志系统或放宽阈值。

## 本轮完成与边界

产品、配置、测试工程、运行态均未改动；S41 A 样本保留。未运行测试、MCP、
进程/lease/实时日志扫描、Unity 或自动化；未委派、提交、导出或清理。
改变的仅是任务激活记录、本文，以及早期 Unconfirmed 记录的交叉引用。
未修改或重标既往 S40/S39 PASS，也未形成重构、修复或发布批准。

Current task: cdb-identity-handoff-heartbeat-followup.
Current status: PARTIAL / STATIC_MAPPING_COMPLETE; incident root causes remain partial.
Next notification: user / current development session.
Next action: align the smallest safe live-evidence window or focused child-handoff
verification; neither is active. S41 remains stopped.
Human decision or authorization required: YES for live collection, reproduction,
tests, product changes or cleanup; no repeated approval needed for completed static work.

# 最小修复方案：启动形态与查询就绪一致

日期：2026-10-22。状态：ALIGNMENT_COMPLETE / PRODUCT_IMPLEMENTATION_NOT_STARTED。
用户同意继续对齐最小修复方案；本文件不自动授权产品编辑、测试、交付或现场恢复。

## 单一目标

自动启动、重开后的恢复和已有显式 watch 路线，必须建立同一受支持的完整查询
服务形态。Supervisor 发布的 operational Ready 必须满足该形态下 wrapper 的
现有准入条件；不要求 UI、IPC 和查询在不同采样时刻总是给出相同状态。

不调整心跳间隔/过期阈值，不改变 MCP 注册或初始化时序，不删除 wrapper 校验，
不把当前问题扩为整个 Supervisor 重构。原 Unconfirmed、短命 child 交接和
compile/update 心跳连续性继续分别保留，不能宣称此修复包办全部反馈。

## 冻结的行为要求

1. **完整启动参数。** Supervisor 从选中实例/代际派生 watch config、adapter
   builder/worker、manifest 和 debounce，并遵循现有 watch 路线的参数语义。
   watch config 缺失时不能悄悄使用正式的 watch-disabled config；由既有准备/
   materialization 路线负责生成，不在 Supervisor 另建一套配置写入逻辑。
   不改变正式配置本身。所有路径组合推导，不写死绝对机器路径。
2. **兼容才复用。** 不能仅凭 provider_state=ready 返回 attached。核对与这次
   服务形态直接相关的选中身份、生命周期边界、配置及 adapter 参数；复用现有
   coordinator 的 context-matching 语义，避免另加与本问题无关的校验矩阵。
   兼容且处于正常 pending/building 的服务不应因这项修复重复启动或被停掉。
3. **Ready 的单向保证。** adapter disabled、worker 缺失或相关配置/代际不匹配
   时，不能继续发布该项目完整服务的 operational Ready。保留 failure 与
   maintenance 的区别及已有 observation 身份/时间契约；不伪造新时间戳为
   旧 Ready 续命。不要求把所有内部状态转换成一个通用布尔值。
4. **明确不兼容状态。** 已运行但不兼容的后端，不能错误 attached，也不能无
   限当作正常 STARTING 等待。复用已有明确错误/诊断类别能表达时不新建协议；
   如表达不足，仅提出最小必要契约变更和消费闭包，不擅改 schema。
5. **现场恢复分开。** 此阶段默认不增加自动重启/杀进程机制。不兼容后端的
   停止必须经现有认证 owner、expected lifecycle 与 Package 权限路线；无法
   证明 ownership 时拒绝操作。源修复不等于现有 CodedbTest_2 已被恢复。
   交付前明确一次受控的人工作业/既有恢复入口，不要求用户手改 JSON/删状态，
   不把重装作为默认补救。若现有入口无法安全完成，返回一个具体恢复决策。

## 实现与消费闭包建议

第一落点是 `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`：
context 路径派生、ensureCoordinator 的启动/复用、operational readiness 生产者。
这些行为要一起修复，避免只修 UI 或只追加 CLI 参数。

直接读取/验证：

- poc.44 coordinator 的参数解析、launch-ready 和 context-matching；
- poc.44 watch manager 的完整启动参数；
- poc.44 instance worker 的 query readiness；
- SupervisorBridge/EditorLifecycle/Manager 的 operational observation 消费；
- Package materializer 对 Supervisor 启动参数和 operational marker 的消费。

不预先修改 Bridge 的通用 adapter-disabled 支持，也不改 immutable poc.44 来
迎合错误后端。若只需修复 Package-side Supervisor，保持 runtime 协议与代际
不变；若必要变更触及已冻结代际，按既有 successor-generation 权威流程另行
闭合，不能原地改 poc.44 或绕过版本/manifest gate。

开始实现前，将实际直接消费者与必要测试路径收敛到一个任务 allowlist；保留
主工作区 dirty state，在 `<repository-root>/.worktrees/` 内隔离实施。不能拿
整个主工作区当作已验收 186aacf，不能带入 ProcessRunner 等 writer-lifetime WIP。
当前没有新的 worktree、分支、子 agent 或执行任务被创建。

## 最小定向证据

优先复用 `Tests~/test-codedb-project-supervisor.mjs`，为同一契约增加一个可单独
选择的 focused scenario，而不是运行默认全套。现有 mock 把 adapter-disabled
作为完整服务正常值时只修直接耦合断言，不放松实际生产消费者。

| 场景 | 必须证明 |
| --- | --- |
| 无 coordinator 的自动启动 | 实际生产参数包含 watch config 和完整 adapter 参数，路径来自选中实例/代际；不是只查字符串存在 |
| 兼容服务复用 | 正确返回 attached，不重复 spawn；正常 pending/building 不被误停 |
| 已运行的不兼容服务 | 不返回 attached/Ready，不启动第二 owner、不误停其他进程，输出可识别失败 |
| Ready 生产/消费 | 用相同组件/配置事实对照 Supervisor operational decision 与 wrapper 实际 predicate，禁用或缺失组件不能形成 Ready 后被固定契约拒绝 |
| 邻接回归 | 保留 admission attribution、超时分类、unknown/live child 拒绝；不趁机修历史 child 交接 |

现有 coordinator-readmission filter 同时执行其他恢复场景，不能不加分析就宣称
它是本次最小集合。实际实现改动触及它时，仅纳入直接受影响成员。
上述证据是隔离源行为证据，不能替代真实 Unity、Provider 或 MCP。

源实现和 focused 证据稳定后，才对齐单次交付/现场恢复及真实客户端验收：确认
完整服务形态，再执行有界查询。S41 A 已存在，必须另冻结恢复方案，不能直接
重放要求样本不存在的原 TASK。暂不增加保存/重开循环或完整 freshness 矩阵。

## 完成和停止边界

此次方案对齐完成。后续实现遇到必须改运行协议、接管/停止未知进程、增加自动
恢复机制、激活历史 WIP，或原 child 交接 blocker 阻止既定路径时，先返回具体
冲突与最小必要扩展，不在当前目标里连带重构。缺证据不自动升级为全面审计。

Current task: cdb-identity-handoff-heartbeat-followup.
Current status: REPAIR_PLAN_ALIGNED / IMPLEMENTATION_NOT_STARTED.
Next notification: user / current development session.
Next action: freeze implementation task, narrow file/test envelope and safe
consumer recovery boundary before product edits. No runtime action active.
Human authorization required: product implementation/tests and later exact
delivery/consumer operation retain their explicit gates; current approval
covers this completed diagnosis/plan, not deployment or publication.

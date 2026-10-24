# 单次只读采集：就绪契约差异已观察

日期：2026-10-22。状态：COMPLETE / CURRENT_SNAPSHOT_ONLY。
单次采集预算已消耗，不重读、不查询验证、不等待恢复。

## 来源与边界

用户同意有界只读采集后，开发会话执行 collect-state-once.mjs 一次。
仅读取 CodedbTest_2 既有磁盘状态；无 MCP/RPC、进程探测、日志搜索、等待或轮询。
采集时无新的人工 UI/compile/update/Play 状态确认，所以结果是当前状态快照，
不是一次新确认的 UI 异常现场，更不是 S41 03:10:35Z 的失败现场。

原始 JSON 未写出。保存文件只有白名单字段、读取时间和源文件哈希；不包含
连接 token、pipe 名、命令行或自由文本输出/error。不会修改目标工程运行态。
采集器先验证选中实例与任务基线，再读取同一实例的记录。源文件读取不是原子
事务；pointer 首尾字节稳定只能确认本轮绑定未变，不能证明每一状态同时成立。

证据：
`.artifacts/tests/identity-handoff-heartbeat/current-snapshot-2026-10-22T03-34-05-725Z-fee320/snapshot.json`。
保存的 capture window 为 `2026-10-22T03:34:05.725Z` 至 `03:34:05.739Z`。
现有字段键名预检另做过读取；只有本次正文采集构成完整快照，没有额外快照循环。

## 观察事实

| 项目 | 本轮值 | 限制 |
| --- | --- | --- |
| selected pointer | 与 S41 相同，SHA-256 `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a` 首尾稳定 | 不是查询响应身份 |
| Editor lease | 一个，heartbeat `03:34:05.6200632Z`，采读时 age 约 114ms | 没有独立探测 PID 存活/起始身份 |
| coordinator demand | enabled / online / session count 1，lease scan age 约 74ms | 磁盘记录，不是新认证 IPC |
| Provider | ready | 不等于 wrapper 查询就绪 |
| adapter | enabled=false、state=disabled、worker=disabled、worker PID=null | 确定不满足 wrapper 的 adapter 条件 |
| coordinator 路径比较 | root/runtime 匹配；provider_config 不等于 watch 配置，adapter_manifest 不等于预期 manifest | 未输出原始路径；未验证所有其他路径 |
| Supervisor operational observation | core_ready / COORDINATOR_OPERATIONAL，时间 `03:34:05.678Z`，age 约 62ms | 顶层状态另为 maintenance，二者语义不同 |
| 当前 operation | materialize:Probe / running / materializer_admitted；CHILD_ADMITTED、child=null | 运行中尚未捕获身份可能是正常瞬间，不认定为第二次失败 |

instance 仍为 `a492a5e936c14e4da3ed7e4cc7c8c16c`、epoch
`063aa347f49a4b9f955a5447f293a0ac`、poc.44 / 0.3.0-preview.5。
coordinator 记录的 started_at 为 `03:12:02.436Z`，晚于 S41 失败时刻；所以本轮
coordinator 不能冒充当时同一执行实例。没有记录新的实际查询响应。

## 静态因果对应：确定存在两套不一致的启动/就绪要求

源代码与本轮状态形成具体对应，不依赖假设所有心跳失效：

1. `Tools~/codedb-project-supervisor.mjs:255` 的 Provider config 派生为
   实例 `config/codedb-mcp.toml`，不是 `codedb-mcp.watch.toml`。
2. `ensureCoordinator:1931` 的直接启动参数传该 config，不传 adapter builder、
   worker、manifest 或 debounce。现有 coordinator 若 provider ready 就先复用，
   没有在此分支证明它满足完整 wrapper 服务形态。
3. poc.44 coordinator `parseContext:137` 以 adapter-builder 是否提供决定
   adapterEnabled；未提供时 adapter/worker 为 disabled。
4. Supervisor `resolveOperationalReadiness:1874` 未将 disabled 当作失败或 starting，
   Provider ready 时可返回 core_ready。Bridge 也支持 adapter-disabled 的 Ready。
5. poc.44 wrapper `getReadyWatchCoordinatorState:1756` 却要求 adapter_enabled=true、
   worker ready，并要求 watch config/adapter manifest 等路径匹配；不满足时拒绝
   查询，剩余条件合并为 STARTING。
6. 同一代际的现有 `manage-codedb-project-watch.ps1:548-575` 启动路线明确传入
   watch config 和完整 adapter 参数，说明当前至少有两种不同服务形态的入口。

因此确认：**Supervisor 可认可一种不满足 MCP wrapper 既有准入条件的后端形态；
本次磁盘快照恰好观察到这种形态。** 它足以解释一种 Ready/STARTING 不一致机制，
但没有新调用，不宣称刚刚复现了查询失败；也未证明它就是 S41 或历史 Unconfirmed
的完整原因。该契约差异比增加心跳容差或单纯隐藏 UI 提示更应优先处理。

## 下一阶段最小修复方向，尚未实施

建议先冻结“自动启动、重开/重连后的恢复、显式 watch 启动必须建立同一受支持
查询服务形态”的小范围契约；将 Provider config、adapter 参数与 readiness 的
对应关系对齐。复用已有选中实例/代际的路径派生与启动约定，不写死机器路径，
不增加新注册流程，不主动停止未知/外部进程，不将适配器缺失静默视作正常查询。

不能仅为通过 C# 样本删除 wrapper 的既有校验，或仅把 Supervisor Ready 改成
Starting 后无限等待：需要启动形态与认可形态一致。已运行且不兼容的后端如何
安全处置，应在修复契约中明确，不能自动杀进程或重装作为捷径。

后续针对性证据应覆盖自动 cold-start 参数、兼容后端复用/不兼容状态处理、
两端 readiness 对同一组件状态的判断，以及有界真实客户端查询。源修复、隔离
测试、交付、人工 Unity 和真实客户端验收分开记账；本轮不自动启动这些阶段。

历史子进程交接、compile/update 心跳连续性、Unconfirmed 确认时序继续保留为
独立问题；新差异不构成“其余反馈全部解决”。S41 A 样本与原失败不变，不重放。

## Retention 与交接

- 生成证据：PROTECTED，owner 为本任务，用于解释未解决的就绪契约差异。
  下一 review milestone 为最小修复验收及历史问题处置；不覆盖或自动删除。
- 改动仅为本任务记录、采集脚本及 task-owned sanitized artifact。
- Current status: PARTIAL / READ_ONLY_CAUSE_MAPPING_COMPLETE。
- Next notification: human / current development session。
- Next action: 对齐上述最小修复契约；不再增加实时采样或查询。
- Human authorization required: YES for product changes/tests/delivery/runtime action。

# VERIFICATION-01: S13 Coordinator Startup Recovery Lifecycle

## Verdict

- 结论：`FAIL`
- 模式：`GUARDED` 定向只读验收
- Findings：`1` 项 `P1`；无 `BLOCKER`、`P2` 或 `FOLLOW-UP`
- 验收对象：committed HEAD `9aada838e26879810a4f79760273ca66340ebf12` 上的当前稳定未提交 S13 快照
- 失败原因：新增 shutdown evidence 的 `shutdown_disposition` 未被限制为固定 enum 集合，而是可以接受任意满足 bounded-identifier 格式的 Supervisor `ErrorCode`。这不满足冻结的 evidence-field contract。

## One-Time Findings

### P1 - Shutdown disposition is sanitized but not enum-bounded

- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs:375` 的 `RecordShutdownDisposition` 在响应存在非空 `ErrorCode` 时直接选择该字符串，并仅通过 `SanitizeCode` 后写入 `shutdown_disposition`。
- `SanitizeCode` 只检查 bounded-identifier 形式；它不像相邻状态字段的 `SanitizeEnumCode` 那样验证成员属于固定 enum。
- restore 路径同样对 `document.shutdown_disposition` 只调用 `SanitizeCode`，因此任意符合字符/长度约束的动态错误代码都可成为持久 evidence 值。
- 现有 direct test 验证 Manager/quitting 计数、布尔快照与 restore，但没有证明 shutdown disposition 只能取固定集合。
- 该实现没有证据表明会记录 raw path、pipe、token、command line 或 exception；问题是 evidence vocabulary 不满足冻结的固定枚举约束，而不是已证明存在敏感信息泄漏。
- 此项属于原 shutdown-evidence finding 的直接闭合范围，故阻止本轮 `PASS`。未扩大到 Supervisor protocol 或其他 telemetry 审计。

其余一次性 findings：无。

## Frozen Identity

HEAD 与所列文件身份只确认一次，全部匹配：

| Frozen input | Bytes | SHA-256 | Result |
| --- | ---: | --- | --- |
| committed HEAD | - | `9aada838e26879810a4f79760273ca66340ebf12` | PASS |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/RESULT.md` | 100701 | `f1a8ee9bf6bddbe11a8d8d28e9309f0f130220c333c76330eced47cc784c1419` | PASS |
| `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` | 128166 | `d7567cda79add3a1717c861f542d9516e18cb483fe44220da1b704931c7dd176` | PASS |
| `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs` | 70576 | `a51ee74454dcb5336564d718abcf26718506430a3f547b4b3cd5e30e6c362514` | PASS |
| `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs` | 122925 | `750f63b5485d1ba8901ced4f9a220973ccb178483eb23e03285438a4cbbf8877` | PASS |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | 156286 | `ee1630b8119b79fd226791f6bb4852fe0b9c626f6b316ba653f79cdf305991cb` | PASS |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | 47464 | `3cde08bb2f5f48ffd998f5e01503adf18abbd04925d012e72e381138420fd6a1` | PASS |
| `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs` | 126612 | `88fdca68be19e9ba82cf8361f253f7baaa189bb77e89116076801df26cceec8a` | PASS |
| `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs` | 49434 | `bd64acea729c27b5dceba20c534d2e49ab3e6ba2f181b333923a0d9e8ab72904` | PASS |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | 206280 | `ee0cd9799a9262e08b4cbbe619dd3996fb814b5f3a46f01c6d762b4b21144527` | PASS |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | 162653 | `c413b9e720bea021b618de7d87feff36b9f02f505f1e18ff6d7de83b46eafd54` | PASS |

## Directed Review

### FIX 05: trusted prerequisite reuse at migration gate

`PASS`

- 同一 worker pass 仅在 independent prerequisite disposition 为 `TrustworthyCurrent` 时把原 command result 传入 migration resolver。
- resolver 优先选择该结果，因此 blocked migration gate 不调用 coordinator-backed Probe；随后仍通过 `AICodedbProductStatusBuilder.Build` 与 `TryReadTrustworthyPrerequisiteEvidence` 重新校验，不把调用者判断直接提升为 authority。
- `ObsoleteReinstallRequired` 保留 `ControlContractReinstallRequired`，`InvalidOrAmbiguous` 保留 `ControlContractInvalidOrAmbiguous`；只有前者暴露 Reinstall。
- direct tests 断言 coordinator Probe 调用数为 `0`、复用同一 result，并覆盖两种 reason/Reinstall 映射。
- missing prerequisite、Uninstalled、invalid integration 的既有优先级及 fail-closed 行为仍有紧邻测试；Manager 的 migration summary/action 测试保留 authoritative diagnostic 和仅-obsolete Reinstall gate。

### Terminal presentation

`PASS`

- `showChecking` 仅在 `statusRefreshInFlight` 且 cached product state 为 `Starting` 时成立。
- terminal `NeedsAttention` 即使在 worker 退出前刚发布，未执行层仍显示 `Not evaluated`；idle `Starting` 也不显示 `Checking`。
- direct tests覆盖 terminal NeedsAttention、published-before-worker-exit、idle Starting 与 genuine in-flight Starting。
- RESULT 的人工观察确认 Manager 前后两次都收敛到 terminal/not-evaluated 状态，没有永久 `Checking`；该事实只作为人工观察，不提升为 machine-log 证明。

### Manager lifetime and stale publication

`PASS`

- `OnEnable` 建立 per-window generation/cancellation lifetime；`OnDisable` 记录 close、递增 generation 并取消旧 token。
- async status publication 同时检查 window generation、cancellation、Play generation 与 display suspension；pre-cancelled snapshot worker不启动工作。
- 旧 generation 的 `finally` 只有在其 generation 仍等于 `_hostStatusRefreshGeneration` 时才清除 in-flight flag，不能覆盖新 generation 状态。
- Play transition 递增 generation，直接 decision tests 覆盖 current/stale/cancelled/Play-stale/suspended 组合。
- 该证据证明 stale async publication 防护；没有把它夸大为 shutdown 根因已经由机器证据证明。

### Shutdown entry/return and ordering

`FAIL`，原因仅为上述 P1；其余邻接性质为 `PASS`。

- `OnEditorQuitting` 在既有 shutdown sequence 周围采集 entry/return 快照；主体顺序仍为设置 quitting、取消后台 maintenance、排队 lease 删除、排队 owned Supervisor shutdown、Bridge dispose、queue dispose、解绑 Editor callbacks。
- owned shutdown 只创建异步 task 并用 continuation 记录结果；quitting callback 未 await task，也未新增 pipe/filesystem 等待。
- entry/return 的 reconcile、Manager refresh、queue pending/active 均为整数或布尔编码；Manager refresh disposition 通过固定 enum 分派到整数 counters。
- `shutdown_disposition` 的固定枚举约束未闭合，详见 P1。

### Recorded child already absent

`PASS`

- fixture 持久化结构有效的 operation/child identity，使用预先证明已消失的 reserved PID `2147483647`，并在 recovery 前建立 coordinator status。
- 断言 terminal `pending=false`、`ok=false`，错误为 child 已消失且结果不可认证；replacement materializer counter 文件不存在。
- durable `operation.json` 保持同一 operation id，并进入 `failed` 状态。
- 生产 `Tools~/codedb-project-supervisor.mjs` 在连续 FIX 中保持相同 bytes/SHA-256；没有为 fixture 改写 production Supervisor。

### Mechanical using correction

`PASS`

- 当前 `AICodedbManagerUiTests.cs` 中 `using System.IO;` 恰好 `1` 次，`using System.Text;` 恰好 `1` 次，拼接 directive 为 `0`。
- 复用 RESULT 的机械修复记录：只修改 using header，未改测试主体；单文件 scoped diff-check exit `0`、无输出。

## Reused Evidence

以下证据来自冻结 RESULT，本轮未重跑：

| Evidence | Recorded result | Disposition |
| --- | --- | --- |
| FIX 05 corrected static/source batch | exit `0`, `FIX05_STATIC_SOURCE_BATCH=PASS`; retry `1/1` | REUSED / PASS |
| Continuous FIX static/source batch | exit `0`, `S13_CONTINUOUS_FIX_STATIC_SOURCE_BATCH=PASS`; retry `0/1` | REUSED / PASS |
| Recorded-child-absent Node L0 | exit `0`, one focused PASS; retry `0/1` | REUSED / PASS |
| Nine-file scoped diff-check | exit `0`, no diagnostics | REUSED / PASS |
| Mechanical using source check | IO `1`, Text `1`, concatenated `0` | REUSED + CURRENT HEADER CHECK / PASS |
| Mechanical using scoped diff-check | exit `0`, no diagnostics | REUSED / PASS |

## Human Acceptance Evidence

以下仅按 RESULT 作为人工观察或受限进程证据，不推断未记录的内部因果：

| Stage | Recorded evidence | Disposition |
| --- | --- | --- |
| Recompile | `0 warnings / 0 errors` | HUMAN OBSERVATION / PASS |
| Manager terminal presentation | setup-needed/not-evaluated；无永久 `Checking` | HUMAN OBSERVATION / PASS |
| Manager open during Play -> Edit | 一次自动 CodeDB action；无 stall/error/异常；随后 terminal persisted-child-absent/unauthenticated | HUMAN OBSERVATION / PASS WITH LIMIT |
| Normal shutdown with Manager open | 正常关闭，小于 30 秒，未强停 | HUMAN PATH / PASS |
| Post-exit target Unity match count | `0`，read-only count `1/1` | BOUNDED PROCESS EVIDENCE / PASS |

这些证据证明原真实用户退出路径本次成功；不证明自动 action 的 command identity、内部 queue 因果、shutdown task disposition 或此前 shutdown 失败的根因已经闭合。

## Machine Evidence Limits

- 唯一 Editor-log 读取仅为最后 `131072` bytes，且其中可解析 lifecycle document 数为 `0`。
- 以下继续标记 `NOT OBSERVED / DEFERRED`：compile/scripts-reload checkpoint、Domain Reload、Play transition、Manager open/enable/close、Manager refresh started/completed/cancelled/failed 与 current/max in-flight、terminal cached-presentation marker、`editor_quitting_entry`、`editor_quitting_return`、entry/return reconcile/Manager/queue state、shutdown queued/requested/completed/disposition、main-thread violation count及 marker 相对顺序。
- 未因 tail 中缺少 marker 推断 PASS，也未重读、扩大日志或为追逐 marker 阻塞已经通过的真实用户退出路径。

## NOT RUN / DEFERRED

- `NOT RUN`：任何测试、编译、Node L0、PowerShell probe、Unity、Unity Hub、Unity MCP、Supervisor、Coordinator 或其他业务进程。
- `NOT RUN`：protected runtime、全量日志、`UnityValidationProject/.codex/`、`UnityValidationProject/AIWork/` 的读取。
- `NOT RUN`：全量 diff、Git status、仓库级搜索、重复身份检查、广泛文件读取或新的进程检查。
- `NOT RUN`：源码、测试、配置、TASK、RESULT 或既有 dirty 文件修改；commit、push、publish；联系 Coder 或派发修复。
- `DEFERRED`：未在 bounded tail 中观察到的内部 lifecycle/shutdown marker；affected C# L1/EditMode；完整 Cold Start/Domain Reload machine trace；consumer、third-party、release 与 publication gate。

## Next Role

将本次 `FAIL`、唯一 P1、其余通过项以及人工/机器证据边界交回 UnityCodeDB v0.3 Planner。由 Planner/用户决定 `ACCEPT / FIX / DEFER / STOP`；Verifier 不自行联系 Coder或派发下一角色。

当前 S13 定向验收已完成，下一步需要通知 Planner 汇总，并由用户决定 ACCEPT / FIX / DEFER / STOP。

# v0.3 候选包残留与历史实现 Review

日期：2026-10-25（Asia/Shanghai）。
结论：`F01_F02_SCOPED_FIX_AND_REVIEW_PASS`（下方保留原审核历史）。
本范围未发现已成立的 BLOCKER；用户已选择修复两项 CURRENT_FIX_CANDIDATE。
这不是完整代码审计、独立发布验收或候选包整体 PASS。

## 快照与审核身份

- 主审查快照：`fe08d6e0961189cedd467487675062564c470644`；Package tree
  `8d0db4404025fd1db607770fc38d6a9d8427cd84`。
- 补充快照：`f7634d29664e6557308938068814d5d2d1c0fd5c`；仅核对主仓库
  独有 WIP 与候选整合边界，不将其整体视为已交付/已验收候选。
- Package：`0.3.0-preview.5`；generation：`poc.44`。名称相同不代表完整包相同。
- 审查由当前会话以源码 reviewer 职责执行；没有独立 reviewer 或子 agent。
  当前 agent 清单没有正在执行的独立 Code 子任务；未联系、打断或派工给其他会话。
- 读取位置：`<repository-root>/.worktrees/cdb-identity-handoff-heartbeat-followup/`。
  该工作树 HEAD 为 `0f61646ae376ec5ddf3351581487f468ade93520`，其 Package Git tree
  与 fe08d6e 相同。已有验证工程及历史 payload dirty 状态不纳入审查快照。
- 17 个主要读取文件逐字节与 fe08d6e Git blob 比较一致：Manager、transition
  helper、Lifecycle/evidence、Bridge、Paths、两个 asmdef、materializer/engine、
  Supervisor、Provider installer、exporter、closure validator、payload manifest，
  以及 poc.44 worker/coordinator。补充 writer 代码按 f7634d2 定位。

前置候选比对已确认消费者 669 个交付文件等于 fe08d6e，额外一个测试 `.meta`
单列；本轮没有再次读取消费者、查询实时状态或推断运行进程身份。

## 覆盖与证据边界

| 检查面 | 本轮覆盖 |
| --- | --- |
| 自动诊断输出 | Manager OnEnable/Repaint 接线、sidecar 限额/发布、Lifecycle checkpoint 输出 |
| 正常路径与测试替身 | materializer 参数/fixture 前置门、candidate fixture shortcut、Provider TestMode、Paths 的测试作用域 |
| 交付隔离 | Editor/Tests asmdef、Tests~ 调用引用、commit-derived exporter、payload/generation 选择 |
| 已修复路径是否仍属临时行为 | C 方案只读 observation 的直接接线、cleanup 调度生产/消费记录；不重审完整状态机 |
| 历史保留代码 | 当前 generation/受信前代选择、legacy idle helper 的直接引用、listen-delay 测试接线 |
| 主仓库独有 WIP | ProcessRunner 与 Manager action writer 的超时差异及原有未验收记录 |

证据为静态调用链、Git 对比和已有归属明确的任务记录。
未运行 L0、L1、EditMode、Unity、MCP、Provider、Supervisor、导出或性能测试。
未新增观测器、运行源码提取 harness、读取 live lease/进程/日志，或重跑既有 PASS。
定向读取与检查在 STANDARD_30M 预算内完成。未深审每个历史 generation。

## F01 — 普通使用仍默认发布阶段性诊断输出

分类：`CURRENT_FIX_CANDIDATE`，不作为功能 BLOCKER。
快照：fe08d6e。

位置与触发：

- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs:185` 在普通 OnEnable 创建
  transition evidence；`:1309` 在实际 Repaint 调用 CaptureHeaderRenderInput。
- `Editor/AICodedbLifecycleEvidence.cs:964` 持有 domain-local helper。
- `Editor/AICodedbManagerTransitionEvidence.cs:20` 为每个 domain-local helper
  建新 session；`:109`、`:111` 向 `Library/CodeDB/Diagnostics/` 发布 sidecar。
- `Editor/AICodedbEditorLifecycle.cs:705` 在 reconcile 完成后调用 PersistAndEmit；
  reload/Play/退出回调也有同类接线。
- `Editor/AICodedbLifecycleEvidence.cs:1163` 至 `:1172` 保存 SessionState 并
  Debug.Log 完整 `CODEDB_S12_EVIDENCE` 文档，没有显式诊断启用门。

具体影响：诊断目录清空不等于关闭源头。下一次普通 Manager 打开/重绘可以重新
生成 sidecar；后续生命周期 checkpoint 继续向 Unity 日志输出整份证据文档。
这使此前已阶段收口的诊断行为继续进入正常使用环境，增加文件和日志噪声。

限制：sidecar 有 64 条/128 KiB 限额、语义去重、后台单 writer 和失败停止逻辑；
不是每帧写盘，也未证明其造成卡顿、Ready 波动或数据损坏。每次 domain 创建新
session，不等于本轮实测了跨会话积累量。Lifecycle 的纯内存计数也不能直接等同
于日志开销。此 finding 不重开心跳/身份根因调查。

最小建议：在候选冻结前选择关闭默认的 sidecar 与整份证据日志发布，保留正式
回归测试、产品故障 warning/error 以及仍需使用的内存计数。诊断能力可作为显式
启用入口保留，或定向移除临时生产接线；不要求新建日志系统或重构状态机。
用户也可以明确延期此项；本轮没有实施任何一种选择。

## F02 — 主仓库 writer-lifetime WIP 不能随整合自动获得候选资格

分类：`CURRENT_FIX_CANDIDATE / CANDIDATE_SCOPE`，仅适用于 f7634d2 的后续整合。
它不是 fe08d6e 内的缺陷，也不推翻已交付包的历史功能结果。

位置与触发：

- f7634d2 的 `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs:756` 对
  ConfirmedProjectMutation 选择 `terminateOnTimeout=false`；`:2200` 至 `:2205`
  改变超时后的终止和 output-drain 行为。
- 同快照 `Tools~/invoke-codedb-manager-action.ps1:234`、`:359`、`:387` 对该
  effect class 保留 writer/child，而不是采用已交付基线的终止行为。
- 原记录 `.ai/tasks/v0.3.0/cdb-v0.3-p0-s40-retained-mcp-install-admission/`
  `SOURCE-INTEGRATION-RESULT.md:33` 明确标为 unaccepted writer-lifetime deltas；
  identity-handoff `REPAIR-PLAN.md` 也明确禁止随其修复带入这批 WIP。
- `git show f7634d2` 证实整理提交纳入了这两处产品行为改变；写入 Git 本身没有
  补齐其验收。它们不存在于 fe08d6e。

具体影响：若把“主仓库已提交/干净”当作整包验收依据，再叠加隔离分支修复导出，
会把不同的 mutation writer 超时策略一起交付。现有 fe08d6e 编译、focused 测试
及观测证据不能转移给该组合，正常安装/卸载的终态归属也不能预先宣称等价。

限制：本轮没有证明任一策略实际损坏数据、遗留进程或误停外部进程；没有给该
WIP 下产品缺陷结论，也不以理论竞态升级为 BLOCKER。

最小建议：当前候选默认从已交付基线整合，保留 WIP 的源码/历史，但明确排除
这两处独立行为差异；若用户选择纳入，则单列它的冻结需求与直接超时/终态证据，
不能用旧包 PASS 代替。文档澄清与产品实现资格分开处理，不整分支覆盖或回滚。

## 已核对的保留用途与非阻塞清理项

| 内容 | 证据与建议 |
| --- | --- |
| 正式 Editor 回归测试 | `Tests/Editor/Rice.AICodedb.Editor.Tests.asmdef:2` 为独立测试程序集，引用生产 Editor，autoReferenced=false，使用 TestAssemblies；未发现本范围内的测试 InitializeOnLoad/菜单自动接线。保留测试与 testables 用途。 |
| Tests~ 脚本 | exporter `Tests~/export-codedb-package.ps1:96` 按提交归档整个 Package，`:103`/`:112` 使用包内 validator。它们随包交付有开发验证用途；定向引用搜索未发现正常 Editor/Tools/poc.44 调用测试 runner。不能把随包包含等同于自动执行。 |
| fixture-ready 与故障注入 | `Tools~/codedb-instance-engine.ps1:2651` 的 synthetic probe 受 PocFixture 控制；materializer `:12410` 起拒绝 fixture 与确认项目修改并用，并约束 test faults；`:1167` 起要求受限 fixture 路径、归属 marker。是有隔离门的测试替身，不是发现了普通 Install 绕过。 |
| Provider TestMode | `Tools~/install-codedb-provider.ps1:686` 起检查隔离脚本路径，后续要求明确隔离输入。保留现有测试门。 |
| C# 测试作用域 | `Editor/AICodedbPaths.cs:391` 的 AsyncLocal root override 仅有测试调用，Dispose 恢复前值；默认生产路径仍解析正常 receipt root。不是默认改变全局环境。 |
| C 方案 observation | `Editor/AICodedbEditorLifecycle.cs:4137`、Bridge `:1490` 的直接路径用于只读已有 Supervisor 状态；没有在该直接路径发现 fixture shortcut 或自动 install/cleanup 接线。保留已阶段验证的修复，不借本 Review 重构。 |
| 历史 generation | materializer `:1834` 起区分 CURRENT/TRUSTED_PREVIOUS 并从声明的前代目录读取闭包。历史目录不是仅凭存在就可删除；本轮不逐代重验，也不把换行差异当作新功能。 |
| legacy idle helper | Bridge `:1678` 的 WaitForLegacySupervisorIdle 在本次引用搜索中仅由 Lifecycle tests 直接调用，当前协议入口 `:1665` 起拒绝旧 owner 协议。列为 FOLLOW-UP 的测试/历史 helper 整理项，不影响当前正常路径，不要求现在删除或重跑测试。 |
| listen-delay seam | Supervisor `:1694` 默认 0，仅显式环境值启用且有上限；supervisor test `:1876` 使用它模拟启动窗口。有明确回归用途，未发现默认启用，保留。 |
| 额外测试 .meta | 前置比对仅发现一个额外测试 meta，不是新产品代码；未来定向整合时明确元数据归属，禁止以此删除正式测试。 |

没有因历史年份、命名含 S12/POC/Test 或方法仅由测试引用而提出批量删除。
没有逐条证明所有间接动态调用、所有支持平台、长期日志量或全生命周期行为。

## 用户统一处置与停止点

建议：F01 在当前候选中收敛默认诊断输出；F02 将独立 writer WIP 排除在本轮
候选之外，保留待单独验收。正式回归测试与有明确用途的 fixture/前代数据保留，
legacy helper 清理延期。

用户可对每项选择 FIX_NOW / DEFER / ACCEPT_RISK。审核到此停止；没有直接分派
开发、修改源码、删除文件、启动新测试或批准生命周期验收。修复复审只验证用户
选定的原 finding 及紧邻回归，不重新展开全面审计。

- Current task: cdb-v0.3-candidate-residual-legacy-review.
- Current status: REVIEW_COMPLETE / USER_DISPOSITION_PENDING.
- Next notification: user.
- Next action: 用户统一处置 F01/F02 后，再冻结最小修复/源码整合范围。
- Human decision or authorization required: findings 处置；产品修改、整合、提交、
  Package 交付、Unity/MCP 验收均未执行或由本报告授权。

## 2026-10-25 原 finding 定向复审

用户“需要处理 f01 \\ f02”已授权局部修复。当前会话先完成稳定源码修改及定向
离线检查，再切换 reviewer 职责；未启用独立 reviewer，也未扩展全面审计。
具体文件哈希、原始 WIP 恢复来源、执行回执和限制见同目录 `RESULT.md`。

| Finding | 本轮处置 | 定向复审结论 |
| --- | --- | --- |
| F01 | 隔离候选的 evidence factory 和两条整文日志路径增加默认关闭的 domain-cached 显式开关 | SOURCE PASS：默认不创建 sidecar、不输出整文日志；实际抽取方法体的四种开关场景通过。计数、SessionState 与显式诊断保留；Manager 已有 null 消费边界适配。 |
| F02 | 主仓库两份 writer 文件精确恢复到 fe08d6e 字节，未验收 WIP 留在 f7634d2 | CANDIDATE_SCOPE PASS：逐字节核对和原版哈希恢复核对通过，没有带入新的 writer 策略。 |

九项离线分组检查、保护文件哈希及 scoped diff 检查通过。首次 harness 参数转换
错误保留独立回执，修正调用后通过；不计为产品故障。所有既有 dirty 文件保留。
源码修改尚未合并为唯一主仓库候选或交付消费者；Unity 编译、EditMode、实际
sidecar/日志行为的 Unity 验证及 MCP 均 NOT_RUN。历史 PASS 不转移到新包。

两项原 finding 的源码/候选范围修复关闭；未新增 BLOCKER。正式测试、fixture、
历史 generation 保留；原 legacy helper FOLLOW-UP 不在本轮展开。
当前审核停止，后续接唯一候选源码整合与对应交付/验收阶段。

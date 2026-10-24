# S29 移除预检：历史进程身份分类修复草案

日期：2026-10-14。状态：DRAFT / ANALYSIS_COMPLETE / NOT_IMPLEMENTATION_AUTHORITY。
源码基线：39d79aeee1bd5525c6ed2eb1369f6c27334b9d07。
本记录只整理已讨论边界和建议实现范围，不修改此前已接受契约，不授权源码修复、
子 agent、交付或真实环境操作。历史不做无限兜底；CleanupMono 继续延期。

## 当前证据及其限制

- 当前 S29 manifest 仍引用 s29-removal-namespace-39d79ae 精确包。工作树与该包的
  materialize-codedb-host-payload.ps1 SHA256 相同：
  1bc989195aa14def596e16231cc2876afcedfbab4a5f342ca1384f9567de695a。
- 只读检查当前 v2 Supervisor 命名空间内 1017 条历史记录，约 3.74 MB；
  它们均指向当前 selected poc.42。没有执行产品预检或更改历史文件。
- 2026-10-14T13:33:52Z 起的有界快照中：975 条记录的 PID 不存在，30 条
  启动身份不同，10 条身份不可读取，2 条 child=null。进程状态会变化；较早一次
  快照为 974/31/10/2，不能将这些数字视为稳定产品状态或验收计数。
- 023ba757012744efa16a296508874bb0 是一个具体可触发现有 PID 拒绝条件的样本：
  历史 PowerShell PID50100 的启动身份为 639274576991952580；当前该 PID 是
  node_repl，按生产端精度归一后的身份为 639275489614900810。
- child=null 的两条记录是 45e02ba862654c81af4d592dc56e49d3（Probe completed，
  exit0）和 69d2e7c44f774e3687e352d5faf9eb97（Upgrade failed，exit1，
  EDITOR_OFFLINE）。成功、失败或错误文案均不能替代未捕获进程的安全证明。
- 这些样本说明当前条件可独立拒绝；没有重跑真实预检，不能断言哪条记录是
  此前截图中的首个失败项，也未验证全部记录的严格产品解码与资源安全。

## 本次建议结果

只修正 v2 removal 对已有 Supervisor 进程身份的解释及拒绝原因：
PID 是查询入口，启动身份用于区分原进程与复用 PID 的新进程。身份结果本身
不发放移除许可，不构成原操作全部子进程或副作用已经结束的证明。

本阶段明确不承诺解锁真实移除：两条缺失 child 的历史记录仍按原契约拒绝。
不通过伪造历史身份、推断错误文案、删除记录或启动通用恢复来绕过它们。
如需处理它们，先另行证明一个有界的当前资源隔离方案；无法证明则保留具体阻断。

## 分类与准入责任

| 观察 | 分类 | v2 removal 的处理 |
| --- | --- | --- |
| 明确查无 PID 或进程已退出 | 原进程已退出 | 不由该 PID 继续否决；其他安全检查继续 |
| PID 可见，启动身份匹配 | 原进程仍在 | 拒绝，说明 owner/child 和原记录身份 |
| PID 可见，启动身份确定不同 | PID 被复用 | 不认领、不接管、不停止当前进程；继续其他相关安全检查 |
| 查询失败、启动身份不可读或没有适用的比较语义 | 身份未知 | 明确拒绝，不混写为原进程仍在或复用 |
| 历史 child 缺失或记录格式非法 | 历史证据缺失或无效 | 单独拒绝，不转换成 PID 不存在 |

比较契约：Supervisor 的 Windows 生产端使用 UTC ticks 并截去 ticks%10；
读取端遵循同一精度。不得借用 generation lease 的 Unix 毫秒加减 2 秒比较函数，
不得采用进程名称、路径相同或任意时间容差来替代启动身份。无效身份不得得出
“确定不同”。其他平台仅采用已有明确生产契约；不扩大兼容或引入隐式转换。

本轮适用点仅为 VERSIONED_V2 removal 的历史 child、stale Supervisor owner
及当前 Supervisor owner。current state/lock 仍须成对、身份一致；活动历史、
foreign/malformed 记录、缺失 child、未知身份继续按对应原因拒绝。
legacy/v1 的现有处理不变，不改通用进程 inspector 和其他命令的停止/恢复语义。

保留以下独立检查：Package/selection/activation 身份、不可变闭包、路径与重解析
保护、命名空间与历史指纹、配置保留、相关 selected/LKG holders，以及锁内、
变更前和提交前核验。Get-InstanceRetirementHolderEvidence 覆盖 MCP/Editor/
coordinator；它不能单独证明缺失 child 无逃逸影响，不能用它替代缺失证据拒绝。
预检结果不是无限期许可；原有执行时核验继续调用同一身份解释。

拒绝诊断应区分 original process alive、identity unavailable、child evidence missing，
包含有界 operation_id 或 owner 角色，避免同一句 live/reused/unverifiable 混写。
沿用现有受限、脱敏的 Manager 诊断传递，不输出完整参数、令牌或 handoff。
分类结果是检查时的派生值，不新增持久化状态、schema 或独立所有权 authority。

## 建议源码与测试范围（尚未授权）

相对 com.rice.ai-codedb，仅建议允许修改：

1. Tools~/materialize-codedb-host-payload.ps1：v2 removal 局部分类及三个消费点。
2. Tests~/test-codedb-host-payload-materializer.ps1：既有 RemovalNamespaceOnly
   隔离场景，使用可控进程观察 seam 验证真实生产调用链。
3. Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs：
   生产输出到 C# 诊断消费的直接回归。

直接读取 Supervisor 身份生产函数、实例 holder、现有 lifecycle 诊断及测试工具；
不修改它们。不改 Payload、generation、Manager 布局或通用进程控制。
若发现必须跨出该范围才能建立正确语义，先返回具体契约缺口。

## 建议验收

- PowerShell 语法、scoped diff-check、强制 PathProvenanceOnly；精确包隔离 overlay，
  不读取 dirty Payload 作为替代权威。测试路径来自调用方的仓库本地隔离根。
- 隔离生产预检：PID 不存在、启动身份匹配、确定复用、查询或启动身份不可读，
  以及匹配精度、同可执行文件不同启动身份的场景。复用只通过进程身份这一关。
- child/stale/current owner 的消费行为一致；复用 PID 后相关 holder 仍活跃或
  无法认证时仍拒绝。child=null、活动/非法记录与 v1 原规则回归继续拒绝。
- handoff/锁内/变更前重新观察身份；若原进程仍在或无法认证，不能沿用旧许可。
  保留原历史字节与交易目标边界。对已有终态核验按原入口验证，不新增重放能力。
- 精确拒绝文本通过既有生产输出和 C# 消费 seam；未知或证据缺失不产生 Available。
  适当编译直接受影响测试，源码证据与人工作业、真实移除、release 分别记录。
- 生产进程观察使用隔离 seam，不停止、附着或启动受监督子进程；不执行真实
  Install/Remove/Upgrade/Probe/IPC、Unity、清理、出包或引用切换。

## 授权与下一步

用户已对齐分类、不暴力终结、历史有界支持原则；尚未授权本草案的源码实现。
实现前需冻结执行范围与审查路由。新任务不能继承此前六文件任务的子 agent
批准或已完成的交付授权；如采用子 agent，须按当前用户约定取得本任务批准，
父 agent 持续处理问题并等待 Coder 稳定完成后再进入只读 Verifier。

本次草案不启动源码、隔离测试或审核，不修改既有验收结论。S29 仍为 PARTIAL。

后续授权：用户在审阅本草案及三文件范围、隔离验证、复用 Coder -> 只读 Verifier
提案后回复「好的 批准」。该后续批准覆盖源码执行与审核，不含交付或真实操作。
执行入口现为 REMOVAL-PREFLIGHT-PROCESS-IDENTITY-TASK.md；前文的未授权描述记录
草案提出时状态，不再代表该已批准源码 envelope 的当前状态。

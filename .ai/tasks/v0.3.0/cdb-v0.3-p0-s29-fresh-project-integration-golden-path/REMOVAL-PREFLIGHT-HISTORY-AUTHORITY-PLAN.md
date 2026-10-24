# S29 移除预检：操作来源与实例身份分离方案

日期：2026-10-15。状态：PROPOSED / NOT_IMPLEMENTATION_AUTHORITY。
基线：544be4f7e339acefb47137b188cdc85e22483efb。
用户本轮「嗯 我们继续」承接只读分析和方案整理，不代表新源码或子 agent 授权。
诊断入口：REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-DIAGNOSIS-2026-10-15.md。

## 一个独立结果

让 v2 removal 正确解释已有生产端可以生成的「执行 Package 与 selected 实例
不相同」记录，不再仅因二者契约不同而将合法来源组合混报为 foreign/active。
这是记录消费者的职责修正，不新增历史迁移、通用兼容层或 schema。
本阶段不承诺真实移除解锁、Ready 或 Install 按钮恢复。

roadmap 的既有定义：runtime_contract_sha256 是作出决定的精确 Package 契约；
target_generation_id 与 selected_generation_id 分开。生产端已遵循该定义。
本方案不修改生产端去伪装其操作来自旧 Package，也不改写旧 activation/记录。

## 身份职责

| 消费对象 | 必须使用的权威 |
| --- | --- |
| selected 实例、不可变闭包、committed activation | 现有精确 selected 身份及其唯一 Package-declared transition；不放宽 |
| 历史操作的 runtime_contract_sha256 | 操作生产 Package；仅允许下述有界组合 |
| current/stale owner 的 target/hash/disposition | 同一个受信 Package 组合；额外维持 selected、activation、state/lock 配对等约束 |
| removal handoff、意图指纹、重验证 | 保留现有各字段职责；不能把局部历史来源允许集当作通用权限 |

## 唯一允许的来源组合

先按现有入口认证 selected 闭包，再派生至多两个来源，不扫描磁盘找旧包、
不遍历所有 bootstrap transitions、不从历史记录自报字段构造信任根。

1. **selected 来源**：当前 selected 的精确 generation 身份；若是旧实例，必须
   来自当前 Package 唯一、精确声明并保留闭包的 predecessor transition。
   source runtime hash 不存在或不明确时拒绝，不补猜。
2. **当前 Package 来源**：已验证的当前 Package runtime hash/target generation，
   与已认证的 selected 实例绑定。仅当 selected 是 CURRENT 或该 Package
   精确声明的 TRUSTED_PREVIOUS 时成立；不扩展到任意旧 generation。

selected 已是当前目标时合并重复组合。哈希、target 或来源发生无法唯一解释的
冲突时继续拒绝；不依据 generation 名称、文件名、版本字符串或 PID 猜测。
实现不得写死本次 poc.42/poc.43、哈希、实例、磁盘路径或操作 ID。

## 各消费者规则

- 历史 operation 本身没有 target_generation_id 或 activation_epoch；不要求
  凭空补造字段或重建已丢失 owner。保留 schema、project/root/namespace、
  selected instance/generation、owner_epoch 格式、终态、结果和 child 验证；
  runtime hash 只能匹配上面派生的来源。哈希匹配只是这一项通过，不能替代
  原有全部证明，也不能宣称完成了额外的原始 owner/activation 认证。
- owner 有 target/hash/disposition，必须三者整体匹配同一个来源；不能独立
  使用「target 在集合中」「hash 在集合中」而允许交叉拼接。
  selected 来源的旧 owner 为 CURRENT；当前 Package 对旧 selected 的 owner
  为 TRUSTED_PREVIOUS。保留 control contract、selected、activation、进程身份、
  state/lock 同一 owner 与 fingerprint 等原约束。
- 对历史 operation 不存在的 target 字段不做额外承诺；若现有 schema 与上面
  的有界来源仍不足以安全解释实际记录，应返回明确缺口，不扩大 schema 或
  用 child argv/外部日志临时补信任。
- 预检、锁内、变更前、提交前及既有 terminal/recovery 重验证使用同一来源规则；
  preserved history 字节与 fingerprint 继续保留，不把预检缓存当长期许可。
- foreign/未知 hash、来源组合错误、活动记录等分别给出准确拒绝；使用有界
  operation_id 或 owner 角色定位。不得输出 token、完整 argv、完整内部命令。
- 原进程仍在、身份未知、child 缺失、holder 活跃/不明继续阻断。PID 复用
  仅通过进程身份关。两条真实 child=null 历史及 CleanupMono 继续延期。

## 建议源码范围与验证

源码写入仅建议三个文件，相对 com.rice.ai-codedb：
Tools~/materialize-codedb-host-payload.ps1、
Tests~/test-codedb-host-payload-materializer.ps1、
Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs。
在 materializer 内新增或细分局部来源解释，保留原 selected runtime context
给 activation 等现有消费者。instance engine、Supervisor、Manager、Payload、
generation、真实历史与 legacy/v1 行为不在修复范围。

复用现有 RemovalNamespaceOnly 隔离生产链及原 C# 诊断/cache/UI 消费工具：

1. CURRENT 单一来源、TRUSTED_PREVIOUS 双来源及两种历史混合通过来源验证；
   夹具保留真实生产字段语义，不能把所有记录改成同一 hash 才测试。
2. 两种来源分别覆盖 current/stale owner，错误 target/hash/disposition 拼接、
   state/lock 混合、foreign project/selected/hash、未知来源仍拒绝。
3. 已有 child live/reused/unknown/missing、活动记录、holder、canonical/history
   一致性、fingerprint 和锁内/变更前重验证回归；来源正确不绕过任何安全拒绝。
4. 既有 copied transaction、terminal/recovery 消费与精确诊断到 C# 缓存/UI 的
   直接回归；不增加通用恢复入口、不声称真实移除成功。
5. PowerShell 语法、scoped diff-check、强制 PathProvenanceOnly、原字节 Editor
   与 Editor.Tests 编译；精确已接受包 overlay 只允许上述三文件差异，真实
   protected-state 哈希核对。测试根由调用方提供，遵守 test-workspace-contract。

所有产品进程观察使用隔离 seam；真实 preflight/Probe/IPC、Install/Remove/
Upgrade、Unity/MCP/BatchMode、进程控制、历史清理、环境修改均不执行。
不重跑无关全回归；不重复已完成交付；source/isolated、人工 Unity、实际移除、
release 各自记录。任何范围、schema、信任根或闭包扩展先返回用户。

## 建议执行与授权边界

本文件只完成方案整理。建议冻结为一个 GUARDED 源码任务，采用既有 Coder
稳定快照 -> 父 agent 准入 -> 独立只读 Verifier -> 用户统一裁决。
跨层身份契约沿用 DURABLE_SESSION 默认；若本任务复用已有 task-scoped Coder
与 Verifier，须用户明确批准该路由例外，不能继承已结束任务的 delegation。
父 agent 持续接收问题并确认子任务终态；不派发后提前结束。
源码修复、隔离验证和独立复核可以一并授权后连续执行；commit/出包/引用切换、
真实操作和新人工 Unity 验收均不包含在该源码授权内。
当前未启动子 agent，未修改源码，未执行测试。S29 保持 PARTIAL。

后续授权（2026-10-15）：用户对三文件修复、隔离验证和复用 Coder -> 只读
Verifier 的具体提案回复「同意」。执行以同前缀 TASK.md 为准；本方案提出时
的未授权描述保留历史含义，不再代表已批准源码阶段的当前状态。

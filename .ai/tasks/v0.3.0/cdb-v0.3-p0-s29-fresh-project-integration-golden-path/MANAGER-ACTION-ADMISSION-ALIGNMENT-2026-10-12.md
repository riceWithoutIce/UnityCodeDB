# S29 — Manager 操作入口与交付证据对齐

日期：2026-10-12。
阶段：任务整理；后续只读诊断范围草案。源码修复、交付和真实工程操作尚未授权。
所属：现有 S29；不新增并行开发路线。S29 / release 维持 PARTIAL。

## 目标

从操作准入的源头解释 Install 等入口为何没有正常显示，区分错误隐藏与安全限制，并形成可审核的窄范围修复建议。

预期行为：满足操作条件时显示正确入口；条件不满足时给出可理解、可归属的受阻原因。不能仅凭 Manager 显示 Ready 推定安装、卸载或重装已获准。

## 当前证据与已作决定

- 当前 HEAD：9179d8a1a679056bef19b7e9246988510c3c9284。
- HISTORY-AGGREGATE-REPAIR 与 PRODUCER-ATTRIBUTION-REPAIR 均已有独立 PASS_WITH_LIMITS 记录；四个 Editor / Tests 文件仍是未提交工作树修改。
- 用户在对话中报告编译、Manager 开关、页签切换及 Unity 正常关闭等人工检查通过。这些结果属于已交付包，不能作为上述未交付源码的 Unity / runtime 验收。
- producer focused fixture 曾被 poc.42 coordinator 的 payload source hash mismatch 阻断；这是未完成的功能验证，不是功能 PASS。
- 用户已决定延期旧历史归属断链，继续严格 fail-closed。不得通过时间、generation 或 receipt 邻近性推断旧 candidate 的归属。
- 现有 roadmap 的 2026-10-10 状态段早于后续源码和人工结果；本稿记录当前边界，不自动改写 roadmap 或远端 Project。

## 只读诊断范围

1. 追踪 Manager 主操作入口的决策链：按钮标签与可用性、产品 / Host 状态、session 恢复、action journal、失败 INSTALL 聚合、candidate attribution。
2. 重点核对 Install / Reinstall 相关分支；Uninstall / Remove Integration 仅核对共享判断及紧邻回归，不扩展到所有生命周期操作。
3. 明确区分四类结果：合法可操作、合法但受已有动作阻塞、历史归属冲突、证据缺失或过期。记录入口显示 / 隐藏 / 禁用及提示来源。
4. 核对 Manager 关闭重开后的 durable history 与 SessionState 恢复，确认入口判断是否一致；不自动操作 Unity。
5. 核对 instance ID 契约差异：FindUnownedProvisioningCandidate 调用要求 24 位的 IsPhysicalKey，但真实 S29 的三个 instance 目录均为 32 位。检查 producer、manifest reader 与相关测试的契约，判断其对正常实例扫描和按钮准入的影响。
6. 有限核对已记录的 payload hash 不匹配：确定它阻断的验证范围及交付影响，区分既有 dirty 源码与已交付 artifact；不重新生成 payload、修 hash 或重跑被阻断的 fixture。
7. 整理已交付包、未交付源码、人工结果及未执行验证之间的对应关系，避免混用结论。

## 不在本阶段内

- 不修改产品源码、测试、payload、generation 或包引用。
- 不重复 Install、Uninstall、Remove Integration；不启动 Unity、BatchMode、Unity MCP 或 UI 自动化。
- 不改写 / 删除真实 receipt、candidate、manifest、cleanup state；不手工释放 admission 或停止外部进程。
- 不恢复延期的历史孤立 candidate，不扩大到 Host / Supervisor 架构重构。
- 不 commit、出包、切引用、push、发布或同步 GitHub Project。
- 保留全部现有 dirty / untracked 状态，不整体 staging、reset 或 clean。

## 输出与诊断完成标准

- 一份源头分析：每个确认的问题有具体条件、生产源码路径和证据；假设、已证实缺陷与有意 fail-closed 分开标注。
- 一张聚焦状态表：操作条件 → 入口表现 → 受阻原因 → 证据类别，覆盖正常 Install、失败 retained / conflict、stale session 及合法已安装状态的紧邻分支。
- 对 24 / 32 位差异给出契约结论，对 payload hash mismatch 给出有限交付影响结论。
- 一次性返回 findings，提出最小修改文件、必要回归与验收限制；由用户决定修复、延期或接受风险。
- 诊断完成不等于按钮修复完成；旧工程仍处于历史 conflict 时，Install 继续隐藏可以是正确结果。

## 后续修复与交付门槛

若用户授权修复，先冻结确认 finding 和文件范围，再执行 Coder → 稳定快照 → 独立只读 Verifier → 用户 disposition。复审只覆盖原 finding 和紧邻回归。

修复验收应证明：合法路径入口正确；历史归属不明仍拒绝操作并解释冲突；关闭重开不引入陈旧会话误阻塞；真实格式的合法 instance 不被错误判为非法。具体测试与运行权限在修复范围确认时冻结。

新子 agent 另需用户批准；如派发，父任务持续接收问题并确认终态。完成源码验收后，commit / 出包 / 引用切换及人工 Unity 验收仍是后续独立阶段。本稿不预先授权这些动作。

全新工程 Install → 已认证卸载 / 移除集成 → 重装 → reopen 的连续 golden path 留待交付条件和操作授权明确后开展；不得用现有基础 UI 检查替代该路线。

## 本稿来源

- 用户本轮要求“先整理任务内容”，以及此前关于 fail-closed、历史延期、人工检查和不交付的决定。
- HISTORY-AGGREGATE-REPAIR-VERIFICATION.md。
- PRODUCER-ATTRIBUTION-REPAIR-RESULT.md / VERIFICATION.md。
- 当前源码的 FindUnownedProvisioningCandidate / IsPhysicalKey 与只读目录清单。
- Documentation~/v0.3.0-roadmap.md 的 Current Route Status / Delivery Sequence。

本稿仅文件化现有决定及待核对范围，没有新增诊断 PASS 或人工运行时验收结论。

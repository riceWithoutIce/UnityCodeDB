# S29 — Manager 操作入口源头诊断

日期：2026-10-12。父任务只读诊断完成；不是独立 Verifier 结果。
范围依据：MANAGER-ACTION-ADMISSION-ALIGNMENT-2026-10-12.md。
产品源码 / 测试 / payload / 实际运行状态未修改；仅新增本诊断记录。

## 结论

按钮没有显示不是单一 UI 绘制故障。已交付包存在单条失败历史恢复限制；真实 S29 还存在用户已决定延期的历史归属断链。未交付源码新增了实例扫描，但错误复用了 24 位 receipt 目录键校验，会把合法 32 位 instance 判为非法。这三个事实必须分开处置。

本次确认一个应在交付前修复的 P1 源码缺陷；多条失败历史的恢复呈现需要单独明确策略。旧 orphan 继续 fail-closed，不在本次修复建议中恢复。S29 / release 保持 PARTIAL。

## 决策链与证据

- ManagerWindow:1466–1494 分别计算 removal、fresh-install recovery 和可执行回调，再将 GetPrimaryActionLabel 的字符串交给 DrawBanner。
- SectionView:51–52 仅在标签非空时绘制按钮。空标签代表入口不呈现；有标签但回调为空代表不可执行。不能把两者混为一个 UI 原因。
- ManagerWindow:2144–2176：NotIntegrated / Uninstalled 给出 Install；NeedsAttention 先尝试 fresh recovery，再尝试 Remove Integration / Uninstall，否则返回空标签；Ready 默认不显示 Install。
- ManagerWindow:2414–2432：fresh recovery 必须有非 recovering、带原始上下文且 FailedCandidateEffectsRetained 的历史 session；产品 NeedsAttention / AttentionReason.None；Host SetupRequired；当前包键与失败动作包键不同。
- ManagerWindow:445–452：running 或 recovering session 均令 _userActionInFlight 为 true。恢复呈现的 ButtonLabel 为空（ActivityPanel:648–658），因此可直接导致主入口不呈现。
- ManagerWindow:462–484 / 3584–3641：打开窗口后只读获取 durable journal，恢复 session，再附着 UI。Conflict 产生 IsRecovering / IsEvidenceConflict session，阻止新变更；Empty 带有效 retained result 才能替换同工程 stale session。
- Journal:891–897：failedInstallCount 仍必须等于 1 才返回历史 Index / Result。两条及以上时仅保留 warning，不能形成 fresh recovery session。此前名为 history aggregate 的修复聚合的是已知 action IDs，并没有消除此单条恢复限制。
- Journal:219–223：扫描异常被转换为 Conflict；ManagerWindow:3617–3623 将具体 Detail 放入 Recovery 呈现。恢复提示存在生产路径，但本次没有打开 Unity 验证原生呈现。

## 聚焦状态表

| 条件 | 当前入口表现 | 准入 / 原因 | 证据边界 |
| --- | --- | --- | --- |
| NotIntegrated / Uninstalled，且无 in-flight action | Install | 可进入确认与后端准入 | 静态分支；不是本次真实安装 PASS |
| 单条已认证 retained，包不同，NeedsAttention 无特定 attention，Host SetupRequired，session 非 recovering | Install | fresh recovery 条件满足 | 静态 gate；仍需后端安全检查 |
| 上述条件，但旧 SessionState recovering 未被 durable result 替换 | 主入口可为空 | session 阻塞 | 当前未交付源码已有替换逻辑；尚无本次 Unity 运行证据 |
| 多条失败历史，无 current index，且未形成其他 pending/conflict | 无可用 retained fresh recovery；可能显示其他移除入口 | count != 1 时 Index / Result 被省略 | 确认源码限制；不宣称任意多历史均可安全安装 |
| 任意合法 32 位 instance，且 journal 进入新增候选扫描 | 主入口可为空，恢复 Conflict | 目录被错误判为非法；包括 READY instance | 确认的未交付源码 P1 |
| PROVISIONING candidate 的 action 无归属记录 | 新变更受阻 | 严格 fail-closed；修正 ID 校验后仍应如此 | 实际历史字段 + 静态判断；未运行当前 reader |
| Ready，无 session 阻塞 | 不显示 Install；满足 removal preflight 时 header 菜单有 Uninstall | 已安装时的预期行为 | 静态菜单与准入条件 |
| RequiresReinstall 且 removal preflight 通过 | Remove Integration | 不能直接以 Install 跳过移除前置条件 | 静态 gate |

菜单项的存在不等于新变更已获准；实际动作仍经过 session / backend admission。此表不声称所有 header 菜单都按 session 状态隐藏或禁用。

## F-01 — P1：实例扫描使用 receipt 目录键契约

触发：Manager journal 存在且执行 FindUnownedProvisioningCandidate，instances 下有正常 producer 生成的目录。

Journal:915 对 instanceId 调用 IsPhysicalKey；该 helper 在 :940 仅接受 24 位小写 hex。24 位对 historical Manager Package 目录是正确契约：Paths:432–444 将 64 位 identity hash 截为 24 位；Journal:691 / :745 依赖该契约。

instance 是另一契约：Tools~/codedb-instance-engine.ps1:2728 使用 Guid.NewGuid().ToString("N") 创建 32 位 ID；materializer:10321、poc.42/scripts/codedb-project-common.ps1:135 和 stable wrapper:102 都要求 32 位。真实三个目录的 manifest.instance_id 与目录名一致且均为 32 位。

扫描在读取 state 前即抛出 invalid directory，所以不仅 orphan，合法 READY / 已归属 PROVISIONING 也会触发 Conflict，进而阻塞正常用户路径。它是未交付源码的发布前缺陷，不是理论加固。

Tests/Editor/AICodedbManagerUiTests.cs:1972 / :2003 的两个新 orphan regression 都使用 24 位虚构 instance，无法验证生产格式；现有 semantic PASS 不证明这一运行行为正确。HISTORY-AGGREGATE-REPAIR-VERIFICATION.md 对 24 位 candidate 校验的肯定结论被本次契约证据纠正，该快照不能按原记录直接进入交付。

最小修复建议：

- 保留 historical receipt IsPhysicalKey 的 24 位语义；在 instance 扫描使用明确的 32 位小写 hex 校验，避免全局改成 32 位破坏 receipt 读取。
- 仅修改 Editor/AICodedbManagerActionJournal.cs 和 Tests/Editor/AICodedbManagerUiTests.cs。
- 修正两个既有 orphan fixture 的 ID；必要回归覆盖合法 32 位 READY / 已归属 PROVISIONING、32 位 orphan 的 legacy / current-index 与 retained early-return、24 位非法 instance，以及合法 24 位 receipt 目录仍可读取。
- retained 路径使用生产 reader 与可归属 fixture，不仅向 UI 注入 recoveryAvailable=true。现有完整 producer retained-marker/effects fixture 缺口须在冻结修复范围时明确能补到何种证据。

修复不要求改写真实历史；修正后 S29 的旧 orphan 应得到归属冲突，而不是合法目录格式错误，Install 仍应阻塞。

## F-02 — 恢复策略 / 提示缺口：多条失败历史没有明确准入结果

Journal 保留 failedInstallCount == 1 条件；两条失败历史会失去可恢复 Index / Result。单纯修 F-01 或 stale SessionState 不会使多条历史恢复成为可用路线。

不以“取最后一条 / 最新一条 retained”作为修复方案：计数中包含 FailedCandidateEffectsRetained 和 failed INSTALL cleanup PENDING，两者权限不同；部分仍有未闭合 effects。需要区分每条历史是否已安全闭合，并返回明确受阻原因。

这是后续恢复策略与可解释性任务，当前不将它扩成 F-01 的实现范围。用户需决定：保持多历史拒绝并明确提示，或单独设计全量认证闭合后的聚合准入。不能把 count != 1 直接放宽成任意历史可 Install。

## 真实历史：有意保持的阻塞

只读检查当前 index 有四个 resolved markers，无 current-action 文件：176147...、d8c736...、dc7267... 是 CommandTerminal；f14c05... 是 FailedCandidateEffectsRetained。

三个实际实例：

| Instance | State | Originating INSTALL action |
| --- | --- | --- |
| 330b7a972a7649259409fbce4de8ca56 | PROVISIONING | 73c9d6a0a8ba4df0898721265ec515d6 |
| 5a6ff71560234b558e1a42148b680a77 | PROVISIONING | f14c0524af324b7a802335a393483fa0 |
| d620abbab0334a2d9c49e59888c1ef55 | READY | dc72675bc8e54b4daaf82592115f2448 |

已检查的 index legacy Package 目录只有 d8 action；compact 73c9 action 目录不存在，resolved markers 中也无 73c9。此证据支持继续把 330b 的归属当作未证明，不代表全系统任意位置都已穷举，也不允许推断 73c9 = d8。

这是用户已延期的历史恢复问题。F-01 修复只能恢复正确识别与提示，不能承诺旧 S29 立即出现 Install。

## 已交付包与人工证据

本次重新读取 manifest.json / packages-lock.json，二者均指向：
file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-package-mismatch-recovery-9179d8a/review/com.rice.ai-codedb。

ZIP SHA256 重新核对为：80f0a6caa55b1486a65da2862f038c09e3e5d18c59e4629625d93417e0190663，与交付记录一致。

该 extraction 没有 FindUnownedProvisioningCandidate 新增代码，仍有单条 failedInstallCount gate 和 stale session 同 action-id 才替换的旧条件。因此 F-01 不是此前旧包截图问题的根因；它是后续未交付源码引入的正常路径误阻塞。

人工基础检查沿用用户对话报告。本次没有重新运行 Unity、NUnit、真实 Install / removal / reinstall，也没有将旧包人工结果升级为新源码 PASS。

## Payload fixture 阻断的有限结论

核对对象仅为此前报错的 poc.42 coordinator entry，不是完整 payload admission / artifact closure。

| 对象 | payload / generation 声明 SHA256 | 实际 coordinator SHA256 |
| --- | --- | --- |
| 当前工作树 | 5a61242e336fac40ac5ce94729d71c676272f65510993481c80a0ee71651ed00 | 928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09 |
| HEAD 9179d8a | 928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09 | 本次未单独导出 HEAD blob 计算；当前文件在此路径无 git dirty 标记 |
| 已交付 extraction | 928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09 | 928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09 |

工作树 generation manifest 自身哈希匹配 payload 声明，但其中 coordinator entry 与文件不匹配；materializer:1320–1322 会拒绝这一组合。两个 manifest 是既有 dirty 文件。不是本次 attribution 修复引入的 coordinator 源码变化，也不是已交付包在这一项上的不匹配证据。

后续 focused validation / 交付应使用隔离的 HEAD payload baseline，并只带入接受的源码快照；这属于另行冻结的验证 / 交付步骤。不能从 dirty 工作树重新出包或通过整体恢复 / 重写 manifest 掩盖差异。本次没有重新执行 fixture、改 hash、生成 payload 或出包。

## 诊断快照

四文件 SHA256 与前两轮最终快照一致：

```text
878fc673f814e9f209d56ecd50c19fb810fcda59f159d24dca35132520efc040  Editor/AICodedbManagerActionJournal.cs
e5a43316fb801b9e10f83a0141d441ca6a6006d119e60d88232b71a668ced5ca  Editor/AICodedbManagerWindow.cs
26a73953659cf640801aee08b9f64613ffa1aba9e55ad501e2157cfa6e2448f4  Editor/AICodedbHostPayloadMaterializer.cs
ca16ddb8fd5068693dbc85532caa9130e10df426aed6922356d564c5b01dcef5  Tests/Editor/AICodedbManagerUiTests.cs
```

以上是读取与静态契约分析；未运行生产 journal reader、Unity / NUnit 或 focused 功能测试。未创建子 agent，也未修改 roadmap / GitHub Project。

## 建议顺序

1. 用户处置 F-01：建议授权上述两文件窄范围修复与必要回归，修复前冻结完整边界。
2. F-02 保持独立策略事项；旧 73c9 历史恢复继续延期。
3. 稳定源码通过只读复审、用户接受后，再对齐隔离验证与交付；全新工程连续 golden path 是后续人工操作阶段。

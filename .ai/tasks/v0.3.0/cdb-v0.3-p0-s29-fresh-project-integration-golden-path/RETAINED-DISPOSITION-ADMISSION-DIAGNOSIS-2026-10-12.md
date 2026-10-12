# S29 — 保留处置与 Manager 准入识别不一致

日期：2026-10-12。
状态：READ_ONLY_DIAGNOSIS_COMPLETE / REPAIR_SCOPE_PROPOSED。
源码基线：`b76957a9dbcae9b00eff73775a97c4e8f33ae785`。
来源：用户要求继续梳理成因，并优先降低不影响当前版本的旧 candidate 的处理优先级。
本轮只读分析与证据登记；源码修复、子 agent、交付和真实操作尚未启动。

## 结论与对先前分析的纠正

旧 `330b7a972a7649259409fbce4de8ca56` 的原 Manager action 归属仍未恢复，
但不能因此断言它没有后续处置。它已有 schema 2 / FAILED_PREPARATION
removal intent `35db5b76947741278dceeef1d98990c7`。
2026-10-09 的 RETAINED-CANDIDATE-RECOVERY-DIAGNOSIS.md 和
REAL-RECOVERY-PREFLIGHT-20261009.md 已记录这项 authority；本轮重新核对了实物。

Manager 的 FindUnownedProvisioningCandidate 只检查原 action id 是否在
authenticated journal/marker 的 knownActionIds 内。它不检查独立有效的
removal intent，因此原 action 缺失会让已绑定保留内容仍被判为 Conflict。
此 Conflict 恢复为 recovering session，主按钮标签为空，入口消失。

后端 Assert-InstanceNextChangeAdmission 则先通过 Get-InstanceRemovalIntents
验证并收集 retained instance，之后才拒绝未绑定实例。两者用于判定实例是否
已被处置的证据集合不一致。这是当前已确认的生产分支缺口；是否能安全放行
本项目仍受完整 intent、共享 wrapper、holder、当前包/selection 等检查限制。

原 action 结果与当前 effects 处置应分开：历史失败/未知保持原样；
已验证不影响当前版本的保留 effects 可降为历史提示。不能直接把 73c9…
加入已知 Manager action 集合、推断它等于 d8c…，或凭 intent 文件存在跳过验证。

## 本轮只读证据

- intent SHA256：`aa6dfb83231fadfc8fc6d1d1ecc963c4053414ede28bacb8bcfb3d810c7c8039`，
  与 2026-10-09 记录一致。
- 清单 46 项：25 个文件哈希匹配、21 个目录存在；没有报告缺失或漂移。
- 在旧实例与 poc.39 generation 两个限定根目录内，未发现清单之外的条目；
  旧 instance manifest、generation manifest 哈希与 intent 声明匹配。
- current / last-known-good instance 均为 `d620abbab0334a2d9c49e59888c1ef55`；
  host current / last-known-good 均为 poc.42；activation operation 为 COMMITTED / INSTALL。
- 旧实例 retained Editor lease 指向 PID 200188，该 PID 当前不存在。
  本轮 process 查询中仅命中了自身诊断 PowerShell，不据此宣称完整 holder gate PASS。
- 旧 originating action `73c9d6a0a8ba4df0898721265ec515d6` 没有已检查位置的
  compact receipt / resolved marker；实际 d8c… INSTALL 参数未携带 origin IDs。
  这条旧历史不能改写成成功或重新归属。

以上为文件/引用/hash 与有限进程观测，不是执行完整 production intent validator、
backend preflight、Unity/NUnit 或真实 Install。未验证 authority_fingerprint 重算、
所有祖先路径/holder 语义和当前包下的完整 stable-wrapper handoff。

## 必须同时明确的两个限制

1. **多失败历史呈现。** 当前 journal 会把 d8c… 的 failed INSTALL/PENDING 与
   f14c… 的 FailedCandidateEffectsRetained 分别计入 failedInstallCount；
   Empty 返回仍仅在 count == 1 时提供 Index/Result。单纯排除已处置的 330b…
   不保证出现 Install。不能取最后一次失败来代表全部 effects，需区分原命令
   结果与已验证的当前 effects 分类，并显式保留多历史限制/原因。
2. **当前 runtime/package 对齐。** 当前包 generation manifest 为 `944fab…`，
   selected poc.42 instance/host 仍为 `227326…`。后端 retained wrapper 的
   COMMITTED handoff 使用当前 Package authority 验证 activation/selection。
   已发现历史保留处置不等于当前包 Ready 或真实新操作已获准。

## 建议冻结的修复边界

目标：让 Manager 将“原 action 结果”“当前 candidate effects 处置”与
“具体下一操作的后端准入”分别表达。优先使用已有处置 authority，避免要求
恢复全部旧 action 历史或先物理清理。只有有效、无冲突、对当前操作无影响的
保留内容才降为提示；无处置、漂移、当前/正在激活对象、holder 或共享资源
冲突继续阻断并说明具体原因。

优先触及 AICodedbManagerActionJournal.cs、AICodedbManagerWindow.cs 与
AICodedbManagerUiTests.cs，复用并整理现有 retained 验证逻辑；不新增历史恢复服务。
这是范围建议，不是承诺两三文件即可覆盖完整后端证据。实施前需冻结
producer/reader/UI 决策映射、确切验证权限与是否需要共享验证接口；若无法
在窄范围中复用 authority，应返回设计选择，不逐层追加临时 bypass。

最低必要回归：原 action 无记录但有效 inert retention；无 intent；错误 project/
instance、hash 或清单漂移；当前 selection/activation 冲突；无法证明安全的
holder/共享 wrapper；多条失败历史中已处置与未处置混合；关闭重开的一致性。
必须经过真实 journal reader 到 session/action presentation，不能只注入
recoveryAvailable=true；纯语义编译或单个 fixture 不构成整条恢复路线 PASS。

不在本范围：改写旧 receipt/manifest/intent、恢复 73c9…=d8c…、物理删除 candidate、
关闭外部进程、runtime generation 修复、重复 Install/Uninstall、出包/切引用、
Unity 自动化、远端 Project 更新或稳定后归档执行。后续各阶段沿用原授权流程。

本轮仅新增本记录并补充旧诊断的指向，未修改产品源码、测试或运行时状态。

# S29 当前人工操作单 — 2026-10-06

状态：UNITY_COMPILE_FAILED / HUMAN_SESSION_PAUSED。Package 导入已进行，但编译出现 CS1503；下面的测试及 Install/Uninstall/reinstall 阶段不得继续。本操作单保留为历史授权，不能用于自动重试。

当前处理入口：[COMPILE-FIX-GRANT.md](COMPILE-FIX-GRANT.md)。用户已同意同一 S29 的编译接口修复、定向复审和重新出包，并已人工确认此工程关闭。现进入既定 Coder 源码修复阶段，尚未重新激活人工验证。保留当前工程和原失败产物，不换工程，不修改冻结包。

用户已授权这一整轮，无需每个按钮再确认授权。本操作单及 TASK.md 最新人工授权是当前入口；旧清单的 DOCUMENT_FIX_BLOCKED 是 Coder 检查器历史状态，F-D01 已由 Planner 定向只读复核关闭。原失败报告保留，不改写为 PASS。

## 1. 新建空工程并导入精确 Package

- 人工通过 Unity Hub 新建、打开：`G:\RiceProgram\UnityCodeDB\UnityFreshInstallValidationProjectS29`。
- 推荐 Unity 2022.3.x，记录实际版本，不要求固定 patch。若目录已有工程/集成，不覆盖、不清理，先反馈。
- 不复制旧工程的 Assets、Packages、ProjectSettings、AIWork、.codex、Library 或运行态。原工程和旧未归属候选保持不动。
- Package Manager -> Add package from disk，仅选择：
  [package.json](G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/package.json)。
- Source commit：306f329b8f51f82695dccc5e8de67c6bcea5320e；版本 0.3.0-preview.5；generation poc.39。
- ZIP SHA-256：717700a9ffe7af7ace1e937e29be3491ca13ae61aeb7b350678de257ea949141。不要导入工作树或旧包，不覆盖/修改包。
- 等待编译完成，须为 0 个 C# error；发生编译错误即停止后续测试/安装，并返回完整首条错误。

## 2. 一批 focused EditMode 测试

打开 Test Runner -> EditMode。程序集：Rice.AICodedb.Editor.Tests；命名空间：Rice.AI.Codedb.Editor.Tests。

只选择下列 16 个方法组及它们的全部 TestCase 参数，Run Selected 一次，预期共 43 cases（19 新增 + 24 紧邻）。不 Run All，不选择整个类或 Category，也不用宽泛前缀替代精确选择。

| 实际测试类 | 精确方法名 | cases |
| --- | --- | ---: |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_CurrentSupervisorOnlyNamespaceOffersFirstInstall | 1 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_BlockedMigrationCannotBecomeFirstInstall | 2 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_InvalidCurrentContractCannotBecomeFirstInstall | 1 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_SupervisorOnlyClassificationRejectsAdditionalEvidence | 4 |
| AICodedbEditorLifecycleTests | InstanceOrigin_LegacyAbsenceAndNullRemainReadable | 1 |
| AICodedbEditorLifecycleTests | InstanceOrigin_ValidAdditiveAttributionRemainsReadable | 3 |
| AICodedbEditorLifecycleTests | InstanceOrigin_InvalidAdditiveAttributionFailsClosed | 6 |
| AICodedbProductStatusTests | CachedNotIntegratedSnapshot_OffersInstallWithoutCheckingOrUninstallHistory | 1 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_NoIntegrationOffersFirstInstallWithoutUninstallHistory | 1 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_MissingDesiredStateAloneDoesNotProveFirstInstall | 3 |
| AICodedbEditorLifecycleTests | CurrentUninstalledPendingState_ExposesInstallWithoutEditorLease | 1 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_CompleteSuppressesLeaseAndAutomaticCleanup | 1 |
| AICodedbEditorLifecycleTests | ControlContractMigration_UninstalledKeepsInstallSemanticsWithoutAdmissionDryRun | 1 |
| AICodedbProductStatusTests | CachedUninstalledSnapshot_PreservesInstallStateWithoutLiveScan | 1 |
| AICodedbProjectSettingsTests | ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation | 5 |
| AICodedbProductStatusTests | ResolvePrimaryAction_ExposesOnlyOneContextualUserAction | 11 |

全部参数和方法名沿用已修正清单，没有添加测试。43 是计划数量，不是已运行 PASS。

若包测试不显示，仅在这个新工程的 `Packages/manifest.json` 顶层合并：

```json
"testables": ["com.rice.ai-codedb"]
```

保留其他依赖和已有 testables；不要改 Package/asmdef。Test Framework 不可用、数量/选择不同、超出 300 秒或任何测试失败，停止返回 Planner，不自行装额外工具、调整测试或重跑。

## 3. 同一次 Unity 会话的黄金路径

编译及 focused tests 通过后继续，无需中途关闭 Unity 或再次申请每步授权。

1. 打开 Tools -> Rice AI -> Codedb -> Manager。初态应是未集成/Not installed，可用 Install CodeDB；不要把初态伪造为 Uninstalled。
2. 点击 Install CodeDB 一次，确认该新工程。等待稳定 Ready。保留结果文本及截图；exit 0 或弹窗消失本身不是 Ready。
3. 在 Ready 下切换页签、重绘、关闭再打开 Manager，一次只读观察响应和状态；不点额外维护按钮。
4. More actions -> Uninstall CodeDB from Project，确认移除当前新工程的 CodeDB 集成一次，等待真实 Uninstalled。这里不移除 UPM Package，不卸载共享 Node/Provider，也不删除其他项目/全局配置。
5. 在真实 Uninstalled 后点击 Install CodeDB 一次，执行认证重装，等待再次稳定 Ready。记录 cleanup 原样状态；PENDING 不改写为 COMPLETE，unknown effects/未证明的活动状态不继续重装。
6. 正常关闭 Manager 并退出 Unity，记录是否卡顿、约多久退出以及有无异常。不强杀进程或重开重试。

正常 Ready 的移除按钮就是 Uninstall CodeDB from Project。Remove CodeDB Integration 属于 obsolete identity 路径，本轮不人为制造该状态。

每个产品状态转换最多观察 300 秒。按钮缺失、依赖缺失、Needs attention、持续 Checking/超时、原始 native failure、unknown effects、移除或重装异常，均在首个问题停止后续动作，返回原始信息。失败时仍可正常关闭 Unity；不要反复 Configure/Install、换包、删状态、补绑候选或重启系统。

## 4. 返回这些精简证据

- 实际 Editor 版本、导入路径、C# error 数量。
- 43 cases 的选择/通过/失败数量与 Test Runner 截图；若失败给第一条完整错误。
- 首次安装、正常卸载、认证重装各自的终态截图和必要结果文本；保留实际动作/错误，不粘贴全量日志或敏感配置。
- Manager 切换/关闭重开是否正常；Unity 正常退出耗时和异常。
- 未到达阶段标记 NOT RUN；不可得的激活/注册/子进程关闭证据保留 DEFERRED，截图不冒充运行态完整证明。

本轮不额外 Play、做全量回归、查询/MCP/client reconnect、原工程恢复或发布；不用反复重绑 Codex 会话。到首次失败或正常退出终点即停止并回交 Planner。整体 S29/发布 ACCEPT、后续复审及任何修复/重试另行决定。

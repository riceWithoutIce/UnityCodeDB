# S29 Manager 回执修复：人工验证清单

本次源码已 ACCEPT，限定提交和本地出包完成。工程引用已由 Planner 在你
确认 Unity 正常关闭后切换，不需要卸载或重新添加 Package。

工程：G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29

精确 Package：
G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-manager-receipts-poc40/review/com.rice.ai-codedb/package.json

提交：932e3e7ff695019ebebac9d3e7ba2f4b9e205105。
推荐 Unity 2022.3.x，不把补丁版本作为硬门槛。

## 一次打开完成本轮检查

1. 打开上述工程，等待导入和编译完成，确认 Console 为 0 个 C# error。
   如有错误，保留第一条完整错误，停止后续步骤。
2. Test Runner -> EditMode，运行以下 3 组过滤结果，共 9 个方法组 / 41 例。
   每组先确认筛选到的数量再 Run Selected；无需跑整类、全项目或重跑之前
   已通过的 48/11 例。若出现失败，保留完整首条失败与汇总，不自动重试。
3. 全部通过后打开 CodeDB Manager，等待当前观察结束，截取最终状态、
   历史操作提示及可见操作入口。可以保持 Unity 打开用于后续同会话验证。

| 类 | Test Runner 搜索内容 | 方法组 / 例数 |
| --- | --- | --- |
| AICodedbProjectSettingsTests | ManagerReceipt_ | 7 / 38 |
| AICodedbEditorLifecycleTests | LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait | 1 / 2 |
| AICodedbEditorLifecycleTests | ActionContext_NewIdentityResetsStageAndRestoresOuterScope | 1 / 1 |

第一组的完整方法清单：

| 方法 | 例数 |
| --- | --- |
| ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate | 4 |
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage | 8 |
| ManagerReceipt_ConflictWithoutAuthenticatedContextLabelsOriginalUnavailable | 1 |
| ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown | 3 |
| ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory | 4 |
| ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects | 7 |
| ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain | 11 |

## Manager 观察的预期与边界

对已诊断的历史操作 d8c736504562495dbafdd673c6851efb，本轮预期能识别原
Install 失败和 PENDING 遗留影响，不再单纯因三个阶段都声明 action-terminal
而报 resolved marker 冲突。历史 Package 应正确指向原始 compile-fix-70f33f7
产物，或明确说明未知，不应把本次新包误标为原包。

失败候选仍然保留，因此 Needs Attention 可以是正确结果，本轮不要求 Ready。
记录是否有明确的移除入口即可；Overview 不显示按钮不等于所有入口都不存在。

本轮不点击 Install、Remove CodeDB Integration、Redeploy、Upgrade 或 Configure
Dependencies，不进行真实清理、重放、Play、手工删回执/候选。实际移除将根据
新的 Manager 状态单独给出明确操作；源码 PASS 不代表真实移除/重装已成功。

请回报：编译是否 0 error、41 例结果、Manager 最终截图。如计数不符或失败，
直接发截图/完整首条错误，保留现场。无需为回报再次关闭 Unity。

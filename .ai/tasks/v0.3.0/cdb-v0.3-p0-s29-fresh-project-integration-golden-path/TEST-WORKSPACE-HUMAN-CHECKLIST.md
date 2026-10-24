# S29 测试工作区修复：人工验证

源码已 ACCEPT，提交和出包核对完成。你已确认人工关闭 Unity；Planner 已
切换工程引用，无需卸载或重新添加 Package。

工程：G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29

Package：
G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-test-workspace-poc40/review/com.rice.ai-codedb/package.json

提交：332c7ffd510daebb6da6a386d66783d4aabf6bd6。
推荐 Unity 2022.3.x，不把补丁版本作为硬门槛。

## 一次打开，按顺序检查

1. 打开工程，等待导入/编译完成，确认 Console 为0个 C# error。
2. Test Runner -> EditMode，运行下面四组，共24方法组/62例。先运行新
   工作区测试，再验证消费者。任一组失败就停止，不点 Rerun Failed；复制
   第一条完整错误、堆栈及汇总。原始失败与清理错误若同时显示，请都保留。
3. 全部通过后打开 CodeDB Manager，等待观察结束，提供最终状态、历史操作
   提示和可见操作入口截图。可以保持 Unity 打开，无需为回报再关闭。

## 第一组：新工作区（9例）

搜索并运行整个 `AICodedbTestWorkspaceTests` 类，预期7方法组/9例。
覆盖实际工程根、能力探测、无回退、清理边界、状态恢复及异常保留。

## 第二组：S29上下文（3例）

搜索并运行整个 `AICodedbS29ExecutionContextTests` 类，预期2方法组/3例：

- LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait：2例。
- ActionContext_NewIdentityResetsStageAndRestoresOuterScope：1例。

这两项已移出旧 AICodedbEditorLifecycleTests；不要为此运行旧整类。

## 第三组：Manager回执（38例）

搜索 `ManagerReceipt_`，属于 AICodedbProjectSettingsTests，预期7方法组/38例。

| 方法 | 例数 |
| --- | --- |
| ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory | 4 |
| ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects | 7 |
| ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain | 11 |
| ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate | 4 |
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage | 8 |
| ManagerReceipt_ConflictWithoutAuthenticatedContextLabelsOriginalUnavailable | 1 |
| ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown | 3 |

## 第四组：共享会话夹具调用方（12例）

都位于 AICodedbProjectSettingsTests，逐项搜索或多选以下8方法组。
它们直接依赖此次改动的夹具，不要求整个类或全项目回归。

| 方法 | 例数 |
| --- | --- |
| ManagerActionSession_RejectsOverlapAndRetainsResultAcrossWindowInstances | 1 |
| ManagerActionSession_ReloadRestoresUnconfirmedOutcomeWithoutRetry | 1 |
| ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission | 1 |
| ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation | 5 |
| ManagerActionSession_WindowCloseWithCommandRetainsResultWithoutClaimingReady | 1 |
| ManagerActionSession_WindowCloseWithoutCommandKeepsRecoveryAdmissionBlocked | 1 |
| ManagerActionSession_MissingCommandResultCannotReleaseAdmission | 1 |
| ManagerActionSession_UnconfirmedTransportFailureKeepsRecovery | 1 |

## 观察边界

测试目录归属于当前工程 Library/CodeDB/Tests/run-<唯一标识>/，正常结束会
清理各自run目录，父目录可以保留。不要手工清理父目录或旧 Windows Temp。
真实失败候选仍在，因此 Manager Needs Attention 可以正确，本轮不要求 Ready。
暂不点击 Install、Remove CodeDB Integration、Redeploy、Upgrade 或 Configure
Dependencies，不做真实清理/重放/Play。后续操作依据新截图统一安排。

请回报：编译结果、四组各自结果（9+3+38+12）、Manager最终截图。
若数量不符先提供截图，不扩大为整类/全工程 Run All。全部用例在新包上均
待人工运行，先前失败证据保留，不因源码/包字节核对通过而改记PASS。

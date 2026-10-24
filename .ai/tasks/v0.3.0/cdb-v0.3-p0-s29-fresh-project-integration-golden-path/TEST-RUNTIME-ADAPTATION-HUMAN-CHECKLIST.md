# S29 测试运行适配：合并人工验收

状态：HUMAN_REPORTED_TEST_PASS / HUMAN_REPORTED_MANAGER_OBSERVATION_PASS。用户2026-10-08反馈
测试全部通过；详细证据边界见TEST-RUNTIME-ADAPTATION-HUMAN-RESULT.md。
此清单替代前次34方法/80例清单，并补回历史上下文测试。
工程：G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29。
已切换的 Package：.artifacts/s29-test-runtime-poc40/review/com.rice.ai-codedb。
源码提交：3b09859045d0d4547d9ba2cef332a550e8530f99。
版本0.3.0-preview.5 / poc.40不变。无需卸载重装、重启Codex或更改系统设置。

## 一次打开完成

1. 正常打开上述工程，等待导入编译，确认0个C#编译错误。
2. Test Runner -> EditMode，按下列三组运行，共39方法/88例。上下文组现在
   应显示两个独立协程入口，不再是原来的True/False参数节点。
3. 如有失败，保留该组汇总和完整第一条错误/堆栈；不要重复跑失败项或手工
   创建/删除目录。保持工程打开即可反馈，不必为报告结果立即关闭。
4. 全部测试通过后打开CodeDB Manager，等待当前checking结束，切换页签并关闭
   Manager窗口，观察Console/显示是否正常。已有历史失败/PENDING可能保留，
   本轮不承诺Ready、不解除真实历史操作的变更限制。
5. 暂不点击Install、Remove、Redeploy、Configure或任何恢复/重放按钮。观察后
   可正常退出Unity并反馈退出状态。没有自动化Unity执行或系统重启要求。

## 第一组 AICodedbTestWorkspaceTests：整类12方法/17例

验证共享短根、compact和legacy探测、碰撞/归属、失败诊断与清理异常保留。

| 方法 | 例数 |
| --- | ---: |
| TestWorkspace_OwnedRootUsesActualProjectAndProbesCapabilities |1|
| TestWorkspace_ProbesS29DepthUsingProductionPaths |1|
| TestWorkspace_ExclusiveCollisionPreservesExistingOwner |1|
| TestWorkspace_OverlongComponentReportsExactPathWithoutFallback |1|
| TestWorkspace_UnavailableCapabilityFailsBeforeBodyWithoutFallback |3|
| TestWorkspace_CleanupRejectsOutsideTargetAndChangedOwnership |1|
| TestWorkspace_ReparseBoundaryIsRejectedBeforeTraversal |1|
| TestWorkspace_PrimaryFailureRestoresRegisteredScope |1|
| TestWorkspace_PrimaryAndCleanupFailuresRemainSeparate |1|
| TestWorkspace_CleanupOnlyFailureCannotPass |1|
| TestWorkspace_ProfileProbesFullPathsBeforeBodyAndRemovesProbeDirectories |2|
| TestWorkspace_LegacyCapabilityFailureReportsExactPathAndRestoresScope |3|

## 第二组 AICodedbS29ExecutionContextTests：整类3方法/3例

| 方法 | 例数 |
| --- | ---: |
| LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait_Terminal |1|
| LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait_Nonterminal |1|
| ActionContext_NewIdentityResetsStageAndRestoresOuterScope |1|

## 第三组 AICodedbProjectSettingsTests：仅以下24方法/68例

不要运行包含无关用例的整个类。可按方法名搜索选中运行，记录每组结果。

| 方法 | 例数 |
| --- | ---: |
| ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory |4|
| ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects |7|
| ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain |11|
| ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate |4|
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage |8|
| ManagerReceipt_ConflictWithoutAuthenticatedContextLabelsOriginalUnavailable |1|
| ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown |3|
| ManagerActionJournal_RestoresOriginalIdAfterFullExitAndPackageReplacement |1|
| ManagerActionJournal_CorruptOrConflictingIndexFailsClosed |1|
| ManagerActionRecovery_ClaimWithoutTerminalStaysUnknownAndStartFailureIsDistinct |1|
| ManagerActionJournal_HistoricalUnknownMarkerReleasesOnlyBoundPendingStage |1|
| ManagerReceipt_CompactMissingOrWrongLayoutIsConflict |6|
| ManagerReceipt_DuplicateOrPrefixCollisionCannotReplaceAdmission |2|
| ManagerReceipt_CompactFullIdentityAndLocationsFailClosed |4|
| ActionContext_FlowsCapturedProjectAndPackageToWorker |1|
| ManagerActionSession_RejectsOverlapAndRetainsResultAcrossWindowInstances |1|
| ManagerActionSession_ReloadRestoresUnconfirmedOutcomeWithoutRetry |1|
| ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission |1|
| ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation |5|
| ManagerActionSession_ProviderSuccessKeepsCommandAndNeedsAttentionSeparate |1|
| ManagerActionSession_WindowCloseWithCommandRetainsResultWithoutClaimingReady |1|
| ManagerActionSession_WindowCloseWithoutCommandKeepsRecoveryAdmissionBlocked |1|
| ManagerActionSession_MissingCommandResultCannotReleaseAdmission |1|
| ManagerActionSession_UnconfirmedTransportFailureKeepsRecovery |1|

源码复核、出包闭包和身份核对均通过；用户已反馈测试全部通过。Manager打开截图
显示历史回执冲突；用户随后确认各页签切换、关闭Manager无明显异常。真实集成
仍未通过，不能把Manager关闭解释为Unity已退出，也不推断精确Console错误计数。

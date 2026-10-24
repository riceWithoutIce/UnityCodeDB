# S29 本轮人工检查：编译、新增用例、Manager 状态

前置已完成：源码 ACCEPT、提交 651f9b3、本地导出及精确产物 201 项
隔离测试通过。工程 Package 引用已切换，无需再次添加或卸载 Package。

工程：G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29

精确 Package：
G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-failed-install-recovery-poc40/review/com.rice.ai-codedb/package.json

推荐 Unity 2022.3.x；不把补丁版本作为本轮硬门槛。

1. 打开上述工程，等待导入和编译结束，确认 Console 为 0 个 C# error。
   如有错误，保留完整首条错误并停止后续操作。
2. 在 Test Runner 的 EditMode 中运行下面 4 个方法组，共 11 例。
   之前已经通过的 48 例无需重跑；无需运行全类或全工程。
3. 打开 CodeDB Manager，等待当前观察结束，提供最终状态及操作按钮截图。
   失败候选仍被保留，因此本检查点不要求 Ready。先确认是否呈现明确的
   卸载/移除入口与原失败状态，不点击任何修改项目的按钮。

| 测试类 | 方法组 | 例数 |
| --- | --- | --- |
| AICodedbProjectSettingsTests | DirectInstallArguments_BindActualActionBeforeAdmission | 1 |
| AICodedbProjectSettingsTests | InstallEntryAndManager_RequireConfirmedCompleteSuccess | 5 |
| AICodedbProjectSettingsTests | InstallEntry_MissingOrMalformedResultDoesNotReconcile | 1 |
| AICodedbEditorLifecycleTests | UnselectedRetainedInstance_BlocksAutomaticConvergence | 4 |

本检查点不执行 Install、Remove CodeDB Integration、Uninstall、Configure
Dependencies、Upgrade、Play 或手工删除文件。真实卸载会写入恢复意图和
项目集成终态，需在明确目标与当前 UI 后单独说明一次具体操作。

请回报：编译是否 0 error、11 例是否全部通过、Manager 最终截图。
可以保持 Unity 打开，供后续同一会话内继续验证；无需为提交或审核再次关闭。
本轮通过也不等同于真实卸载/重新安装、MCP Ready 或整个 S29 验收通过。

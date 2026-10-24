# S29 结果语义修复：一次人工验证清单

状态：待人工执行。源码已 accept；源码复核、提交、出包、字节检查通过。
真实 C# 消费者执行尚未通过，不能据此宣称 S29 集成验收完成。

## 工程与产物

- 打开现有工程：`G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`。
- 工程引用已切换，无需重新安装 Package 或手工修改 manifest。
- Package：`G:/RiceProgram/UnityCodeDB/.artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb/package.json`。
- 提交：`d56f0e507b48af24a39f23411c06dbdd4e093084`。
- 版本仍为 `0.3.0-preview.5` / `poc.40`；本轮身份以提交和产物路径区分。
- Unity 2022.3.x 为推荐环境；工程当前记录 2022.3.62f3，不额外锁定补丁版本。

## 1. 编译与聚焦测试

等待编译完成，确认没有新的 C# 编译错误。若有，记录第一条完整错误，
停止后续验证，不继续点击安装类操作。

在 Test Runner 的 EditMode 中查找 `AICodedbProjectSettingsTests`。
运行下表五个方法组的全部参数用例，共 45 例；无需重跑整个测试程序集。
可以逐个搜索方法名后运行，避免搜索过滤器遗漏参数用例。

| 方法组 | 用例数 |
| --- | ---: |
| ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate | 8 |
| MaterializerResults_ProductionWriterFeedsHistoricalRecoveryAndSession | 1 |
| MaterializerResults_UnsupportedShapeCannotResolveHistoricalChain | 20 |
| MaterializerResults_IncompleteEvidenceIsNotKnownFailure | 8 |
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage | 8 |

生产写入器测试会启动一个隐藏、受限的 PowerShell 测试进程，调用本次 Package
内的真实结果写入函数，然后把输出交给真实 C# 解析和恢复逻辑。它不执行真实
Install/Upgrade，不读取真实历史回执；临时文件使用现有项目 Library/cdt 测试工作区。
该方法内部覆盖六个输出场景，但在 Test Runner 中只计 1 例。

若测试失败，保留第一个失败用例的完整错误和堆栈，不反复重跑。

## 2. Manager 观察

仅在测试通过后，打开 CodeDB Manager，等待正常观察结束：

- 原来的 `A resolved action marker conflicts with its original receipt` 不应再
  因本次已支持的 Install/DryRun/Upgrade 历史链出现。
- 原 Install 的失败和 `PENDING` 提示仍应保留；不得变成安装成功、清理完成。
- `Needs attention` 本身不代表这次修复失败；本轮不要求历史残留已清理或整体 Ready。
- 切换各页签、关闭 Manager，确认没有新增异常；关闭 Manager 不等于关闭 Unity。
- 本轮不点击 Install、Upgrade、Remove、Reinstall、Configure Dependencies 等
  修改项目的按钮，也不删除历史记录。若出现其他阻断，保留原始提示供只读核对。

## 3. 一次性反馈

请反馈：编译是否无错误；五组共 45 例是否通过；历史回执冲突提示是否消失；
原失败/PENDING 是否仍有正确说明；页签与窗口关闭是否正常。
附 Manager 最终截图；如失败则附完整错误。完成前不必反复重启 Unity。
本轮结果只用于关闭该修复的测试/观察门槛，真实卸载重装仍属于后续独立操作。

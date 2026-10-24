# S29 源码已接受后的人工清单（本地准备，不是执行授权）

状态：DOCUMENT_FIX_BLOCKED / TARGET_CONFIRMED / AWAITING_HUMAN_AUTHORIZATION。

这份清单在操作上替代旧 HUMAN-CHECKLIST.md 的 Package 路径和测试方向；旧 RESULT.md、HUMAN-CHECKLIST.md、失败与超额证据保留。源码已经 ACCEPT/提交，但下面的编译、测试、Unity 和真实安装流程尚未运行，也尚未由本次交付授权放行。

## 目标已确认；执行仍待人工授权

- 人工已确认的新空工程目标目录：G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29。确认不代表目录已存在；本轮未检查、创建或打开该目录。
- 当前 TASK 已记录该精确目标目录确认。仍须由 Planner/User 独立授权人工创建/打开、同一次可见 Unity/C# 会话及真实 Install/Remove/Reinstall；不要把目录确认或本清单当作执行授权。
- 工程由人工新建、打开，不能复制旧 UnityFreshInstallValidationProject 或其配置、缓存、.codex、AIWork、运行态。
- 推荐 Unity 2022.3.x；不是固定 patch/version 门槛，不因不同版本制造第二套产品行为。
- Coder 不启动/绑定 Unity，不使用 MCP/CUA/BatchMode 或隐藏 Editor，也不操作真实进程。
- 原工程及 fd14a3cfa964437d9192f787df68bcf3 未绑定候选保留；恢复/清理/采纳/补绑 DEFERRED。新工程成功不等于旧工程修复。

## 只导入这份 Package

- Source commit：306f329b8f51f82695dccc5e8de67c6bcea5320e。
- ZIP：G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/com.rice.ai-codedb.zip
- ZIP SHA-256：717700a9ffe7af7ace1e937e29be3491ca13ae61aeb7b350678de257ea949141
- 已从该 ZIP 提取并通过闭包的唯一 Package 根：G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb
- 在 Unity Package Manager 选择 Add package from disk，使用：
  [package.json](G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/package.json)
- 不从工作树 G:/RiceProgram/UnityCodeDB/com.rice.ai-codedb 导入；不导入旧 consumed candidate；不覆盖/修改 ZIP 或新 Package，不再导出/重解压覆盖 review。
- 包版本 0.3.0-preview.5；payload/generation=poc.39；sequence=39；bootstrap=1；Owner Identity=2；control=v0.3-control/v2/schema1。
- 已接受十五文件的源字节 digest：7a3556f686f359b93070e606a4bf51895c45a42773e22cb77cecf33d5006ffd8。
- 当前没有任何实际工程 Ready、安装、卸载、重装或发布 PASS。

## 一次会话中的编译与测试准备（仅在后续授权后）

人工只在确认的新空工程操作，保持同一可见 Editor 会话，不重复 Configure、不按步骤切换 Codex 会话/重新绑定，不安装替代 Unity MCP。

1. 完成 Package 导入并等待编译结束。记录 Editor 版本、精确 Package 路径和编译结果；有编译错误立即停止，不改源码或换旧包。
2. 使用 Editor 自带 Test Runner 的 EditMode。包内测试程序集为 Rice.AICodedb.Editor.Tests，namespace 为 Rice.AI.Codedb.Editor.Tests。
3. 若包测试未显示，在后续授权覆盖的新工程里保留 manifest.json 既有内容，仅把 com.rice.ai-codedb 纳入顶层 testables。例如顶层成员：
   `"testables": ["com.rice.ai-codedb"]`
   若已有数组，合并不覆盖；不要改 Package/test asmdef。若 Test Framework 不可用或需要额外依赖授权，停止返回 Planner，不自行安装全局工具。
4. 仅多选下表 16 个方法组，Run Selected；不 Run All，不选整个 class/Category/S28PhaseC，也不以宽泛 prefix 搜索全部命中代替精确选择。全部该方法的 TestCase 参数均在下表范围。
5. 计划为 43 个参数化用例：新增 19 + 直接邻近 24。若实际列表/数量不同，保留原始差异并停止，不能调整测试来制造匹配。测试失败不自动重试，也不继续真实安装。

### 新增 19 个用例：八个精确方法选择器

| 完整方法选择器 | 参数 / 用例数 |
| --- | --- |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ProjectIntegrationState_CurrentSupervisorOnlyNamespaceOffersFirstInstall | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ProjectIntegrationState_BlockedMigrationCannotBecomeFirstInstall | ObsoleteReinstallRequired；InvalidOrAmbiguous，2 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ProjectIntegrationState_InvalidCurrentContractCannotBecomeFirstInstall | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ProjectIntegrationState_SupervisorOnlyClassificationRejectsAdditionalEvidence | "legacy-supervisor"；"foreign-contract"；"activation-record"；"unknown-runtime"，4 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.InstanceOrigin_LegacyAbsenceAndNullRemainReadable | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.InstanceOrigin_ValidAdditiveAttributionRemainsReadable | "INSTALL"；"UPGRADE"；"REINSTALL"，3 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.InstanceOrigin_InvalidAdditiveAttributionFailsClosed | "action"；"action_id"；"operation_id"；"extra"；"missing-operation"；"not-object"，6 |
| Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.CachedNotIntegratedSnapshot_OffersInstallWithoutCheckingOrUninstallHistory | 无参数，1 |

### 直接邻近 24 个用例：八个精确方法选择器

| 完整方法选择器 | 参数 / 用例数 |
| --- | --- |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ProjectIntegrationState_NoIntegrationOffersFirstInstallWithoutUninstallHistory | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ProjectIntegrationState_MissingDesiredStateAloneDoesNotProveFirstInstall | "AIWork/codedb"；"AIWork/.runtime/codedb/instances"；"AIWork/.runtime/codedb/control"，3 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.CurrentUninstalledPendingState_ExposesInstallWithoutEditorLease | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ProjectIntegrationState_CompleteSuppressesLeaseAndAutomaticCleanup | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_UninstalledKeepsInstallSemanticsWithoutAdmissionDryRun | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.CachedUninstalledSnapshot_PreservesInstallStateWithoutLiveScan | 无参数，1 |
| Rice.AI.Codedb.Editor.Tests.AICodedbProjectSettingsTests.ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation | Ready；NeedsAttention；Uninstalled；NotIntegrated；MissingPrerequisite，5 |
| Rice.AI.Codedb.Editor.Tests.AICodedbProductStatusTests.ResolvePrimaryAction_ExposesOnlyOneContextualUserAction | 下列十一组全部，11 |

ResolvePrimaryAction 的四个参数依次为 product state、attention reason、recoveryAvailable、actionInFlight；期望 bool 也列出：

1. (Starting, None, true, false) -> false
2. (Ready, None, true, false) -> false
3. (NeedsAttention, None, true, false) -> false
4. (NeedsAttention, ControlContractReinstallRequired, true, false) -> true
5. (NeedsAttention, InstanceIdentityReinstallRequired, true, false) -> true
6. (NeedsAttention, ControlContractInvalidOrAmbiguous, true, false) -> false
7. (Uninstalled, None, false, false) -> true
8. (NotIntegrated, None, false, false) -> true
9. (NotIntegrated, None, false, true) -> false
10. (Uninstalled, None, true, true) -> false
11. (MissingPrerequisite, ControlContractReinstallRequired, true, false) -> false

这些名称/参数来自上述精确 Package 的 Tests/Editor/AICodedbEditorLifecycleTests.cs 与 AICodedbManagerUiTests.cs，不是工作树或旧包。清单生成时未运行任何用例。

## 同一次可见 Unity 会话的真实流程（待独立授权）

阶段等待/超时与允许动作由下一份人工授权明确；未授权不得开始。不得凭“仍在 Checking”无限等待、反复点击或自动续行。出现失败/超时按下节停止。

1. 编译与上述 focused tests 均通过后，打开 Tools/Rice AI/Codedb/Manager。
2. 新工程应是 NotIntegrated/“Not installed”与可用 Install CodeDB，而不是伪造的 Uninstalled/history。只有真实后台进行时才能 Checking；若终态停在 NeedsAttention/Checking，保留证据停止。
3. 人工点击一次 Install CodeDB 并确认当前新工程。观察真正稳定 Ready 和选中实例/generation=poc.39；命令 exit 0、提示框消失或按钮可点本身不是 Ready 证据。依赖缺失/Native failure/unknown effects 不得按成功处理或自动清理。
4. 当前健康 Ready 集成，使用 Manager 的 More actions -> Uninstall CodeDB from Project，并确认当前新工程，观察 Uninstalled。这里是任务所说移除当前集成的正常入口。
   Remove CodeDB Integration 是 obsolete identity 的另一条 guarded 路径；新健康工程不应人为制造旧身份/停进程让该标签出现。若入口语义/状态不符，停止请 Planner 对齐，不能用旧工程替代。
5. 在真实 Uninstalled 后再点击一次 Install CodeDB，执行认证卸载状态后的重装路径；不要用 NeedsAttention 下的修复/旧身份菜单冒充重装，也不重复 Configure。观察再次稳定 Ready。记录 cleanup disposition；没有证据不能擅自把 PENDING/unknown effects 写成 COMPLETE。
6. 人工正常关闭新工程的 Unity 窗口。不要强制杀进程/改 runtime/清理 lease，也不在旧工程操作。若只能证明窗口消失而没有足够 shutdown 证据，应保留 shutdown/ownership 验收 DEFERRED，而非猜测所有子进程已安全退出。
7. 到该正常关闭终点停止会话；不追加 Play、全量回归、查询/维护场景、原工程恢复或发布流程，不重新打开 Editor 自动重试。

## 最小脱敏证据

- 新目录人工确认与后续 grant；Editor 版本、实际 imported package.json 路径。
- 编译结果；43 focused case 的选择清单、pass/fail/count 与必要的原始失败，不输出全量日志。
- 每次动作一次：动作名、观察时间、Manager 产品终态/错误类别、是否真实 in-flight、选中 generation/实例的脱敏观察、cleanup disposition。
- 若提供现有 CODEDB_S12_EVIDENCE，只给相关完整脱敏结构化行/截图（阶段明确），不读出 token、全局配置、原始命令行、原始 runtime 文档或 unrelated process。
- 测试与真实流程证据分段；若测试 setup 影响计数，保留基线/差值和归因，不清零/伪造 instrumentation 或把历史计数当成 Manager 当前违规。
- 正常 shutdown 的现有脱敏 entry/return/disposition 证据；不可得即 unavailable/DEFERRED。不做未授权进程探针。

## 停止及回交

编译/Test Framework/测试失败、Case/Package 不符、依赖或身份/授权障碍、Ready 未收敛、原始 native failure/unknown effects、移除/重装/关闭异常：在首个独立问题停止，保留精简原始证据并返回 Planner。不要修改源码/元数据、切换包、手工补绑/清理候选、查询旧工程、自动重跑/强制终止或绕开 Unity/权限。

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: DOCUMENT_FIX_BLOCKED / TARGET_CONFIRMED / AWAITING_HUMAN_AUTHORIZATION
Next notification: UnityCodeDB v0.3 Planner
Next action: 复核 F-D01 文档修正及既定源提交绑定 Package/正常移除入口与 focused 范围，再单独授权一次人工会话。
Human decision or authorization required: 人工创建/打开、C# focused tests、真实 Install/移除/Reinstall/正常关闭；后续 Verifier、修复或发布另行决定。

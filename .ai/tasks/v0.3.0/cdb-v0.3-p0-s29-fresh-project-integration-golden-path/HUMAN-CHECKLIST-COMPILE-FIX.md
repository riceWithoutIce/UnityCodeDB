# S29 编译修复后的人工操作清单

状态：PREPARATION_COMPLETE / AWAITING_HUMAN_ACTIVATION。仅交付准备；实际编译、测试与真实动作全部 NOT RUN。本清单不是人工执行授权。

## 唯一工程与新 Package
沿用人工已确认、最后明确关闭的 G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29。不要新建/复制第二个工程；Coder 未查看或修改工程。仅在后续整次人工会话授权后，由人工打开并切换此工程的 Package 引用。

- Source commit：70f33f7e9f7b39b63aaf9c1d4eedba122f67799a。
- ZIP：G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-compile-fix-70f33f7/com.rice.ai-codedb.zip
- ZIP SHA-256：c314ad2fd0a72215e14990a285d3e5488a224668add751c62f62d5ba3a49aa85
- 唯一 package.json（人工 Package Manager / Add package from disk 目标）：
  G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-compile-fix-70f33f7/review/com.rice.ai-codedb/package.json
- 包版本 0.3.0-preview.5；generation=poc.39。推荐 Unity 2022.3.x，不设固定 patch/version gate。
- 旧 .artifacts/0.3.0-preview.5-s29-source-306f329/review/com.rice.ai-codedb/package.json 有已知编译失败，不能继续作为本轮人工入口。旧 ZIP/review 全部保留，只读、不覆盖；不从 dirty 工作树导入。
- 人工切换时保留其他依赖/testables；不自动改 manifest/lock/config，不重复 Configure，不安装替代 MCP/工具。引用不符或不能切换时停止回 Planner。

## 一次 Run Selected 的精确范围（仅待后续授权）
程序集 Rice.AICodedb.Editor.Tests；namespace Rice.AI.Codedb.Editor.Tests。下表是实际 fixture class + 精确方法名，不是源文件名；完整选择器为 namespace.class.method。
原 HUMAN-SESSION-GRANT.md 的 16 方法组/43 cases 及全部 TestCase 参数、fixture owner 不变，仅加下述编译边界两组共 5 cases。预期 18 方法组、48 planned cases = 24 authored-new + 24 adjacent，均 NOT RUN。
选择每个方法及其全部现有 TestCase 参数；只 Run Selected 一次，不 Run All/整类/Category/宽泛前缀。新增拒绝组的四个参数是 missing / null / wrong-type / null-object。

### Authored-new：10 方法组 / 24 cases
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
| AICodedbEditorLifecycleTests | InstanceOrigin_InterfaceDictionaryUsesRequiredStringBoundary | 1 |
| AICodedbEditorLifecycleTests | StrictJson_RequiredStringRejectsInvalidInterfaceValue | 4 |

### Adjacent：8 方法组 / 24 cases
| 实际测试类 | 精确方法名 | cases |
| --- | --- | ---: |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_NoIntegrationOffersFirstInstallWithoutUninstallHistory | 1 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_MissingDesiredStateAloneDoesNotProveFirstInstall | 3 |
| AICodedbEditorLifecycleTests | CurrentUninstalledPendingState_ExposesInstallWithoutEditorLease | 1 |
| AICodedbEditorLifecycleTests | ProjectIntegrationState_CompleteSuppressesLeaseAndAutomaticCleanup | 1 |
| AICodedbEditorLifecycleTests | ControlContractMigration_UninstalledKeepsInstallSemanticsWithoutAdmissionDryRun | 1 |
| AICodedbProductStatusTests | CachedUninstalledSnapshot_PreservesInstallStateWithoutLiveScan | 1 |
| AICodedbProjectSettingsTests | ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation | 5 |
| AICodedbProductStatusTests | ResolvePrimaryAction_ExposesOnlyOneContextualUserAction | 11 |

仅当后续授权允许且包测试未显示，人工在本工程 Packages/manifest.json 顶层 testables 合并 com.rice.ai-codedb，保留其他内容，不改 Package/asmdef。Test Framework 不可用、选择/数量不同或测试失败，保留差异后停止，不装依赖、不改用例、不自动重跑。

## 规划一整次人工会话；本轮不执行
1. 人工将同一工程引用切到上述新 package.json。等待编译并确认 0 C# errors；先前 source ACCEPT、closure 或本清单都不是编译 PASS。失败即停止。
2. 编译通过后执行上述 18 组/48 cases 的一次 focused Run Selected；记录实际选项/count/pass/fail。未通过不得继续真实动作。
3. 打开 Tools/Rice AI/Codedb/Manager；确认真实前置状态。人工一次 Install CodeDB，观察 stable Ready 和 selected generation poc.39。exit 0/提示框消失不等于 Ready；依赖缺失/身份异常/unknown effects 停止，不制造 Uninstalled/history。
4. 健康 Ready 的正常项目入口是 More actions -> Uninstall CodeDB from Project；确认当前工程，观察 authenticated Uninstalled。不要用 obsolete-only Remove CodeDB Integration，也不要制造 obsolete identity、删除共享 Provider/global MCP 或误停外部进程。
5. 真实 Uninstalled 后一次 Install CodeDB，作为 authenticated reinstall，观察再次 stable Ready。记录 cleanup disposition；PENDING/unknown 不冒充 COMPLETE。不得重复 Configure 或反复重绑 Codex/会话。
6. Ready 后只读观察 Manager 各页签、重绘与关闭/重开响应；不增加查询/维护/Play 场景，不制造计数或运行态证据。
7. 人工正常退出同一 Unity 工程，记录现有脱敏 shutdown entry/return/disposition；没有证据则 unavailable/DEFERRED。不强制终止、不清理 lease/runtime、不开第二个 Editor、不自动再开或重试。

每个 transition/focused batch 最多 300 秒。首个错误、歧义效果或超时即停止下游 mutation、保留精简原始证据并回 Planner；工程/进程控制归人工，不无限等待/反复点击/自动续窗。

## 最小回交
记录实际新 package.json/source/ZIP、Editor 版本、0-error 编译、48-case selection/count/result、每次动作与终态/selected generation/cleanup、Manager 响应及正常退出的脱敏证据。只提供相关截图或完整结构化证据行；不导出全日志、token、原始 runtime/global config/命令行或无关进程。
编译、focused tests、真实动作、UI/退出分开归因。旧失败工程/未绑定候选的恢复/清理/采纳/补绑仍 DEFERRED；新流程不能证明旧候选已修复。

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: PREPARATION_COMPLETE / AWAITING_HUMAN_ACTIVATION
Next action: Planner 准入新 artifact/清单后决定一整次人工会话授权。
Human authorization required: 人工 open/Package switch/compile/tests/真实动作；后续 findings、S29/release ACCEPT。不自动续行。

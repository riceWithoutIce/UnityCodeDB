# S29 process identity — 人工 Unity 验收清单

源码：544be4f7e339acefb47137b188cdc85e22483efb（2026-10-14）。
状态：HUMAN_REPORTED_PASS（2026-10-15）；结果和限制见同前缀 HUMAN-RESULT.md。
交付前置结果以同前缀 DELIVERY-RESULT.md 为准。
工程：G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29。
预期 Package 引用：
file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-process-identity-544be4f/review/com.rice.ai-codedb。
ZIP SHA256：65c0bcbb46f138941b5becf4dd59abbebb6528524db7ef5cff91c3e6c152e16a。

## 操作

1. 等交付结果确认两处引用切换完成后，由用户打开上述同一个 Unity 工程。
   等待编译完成，确认无新增编译错误；不需要重新装包或点击 Install/Remove/Upgrade。
2. 在 EditMode Test Runner 中分别搜索并运行以下六个普通测试方法。
   前四个属于 AICodedbHostPayloadMaterializerPreflightHandoffTests：

   - RemovalPreflight_LifecycleRefusesIncompleteAndMalformedPermits
   - RemovalPreflight_RequiresOneAvailableLineAndHandoff
   - RemovalPreflight_RejectsMissingOrDuplicateHandoff
   - RemovalIntegrationArguments_RequireHandoff

   后两个属于 AICodedbS29ExecutionContextTests：

   - RemovalPreflightFailureDiagnostic_IsBoundedRedactedAndRetainsCause
   - RemovalPreflightFailureCache_PreservesBackendReasonWithoutDispatch

   不将 RemovalPreflight_ConsumesIsolatedProductionNamespaceRefusal 纳入这次
   普通 Unity 清单；它需要显式隔离 fixture 参数，已在精确出包的仓库隔离链中
   验证。不要为运行它而手动安装或改真实 runtime。若误选后出现 Requires the
   explicit isolated RemovalNamespaceOnly fixture，记录为未配置的夹具项，
   不能把它当作本次六项测试的通过证据或新产品编译错误。
3. 打开 Manager，观察当前状态和诊断；关闭再打开一次，并切换页签。
   确认无异常。若出现移除预检拒绝，保留完整可见原因或截图；可接受的原因包括
   原进程仍在、身份不可读取或 child 证据缺失。诊断应能指出 child 的操作记录
   或 current/stale owner 角色，而不是将 reused/live/unknown 混写成同一原因。
4. 正常关闭 Unity，反馈是否完成。CleanupMono 再现时单独记录发生条件和是否
   需强制关闭，不据此扩展本轮修复；不要求为增加样本反复重启或重跑测试。

## 通过与限制

人工结果请分别说明编译、六项 Test Run、Manager 开关、页签与退出情况。
原始 Test Runner 计数/XML 与用户文字报告是不同证据；没有提供时不补造计数。
本轮不要求 Manager 达到 Ready 或出现 Install：当前 selected42/target43 与
缺失 child 等历史阻断仍可能存在。身份分类本身不授予移除权限。

用户反馈后，父 agent 执行有界只读核对，确认精确引用及相关日志/状态归因；
不自动 Install/Remove/Upgrade、终结进程、修复历史或重新出包。
真实移除/迁移/安装与 release 验收保持独立，S29 仍为 PARTIAL。

# S29 编译修复后：当前人工操作授权 — 2026-10-07

状态：HUMAN_SESSION_AUTHORIZED / AWAITING_HUMAN_START。用户已同意下面整轮；无需逐按钮再申请批准。实际编译、测试和真实动作尚未回报，不能由出包或源码 PASS 推断。

本文件是当前执行入口。旧 HUMAN-SESSION-GRANT.md 保留为已失败/暂停的历史授权；[HUMAN-CHECKLIST-COMPILE-FIX.md](HUMAN-CHECKLIST-COMPILE-FIX.md) 的 AWAITING_HUMAN_ACTIVATION 是出包时历史状态，现在只提供已核对的精确测试表。本授权优先，不修改这两份历史文件。

## 1. 同一工程切换到唯一新 Package

- 沿用 `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`，不要新建、复制或清理第二个工程。
- 新入口：[package.json](G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-compile-fix-70f33f7/review/com.rice.ai-codedb/package.json)。人工打开同一工程，在 Package Manager -> Add package from disk 选择这个文件，使 CodeDB 引用切换到新目录。
- 若在 Unity 仍关闭时人工改引用，只改本工程 Packages/manifest.json 的 com.rice.ai-codedb 依赖，值为：

```json
"com.rice.ai-codedb": "file:G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-compile-fix-70f33f7/review/com.rice.ai-codedb"
```

- 保留其他依赖、testables 和工程状态；packages-lock.json 交给 Unity 正常更新，不手工造锁文件。不移除 Package、不删 Library/运行态，不修改包或共享 Node/Provider。Planner 不代改这些文件。
- Source：70f33f7e9f7b39b63aaf9c1d4eedba122f67799a；版本 0.3.0-preview.5；generation poc.39。ZIP SHA-256：c314ad2fd0a72215e14990a285d3e5488a224668add751c62f62d5ba3a49aa85。
- 旧 source-306f329 包有已知编译失败，不能继续使用。若打开时尚显示旧错误，先完成新引用切换，确认 resolved 路径包含 compile-fix-70f33f7；以这次新包编译结果为准，不把历史 Console 条目算作新结果。
- 推荐 Unity 2022.3.x，不把固定 patch/version 当硬门槛。确认新包编译 **0 个 C# error** 后才继续；新引用编译仍报错时保留完整首条错误并停止后续阶段。

## 2. 一次精确 focused EditMode batch

Test Runner -> EditMode；程序集 Rice.AICodedb.Editor.Tests，namespace Rice.AI.Codedb.Editor.Tests。

按[已核对测试表](HUMAN-CHECKLIST-COMPILE-FIX.md#一次-run-selected-的精确范围仅待后续授权)精确选择 **18 个方法组和全部参数，共 48 planned cases**（24 authored-new + 24 adjacent），Run Selected 一次。表中的 fixture 是实际测试类，不是文件名。原 16 组/43 例加这两组：

- AICodedbEditorLifecycleTests.InstanceOrigin_InterfaceDictionaryUsesRequiredStringBoundary：1。
- AICodedbEditorLifecycleTests.StrictJson_RequiredStringRejectsInvalidInterfaceValue：4（missing、null、wrong-type、null-object）。

不 Run All、不选整类/Category、不以宽泛前缀替代精确选择。若 Package 测试隐藏，人工仅在本工程 manifest.json 顶层 testables 合并 com.rice.ai-codedb，保留现有项，不改 Package/asmdef。Test Framework 不可用、选择/count 不符、任何失败或超时即停止回交，不自行装工具、修测试或重跑。

## 3. 全通过后，同一次 Unity 会话贯通

1. 打开 Tools -> Rice AI -> Codedb -> Manager。确认本工程的真实前置状态和 Install CodeDB 按钮；没有预期入口或出现未归属/歧义效果时停止，不伪造 Uninstalled 或历史。
2. 人工点击 Install CodeDB 一次，确认当前工程。等待稳定 Ready、selected generation poc.39，保留终态文本/截图。exit 0 或弹窗消失不等于 Ready。
3. 健康 Ready 下，More actions -> **Uninstall CodeDB from Project**，确认当前工程，观察 authenticated Uninstalled。这是卸载 CodeDB 管理的项目集成及其项目级注册，不是移除 UPM Package，不卸载共享 Node/Provider，不删除别的项目/全局 MCP 配置。不用 obsolete-only Remove CodeDB Integration 代替。
4. 真实 Uninstalled 且 Install 可用、没有未确认效果时点击 Install CodeDB 一次，作为重装；等待再次稳定 Ready。cleanup 按实际 disposition 记录，PENDING 不冒充 COMPLETE；拒绝/未知效果即停止，不能靠反复点击消除。
5. Ready 后只读切页签、观察重绘、关闭/重新打开 Manager 一次。观察响应及状态；不添加查询、维护、Play、Configure 或 Codex/client reconnect 场景。
6. 人工正常退出同一 Unity 工程，记录退出用时、是否被 Manager 阻塞，以及已有可见脱敏 shutdown 记录（如无则 unavailable）。不强制终止、不清理 lease/runtime、不重启 Windows/Codex、不再开第二个 Editor。

阶段通过后直接继续，不需要中途关闭 Unity 或等 Planner 再批准下一按钮。可以分段回报进度，但不自动增加任何重跑预算。

## 4. 精确预算与停止条件

- 新包 import/compile 1 次；focused batch 1 次；首次 Install 1 次；正常项目 Uninstall 1 次；Uninstalled 后 Install 1 次；Manager 只读观察 1 次；正常人工关闭 1 次。
- 每个产品 transition/测试 batch 最多 300 秒。初始人工打开/选择包不是 agent 自动启动等待门槛；没有无限 Checking 等待或自动续窗。
- 首个新包错误、测试/数量失败、缺失入口/依赖、歧义或未确认效果、身份拒绝、Ready/卸载/重装失败或超时，停止所有下游变更，保留精简原始证据并回 Planner。安全正常关闭仍允许；修复、重试、新出包需另行决定。
- 本授权不包含自动 UI/MCP/CUA/BatchMode、agent 启动或进程探针、全量回归、源码/元数据改动、其他工程/旧候选恢复或清理、全局配置/共享依赖变更、Git/远端/发布或整体 S29 ACCEPT。

## 5. 一次回交这些证据

实际新包路径和 Editor 版本；新包编译是否 0 error；48 例实际选择/count/pass/fail；三个真实动作终态/Ready/Uninstalled/cleanup；Manager 响应；正常退出用时/可见脱敏结果。截图只证明可见状态，不补造缺失的运行态、MCP 注册或进程关闭证明。

不要导出全日志、token、原始 runtime/global config/命令行或无关进程。首失败或成功正常退出即回交。该结果不自动证明旧失败工程/未绑定候选恢复或整体发布通过。

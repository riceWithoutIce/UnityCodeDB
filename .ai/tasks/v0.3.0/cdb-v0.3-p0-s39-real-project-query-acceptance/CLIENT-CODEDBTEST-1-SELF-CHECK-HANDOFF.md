# CodedbTest_1 target-session self-check — read-only handoff

Date: 2026-10-21. Status: PREPARED_NOT_DISPATCHED / MCP_CALLS_ZERO.
Purpose: let a fresh Codex session rooted at `CodedbTest_1` report its own
launch-context facts before any MCP retry. This is environment diagnosis only,
not CodeDB acceptance.

## Instruction to send to the target session

```text
你负责 UnityCodeDB v0.3 的 CodedbTest_1 只读启动环境自检。
本轮不做 CodeDB 查询，不调用任何 codedb_status、codedb_text_search 或其他
CodeDB 服务；不启动 wrapper、worker、Provider、probe 或 CLI，不重试 MCP。
不修改项目、配置、环境变量、runtime、Unity 状态，不 Install/Reinstall/Uninstall，
不启停外部进程，不做 OS trace，不创建其他会话。

第一步报告当前会话实际 cwd。必须是外部
G:\RiceProgram\Test\CodedbTest\CodedbTest_1 Unity 工程根目录；如果不是，
立即停止，报告实际 cwd，所有 MCP 调用次数为 0。

在 cwd 正确后，只读检查并报告以下内容：

1. 项目级 `.codex/config.toml`
   - 注册名应为 `codedb-codedbtest-1`；
   - command 应为 `node`；
   - cwd 应为 `.`；
   - args 应为 `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]`；
   - startup_timeout_sec 应为 120。
   只报告匹配/不匹配和必要字段，不输出用户/全局配置全文。

2. manifest / lock
   - 引用应解析为 `file:../../Packages/237c72d/com.rice.ai-codedb`；
   - 报告 manifest、lock 和实际解析目录是否一致；
   - 不修改 manifest、lock 或 Unity 生成文件。

3. 当前会话的 Node 解析信息
   - 只读报告 `node` 的实际可执行路径和 `node --version`；
   - 可报告 `process.execPath` 与 `process.cwd()`；
   - 只报告 PATH 中是否能解析到 node，不输出完整 PATH；
   - 只报告 LOCALAPPDATA 是否存在，不输出其值；
   - 不修改 PATH 或其他环境变量。

4. v0.3 选定实例和 Package 身份
   - 读取 `AIWork/.runtime/codedb/control/current-instance.json`；
   - 读取其指向的 instance.json；
   - 报告 project_identity、instance_id、activation_epoch、generation、
     package_version、state，以及 pointer/instance 是否一致；
   - 预期 project_identity：
     `sha256:df651cdb0a4933afe68d959f08b5a1f00648a2631f598f606c7d2f756b9ff89e`
   - 预期 instance_id：`d442deda8b914a7bad6af7dd79e2d50c`
   - 预期 activation_epoch：`5b1c035c0fd44ea095d045ab4f5c79ba`
   - 预期 generation/package：`poc.43` / `0.3.0-preview.5`
   - 预期 state：`READY`
   - 本地身份只能作为磁盘证据，不能称为 MCP 响应身份。

5. 入口文件存在性和哈希（只读）
   - wrapper 应位于项目根下的
     `AIWork/codedb/wrapper/codedb-project-wrapper.mjs`；
   - 报告 wrapper 是否存在及 SHA-256；预期：
     `a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e`；
   - 不 import、执行或修改 wrapper。

6. 本会话可见工具
   - 只报告工具清单中是否存在精确目标命名空间
     `mcp__codedb_codedbtest_1__*`；
   - 如果目标命名空间未暴露，立即停止；不要使用
     `mcp__codedb_balance__*`、`mcp__codedb_mcp__*` 或其他 CodeDB 服务替代；
   - 本轮无论是否暴露目标工具，CodeDB 调用次数都必须为 0。

7. 目标会话日志（若当前会话能读取）
   - 只读查找与本会话／`codedb-codedbtest-1` 相关的启动、stderr、退出摘要；
   - 不导出完整日志、完整环境、token、argv 或无关 runtime 内容；
   - 找不到日志也要明确报告“未发现”，不能推断 wrapper 未启动。

结束时按以下格式返回：

- 实际 cwd：
- 项目配置：匹配 / 不匹配 / 未读取；
- manifest/lock：匹配 / 不匹配 / 未读取；
- node 路径与版本：
- process.cwd：
- LOCALAPPDATA：存在 / 不存在 / 未检查；
- selected pointer / instance：匹配 / 冲突 / 未读取；
- wrapper：存在、SHA-256 / 缺失 / 未读取；
- 目标工具命名空间：暴露 / 未暴露；
- CodeDB 调用次数：status=0，query=0，其他=0；
- 本会话日志摘要：
- 发现的冲突或缺失：
- 限制：哪些只是本地静态证据，哪些没有观测到。

任何路径、身份、配置或工具清单冲突都只报告并停止，不修复、不重试。
Ready 或本地磁盘身份不能替代 MCP 响应身份。本轮不形成查询通过、性能、
升级或发布结论。
```

## Parent-side boundary

The parent has only prepared this handoff. It has not opened, messaged or
started a target session, and has not invoked any MCP tool. The target session's
self-check may reduce cwd/Node/config noise, but shell observations still do not
prove the exact environment inherited by a host-spawned MCP child. If the
self-check is clean and the target namespace remains absent, retain that as a
host startup-boundary finding; do not treat the self-check as CodeDB acceptance.

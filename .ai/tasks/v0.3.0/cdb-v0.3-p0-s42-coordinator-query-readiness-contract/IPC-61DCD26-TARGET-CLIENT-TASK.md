# 61dcd26 Package 目标客户端有界验收

日期：2026-10-22。状态：AUTHORIZED_FOR_HUMAN_FORWARDING / NOT_EXECUTED。
用户已同意本轮一次 status → 一次固定查询。由用户将本任务转交现有
CodedbTest_2 会话执行；开发会话不代调其他项目服务、不发送会话消息。
本轮为新交付后的独立观测，不续跑任何历史失败 Attempt。

## 执行位置与范围

在现有外部 CodedbTest_2 Unity 工程根目录执行。记录实际 cwd，以及宿主
明确提供的当前聊天 ID；未提供则记为未提供，不扫描或猜测。
人工起点：用户报告新 Package 无编译错误；Manager 首次 Needs attention，
数分钟后 Ready，界面明确表示该 Ready 为缓存观测。不要自行刷新以改变起点。

只读核对以下文件：项目 Packages/manifest.json、Packages/packages-lock.json、
.codex/config.toml、选中 pointer 及对应 instance.json、原始固定查询探针，以及
manifest 所引用 Package 的 package.json 和 Editor/AICodedbSupervisorBridge.cs。
相对 Package 引用以 Packages/manifest.json 所在目录为基准解析。

预期基线：

- manifest/lock 的 CodeDB 引用均为
  `file:../../Packages/61dcd26-s42-ipc-compile-repair/com.rice.ai-codedb`。
- 引用 Package 的版本为 `0.3.0-preview.5`；Bridge SHA-256 为
  `b2fe1c6564ea0bf5f386eaf40e1ca6ace7643f925203ff520ffb202500a2bfe5`。
- 注册名 `codedb-codedbtest-2`，command=`node`，cwd 解析为当前项目根；args 为
  `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]`，超时 120 秒。
- 选中 pointer：`AIWork/.runtime/codedb/control/current-instance.json`。
- project_identity：`sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c`。
- instance_id：`a492a5e936c14e4da3ed7e4cc7c8c16c`。
- pointer activation_epoch：`063aa347f49a4b9f955a5447f293a0ac`。
- generation=`poc.44`，instance state=`READY`，Package=`0.3.0-preview.5`。
- pointer SHA-256：`1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`。
- instance manifest SHA-256：`61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced`。
- generation manifest SHA-256：
  `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`。
- 原始探针 SHA-256：`d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`；
  第 5 行 marker 为 `CODEDB_S39_CWD_POC44_TEST2`。

当前工具目录必须实际暴露 `mcp__codedb_codedbtest_2__codedb_status` 与
`mcp__codedb_codedbtest_2__codedb_text_search`。任一前置冲突或目标工具缺失，
立即停止并报告调用次数 0。不得替换命名空间、手动启动组件、修改配置或重连。

## 有界调用：每项最多一次

1. 调用目标 `codedb_status({})` 一次，保留完整原始响应。要求成功、状态兼容
   READY，Package、generation 和 generation manifest 符合基线；STARTING、
   超时、STALE、离线、降级、错误或明确身份冲突均立即结束本轮。
2. 仅当 status 通过，调用目标 `codedb_text_search` 一次：

   ```json
   {"query":"CODEDB_S39_CWD_POC44_TEST2","path_glob":"Assets/CodeDBValidation/CodeDBQueryProbe.cs","regex":false,"limit":5}
   ```

   要求唯一命中预期路径、第 5 行及完整 marker；错误、无命中或错误命中均停止。
   不重试、不等待、不追加 status。调用后复读 pointer，记录原文字节是否稳定。

## 回执与身份界限

分别报告实际 cwd、工具可见性、只读核对、每项调用次数、参数、完整原始响应、
命中路径/行号/文本和 pointer 稳定性，并分别判定 status、固定查询和正式响应身份。
响应缺少 project_identity / instance_id / activation_epoch 时记为 `not provided`；
磁盘身份、wrapper 名称或 config 路径不能替代正式响应身份。缺少字段是证据限制，
不是新的功能阻断条件。

首次异常即停止。不得刷新、重连、Install、Uninstall、Repair、Restart、Start/Stop、
进程/lease/日志扫描或额外 RPC；不得修改/删除探针、meta、pointer、注册、运行时或
Package 文件。即使两次调用通过也立即停止。本轮不关闭启动超时、心跳、Unconfirmed、
身份交接、性能、升级或发布验收；不执行 S41 A→B 实验。

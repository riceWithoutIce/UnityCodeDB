# S40 CodedbTest_2 重装后真实客户端验收任务

## 执行范围

用户已同意继续重装后的真实目标客户端验收。请在 CodedbTest_2 工程根目录
新建的正常 Codex 会话执行本任务，无需再次询问本任务列明的只读检查和两次
条件调用授权。保留既有客户端连接；不要为了验收关闭、重连或复用旧连接。
本任务不是继续旧实例的 S39 验收，不创建新 Unity 工程。

最多调用目标 `codedb_status` 一次、目标 `codedb_text_search` 一次；后者仅在
前者成功且无目标身份冲突时执行。首次失败即停止，不重试、不替代服务。
开发会话只准备任务；真实响应必须来自执行本任务的目标项目会话。

## 最小前置核对

1. 报告实际 cwd，确认是 CodedbTest_2 Unity 工程根目录。会话 ID 仅记录宿主明确
   提供、可归属当前聊天的值；没有则写未提供，不扫描其他会话猜测。
2. 只读核对 `Packages/manifest.json` 和 `Packages/packages-lock.json` 的 CodeDB
   引用均为 `file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb`。
   项目 `.codex/config.toml` 注册名应为 `codedb-codedbtest-2`；command 为 node，
   cwd 解析为本工程根目录，args 为
   `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]`，超时 120 秒。
   无需检查或输出用户/全局配置，也不修改配置。
3. 读取 selected pointer `AIWork/.runtime/codedb/control/current-instance.json`
   和其引用的 `instance.json`，核对下表。instance manifest 哈希必须匹配 pointer
   所载值。不要假定 instance.json 有 activation_epoch；该字段取自 pointer。

| 本轮新实例基线 | 预期值 |
| --- | --- |
| project_identity | `sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c` |
| instance_id | `a492a5e936c14e4da3ed7e4cc7c8c16c` |
| activation_epoch | `063aa347f49a4b9f955a5447f293a0ac` |
| generation_id | `poc.44` |
| instance state / package_version | `READY` / `0.3.0-preview.5` |
| instance manifest SHA-256 | `61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced` |
| generation manifest SHA-256 | `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb` |

保留开始时 pointer 原文字节或哈希用于结束复核。开发会话准备任务时 pointer
SHA-256 为 `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`；
该值是准备时磁盘证据，不替代客户端响应身份。

4. 检查本会话真正暴露的精确命名空间 `mcp__codedb_codedbtest_2__*`。
   预期六个工具：context、find、read、search、status、text_search。
   status 或 text_search 不可见则停止，不调用其他服务；其余工具数量/名称
   仅如实报告，不为与本任务无关的工具清单差异额外增加阻断条件。
   前置身份、引用或 cwd 冲突则停止。不得调用 `codedb_balance`、`codedb_mcp`
   或其他项目工具补位。

## 两次有界调用

第一步仅调用一次：

`mcp__codedb_codedbtest_2__codedb_status({})`

保留完整原始响应（含 isError、文本和 timing）。宿主错误、超时、工具错误、
不可用状态或明确身份冲突立即停止，query 调用为零。成功响应中的 Package、
generation 和 generation manifest 应与本轮基线一致；明确指向旧实例
`fe3b257859f34023a9e290db3b2ad457` 的活跃实例响应属于冲突，不能继续查询。

若响应没有正式 project_identity / instance_id / activation_epoch 字段，逐项写
“未提供”，不把缺字段本身认定为调用失败，不以磁盘值填充响应身份，也不凭
配置路径中的实例字符串宣称正式身份字段充分。存在路径等关联线索可单独报告。

第一步成功且无冲突后，仅调用一次：

`mcp__codedb_codedbtest_2__codedb_text_search`

```json
{"query":"CODEDB_S39_CWD_POC44_TEST2","path_glob":"Assets/CodeDBValidation/CodeDBQueryProbe.cs","regex":false,"limit":5}
```

预期命中 `Assets/CodeDBValidation/CodeDBQueryProbe.cs` 第 5 行：

```csharp
        public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";
```

保留完整原始响应并与本地样本路径、行号、文本核对。样本准备时 SHA-256 为
`d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`。
本地读取不替代查询；无命中、错误或超时即停止，不增加补救查询。完成后只读
复核 pointer 与本轮开始时一致；若变化，保留响应但将新实例归属结论记为不充分。

## 结果与停止边界

直接在本会话回复：实际 cwd、可确认的会话 ID、精确工具名/可见数量、各调用
次数、完整原始响应、命中位置和文本、pointer 是否稳定，以及身份字段的来源
与缺失项。分别给出目标工具/状态可用、查询功能、新实例响应身份充分性的结论。
不要求主动读取进程/lease；若宿主已有明确可归属连接信息，可引用并说明来源，
不得将既存 lease 或安装探针当成本次真实客户端响应。

任务结束即停止。失败时仅报告既有证据和宿主直接提供的错误，不扫描原生日志、
轮询、重连、重新启动组件或进行补救。不要手动执行 wrapper/CLI/Provider，
不要 Install/Uninstall、启停 Unity/外部进程、改文件/配置/环境/runtime、清理、
委派、创建其他会话、发送消息、提交、push 或发布。

本任务不重新验收旧 MCP 存活时重装、不测第二轮卸载/安装、不证明物理清理或
性能/升级/公共发布。安装内部探针与 Manager 缓存 Ready 均不替代本轮调用。

# 原生日志有界提取 01：归属检查停止

日期：2026-10-23。状态：STOPPED_SOURCE_ATTRIBUTION_MISMATCH / NO_BODY_EXTRACTION。

## 授权范围

用户同意继续已有原生日志及动作记录的有界、脱敏提取。不改变 Unity 或 CodeDB 状态；先归属，不能归属则停止，不以其他工程记录替代。

## 实际执行

1. 读取已有诊断盘点、人工 timeout 回执及 Paths 源码，定位标准 Unity 日志候选与动作存储规则。
2. 仅检查标准 Unity `Editor.log`、`Editor-prev.log` 的文件元数据。未读取 prev 正文或日志头。
3. 对 `Editor.log` 一次只读打开，以共享读写/删除方式读取前 65536 字节，检查启动参数中的 `-projectPath`。没有跟踪新增日志。
4. 启动参数存在，但规范化后与目标 CodedbTest_2 不匹配。立即停止；没有扫描日志正文、其他日志或实际动作存储。

候选源记为 `<LOCALAPPDATA>/Unity/Editor/Editor.log`；不记录另一个工程的路径、完整命令行或日志文本。

| 字段 | 实际值 |
| --- | --- |
| header_bytes_read | 65536 |
| project_argument_found | true |
| target_project_matches | false |
| length_at_open | 8249544 bytes |
| header_sha256 | ad081cc34af738df763d076969c571549f257e18fb65e4b52e814d1eb2d64486 |
| extract operation/timeout/context | NOT_RUN |
| manager action storage scan | NOT_RUN |
| log re-read / alternate source search | 0 |

文件是活动日志；元数据检查时大小与打开时大小不同，不将两次值视为同一原子快照。未记录精确读取 UTC，不借用另一次检查的时间替代。

## 结论与下一步

前 64 KiB 的启动参数不能作为本轮 CodedbTest_2 归属证据；不能由此排除文件后续存在目标工程日志段。此前把日志头不匹配扩大为整份日志不可用的表述过强，在此修正。这不证明目标 Unity 未运行，也未判断目标是否使用自定义日志路径。没有获得本次 Upgrade 的触发/终态、timeout 的服务端原因或 UI/cache 同步证据。

下一步只需先定位目标 Unity 实际日志路径及其会话归属，再对齐固定文件的读取窗口/字节预算。可由目标工程会话提供已有的明确日志路径；若需要只读进程启动信息定位，应先明确仅筛选目标 Unity、只输出项目/日志归属和必要进程身份，不输出完整命令行，不扫描正文或探测 CodeDB 组件。不得自动改用 prev 或另一个 Unity 工程日志。

本轮无需关闭 Unity，没有 MCP/RPC、观察器、刷新、重试、重连、安装、恢复、进程探测/控制、测试或产品改动。首次归属异常后的停止不构成根因结论。

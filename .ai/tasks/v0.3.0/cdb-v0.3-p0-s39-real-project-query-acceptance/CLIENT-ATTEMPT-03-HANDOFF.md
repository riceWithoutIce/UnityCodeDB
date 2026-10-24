# S39 Attempt 03 — fresh CodedbTest_1 actual-client handoff

Date: 2026-10-21. Status: ATTEMPT_03_STOPPED / WRONG_WORKSPACE / TARGET_CALLS_ZERO.
The human returned actual cwd CodedbTest_0 instead of CodedbTest_1. See
CLIENT-ATTEMPT-03-RESULT.md. The instruction below is historical, not a retry
grant; do not paste it again. Next preparation: CLIENT-ATTEMPT-04-HANDOFF.md.
Prerequisites: DIAGNOSTICS-DELIVERY-RESULT.md and
CODEDBTEST-1-FIRST-INSTALL-RESULT.md. Earlier attempts remain stopped.

Keep Unity in its current state. The human opens a fresh Codex chat whose
workspace is the external CodedbTest_1 project root and sends the instruction
below. Do not use the development checkout or an old failed chat. No restart,
re-Install, registration edit or environment adjustment is a precondition.
This parent has not created/messaged the acceptance chat or invoked target MCP.

## Instruction to send in the fresh target-root chat

```text
你负责 UnityCodeDB S39 Attempt 03：新工程 CodedbTest_1 的真实 Codex 客户端验收。
当前目录必须是用户创建的外部 CodedbTest_1 Unity 工程根目录，不能是 UnityCodeDB 开发库。
用户在这个新会话发送本指令，即授权一次目标 codedb_status 和成功后的单次有界查询，
包括正常 MCP 连接自身的 lease/log 和受管依赖启动。无需再申请这两个调用。
本轮是新工程首次真实客户端验收，旧 Attempt 01/02 保持停止，不续跑。

先只读核对实际 cwd、.codex/config.toml、manifest/lock、selected pointer 和 instance.json。
注册应为 codedb-codedbtest-1；command=node，cwd="."，
args=["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]，
startup_timeout_sec=120。manifest/lock 引用：file:../../Packages/237c72d/com.rice.ai-codedb。
project_identity：sha256:df651cdb0a4933afe68d959f08b5a1f00648a2631f598f606c7d2f756b9ff89e
instance_id：d442deda8b914a7bad6af7dd79e2d50c
pointer activation_epoch：5b1c035c0fd44ea095d045ab4f5c79ba
generation：poc.43；Package：0.3.0-preview.5；实例应为 READY。
pointer 路径：AIWork/.runtime/codedb/control/current-instance.json
pointer SHA-256：06a1afc91f9bea6a15b6d19130a166c5aa2c8926edd976ae36c61cbf7c37af1d
对应 instance.json 实际 SHA-256 应匹配 pointer：
a329f604fa5c048026622f0e8736dfd6f732adf9009931023125a01b67ccceeb
稳定 wrapper SHA-256：a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e
activation runtime_contract_sha256：750f54d6bd187b51a436e28002ea2099b9ce0a21b9f9fe6543ecc4197269b84a
字段取自其实际 authority；不要假定 instance.json 含有 activation_epoch 或 runtime_contract_sha256。

检查本会话真正暴露的目标项目工具，预计 mcp__codedb_codedbtest_1__*，以实际名称为准。
不要使用 codedb_balance、codedb_mcp 或其他项目服务替代。
记录可观察到的注册来源；未检查的用户/全局配置明确写未验证，不输出完整配置。
身份/哈希/引用冲突或工具未暴露立即停止，查询调用数为零，不自动重试。

1. 目标 codedb_status({}) 恰好调用一次，保留原始响应。状态可用且目标绑定无冲突才继续。
   不可用、错误或超时立即停止，不查询、不重试。
2. 目标 codedb_text_search 恰好一次：
   {"query":"CODEDB_S39_EXTERNAL_20261020","limit":5,"regex":false}
   保留原始响应，核对 Assets/CodeDBAcceptance/S39QueryProbe.cs，第 5 行及文本：
           public const string Marker = "CODEDB_S39_EXTERNAL_20261020";
   无命中、错误或超时立即停止，不做补救查询。
3. 可只读核对样本内容/SHA-256：
   0b606ee895088add24435eb628f6ebfb2e3af8facec3133b6eee96623ba3041b
   结束时复核 selected pointer 未变化。本地文件读取不能替代 MCP 查询。

status 可能缺 instance_id/activation_epoch：如实记录，不用磁盘身份冒充响应身份。
若存在本会话新建且可归属的 MCP lease，可只读记录其身份关联依据；无法归属则保留限制。
项目现存 bootstrap 诊断基线：
AIWork/.runtime/codedb/diagnostics/bootstrap/60580-e1219fb5-feb2-4530-8d81-4688cd6805e3.json
该记录时间 2026-10-21T01:47:53.330Z，是验收前已有证据，不能归属于本会话。
若本轮失败，可在停止工具调用后做一次有界的只读诊断快照，列出现有/新增记录的
文件名、时间、pid、stage、Node 版本、exit/error 与 disk selected identity。
不轮询等待记录，不删除日志，不凭“新增”就归属连接；无记录也不能证明 wrapper 未启动。
worker_exit_code、wrapper_exit_code_requested、外部实际进程退出必须分别记录。
原始响应在本会话保留；跨会话报告不要输出令牌、完整环境/argv 或无关 runtime 全量转储。

禁止直接运行 wrapper/CLI/provider/probe 替代 MCP，不改源码、注册、环境或 runtime，
不 Install/Reinstall/Uninstall，不启停 Unity 或外部进程，不做 OS trace，不创建其他会话、
发消息、委派、提交、push 或发布。尊重宿主期限和 120 秒启动配置；首次失败即停止。
最终返回实际 cwd、工具名、调用次数、原始 status/query、命中位置/文本、身份归属依据与
缺失项、必要的失败诊断。分别报告查询功能和响应身份是否充分。
Ready、安装探针 AVAILABLE 和磁盘绑定不等于本次查询通过，不形成性能/升级/发布结论。
```

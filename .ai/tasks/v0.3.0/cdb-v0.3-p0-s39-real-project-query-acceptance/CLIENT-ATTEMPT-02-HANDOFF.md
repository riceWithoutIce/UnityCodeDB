# S39 Attempt 02 real-client query handoff

Date: 2026-10-20. Status: ATTEMPT_02_STOPPED / TARGET_CALLS_ZERO /
INITIALIZE_CONNECTION_CLOSED. See CLIENT-ATTEMPT-02-RESULT.md.
The human sent the instruction in a new Codex chat and returned its stopped
result. The following instruction is historical; do not paste it to retry.
The development parent did not create/message that chat or run any MCP call.

Prerequisites: repaired c07bb59 delivery and historical helper recovery PASS;
human reports Manager Ready after reopening; parent read-only observation finds
a new c07bb59 Supervisor with core_ready / COORDINATOR_OPERATIONAL and preserved
original instance, epoch, generation, registration and sample hashes. See
POST-HANDOFF-READY-RESULT.md. This is historical-install regression, not a real
clean-publication/first-Install gate. Attempt 01 remains stopped and historical.

Keep Unity in its current state. Create a fresh Codex chat at the existing
external CodedbTest_0 project root. Paste only the following instruction.
Do not use the development repository or the old failed client chat as the
new acceptance chat, and do not repeat Install or change registration.

## Instruction

```text
你负责 UnityCodeDB S39 Attempt 02：修复后独立工程的真实 Codex 客户端查询验收。
当前工作目录必须是用户创建的外部工程 CodedbTest_0 根目录。
用户在此新会话发送本指令，即授权本轮一次目标项目 codedb_status，以及成功后的单次有界
codedb_text_search；无需再次申请这两个调用的授权。

这是新的有界 Attempt 02，不续跑或重试 Attempt 01。
先只读核对实际 cwd、.codex/config.toml，以及
AIWork/.runtime/codedb/control/current-instance.json 和对应 instance.json。
预期注册：codedb-codedbtest-0；command=node，cwd="."，
args=["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]，
startup_timeout_sec=120。
预期 project_identity：
sha256:85d0f58fdebf7f4d5fb92ae80ba2a797a6f76f03a4443684deca2026f6f5bfc3
预期 instance_id：2414c73c2fbb47f4b664c1bdbcad5969
预期 activation_epoch：4ad2120d1559487f8e54c015685496f6
预期 generation_id：poc.43；Package：0.3.0-preview.5。
manifest/lock 的 CodeDB 引用应为 file:../../Packages/c07bb59/com.rice.ai-codedb。
恢复的 AIWork/codedb/shared/codedb-instance-manifest-contract.mjs 应存在，SHA-256：
de2366310169830738ceef4cba4d24e2b54da72f6a8a11ec8c564b4dc298d07f。
selected pointer 预期 SHA-256：
b28c7e8c1268bd06b5c58b1f8a16c1470701b0d06602ed2685b1d5b74db8e00c。
对应 instance.json 的实际 SHA-256 应与 current pointer 一致：
dd1244b1660a26b102867035cb85525d7e124b0c72ae0c55e18868eeab8b423e

发现这个会话实际暴露的目标项目 MCP 工具，按真实工具名称调用；
预计命名空间 mcp__codedb_codedbtest_0__*，名称必须由实际暴露确认。
不要使用其他 CodeDB 服务替代。记录可观察的配置来源及其他 CodeDB
命名空间；无法观察的用户/全局配置记为未验证，不要输出完整全局配置。

1. 调用目标项目 codedb_status({}) 恰好一次，保存原始返回。
   核对 wrapper 可用、目标项目/版本/代际信息。若工具未暴露、返回
   不可用、身份冲突或超时，立即停止，不执行查询、不自动重试。
2. 仅在状态可用且绑定无冲突时，调用目标项目 codedb_text_search
   恰好一次：{"query":"CODEDB_S39_EXTERNAL_20261020","limit":5,"regex":false}。
   保留原始响应，核对路径 Assets/CodeDBAcceptance/S39QueryProbe.cs、
   1-based 行号 5 和文本：
           public const string Marker = "CODEDB_S39_EXTERNAL_20261020";
   无命中、错误或超时立即停止，不用其他查询补救。
3. 可在本地只读比较该文件的实际内容与 SHA-256：
   76442fb3d5d7c950f8836f152bfd273c9b9a00c06d1d287eba036dc6e5d23842。
   本地读取不能替代 MCP 查询。调用后只读确认 selected pointer 未变。

status 实现可能不返回 instance_id / activation_epoch；请如实列出
缺失字段，不能用磁盘指针冒充响应身份。若能通过本会话新建且可归属的
MCP lease 关联实例，记录 project_identity、instance_id、generation_id
及关联依据；无法归属时明确保留证据限制，不猜测。

正常 MCP 连接可创建自身 lease/log 并启动受管依赖；除此之外保持只读。
不要直接运行 wrapper/CLI/provider 来替代 MCP，不轮询，不改注册、
全局配置、runtime 或源码，不安装/卸载/重装，不启停 Unity 或外部进程，
不创建其他会话、发消息、委派、提交、push 或发布。尊重宿主工具期限及
120 秒启动配置；第一次失败后保留原始证据并停止。

最后在本会话返回实际 cwd、实际工具名、原始 status 和 query 响应、
命中路径/行号/文本、身份关联依据与缺失项，并分别报告查询功能结果和
身份归属证据是否充分。不要把 Package 安装 Ready 等同于本次查询通过，
也不要宣称公共分发、性能、跨版本升级或发布验收完成。
```

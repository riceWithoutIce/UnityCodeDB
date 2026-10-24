# Single-variable cwd experiment 01

Date: 2026-10-21. Authority: user agreed to the proposed temporary absolute-cwd
experiment. Run: `41ecceeacdb94d77be0d96f3be4e857e`.
Final status: COMPLETE / ORIGINAL_BYTES_RESTORED / DO_NOT_RERUN. The human
target chat reported six visible tools and zero calls. See
CWD-EXPERIMENT-01-RESULT.md for evidence, attribution limits and restore receipt.
The steps below are retained history, not instructions for another attempt.
This is startup diagnosis, separate from query acceptance Attempt 04 (ON_HOLD).

## Frozen scope

Temporarily change only `mcp_servers.codedb-codedbtest-1.cwd` from `.` to the
confirmed absolute `<external-unity-root>` in the project's `.codex/config.toml`.
Preserve command=node, relative wrapper entry/--root args, timeout, Package,
runtime inputs, all other registrations, stdio, environment and normal Codex
privileges. No product source/validator change or permanent machine-local fix.
No manual wrapper/worker/probe/Provider start, reconnect, reinstall, new Unity
project, OS trace, administrator capture, or CodeDB call.

Local evidence and switch/restore helper:
`.artifacts/tests/s39-cwd-experiment/41ecceeacdb94d77be0d96f3be4e857e/`.
Machine-local paths remain in local artifacts only.

## Configuration transition and attribution

1. Confirm original config hash `cc266892469cc172733cea857fd29eaf80c44c0c37f4fa1b2ad4987dc494038b`;
   pin manifest, lock, pointer and wrapper to observation-04 baselines.
2. Retain exact original bytes, candidate bytes, bootstrap metadata and plan
   before replacement. Preserve encoding/line endings and all other bytes.
3. Replace config once and verify hash and the four protected input hashes.
   The helper has no runtime launch or monitoring functionality.
4. Config adoption may itself trigger normal native refresh. This is part of
   the configuration transition; do not assume a single child process start.
   Native automatic refresh is distinct from human/agent retry.
5. Human creates exactly one normal local chat under existing CodedbTest_1,
   with the prompt below. Do not resume an old chat for the experiment.
   The normal configured startup timeout remains 120 seconds. On failure or
   completion, stop: no retry, second chat, reconnect or configuration tweak.
6. Human returns target chat ID/title/result. Development session reads the
   attributable chat, takes one post-observation bootstrap snapshot and a
   bounded read-only native-log extraction for the exact service/chat/time.
   Limit the target evidence window to 180 seconds from its confirmed creation;
   if insufficient or no authoritative timestamp, report that limitation rather
   than broadening. Extract relevant sanitized fields only, not full logs/env.
   Absence of a bootstrap record/error is not proof of no wrapper execution.
7. Close the target observation BEFORE restore; record the boundary. Restore
   original bytes using the prepared helper only if current config hash still
   equals the candidate. Stop on drift, preserve evidence, do not overwrite
   intervening edits. Keep config editors/Install actions quiescent throughout.
   Hash guarding does not provide a multi-editor transaction.
8. Restoration can cause another native refresh. Record restore start/end and
   keep any resulting events outside the experiment outcome. No process kill
   or automatic cleanup of live host components is authorized. Do not restore
   while the human's target observation is still in progress.

If the user postpones/cancels the experiment, close the observation and restore
with the same guard; do not leave an unexplained permanent absolute cwd.
An interrupted switch must be inspected from retained bytes/plan and current
hash before any action; do not repeat Apply.

## Prompt for the one human-created target chat

```text
这是 CodedbTest_1 的一次有界 MCP 启动诊断；不是查询验收。
不要调用任何 CodeDB 工具（status/query/其他均为 0），不使用其他项目服务替代。
不手动启动 wrapper、worker、probe 或 Provider，不重连、不重试、不修改任何文件
或环境，不 Install/Reinstall/Uninstall，不启停 Unity 或外部进程，不创建新会话。

只核对并报告：
1. 实际 cwd 是否为当前 CodedbTest_1 Unity 工程根目录。错误就立即停止。
2. 只读核对项目 .codex/config.toml 中 codedb-codedbtest-1：
   cwd 是否为本工程绝对路径，command=node，原相对 wrapper/--root 参数未变，
   startup_timeout_sec=120。不要输出用户/全局配置或完整环境。
3. 当前工具目录是否暴露精确 mcp__codedb_codedbtest_1__*，给出匹配工具数；
   无论暴露与否，都不要调用。不要把配置文本存在当成工具已暴露。
4. 如宿主直接提供本次启动错误，只报告目标服务的必要错误摘要；不要查找完整
   日志或推断 wrapper 执行阶段。
5. 只在系统明确提供会话 ID 时报告它；不要扫描环境变量、会话库或旧记录来猜。

完成上述只读报告后立即停止，不等待工具变得可见、不刷新、不再次检查。
报告 CodeDB 调用总数=0；工具可见不等于查询通过或响应身份验收通过。
```

## Interpretation

An attributable ready client/tool list with only cwd changed supports a host
relative-cwd compatibility problem. It does not prove the failed historical
cwd was .codex, identify a portable correction, or pass queries/identity gates.
If only bootstrap execution advances, report that narrower change and next
actual failure. If startup still fails, cwd is not automatically excluded:
verify host adoption/attribution before interpreting. Missing adoption/error
evidence is INCONCLUSIVE. No automatic fallback experiment.

Any product correction later must align generator, validation and real-host
coverage after a separate scope agreement. Unconfirmed FOLLOW-UP stays deferred.

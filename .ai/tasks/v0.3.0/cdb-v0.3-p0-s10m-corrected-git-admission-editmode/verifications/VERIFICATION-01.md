# VERIFICATION-01: S10m Corrected Git Admission EditMode

## Verdict

- 结论：`FAIL`
- 模式：`GUARDED` 定向只读验收
- Findings：`1` 项 P1；无 BLOCKER、P2 或 FOLLOW-UP
- 验收对象：冻结 HEAD `6408b0d540b32584147588efb67ecc5ba12b2fda`
- 原因：现有 S10m log 的单次只读复核中，Package record 数量为 `1`，但 Verifier 的 source/location 归一化比较返回 `false`，与冻结 S10m RESULT 声明的 `True / True` 不一致。在 `1/1` evidence batch、retry `0/0` 的边界内不得重读、换模式或扩大调查，因此不能把该必需断言推断为 PASS。

## One-Time Findings

### P1 - Package source/location 绑定证据未在本轮闭合

- 冻结 S10m RESULT 声明：repository-local `com.rice.ai-codedb` Package record 恰好 `1`，source 与 location 归一化后均指向 repository Package。
- Verifier 对同一冻结 log 的一次读取确认 record 数量为 `1`，但 source/location 归一化比较结果为 `false`。
- 这是一项证据矛盾，不等同于已证明 Package 实际来自错误位置；但冻结验收要求该绑定必须明确为 PASS，故当前结论不能为 PASS。
- 按冻结预算未重读 log、未更换匹配算法、未执行第二批证据，也未检查范围外文件。

其余一次性 findings：无。

## Admission And Frozen Identity

已复用本任务此前完成且通过的 admission，未重复执行：

| Frozen input | Bytes | SHA-256 | Result |
| --- | ---: | --- | --- |
| S10l `TASK.md` | 16177 | `9bef5bf3a1febfd21f7f747adf97ac1e07b5ea686f332f3e6d8bdb29c806e3db` | PASS |
| S10m `TASK.md` | 10931 | `b2bc1da1ba74c90a28673532f9af6c6e67ebecd3e7420123d0b048ebabb380bb` | PASS |
| S10m `RESULT.md` | 8482 | `866df276c39f9d12eee7537e8abad066aad286529274ba833ebefbae015879f9` | PASS |
| S10n `TASK.md` | 9807 | `f0a3b8137ad813bb5e483dff8841934b736bd82088d1348491e47c8f26c8c464` | PASS |
| S10n `RESULT.md` | 3307 | `75dc240c97f8ec3e350b03f8a0483499a7c950baa3865719107459dc25615d58` | PASS |
| S10m XML | 55243 | `6628875ece46714f1b217ed08f4ff8b4b1c0f6cdd808d7dcb8b8738c874c9dd9` | PASS |
| S10m log | 93997 | `1b60d8d43f6513d5f235fe862dfd915dd98180a2022fbc142f6c3d288949ca51` | PASS |

## Corrected Filter And XML

- Filter source：冻结 S10l `TASK.md` 的 `## Corrected Focused Filter`。
- Fully qualified methods：`39`。
- XML root result：`Passed`。
- Total / passed：`69 / 69`。
- Failed / skipped / inconclusive：`0 / 0 / 0`。
- XML test cases：`69`。
- Represented methods：`39`。
- Unmapped cases：`0`。
- Missing / extra mappings：`0 / 0`。
- 结论：`PASS`。

S10n 的 `filter_heading:FAIL` 仅是其从错误任务卡查找标题导致的历史证据脚本错误；本轮按更正要求从 S10l 读取，不构成产品或测试 finding。

## Existing Log Evidence

同一冻结 S10m log 只读取一次：

| Assertion | Observed | Result |
| --- | ---: | --- |
| `com.rice.ai-codedb` Package records | 1 | PASS |
| Package source/location normalized to repository Package | false | FAIL |
| `error CS####` records | 0 | PASS |
| Immediate compiler-error summaries | 0 | PASS |
| Fatal/abort/crash markers | 0 | PASS |
| `Saving results to:` records | 1 | PASS |
| Saved-results target equals frozen XML | true | PASS |

三方完成证据中，精确 `Saving results to:`、冻结 S10m exact-process exit `0`、XML `69/69` 均成立；不要求 S10m 曾误用且未命中的 generic completion phrase。

## Ten-File Post-Run Closure

按冻结 S10n 表恰好一次复算 bytes/SHA-256，并以一次 NUL-delimited porcelain-v1 scoped status 查询核验：

| Repository-relative path | Expected status | Identity | Status |
| --- | --- | --- | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | ` M` | PASS | PASS |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | ` M` | PASS | PASS |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | ` M` | PASS | PASS |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | clean | PASS | PASS |
| `com.rice.ai-codedb/package.json` | clean | PASS | PASS |
| `UnityValidationProject/Packages/manifest.json` | ` M` | PASS | PASS |
| `UnityValidationProject/Packages/packages-lock.json` | ` M` | PASS | PASS |
| `UnityValidationProject/ProjectSettings/ProjectVersion.txt` | clean | PASS | PASS |
| `UnityValidationProject/ProjectSettings/ProjectSettings.asset` | ` M` | PASS | PASS |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | ` M` | PASS | PASS |

- Identity mismatches：`0`。
- Status mismatches：`0`。
- Scoped status：`7 modified / 3 clean`。
- 结论：`PASS`。

## Passive Process Point Check

- 查询成功：`true`。
- command line 指向 `UnityValidationProject/` 的 `Unity.exe`：`0`。
- 未轮询、附加、发送信号、停止或控制任何进程。
- 结论：`PASS`。

## Reused Evidence

- 冻结 S10m RESULT：单次同步 Unity exact process exit `0`，wall time `53.0254733s`，retry `0/0`。
- 冻结 S10m XML：`Passed`，`69/69`，39 methods，无 missing/extra mapping。
- 冻结 S10m RESULT 的 Package source/location 声明为 `True / True`，但本轮一次性比较未复现，因此保留为上述 P1，不据此推断 PASS。

## NOT RUN / DEFERRED

- `NOT RUN`：Unity、Unity Hub、Unity MCP、EditMode 重跑、C# compiler、Package Manager 操作、真实 prerequisite/Codex/外部业务进程、其他 L0/L1、全量回归。
- `NOT RUN`：全仓 diff/status、仓库级搜索、第二次 log/XML 读取、第二次十文件 identity/status、第二次进程查询。
- `NOT RUN`：源码、测试、TASK、RESULT 或任何已有输入修改；commit、push、publish；联系或派发 Coder。
- `DEFERRED`：Unity 手工 UI、runtime、consumer、release、publication 与发布验收。

## Next Role

将本次 `FAIL`、唯一 P1 与本报告路径一次性交回 UnityCodeDB v0.3 Planner。由 Planner/用户决定 `ACCEPT / FIX / DEFER / STOP`；Verifier 不自行派发 Coder。

当前 S10 定向验收已完成，下一步需要通知 UnityCodeDB v0.3 Planner 汇总，并由用户决定 ACCEPT / FIX / DEFER / STOP。

# 环境整理执行结果

日期：2026-10-30。
状态：`APPROVED_BATCH_COMPLETE / PRESERVATION_AND_CLEANUP_VERIFIED / LOCAL_COMMITS / PROJECT_READBACK_PASS / NO_PUSH`。
用户明确授权：“执行清理＋本地提交＋看板同步（不推送）”。

## 独立保存与清理

原始恢复资料根：
`G:/RiceProgram/UnityCodeDB/.artifacts/maintenance/environment-preparation-20261030-114343/`。

| 项目 | 实际结果 |
|---|---|
| 六个 checkout 的初始 dirty 内容 | 保存 232 个文件、HEAD/branch/status、binary/staged/unstaged patch 和 index；原文件与 ZIP SHA-256 逐项相符 |
| Git refs bundle | 5,939,322 字节，bundle verify 通过；保存时六个 HEAD 均可从其中 refs 到达 |
| Test0–Test6 精简证据包 | 7 个 ZIP，6,178 个文件条目，ZIP 合计 28,490,114 字节；源重读与 ZIP 内容 SHA-256 逐项一致 |
| 已删除精确目标 | 165 项、69,674 个文件、1,067,474,466 逻辑字节（约 1,018.02 MiB） |
| 删除内容 | Test2–Test6 Library 所列子项，排除 CodeDB；两套 Temp 编译夹具的四个 bin/obj 目录；带空格 `.ai` 下的一份旧候选文件 |
| 清理后保留 | 38 个受保护配置/诊断/冻结矩阵文件摘要不变；全部九个工程根仍在；共享 Packages、Test7/Test8、完整 worktree 和历史证据未删除 |

恢复 ZIP 与 bundle 合计 36,057,865 字节（约 34.39 MiB），另有清单/patch/index
副本的开销。删除值是逻辑文件字节，不是卷空闲空间差值实测。普通缓存字节未作
完整备份；未来打开历史工程会重新导入，可能增加首次打开成本。

精简证据包含项目非 Library 文件、Library/CodeDB 现存文件，以及实际引用的
Package，包含配置、AIWork 历史、Assets/meta、Logs/UserSettings。
原配置身份未改写；没有运行恢复后的归档工程。ZIP 不逐项保存空目录，不是完整
Library 或可直接重放历史运行身份的备份。

清理前完整路径/文件长度/时间复核、reparse/nested-Git 检查、相关进程检查和
逐文件独占只读打开通过后才开始删除。使用原生 PowerShell LiteralPath。
清理日志 167 条：1 条 preflight、165 条 removed、1 条 complete，没有失败或重放。
`cleanup-execution.jsonl` SHA-256：
`b2ed19abfdc17923dad1756f79a05edee30085d5304601ab27868e5aebb487da`。
所有精确目标缺失与受保护文件不变已回验。

## 本地 Git 保存

| 组 | 分支 | 文件数 | 提交 |
|---|---|---:|---|
| G1 历史交付/收尾证据 | codex/v0.3.0-legacy-workflow | 45 | `d8f00c303daf57856b8824fdf4587ce37999be47` |
| G2 观察修复记录与冻结设计 | codex/install-quarantine-admission | 111 | `52cf9bc8bfc82fb48f972abbf8987db110035171` |
| G3 本次执行记录、同步正文和项目索引 | codex/v0.3.0-legacy-workflow | 13 | 本记录所在的整理提交；最终 hash 见 ignored `git-commit-result.json` 和 Git log |

G1/G2 均按清单逐项比对内容摘要和 staged/committed 文件集合；未混入生产源码、
配置或 raw 恢复资料。G1 默认 diff-check 通过。G2 默认 diff-check 仅报告冻结
设计第 3 行原有 Markdown 双空格硬换行；保留其原字节，以仅排除 blank-at-eol 的
scoped check 通过，其余 whitespace 检查不关闭。没有为格式修改冻结设计。
G3 记录本次事实；最终精确路径和 staged diff 检查在该次提交前执行。

保存初期六个 checkout 的 HEAD/index/staged patch 均一致；现在仅两条已授权
分支因本地提交前进。其余四个历史 worktree 的原有 dirty 内容保持原字节。
它们的 ignored 证据没有全备份，因此仍不得整体移除。没有合并、推送或发布。

## Project 7 同步

地址：https://github.com/users/riceWithoutIce/projects/7。
先比对旧 readme 和 13 张卡的内容/状态仍匹配保存快照，再执行本次写入：

- 追加 2026-10-30 当前路线说明，明确源代码基线、两个本地文档提交及未推送。
- 3 张既有卡追加 dated overlay：Supervisor/Core Ready、cached Manager、controlled uninstall/reinstall；旧正文和状态保留。
- 新建设计冻结卡 Done（仅设计）、Slice A 卡 Ready（未授权实施）、环境整理卡 In review（实际执行批次待审）。
- Project 共 16 张卡；全部原有 13 张卡状态不变，其余 10 张卡正文不变。

写入后 readme、所有相关正文和状态均读回精确匹配。
机器回执：`project-sync-result.json`、`project-sync-execution.jsonl` 与前后快照。
新卡 ID：设计 `PVTI_lAHOAJuWC84BeIzrzhEq7ms`；Slice A `PVTI_lAHOAJuWC84BeIzrzhEq7nA`；
环境 `PVTI_lAHOAJuWC84BeIzrzhEq7nQ`。
未调用普通 Issue、评论或聊天消息发送接口。

## 保留与未运行边界

Test8 继续作当前人工 Ready UX 基线；Test7 完整保留迁移/移除阻塞复现。
Test2 四条未闭合历史记录不被后续测试结果关闭。S33/S35/S38、旧 Package 和
两个 `.artifacts` 大目录留后续保留评估；本批不扩展清理。

生产源码、消费者配置、Package 引用和既有测试结果没有修改。
没有 Unity/MCP/Provider 启停、产品测试、Slice A 开发、合并、推送或发布。
保存和清理核验不是新的 Unity/runtime/性能/发布验收。

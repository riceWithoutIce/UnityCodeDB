# 环境整理精确执行候选

状态：`APPROVED_EXACT_BATCH_EXECUTED / READBACK_VERIFIED / NO_PUSH`。
日期：2026-10-30。用户已批准本批“清理＋本地提交＋看板同步（不推送）”。
下文保留精确执行范围和执行规程，实际回执见 `RESULT.md`，不得重放删除。

## A. 已完成的独立保存

恢复资料根：
`G:/RiceProgram/UnityCodeDB/.artifacts/maintenance/environment-preparation-20261030-114343/`。

- 六个 checkout 的 HEAD、branch、原始 status、完整 dirty 文件、binary diff、staged/unstaged patch 和 index。
- 一个通过 `git bundle verify` 的 refs bundle；六个 HEAD 均可从所保存 refs 到达。
- Test0–Test6 的精简证据包：项目目录除 Library 普通缓存外的全部文件，包含
  AIWork、Assets/meta、Packages/ProjectSettings、.codex/.vscode、Logs/UserSettings，
  另加 Library/CodeDB 现存文件及当前引用 Package 的全部文件。
- 每个 ZIP 内文件的长度/SHA-256 与 ZIP 读回、源文件重读均逐项相符。
- Test0–Test8 的原始文件长度/时间清单；Project 7 完整只读快照。

精简证据包不是完整 Library 备份，也没有运行恢复后的工程；原目录均保留。
空目录不是 ZIP 的逐项保存对象。原始文件和包引用相对结构保留，不能在不同路径
直接启动归档副本并声称历史运行身份仍有效。

## B. 本批拟清理的精确范围

机器清单：`CLEANUP-TARGETS.json`，共 **165 个精确子目录/文件、69,674 个文件、
1,067,474,466 字节（约 1,018.02 MiB）**。这是逻辑文件字节，不是磁盘释放量实测。

| 组 | 精确包含规则 | 逻辑字节 | 保留 |
|---|---|---:|---|
| B1 | `G:/RiceProgram/Test/CodedbTest/CodedbTest_2/Library/` 下机器清单逐个列出的子项 | 209,115,244 | Library/CodeDB 目录、整个工程其余内容 |
| B2 | 同根 `CodedbTest_3/Library/` 下所列子项 | 205,838,230 | 同上 |
| B3 | 同根 `CodedbTest_4/Library/` 下所列子项 | 205,623,997 | 同上 |
| B4 | 同根 `CodedbTest_5/Library/` 下所列子项 | 205,638,444 | 同上 |
| B5 | 同根 `CodedbTest_6/Library/` 下所列子项 | 206,076,099 | Library/CodeDB 的 7 个诊断文件原地保留 |
| B6 | 主目录 `Temp/codedb-editor-compile/{bin,obj}` 与 `Temp/codedb-tests-compile/{bin,obj}`，仅这四个具体目录 | 35,179,401 | csproj、其他源/夹具、全部 XML/log 结果和历史状态归档 |
| B7 | 设计 worktree 的 ` .ai/tasks/v0.3.0/cdb-v03-ready-observation-deadline/SLICE-A-EVIDENCE-STOP-MATRIX.md`，注意 `.ai` 前有一个空格 | 3,051 | 正常 `.ai/` 中已冻结版；旧候选字节也已进入 worktree-04 恢复包 |

B6 表中的大括号是人读缩写；PowerShell 不使用此语法，执行必须逐个读取 JSON 中
四个完整 LiteralPath。B7 只删已保存旧文件，不递归删整个带空格目录树。

不在本批：Test0–Test6 原工程根、共享 Packages 的任何版本、Test7/Test8 的任何
内容、历史 worktree、主目录/设计 worktree 的 `.artifacts`、`.backups`，以及
S33/S35/S38 整体工程。原工程保留是为了先验证精简归档，不能用本次缓存清理
推导这些对象也获准删除。

## C. 执行前与执行后

获准执行后，只针对 B 的精确清单：

1. 重新检查路径在已声明根内、无 reparse/nested Git，保存包及其 manifest 校验通过。
2. 重读源清单。任何目标文件增加/删除/长度/时间变化、目录新增子项、原有引用
   改变或相关活跃进程/锁出现，停止并返回差异。进程命令行检查不等同全部文件句柄证明。
3. 复核 B7 原文摘要和正常路径冻结版；不把不同状态版本当完全相同文件。
4. 仅使用原生 PowerShell `Remove-Item -LiteralPath` 操作已核对的精确目标；
   不跨 shell 拼接删除路径，不停止任何进程，不为通过检查重试或自动恢复。
5. 首个异常即停，记录成功/失败的精确路径和字节。完成后核对目标缺失、保留项
   内容摘要及原消费者 manifest/lock 不变；记录缓存再生成会增加下次导入成本。

删除完成不会释放历史 issue，也不是 CodeDB 卸载或新的运行验收。
精简证据之外的旧缓存字节不会被完整备份；若需要它们，先调整清单而不是删后补救。

## D. Git 与看板

具体内容见 `GIT-AND-PROJECT-UPDATE-PROPOSAL.md`。

- Git：G1 保存主目录 45 个旧证据变更，G2 保存设计 worktree 111 个资料文件，
  G3 保存本次整理记录及项目索引更新。每组独立本地提交；不含历史 worktree 源码改动。
- 看板：追加一段路线说明，为 3 张既有卡追加相同的有日期 overlay，原状态保留；
  新建设计 Done、Slice A Ready、环境整理 In review 三张 DraftIssue。
- 不 push、不 merge、不发布；有批准也不能把文档工件等同新方案已实施。
- 若执行 B/Git/Project，分别写回实际回执，只有全部完成且核验通过才改该项状态。

## E. 后续归档评估

Test0–Test6 已有小型独立保存，原工程暂不移走；Test2 的四条未闭合历史记录
不修复、不删除。Test7 保留完整迁移复现，Test8 保留当前 Ready 人工基线。

历史 worktree 均有本地改动；恢复包只覆盖 Git dirty/untracked 和所保存 refs，
**不包含各 worktree 的 ignored 原始证据**。因此不能只凭本次 ZIP 就整体移除
worktree。未来需要补充其 ignored 证据处置、引用、使用会话和占用核对。

`.artifacts` 大目录、旧共享 Package、S33/S35/S38 进入后续证据保留评估；
不把本轮扩大为全部历史资料审计，也不借整理启动产品开发。

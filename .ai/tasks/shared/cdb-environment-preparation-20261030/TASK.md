# 开工前环境整理 — 2026-10-30

状态：`APPROVED_BATCH_EXECUTED / CLEANUP_VERIFIED / LOCAL_GIT_AND_PROJECT_SYNC_COMPLETE / NO_PUSH`。

用户要求先对齐本地生成物、CodedbTest 工程、Git 和 GitHub Project 任务，
并对集中整理原则回复“同意”。完成可恢复保存和精确清单后，用户选择
“执行清理＋本地提交＋看板同步（不推送）”，授权本记录中的具体批次。

已确认的边界：

- 保存主目录和全部 worktree 的现有 dirty/untracked；不得混入下一轮生产实现。
- Test8 保留作当前人工验收基线；Test7 保留作历史迁移/移除复现。
- Test0–Test6 转入证据归档评估；Test2 的未闭合历史记录不因新结果而关闭。
- 缓存只能按精确清单清理，先保留 Library/CodeDB/Diagnostics、Logs 和项目配置。
- Git 保存、提交、推送、看板同步分别列明内容；仅执行已授权的三组本地提交和 Project 同步。
- 缓存按已批准的 165 项清单删除；不删除完整工程/worktree，不切消费者引用，不启动或终止 Unity/MCP/Provider。
- 不启动 Slice A，不派发子 agent，不改历史验收结果或永久 memory。

本地保存为新增的独立恢复资料。ZIP 不代表可直接运行的工程，原目录保持原状。
历史配置可能含本地身份/路径，原样保存在 ignored 存储，不放入 Git/远端正文。

产物：

- `prepare_environment.py`：仅盘点、复制、散列核验和生成候选清单，不含删除/提交/远端写入。
- `PLAN.md`：精确候选与分批顺序。
- `GIT-AND-PROJECT-UPDATE-PROPOSAL.md`：待审提交分组、Project 更新正文和状态映射。
- `RESULT.md`：本阶段实际保存结果及明确未执行项。
- 原始库存、恢复包、Git bundle、远端只读快照保存在 `.artifacts/maintenance/`。

精确清理、本地提交和远端看板更新已获确认；实际结果见 `RESULT.md`。
该确认不包含推送、完整工程/worktree 删除、额外历史清理或 Slice A 实施。

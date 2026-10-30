# Git 与 Project 7 具体同步草案

状态：`APPROVED_BATCH_EXECUTED / LOCAL_COMMITS_AND_PROJECT_READBACK / NO_PUSH`。
日期：2026-10-30。Project：https://github.com/users/riceWithoutIce/projects/7。

用户已选择执行精确清理、G1/G2/G3 本地提交及本文件中的 Project 更新。
下文保留形成授权时的分组/范围；实施结果见 `RESULT.md`，不代表可重复执行。

## Git 保存与提交分组

独立恢复保存已核验；本地提交按用户本次明确授权执行。push 未获授权且未执行。

| 分组 | checkout / branch | 精确范围 | 建议提交说明 |
|---|---|---|---|
| G1 | 主目录 / codex/v0.3.0-legacy-workflow | `.ai/tasks/v0.3.0/cdb-v0.3-candidate-freeze-delivery-preparation/` 的 1 个 tracked 修改和 9 个新文件；`cdb-v0.3-candidate-lifecycle-acceptance/` 的 9 个新文件；`cdb-v0.3-install-quarantine-admission/` 的 26 个新文件 | `docs: preserve v0.3 candidate and child-closure evidence` |
| G2 | 当前设计 worktree / codex/install-quarantine-admission | 原有 `.ai/` 下 111 个新文件，见机器清单；不纳入带前导空格的 ` .ai/`；生产源码不变 | `docs: preserve observation deliveries and frozen session redesign` |
| G3 | 主目录 / codex/v0.3.0-legacy-workflow | 本次 `.ai/tasks/shared/cdb-environment-preparation-20261030/` 内人工可读记录、保存脚本和具体同步正文，以及 `.ai/validation-projects.md` 的日期/现状更新 | `docs: record environment preservation and cleanup plan` |

不纳入：`.artifacts/`、`.backups/`、原始本地配置、恢复 ZIP/bundle、Test 工程，
以及其他四个历史 worktree 的源码/配置改动。
G2 是设计及交付记录保存，不表示 Slice A 已实施。脚本/证据文件在提交前按精确
清单检查本地身份和敏感数据；恢复资料继续留在 ignored 路径，不作为公开附件。

主目录 HEAD 为 `11056964da1143955ed69a067361622799e3d6f2`；设计 HEAD 为
`3beb2c7ff35ce2159273a5f795b6f2e54ff427fb`。二者 merge-base 是前者。
当前设计分支没有同名远端分支；不自动合并两个分支、不 checkout 覆盖 dirty，
不重写历史。若要 push，另列实际 commit 和目标远端分支再确认。

## Project 更新的精确方式

先保存完整旧 readme 和 13 张现有卡正文，再追加有日期的当前路线说明。
保留旧正文/状态和历史验收；不批量标 Done，不删除或归档已有卡。
当前新记录尚未 push，正文必须说明源文件目前仅本地可用。

1. 将 `PROJECT-ROUTE-OVERLAY.md` 原文追加到 Project readme。
2. 创建下列三张 DraftIssue，并分别设置状态；不创建普通 GitHub Issue，不发送评论/通知消息。
3. 为三张既有卡追加 `PROJECT-EXISTING-CARD-OVERLAY.md`，原状态不变：
   - `PVTI_lAHOAJuWC84BeIzrzg2hP5s`：establish project Supervisor, versioned IPC, and Core Ready — In progress。
   - `PVTI_lAHOAJuWC84BeIzrzg2hP98`：make Manager a cached Supervisor client — In review。
   - `PVTI_lAHOAJuWC84BeIzrzg4XSqw`：controlled project uninstall and fresh reinstall — In review。

| 新卡 | 正文工件 | 拟定状态 | 状态边界 |
|---|---|---|---|
| `[Design] UnityCodeDB: freeze frontend/backend session redesign contracts` | `PROJECT-CARD-DESIGN.md` | Done | 仅设计冻结和离线工件准备完成 |
| `[P0] UnityCodeDB Slice A: strict contracts and single project authority gate` | `PROJECT-CARD-SLICE-A.md` | Ready | 可审阅实施卡；未授权、未开始实施 |
| `[Housekeeping] UnityCodeDB: preserve workspace evidence and prepare exact cleanup` | `PROJECT-CARD-ENVIRONMENT.md` | In review | 保存/清单待审；未清理、未发布 |

本草案不更改已有卡的 Priority/Size/Estimate、负责人和日期；不创建重复 Provider、
Manager 或历史问题卡。Test2/Test7 保留状态写入旧卡 overlay，与 Test8 分开。
其余 10 张现有卡的正文和字段保持不变，Discover Read 仍在 Backlog。

执行远端更新前重新读取 readme/卡内容。若相对本任务保存快照出现变化，停止写入
并返回差异，不能覆盖其他人的新记录。完成后读取回验实际正文和状态。

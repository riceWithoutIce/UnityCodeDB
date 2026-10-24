# 用户提供 Lifecycle 日志：Retire 线索与计数语义

日期：2026-10-23。来源：用户直接粘贴的 CODEDB_S12_EVIDENCE 和相邻调用栈；不是本轮重新采集的运行态。未提供该条 UTC、原文件路径或 operation/request ID。

## 关联依据

- selected_instance_id 为 `a492a5e936c14e4da3ed7e4cc7c8c16c`，generation 为 `poc.44`，与既有 CodedbTest_2 基线一致。
- 调用栈指向既有交付 Package `61dcd26-s42-ipc-compile-repair`，LifecycleEvidence:1032、EditorLifecycle:698。
- 不含字面工程名 CodedbTest_2；此前按工程名零命中不能排除这类目标关联记录。实例及 Package 是关联线索，不等于获得独立进程/日志会话归属或正式 MCP 响应身份。

## 用户记录的关键字段

| 字段 | 值 |
| --- | --- |
| checkpoint / last_product_state | reconcile_completed / Ready |
| reconcile_started_count / completed_count | 1919 / 1919 |
| post_admission_disposition / convergence_plan | RetirementSelected / Retire |
| post-admission 四层 | 全部 Current |
| current_instance_state | NotEvaluated |
| materializer_command_count | 5745 |
| supervisor_observation_count / identity_change_count | 7644 / 6016 |
| supervisor_pid / coordinator_pid（计数器保存值） | 48928 / 64092 |
| direct_materializer_fallback_count | 0 |
| manager_status_refresh_started/completed/failed | 2 / 2 / 0 |
| main_thread_work_counts / violation_count | 全零 / 0 |

这些是累计计数及最近记录字段；不是单次原子事务，不从 5745/1919 的接近三倍关系推导每轮固定执行三条命令，也不据 2/2/0 排除 Lifecycle IPC 超时。

## 源码复核

本轮比较 Lifecycle 和 LifecycleEvidence 与交付提交 61dcd26383c42766763eca2b885b159725b2f7dc，无 diff。

1. EditorLifecycle:2412-2424：Retire 条件为实例 Current、product Ready、integration cleanup Pending。1387-1415 记录选择结果后，正常继续路径发送 materialize/Upgrade，再以 Probe 重新确认 readiness。日志支持自动历史清理分支被选择，不能单凭此记录证明 Upgrade/cleanup 成功、对应第二次观察的特定 operation，或由它造成 UI 波动。
2. LifecycleEvidence:338-348 会在 admission 阶段重置 current_instance_state 为 NotEvaluated；该值不能直接解释为实例读取失败。Retire 的分支条件与字段重置应分别理解。
3. LifecycleEvidence:302-319 的 identity_change_count 在任一追踪字段不同于保存基准时加一。TrackIdentity:731-752 仅在零/空值时设置基准；非空基准有差异时返回 true，但不更新为最新值。因此重复观察同一个新身份会重复计数。6016 是“与保存基准有差异的观测数”，不是身份切换次数或重启次数；输出 PID 也不能当作本条日志时刻的新鲜进程身份。
4. 计数可经 SessionState 恢复；没有明确时间跨度和前后差分，不能评价调用频率、性能或重试次数。

## 当前结论与后续顺序

新增实证把排查重点缩小到“为什么 cleanup 仍 Pending、自动 Retire 的结果如何、是否反复选择同一清理”。先查已有相邻 CodeDB warning/command result 的 reason、cleanup state 及明确 ID/时间；没有差分序列前不宣称反复执行已被证明。

需要保留的关联缺口：该记录的时间/会话来源、退役前后 cleanup 状态、Upgrade 终态及其与 UI 的同时刻关系。既有 read-timeout 仍为另一真实线索，未与本条建立因果。

本轮只读源码和处理用户文本，新增本任务记录；未重读原生日志、扫描其他工程、调用 MCP、启动观察器、修改产品或操作进程。诊断计数的命名/更新方式作为解释限制记录，不顺手修改或扩大为重构任务。

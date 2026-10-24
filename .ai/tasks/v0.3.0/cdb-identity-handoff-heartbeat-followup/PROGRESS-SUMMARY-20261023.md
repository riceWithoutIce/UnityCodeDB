# v0.3 当前进度与诊断边界汇总

日期：2026-10-23。依据为已有任务记录、用户转交回执和本次静态复核；本轮未重新运行验收、观察器或产品组件。

## 已有验收

| 范围 | 已有结果 | 边界 |
| --- | --- | --- |
| CodedbTest_2 项目注册与工具暴露 | 目标命名空间 6 个工具，实际 status 成功 | 不替代全部宿主环境验收 |
| 固定查询 | 实际命中指定文件第 5 行与 marker | 不构成性能/SLA 结论 |
| Unity 关闭/重开 | 人工报告重新 Ready、无编译错误 | 中途 Needs attention/Starting 恢复耗时仍待定位 |
| 卸载与重新安装路径 | 卸载成功；重装首次因 retained execution 拒绝，后续修复交付后重新 Ready，真实 status/query 成功 | 不以之后 PASS 抹去原失败 |
| S41 文件变更可见性 | 第二轮 A 基线命中、B 命中、旧 A 零命中 | 等待约 15.13 秒，保存至 B 调用约 33.43 秒，不承诺 15 秒 SLA |
| S42 当前交付候选 | 61dcd26 编译修复后，人工无编译错误并 Ready；目标 status/query 回执 PASS | 稳态功能验收不关闭间歇状态波动 |
| focused readiness contract | 7 组场景 PASS，actual child starts=0 | CONTRACT_ISOLATED，不替代真实生命周期验收 |

S42 早期 RESULT.md 标题中的 NOT_DELIVERED 是当时阶段记录；交付及人工/客户端后续证据应结合后续命名结果文件和用户回执阅读，不能只读早期标题。

## 当前活动问题

1. Unity 静止挂机时出现 Ready → Unconfirmed/Needs attention/Starting → Ready；缺少 UI、动作会话和后端同一时间线。
2. 历史 S41 在 Manager Ready 起点后，实际查询返回 STARTING、provider_attempts=0；具体拒绝条件未还原，后续稳态 PASS 不关闭此事件。
3. 重开后几分钟才 Ready；启动/IPC 与状态确认延迟尚未完整归因。
4. 心跳连续性及身份交接是否另有问题仍开放；没有证据把以上全部现象归为同一心跳故障。
5. 正式 MCP status/query 响应未独立提供 project_identity、instance_id、activation_epoch；磁盘绑定及路径线索不能替代这些字段。

## 两次观察

| 项目 | 第一次 | 第二次 |
| --- | --- | --- |
| 结果 | TRANSITION_CAPTURED | ALREADY_IN_TRANSITION，基线即退出 |
| 公共 readiness | core_ready → maintenance | maintenance |
| operation | materialize:Probe / NO_CHILD | materialize:Upgrade / CHILD_ADMITTED |
| operational readiness | core_ready | core_ready |
| Provider/adapter/worker | ready / watching / ready | ready / watching / ready |
| heartbeat | 所采样 heartbeat 推进 | 所采样年龄约 1.344 秒 |
| pointer | 稳定 | 稳定 |
| UI/实际查询/进程存活 | 未观测 | 未观测 |

第一次观察器读取过密，回执保留且不作性能依据；随后分类读取已收紧为上限 24 次。第二次仅进行基线和结束核对，没有等待或重跑。第二次 Upgrade 的触发来源、终态和是否反复执行均未由本快照证明。

## 修正与当前结论

公共 maintenance 表示存在维护 operation，可与 operational core_ready 并存。当前 Bridge 真实解析路径读取 operational_readiness.state；因此不能据公共 maintenance 直接推导 Bridge Maintenance 或 UI Starting。消费链文档已修正此前过强的推断。

两次磁盘快照均未观察到采样时 heartbeat 过期或组件失效，但不能据此宣布查询实时可用，也不能排除其他时间窗口的故障。Unconfirmed 有动作结果确认语义；Needs attention 有多个生产分支，必须取得当时 detail/原因及配对缓存才能定位。

## 后续建议与停止边界

当前先完成汇总，不再执行第三次相同后端观察。优先只读核实已有诊断产物是否包含 Manager 的产品状态、动作 phase、缓存观测时间/revision、刷新失败原因，并核实 operation 触发来源；确认缺口后才设计最小关联观测。无需人工抓瞬间，也不直接启动 UI 注入或新日志系统。

继续使用现有 CodedbTest_2；不修改 MCP 注册时序、心跳/过期阈值、wrapper 准入或 immutable poc.44；不重启、杀进程、重连、刷新、Install/Repair/Uninstall。产品修改须在仓库内隔离 worktree 进行；Package 交付和 Unity/MCP 验收仍为独立步骤。当前 v0.3 为基础链路已有验收、稳定性诊断未闭合，未达到发布验收关闭状态。

相关记录：EVENT-OBSERVER-RESULT-01.md、EVENT-OBSERVER-RESULT-02.md、CONSUMPTION-CHAIN-ANALYSIS-20261023.md、IMPLEMENTATION-ENVELOPE-RESULT.md，以及相邻 S41/S42 任务目录。

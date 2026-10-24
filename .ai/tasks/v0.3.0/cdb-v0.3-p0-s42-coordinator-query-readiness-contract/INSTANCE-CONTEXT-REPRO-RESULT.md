# Offline instance-context reproduction result

Status: REPRODUCED_CONTEXT_DEPENDENCE. Evidence: OFFLINE_FUNCTION_BOUNDARY.
One initial batch, no corrected semantic rerun. Node harness syntax PASS.

Original frozen S42 runWatchManager and runChild executed in a VM. The actual
spawn options were captured with a controlled process.env; no production spawn
occurred. Original PowerShell Get-ProjectCodedbContext and
Get-ActiveEditorSessionIds were extracted with the PowerShell AST and executed
in a synthetic fixture. Original module entry points/imports were not run.
The fixture supplied slug/output-contract/path-containment dependencies and
synthetic process-start evidence. It created one fresh lease in the selected
instance only. One PowerShell fixture process was started; no real process
identity probes, product service/Provider/Unity/MCP or IPC request occurred.

| Inherited instance environment | Selected instance used by consumer | Visible Editor sessions |
| --- | --- | --- |
| Absent | No; legacy project-named runtime selected | 0 |
| Matches selected instance | Yes | 1 |
| Names a different fixture instance | No; foreign instance selected | 0 |

All three observations matched the diagnostic expectations. Existing explicit
expected lifecycle and admission/capture callbacks were preserved at the JS
boundary; unrelated environment was preserved. Mock child completion is not
evidence of a real watcher success. No manual-runtime or coordinator action was
executed by the PowerShell probe.

This establishes a source-level defect: a validated selected instance in the
Supervisor context does not determine the watch-manager child instance. The
child instead depends on inherited RICE_CODEDB_INSTANCE_ROOT. Its absence or a
foreign value can select the wrong lease/config/coordinator runtime.

It is consistent with the previously observed Stop session-prerequisite failure,
but the historical child's actual environment remains unobserved. This does not
prove every historical Needs attention, Unconfirmed or STARTING event has this
cause, nor does it establish a heartbeat TTL defect or live retirement.

Canonical result:
`<repository-root>/.artifacts/tests/s42-instance-context/2026-10-22T05-36-32-492Z/result.json`
SHA-256 `7d68b19b581b373fe912bd39a8e1982ba868f52d20ed2b0a9365648e61b1f3cc`.

Task harness reproduce-instance-context.mjs SHA-256:
`9841b56f641af34dd728988ebe163376f5c3949c0373cfb6da61999735b6192a`.
The result records all three original source hashes. Supervisor remains
`ac341b039f0840735801dc991e42a9ba7e313df0c82cca895d00dfc08a104fba`;
production test harness remains
`7bf20ca426419905b34bb3297af2f164be2946d50a3e95a9850de09fb77f468e`.
No product source or already exported artifact was changed.

Next proposed step: align INSTANCE-CONTEXT-REPAIR-PROPOSAL.md. Live Stop is not
replayed; Package delivery remains pending. Unity open/close stays human-owned.

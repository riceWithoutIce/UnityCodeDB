# S29 control authentication recovery: human Unity result

2026-10-10. Human evidence was reported after delivery of commit
`7c82ff46997417a82ccceedcf0f846afd8dcda93` and exact package
`.artifacts/s29-control-auth-recovery-7c82ff4/review/com.rice.ai-codedb`.
The user reported: “manager 开关，unity 关闭都正常”.

## Observed human behavior

- Manager can be opened and closed normally.
- Unity can be closed normally; the user reported no crash during this run.
- The supplied screenshot is retained as the human UI evidence:
  `C:/Users/admin/AppData/Local/Temp/codex-clipboard-d3f90342-2ed3-42c7-9b87-a2e05dc69090.png`.
- The screenshot shows `CodeDB needs attention`, `Host payload: Needs Setup`,
  and repeated `SUPERVISOR_IPC_TIMEOUT` diagnostics. It does not show an
  authenticated Ready result for this session.
- The screenshot also shows a historical failed INSTALL warning for an older
  package path. That banner is historical information and is not evidence that
  the new accepted package failed to install.

## Read-only attribution after the report

The S29 manifest and lock still select the exact control-auth recovery package.
The current supervisor operation is `5bb81f9b95074bb5848d8bca01e265ea`, a
maintenance `Probe` that failed at 2026-10-10T09:29:47.470Z UTC after the child
coordinator did not become ready within its 30,000 ms startup wait. Its recorded
stderr is `[ERROR] Timed out after 30000 ms waiting for coordinator readiness.`
Supervisor events show `coordinator_start_failed / NONZERO_EXIT` followed by
`operation_failed / materialize:Probe` and later authenticated shutdown. The
coordinator state observed afterward was stale `provider_state=starting` with
no `provider_ready_at_utc`; no matching S29 Unity process remained.

The existing desired/current/activation/operation records still describe the
previous successful INSTALL, selected instance `d620abbab0334a2d9c49e59888c1ef55`,
generation `poc.42`, and cleanup `PENDING`. No receipt, index, desired state,
current instance, activation, operation, or external process was modified by
this read-only follow-up.

## Acceptance boundary

Normal Manager/Unity shutdown behavior: HUMAN PASS for the reported run.
Authenticated Ready, transient-auth recovery, real IPC timing, provider
startup, lease-file publication and release acceptance: NOT PASS / unresolved
because the session ended at `NeedsAttention` with coordinator readiness timeout.
Focused Unity Test Runner results were not included in the human report and
remain NOT_REPORTED. No Install/Uninstall or automatic retry is requested by
this record.

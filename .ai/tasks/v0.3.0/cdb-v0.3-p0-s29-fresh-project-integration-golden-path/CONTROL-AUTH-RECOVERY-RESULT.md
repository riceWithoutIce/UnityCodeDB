# S29 control authentication recovery: frozen Coder result

## User disposition

2026-10-10: User explicitly stated "同意 accept". The v3 seven-file frozen
source snapshot in CONTROL-AUTH-RECOVERY-SOURCE-SHA256.txt is **SOURCE_ACCEPTED**
after independent v3 PASS and B01 closure. Parent rechecked 7/7 hashes with zero
mismatches before recording acceptance. This closes the current source slice.
Commit, package export/reference switching, human Unity validation and release
acceptance remain separate, unperformed stages for this snapshot. S29/release
remain PARTIAL. This acceptance record does not authorize those later actions.

2026-10-10. Base HEAD `9a2ca41e19baf125cae594eb10ceef6b28cfef9b`.
Later authorized delivery is complete: source commit
`7c82ff46997417a82ccceedcf0f846afd8dcda93`, exact export and S29 reference switch
PASS. See CONTROL-AUTH-RECOVERY-DELIVERY-RESULT.md. The following frozen Coder
evidence describes the pre-commit source stage; human Unity/release remain pending.

Source is an uncommitted, stopped-editing snapshot identified by
CONTROL-AUTH-RECOVERY-SOURCE-SHA256.txt. Independent v2 verification found B01;
the user authorized its narrow repair. v3 adds only the recovery early-return
guard and adjacent full-worker regression evidence; v3 re-review is PASS.
Admission v2: the parent changed Bridge terminal-evidence conversion and its test
after dispatch, prematurely invalidating v1's freeze. Source editing has now
stopped; v2 hashes replace v1 before Verifier admission. Verifier did not edit.
Both timed-out Manager and non-Manager responses now refuse authoritative terminal
evidence. The corrected 14-method/30-case runner and 0-error semantic compilation
passed on v2, and scoped diff --check passes. Do not attribute v1 to v2.
The user authorized this narrow repair after POST-P1-READINESS-DIAGNOSIS-2026-10-10.md,
then explicitly approved one read-only Verifier child on this frozen snapshot.

## Frozen scope and behavior

Seven changed files: ControlContract, EditorLifecycle, SupervisorBridge,
HostPayloadMaterializer (attention enum only), StatusSnapshot (attention wording),
EditorLifecycleTests and ManagerUiTests. No other source is in this slice.

- Only transport timeout/IOException/empty response after persisted selection,
  state/lock, process identity and canonical pipe validation become
  TransientAuthenticationUnavailable. Malformed/foreign responses, invalid disk
  records and multiple control authorities retain invalid/ambiguous classification.
- The new state blocks automatic start and is not usable for automatic admission.
  Reconcile disables start/lease admission, retries the full classifier for the
  same context with three total attempts and 250 ms between attempts, publishing
  Starting then explicit NeedsAttention on exhaustion. Later authentication
  success bypasses the old Ready/backend-no-op early return and continues through
  the existing Probe, normal publication and lease restoration route.
- Temporary authentication failure cannot create a terminal convergence failure.
  Existing terminal retention/clearing policy is unchanged.
- Bridge preserves operation-result timed_out and dispatched Manager IPC timeout
  remains outcome-unconfirmed. Timeout budgets, queue policy and payload stay unchanged.
- Manager cache/reopen and 30-second freshness are unchanged. No old timestamp is
  refreshed or Ready pinned to conceal authentication loss.

## Evidence and corrections

Semantic compilation of original Editor/Tests with installed Unity/NUnit metadata:
0 errors. Scoped git diff --check passes; staged index is empty.

The preceding report of 13 methods/34 cases counted ManagerReadyFreshness twice.
Its distinct evidence is 12 methods/28 cases PASS, including actual migration Read
with injected transport response while all disk/process/response classification
bodies remain production source. The runner now removes that duplicate and adds
two existing terminal retention/clear methods; its result will be recorded below.

Corrected focused run completed: 14 distinct methods / 30 cases PASS plus 5 full
RunReconcileWorker recovery cases; semantic compilation 0 errors. Successful
retry publishes bound Ready and restores lease prerequisite; missing proof, Probe
timeout and exhaustion remain non-Ready; the unchanged no-timeout Ready route
still skips backend work. IPC, lease file writing and removal preflight are stub
boundaries; worker branching, binding, cache publication and prerequisite logic
remain production.

Independent v3 re-review completed: 7/7 source hashes MATCH, scoped
`git diff --check` PASS, B01 closed, and no BLOCKER or FOLLOW-UP. The Verifier
completed without editing source or operating Unity/package/release workflows.

Parent continuation check: 7/7 v3 hashes MATCH and staged index empty. The scoped
seven-file whitespace check passes. A whole-worktree `git diff --check` reports
trailing whitespace in the unrelated dirty UnityValidationProject
ProjectSettings.asset; it is not a whole-worktree PASS and was left unchanged.

Runner: `.artifacts/tests/s29-control-auth-recovery/Semantic.csproj`, invoke
`dotnet run --project .artifacts/tests/s29-control-auth-recovery/Semantic.csproj -- run`.
Standalone adapters suppress the lifecycle static Unity initializer and replace
SessionState/native dataPath/time and NUnit assertions. UseActionContext supplies
the package path through an existing production test seam, avoiding native UPM.
No real receipt/index mutation, service control or Unity process launch occurs.

Earlier harness attempts failed on native UPM/JsonUtility entry points outside
Unity. JsonUtility round-trip/native GUI remain NOT_RUN, not PASS. The older
post-install runner's real Pending-index assertion is obsolete after human
recovery made the actual index Empty; that old runner is not this slice's acceptance.

Unity import/EditMode/lifecycle timing, package delivery and release acceptance
remain separate. No commit/export/reference switch, Install/Uninstall, cleanup,
external-process stop, Unity/MCP/CUA/BatchMode or push was performed. Preserve
unrelated dirty documentation, payload, older project and historical artifacts.

Verifier must inspect only this diagnosis/scope and adjacent regressions. Return
findings together to User; do not modify source or send fixes to a running Coder.
Do not label theoretical hardening or unrelated old issues release blockers.

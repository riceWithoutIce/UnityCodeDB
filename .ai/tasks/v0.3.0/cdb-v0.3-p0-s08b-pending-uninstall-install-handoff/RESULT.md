# Result: cdb-v0.3-p0-s08b-pending-uninstall-install-handoff

## Outcome

- Status: `BLOCKED` by the single focused functional run.
- Date: `2026-09-07` (`Asia/Shanghai`).
- Actual model/profile: `GPT-5` Codex session, dispatched as `v0.3.coder.deep`, `GUARDED`, `REUSE_ONLY`; exact backend variant and reasoning-effort label are unavailable to this session.
- Preserved reproduction: S08a FIX 01 had already passed all earlier scenarios and then failed because pending-Uninstall Install did not reach the existing candidate-verification pause. No pre-repair reproduction rerun was performed.
- The bounded engine/harness repair parsed successfully, but the one authorized `-UninstallOnly` run reached the same candidate-pause assertion failure. The dynamic handoff is therefore not proven.
- Per the first-failure stop condition, no investigation, further edit, rerun, scoped `git diff --check`, or final Git capture was performed after the failure.

## Admission Evidence

The single bounded admission capture verified exact HEAD, starting two-file/per-file identities, materializer cleanliness, scoped code status, and expanded task records.

- Exit code: `0`.
- Wall time: `0.5327791s`.
- Output disposition: complete and untruncated; `206` tool-reported tokens, visibly below `64 KiB`.
- Frozen HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Starting two-file patch identity:
  `f2acaaec73b20294d27f37a6258cfdd6f8902b87`.
- Starting engine diff identity:
  `0299b322acb696f44a1d4c5d34916990c07cb670`.
- Starting harness diff identity:
  `192d70b93c660e079b89fe200aceac3444629c40`.
- Scoped code status contained exactly the modified engine and direct harness; `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` was clean.
- Expanded task status contained only S08 and S08a `TASK.md`/`RESULT.md` plus S08b `TASK.md`.

## Authority Analysis

- Existing authority was statically sufficient without a new schema or policy owner:
  - The authenticated non-legacy desired-state document supplies the pinned old `UNINSTALLED + PENDING` state-id.
  - The old strictly parsed `COMMITTED` activation/operation pair supplies the retained candidate's complete instance/generation/hash identity.
  - `Get-ValidatedRetiredInstance` authenticates the retained instance closure without selecting or reusing it.
  - The existing activation transaction accepts a verified `PreviousInstance`, creates the existing immutable retirement intent, verifies the new candidate before publication, atomically writes current selection and `INSTALLED` desired state, and commits the selected candidate authority.
  - Automatic Uninstall cleanup already captures its state-id before the operation lock and exits obsolete when the locked desired state no longer matches after Install commit.
  - Existing retirement cleanup validates selected/retired intent identity and holder evidence before deleting anything; no process-stop authority was added.
- Fail-closed boundary: a prior COMMITTED contract already carrying retirement intent cannot be replaced by this single-retained-closure handoff; changed state-id, invalid/legacy state, retained current/LKG selection, mismatched contract/instance evidence, or ordinary installed missing-selection remain rejected.
- Dynamic qualification: although the existing authority can represent the state transition, the focused run did not reach the candidate pause, so the implementation path remains unaccepted and its concrete runtime failure was not investigated in this task.

## Implemented Changes

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - Extended activation recovery with explicit ref outputs for one authenticated retained previous instance and its exact superseded COMMITTED contract state.
  - For exact explicit Install with the pinned non-legacy `UNINSTALLED + PENDING` state-id, required missing current/LKG selections, no pre-existing retirement intent, a strictly validated retained instance root, and full retained evidence equality with the COMMITTED candidate.
  - Kept the old COMMITTED contract in place through candidate creation and the existing candidate-verification pause.
  - Before activation, under the same operation lock, reread and required the same `UNINSTALLED + PENDING` state-id, unchanged activation/operation hashes, no retirement intent, and unchanged retained instance identity; only then removed the old completed attempt so the existing activation transaction could publish its new authority.
  - Passed the retained old instance as `PreviousInstance`, allowing the existing transaction to create its standard retirement intent and keep cleanup `PENDING` after new selection.
  - Preserved the completed-Uninstall path and ordinary COMMITTED current-selection validation.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - Kept the existing candidate pause, desired-state/current-selection prepublication assertions, old automatic-cleanup orchestration, and obsolete-cleanup expectations unchanged.
  - Added adjacent snapshots asserting the retained previous instance and generation are unchanged at the candidate pause and after obsolete cleanup.
  - Added an assertion that successful pending-Uninstall Install selects a new instance identity rather than reusing the retained old instance.
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08b-pending-uninstall-install-handoff/RESULT.md`: this record.
- Protected `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` and all other files were not intentionally modified by S08b.

## AST Evidence

One parse covered only the changed engine and harness:

```powershell
$files = @('com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $failed = $false; foreach ($file in $files) { $tokens = $null; $parseErrors = $null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $file).Path, [ref]$tokens, [ref]$parseErrors) | Out-Null; if (@($parseErrors).Count -ne 0) { $parseErrors | ForEach-Object { Write-Output "AST_ERROR file=$file message=$($_.Message)" }; $failed = $true } else { Write-Output "AST_OK file=$file" } }; if ($failed) { exit 1 }
```

- Exit code: `0`.
- Wall time: `0.4597573s`.
- Output disposition: complete and untruncated; `37` tool-reported tokens.
- Result: both files reported `AST_OK`.

## Focused Functional Evidence

Exact command, invoked once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

- Functional batch: `1/1` used.
- Retry: `0/0`; no rerun occurred.
- Exit code: `1`.
- Total wall time: `90.0431645s` across the same ongoing execution session (`30.012652s`, `30.0147645s`, `30.0157464s`, and `0.0000016s`), below the `180s` limit.
- Output disposition: complete and untruncated; `215` tool-reported tokens across the session, visibly below `64 KiB`.
- Passed before terminal failure:

```text
[OK] Complete Uninstall, repeated Uninstall, suppression, fresh Install recovery, and ordinary missing-selection refusal preserved user-owned MCP content.
[OK] Uninstall/Install preserved child-first and child-only user namespaces, BOM/EOL, comments, and custom keys.
[OK] Cleanup held one lock from MCP removal through Host cleanup; waiting Install restored Host only after cleanup completed.
```

- First terminal failure, preserved without investigation:

```text
Install did not pause between candidate verification and atomic activation.
```

- Outer exit: `1`.
- Harness assertion helper location: `test-codedb-host-payload-materializer.ps1:175`.
- Fixture cleanup disposition: the harness returned after its existing `finally` path; no separate cleanup failure appeared in captured output. No independent post-failure process/status probe was authorized or run.

## Identity And Budget Ledger

- Starting HEAD and patch identities: proven by admission as listed above.
- Final HEAD: `unavailable`; immediate stop prohibited post-failure Git capture.
- Final two-file/per-file patch identities: `unavailable` for the same reason.
- Final scoped status: `NOT RUN`.
- Two-file scoped `git diff --check`: `NOT RUN` because it was authorized only after functional success.
- AST batch: `1/1`, passed.
- Functional batch: `1/1`, failed.
- Retry: `0/0`.
- Output truncation: none observed.
- Context compactions during S08b: `0`.

## NOT RUN / DEFERRED

- `NOT RUN`: test retry, post-failure investigation, further edit, scoped diff check, final identity/status, S08 continuation, other materializer modes, no-switch/full harness, other L0/L1, C# compile, and repository-wide tests.
- `NOT RUN`: Unity, Unity MCP, EditMode, PlayMode, cold start, Domain Reload, real project migration, real Supervisor/Codex/MCP/process acceptance, consumer/third-party Package, commit, push, publication, deployment, or release validation.
- `DEFERRED`: root-cause investigation and correction for the unchanged candidate-pause failure, requiring a separately frozen Planner/user decision.
- `DEFERRED`: dynamic proof of retained closure/new retirement intent/obsolete cleanup for pending-Uninstall Install.
- `DEFERRED`: S08 restart and commands `3-8`, C# compilation/focused EditMode, Unity runtime, real Manager/Supervisor/Install, consumers, and release acceptance.
- No Unity or Unity MCP was started or contacted. No commit, push, or Verifier contact occurred.

## Completion Routing

- Current task: `cdb-v0.3-p0-s08b-pending-uninstall-install-handoff`.
- Current status: `BLOCKED` by the sole focused run at the unchanged candidate-verification pause assertion.
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: review the static authority design and exact dynamic failure, then decide whether to freeze a bounded investigation/FIX. This task cannot inspect, amend, or rerun after its terminal failure.
- Verifier routing: not performed. Only Planner may decide whether a future stable result routes to `v0.3.verifier.deep`.
- Commit/push: not performed.

当前 S08b 已因唯一功能测试未到达 candidate pause 而阻塞；下一步由 Planner 审核现有 authority 设计与失败证据，并决定是否冻结独立 investigation/FIX，以及后续是否路由 `v0.3.verifier.deep`。

## DIAGNOSTIC-01

### Outcome

- Diagnostic status: `COMPLETE`; the authorized harness-only diagnostic produced attributable child-process evidence.
- S08b implementation status remains `BLOCKED`; the Install child exited before signaling the candidate-ready event because production convergence rejected the retained instance root.
- No production inference or correction was attempted. The engine and protected materializer remained read only.

### Starting Snapshot

- HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Two-file patch identity: `254152f5d3a50af6d7637c8e9df733765e7d0900`.
- Engine patch identity: `1a66fd1d7075bb25f32dd956f5938415066d2a79`.
- Harness patch identity: `40c7281ba69c471c114384c62dcb0bf233bf72e3`.
- Scoped status showed only the engine and harness modified; protected `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` was clean.
- Expanded task records were the expected S08, S08a, and S08b `TASK.md`/`RESULT.md` files.

### Harness Diagnostic Change

- Modified only `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` at the existing candidate-pause wait failure.
- A failed 30-second ready wait now records the immediate ready/continue event state.
- If the Install child has exited, the branch waits for final process completion and reports its exit code, complete captured stdout, and complete captured stderr before preserving the assertion failure.
- If the child is still running, the branch reports its PID, observed `HasExited` value, and event/wait state.
- The existing success-path candidate pause, prepublication assertions, cleanup interleaving, and obsolete-cleanup behavior were unchanged.

### Focused Diagnostic Evidence

Exact command, invoked once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

- Exit code: `1` (permitted for this diagnostic; attributable child evidence was the acceptance criterion).
- Total wall time: `98.1307467s` in one execution session, below the `180s` limit.
- Batch: `1/1`; retry: `0/0`.
- Captured output: complete and untruncated; approximately `754` tool-reported tokens, visibly below `64 KiB`.
- Earlier scenarios again reported their three existing `[OK]` lines before the target branch.
- Ready-wait evidence: `ready_wait_result=False`, `ready_event_signaled_after_wait=False`, `continue_event_signaled_at_wait_failure=False`.
- Child evidence: `child_status=exited`, child exit code `6`.
- Child stdout reported `outcome=BLOCKED`, `phase=PREFLIGHT`, `reason_code=INSTANCE_CONVERGENCE_FAILED`, and detail `Instance Install failed without selecting an unverified candidate. Retired instance root is not a directory.`
- Child stderr independently reported `Instance Install failed without selecting an unverified candidate. Retired instance root is not a directory.`
- Conclusion: the original candidate-pause message was downstream of an early Install child failure. The child neither remained alive waiting nor reached the ready event.

### Static And Final Identity Evidence

Exact scoped command, invoked once:

```powershell
git diff --check -- 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'
```

- Exit code: `0`.
- Wall time: `0.2697608s`.
- Output: empty; no whitespace errors.
- Final HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Final two-file patch identity: `d74922996e4a84920004acefe4c4db23e27d5dcf`.
- Final engine patch identity: `1a66fd1d7075bb25f32dd956f5938415066d2a79` (unchanged from DIAGNOSTIC-01 admission).
- Final harness patch identity: `a576d7ee806b46aaa5dbdc20548411bf887b8249`.
- Final scoped status retained only the modified engine/harness and expected untracked S08/S08a/S08b task records; the protected materializer remained clean.

### Boundaries And Completion Routing

- `NOT RUN`: AST parse, any production investigation or edit, additional harness runs, any other L0/L1, S08 continuation, C# compile, repository-wide diff/test, and real business-process validation.
- `NOT RUN` / `DEFERRED`: Unity, Unity MCP, EditMode, PlayMode, real Manager/Supervisor/Codex/MCP acceptance, consumer/release gates, commit, push, and Verifier routing.
- Current task: `cdb-v0.3-p0-s08b-pending-uninstall-install-handoff`.
- Current status: `BLOCKED` by the newly attributable production preflight failure `Retired instance root is not a directory.`
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: review this evidence and decide whether to freeze a separate bounded production investigation/FIX for the retained-instance-root rejection. Do not route to Verifier from this diagnostic snapshot.
- Commit/push: not performed.

当前 S08b DIAGNOSTIC-01 已完成；下一步由 `UnityCodeDB v0.3 Planner` 审核明确的 Install 子进程 preflight 失败，并决定是否冻结独立 production investigation/FIX。未联系 Verifier。

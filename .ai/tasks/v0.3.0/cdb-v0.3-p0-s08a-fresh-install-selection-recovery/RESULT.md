# Result: cdb-v0.3-p0-s08a-fresh-install-selection-recovery

## Outcome

- Status: `BLOCKED` by the single focused repair test.
- Date: `2026-09-07` (`Asia/Shanghai`).
- Actual model/profile: `GPT-5` Codex session, dispatched as `v0.3.coder.deep`, `GUARDED`, `REUSE_ONLY`; exact backend variant and reasoning-effort label are unavailable to this session.
- The preserved S08 ATTEMPT-03 failure was reused; `-UninstallOnly` was not rerun before repair.
- The one authorized post-repair `-UninstallOnly` invocation reached and passed the primary fresh Install recovery plus the new ordinary missing-selection refusal, then failed at the later existing `Install waiting behind automatic cleanup` scenario.
- Per the first-failure stop condition, no investigation, additional edit, rerun, scoped `git diff --check`, or final Git inspection was performed after the failure.

## Admission

The bounded admission check verified the frozen identity, clean allowed code paths, and exact expanded task records.

- Exit code: `0`.
- Wall time: `0.3665287s`.
- Output disposition: complete and untruncated; `87` tool-reported tokens, visibly below `64 KiB`.
- Exact frozen HEAD observed: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Allowed production/test path status: `CLEAN` for:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- Exact expected untracked inputs observed:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08-control-plane-code-freeze-l0/TASK.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08-control-plane-code-freeze-l0/RESULT.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08a-fresh-install-selection-recovery/TASK.md`

## Preserved Reproduction

- Source: S08 ATTEMPT-03 command `2/8`; no pre-repair rerun.
- Outer exit: `1`.
- Inner fresh Install exit: `6`.
- Phase: `PREFLIGHT`.
- Reason: `INSTANCE_CONVERGENCE_FAILED`.
- Detail: `Instance Install failed without selecting an unverified candidate. Current CodeDB instance selection is missing.`
- Preceding evidence: machine prerequisite `CURRENT` and a recovered versioned activation in `COMMITTED` phase.

## Root Cause And Authority

- Root cause: a complete Uninstall correctly persisted authenticated `UNINSTALLED` desired state and removed current/LKG instance selections and the retired selected instance. The prior strictly validated activation/operation contract remained `COMMITTED` as durable completed-installation evidence. During explicit Install, `Invoke-InstanceConvergence` called `Invoke-InstanceActivationContractRecovery` before candidate creation; the COMMITTED branch unconditionally called `Get-ValidatedCurrentInstance`, so the intentionally absent current selection failed before the fresh transaction could supersede the prior completed contract.
- Authority decision: `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` owns this correction because it already exclusively validates activation namespace, activation/operation identity, publication phase, selected evidence, desired state, and activation-attempt removal. The materializer dispatch and ordinary current-selection validator were left unchanged to avoid duplicating policy or weakening fail-closed reads.

## Implemented Repair

Changed files before the focused test:

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - Bound activation recovery to the explicit `Install`/`Upgrade`/`Reinstall` action.
  - Added a fresh-Install-only COMMITTED supersession path gated by a non-legacy authenticated desired-state document with exact pinned state-id, `UNINSTALLED`, cleanup `COMPLETE`, missing current and LKG selections, and absence of the strictly validated prior candidate's retired instance root.
  - Reused `Get-InstanceActivationContractState` validation before removing only that authoritative completed activation attempt.
  - Preserved the ordinary COMMITTED branch, which still requires and validates current selection for all non-eligible states and actions.
  - Rechecked the same UNINSTALLED identity after activation and operation recovery while holding the project operation lock.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - Preserved the existing new-instance identity, current selection, generation/stable wrapper, desired-state, MCP namespace, business sentinel, and repeated-Install refusal assertions.
  - Added an adjacent installed-state regression that removes current selection, invokes ordinary `Upgrade`, requires exit `6` with the exact missing-selection failure, verifies no contract/project mutation, and restores the selection bytes in `finally`.
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`: unchanged; existing explicit mutation confirmation and `Install` dispatch remain authoritative.
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08a-fresh-install-selection-recovery/RESULT.md`: this result record.
- S08 `TASK.md` and `RESULT.md`: read-only and unchanged by this task.

## Static Evidence

One changed-file AST parse covered only the two changed `.ps1` files:

```powershell
$files = @('com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $failed = $false; foreach ($file in $files) { $tokens = $null; $parseErrors = $null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $file).Path, [ref]$tokens, [ref]$parseErrors) | Out-Null; if (@($parseErrors).Count -ne 0) { $parseErrors | ForEach-Object { Write-Output "AST_ERROR file=$file message=$($_.Message)" }; $failed = $true } else { Write-Output "AST_OK file=$file" } }; if ($failed) { exit 1 }
```

- Exit code: `0`.
- Wall time: `0.4312698s`.
- Output disposition: complete and untruncated; `37` tool-reported tokens.
- Result: both changed files reported `AST_OK`.

## Focused L0 Evidence

Exact command, invoked once after the repair:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

- Invocation count: `1/1`.
- Retry count: `0/0`.
- Exit code: `1`.
- Wall time: `60.0105659s` across the same ongoing execution session (`30.004689s`, `30.0058754s`, and `0.0000015s` tool-reported segments), below the `180s` maximum.
- Output disposition: complete and untruncated; `649` tool-reported tokens across the same session, visibly below `64 KiB`.
- Passed before the terminal failure:

```text
[OK] Complete Uninstall, repeated Uninstall, suppression, fresh Install recovery, and ordinary missing-selection refusal preserved user-owned MCP content.
[OK] Uninstall/Install preserved child-first and child-only user namespaces, BOM/EOL, comments, and custom keys.
```

- First terminal failure:
  - Harness label: `Install waiting behind automatic cleanup`.
  - Outer command exit: `1`.
  - Expected inner exit: `0`; actual inner exit: `6`.
  - Structured result: action `INSTALL`, outcome `BLOCKED`, phase `PREFLIGHT`, reason `INSTANCE_CONVERGENCE_FAILED`, cleanup `COMPLETE`.
  - Preserved detail: `Instance Install failed without selecting an unverified candidate. Current CodeDB instance selection is missing.`
  - Preceding output again reported prerequisite `CURRENT` and a versioned activation in `COMMITTED` phase.
- Classification: this later scenario is the first post-repair failure. Its cause was not investigated and no conclusion beyond the captured evidence is claimed.

## Identity And Verification Ledger

- Base/pre-repair HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`, proven by admission.
- Post-repair/final HEAD: `unavailable`; the immediate-stop rule prohibited a Git command after the focused test failed.
- Scoped patch identity: `unavailable`; no final patch-identity command was run after failure.
- Final scoped status: `NOT RUN` due immediate stop.
- Scoped allowed-file `git diff --check`: `NOT RUN` because the focused test failed first.
- Changed-file AST parse: `1/1`, passed.
- Focused L0 batch: `1/1`, failed.
- Functional retry: `0/0`; no retry occurred.
- Output truncation: none observed.
- Context compactions during S08a: `0`.

## NOT RUN / DEFERRED

- `NOT RUN`: repair-test retry, scoped `git diff --check`, final status/patch identity, S08 continuation, other materializer modes, S08 commands `1` and `3-8`, no-switch/full harness, other L0/L1, C# compile, and repository-wide tests.
- `NOT RUN`: Unity, Unity MCP, EditMode, PlayMode, cold start, Domain Reload, real project migration, real Supervisor/Codex/MCP or other external validation, consumer/third-party Package, commit, push, publication, deployment, or release validation.
- `DEFERRED`: diagnosis and correction of the first later `Install waiting behind automatic cleanup` failure, requiring a separately frozen Planner/user decision.
- `DEFERRED`: completion of S08 commands `3-8` and any new complete code-freeze batch.
- `DEFERRED`: C# compilation and focused EditMode in `UnityValidationProject/`, Unity runtime behavior, real Manager/Supervisor/Install flows, consumers, and release acceptance.
- No Unity or Unity MCP was started or contacted. No commit, push, or Verifier contact occurred.

## Completion Routing

- Current task: `cdb-v0.3-p0-s08a-fresh-install-selection-recovery`.
- Current status: `BLOCKED` by the single post-repair `-UninstallOnly` run at the later automatic-cleanup concurrency scenario.
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: review the bounded root cause and authority repair together with the exact first post-repair failure, then decide whether to freeze a separate bounded follow-up. This task cannot investigate, amend, or rerun.
- Verifier routing: not performed. Planner alone decides whether a future stable result should route to `v0.3.verifier.deep`.
- Commit/push: not performed.

当前 S08a 已因唯一修复测试中的后续首个失败而阻塞；下一步需要通知 Planner 审核现有修复与该失败，并决定是否冻结独立 follow-up，以及后续是否路由 `v0.3.verifier.deep`。

## FIX 01 - Pending-To-Complete Fresh Install Admission

### Outcome

- Status: `BLOCKED` by the first independent failure after the targeted automatic-cleanup scenario passed.
- Date: `2026-09-07` (`Asia/Shanghai`).
- Authorization: bounded FIX 01 preserving the existing uncommitted engine and direct-harness repair.
- Actual model/profile: `GPT-5` Codex session, dispatched as `v0.3.coder.deep`, `GUARDED`, `REUSE_ONLY`; exact backend variant and reasoning-effort label are unavailable to this session.
- Target finding closed in the observed run: `Install waiting behind automatic cleanup` passed and reported that waiting Install restored Host only after cleanup completed.
- Terminal stop: the same sole `-UninstallOnly` invocation later failed with `Install did not pause between candidate verification and atomic activation.` Per the first-independent-failure rule, no investigation, edit, rerun, diff check, or final identity/status command followed.

### Starting Snapshot

- Admission/status command: exit `0`, wall time `0.5434106s`, complete and untruncated output (`182` tool-reported tokens).
- Frozen HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Pre-FIX two-file patch identity:
  `30b3ed86fb178f7103978c29936321a1d0c70e41`.
- Pre-FIX engine diff identity:
  `0e66c42de3790e21206d552bbd0cf904fd6290ee`.
- Preserved harness diff identity:
  `192d70b93c660e079b89fe200aceac3444629c40`.
- Scoped code status contained exactly:
  - `M com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `M com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` was clean.
- Expanded task status contained only S08 and S08a `TASK.md`/`RESULT.md` records.

### FIX 01 Change

- Changed by FIX 01: `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` only.
- Preserved unchanged by FIX 01:
  `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` and
  `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`.
- Exact semantic change: the pre-lock fresh-Install state-id latch now accepts an authenticated, non-legacy `UNINSTALLED` desired-state record whose cleanup state is either `PENDING` or `COMPLETE`.
- Authority remains locked down:
  - The latch records only the authenticated pre-lock `state_id`; it does not supersede or activate anything.
  - After acquiring the operation lock and immediately before COMMITTED supersession, recovery still rereads and requires the same non-legacy `state_id`, `UNINSTALLED`, and cleanup `COMPLETE`.
  - The subsequent locked-state check still requires the same `state_id` and cleanup `COMPLETE`.
  - Still-`PENDING`, changed state-id, missing/invalid/legacy desired state, retained current/LKG, retained retired candidate root, and ordinary installed missing-selection paths remain fail-closed.

### Engine AST Parse

Exact command, run once:

```powershell
$tokens = $null; $parseErrors = $null; $path = (Resolve-Path -LiteralPath 'com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1').Path; [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$parseErrors) | Out-Null; if (@($parseErrors).Count -ne 0) { $parseErrors | ForEach-Object { Write-Output "AST_ERROR message=$($_.Message)" }; exit 1 }; Write-Output 'AST_OK file=com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1'
```

- Exit code: `0`.
- Wall time: `0.3731071s`.
- Output disposition: complete and untruncated; `17` tool-reported tokens.
- Result: `AST_OK file=com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`.

### Focused Functional Evidence

Exact command, invoked once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

- Functional batch: `1/1` used.
- Retry: `0/0`; no rerun occurred.
- Exit code: `1`.
- Total wall time: `87.4418465s` across the same ongoing execution session (`30.0153163s`, `30.0160373s`, and `27.4104929s`), below the `180s` maximum.
- Output disposition: complete and untruncated; `215` tool-reported tokens across the same session, visibly below `64 KiB`.
- Passed before the terminal failure:

```text
[OK] Complete Uninstall, repeated Uninstall, suppression, fresh Install recovery, and ordinary missing-selection refusal preserved user-owned MCP content.
[OK] Uninstall/Install preserved child-first and child-only user namespaces, BOM/EOL, comments, and custom keys.
[OK] Cleanup held one lock from MCP removal through Host cleanup; waiting Install restored Host only after cleanup completed.
```

- Root-cause closure evidence: the third line is the existing concurrency regression named by FIX 01. It proves the pre-lock `PENDING` state only latched identity, automatic cleanup completed under the operation lock, and waiting Install restored Host after completion.
- First later failure, preserved without investigation:

```text
Install did not pause between candidate verification and atomic activation.
```

- Outer exit: `1`.
- Failure location reported by the harness assertion helper: `test-codedb-host-payload-materializer.ps1:175`.
- Classification: independent post-target harness failure; no cause or product/fixture attribution was investigated in FIX 01.

### Identity And Remaining Checks

- Post-FIX/final HEAD: `unavailable`; immediate stop prohibited a Git command after the focused test failed.
- Final two-file patch identity: `unavailable` for the same reason.
- Final engine patch identity: `unavailable`.
- Harness preservation post-check: `NOT RUN`; pre-FIX identity was captured, and no harness edit was made by FIX 01.
- Scoped status: `NOT RUN` after failure.
- Engine/direct-harness scoped `git diff --check`: `NOT RUN` because the functional command failed first.
- Context compactions during FIX 01: `0`.

### NOT RUN / DEFERRED

- `NOT RUN`: test retry, failure investigation, further edit, scoped `git diff --check`, final status/identity capture, S08 continuation, other materializer modes, other L0/L1, full harness, C# compile, and repository-wide tests.
- `NOT RUN`: Unity, Unity MCP, EditMode, PlayMode, cold start, Domain Reload, real project migration, real Supervisor/Codex/MCP or external acceptance, consumer/third-party Package, commit, push, publication, deployment, or release validation.
- `DEFERRED`: investigation and disposition of `Install did not pause between candidate verification and atomic activation`, requiring a separately frozen Planner/user decision.
- `DEFERRED`: S08 commands `3-8`, any new complete S08 code-freeze batch, C# compilation/focused EditMode, real runtime flows, consumers, and release acceptance.
- No Unity or Unity MCP was started or contacted. No commit, push, or Verifier contact occurred.

### FIX 01 Completion Routing

- Current task: `cdb-v0.3-p0-s08a-fresh-install-selection-recovery`.
- Current status: `BLOCKED` by the first independent failure after the bounded target regression passed.
- FIX 01 target disposition: the automatic-cleanup `PENDING -> same state_id COMPLETE` admission path passed its existing regression in the sole authorized run.
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: review the target closure evidence and independently classify/freeze the later activation-pause failure. This FIX cannot investigate, amend, or rerun.
- Verifier routing: not performed. Only Planner may decide whether a future stable result routes to `v0.3.verifier.deep`.
- Commit/push: not performed.

当前 S08a FIX 01 已关闭目标并发路径，但被随后首个独立失败阻塞；下一步由 Planner 审核证据并决定是否冻结独立 follow-up，以及后续是否路由 `v0.3.verifier.deep`。

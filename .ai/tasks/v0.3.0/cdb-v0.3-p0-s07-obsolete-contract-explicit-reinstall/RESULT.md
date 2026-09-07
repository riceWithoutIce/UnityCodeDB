# Result: cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall

## Outcome

- Status: `BLOCKED` by the frozen task's output-limit stop condition.
- Implementation status: source-complete on the uncommitted allowlisted snapshot described below.
- Focused L0 status: `PASS` on that snapshot.
- Blocking procedural fact: the initial bounded preflight route search completed with exit `0`, but its captured output was truncated by the execution tool (reported original route-search output approximately 35,815 tokens; aggregate result approximately 30,107 tokens). Work incorrectly continued after that capture limit. This result therefore does not claim a compliant `COMPLETE` run.
- No context compaction occurred during S07 execution.
- Date: `2026-09-07` (`Asia/Shanghai`).
- Actual model/profile: `GPT-5` Codex session, `v0.3.coder.deep` reasoning profile, `GUARDED` review mode.

## Snapshot Identity

- Frozen base and current HEAD before implementation: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
- HEAD after implementation and focused evidence: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
- Pre-L0 and post-L0 six-file patch identity: `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.
- Patch identity method:

```powershell
git diff --binary -- "com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs" "com.rice.ai-codedb/Editor/AICodedbActions.cs" "com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" "com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1" | git hash-object --stdin
```

- The frozen `TASK.md` remains unmodified. All implementation changes remain unstaged and uncommitted.

## Changed Files

- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - Captures the cached product status before confirmation.
  - Passes `confirmedProjectMutation=true` explicitly through an `Action<bool>` only after the dialog returns true.
  - Suppresses the Manager's generic post-action reconcile for this route so Actions remains the single successful-Reinstall reconcile owner.
- `com.rice.ai-codedb/Editor/AICodedbActions.cs`
  - Admits only cached `NeedsAttention + ControlContractReinstallRequired + prerequisite Current` together with freshly read `Installed` integration and exact `ObsoleteReinstallRequired` migration evidence.
  - Reads current integration/migration evidence inside `Task.Run`, before issuing any Supervisor or fallback command.
  - Sends the explicit confirmation bit to the existing Supervisor route and its exact Bridge-authorized fallback.
  - Issues one reconcile only after a successful command; failure and missing confirmation issue none and never auto-retry.
- `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
  - Changes Reinstall entry points to require an explicit confirmation argument; no parameterless confirmation inference remains.
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  - Adds exact admission precedence, worker-only current-evidence reads, cancellation/confirmation propagation, materializer argument, and one-command/one-reconcile source tests.
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - Adds Reinstall request serialization, confirmed versus unconfirmed empty-runtime fallback, and no automatic Lifecycle Reinstall source coverage.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - Adds mutually exclusive `-ControlContractReinstallOnly`.
  - Builds disposable authenticated-obsolete-shaped legacy evidence and an unrelated sentinel.
  - Rejects unconfirmed and `InvalidOrAmbiguous` fixture admission before invoking materialization.
  - Uses only the existing deterministic `PocFixture` candidate path after explicit fixture admission; no holder, Node, Codex, MCP, Supervisor, or Unity process is started.
  - Proves candidate failure before selection, explicit retry, current/COMMITTED identity agreement, and byte preservation of legacy and unrelated evidence.

## Protected Authorities

- Read only and unchanged: `AICodedbControlContract.cs`, `AICodedbStatusSnapshot.cs`, `codedb-instance-engine.ps1`, `materialize-codedb-host-payload.ps1`, `codedb-project-supervisor.mjs`, and `Payload~/payload-manifest.json`.
- `AICodedbEditorLifecycle.cs` and `AICodedbSupervisorBridge.cs` production behavior was also unchanged; existing accepted scheduling and fallback authority was reused.
- No runtime state outside disposable harness fixtures was changed.

## Static Evidence

- Targeted PowerShell AST parse for `test-codedb-host-payload-materializer.ps1`: exit `0`, output `AST_PARSE_OK`.
- Parameterless-call search: exit `0`, output `NO_PARAMETERLESS_REINSTALL_CALLS`.
- One scoped `git diff --check` over the six changed code/test files: exit `0`, no output.
- Individual static-command wall times are unavailable because these read-only checks were executed in parallel orchestration; the AST/reference batch observed `5.4s`, and the final diff-check/identity batch observed `4.3s` total wall time.
- Affected C# source-test matrix is present but was not executed because EditMode authorization is `NOT_REQUESTED`.

## Focused L0 Evidence

Exact command, invoked once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ControlContractReinstallOnly
```

- Exit code: `0`.
- Wall time: `16.0994323s`.
- Captured output disposition: complete and not truncated.
- Captured output:

```text
[OK] Explicit obsolete-contract Reinstall rejected unconfirmed and ambiguous admission, verified its candidate before selection, retried after pre-commit failure, committed one current instance, and preserved legacy/unrelated bytes.
[OK] Focused obsolete control-contract explicit Reinstall scenarios passed.
```

- The fixture used the deterministic Package materializer candidate path in a disposable project. It did not run the real C# Manager/Supervisor route; that boundary remains deferred with C# execution.

## Batch And Retry Ledger

- `-ControlContractReinstallOnly` focused L0 batches: `1/1` used.
- Focused L0 command invocations: `1`.
- Corrected retries: `0/1` used.
- Affected C# L1/EditMode batches: `0`; `DEFERRED` because authorization is `NOT_REQUESTED`.
- S04 `-ActivationContractOnly`: `0` / `NOT RUN`.
- S05 `-ActivationTransactionOnly`: `0` / `NOT RUN`.
- S06 `-ActivationRetirementOnly`: `0` / `NOT RUN`.
- Supervisor Node, Package-boundary, full materializer, other L0/L1, C# compile, and repository-wide tests: `0` / `NOT RUN`.
- Context compactions: `0`.
- Test retries: `0`.

## Deferred Boundaries And Risk

- `DEFERRED`: C# compilation and focused EditMode tests in `UnityValidationProject/`.
- `DEFERRED`: real Manager confirmation interaction, real current Supervisor routing, empty-runtime one-shot fallback, cold start, Domain Reload/Play, and post-success Lifecycle scheduling.
- `DEFERRED`: real obsolete project Reinstall, long-lived Codex/MCP/Editor holders, consumer/third-party Package acceptance, sequential activation history, final P0 layered acceptance, release, publication, and deployment.
- The PowerShell fixture's explicit admission wrapper composes with `PocFixture`; it does not constitute execution proof that the C# confirmation bit reached a real Supervisor or materializer process. Direct C# tests cover that source contract but remain unexecuted.
- The initial preflight capture truncation is the run-level blocker. Passing focused evidence does not erase that frozen stop-condition violation.
- No Unity or Unity MCP was opened, created, connected, or started. No process was stopped, killed, signalled, restarted, or attached. No commit or push occurred.

## Completion Routing

- Current task: `cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall`.
- Current status: `BLOCKED` by preflight output-limit violation; implementation and focused L0 evidence are preserved on patch identity `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: review the exact uncommitted snapshot, the passing focused L0 evidence, the unexecuted C# matrix, and the procedural blocker; Planner decides whether to authorize a fresh bounded closure attempt before any Verifier routing.
- Verifier routing: not performed by Coder. Planner alone decides whether and when to route a stable result to `v0.3.verifier.deep`.
- Commit/push: not performed.

当前 S07 结果已返回 Planner 审核；由于 preflight 输出捕获截断，本轮按冻结 stop condition 标记 BLOCKED。下一步由 Planner 决定是否授权新的 bounded closure，并决定后续是否路由 `v0.3.verifier.deep`。

## Independent Evidence-Only Closure

- Closure status: `COMPLETE`.
- Authorization: Planner/human-authorized independent evidence-only closure on `2026-09-07` (`Asia/Shanghai`).
- Purpose: procedurally close the original preflight output-limit blocker on the exact frozen implementation identity. This closure adds no feature change and no new functional test evidence.
- Actual model/profile: `GPT-5` Codex session / `v0.3.coder.deep`; the exact backend variant and reasoning-effort label are not exposed to this session.
- Production/test changes during closure: none.

### Preflight And Identity Evidence

Pre-check HEAD command:

```powershell
git rev-parse HEAD
```

- Exit code: `0`.
- Tool-observed wall time: `0.2790197s`.
- Complete, untruncated output: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.

Pre-check six-file patch identity command:

```powershell
git diff --binary -- "com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs" "com.rice.ai-codedb/Editor/AICodedbActions.cs" "com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" "com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1" | git hash-object --stdin
```

- Exit code: `0`.
- Tool-observed wall time: `0.4716799s`.
- Complete, untruncated output: `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.

Bounded per-file existence/status command:

```powershell
$paths = @('com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs','com.rice.ai-codedb/Editor/AICodedbActions.cs','com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs','com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs','com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $failed = $false; foreach ($path in $paths) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Write-Output "FILE MISSING path=$path"; $failed = $true; continue }; $status = @(git status --short -- $path); if ($LASTEXITCODE -ne 0) { Write-Output "FILE STATUS_ERROR path=$path"; exit 2 }; $statusSummary = if ($status.Count -eq 0) { 'clean' } else { ($status -join ' | ') }; Write-Output "FILE OK path=$path status=$statusSummary" }; if ($failed) { exit 3 }
```

- Exit code: `0`.
- Tool-observed wall time: `0.5942356s`.
- Captured output: six complete, untruncated summary lines, exactly one for each allowed implementation/test file; every file existed and reported unstaged `M` status.
- No file contents were emitted.

Protected-authority status command:

```powershell
$protected = @(git status --short -- "com.rice.ai-codedb/Editor/AICodedbControlContract.cs" "com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs" "com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1" "com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1" "com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs" "com.rice.ai-codedb/Payload~/payload-manifest.json"); if ($LASTEXITCODE -ne 0) { exit 2 }; if ($protected.Count -ne 0) { $protected; exit 3 }; Write-Output 'PROTECTED_STATUS CLEAN'
```

- Exit code: `0`.
- Tool-observed wall time: `0.3460705s`.
- Complete, untruncated output: `PROTECTED_STATUS CLEAN`.

Post-check HEAD command:

```powershell
git rev-parse HEAD
```

- Exit code: `0`.
- Tool-observed wall time: `0.2457224s`.
- Complete, untruncated output: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.

Post-check six-file patch identity command:

```powershell
git diff --binary -- "com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs" "com.rice.ai-codedb/Editor/AICodedbActions.cs" "com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" "com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1" | git hash-object --stdin
```

- Exit code: `0`.
- Tool-observed wall time: `0.2659721s`.
- Complete, untruncated output: `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.
- Total tool-observed wall time for the six closure commands: `2.2027002s`.
- The original aggregate `rg` route search was not rerun.

### Reused Evidence And Budget Ledger

- Reused unchanged-identity focused evidence: `-ControlContractReinstallOnly`, exit `0`, wall time `16.0994323s`, complete output, originally run once on patch identity `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.
- New functional test batches in this closure: `0`.
- Cumulative focused L0 batches: `1/1` used.
- Corrected retry in this closure: `0`; cumulative corrected retries remain `0/1` used. The remaining retry was not consumed.
- Scoped `git diff --check`: not rerun; the existing pass on the same frozen patch identity is reused.
- Closure command failures: `0`; closure retries: `0`.
- Output-limit status: all six closure command captures were complete and untruncated; aggregate closure output remained bounded to hashes and short summaries.

### NOT RUN / DEFERRED Boundaries

- `NOT RUN`: any additional L0, Supervisor Node, Package-boundary, full materializer, repository-wide test, C# compile, EditMode, Unity, Unity MCP, real process, consumer/third-party Package, release, publication, or deployment validation.
- `NOT RUN`: S04 `-ActivationContractOnly`, S05 `-ActivationTransactionOnly`, S06 `-ActivationRetirementOnly`, and any rerun of S07 `-ControlContractReinstallOnly` or scoped `git diff --check`.
- `DEFERRED`: C# compilation and focused EditMode tests in `UnityValidationProject/`.
- `DEFERRED`: real Manager confirmation, current Supervisor/fallback routing, cold start, Domain Reload/Play, real obsolete-project Reinstall, long-lived holder behavior, and final P0 layered acceptance.
- No Unity or Unity MCP was started or contacted. No commit, push, process control, production/test edit, or Verifier dispatch occurred.

### Closure Completion Routing

- Current task: `cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall`.
- Current closure status: `COMPLETE` on HEAD `8ccaec40df8773ee0296c4160f8357d5fd7125d3` and six-file patch identity `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.
- Closure meaning: the prior output-limit blocker is procedurally closed by a new bounded, untruncated preflight on the unchanged snapshot; this does not broaden or replace the existing functional evidence.
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: perform convergence review of the frozen identity and closure evidence, then decide whether to route the same snapshot to `v0.3.verifier.deep` for targeted read-only acceptance.
- Verifier routing, commit, and push: not performed by Coder.

当前 S07 独立 evidence-only closure 已完成；下一步需要通知 Planner 对冻结身份与程序性闭合证据做收敛复审，并决定是否路由 `v0.3.verifier.deep`。

## FIX 01 - Repeated Explicit Reinstall Evidence

- Status: `COMPLETE`.
- Authorization: Planner/human-authorized bounded FIX on `2026-09-07` (`Asia/Shanghai`).
- Finding correspondence: closes `VERIFICATION-01.md` P1, which found that the focused fixture only reread committed records instead of issuing a second explicit confirmed Reinstall. This was an evidence gap; no production defect was established.
- Actual model/profile: `GPT-5` Codex session / delegated `v0.3.coder.deep`; the exact backend variant and reasoning-effort label are unavailable to this session.

### Changes

- FIX implementation file: `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` only.
  - Added `Current` to the fixture admission input set so the wrapper can model the actual post-migration admission state without reusing stale `ObsoleteReinstallRequired` evidence.
  - Replaced passive repeated JSON reads with a second explicit `ConfirmedProjectMutation=true` request through `Invoke-ControlContractReinstallFixtureRequest`.
  - Derived the second request's `Current` migration state from the first request's actual `COMMITTED` activation/operation and current-selection agreement.
  - Proved the second request was rejected before materializer invocation (`Invoked=false`, `Result=null`) and preserved current selection, the complete contract snapshot, `activation.json`, `operation.json`, authenticated legacy evidence, and the unrelated sentinel.
  - Preserved the existing unconfirmed, `InvalidOrAmbiguous`, candidate-before-selection, pre-commit retry, current/COMMITTED identity, and byte-preservation assertions.
- Record file appended: this `RESULT.md`.
- The five existing C# files were not changed by FIX 01. No production or protected-authority file was changed.

### Snapshot Identity

- Pre-FIX HEAD: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
- Pre-FIX six-file patch identity: `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.
- Final HEAD: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
- Final six-file patch identity: `e7443205eeff78aafbb4783af1a192e68cec9691`.
- Six-file identity method remained the binary diff of the five existing C# files plus `test-codedb-host-payload-materializer.ps1`, piped to `git hash-object --stdin`.
- Pre-FIX identity command: exit `0`, wall time `1.155095s`, complete and untruncated output.
- Pre-test final-patch identity command: exit `0`, wall time `0.3600228s`, complete and untruncated output.
- Post-test identity command: exit `0`, wall time `0.5348633s`, complete and untruncated output.
- Five-file C# diff identity/protected-status pre-check: exit `0`, wall time `0.4999369s`, complete and untruncated output.
- Five-file C# diff identity/protected-status post-check: exit `0`, wall time `0.6324528s`, complete and untruncated output.
- The five C# per-file diff hashes matched before and after FIX 01:
  - `AICodedbManagerWindow.cs`: `7c715e5ec6aacb0a3baccc6ffc6a274e6fee9efd`.
  - `AICodedbActions.cs`: `fcc9a15e1d6cb4ac0ba2dd75ba2e42630b3b8227`.
  - `AICodedbHostPayloadMaterializer.cs`: `ab2bdf7a51f6eab1d9b54430d522dd7439493f68`.
  - `AICodedbManagerUiTests.cs`: `02553d8b421d363931b6aff7b8182cd0282a6926`.
  - `AICodedbEditorLifecycleTests.cs`: `316fc1bb5fa585e306f337f9b3d570e2a0bdfc07`.
- Protected-authority scoped status was `CLEAN` before and after FIX 01.

### Focused Corrected Retry

Exact command, run exactly once in FIX 01:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ControlContractReinstallOnly
```

- Exit code: `0`.
- Wall time: `16.8788779s`.
- Captured output disposition: complete and untruncated.
- Captured output:

```text
[OK] Explicit obsolete-contract Reinstall rejected unconfirmed and ambiguous admission, verified its candidate before selection, retried after pre-commit failure, committed one current instance, rejected a repeated confirmed request after migration became current, and preserved selection/contract/legacy/unrelated bytes.
[OK] Focused obsolete control-contract explicit Reinstall scenarios passed.
```

- Specific repeated-request result: post-commit evidence resolved the fixture migration admission to `Current`; the second explicit confirmed request returned `Invoked=false` and `Result=null`. Passing assertions establish that no materializer call or second activation/operation occurred and all required snapshots remained unchanged.

### Scoped Diff Check

Exact command, run exactly once after the final FIX 01 edit:

```powershell
git diff --check -- "com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs" "com.rice.ai-codedb/Editor/AICodedbActions.cs" "com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" "com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1"
```

- Exit code: `0`.
- Wall time: `0.2500509s`.
- Captured output disposition: complete and untruncated; no output.

### Batch And Retry Ledger

- Original focused L0 batch: `1/1` used before FIX 01.
- FIX 01 corrected retry: `1/1` used; exactly one invocation, no further retry.
- Cumulative `-ControlContractReinstallOnly` invocations: `2` (original batch plus the one authorized corrected retry).
- FIX 01 scoped `git diff --check`: `1` authorized invocation, passed.
- Command failures: `0`; output truncations: `0`; context compactions during FIX 01: `0`.
- The focused L0 and corrected-retry budgets are now exhausted.

### NOT RUN / DEFERRED

- `NOT RUN`: AST parse, full diff, any additional S07 invocation, S04 `-ActivationContractOnly`, S05 `-ActivationTransactionOnly`, S06 `-ActivationRetirementOnly`, Supervisor Node, Package-boundary, full materializer, other L0/L1, C# compile, or repository-wide tests.
- `NOT RUN`: Unity, Unity MCP, EditMode, cold start, PlayMode, Domain Reload, real Supervisor/Codex/MCP/project/business process, consumer/third-party Package acceptance, commit, push, publication, deployment, or release validation.
- `DEFERRED`: C# compilation and focused EditMode execution in `UnityValidationProject/`.
- `DEFERRED`: real Manager confirmation, authenticated Supervisor and one-shot fallback routing, real obsolete-project Reinstall, lifecycle scheduling, long-lived holder behavior, sequential activation history, and final P0 layered acceptance.
- No Unity or Unity MCP was started or contacted. No commit, push, production edit, protected-authority edit, or Verifier dispatch occurred.

### FIX 01 Completion Routing

- Current task: `cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall`.
- Current FIX status: `COMPLETE` on HEAD `8ccaec40df8773ee0296c4160f8357d5fd7125d3` and six-file patch identity `e7443205eeff78aafbb4783af1a192e68cec9691`.
- P1 disposition: the required repeated explicit confirmed Reinstall idempotence evidence is now present in the focused fixture; production behavior was not changed.
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: review FIX 01 against the original P1 and its adjacent regression boundary, then decide whether to route the final frozen snapshot for targeted read-only verification.
- Verifier routing, commit, and push: not performed by Coder.

当前 S07 bounded FIX 01 已完成；下一步需要通知 Planner 仅复审原 P1 与紧邻回归，并由 Planner 决定后续是否路由 `v0.3.verifier.deep`。

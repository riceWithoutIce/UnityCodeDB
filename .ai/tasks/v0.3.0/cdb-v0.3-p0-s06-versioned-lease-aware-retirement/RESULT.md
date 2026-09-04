# Result: cdb-v0.3-p0-s06-versioned-lease-aware-retirement

## Outcome

- Status: `COMPLETE` for the frozen S06 Coder scope.
- Base/HEAD: `0164ee59905d7f72e8d3b4404babf02a6cfed543` (exact match before and after implementation).
- Final uncommitted patch identity: Git blob hash `e81e726f7430cb50a71ef0a994a7ab5d4a178a85` from the binary diff of the four changed implementation/test files.
- Actual execution identity: Codex based on GPT-5, using the assigned `v0.3.coder.deep` reasoning profile. No model/profile/session escalation occurred.
- Context compactions observed during S06 execution: `0`.

## Changed Files

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - Extends the existing versioned control-contract namespace with strict `retirements/<operation-id>.json` intent paths and bounded immutable intent documents.
  - Binds each intent to control/runtime contract identity, project identity/root, activation epoch, operation id, selected and retired instance identities, generation identities, and exact instance/generation manifest hashes.
  - Adds exact nullable `retirement_intent_path` and `retirement_intent_sha256` fields to the existing activation operation journal; publication occurs before `COMMITTED`, and recovery removes an uncommitted intent with its activation attempt.
  - Validates namespace/cardinality/path/hash/cross-record identity strictly; missing, mismatched, orphaned, extra, redirected, or malformed evidence fails closed.
  - Adds committed-intent-only retirement cleanup. It revalidates current selection, intent, old instance/generation closure, no-reparse boundaries, MCP leases, Editor leases, and Coordinator evidence before the fence, after the fence, and immediately before deletion.
  - Live, invalid, unavailable/ambiguous holder evidence returns `READY` with `PENDING` without stopping a process or changing the retired closure. Stale owned lease evidence is removed only after proof; only the intent-bound instance is deleted. The immutable intent remains as audit evidence.
  - Keeps legacy generation/flat cleanup mechanically separate and starts it only after intent-bound instance cleanup is complete, preventing an old generation from being removed while its retired instance still has a holder.
  - Reuses serialized `Upgrade` convergence for a current usable selected instance with `cleanup_state=PENDING`; this branch performs retirement only and does not provision a candidate or switch selection.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - Adds the mutually exclusive `-ActivationRetirementOnly` fixture batch.
  - Covers committed intent binding, missing/mismatched/orphan fail-closed behavior, activation with a live previous holder, no-holder completion, live MCP/Editor/Coordinator preservation, invalid and ambiguous evidence preservation, natural drain, stale reclamation, repeated idempotence, immutable audit evidence, unchanged current selection/sentinel, and preservation of an arbitrary unbound instance.
  - Starts at most one short-lived fixture-owned holder. It is closed through stdin and exits with code `0` from a `finally` block; cleanup never stops it.
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - Routes `Ready + PENDING` to a distinct `Retire` convergence plan through the existing background scheduler, serialized Supervisor request queue, and `Upgrade` command.
  - Preserves 30-second periodic backoff, defers while maintenance is suspended or reconcile is in flight, and does not set `RetrySoon`.
  - `Ready + COMPLETE`, invalid selection, and blocked state do not select retirement.
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - Adds direct pure-decision coverage for `Retire`, Complete/invalid suppression, one throttled request, in-flight backoff, and Play/compile/update deferral.
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s06-versioned-lease-aware-retirement/RESULT.md`
  - Records the exact implementation snapshot, focused evidence, budget ledger, guarded/deferred boundaries, risks, and completion routing.

No other production, test, payload, configuration, runtime, Package generation, or task-contract file was modified. In particular, `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` and `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1` remain unchanged.

## Snapshot Evidence

- Final modified paths: exactly the four files listed above.
- Final SHA-256 identities:
  - `9aca2b7c9dd9e5c1c86fd70f1dd9aa936c3404c100aa83630f0aaef935a4fa7f` — `codedb-instance-engine.ps1`
  - `44a3b7aae43626c7ed368b55a7b5a7c2536a0b4a1c26c737667776adfe0045b1` — `test-codedb-host-payload-materializer.ps1`
  - `32b5b619d0a36fd3b6fa3ab9b6d998a05d453f3c1299b592409f244c22af0301` — `AICodedbEditorLifecycle.cs`
  - `2acf652ed0173be2578c34be0f96dcde934ec11a0576bf904408280962ad06b0` — `AICodedbEditorLifecycleTests.cs`
- Final line delta: engine `+461/-45`; harness `+288/-2`; Lifecycle `+40/-9`; Lifecycle tests `+79/-2`.
- Targeted PowerShell AST parse: `PASS` for engine and harness before the focused batch and after the concrete fixture correction.
- Final scoped `git diff --check`: exit `0`, no output.

## Focused L0 Evidence

Exact command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationRetirementOnly
```

Initial run:

- Exit: `1`.
- Wall time: `12.9625566s`.
- Concrete fixture-only failure: the missing-intent scenario moved the intent to `<operation-id>.json.missing` inside the strict `retirements/` namespace, so the strict unknown-entry check correctly fired before the intended missing-reference assertion.
- Captured failure:

```text
Missing committed retirement intent returned an unexpected error: Instance retirements root contains unexpected entry: <operation-id>.json.missing
```

Corrected retry:

- Correction: moved the temporary missing-intent file to the disposable run root, outside the strict contract namespace. No production behavior changed.
- Retry count: `1/1` used.
- Same exact focused command; no replacement or additional test command.
- Final exit: `0`.
- The execution tool yielded one ongoing session; all waits continued that same session. Observed cumulative tool wait/wall time: `61.3260551s` (`30.0085335s + 30.0109463s + 1.3065753s`).
- Captured final output:

```text
[OK] Versioned retirement intents fail closed, preserve live/invalid/ambiguous holders, drain naturally, reclaim stale evidence, and delete only the intent-bound instance.
[OK] Fixture retirement lease holder exited normally without cleanup stopping it.
[OK] Focused versioned lease-aware retirement scenarios passed.
```

## Budget Ledger

- Focused L0 batch: `1/1` authorized scenario batch used.
- Focused command invocations: `2` total (`1` initial run plus the single authorized corrected retry).
- Corrected retries: `1/1` used; no retry budget remains.
- Package-boundary batches: `0`; the assertion file was unchanged, so no batch was required.
- Affected C# L1/EditMode batches: `0`; execution is `DEFERRED` because `EditMode authorization: NOT_REQUESTED`.
- Other L0/L1, S05 `-ActivationTransactionOnly`, full materializer/Supervisor suites, C# compilation, repository-wide regression, consumer/third-party Package, release, and publication: `0` / `NOT RUN`.
- Static-check command correction: one read-only `rg` expression initially failed because PowerShell expanded `$` inside the regex; the corrected literal search exited `0`. This was not a test batch or product retry.

## Guarded Boundaries And Risk

- Unity, `UnityValidationProject/`, Unity MCP, EditMode, Play/Domain Reload, real Codex Desktop, and real business processes were not opened, started, changed, or probed.
- The only authorized process exception was the single fixture-owned holder. It ran only inside a disposable project fixture, remained alive throughout each live/ambiguous-holder cleanup attempt, and exited normally from the harness `finally` block.
- No process was stopped, killed, signalled, or restarted by production retirement cleanup.
- Existing Package-manifest-authorized legacy generation/flat cleanup code was not redesigned; it remains a separate completion component after versioned instance retirement.
- `DEFERRED`: actual Unity lifecycle scheduling in `UnityValidationProject/`; real long-lived Codex/MCP and Editor drain; real Coordinator lifecycle; crash/restart and external Supervisor integration; sequential activation history; consumer/third-party Package acceptance; release/publication/deployment.
- Residual risk: the C# Lifecycle changes have direct source tests but no compiled/EditMode evidence under this authorization. Real process identity and long-lived drain behavior remain outside the disposable fixture evidence.
- All implementation remains uncommitted. No commit, push, deployment, or Verifier contact occurred.

## Completion Routing

- Current task: `cdb-v0.3-p0-s06-versioned-lease-aware-retirement`
- Current status: `COMPLETE` for frozen Coder scope; focused L0 `PASS`; C# L1/EditMode `DEFERRED`
- Return to: `UnityCodeDB v0.3 Planner`
- Planner next action: review the exact uncommitted four-file snapshot, the strict intent/holder contract, the one corrected fixture retry, and the deferred C# EditMode boundary; Planner decides whether and when to route the stable snapshot to Verifier.
- Verifier dispatch: not performed by Coder.
- Commit/push: not performed; any commit, push, Unity/EditMode run, additional test, or Verifier routing requires a later Planner/human decision.

## FIX 01 - Interrupted Retirement Intent Binding Recovery

### Outcome And Identity

- FIX status: `BLOCKED` at the final-evidence boundary. The bounded implementation is present, but the only authorized focused L0 invocation ran before one necessary final semantic correction; retry budget was `0/0`, so the final snapshot was not rerun.
- Base/HEAD before and after FIX: `0164ee59905d7f72e8d3b4404babf02a6cfed543`.
- FIX entry patch identity: `e81e726f7430cb50a71ef0a994a7ab5d4a178a85` (exact expected identity).
- Focused-L0 snapshot identity: `930bbe4c330f9ee7e5c1093ab4eead9f613ab134`.
- Final uncommitted four-file patch identity: `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`.
- Final SHA-256:
  - `5c97a34dab41e01c2bc36dc772f6210414fdb9115f7803fd9cc4e2d525f569ce` - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `931b74cde10b819cf486baf1b0c02e1ee34d8fe4bc47fc43bac2db7811d1fb03` - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `32b5b619d0a36fd3b6fa3ab9b6d998a05d453f3c1299b592409f244c22af0301` - unchanged S06 `AICodedbEditorLifecycle.cs`
  - `2acf652ed0173be2578c34be0f96dcde934ec11a0576bf904408280962ad06b0` - unchanged S06 `AICodedbEditorLifecycleTests.cs`

### Exact Changes

- `codedb-instance-engine.ps1`:
  - Leaves the ordinary `Get-InstanceActivationContractState` orphan/mismatch rejection unchanged.
  - Adds a recovery-only recognizer for the exact interrupted publication window: matching activation/operation records must both be `PREPARED`; journal intent path/hash must both be null; exactly one derived operation directory and one derived retirement intent must exist; namespace, no-reparse, bounded file, operation-root shape, contract/runtime/project/attempt, selected/retired identity, instance manifest, generation manifest, candidate closure, retired closure, and unchanged current selection must all validate.
  - `Invoke-InstanceActivationContractRecovery` falls back to that recognizer only after the ordinary state reader rejects the namespace. Any failed proof rethrows the original orphan error and preserves all evidence.
  - A successful proof removes only the exact PREPARED activation/operation records, derived intent, and operation staging directory through the existing attempt-removal path. The verified unselected candidate remains byte-preserved; recovery neither stops a holder nor creates mechanical retirement authority for it.
  - Adds a `PocFixture` plus exact environment-variable fault hook immediately after durable intent publication and before PREPARED journal binding.
- `test-codedb-host-payload-materializer.ps1`:
  - Adds a focused interruption scenario that exits at the exact durable-intent/unbound-journal window, proves old selection preservation, PREPARED/no-reference records, exact intent identities, and ordinary orphan rejection, then exercises the next Upgrade recovery.
  - Final assertions require the interrupted candidate closure to remain byte-identical and require no unbound `retired-instances/<candidate>.json` marker; the replacement activation must commit with its own valid retirement intent.
  - Existing ordinary committed-orphan rejection remains present and unchanged.
- No C# file, materializer entry script, Package boundary, payload, runtime state outside disposable fixtures, or task contract was changed by FIX 01.

### Static And Focused Evidence

- PowerShell AST parse before the focused batch: `PASS` for engine and harness.
- Scoped `git diff --check` invocation: exactly `1`; exit `0`, no output. It covered the focused-L0 snapshot identity `930bbe4c330f9ee7e5c1093ab4eead9f613ab134`.
- Exact focused command, invoked once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationRetirementOnly
```

- Exit: `0`.
- Total observed wall time across the same ongoing process session: `39.761s`.
- Captured output was complete and not truncated:

```text
[OK] Exact PREPARED intent-publication interruption remains orphan-rejected to ordinary readers and is recovered only from matching contract and instance identities.
[OK] Versioned retirement intents fail closed, preserve live/invalid/ambiguous holders, drain naturally, reclaim stale evidence, and delete only the intent-bound instance.
[OK] Fixture retirement lease holder exited normally without cleanup stopping it.
[OK] Focused versioned lease-aware retirement scenarios passed.
```

- Post-batch finding: the first recovery implementation reused `Remove-ValidatedRetiredInstance`, which creates a mechanical retired-instance marker before deletion. That marker would be unbound to the next committed intent and could keep later cleanup `PENDING`; a real candidate may also retain a live holder that cannot be stopped under S06. The final correction therefore preserves the validated candidate and does not mint deletion authority.
- Final engine/harness AST parse after that correction: `PASS`.
- Final focused L0: `NOT RUN` because this checkpoint authorized one invocation and retry `0/0`. The two final candidate-preservation/no-marker assertions are source-present but not execution-proven on final identity `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`.
- Final scoped `git diff --check`: `NOT RUN`; the single authorized invocation was already consumed before the final semantic correction.

### Budget, Deferred Boundaries, And Risk

- New independent `-ActivationRetirementOnly` L0 batch: `1/1` used.
- Focused command invocations: `1`; retries: `0/0`.
- AST parse: pre-batch and final targeted parses only.
- Scoped `git diff --check`: `1/1` used.
- S05, Package-boundary, other L0/L1, C# compile/EditMode, full materializer/Supervisor suites, broad diff, Unity, Unity MCP, and real business process validation: `0` / `NOT RUN`.
- `DEFERRED`: C# L1/EditMode and all original S06 deferred runtime/consumer/release boundaries remain unchanged.
- Residual risk/blocker: final identity has static parse evidence but lacks the authorized focused L0 and final diff-check evidence. A fresh, independently authorized evidence-only checkpoint is required to close FIX 01; this run cannot honestly report the final snapshot as `COMPLETE`.
- Implementation remains uncommitted. No reset, stash, clean, rebase, commit, push, Unity/Unity MCP action, business-process stop, or Verifier contact occurred.

### FIX 01 Completion Routing

- Current task: `cdb-v0.3-p0-s06-versioned-lease-aware-retirement`
- Current FIX status: `BLOCKED` at final focused-evidence closure; implementation is present on uncommitted identity `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`
- Return to: `UnityCodeDB v0.3 Planner`
- Planner next action: review the strict transitional recovery and candidate-preservation correction, then decide whether to authorize one new independent evidence-only `-ActivationRetirementOnly` run plus a final scoped `git diff --check` on the same frozen snapshot before any Verifier routing.
- Verifier dispatch: not performed by Coder.
- Commit/push: not performed.

## Evidence-Only Checkpoint - FIX 01 Final Snapshot

### Outcome And Frozen Identity

- Checkpoint status: `COMPLETE`. The missing final-snapshot dynamic and scoped diff evidence for FIX 01 was collected without changing the frozen production/test snapshot.
- Pre-check HEAD: `0164ee59905d7f72e8d3b4404babf02a6cfed543`.
- Pre-check four-file patch identity: `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`.
- Post-check HEAD: `0164ee59905d7f72e8d3b4404babf02a6cfed543`.
- Post-check four-file patch identity: `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`.
- Identity method: `git diff --binary -- <the four frozen files> | git hash-object --stdin`.
- Identity conclusion: `PASS`; HEAD and the four-file patch identity were unchanged before and after both authorized commands.

### Exact Evidence

Focused L0 command, invoked exactly once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationRetirementOnly
```

- Exit code: `0`.
- Total observed wall time across the initial yield and waits on the same execution session: approximately `91.0s`.
- The tool yielded an ongoing session; every subsequent wait continued that same session and did not restart the command.
- Captured output:

```text
[OK] Exact PREPARED intent-publication interruption remains orphan-rejected to ordinary readers and is recovered only from matching contract and instance identities.
[OK] Versioned retirement intents fail closed, preserve live/invalid/ambiguous holders, drain naturally, reclaim stale evidence, and delete only the intent-bound instance.
[OK] Fixture retirement lease holder exited normally without cleanup stopping it.
[OK] Focused versioned lease-aware retirement scenarios passed.
```

Scoped diff-check command, invoked exactly once:

```powershell
git diff --check -- "com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1" "com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1" "com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs"
```

- Exit code: `0`.
- Wall time: `0.2416499s`.
- Output: none.
- Conclusion: `PASS` on frozen patch identity `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`.

### Budget And Deferred Boundaries

- Independent focused `-ActivationRetirementOnly` L0 batch: `1/1` used.
- Focused command invocations: `1`; retries: `0/0`.
- Scoped four-file `git diff --check`: `1/1` used; retries: `0/0`.
- S05, Package-boundary, other L0/L1, C# compile, EditMode, Unity, Unity MCP, full test suites, broad diff, and real business process validation: `0` / `NOT RUN`.
- `DEFERRED`: C# L1/EditMode and all previously recorded S06 runtime, consumer, integration, release, and publication boundaries remain unchanged.
- Production/test changes in this checkpoint: none. The only write was this append-only evidence record in `RESULT.md`.
- Commit/push: not performed. Verifier was not contacted or dispatched.

### Evidence-Only Completion Routing

- Current task: `cdb-v0.3-p0-s06-versioned-lease-aware-retirement`.
- FIX 01 final evidence status: `COMPLETE` on frozen HEAD `0164ee59905d7f72e8d3b4404babf02a6cfed543` and four-file patch identity `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`.
- Return to: `UnityCodeDB v0.3 Planner`.
- Verifier dispatch: not performed by Coder.

当前 S06 evidence-only checkpoint 已完成，下一步需要通知 Planner 对冻结身份与新增证据做收敛复审，并决定是否通知 Verifier 进行原 P1 及紧邻回归的定向只读验收。

# VERIFICATION-01: cdb-v0.3-p0-s06-versioned-lease-aware-retirement

## Verdict

- Review mode: `GUARDED`
- Overall verdict: `PASS`
- `FAIL`: none
- One-time findings: 无（`BLOCKER` / `P1` / `P2` / `FOLLOW-UP` 均无）
- Review scope: original P1 interrupted retirement-intent binding recovery and its adjacent regressions only.

This verdict is not Unity, C# compiled/EditMode, real-process, consumer, or release acceptance.

## Frozen Identity And Admission

- Task input: `.ai/tasks/v0.3.0/cdb-v0.3-p0-s06-versioned-lease-aware-retirement/TASK.md`
- Coder evidence: same-directory `RESULT.md`, including `FIX 01` and `Evidence-Only Checkpoint - FIX 01 Final Snapshot`.
- Required and observed `HEAD`: `0164ee59905d7f72e8d3b4404babf02a6cfed543`
- Required and observed four-file patch identity: `e8924d0ed23be8090a7d85e50d50c7cc346df8bd`
- Identity method, executed once by this Verifier: `git diff --binary -- <four frozen files> | git hash-object --stdin`.
- Frozen paths observed modified and unstaged:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `.git/index.lock`: absent.
- Identity conclusion: `PASS`. The result matches the Planner-confirmed and RESULT-recorded checkpoint pre/post identity. No second identity or Git diff check was run.

## Directed Verification

### 1. Exact recovery-only intermediate state: PASS

- The intent path is derived as `retirements/<operation-id>.json` from the same S04 contract context (`codedb-instance-engine.ps1:175-215`).
- Retirement intent construction and parsing bind the strict control/runtime contract, project root/identity, activation epoch, operation id, selected and retired instance identities, generation dispositions, instance/generation hashes, exact derived path, bounded regular-file read, and no-reparse boundary (`codedb-instance-engine.ps1:298-386`).
- `Get-InstanceActivationContractRecoveryState` is a separate recovery-only reader. It requires both activation and operation records, validates and cross-matches them, requires both phases to be exactly `PREPARED`, requires both journal intent fields to be null, and requires exactly one derived operation directory and one derived intent (`codedb-instance-engine.ps1:1144-1204`).
- The recognizer additionally requires the derived operation root to contain only `stage` and `backup`, with bounded regular evidence and at least one staged item (`codedb-instance-engine.ps1:1105-1142`). It then binds the intent to the PREPARED attempt/candidate/previous current, revalidates unchanged current selection, and validates both retired and unselected candidate closures against their exact manifest/generation identities (`codedb-instance-engine.ps1:1204-1257`).

### 2. Ordinary states remain fail-closed: PASS

- The ordinary `Get-InstanceActivationContractState` remains unchanged as the normal authority reader. Null journal intent references with any retirement entry are rejected as orphaned; referenced intent cardinality, path, hash, attempt, candidate, and previous-current relationships are all strict (`codedb-instance-engine.ps1:1012-1102`).
- Recovery first calls the ordinary reader. It invokes the recovery-only recognizer only after an ordinary rejection; if any recovery proof fails, it rethrows the original ordinary error before performing mutation (`codedb-instance-engine.ps1:1398-1418`). Thus ordinary orphan, mismatch, invalid, extra, or incomplete proof remains rejected and preserved.
- Direct fixture coverage checks that the exact unbound state is still rejected by the ordinary reader, and that missing, mismatched-hash, and orphaned committed intent states fail closed without changing immutable intent evidence (`test-codedb-host-payload-materializer.ps1:6944-6948`, `6981-7019`).

### 3. Recovery cleanup is exact and does not mint authority: PASS

- For the accepted PREPARED recovery state, `Remove-InstanceActivationContractAttempt` removes only the exact activation record, operation record, recognized intent, and derived operation staging directory (`codedb-instance-engine.ps1:1387-1396`, `1420-1424`). It does not call candidate deletion, retirement-fence publication, holder classification, or process-stop code.
- The verified interrupted candidate returned by the recognizer is intentionally not deleted. The focused fixture snapshots the candidate before recovery and proves byte identity afterward; it also proves no `control/retired-instances/<candidate>.json` marker was created (`test-codedb-host-payload-materializer.ps1:6949-6971`).
- The subsequent Upgrade selects a replacement candidate and leaves a `COMMITTED` operation with its own valid retirement intent (`test-codedb-host-payload-materializer.ps1:6954-6979`).

### 4. Exact fault window and adjacent test coverage: PASS

- The fixture-only hook exits immediately after durable intent publication/read-back and before the PREPARED operation is republished with the intent path/hash (`codedb-instance-engine.ps1:1260-1268`, `1453-1557`).
- The focused scenario enables that hook only around one disposable Upgrade and requires exit `88` with the exact fault message. It verifies dual PREPARED records, null intent references, durable derived intent, candidate/retired identity binding, unchanged old selection, and ordinary-reader rejection (`test-codedb-host-payload-materializer.ps1:6905-6952`).
- The same scenario then executes the next Upgrade recovery and asserts candidate byte preservation, no unbound marker, new selection, `COMMITTED` replacement operation, and a replacement retirement intent (`test-codedb-host-payload-materializer.ps1:6954-6979`).

### 5. Original S06 adjacent commitments: PASS

- Retirement cleanup requires a `COMMITTED` operation and matching retirement intent, validates current selection and the exact retired closure, and returns `PENDING` rather than deriving deletion authority from mechanical markers (`codedb-instance-engine.ps1:3301-3331`, `3435-3468`).
- Holder evidence is clear only when MCP leases, Editor leases, and Coordinator evidence contain no live or invalid state. Cleanup revalidates intent authority and holders after publishing the mechanical fence and again immediately before deleting only the intent-bound instance (`codedb-instance-engine.ps1:3333-3350`, `3395-3432`).
- The focused fixture covers live MCP, Editor, and Coordinator preservation; invalid and ambiguous preservation; normal holder exit/drain; stale evidence reclamation on the drained pass; unchanged current selection/sentinel; no-holder deletion; arbitrary unbound-instance preservation; and repeated idempotence (`test-codedb-host-payload-materializer.ps1:6981-7149`). The fixture-owned holder is closed normally in `finally`; production cleanup does not stop it.
- Lifecycle source keeps `Ready + PENDING` on the serialized `Retire` plan without redeploying current, while `Ready + COMPLETE`, invalid selection, in-flight work, and Play/compile/update boundaries suppress or defer it with periodic backoff (`AICodedbEditorLifecycle.cs:699-728`, `1026-1092`; `AICodedbEditorLifecycleTests.cs:3112-3235`). These are direct source/test assertions only; execution remains deferred.

## Reused Final Evidence

The Verifier did not rerun tests. The following Coder evidence is accepted only for the frozen identity above:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationRetirementOnly
```

- Invocations: `1/1`
- Retry: `0/0`
- Exit: `0`
- Observed wall time: approximately `91.0s`, across one continuing execution session.
- Recorded output:

```text
[OK] Exact PREPARED intent-publication interruption remains orphan-rejected to ordinary readers and is recovered only from matching contract and instance identities.
[OK] Versioned retirement intents fail closed, preserve live/invalid/ambiguous holders, drain naturally, reclaim stale evidence, and delete only the intent-bound instance.
[OK] Fixture retirement lease holder exited normally without cleanup stopping it.
[OK] Focused versioned lease-aware retirement scenarios passed.
```

Coder also recorded one scoped four-file `git diff --check`: exit `0`, no output, retry `0/0`, on the same pre/post patch identity. This Verifier reused that evidence and did not rerun it.

## NOT RUN / DEFERRED

- `NOT RUN` by this Verifier: `-ActivationRetirementOnly`, S05, Package-boundary, other L0/L1, C# compilation, EditMode, Unity, Unity MCP, full materializer/Supervisor suites, broad/full diff, repository-wide regression, and real business-process validation.
- `DEFERRED`: compiled C# and actual Lifecycle scheduling in `UnityValidationProject/`; real long-lived Codex/MCP and Editor lease drain; real Coordinator lifecycle; crash/restart and external Supervisor integration.
- `DEFERRED`: sequential activation history, consumer/third-party Package behavior, release, publication, and deployment acceptance.
- Residual risk is limited to those explicitly deferred runtime/integration classes. Direct Lifecycle tests are source-present but were not compiled or executed in this acceptance.
- This verification modified no production/test/TASK/RESULT/runtime/configuration/process state. The only added artifact is this report.

## Completion Routing

- Next role: `UnityCodeDB v0.3 Planner`
- Human decision gate: `ACCEPT` / `FIX` / `DEFER` / `STOP`
- No Coder contact, fix dispatch, commit, push, or next-role dispatch was performed.

当前 S06 定向验收已完成，下一步需要通知 Planner 汇总，并由用户决定 `ACCEPT` / `FIX` / `DEFER` / `STOP`。

# Verification 02: cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall

## Verdict

- Review mode: `GUARDED` directed FIX re-review.
- Overall verdict: `PASS`.
- Date: `2026-09-07` (`Asia/Shanghai`).
- One-time findings: 无。`BLOCKER` / `P1` / `P2` / `FOLLOW-UP` 均无。
- Scope: only the original `VERIFICATION-01.md` P1 and its immediately adjacent regressions.

## Frozen Identity And Admission

- Expected and observed HEAD: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
- Expected and observed six-file patch identity: `e7443205eeff78aafbb4783af1a192e68cec9691`.
- Identity was checked once from the binary diff of the six frozen files named in the review request.
- Working directory: repository root.
- `.git/index.lock`: absent at admission.
- Identity conclusion: `PASS`; no drift was observed, so the directed re-review proceeded.

## Original P1 Disposition

- Original finding: the first focused fixture reread committed records but did not issue a second explicit confirmed Reinstall.
- Disposition: `CLOSED`.
- After the first successful Reinstall, the fixture reads the real current selection plus the produced activation and operation records, requires both records to be `COMMITTED`, requires the operation action to be `REINSTALL`, and requires the operation candidate instance to equal the selected current instance (`test-codedb-host-payload-materializer.ps1:7321-7346`).
- That post-success evidence resolves the fixture migration input to `Current`; stale `ObsoleteReinstallRequired` evidence is not reused.
- The fixture then calls the same `Invoke-ControlContractReinstallFixtureRequest` wrapper with the derived `Current` state and `ConfirmedProjectMutation=true` (`test-codedb-host-payload-materializer.ps1:7348-7350`).
- The wrapper admits materialization only for exact `ObsoleteReinstallRequired`; therefore the repeated request returns before `Invoke-Materializer`, with `Invoked=false` and `Result=null` (`test-codedb-host-payload-materializer.ps1:7237-7260`, `:7351-7352`).
- Before the repeated request, the fixture snapshots current selection, the complete contract tree, `activation.json`, `operation.json`, authenticated legacy evidence, and the unrelated sentinel. It compares every snapshot afterward and requires byte/tree equality (`test-codedb-host-payload-materializer.ps1:7334-7339`, `:7353-7358`). This also proves no second activation or operation was created or changed within the contract tree.

## Adjacent Regression Review

- `PASS`: unconfirmed and `InvalidOrAmbiguous` requests remain rejected before materialization with project-state preservation (`test-codedb-host-payload-materializer.ps1:7277-7287`).
- `PASS`: injected candidate failure still proves candidate verification before selection; the selection remains absent and legacy/sentinel bytes remain unchanged (`test-codedb-host-payload-materializer.ps1:7289-7303`).
- `PASS`: the subsequent explicit retry succeeds and retains candidate-before-completion ordering (`test-codedb-host-payload-materializer.ps1:7305-7319`).
- `PASS`: current selection, `COMMITTED` activation/operation, `REINSTALL` action, and candidate/selection identity remain asserted (`test-codedb-host-payload-materializer.ps1:7321-7333`).
- `PASS`: final legacy and unrelated sentinel preservation assertions remain present after the repeated-request checks (`test-codedb-host-payload-materializer.ps1:7357-7360`).
- `PASS`: the five C# files retain the pre-FIX per-file diff identities recorded in `RESULT.md`; FIX 01 changed only the PowerShell fixture.
- `PASS`: directed current-source review confirms confirmation remains explicit from Manager to Actions/materializer, the Manager suppresses its generic Reinstall reconcile, and Actions requests one reconcile only after one successful command (`AICodedbManagerWindow.cs:1870-1897`; `AICodedbActions.cs:202-275`).
- `PASS`: the existing direct C# test matrix for cancellation, confirmation propagation, exact admission, one command/one reconcile, Supervisor confirmation serialization, fallback gating, and no automatic Lifecycle Reinstall remains present. Execution remains deferred.

## Reused Evidence

- FIX 01 corrected retry command: `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ControlContractReinstallOnly`.
- Coder-recorded corrected retry: exit `0`, wall time `16.8788779s`, exactly `1/1`, complete and untruncated output, no further retry.
- Cumulative focused S07 invocations: `2` (the original batch plus the one authorized corrected retry); the test budget is exhausted.
- The corrected output explicitly reports rejection of the repeated confirmed request after migration became current and preservation of selection/contract/legacy/unrelated bytes.
- Coder-recorded scoped six-file `git diff --check`: exit `0`, wall time `0.2500509s`, complete capture with no output.
- Both evidence items are bound by `RESULT.md` to final patch identity `e7443205eeff78aafbb4783af1a192e68cec9691`. The Verifier reused them and did not rerun either command.

## Evidence Boundary

- Read: the original P1 in `VERIFICATION-01.md`, the appended FIX 01 section of `RESULT.md`, the corrected fixture wrapper/scenario, and only the directly adjacent Manager/Actions source and named test assertions.
- Performed: one frozen HEAD/six-file identity admission check and directed static reads.
- Not performed: a new full diff, repository-wide search, general S07 audit, or S04-S06 re-review.
- No production, test, task, result, protected-authority, or existing dirty file was modified. This report is the only written artifact.

## NOT RUN / DEFERRED

- `NOT RUN`: `-ControlContractReinstallOnly`, scoped `git diff --check`, AST parse, any additional S07 command, S04 `-ActivationContractOnly`, S05 `-ActivationTransactionOnly`, S06 `-ActivationRetirementOnly`, Supervisor Node, Package-boundary, full materializer, other L0/L1, C# compile, and repository-wide regression.
- `NOT RUN`: Unity, Unity MCP, EditMode, cold start, PlayMode, Domain Reload, real Supervisor/Codex/MCP/Editor/business processes, consumer/third-party Package acceptance, commit, push, publication, deployment, and release validation.
- `DEFERRED`: C# compilation and focused EditMode execution in `UnityValidationProject/`.
- `DEFERRED`: real Manager confirmation, authenticated Supervisor and one-shot fallback routing, real obsolete-project Reinstall, Lifecycle scheduling, long-lived holder behavior, sequential activation history, and final P0 layered acceptance.

## Residual Risk And Routing

- The original static-evidence gap is closed. No remaining finding exists within this directed re-review boundary.
- C# and real runtime behavior remain unexecuted and must not be inferred from the static review or disposable PowerShell fixture.
- Next role: `UnityCodeDB v0.3 Planner`.
- Next action: Planner consolidates this PASS and presents the human gate; the Verifier does not contact Coder, dispatch a repair, commit, push, or notify another role automatically.
- Human gate: the user decides `ACCEPT` / `FIX` / `DEFER` / `STOP`.

S07 定向修复复审已完成，下一步由 Planner 汇总并由用户决定 `ACCEPT` / `FIX` / `DEFER` / `STOP`。

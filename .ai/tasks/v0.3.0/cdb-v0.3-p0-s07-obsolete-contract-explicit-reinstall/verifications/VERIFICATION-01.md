# Verification: cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall

## Verdict

- Review mode: `GUARDED`
- Overall verdict: `FAIL`
- Date: `2026-09-07` (`Asia/Shanghai`)
- One-time findings: one `P1`; `BLOCKER`, `P2`, and `FOLLOW-UP` findings are `None`.
- Scope: frozen S07 explicit-Reinstall objective and its adjacent regressions only.

## Frozen Identity And Admission

- Expected and observed HEAD: `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
- Expected and observed six-file patch identity: `9bdf5107aaedf9d99aac61be1d4080c8e9e1c5d5`.
- Identity was computed once from the binary diff of the six frozen files named in `TASK.md`.
- Working directory: repository root.
- `.git/index.lock`: absent at admission.
- Protected-authority scoped status: `CLEAN` for `AICodedbControlContract.cs`, `AICodedbStatusSnapshot.cs`, `codedb-instance-engine.ps1`, `materialize-codedb-host-payload.ps1`, `codedb-project-supervisor.mjs`, and `Payload~/payload-manifest.json`.
- The original `RESULT.md` output-limit record remains historically `BLOCKED`, but its appended independent evidence-only closure is complete and untruncated on the same HEAD and patch identity. Admission therefore proceeded on that closure; no feature or test evidence was inferred from it.

## One-Time Findings

### P1 - Focused L0 does not exercise repeated explicit Reinstall idempotence

The frozen task requires the focused fixture to prove that repeated completion is idempotent, and the routed acceptance scope states this more specifically as explicit repeated execution idempotence. The fixture executes an unconfirmed refusal, an ambiguous refusal, one injected candidate failure, and then exactly one successful confirmed Reinstall (`test-codedb-host-payload-materializer.ps1:7277`, `:7283`, `:7292`, and `:7305`).

After that success, the fixture snapshots the contract directory and only reads `activation.json` and `operation.json` again before comparing the snapshot (`test-codedb-host-payload-materializer.ps1:7334-7337`). It does not issue a second explicit confirmed Reinstall. Repeated reads of already committed records do not establish the behavior of repeated explicit execution.

Impact: the reused `-ControlContractReinstallOnly` exit `0` proves the other exercised scenarios, but it does not close this required S07 acceptance point. This is a required-evidence failure, not proof that the production transaction is defective. It is not a `BLOCKER` under the task's severity definition, but it prevents a `PASS` verdict for the frozen acceptance scope.

## Criterion Review

1. Exact admission and presentation: `PASS` by directed static review.
   - The production lifecycle constructs `ControlContractReinstallRequired` only after valid installed integration and trustworthy `PREREQUISITE=CURRENT` evidence (`AICodedbEditorLifecycle.cs:772-847`).
   - The Manager consumes cached status and exposes Reinstall only for `NeedsAttention + ControlContractReinstallRequired`; it does not read the classifier or filesystem (`AICodedbManagerWindow.cs:1830-1867`; `AICodedbHostPayloadMaterializer.cs:573-587`).
   - The worker-side action independently requires explicit confirmation, cached prerequisite `Current`, current integration `Installed`, and current migration `ObsoleteReinstallRequired` (`AICodedbActions.cs:202-245`). Exact enum comparisons reject uninstalled, invalid, ambiguous, unknown, and unrelated states.

2. Confirmation, cardinality, and reconcile: `PASS` by directed static review.
   - Cancellation invokes no action. Confirmation passes `confirmedProjectMutation=true` explicitly into one asynchronous action (`AICodedbManagerWindow.cs:1870-1897`).
   - One command is awaited; only a successful non-null result requests one reconcile, while failure/null/unconfirmed results do not retry or reconcile (`AICodedbActions.cs:248-279`).
   - The Manager disables its generic post-action reconcile for Reinstall, leaving Actions as the single successful-Reinstall reconcile owner.

3. Supervisor and one-shot fallback authority: `PASS` by directed static review.
   - Actions attempts the existing Supervisor route first and invokes fallback only when the Bridge-authored result carries `OneShotFallbackAuthorized` (`AICodedbActions.cs:282-304`).
   - The unchanged Bridge requires no current selection, the reviewed `materialize/Reinstall` command with explicit confirmation, and an absent or empty current Supervisor control directory. Any control entry or evidence-reading exception fails closed (`AICodedbSupervisorBridge.cs:1869-1935`).
   - Direct source tests cover forged authorization rejection, outage rejection, unconfirmed Reinstall rejection, confirmed empty-bootstrap admission, and non-empty control-evidence rejection (`AICodedbEditorLifecycleTests.cs:813-923`).

4. Focused fixture transaction evidence: `FAIL` because of the P1 finding.
   - Present: authenticated-obsolete-shaped legacy evidence, unconfirmed and invalid/ambiguous refusal before materialization, injected candidate verification failure before selection, explicit retry after that failure, current selection plus `COMMITTED` activation/operation agreement, and byte-preservation checks for legacy and unrelated sentinel content (`test-codedb-host-payload-materializer.ps1:7268-7339`).
   - Missing: a second explicit confirmed Reinstall after successful completion and assertions proving that repeated execution is idempotent.

5. S04-S06 authority preservation: `PASS` within the static and identity boundary.
   - The protected classifier, materializer script, instance engine, Supervisor, status snapshot, and payload manifest are clean.
   - Manager remains cache-only. Lifecycle contains no automatic `"Reinstall"` command, and the accepted Bridge/activation/rollback/retirement authorities were reused rather than copied into the six-file S07 change.

## Reused Evidence

- Focused L0 command: `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ControlContractReinstallOnly`.
- Coder-recorded result: exit `0`, wall time `16.0994323s`, batch `1/1`, retry `0/1`, complete untruncated output with the two expected `[OK]` lines.
- Scoped six-file `git diff --check`: Coder-recorded exit `0`, no output, same patch identity.
- These results were reused exactly as recorded. The Verifier did not rerun them and does not extend their claim beyond the scenarios actually exercised.

## Evidence Boundary

- Read: `TASK.md`, `RESULT.md`, the six frozen source/test files, and only the directly referenced Lifecycle/Bridge/status/fallback functions needed to evaluate the stated S07 criteria.
- Performed: one HEAD/six-file identity admission check, one protected-authority scoped status check, and directed static source/test reads.
- No repository-wide search, full diff, full audit, or S04-S06 re-review was performed.
- No source, test, task card, result, protected authority, or existing dirty file was modified. This verification report is the only written artifact.

## NOT RUN / DEFERRED

- `NOT RUN`: `-ControlContractReinstallOnly`, scoped `git diff --check`, any additional L0, S04 `-ActivationContractOnly`, S05 `-ActivationTransactionOnly`, S06 `-ActivationRetirementOnly`, Supervisor Node, Package-boundary, full materializer, other L0/L1, C# compile, and repository-wide regression.
- `NOT RUN`: Unity, Unity MCP, EditMode, cold start, PlayMode, Domain Reload, real Supervisor/prerequisite/Codex/MCP/Editor/holder or other business processes, consumer/third-party Package acceptance, commit, push, publication, deployment, and release validation.
- `DEFERRED`: C# compilation and focused EditMode execution in `UnityValidationProject/`.
- `DEFERRED`: real Manager confirmation, authenticated current Supervisor routing, empty-current-runtime fallback, real obsolete-project Reinstall, lifecycle scheduling, long-lived holder behavior, sequential activation history, and final P0 layered acceptance.

## Residual Risk And Routing

- Acceptance risk: repeated explicit Reinstall behavior remains unproven by the focused L0 evidence, as described in the P1 finding.
- Environment risk: the C# route and real runtime behavior remain deferred and must not be inferred from static tests or the disposable PowerShell fixture.
- Next role: `UnityCodeDB v0.3 Planner`.
- Next action: Planner should consolidate this one-time finding and return it to the user. The Verifier does not contact Coder, prescribe a repair, commit, push, or dispatch another role.
- Human gate: the user decides `ACCEPT` / `FIX` / `DEFER` / `STOP`.

当前 S07 定向验收已完成，下一步通知 Planner 汇总并由用户决定 `ACCEPT` / `FIX` / `DEFER` / `STOP`。

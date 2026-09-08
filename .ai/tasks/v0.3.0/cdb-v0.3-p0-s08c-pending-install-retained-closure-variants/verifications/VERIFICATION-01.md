# Verification: combined S08a/S08b/S08c

## Verdict

- Primary task: `cdb-v0.3-p0-s08c-pending-install-retained-closure-variants`
- Review mode: `GUARDED` directed read-only acceptance
- Overall verdict: `PASS`
- Date: `2026-09-07` (`Asia/Shanghai`)
- One-time findings: 无。`BLOCKER` / `P1` / `P2` / `FOLLOW-UP` 均无。
- Scope: only the frozen S08a/S08b/S08c findings and their immediately adjacent regressions.

## Frozen Identity And Admission

- Working directory: repository root (`.`).
- Expected and observed HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Expected and observed two-file patch identity: `aae922016172611d6742e7d878cf1d9e6378c617`.
- Expected and observed engine identity: `fbad2e20bf6059912a930d0db61ae54cfc154ad6`.
- Expected and observed harness identity: `5af62c199883b33458b0b776e922b7cdaca202c5`.
- Frozen files:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- `.git/index.lock`: absent at admission.
- Protected `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`: scoped status `CLEAN`.
- Identity conclusion: `PASS`; the review proceeded on the exact Planner-routed snapshot. Identities and protected status were not checked a second time.

## Criterion Review

1. Completed-Uninstall fresh Install and ordinary fail-closed behavior: `PASS`.
   - The exact non-legacy authenticated `UNINSTALLED + COMPLETE` path, with current/LKG selections absent and the prior committed candidate root absent, may supersede the old strictly validated COMMITTED attempt only for explicit `Install` (`codedb-instance-engine.ps1:1432-1488`).
   - The focused harness directly retains assertions for a new instance identity, current selection, current generation/stable wrapper, `INSTALLED + COMPLETE`, byte-exact MCP namespace restoration, business-sentinel preservation, repeated-Install rejection, and ordinary installed missing-selection refusal (`test-codedb-host-payload-materializer.ps1:5643-5731`).
   - Invalid, incomplete, mismatched, ambiguous, and non-explicit paths do not enter this exception: contract parsing remains strict, explicit Install requires authenticated UNINSTALLED state, and the ordinary COMMITTED branch still requires a validated current selection. These variants were evaluated statically, not claimed as new dynamic coverage.

2. Pending-Uninstall present/absent variant distinction: `PASS`.
   - Aggregate `PENDING` is not used as proof that the prior instance exists. The engine performs an exact `Get-Item -LiteralPath -Force -ErrorAction Stop`; only `ItemNotFoundException` establishes absence (`codedb-instance-engine.ps1:1447-1466`).
   - A present path still enters complete `Get-ValidatedRetiredInstance` validation and must match the COMMITTED candidate evidence (`codedb-instance-engine.ps1:1468-1481`). That validator rejects non-directories, reparse points, unexpected/incomplete contents, invalid identity/state, and generation-closure mismatch (`codedb-instance-engine.ps1:3005-3075`). Lookup, access, or enumeration failures are not converted into absence.
   - The present-instance pending variant remains a strict source path and retains the existing retirement binding. It was not represented as an additional dynamic S08c variant.

3. Admission and pre-activation revalidation: `PASS`.
   - Pre-lock admission latches only an authenticated non-legacy `UNINSTALLED` state id whose cleanup is `PENDING` or `COMPLETE`; under the operation lock, pending handoff requires the same state id and exact `UNINSTALLED + PENDING` state (`codedb-instance-engine.ps1:3781-3831`).
   - After candidate verification and immediately before supersession, the engine requires the same state id, non-legacy `UNINSTALLED + PENDING`, unchanged activation/operation hashes, no retirement intent, current/LKG absence, and the initially admitted present-versus-absent variant (`codedb-instance-engine.ps1:3902-3963`).
   - The strict contract reader binds activation epoch, operation id, phase, candidate evidence, operation-directory cardinality, and retirement-intent identity (`codedb-instance-engine.ps1:1012-1102`; `:766-780`).

4. Candidate-before-selection and obsolete cleanup: `PASS`.
   - Immutable generation publication and `New-VerifiedInstanceCandidate` occur before the candidate-pause handshake and before activation mutations (`codedb-instance-engine.ps1:3892-3911`).
   - The fixture directly verifies at the pause that desired state remains `UNINSTALLED`, current selection is absent, the prior instance is not recreated, and retained generation/lease/owner evidence is unchanged (`test-codedb-host-payload-materializer.ps1:5880-5925`).
   - After release, the existing transaction publishes the verified candidate and `INSTALLED` desired state under one journaled activation transaction, then commits the activation/operation pair (`codedb-instance-engine.ps1:1516-1730`; `:3964-3988`).
   - Automatic cleanup captures the old state id before the lock and exits obsolete after the Install transaction changes desired-state identity (`codedb-instance-engine.ps1:4067-4101`). The fixture directly asserts that behavior and preservation of the new selection/MCP state (`test-codedb-host-payload-materializer.ps1:5926-5960`).

5. Absent-instance authority and preservation: `PASS`.
   - With no retained previous instance, the transaction does not create a retirement intent, and installed cleanup becomes `COMPLETE`; retirement intent creation is conditional on non-null `PreviousInstance` (`codedb-instance-engine.ps1:1538-1604`; `:2760-2764`).
   - The absent fixture snapshots the retirement-control tree and proves no retirement authority was added. It also proves the prior instance stays absent and the generation lease bytes, generation tree, owner process, and complete MCP/user configuration remain unchanged (`test-codedb-host-payload-materializer.ps1:5869-5879`; `:5911-5918`; `:5946-5958`).
   - No source path recreates the absent previous instance or gives it mechanical retirement authority. Unrelated mutation remains constrained to the existing activation plan; completed-cleanup fresh Install separately retains the business-sentinel byte assertion. No claim is made that S08c added a second dynamic business-file variant.

6. Present variant and S08a/S08b adjacency: `PASS` within the declared evidence boundary.
   - Present prior-instance handoff remains on full validation and is passed as `PreviousInstance`, preserving the existing retirement-intent binding and cleanup `PENDING` semantics (`codedb-instance-engine.ps1:1468-1481`; `:3836-3840`; `:3934-3944`; `:3976-3988`).
   - Existing completed-cleanup Install, Install waiting behind same-state-id cleanup, ordinary missing-selection refusal, repeated Install refusal, candidate pause, obsolete-cleanup skip, active closure/holder preservation, and later Uninstall regressions remain part of the unchanged focused harness.
   - The final `-UninstallOnly` output reports all of those focused acceptance groups as passing. This review does not convert the present variant or extra invalid/reparse variants into newly executed standalone cases.

7. Evidence qualification: `PASS`.
   - Direct final dynamic coverage: the absent-prior-instance pending-Uninstall fixture, candidate pause, atomic Install, old cleanup obsolescence, retained lease/generation/owner/MCP state, and no unbound retirement authority.
   - Static/current-source plus adjacent evidence only: present-prior-instance pending handoff and extra file/non-directory/reparse/access/incomplete/identity-mismatch variants.
   - The S08c `RESULT.md` explicitly preserves this distinction and does not claim Unity, C#, real-runtime, consumer, or release acceptance.

## Reused Evidence

- Two-file AST parse: Coder-recorded exit `0`; both frozen PowerShell files reported `AST_OK`; complete and untruncated output.
- Focused command: `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly`.
- Coder-recorded focused result: exit `0`, wall time `105.4148265s`, batch `1/1`, retry `0/0`, complete and untruncated output.
- Focused output includes completed/repeated Uninstall and fresh Install recovery, ordinary missing-selection refusal, MCP namespace preservation, cleanup/Install serialization, absent-instance candidate pause and commit, obsolete cleanup, active closure preservation, crash/retry convergence, and terminal `[OK] Uninstall CodeDB acceptance scenarios passed.`
- Two-file scoped `git diff --check`: Coder-recorded exit `0`, no output.
- All reused evidence is bound by `RESULT.md` to HEAD `6408b0d540b32584147588efb67ecc5ba12b2fda` and final two-file identity `aae922016172611d6742e7d878cf1d9e6378c617`.
- The Verifier did not rerun AST parsing, `-UninstallOnly`, `git diff --check`, or any other test/static command.

## Evidence Boundary

- Read: the three frozen TASK/RESULT pairs, the direct activation recovery/convergence/transaction/cleanup/strict-validation functions in the engine, and the adjacent `Invoke-UninstallAcceptanceScenarios` fixture.
- Performed: one HEAD/two-file/per-file identity admission capture, one protected-materializer scoped status check, and directed source/fixture reads.
- Not performed: full diff, repository-wide search, repeated Git checks, broad S08 review, or unrelated regression analysis.
- Production/test files remained read only. This verification report is the only written artifact.

## NOT RUN / DEFERRED

- `NOT RUN`: AST parse, `-UninstallOnly`, scoped `git diff --check`, any other materializer mode, S08 commands `1` or `3-8`, no-switch/full harness, other L0/L1, C# compile, and repository-wide diff/test.
- `NOT RUN`: Unity, Unity MCP, EditMode, PlayMode, cold start, Domain Reload, real Manager/Supervisor/Codex/MCP/holder or business processes, consumer/third-party Package acceptance, commit, push, publication, deployment, and release validation.
- `DEFERRED`: present-instance and additional invalid/non-directory/reparse/access/incomplete/identity-mismatch variants as standalone dynamic cases.
- `DEFERRED`: the complete S08 code-freeze batch, C# compilation/focused EditMode in `UnityValidationProject/`, real Unity/runtime flows, consumers, and release gates.

## Residual Risk And Routing

- Residual risk: present-instance and additional invalid evidence variants were established by strict current-source paths and adjacent evidence, not by new standalone dynamic runs. C#/Unity and real process behavior remain unexecuted.
- Next role: `UnityCodeDB v0.3 Planner`.
- Next action: Planner consolidates this combined PASS and presents the human gate. The Verifier does not contact Coder, dispatch a repair, commit, push, or notify another role automatically.
- Human gate: the user decides `ACCEPT` / `FIX` / `DEFER` / `STOP`.

当前 combined S08a/S08b/S08c 定向验收已完成，下一步需要通知 Planner 汇总，并由用户决定 `ACCEPT` / `FIX` / `DEFER` / `STOP`。

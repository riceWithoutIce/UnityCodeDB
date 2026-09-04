# VERIFICATION-01: cdb-v0.3-p0-s05-candidate-activation-transaction

## Verdict

- Review mode: `GUARDED`
- Bounded verdict: `PASS`
- `BLOCKED`: none
- `FAIL`: none
- `DEFERRED`: dynamic/integration/release classes listed below
- One-time findings: none (`BLOCKER` / `P1` / `P2` / `FOLLOW-UP` all none)

This acceptance is limited to the frozen S05 candidate-activation transaction and its direct S04 versioned-contract dependency. It is not a repository-wide, Unity, consumer, runtime, or release acceptance.

## Admission And Snapshot Binding

- Task: `.ai/tasks/v0.3.0/cdb-v0.3-p0-s05-candidate-activation-transaction/TASK.md`
- Coder evidence: same-directory `RESULT.md`, including the corrected `CHECKPOINT-09` record and final `CHECKPOINT-10` record.
- Frozen base and observed `HEAD`: `769e5c12c7678e490dd25845c9d60c04d4a2b17e`
- Worktree: the two declared implementation/test paths are modified and unstaged; TASK/RESULT are task artifacts; no other implementation path was admitted.
- `.git/index.lock`: absent.
- No commit, push, reset, clean, stash, rebase, or source/test mutation was performed by this Verifier.

Observed input hashes:

| Input | SHA-256 |
| --- | --- |
| `TASK.md` | `0e9c84c991a2342b40d97d8fd2aaf348d594e598367c6c2b956a90c58c532e97` |
| `RESULT.md` | `831a77948532ab36af94dc4a22e95a5d295f17ecad9f5a491c1bbe9de95e7d90` |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `6d57dd50326e606ea863767d87b8fd268135e076b2254fbbf2df332625d4959b` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `6fdc7f830c7c838395f91350665c0ffa95eaa11b853f086ae95a1c500cd25d9f` |

The earlier RESULT checkpoints remain historical failure/partial records. `CHECKPOINT-10` is the final preserved snapshot evidence for this review: it corrected the allowlist placement, recorded the placement gate, and ran the single final focused batch successfully.

## Bounded Review

### Candidate-before-selection: PASS

- `Invoke-InstanceConvergence` performs candidate construction and verification at `codedb-instance-engine.ps1:3203-3219`, then enters activation at `:3220-3241`. The candidate failure fixture at `test-codedb-host-payload-materializer.ps1:6721-6727` asserts no versioned contract, no selection change, and no old-instance/generation change when verification fails.
- `New-VerifiedInstanceCandidate` reaches `READY` and the deterministic candidate probe before returning a candidate (`codedb-instance-engine.ps1:1708-1762`). The failure injection is before activation-contract publication.

### One attempt, identity pair, and phase semantics: PASS

- S04 creates distinct lowercase 32-hex `activation_epoch` and `operation_id` values and rejects equality (`codedb-instance-engine.ps1:212-226`). The activation and operation constructors carry the same pair and trusted contract/project context (`:404-487`), with phases restricted to `PREPARED`, `ACTIVATING`, and `COMMITTED` (`:411`, `:450`, `:538-540`, `:586-587`).
- `Publish-InstanceActivationTransaction` creates one attempt, writes a matching `PREPARED` pair before mutation, publishes the same attempt as `ACTIVATING`, then publishes `COMMITTED` only after all mutation verification and the selected-candidate callback (`codedb-instance-engine.ps1:1086-1183`, `:1185-1238`).
- The focused fixture checks the injected activation fault, retained `ACTIVATING` pair, equal operation/epoch identities, and final `COMMITTED` pair (`test-codedb-host-payload-materializer.ps1:6730-6772`).

### Low-level recovery evidence is not a second authority: PASS

- S05 recovery obtains state through `Get-InstanceActivationContractState`, which strictly reads and matches the versioned activation/operation pair (`codedb-instance-engine.ps1:857-917`).
- For `ACTIVATING`, `Get-InstanceActivationTransactionEntriesFromContract` derives rollback entries only from the authoritative versioned operation mutations (`:1001-1034`), and `Invoke-InstanceActivationContractRecovery` rolls back from those entries before removing the attempt (`:1044-1083`).
- The S05 publisher uses the versioned pair directly and does not call the legacy `Publish-InstanceOperation` writer (`:1086-1261`). The existing unversioned recovery call remains a separate mechanical recovery step in convergence (`:3153-3156`); its `PREPARED`/`COMMITTED` handling only removes its own legacy evidence, and its `ACTIVATING` handling restores pre-images. It does not publish, commit, or classify the S05 activation.
- The fixture explicitly asserts no legacy operation journal after activation failure and commit (`test-codedb-host-payload-materializer.ps1:6755-6756`, `:6777-6778`).

### Operation-directory cardinality: PASS

- S04 namespace validation admits only the two records, the `operations` root, and 32-hex operation directories (`codedb-instance-engine.ps1:820-855`).
- `Get-InstanceActivationContractState` requires both records together, rejects orphan operation evidence, and binds cardinality to the authoritative operation id: exactly one matching directory for `PREPARED`/`ACTIVATING`; zero or one matching directory for `COMMITTED`; every other count or name fails closed (`:868-910`).
- Recovery follows the phase rule: `PREPARED` removes an unstarted attempt, `ACTIVATING` proves reverse-order rollback, and `COMMITTED` verifies current selection against the candidate before finalizing residual operation evidence (`:1051-1083`).

### Rollback, commit, retry, and conflict: PASS

- Mutation entries are pre-imaged and staged before publication; each target is rechecked for pre-image drift, each published hash is verified, and rollback restores entries in reverse index order or reports that rollback was not proven (`codedb-instance-engine.ps1:1007-1033`, `:1185-1250`).
- The activation mutation boundary is the existing `Get-InstanceActivationEntries` set only: selection/LKG, stable wrapper, MCP config when stale, desired state, legacy integration-state removal when present, and generation pointers when required (`codedb-instance-engine.ps1:2246-2313`; RESULT lines 26-30). `-RetainPreviousInstance` records pending cleanup and does not delete or retire the previous selected instance.
- A pre-existing versioned contract blocks a new attempt instead of overwriting it (`codedb-instance-engine.ps1:1099-1107`). Identical retry after a committed current selection converges to `READY` without changing the committed journal; the fixture checks this byte stability (`test-codedb-host-payload-materializer.ps1:6780-6786`).
- Rewriting the committed operation epoch is rejected by strict cross-record identity matching (`test-codedb-host-payload-materializer.ps1:6788-6794`).

### Retirement, old instance, and external-process boundary: PASS

- The transaction call passes `-RetainPreviousInstance` (`codedb-instance-engine.ps1:1132-1140`), and its mutation set does not include retired-instance deletion or lease draining. The focused fixture snapshots the selected old instance and generation and asserts both remain byte-identical after failure and commit (`test-codedb-host-payload-materializer.ps1:6704-6706`, `:6724-6727`, `:6746-6748`, `:6774-6777`).
- The external MCP/legacy sentinel is preserved (`test-codedb-host-payload-materializer.ps1:6690-6703`, `:6777-6778`). The Verifier did not launch Unity, MCP, Codex, prerequisite probes, or any unrequested external process.
- Candidate-owned cleanup code is outside the accepted old-instance/retirement result: it only handles an unselected newly created candidate after failure; no old selected instance or external sentinel is targeted by the S05 transaction fixture.

## Final L0 Evidence (Coder-Recorded, Not Rerun)

The final CHECKPOINT-10 evidence is accepted as recorded evidence for this exact uncommitted snapshot. Per instruction, this Verifier did not rerun it:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationTransactionOnly
```

- Placement gate: `PASS`; foundation allowlist absent and transaction allowlist contains the stable-wrapper entry exactly once.
- Focused L0 batches: `1/1`
- Corrected retries: `0/0`
- Exit status: `0`
- Wall time: `21.9956949s`
- Recorded output includes the injected mutation fault reaching mutation 1 and:

```text
[OK] Versioned candidate-to-activation transaction covered pre-selection candidate failure, PREPARED/ACTIVATING/COMMITTED phases, rollback recovery, idempotent retry, conflict rejection, and protected old-state retention.
[OK] Focused activation transaction scenarios passed.
```

RESULT also records targeted AST/diff checks as `PASS`; its exact output-byte count and some internal active/paused telemetry are unavailable and were not estimated. Earlier CHECKPOINT-09 placement reporting was corrected by CHECKPOINT-10; no broader evidence is inferred from the earlier failed checkpoints.

## Deferred And Not-Run Boundaries

- `NOT RUN` by this Verifier: `-ActivationTransactionOnly`, Package-boundary tests, full materializer/Supervisor/unchanged L0 groups, Node/Supervisor validation, C# compilation, repository-wide regression, Unity/EditMode, Unity MCP, real prerequisite/Codex probes, and external-process validation.
- `DEFERRED`: C# and Unity integration, consumer/third-party Package behavior, release/publication acceptance, and all excluded tests.
- `DEFERRED`: retirement, lease drain, physical cleanup, consumer routing, Install/Upgrade/Reinstall UI behavior, later crash/restart/runtime behavior, and broader activation migration.
- No source, test, manifest/payload, selected/LKG state outside disposable fixtures, configuration, lease, or external process was changed by this verification.

## Completion Routing

- Return to: `UnityCodeDB v0.3 Planner`
- Human decision gate: `ACCEPT` / `FIX` / `DEFER` / `STOP`
- No Coder contact or repair dispatch was performed.

当前 `cdb-v0.3-p0-s05-candidate-activation-transaction` 的 `GUARDED` 定向只读验收完成，接下来需要通知 Planner 会话复核本报告，由 Planner/用户决定 `ACCEPT` / `FIX` / `DEFER` / `STOP`。

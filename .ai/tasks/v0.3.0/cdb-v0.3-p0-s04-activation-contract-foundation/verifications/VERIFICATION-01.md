# VERIFICATION-01: cdb-v0.3-p0-s04-activation-contract-foundation

## Verdict

- Review mode: `GUARDED`
- Overall verdict: `PASS`
- `FAIL`: none
- `BLOCKED`: none
- `DEFERRED`: integration, runtime, and release evidence listed below
- One-time findings: none (`BLOCKER` / `P1` / `P2` / `FOLLOW-UP` all none)

This verdict is limited to the frozen S04 activation-contract foundation and the three FIX 01 closures. It is not Unity, consumer, runtime, or release acceptance.

## Snapshot Binding And Admission

- Task input: `.ai/tasks/v0.3.0/cdb-v0.3-p0-s04-activation-contract-foundation/TASK.md`
- Result input: `.ai/tasks/v0.3.0/cdb-v0.3-p0-s04-activation-contract-foundation/RESULT.md`, including `FIX 01`
- Base SHA from TASK: `0c2178e113df2cb43a8936d3fcdb7ca5f6674c35`
- Observed `HEAD`: `0c2178e113df2cb43a8936d3fcdb7ca5f6674c35`
- Checkout form: the three reviewed implementation/test paths are modified and unstaged; `TASK.md` and `RESULT.md` are untracked; no commit was inferred.
- `.git/index.lock`: absent.
- Stationarity: two bounded captures used by this review retained the same `HEAD` and the same five input hashes.

| Input | SHA-256 |
| --- | --- |
| `TASK.md` | `05746e627a82b0b38b31e5007d3a13e97f93d16d15ea871c376a99521cb0c6b5` |
| `RESULT.md` | `fe21a3ae593040f8f970f95911127787de8fe4d711d2eacc79173df736f93ccc` |
| `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` | `47d88ea12ccb78d6c17ea825c9cb6474ee61ae3a2a80394b28fa2a72315a0040` |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `a05b929005c934360107885d0bf7ecc5770104199ba40f5d5b50e97029d949d4` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `baf2f1aab77b647eacefb177db01c7c4cb1bf20ead93c9eb585a3b2e05793504` |

Admission is `PASS`: TASK, appended FIX 01 RESULT, exact three-path scope, base/HEAD identity, and stable uncommitted snapshot evidence are present and mutually consistent.

## Focused Verification

### 1. Fresh namespace fail-closed and idempotence: PASS

- `codedb-instance-engine.ps1:696-740` allows only `activation.json`, `operation.json`, the `operations` root, and the unique current empty operation directory. Unknown entries, Supervisor state, another operation directory, non-directory records, redirected entries, and non-empty current operation evidence fail closed.
- `codedb-instance-engine.ps1:743-804` validates both documents and their shared identity before publication, rejects replacement semantics for a fresh contract, requires any existing records to be strictly readable and canonical-text identical, rechecks the namespace before and after publication, and reads both records back.
- `codedb-instance-engine.ps1:656-693` treats an existing record as idempotent only when its bounded bytes exactly equal the desired bytes; conflicting, malformed, oversized, or publication-race evidence is rejected.
- Direct fixture assertions at `test-codedb-host-payload-materializer.ps1:6470-6651` cover creation, no Supervisor state, byte-stable repeat, unknown entries, another/non-empty operation directory, cross-record mismatch, reserved `READY`, conflicting/malformed/oversized evidence, and reparse rejection.

### 2. Trusted target and role/phase semantics: PASS

- `materialize-codedb-host-payload.ps1:1481-1505` derives `TargetGenerationId` from the current manifest generation, derives `TargetGenerationManifestSha256` from that generation's exact `generation-manifest.json` target, and binds both runtime/manifest identities to the same trusted raw manifest hash.
- `codedb-instance-engine.ps1:290-313` requires candidate generation id/hash to match that trusted target with disposition `CURRENT`; current/LKG accept only `CURRENT` or `TRUSTED_PREVIOUS`; `COMMITTED` requires a non-null current identity fully equal to candidate.
- The operation/activation constructors and readers accept only `PREPARED`, `ACTIVATING`, and `COMMITTED`; the focused fixture rejects reserved `READY` and retains an `ACTIVATING` null-selection positive.
- Direct negative fixtures at `test-codedb-host-payload-materializer.ps1:6363-6445` cover missing target identity/hash, wrong target id/hash, non-current candidate, unsafe current/LKG dispositions, and invalid `COMMITTED` combinations.

### 3. Unique mutation targets and contiguous indices: PASS

- `codedb-instance-engine.ps1:315-344` normalizes every target and preserves the supplied non-negative index.
- `codedb-instance-engine.ps1:347-368` requires each record index to equal its zero-based array position.
- Both construction and read-back paths use an ordinal-ignore-case target set and reject duplicates (`codedb-instance-engine.ps1:463-470`, `591-597`).
- Direct negative fixtures at `test-codedb-host-payload-materializer.ps1:6447-6468` reject duplicate normalized targets and a non-contiguous index.

## Recorded L0 Evidence

The following is accepted as Coder-recorded evidence for this exact final snapshot; the Verifier did not rerun it:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationContractOnly
```

- Final FIX 01 batch count: `1/1`
- Retry count: `0`
- Exit: `0`
- Wall time: `5.780s`
- Exact recorded output:

```text
[OK] Versioned activation contract identity, paths, strict records, fresh provisioning, idempotence, and fail-closed boundaries passed.
[OK] Focused activation contract foundation scenarios passed.
```

RESULT also records PowerShell AST parsing and the three-path `git diff --check` as `PASS`. Its budget ledger states that focused output was tool-reported as 50 tokens and not truncated, while exact byte count and resumed-run timing/compaction counters were unavailable. Those gaps are disclosed rather than estimated, so this report does not treat them as stronger evidence or as a failure.

## Evidence Boundary And Residual Risk

- `NOT RUN` by this Verifier: `-ActivationContractOnly`, Package-boundary, full materializer, unchanged focused groups, Supervisor Node, C#, repository-wide tests, Unity/EditMode, Unity MCP, real prerequisite probes, and external-process validation.
- `DEFERRED`: C# compilation, Unity/EditMode, real Unity/Codex behavior, consumer Package behavior, and release acceptance.
- `DEFERRED`: candidate verification, actual activation/switching, atomic activation crash recovery, rollback, retirement, cleanup, consumer routing, and Install/Upgrade/Reinstall wiring.
- No source, test, TASK, RESULT, manifest/payload, runtime state, lease, configuration, or process was modified by this verification. The only added artifact is this report.
- Residual risk is confined to the explicitly deferred integration/runtime evidence classes and the fact that the final L0 result is Coder-recorded rather than independently rerun by the Verifier, as required by the verification boundary.

## Next Notification

- Return once to: `UnityCodeDB v0.3 Planner`
- Planner/user decision gate: `ACCEPT` / `FIX` / `DEFER` / `STOP`
- No Coder contact or repair dispatch was performed.

当前 `cdb-v0.3-p0-s04-activation-contract-foundation` 定向只读 `GUARDED` 验证完成，接下来需要通知 UnityCodeDB v0.3 Planner 会话复核本报告，由 Planner/用户决定 `ACCEPT` / `FIX` / `DEFER` / `STOP`。

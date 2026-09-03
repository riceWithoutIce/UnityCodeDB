# cdb-v0.3-p0-s04-activation-contract-foundation Result

## Result

- Status: `BLOCKED`
- Blocker class: focused-evidence budget exhausted after a post-pass bounded-read hardening.
- Base commit: `0c2178e113df2cb43a8936d3fcdb7ca5f6674c35`
- Execution profile: `v0.3.coder.deep`
- Actual model: GPT-5 Codex family (exact runtime model identifier unavailable)
- Actual reasoning effort: unavailable from the runtime
- Commit/push: not performed

The implementation is present in the allowed three code/test files. The corrected focused L0 retry passed, then static review found that the fresh-provision consistency path could read an existing conflicting record without first applying its size ceiling. That path was changed to use the bounded strict readers and bounded race checks. A third L0 execution would exceed the frozen hard maximum, so the final snapshot cannot be claimed as fully verified.

## Changes

- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - Added SHA-256 derivation from the exact byte array returned by the bounded strict JSON read.
  - Strictly parses manifest `control_contract` through the instance engine.
  - Exposes `ControlContract` and raw-byte `RuntimeContractSha256` on the trusted manifest model; keeps `ManifestSha256` bound to the same bytes.
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - Added strict control-contract identity parity, canonical identity/hash checks, and versioned activation/operation/Supervisor path derivation.
  - Added distinct activation epoch/operation identity generation and validation.
  - Added exact-field activation record, operation journal, instance/generation evidence, and ordered mutation/pre-image evidence constructors/readers.
  - Added bounded UTF-8 reads, lowercase hash checks, project/contract/runtime cross-binding, phase allowlists (`PREPARED`, `ACTIVATING`, `COMMITTED`), and explicit rejection of `READY`.
  - Added safe fresh namespace and exact operation-directory provisioning. Existing files must be valid and byte-identical; repeats are idempotent; conflicting, malformed, oversized, redirected, mismatched, or drifted evidence fails closed.
  - The foundation is not called by Install/Upgrade/Reinstall or any existing command route.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - Added mutually exclusive `-ActivationContractOnly` mode.
  - Added isolated fixture coverage for C#/Node identity/hash/path parity, raw manifest hashing, fresh provisioning, repeat idempotence, strict field/hash/phase failures, mismatch/conflict, malformed/oversized files, reparse rejection, and legacy/config separation.
  - Synthetic payload manifests now preserve the canonical existing `control_contract` required by strict manifest parsing.
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
  - Unchanged; no cross-language source assertion was necessary.

## Evidence

### Bounded preflight

- CWD: `G:\RiceProgram\UnityCodeDB`
- HEAD matched the frozen base: `0c2178e113df2cb43a8936d3fcdb7ca5f6674c35`
- Initial worktree contained only the untracked S04 task directory.
- Direct C#/Node inspection confirmed canonical identity text and the versioned Supervisor namespace.
- No stop condition was present before implementation.

### Focused L0

Batch 1:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationContractOnly
```

- Exit: `1`
- Wall time: `5.451s`
- Finding: nullable `previous_activation_record_sha256` was coerced through a typed PowerShell string parameter and rejected as an empty hash.
- Correction: preserve JSON null at the nullable parameter/assertion boundary while retaining rejection of an empty JSON string.

Corrected retry (batch 2):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationContractOnly
```

- Exit: `0`
- Wall time: `4.270s`
- Exact output:

```text
[OK] Versioned activation contract identity, paths, strict records, fresh provisioning, idempotence, and fail-closed boundaries passed.
[OK] Focused activation contract foundation scenarios passed.
```

Post-pass static hardening:

- Replaced unbounded existing-record consistency reads with the same bounded strict record readers.
- Added size-before-read and size-after-read checks to the publication race path.
- PowerShell AST parse: `PASS` for all three modified scripts.
- `git diff --check`: `PASS`.
- Dynamic rerun: `NOT RUN`; the one corrected retry hard maximum was already consumed.

### Budget ledger

- Focused materializer L0 batches: `2` (`1` initial + `1` corrected retry; hard maximum reached)
- Retry count: `1`
- Package-boundary L0 batches: `0` (file unchanged)
- Other L0/L1 batches: `0`
- Test wall time: `9.721s` total
- Task wall-clock interval before RESULT write: approximately `17m 40s`
- Paused time: `0s` observed
- Compaction/handoff count observed in this task execution: `1`
- Captured test output: tool-reported `169` tokens total; exact byte count unavailable; neither batch was truncated
- Per-batch capture ceiling: `20,000` tokens

## Boundaries And Risk

- `DEFERRED`: final-snapshot focused L0 rerun after the bounded-read hardening; requires a new Planner-authorized test budget/run.
- `DEFERRED`: C# compilation, Unity/EditMode, Unity MCP, real Unity/Codex behavior, consumer Package behavior, and release acceptance.
- `DEFERRED`: candidate verification, activation/switching, atomic activation crash recovery, rollback, retirement, cleanup, consumer routing, and one-action Reinstall.
- `NOT RUN`: full materializer suite, unchanged focused groups, Package-boundary L0, Supervisor Node, C# tests, repository-wide tests, real prerequisite probes, and external-process validation.
- No manifest/payload, C#/Node, runtime state, lease, project/user configuration, existing unversioned selection/LKG/journal, or external process was modified.
- Residual risk: the final bounded-read delta has syntax and diff evidence but no post-change dynamic execution because the frozen retry limit is exhausted.

## Completion Routing

- Current task: `cdb-v0.3-p0-s04-activation-contract-foundation`
- Current status: `BLOCKED`
- Return to: `UnityCodeDB v0.3 Planner`
- Planner next action: review the preserved final three-file implementation snapshot and authorize a fresh, single `-ActivationContractOnly` validation run (or explicitly accept the final static-only hardening evidence) before deciding whether to route the same snapshot to Verifier.
- Verifier dispatch: not performed by Coder.

## FIX 01 (2026-09-03)

### Result

- Status: `PASS`
- Scope: only the three Planner-confirmed findings were repaired on the preserved three-file snapshot.
- Commit/push: not performed.
- TASK rewrite: not performed.

### Changes

- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - The trusted Manifest model now carries the current target generation id and the SHA-256 declared for that generation's exact `generation-manifest.json` target.
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - Fresh provisioning now accepts only byte-identical canonical activation/operation records plus the unique current empty operation directory. Existing Supervisor state, unknown entries, another operation directory, redirected entries, a non-empty current operation directory, or conflicting evidence fail closed; identical same-attempt re-entry remains idempotent.
  - Candidate evidence must exactly match the trusted target generation id/hash and disposition `CURRENT`. Current/LKG evidence rejects `NEWER`, `SEQUENCE_COLLISION`, and `INVALID`; `COMMITTED` requires a non-null current identity fully equal to candidate, while PREPARED/ACTIVATING retain old-selection or null boundaries.
  - New and read-back operation journals reject duplicate normalized mutation targets and preserve exact contiguous zero-based indices.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - The focused fixture now binds candidate evidence to the canonical payload generation-manifest hash.
  - Added direct negative coverage for non-fresh namespace entries, invalid role/disposition/COMMITTED combinations, duplicate mutation targets, and non-contiguous mutation indices, while retaining PREPARED/idempotent and ACTIVATING/null positives.

### Verification

Static checks before the focused run:

- PowerShell AST parse: `PASS` for all three modified scripts.
- `git diff --check` over the three modified scripts: `PASS`.

Authorized focused L0 batch (exactly one):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -ActivationContractOnly
```

- Exit: `0`
- Wall time: `5.780s`
- Exact output:

```text
[OK] Versioned activation contract identity, paths, strict records, fresh provisioning, idempotence, and fail-closed boundaries passed.
[OK] Focused activation contract foundation scenarios passed.
```

FIX 01 budget ledger:

- ActivationContractOnly L0 batches: `1/1`
- Retry count: `0`
- Package-boundary/full materializer/Node/C#/Unity/Unity MCP/real-process batches: `0`
- Captured focused output: tool-reported `50` tokens; not truncated; exact byte count unavailable.
- Active/paused time and compaction count for the resumed FIX execution: unavailable as exact runtime counters; no estimate asserted.

### Boundaries And Risk

- `DEFERRED`: C# compilation, Unity/EditMode, Unity MCP, real Unity/Codex behavior, consumer Package behavior, and release acceptance.
- `DEFERRED`: candidate verification, actual activation/switching, crash recovery, rollback, retirement, cleanup, consumer routing, and Install/Upgrade/Reinstall wiring.
- `NOT RUN`: Package-boundary, full materializer, Supervisor Node, C#, repository-wide, Unity/EditMode, Unity MCP, and real-process tests.
- No manifest/payload, C#/Node, runtime state, leases, project/user configuration, existing selection/LKG/journal, or external process was changed.
- Residual risk is limited to the explicitly deferred integration/runtime evidence classes; the authorized focused final-snapshot batch passed without retry.

### FIX 01 Completion Routing

- Current task: `cdb-v0.3-p0-s04-activation-contract-foundation`
- Current status: `PASS`, ready for Planner review.
- Return to: `UnityCodeDB v0.3 Planner`
- Planner next action: review the final preserved three-file snapshot and the FIX 01 focused evidence, then decide whether to route that same snapshot to Verifier.
- Verifier contact/dispatch: not performed by Coder.

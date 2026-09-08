# Result: cdb-v0.3-p0-s08c-pending-install-retained-closure-variants

## Outcome

- Status: `COMPLETE` for the frozen S08c scope.
- Date: `2026-09-07` (`Asia/Shanghai`).
- Actual model/profile: GPT-5 Codex session dispatched as `v0.3.coder.deep`, `GUARDED`, `REUSE_ONLY`; exact backend variant and reasoning-effort label are unavailable to this session.
- One explicit Install from authenticated `UNINSTALLED + PENDING` now distinguishes a still-present committed candidate instance from a candidate instance that cleanup has already removed while another authenticated closure keeps aggregate cleanup pending.
- The one authorized `-UninstallOnly` batch passed, including the existing candidate pause, atomic Install, obsolete-cleanup interleaving, holder preservation, and adjacent absent-instance assertions.

## Admission Evidence

The single bounded admission capture completed before editing. All five read-only commands exited `0`; orchestration wall time was approximately `6.6s` and output was complete.

- HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Starting two-file patch identity: `d74922996e4a84920004acefe4c4db23e27d5dcf`.
- Starting engine patch identity: `1a66fd1d7075bb25f32dd956f5938415066d2a79`.
- Starting harness patch identity: `a576d7ee806b46aaa5dbdc20548411bf887b8249`.
- Scoped status contained only the modified engine/harness and expected untracked S08, S08a, S08b task records plus S08c `TASK.md`.
- Protected `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` was clean.

## Authority Decision

- The existing authority is sufficient; no schema, journal, desired-state field, protocol, or second policy owner was added.
- The exact authenticated non-legacy `UNINSTALLED + PENDING` desired-state document supplies the pinned old state id.
- The strict unchanged COMMITTED activation/operation pair supplies the prior candidate identity and supersession authority.
- Current and last-known-good selection must both be absent.
- For the present variant, the prior instance continues through the existing complete `Get-ValidatedRetiredInstance` and committed-candidate evidence equality checks.
- For the absent variant, only an exact `Get-Item -LiteralPath -Force -ErrorAction Stop` lookup ending in `ItemNotFoundException` is accepted. Existing files/directories/reparse evidence continue through strict validation or rejection; other lookup failures remain fail-closed.
- Immediately after candidate verification and before old-contract removal, the code rechecks the pinned desired state, activation/operation hashes, absence of retirement intent, current/LKG absence, and the originally admitted present-or-absent instance variant.
- Passing `PreviousInstance = null` for the absent variant uses the existing transaction path and therefore creates no retirement intent or retired marker for a nonexistent instance.

## Implemented Changes

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - Allowed pending-Uninstall recovery to retain the strict superseded COMMITTED contract when its exact prior instance path is proven absent.
  - Defined a pending handoff from the superseded contract ref, independently of whether a retained previous instance object exists.
  - Required current/LKG absence and revalidated the same present/absent variant immediately before supersession and activation.
  - Kept the present-instance branch on complete retained-instance validation and identity equality.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  - Made the candidate-pause fixture intentionally retain its generation lease while confirming the holder-free prior instance has been removed.
  - Asserted before commit and after obsolete cleanup that the prior instance remains absent and the lease owner, lease bytes, and generation bytes remain unchanged.
  - Asserted the selected instance identity is new and the retirement-control snapshot does not gain authority for the absent prior instance.
  - Removed the fixture lease only after the scenario completed, preserving later harness isolation.
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s08c-pending-install-retained-closure-variants/RESULT.md`: this record.
- Protected materializer and all other files were not intentionally modified.

## Static Evidence

One AST parse covered only the changed engine and harness:

```powershell
$files = @('com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $failed = $false; foreach ($file in $files) { $tokens = $null; $parseErrors = $null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $file).Path, [ref]$tokens, [ref]$parseErrors) | Out-Null; if (@($parseErrors).Count -ne 0) { $parseErrors | ForEach-Object { Write-Output "AST_ERROR file=$file message=$($_.Message)" }; $failed = $true } else { Write-Output "AST_OK file=$file" } }; if ($failed) { exit 1 }
```

- Exit code: `0`.
- Wall time: `0.5597375s`.
- Output: both files reported `AST_OK`; complete and untruncated (`37` tool-reported tokens).

One two-file scoped whitespace check ran after the functional batch:

```powershell
git diff --check -- 'com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1' 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'
```

- Exit code: `0`.
- Wall time: `0.2787561s`.
- Output: empty; no whitespace errors.

## Focused Functional Evidence

Exact command, invoked once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UninstallOnly
```

- Exit code: `0`.
- Total process wall time: `105.4148265s` in one ongoing execution session, below the `180s` limit.
- Batch: `1/1`; retry: `0/0`.
- Captured output: complete and untruncated; `210` tool-reported tokens, visibly below `64 KiB`.
- Passed output conclusions:
  - Complete/repeated Uninstall, suppression, fresh Install recovery, and ordinary missing-selection refusal passed.
  - Child-first and child-only MCP namespaces, BOM/EOL, comments, and custom keys were preserved.
  - Cleanup/Install lock serialization passed.
  - The absent-prior-instance pending Install reached candidate pause, committed atomically, and made waiting old cleanup exit without deleting selected instance or MCP state.
  - Active watcher/closure preservation and post-drain cleanup passed.
  - Uninstall crash/retry convergence passed.
  - Harness terminal line: `[OK] Uninstall CodeDB acceptance scenarios passed.`

## Final Identity And Scope

The single final capture completed after AST, functional, and diff-check evidence. All commands exited `0`; orchestration wall time was approximately `0.6s` and output was complete.

- Final HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Final two-file patch identity: `aae922016172611d6742e7d878cf1d9e6378c617`.
- Final engine patch identity: `fbad2e20bf6059912a930d0db61ae54cfc154ad6`.
- Final harness patch identity: `5af62c199883b33458b0b776e922b7cdaca202c5`.
- Final scoped status retained only the modified engine/harness and expected untracked S08/S08a/S08b/S08c task records; protected materializer remained clean.
- Changes remain uncommitted. No reset, clean, stash, rebase, amend, commit, push, publication, or deployment occurred.

## NOT RUN / DEFERRED

- `NOT RUN`: other materializer modes, S08 commands `1` or `3-8`, no-switch/full harness, other L0/L1, C# compile, repository-wide diff/test, and real runtime/process validation.
- `NOT RUN`: Unity, Unity MCP, EditMode, PlayMode, real Manager/Supervisor/Codex/MCP acceptance, consumer/third-party Package, release validation, commit, push, publication, and deployment.
- `DEFERRED`: S08 complete code-freeze batch, C# compilation/focused EditMode in `UnityValidationProject/`, Unity runtime, consumers, and release gates remain separate Planner-authorized work.
- Focused residual risk: present-instance strict retirement behavior and additional invalid/inaccessible/reparse variants were preserved statically but were not expanded into separate test batches beyond the frozen `-UninstallOnly` scope.

## Completion Routing

- Current task: `cdb-v0.3-p0-s08c-pending-install-retained-closure-variants`.
- Current status: `COMPLETE` for the frozen scope.
- Return to: `UnityCodeDB v0.3 Planner`.
- Planner next action: review the frozen identities, authority decision, and focused passing evidence; decide whether the combined S08a/S08b/S08c snapshot is stable enough for the next bounded workflow step.
- Verifier routing: not performed. Only Planner may decide whether and when to route a stable snapshot to `v0.3.verifier.deep`.
- Commit/push: not performed.

当前 S08c 已完成；下一步需要通知 `UnityCodeDB v0.3 Planner` 审核最终身份、authority 边界与唯一 focused L0 证据，并决定后续路由。未联系 Verifier。

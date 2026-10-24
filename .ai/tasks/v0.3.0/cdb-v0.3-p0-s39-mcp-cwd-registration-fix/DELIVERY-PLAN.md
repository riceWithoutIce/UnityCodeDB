# S39 cwd fix: prepared delivery candidate

Date: 2026-10-21. Status: APPROVED / DELIVERY_EXECUTION_PENDING.
The user explicitly approved this prepared sequence: "同意 批准".
The grant covers only the commit, exact export verification and target Package
reference switch below. Human-owned Unity and real-client gates remain separate.

## Frozen candidate

- Branch: `codex/mcp-project-cwd` in the attached isolated worktree.
- Base/HEAD: `237c72d9980114b99887fb8e805658447dd8d4fd`.
- Package: `com.rice.ai-codedb`, version `0.3.0-preview.5`, successor `poc.44`.
- Package allowlist: exactly the 41 paths and SHA-256 values in
  `SOURCE-SHA256.txt`, derived from the completed raw-byte review.
- Task-record allowlist: `TASK.md`, `RESULT.md`, `refresh-cwd-metadata.ps1`,
  `SOURCE-SHA256.txt`, and this `DELIVERY-PLAN.md`, under this task only.
- Preserve all unrelated original-checkout changes, predecessor generations,
  old Package deliveries, diagnostics and `.artifacts` evidence.

## Completed delivery preparation

Local evidence: `.artifacts/tests/s39-cwd-fix/delivery-projection/`.
An isolated index and object directory projected only the 41 Package paths onto
the base. Its review tree is `1ecbc434a12512202a26d33d0623a3d58fce9afc`.
The tree is not a commit, a formal export or an external delivery.

Git archive of this projected tree contains 664 Package files, all byte-equal
to the worktree source. The real index remains unchanged. Archive-extracted
closure/production admission PASS: 62 declared files, zero mismatches, native
source/build/binary bindings PASS. The already completed focused source tests
were not rerun against unchanged inputs during this preparation.

Ordinary Git staging may normalize the mixed-EOL successor common script and
break its declared hash. Use raw blob staging of the frozen allowlist, then
verify each indexed blob's SHA-256 before committing. Exclude the three
historical EOL-status artifacts; all 447 historical files are already proven
byte-identical to the base. Do not fix historical EOLs as part of delivery.

## Proposed authorized execution envelope

1. Recheck base, frozen source hashes and empty real staging area. Stage the
   exact allowlist using raw bytes, verify index scope and bytes, then create
   one commit on this branch. Do not push or merge the dirty primary checkout.
2. Run the existing `Tests~/export-codedb-package.ps1` against that exact commit
   into a fresh local artifact directory. Require both staged and extracted-ZIP
   closure/production-admission PASS. Run the affected cwd consumer Flow
   scenario once from the exact extracted ZIP under each supported PowerShell
   host; retain evidence and stop on the first failed gate.
3. Recheck that the target `<test-projects>/CodedbTest_1` is closed and its five
   frozen inputs still match the source review. Preserve its manifest and lock
   pre-images in task-owned backup evidence. Copy the exact extracted Package
   into a fresh sibling `<external-packages>/<new-commit>/com.rice.ai-codedb/`.
   Never overwrite the prior delivered Package.
4. Replace only the CodeDB local-file reference in the target manifest and lock
   with the new sibling Package reference, preserving unrelated bytes. Verify
   those two references and the copied artifact bytes. The project is not a Git
   repository; do not add Git initialization as a prerequisite.
5. Recheck that target MCP config, selected pointer and wrapper remain unchanged.
   Record the commit, ZIP hash, new relative reference, backups and completed
   gates. Stop before Unity launch or installation/client operations.

Stop on source/base/index drift, byte/closure failure, target occupancy or
external-baseline mismatch. Do not retry an unchanged operational attempt or
fall back to a different installation path. Preserve all evidence and partial
delivery facts if a later step fails; do not claim an atomic cross-file switch.
No missing-module bootstrap recovery from the older CodedbTest_0 delivery is
part of this candidate.

## Target baseline and human handoff

Current target reference is `file:../../Packages/237c72d/com.rice.ai-codedb`.
The config still uses `cwd = "."`; selected generation remains poc.43.
The five config/reference/pointer/wrapper hashes remain equal to the frozen
raw-byte review. Latest read-only check found no Unity process targeting this
project and no `Temp/UnityLockfile`; recheck immediately before external writes.

After delivery, the human opens CodedbTest_1 and reports compilation and Manager
state. Package-reference replacement alone does not prove that the installed
generation, activation contract or MCP config has migrated. Review that actual
state before selecting one existing explicit repair/upgrade/install route.
Do not manually patch config, wrapper, pointer or activation records to create
a passing state. Do not automatically uninstall/reinstall or stop processes.

Real-client acceptance follows only after this handoff: one new attributable
target chat, exact `mcp__codedb_codedbtest_1__*` namespace, agreed status/query
limits and response identity correlation. Disk READY or tool visibility alone
does not pass query acceptance. Attempt 04 remains ON_HOLD; older attempts are
not resumed. No new Unity project is required for this regression.

Unity launch, real installation/activation, real MCP, global config changes,
Unconfirmed investigation, performance and release acceptance are outside this
proposed commit/export/reference-switch grant.

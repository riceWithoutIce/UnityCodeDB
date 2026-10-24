# S39 cwd fix: bounded delivery result

Date: 2026-10-21. Status: DELIVERY_COMPLETE / HUMAN_UNITY_PENDING /
INSTALLED_STATE_MIGRATION_NOT_VERIFIED / REAL_CLIENT_ACCEPTANCE_ON_HOLD.

## Authority and committed snapshot

The user approved DELIVERY-PLAN.md with "同意 批准". The authorized commit,
exact export verification and CodedbTest_1 reference switch are complete.
No push or dirty-primary merge occurred.

- Branch: `codex/mcp-project-cwd` in the attached isolated worktree.
- Base: `237c72d9980114b99887fb8e805658447dd8d4fd`.
- Commit: `c848049d90fbdf618905be25225580642d98d987`.
- Committed tree: `22f5d4b1c96b94c429291f024bd4c7b4f4d2fb28`.
- Scope: exactly 41 frozen Package paths and the five listed task records.
- Indexed blobs were staged without EOL filters and independently checked
  against the frozen SHA-256 allowlist. The commit tree matches that index.
- Historical EOL-status artifacts were excluded, preserving predecessor bytes.

This result is a post-commit task record, not a second source commit.

## Exact artifact gates

Artifact: `.artifacts/exports/s39-cwd-c848049/com.rice.ai-codedb.zip`.
SHA-256: `3d266307ba7e052140575ada0c39d689e5a62d28a9aa3d686420f15e76a98a5d`.
The exact-commit exporter reports 664 files, 14,057,570 bytes and 664 ZIP entries.
Both commit-staged and exact-ZIP Package closure/production admission PASS:
62 declared files, zero hash mismatches and native binary bindings PASS.

The affected Flow scenario was run once per supported host from the exact
extracted ZIP: Windows PowerShell 5.1 PASS 16; PowerShell 7 PASS 16.
Evidence class remains CONTRACT_ISOLATED: real CodeDB calls and real Provider
starts are zero. Prior source Contract evidence is retained in RESULT.md.

Package version remains `0.3.0-preview.5`; selected Package successor is poc.44.
This is bounded local delivery, not public release or upgrade acceptance.

## External switch

Target: `<test-projects>/CodedbTest_1`.
The target's five frozen inputs matched before delivery. Unity process command
lines showed no process targeting this project, and no Temp/UnityLockfile was
present. These conditions were rechecked immediately before reference writes
and at completion. Other projects' Unity processes were not stopped.

The exact extracted Package was copied to a fresh sibling
`<external-packages>/c848049/com.rice.ai-codedb/`; all 664 copied files match.
The old `<external-packages>/237c72d/com.rice.ai-codedb/` remains preserved.
Only the CodeDB reference bytes in manifest and lock were replaced:

- Old: `file:../../Packages/237c72d/com.rice.ai-codedb`.
- New: `file:../../Packages/c848049/com.rice.ai-codedb`.

Manifest SHA-256:
`ad49d5ff6a089693720aa5bb4beb37922093d7fae3075d3b1cbef554081db08f`.
Lock SHA-256:
`21cf2101305eb0248f3ad029f1692faebbbb53160af2b886baa50aeb8e1de943`.
Both JSON references and exact replacement bytes were verified. Pre-images are
retained in `.artifacts/tests/s39-cwd-fix/delivery-execution/external-backup/`.

MCP config, selected pointer and wrapper remain byte-identical to their frozen
hashes. The config therefore still has cwd `.` and the selected instance remains
the predecessor poc.43. This delivery did not manually migrate installed state,
fabricate activation or execute repair/install to produce a passing result.
Reference writes completed sequentially, not as one cross-file atomic operation.

External write window: 2026-10-21T07:26:36.407Z to 07:26:49.202Z.
Machine-local receipt:
`.artifacts/tests/s39-cwd-fix/delivery-execution/external-switch-receipt.json`.

## Human handoff and remaining gates

The human may now open CodedbTest_1, wait for import/compile and report the
Manager status and any concrete compile/import errors. Do not click Install,
Repair or Uninstall as an implied part of this delivery. Review the observed
installed-generation/activation/config state first, then agree the appropriate
existing explicit action. Do not manually edit the config to repeat the earlier
visibility experiment or bypass the product flow.

No Unity launch, Install/Repair/Uninstall, real MCP query, reconnect or process
stop was performed. Attempt 04 remains ON_HOLD. Real-client attribution and one
bounded query still require the separate agreed target-chat sequence. Disk READY
or visibility alone does not establish query success. Unconfirmed remains deferred.

## Evidence

Under `.artifacts/tests/s39-cwd-fix/delivery-execution/`:

- `index-verification.json`: exact staged path and raw-byte receipt.
- `export.log`: staged and exact-ZIP closure plus artifact identity.
- `flow-powershell51.log`, `flow-pwsh7.log`: exact-ZIP consumer-flow results.
- `external-switch-receipt.json`: completed switch, hashes and protected inputs.
- `copied-package-sha256.json`: full delivered-file inventory.
- `external-backup/`: exact original manifest and lock.

Historical source/failed-fixture evidence and old deliveries were preserved.
The primary checkout remains at the base with its original 69 tracked-dirty
entries. The delivery worktree has an empty index, this untracked result and
four EOL-filter status entries (the historical three plus the new poc.44 common
script). `final-git-state.json` verifies all four are raw-byte identical to the
committed blobs; they are not additional source edits. Do not normalize or
stage them as a follow-up correction.

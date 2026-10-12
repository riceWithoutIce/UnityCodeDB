# S29 instance ID contract repair — Coder result

Date: 2026-10-12.

## Stable snapshot

- Base/HEAD: `9179d8a1a679056bef19b7e9246988510c3c9284`.
- Snapshot: working-tree-only; no commit, package export, Unity launch, MCP, Install, Uninstall, or reference switch.
- Allowlist: `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs` and `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`.
- Existing unrelated dirty Editor/Tests/Payload files are preserved.

## Finding and change

`AICodedbManagerActionJournal.FindUnownedProvisioningCandidate` was validating
instance directory names with `IsPhysicalKey`, whose 24-character rule belongs
to historical Manager Package directory keys. Producer instance IDs are 32
lowercase hexadecimal characters. The old check rejected a valid instance before
reading its manifest, converting normal current/legacy journal reads into
Conflict and hiding the normal action entry.

The reader now uses a separate `IsInstancePhysicalKey` 32-character lowercase
hex check. The historical receipt check remains 24-character. The current-index
path also passes its current action ID into legacy aggregation so an attributed
PROVISIONING candidate is not mistaken for an orphan.

Tests now use 32-character instance IDs and cover current/legacy reads for READY
and attributed PROVISIONING instances, invalid 24-character/uppercase/non-hex
directories, legacy and current-index orphan conflict, and the retained early
return guard. The old strict fail-closed orphan behavior is preserved.

## Verification performed by Coder

- Focused standalone compilation: `SEMANTIC errors=0`.
- Focused standalone tests: 9/9 PASS.
- Focused pre-fix comparison: the old 24-character instance check rejects the
  valid 32-character READY case, demonstrating the regression catches the
  original defect.
- Repository semantic compilation using
  `.artifacts/tests/s29-post-install-ui/Semantic.csproj`: `SEMANTIC errors=0`.
- `git diff --check` is clean for the two allowlisted files.
- No Unity/NUnit execution, native UI acceptance, real producer execution,
  payload regeneration, package export, commit, or release validation was run.

## Limits

The existing real project remains subject to the separately deferred historical
orphan attribution (`73c9...`); this repair makes that conflict correctly
identifiable and does not infer ownership. Multi-failure retained-history
aggregation remains a separate strategy decision. The dirty worktree payload
hash mismatch was not changed or rerun.

The exact changed-source hashes are recorded in
`INSTANCE-ID-CONTRACT-REPAIR-SOURCE-SHA256.txt`.

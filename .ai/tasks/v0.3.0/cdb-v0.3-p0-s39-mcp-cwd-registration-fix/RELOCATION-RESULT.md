# S39: repository-local worktree and evidence correction

Date: 2026-10-21. Status: RELOCATION_COMPLETE / DUPLICATE_CLEANUP_COMPLETE /
EMPTY_APP_PARENT_RETAINED_BY_POLICY / CLIENT_ACCEPTANCE_STILL_PENDING.

The user instructed consolidation and direct removal of disposable content.
Scope is this session's cwd-fix worktree and its outputs. Other registered
worktrees, repository historical evidence and external Unity consumers are
outside this cleanup; they were not modified or removed.

## Canonical locations after correction

- Isolated checkout:
  `<repository-root>/.worktrees/cdb-v0.3-p0-s39-mcp-cwd-registration-fix/`.
- Branch: `codex/mcp-project-cwd`.
- Source commit remains `c848049d90fbdf618905be25225580642d98d987`.
- Durable task/acceptance records: this directory under the primary
  `<repository-root>/.ai/tasks/v0.3.0/`.
- Test/delivery evidence: `<repository-root>/.artifacts/tests/s39-cwd-fix/`.
- Exact delivery ZIP:
  `<repository-root>/.artifacts/exports/s39-cwd-c848049/com.rice.ai-codedb.zip`.
- Cleanup inventory/receipts:
  `<repository-root>/.artifacts/maintenance/s39-worktree-relocation-20261021/`.

Use the primary repository root for durable outputs even when source execution
uses the isolated checkout. Do not implicitly treat the checkout as the test
output root; review any future writer's root selection before running it.
The checkout's committed task files remain a historical commit snapshot; the
primary task directory owns subsequent handoffs. No handoff depends on the
former app-managed path. Raw logs/receipts retain original emitted paths for
forensic integrity; relocating them does not authorize replay of old scripts.

## Preservation and verification

The new checkout was created at the exact source commit. All 1,113 tracked
files were verified byte-identical to the former checkout before its removal.
Ten task records and 2,196 artifact/evidence files were copied to previously
absent primary-root destinations and verified by SHA-256 before any deletion.
Untracked follow-up records were included; ignored artifacts were not assumed
to be recoverable through Git.

The old app-managed worktree was archived through the owning app and its live
checkout removed. The app retains a recoverable snapshot, attachment identity
`01a15d7d-eb1e-7223-9d37-c0e636767c3f`. The repository-local checkout then switched
to the existing source branch; no merge, source change, new source commit,
push or export occurred.

The four known EOL-filter status entries remain byte-identical to committed
blobs. They are not repair edits and were not normalized. The primary checkout
remains on its original base with the original 69 tracked-dirty entries.

## Removed content

After confirming the retained copies, removed the obsolete external artifact
copy: 2,196 files / 75,417,489 bytes. Also removed six classified repository-local
intermediates: 2,022 files / 57,440,554 bytes:

- Export `package/` staging directory.
- Export `review/com.rice.ai-codedb/` extracted Package only; adjacent test
  fixture evidence under `review/.artifacts/` remains retained.
- Projection `review/` extraction and `candidate.tar`.
- Projection temporary `objects/` store and `index`.

These are reconstructible duplicates. Full exact path/file/hash inventories
and recovery reasons are retained in `pruned-duplicates.json`; this record is
navigation, not a second source or Package identity authority.

Original ZIP SHA-256 remains
`3d266307ba7e052140575ada0c39d689e5a62d28a9aa3d686420f15e76a98a5d`.
The baseline Git archive, meaningful failed fixtures, test outcomes, raw-byte
reviews, preparation scripts, delivery inventories and manifest/lock backups
remain retained. Final verification rehashed all 184 retained migrated files
(ten task records and 174 artifact files) and confirmed every deliberately
pruned path was absent. This result and the task-location amendment are later
records, created after that frozen copy verification.

Automatic approval review rejected removal of the obsolete app worktree's empty
parent directory and zero-byte `.codex-worktree-name` marker with `blocked by
policy`; no more specific reason was supplied. Those empty remnants remain.
No alternative deletion attempt was made. The old live checkout itself is absent.

## Acceptance continuity

CodedbTest_0/1/2, their manifest/lock files, runtime state, MCP registrations,
leases and referenced Package directories were untouched by this cleanup.
The existing human Ready report and static registration checks remain their
original evidence classes. No Unity/Provider/MCP was launched or queried and
no prior bounded attempt was retried. The next user handoff is the primary-root
`CODEDBTEST2-CLIENT-STARTUP-TASK.md`; status and real query acceptance remain
pending. Old-generation migration and Unconfirmed remain deferred.

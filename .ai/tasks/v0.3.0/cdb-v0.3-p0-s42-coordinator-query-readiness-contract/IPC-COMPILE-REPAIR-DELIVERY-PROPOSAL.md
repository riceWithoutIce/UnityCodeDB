# IPC diagnostics compile repair delivery proposal

Date: 2026-10-22. Status: CONSUMER_REPAIR_REFERENCE_SWITCH_PASS_NOT_REOPENED.
The direct compile regression and its minimal isolated repair are recorded in
IPC-COMPILE-REPAIR-RESULT.md. This proposal covers only a new repository commit,
deterministic Package export, and replacement of the currently delivered
c53e181 Package in the already modified closed CodedbTest_2 project.
Execution is recorded in IPC-COMPILE-REPAIR-DELIVERY-RESULT.md.

## Frozen candidate

Checkout: `<repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract`.
Current base: commit `c53e181fbfb24dea07e6e80daa71787ce192baa0`.
Only these two paths may enter the repair commit:

| Path | Frozen repaired SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs` | `b2fe1c6564ea0bf5f386eaf40e1ca6ace7643f925203ff520ffb202500a2bfe5` |
| `com.rice.ai-codedb/Tests~/test-codedb-supervisor-ipc-diagnostics.ps1` | `165c283496a9cc0f2093994a518b361ee7d9750da07fee150ce7b81c808e18c8` |

The repaired source has passed 82 focused checks. The external project remains
closed and currently references
`file:../../Packages/c53e181-s42-ipc-diagnostics/com.rice.ai-codedb` in both
manifest and lock. Its exact pre-switch backups remain available.

## Proposed bounded sequence

The human approved this exact sequence; it completed once:

1. Recheck isolated branch/base, empty index, the two frozen hashes, and the
   82-check receipt. Commit only the two paths with title
   `Preserve Supervisor IPC transport method-group compatibility`.
2. Export that exact commit to a fresh
   `<repository-root>/.artifacts/exports/s42-ipc-compile-repair-<sha7>/`.
   Require production admission, deterministic ZIP closure, and full inventory
   matching. No payload regeneration or metadata repair.
3. With Unity still closed, verify the existing c53e181 destination and backups,
   copy the repaired 667-file Package into a new destination derived from the
   project root, and verify every file hash.
4. Back up the current manifest/lock bytes for this repair attempt. Replace the
   unique c53e181 reference in both files with the new repair reference. Verify
   exact bytes, protected project hashes, and absent UnityLockfile. Stop before
   reopening Unity.

On any drift or partial write, stop and retain effects; do not auto-rollback,
recopy, retry, or start Unity. The sequence does not include Install, Repair,
Restart, Uninstall, Supervisor/Provider operations, MCP calls, or process
control. The existing first compile error and partial-switch records remain
retained.

## Later human gate

After successful replacement, the human opens CodedbTest_2 once and reports the
first compile/Manager state. This is a separate Unity evidence class. A clean
compile does not establish runtime readiness or close the timeout/heartbeat/
identity-handoff investigation.

Approval requested: execute this exact repair commit, export, and closed-project
Package replacement sequence once.

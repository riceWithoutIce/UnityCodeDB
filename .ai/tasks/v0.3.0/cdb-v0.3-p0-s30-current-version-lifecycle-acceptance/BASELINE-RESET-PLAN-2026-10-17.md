# S30 one-time acceptance baseline reset proposal — 2026-10-17

Status: COMPLETE / SINGLE INDEX ARCHIVED / POSTCHECKS AND HUMAN PRESENTATION PASS.

User `同意授权` explicitly approves the single-index backup/archive group below.
No further stage approval is required within this unchanged scope; real
Install/Uninstall remains excluded.

Executed once after preflight on 2026-10-17; see
BASELINE-RESET-RESULT-2026-10-17.md. Human subsequently reports no errors; the
screenshot confirms Install is visible and the old warning is gone. Next action
is alignment of a separate real Install attempt.

## Purpose And Evidence

Resume current-version real lifecycle acceptance without implementing historical
compatibility or asserting automatic recovery of the old S31-C action. Current
accepted delivery is commit `97471f537749eba97171f6756a29112dd552a22b`.

The preceding read-only pass verified all seven live records against
`.artifacts/s30-uninstall-20261017-1e53bbcf/`; all matched. Exact historical
operation `36d0c70eacb7489c94d36b1b58ba1b50` completed uninstall with exit 0.
Desired state remains UNINSTALLED / cleanup PENDING; current-instance pointer
and Supervisor state/lock are absent. The original uninstall child PID is absent.
No additional process with an explicitly S30-bound command line was observed;
this is not a complete external-process ownership guarantee.

Latest preparation observes no Unity.exe processes. S30's empty
`Temp/UnityLockfile` remains; an Open/Read/FileShare.None probe succeeded without
writing it. Treat it as a residual file at this instant, not proof of an active
Editor. Do not remove it or investigate shutdown under this plan. Recheck
processes/ownership immediately before any proposed mutation.

Only one current-action index exists in this project's Manager index directory.
It binds the exact S30 project and original S31-C Package, has action ID
`1e53bbcf798241c48f72b8bfa8ee2e30`, and remains pending. Its receipt directory has
only action.json. An older resolved marker also exists and remains protected.
The old record lacks new binding/completeness anchors; do not backfill them.

## Exact Proposed Change

Resolve `<manager-actions-root>` read-only using the delivered production
`AICodedbPaths.GetManagerActionsRoot` convention. This is an existing product
receipt location, not a new development-output root. Check redirects and exact
record identity before copying or moving anything.

Only this active record may be moved, after a fresh hash/identity check:

`<manager-actions-root>/ba13a538a1678f1fe1cbb477/current-action-1e53bbcf798241c48f72b8bfa8ee2e30.json`

Expected SHA-256:
`f358a22ec7bea22d1d1e5b1a6c526d6d823bdd7bef1e3fb0ac4a5792e59cffa6`.
Metadata hash must remain:
`8752bdf07db5d6c46e0bf7f972f90f67d47b7752b42afda42ad50ee3688a5a9f`.

1. Recheck no Unity process, no attributed active lifecycle process, unchanged
   single pending index and exact operation/desired-state evidence. Stop on
   drift, conflict, unknown active ownership or redirected paths.
2. Create a fresh repository-local backup/archive root:
   `.backups/s30-baseline-reset-20261017-1e53bbcf/`.
   Copy and hash-verify the seven exact source records already mapped in the
   preserved evidence snapshot; preserve their originals.
3. Move only the named pending index into that root's
   `archived-active-index/` directory with its original filename and bytes.
   Verify archived hash and source absence. This removes a historical admission
   blocker as an explicit human baseline decision. It does not authenticate a
   product terminal, fabricate a result or prove automatic recovery.
4. Verify action metadata, operation history, desired state, retained instance,
   Package references and protected resolved marker remain unchanged. Verify no
   replacement pending index appeared. Record exact before/after evidence.
5. Stop. User may then open Manager to inspect the resulting presentation.
   Actual Install/Uninstall and their precise one-attempt plan remain separate.

No successful/resolved marker is written, no session state is forged, and no
runtime store is rewritten. Do not touch index.lock, UnityLockfile, other action
records, retained-content trees, project config, Payload, source or Package
references. No tests, package export, commit, Unity launch or process control.

## Recovery And Stop Boundary

The exact archived index and redundant copied evidence make the removal
recoverable. Restoring it requires a closed/no-writer baseline and absence of a
replacement pending index; never overwrite a newly admitted action. Do not
auto-restore after a subsequent real operation.

This archive does not guarantee Install admission: retained-content/current
ownership checks still run independently. If another independent historical
blocker appears, stop and discuss a fresh acceptance project rather than
expanding cleanup or recovery. Shutdown blockage remains a separate deferred
observation; no causal conclusion is added here.

Current task: one-time S30 acceptance baseline disposition.
Next actor: User/current parent for real Install attempt alignment.
Parent completed backup/archive/read-only postchecks under the recorded grant.
Real lifecycle execution remains separately scoped.

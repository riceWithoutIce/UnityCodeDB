# S21 FIX 02 Guarded Verification

## Verdict

`PASS`

One-time findings: none (`BLOCKER`: none; `P1`: none; `P2`: none; `FOLLOW-UP`: none).

This is a guarded, read-only review of the frozen S21 FIX 02 recovery contract.
The review did not rerun tests or perform Unity/runtime operations.

## Frozen Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- HEAD: `50b131667b076998f48fedc4f991ff99b0adbd73`
- Ordered ten-path binary diff identity: `952b7d8f209be990187686328f4ca52491893527ded71c5c185d5a78576f367e`
- Patch bytes: `49317`
- Identity admission: PASS
- Scoped `git diff --check` over the ten allowlisted paths: PASS, no output

The ten paths reviewed were exactly those listed in FIX 02 of `TASK.md`. The
pre-existing unrelated dirty worktree state was preserved.

## Reviewed Contract

1. `AICodedbCurrentInstanceStore` recognizes Owner Identity v1 only when the
   exact legacy field shape is present and the project identity, selection,
   instance manifest, immutable generation, worker hashes, and Package
   generation disposition all validate. Partial v2 fields, unknown fields,
   malformed identity, hash drift, escaped/reparse paths, and unsupported or
   incomplete closure remain `Invalid`. Classification is read-only.
2. Lifecycle resolves `ObsoleteReinstallRequired` before Supervisor admission.
   With current prerequisite evidence and no control authority it publishes
   `InstanceIdentityReinstallRequired`; conflicting or ambiguous control state
   remains fail-closed.
3. Manager dependency actions are gated by an actual missing Provider
   prerequisite. Current prerequisites plus generic attention or obsolete
   instance state do not expose `Configure Dependencies`; authenticated
   obsolete evidence routes to `Remove CodeDB Integration`, while arbitrary
   invalid/ambiguous evidence has no destructive primary action.
4. C# removal admission re-reads integration, migration/control, and current
   instance state immediately before mutation and requires explicit confirmation.
5. PowerShell `ORPHANED_V1_SELECTION` admission requires no retained control
   authority or contract files, exact Package-owned selection closure, clear
   holder evidence, and an owner fingerprint recheck immediately before
   mutation. The path neither stops processes nor deletes the immutable
   instance; live, ambiguous, drifted, and incomplete evidence remains
   blocked.
6. The existing authenticated v1/v2 removal, interrupted-recovery,
   idempotence, holder-preservation, and unrelated-data protection contracts
   remain represented by the focused evidence and are not weakened by the
   orphaned-v1 exception.

## Reused Coder Evidence

- Bounded static/source assertions: PASS.
- Production and fixture PowerShell AST parses: PASS.
- C# routing, enum/action, and fresh-admission source assertions: PASS.
- Ten-file scoped `git diff --check`: PASS, exit `0`, no output.
- Focused `OwnerIdentityRemovalOnly`: exit `0`, wall time `82,212 ms`,
  invocation `1/1`, retry `0`.
- The focused output covered live, unverifiable, mismatched, partial, and
  conflicting authority refusal; exact orphaned-v1 admission; immutable
  instance/index/lease/retirement-sentinel and user-data preservation; process
  preservation; and interrupted-removal recovery.

## Not Run / Deferred

The following were intentionally not run in this verification: Unity,
Unity MCP, EditMode, C# compilation, BatchMode, Provider operations, real
validation-project removal, process probes, package export, full regression,
publication, commit, and push. The user-owned Unity golden path remains a
separate gate after this source contract is accepted.

## Next Role

Current S21 FIX 02 guarded verification is complete. Planner should summarize
this frozen PASS and the user should decide `ACCEPT`, `FIX`, `DEFER`, or `STOP`.

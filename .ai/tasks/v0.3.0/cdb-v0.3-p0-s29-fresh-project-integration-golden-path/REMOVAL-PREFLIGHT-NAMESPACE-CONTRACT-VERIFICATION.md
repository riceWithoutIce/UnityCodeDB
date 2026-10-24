# REMOVAL-PREFLIGHT-NAMESPACE-CONTRACT — independent read-only verification

Date: 2026-10-14 (Asia/Shanghai)  
Base: `d88a101f15d21f916cbee9578ab887aa1ea862cd`  
Evidence: `.artifacts/tests/s29-removal-namespace/coder-a1`  
Disposition: **BLOCKED — one production recovery call-site finding**

## Scope and authority

This is the approved independent Verifier pass over the frozen six-file Coder
snapshot. It is read-only. No source, index, Package, Unity project, process,
reader, preflight, Install, Remove, cleanup, commit, or export was changed or
run. The Coder snapshot and its six source hashes were admitted before this
review; all six source files and the copied Package overlay match their recorded
SHA-256 values. `HEAD` and the staged index remained unchanged.

The review covered the frozen namespace/retired-v2 proof, operation termination
evidence, stale-owner pairs, historical preservation and fingerprint binding,
handoff validation, terminal/recovery invariants, and the nearest lifecycle
diagnostic path. It did not expand into a broad regression or live acceptance.

## Evidence confirmed

- The v1/default inventory remains strict and only admits the current state/lock
  pair. It does not inherit retired-v2 history admission. Retired-v2 proof keeps
  `Inventory` (Delete targets) separate from `PreservedInventory` (operation
  history and stale pairs), and binds the preserved fingerprint to selected
  identity and manifest/runtime hashes.
- Terminal operation records require schema/identity/phase/result consistency,
  a complete child identity, and an absent child PID. Live, reused, or
  unverifiable process identities remain blocked. Canonical operation bytes must
  match the corresponding history record; stale state/lock quarantine must be a
  complete matching pair with an absent owner PID.
- Terminal validation retains the historical proof and rejects drift. A missing
  whole namespace with only schema-1 intent is deliberately **BLOCKED** because
  it cannot distinguish an old v1 intent from lost retained-v2 history. This is
  a conservative contract outcome, not a preservation PASS.
- `scenario-a4.log` contains PASS52 for the bounded synthetic fixture, including
  successful and failed terminal records, current/v1 controls, malformed and
  foreign evidence, child/timeout/PID refusal, stale-pair and budget refusal,
  handoff drift, rollback, copied removal terminal checks, and direct helper
  recovery checks. `wrapper-original-a1.log` is PASS27 and
  `wrapper-before-install-a1.log` is PASS32; both preserve their original failed
  intent bytes. Native product children, Unity, IPC, and external process
  observation were zero/not run.
- Exact source/overlay equality was verified for all six files. The copied
  Package payload has 478 files with zero missing or mismatched hashes. The
  protected evidence list has 2,844 entries; current comparison found zero
  missing or changed entries. `protected-before.txt` and `protected-after.txt`
  have the same SHA-256.
- Existing isolated compiler outputs are present for Editor (30 source files)
  and Editor.Tests (4 source files), with no compiler error in the recorded
  output. The seam run reports original assertions and exact extracted-member
  binding, while explicitly leaving native Lifecycle/Unity execution NOT_RUN.

## BLOCKER — committed removal recovery is not wired through normal callers

`Publish-InstanceOperation` writes a `COMMITTED` journal before deleting the
journal and operation root (`Tools~/codedb-instance-engine.ps1:3195-3199`). A
crash in that interval leaves a committed `REMOVEINTEGRATION` journal for the
next command. The new recovery implementation correctly requires Package
authority and terminal validation before deleting such a journal
(`Tools~/codedb-instance-engine.ps1:3109-3118`).

The production Install/upgrade lock path still calls recovery without the
Manifest (`Tools~/codedb-instance-engine.ps1:4902-4905`), and the Uninstall
path does the same (`Tools~/codedb-instance-engine.ps1:5248-5254`). Those paths
therefore deterministically throw `Committed integration removal recovery
requires Package authority before journal cleanup.` when they encounter a
leftover committed removal journal, even though both callers already possess
the Package manifest. The RemoveIntegration caller is the only one passing the
Manifest (`Tools~/materialize-codedb-host-payload.ps1:11718-11720`). The journal
is preserved by the throw, so the normal next Install/Uninstall path remains
blocked on every retry.

This is a frozen recovery/terminal invariant and a normal user recovery path;
it is therefore BLOCKER severity under the task boundary. The executed fixture
called the helper directly with a manually supplied Manifest
(`test-codedb-host-payload-materializer.ps1:1350-1354`), so it cannot close the
production-call-site gap. A real crash was not run, but the static call-chain
contradiction and the deliberate crash window are deterministic. The finding
is returned to the user for FIX/DEFER/STOP; this Verifier did not dispatch a
repair.

## Limits and non-findings

The following remain evidence limits rather than additional findings: full v1
or partial-v1 production transaction, explicit stale-pair count overflow,
copied removal combined with an additional failed-before-install intent, and a
real crash/restart recovery. Actual Manager button availability, Unity/MCP,
live readers, real Remove/Install/Upgrade, device/runtime/performance, and
release acceptance were not claimed. One earlier bounded history metadata read
was tool-truncated; it caused no write or execution and is not used as complete
history evidence. Successful compile logs were refreshed during the Coder
completion, so they are reported as successful bounded compilation evidence,
not as immutable per-attempt artifacts.

No other BLOCKER was established in this guarded namespace review. The schema-1
whole-namespace-missing refusal, the unrun v1 transaction, and the synthetic
zero-child seam are preserved as their stated boundaries.

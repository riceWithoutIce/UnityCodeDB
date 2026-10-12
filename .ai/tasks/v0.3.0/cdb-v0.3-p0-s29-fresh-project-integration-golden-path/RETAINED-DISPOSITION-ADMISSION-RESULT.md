# Retained disposition admission Coder result

Status: STABLE_CODER_SNAPSHOT / PASS_WITH_LIMITS. User-approved source-only REFACTOR.

## Owner and transient mapping

- Producer: existing asynchronous `ReadStatusAsync` / synchronous worker-side
  `ReadStatus(context)` invokes existing materializer `DryRun`. No new CLI action,
  probe, lock, persisted permit or mutation route is introduced.
- `DryRun` reaches the marker only after payload admission and project-root
  validation; it does not enter Probe/Upgrade/bootstrap, mutation confirmation,
  lock acquisition, cleanup, or process-control branches. Marker absent, malformed,
  nonzero, output-drain-incomplete, timeout, or package/project mismatch is
  unavailable and therefore BLOCKED (never a partial SAFE result).
- Backend observation: before DryRun product status, reuse
  `Get-InstanceRemovalIntents` (identity, manifest/generation hashes, fingerprint,
  complete effects, editor holders, shared wrapper handoff) and
  `Assert-InstanceNextChangeAdmission` (complete relevant instance bindings).
  Reject duplicate intent bindings and PREPARED/ACTIVATING contract ownership;
  reject a retained failed candidate selected as current/last-known-good.
- Wire output: exactly one `[RETAINED_EFFECTS]` compact JSON object, transient
  `state` SAFE/BLOCKED, `project_root`, `package_root`, `instance_ids`, `detail`.
  It also carries `install_eligible` and `operation_detail`, reusing existing
  first-install / explicit UNINSTALLED preconditions without changing them.
  SAFE lists only validated FAILED_PREPARATION inert instances; any unavailable,
  unknown or conflicting relevant evidence returns BLOCKED without partial grants.
- Parser: allowlisted HostPayloadMaterializer C# file, strict bounded JSON;
  successful, fully drained process output, exactly one marker and matching
  project/package context required. Missing/malformed/duplicate output unavailable.
- Journal: original receipt/action authenticity remains authoritative. Optional
  parsed observation only exempts explicitly validated inert instance IDs from
  the origin-only orphan scan. Historical failures remain a collection and warning;
  no latest-result selection or manufactured old command terminal.
- Session/UI: backend SAFE observation and no pending/conflicting journal owner
  derive recovery presentation independently of one historical command result.
  Only attributable stale historical session state may stop recovering; foreign
  or running ownership is preserved. Refresh/reopen obtains fresh observation.
- Confirmation: existing Install backend route revalidates resource evidence;
  transient UI classification is never a stored execution permit or Ready proof.
  The existing worker-side Manager admission obtains a fresh DryRun observation,
  then authenticates action history under its existing index lock. The displayed
  observation is never passed to dispatch. A retained current index remains
  attributable for its existing exact release; aggregation never picks a latest
  historical command or converts it to a terminal.

Protected real state has not been modified. Unity, export, commit, reference
switching and real operational acceptance remain outside this source stage.

## Verification snapshot

- PowerShell source parse: PASS.
- Existing semantic C# harness (`s29-post-install-ui`): `SEMANTIC errors=0`.
- Existing runtime harness was attempted but stopped at its pre-existing
  real-journal authentication/package mismatch; it is not claimed as a focused
  retained-disposition PASS.
- Existing retained-candidate fixture was attempted and stopped at the known
  dirty working-tree payload source-hash mismatch (`Generations/poc.42/...`);
  no fixture cleanup crossed its owned boundary.

- Final production owner focused fixture: `RetainedDispositionOnly` with
  immutable package b76957a `Payload~`: **47 checks PASS**, native children=0,
  elapsed=47532 ms. Owned evidence:
  `.artifacts/tests/s29-retained-disposition/r-e40e4566`.
- C# whole Editor/tests semantic compile: **errors=0** against installed Unity
  managed metadata; no Unity launch. Independent standalone fixture/consumer
  harness: **13 cases PASS**, with actual owner-emitted observation -> strict
  parser -> journal -> session/UI. Runtime shims only replace Unity lifecycle,
  SessionState, assertion and entry path boundaries. No actual Unity/NUnit run.
- Direct regressions: independent inert orphan classification; no-intent and
  mixed unresolved candidate; project/instance/effect/fingerprint drift;
  duplicate authority; live/ambiguous holder; old-generation source admission;
  multiple failed receipt aggregation; stale same-project historical session
  clearing and preserved foreign pending session; missing/malformed/duplicate,
  nonzero/incomplete and foreign-package observation; old path-key guards.
- Changed PowerShell files: parse errors=0. Scoped touched diff check: PASS.
- Fixture setup mechanical corrections: live-holder fixture initially had no
  new lease; inserted owned lease. Compact C# fixture serialization and named
  outputDrainIncomplete argument corrected; legacy singleton regression updated
  to the frozen aggregate semantics; two-history setup sequentialized so no
  second live index is fabricated. No production outcome was hidden.

## Material limits and remaining gates

- Actual S29 current package/generation/holders and ownership remain UNRUN by
  this slice. Effects SAFE does not make an INSTALLED project eligible for
  Install; its existing generation migration route needs separate disposition.
  This source does not promise that the current real S29 gets an Install button.
- Full end-to-end Unity UI, exact package export/hash closure, reference switching,
  true first-install execution, full migration and release remain NOT_RUN.
- PREPARED/ACTIVATING owner rejection is source verified; this new fixture does
  not independently produce a pending activation journal. Bound wrapper handoff
  reuses existing validator; the new observation fixture uses ABSENT wrapper,
  not a new committed-wrapper handoff scenario. Confirmed at-effect refusal is
  preserved in source, not newly executed by this slice.
- Independent Verifier must assess these evidence limits; no scope, publication,
  operational or acceptance permission is inferred from this Coder result.
- Seven allowlisted source/test files changed; ProcessRunner remains unchanged.
  Frozen hashes of all eight allowlisted files are in `SOURCE-SHA256.txt`.

## Coder terminal handoff

- Stable snapshot: current working tree source bytes at the hashes in
  `SOURCE-SHA256.txt`, based on `b76957a9dbcae9b00eff73775a97c4e8f33ae785`.
- Coder terminal: **PASS_WITH_LIMITS**, no source blocker. Verifier may inspect
  only this retained-disposition slice and its immediate regressions.
- No commit, package export, Unity operation, reference switch, or real-state
  mutation was performed by this Coder stage.

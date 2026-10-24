# S29 coordinator readiness timeout and cleanup repair

Date: 2026-10-10. User disposition: FIX, authorized after the read-only startup
analysis. This is a narrow source repair under S29; previous accepted source,
package, installation, receipt and human evidence remain unchanged.

## Frozen outcome and authority

Repair only the proven startup boundary exposed by operation
`5bb81f9b95074bb5848d8bca01e265ea`:

1. expose whether Provider readiness is waiting for `initialize` or `tools/list`;
2. classify a coordinator's own readiness-timeout result as `STARTUP_TIMEOUT`
   instead of generic `NONZERO_EXIT`;
3. after a readiness timeout, stop only the coordinator/provider created by this
   start attempt and leave no stale start-owned lease/lock state.

Do not change Install, Uninstall, Payload version, generation identity, cleanup
policy, query queue design, timeout duration, Manager UI architecture, historical
receipts, or real runtime state. Unity, MCP, BatchMode and external process
control remain human/operational gates and are not run by this task.

Base source is the accepted S29 control-auth recovery snapshot at HEAD
`7c82ff46997417a82ccceedcf0f846afd8dcda93`; inherited dirty files are not part
of this task and must remain untouched.

Mode: `FAST_SUBAGENT`; delegation: `STANDING_WORKFLOW` (project grant dated
2026-09-16); single writer, depth one; review mode `GUARDED`. Coder and Verifier
must run sequentially. Coder does not commit, export, switch references, or
contact the Verifier. Planner remains active, consumes child questions and waits
for terminal completion. Verifier is read-only and reviews only this frozen
scope and its immediate regressions.

## Change allowlist

Relative to `com.rice.ai-codedb/`:

- `Tools~/codedb-project-supervisor.mjs`
- `Payload~/Generations/poc.42/coordinator/codedb-watch-coordinator.mjs`
- `Tests~/test-codedb-project-supervisor.mjs`

Coder owns `COORDINATOR-READINESS-REPAIR-RESULT.md` and a changed-source SHA256
manifest in this task directory. Planner owns this task packet and disposition.
Verifier owns `COORDINATOR-READINESS-REPAIR-VERIFICATION.md` only. No other
source, Payload generation, documentation or runtime file may change.

## Required behavior and evidence

- A Provider startup status records a bounded phase for `initialize` and
  `tools/list`; a failure retains safe degraded/NeedsAttention semantics and
  does not manufacture Ready.
- The coordinator start command's own readiness timeout is attributed as
  `STARTUP_TIMEOUT`, distinct from process launch failure and ordinary nonzero
  exit.
- A failed start attempt performs authenticated, same-lifecycle cleanup of the
  coordinator/provider it created, with ownership checks preserved. It must not
  stop or remove an unrelated live coordinator.
- Existing successful startup, attach, provider failure, launch failure,
  nonzero-exit and stale/foreign-state behavior remains intact.
- Tests exercise production scripts/paths. No Unity or real Provider launch is
  required; document exact test commands and limits.

The Coder may add only focused synthetic fixtures/cases inside the allowlisted
supervisor test file. No test may touch the real S29 project, machine receipts,
leases or external processes.

## Handoff and acceptance boundary

Coder returns a stable snapshot, result, exact changed-file hashes, focused test
evidence and deferred Unity/runtime/release gates, then stops. Planner checks the
snapshot and dispatches one independent read-only Verifier. Verifier must not
rerun broad tests, modify implementation files or direct Coder work. Findings
are returned together for user disposition. No commit, package export,
reference switch or human Unity claim is implied by source acceptance.

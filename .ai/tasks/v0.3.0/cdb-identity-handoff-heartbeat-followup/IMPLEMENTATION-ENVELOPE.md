# Identity handoff and heartbeat follow-up implementation envelope

Date: 2026-10-22. Status: IMPLEMENTATION_ENVELOPE_FROZEN /
PRODUCT_IMPLEMENTATION_NOT_STARTED.

This envelope records the next bounded implementation slice after the static
analysis and the successful 61dcd26 target-client status/query gate. It does
not claim a root-cause fix, runtime acceptance, or release readiness.

## Frozen objective

Make Supervisor operational readiness use the same supported complete query
service shape that the existing wrapper admission predicate requires. Keep the
existing MCP registration, generation protocol, heartbeat thresholds, UI and
manual recovery responsibilities unchanged.

## Isolated implementation boundary

Use the repository-local isolated checkout:

`<repository-root>/.worktrees/cdb-identity-handoff-heartbeat-followup`

Preserve the primary worktree's dirty and untracked state. Do not copy or
activate unrelated ProcessRunner or writer-lifetime work in the isolated tree.

## Initial allowlist

1. `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
   - derive context paths and selected instance/generation values;
   - pass the complete existing watch and adapter arguments on automatic start;
   - reuse only a context-compatible Coordinator;
   - publish operational Ready only when the complete service shape is present.
2. `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
   - add or expose only focused scenarios for the frozen contract below.
3. Task-owned evidence under
   `.artifacts/tests/identity-handoff-heartbeat/` for bounded test output only.

No other product file enters the allowlist unless a focused test demonstrates
that the direct contract cannot be closed without it. Any such expansion must
be reported before editing.

## Required focused scenarios

- Automatic start without a Coordinator supplies the real watch config,
  adapter builder/worker, manifest and debounce arguments derived from the
  selected instance/generation.
- A compatible existing service returns attached and is not spawned twice.
- A normal pending/building compatible service is not stopped or replaced.
- An already running incompatible service is not reported as attached or Ready,
  does not start a second owner, and returns an identifiable failure.
- Operational Ready and wrapper readiness agree when adapter, worker,
  configuration or generation facts are missing or disabled.
- Existing admission attribution, timeout classification and unknown/live
  child refusal remain unchanged.

## Explicit exclusions

- no heartbeat interval or expiry-threshold changes;
- no MCP registration or initialization-order changes;
- no wrapper predicate weakening;
- no modification of immutable `poc.44` payload files;
- no UI/Manager state redesign;
- no automatic restart, kill, Stop, Install, Repair or Uninstall;
- no process, lease, log or Unity observation during source implementation;
- no S41 freshness rerun and no new query acceptance;
- no commit, export, consumer switch or Package delivery in this slice.

## Stop conditions and later gates

Stop and report a design conflict if the change requires a runtime protocol or
generation change, ownership of an unknown process, a new response schema, or
an unrelated dirty/WIP file. A focused source/test PASS is followed by separate
authorization for commit/export, consumer delivery, human Unity reopen and
the target-client status/query gate. Do not replay Install automatically.

Current next action: implement only this envelope in the isolated worktree after
the source snapshot and base/HEAD boundary are recorded.

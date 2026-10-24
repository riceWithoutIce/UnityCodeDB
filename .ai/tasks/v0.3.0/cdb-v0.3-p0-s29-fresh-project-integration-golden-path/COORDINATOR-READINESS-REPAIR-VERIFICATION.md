# S29 coordinator readiness repair — independent Verifier

Date: 2026-10-10. Review mode: guarded, read-only. Reviewed the frozen task
packet, `COORDINATOR-READINESS-REPAIR-RESULT.md`, the changed-source SHA-256
manifest, and the current working-tree snapshot. No source, test, runtime,
Unity, MCP, Provider, Install/Uninstall, or external process state was changed
or operated by this review.

## Result

Scoped **PASS_WITH_LIMITS**. No BLOCKER or P1 finding was identified in the
frozen repair. The implementation is confined to the three allowlisted files;
the three current file hashes exactly match the Coder manifest:

| File | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` | `E12DCF9C16E5E435B68DA6A964AAA295A1FAE0D55FFEA5DE6D8C8A0C41A451F5` |
| `com.rice.ai-codedb/Payload~/Generations/poc.42/coordinator/codedb-watch-coordinator.mjs` | `928A58B3E181417B4E70E6B8D23FE90DA43147E50319F113B185674EE26BAA09` |
| `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs` | `786816566CC7E5314B89139703FBD8C793988690EA61FC9A952FF892CFF9B4AB` |

`node --check` passed for all three allowlisted JavaScript files, and the
Coder's `git diff --check` passed. No file outside the allowlist is attributed
to this repair; unrelated pre-existing workspace dirt remains outside this
review's scope.

## Frozen-scope checks

1. Provider phase publication is on the production Coordinator path. The
   daemon initializes `provider_start_phase` to `initialize`, persists it
   before spawning/handshaking the Provider, persists `tools/list` after the
   authenticated `initialize` response, and publishes `ready` only after
   `tools/list` contains `codedb_text_search` (`codedb-watch-coordinator.mjs`
   lines 1461-1513, 1567-1577, 2318-2343). Supervisor status forwards the
   authenticated Coordinator phase as `provider_start_phase` and keeps its
   degraded/start semantics (`codedb-project-supervisor.mjs` lines 1743-1800,
   1858-1898). A failed handshake therefore cannot manufacture `ready`.

2. Readiness timeout attribution is distinct and ordered safely. Supervisor
   preserves `STARTUP_TIMEOUT` for its own bounded child timeout and
   `LAUNCH_FAILED` for process creation failure, then recognizes the exact
   Coordinator-owned `Timed out after <n> ms waiting for coordinator readiness.`
   diagnostic before falling back to `NONZERO_EXIT` (`codedb-project-supervisor.mjs`
   lines 1934-1965). The focused Coder case passed with
   `coordinator_failure_category=STARTUP_TIMEOUT`, including the persisted
   operational observation. The exact diagnostic matcher is narrow enough for
   the Coordinator's production error; no launch-failure path can be
   reclassified because that branch precedes the matcher.

3. Timeout cleanup is authenticated and fail-closed. After the Coordinator
   readiness loop expires, `stopOwnedCoordinatorAfterStartTimeout` re-reads
   authenticated status, requires the same lifecycle, verifies generation,
   root, Provider executable, Provider config, runtime, and adapter lane, then
   sends `stop` with internal `expectedLifecycleId` translated to the wire
   field `expected_lifecycle_id` (`codedb-watch-coordinator.mjs` lines 567-591,
   455-487, 1896-1921). The Coordinator stop handler rejects a lifecycle
   mismatch and exclusive stops without an expected lifecycle
   (`codedb-watch-coordinator.mjs` lines 1526-1535). An unavailable,
   unverifiable, replaced, or foreign state is left for existing stale-owner
   recovery rather than being removed blindly. Normal daemon cleanup stops
   Provider/adapter children before removing state and lock files
   (`codedb-watch-coordinator.mjs` lines 1207-1277).

4. Focused evidence covers the Supervisor production invocation and timeout
   result, plus existing authenticated owner-identity and healthy phase checks:

   ```text
   node --check com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
   node --check com.rice.ai-codedb/Payload~/Generations/poc.42/coordinator/codedb-watch-coordinator.mjs
   node --check com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
   RICE_CODEDB_SUPERVISOR_TEST_FILTER=coordinator-readiness-timeout node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
   RICE_CODEDB_SUPERVISOR_TEST_FILTER=owner-identity-v2 node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
   ```

   The timeout filter and owner-identity filter passed per the Coder result.
   The broader `coordinator-readmission` filter remains blocked by its
   pre-existing fixture durability assertion (`durableProbe.child` is null);
   this is outside the new timeout classification path and is retained as a
   validation limit, not a repair finding.

## FOLLOW-UP / limits

- The new focused test uses a synthetic Coordinator start fixture to exercise
  the Supervisor's production child invocation and classification. It does not
  directly drive the production Coordinator through delayed `initialize`,
  delayed `tools/list`, or the timeout cleanup race. Existing production-path
  launch coverage and the static ownership/protocol inspection support this
  scoped source PASS, but a separately authorized test slice could add direct
  synthetic Provider timing and eventual state/lock convergence assertions.
- Unity, MCP, real Provider, install/uninstall, runtime, device, performance,
  package export, commit, and release gates remain unrun and are outside this
  source Verifier acceptance.

No additional findings. Verifier stops here.

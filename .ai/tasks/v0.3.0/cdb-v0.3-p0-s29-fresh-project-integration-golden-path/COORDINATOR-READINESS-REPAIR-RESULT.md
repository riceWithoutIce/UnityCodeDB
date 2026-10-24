# Coordinator readiness repair — Coder result

Date: 2026-10-10. Scope: the frozen coordinator/provider readiness repair only.

## Implemented

- `codedb-watch-coordinator.mjs` records `provider_start_phase` as `initialize`,
  `tools/list`, or `ready`, and publishes it through authenticated status. The
  phase remains visible while the provider is degraded, so a failed handshake
  does not manufacture Ready.
- A `start` readiness timeout re-reads authenticated coordinator status and sends
  `stop` only when the live coordinator still has the same lifecycle and matching
  root/provider/config/runtime metadata. Unverifiable or foreign state is left to
  the existing stale-owner recovery path.
- `codedb-project-supervisor.mjs` classifies the coordinator's own
  `Timed out after ... waiting for coordinator readiness.` result as
  `STARTUP_TIMEOUT`; process launch failure and ordinary nonzero exit retain their
  existing categories. Supervisor status also exposes `provider_start_phase`.
- The focused Supervisor harness adds a synthetic production-path case for the
  readiness-timeout classification and asserts the healthy phase publication.

## Verification

Passed:

```text
node --check com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
node --check com.rice.ai-codedb/Payload~/Generations/poc.42/coordinator/codedb-watch-coordinator.mjs
node --check com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
$env:RICE_CODEDB_SUPERVISOR_TEST_FILTER='coordinator-readiness-timeout'; node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
$env:RICE_CODEDB_SUPERVISOR_TEST_FILTER='owner-identity-v2'; node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
```

The timeout filter reported `[PASS] Coordinator readiness timeout output is
classified as STARTUP_TIMEOUT.` The owner-identity filter passed its existing
authenticated ownership and fail-closed checks.

The existing `coordinator-readmission` filter remains blocked in its pre-existing
fixture assertion: `durableProbe.child` is null when the test reads
`operation.json` after the Probe (`TypeError: Cannot read properties of null
reading 'normalized_argv'`). This is a test-harness durability issue outside the
new timeout classification path; no production/runtime claim is made from it.

`git diff --check` passed for all three changed source/test files. No Unity,
MCP, real Provider, Install/Uninstall, package export, commit, reference switch,
or external process control was performed.

## Changed-source SHA256

```text
E12DCF9C16E5E435B68DA6A964AAA295A1FAE0D55FFEA5DE6D8C8A0C41A451F5  com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
928A58B3E181417B4E70E6B8D23FE90DA43147E50319F113B185674EE26BAA09  com.rice.ai-codedb/Payload~/Generations/poc.42/coordinator/codedb-watch-coordinator.mjs
786816566CC7E5314B89139703FBD8C793988690EA61FC9A952FF892CFF9B4AB  com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
```


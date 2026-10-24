# S39 Ready after old-owner exit and human reopening

Date: 2026-10-20.
Status: HUMAN_MANAGER_READY_REPORTED / NEW_PACKAGE_OWNER_OBSERVED /
REAL_CLIENT_QUERY_PENDING.

The human reopened CodedbTest_0 and reported Ready. Screenshot shows green
CodeDB is ready, Package v0.3.0-preview.5, Host payload OK / Last verified,
Coordinator startup OK / NONE and no cached Coordinator startup failure.
The display explicitly states its Ready observation is cached and reading it
does not perform a new check. Treat this as human UI evidence, not a fresh
parent MCP probe or a successful Codex-client query.

Bounded read-only corroboration of the existing files/process:

- New Supervisor PID 30756 runs `daemon` from the delivered c07bb59 Package,
  for the exact external project and unity-bridge routing. Observed creation:
  2026-10-20T13:31:28.763192Z. Its state records owner epoch
  `7a296ed641c8410389311c09013c353f` and the same PID/start identity/executable.
  This observation did not independently reauthenticate its IPC channel.
- Retained operational observation `9575de370a4e4c92b9ef25bf2b0b74c1`, revision
  129, observed_at_utc 2026-10-20T13:32:45.263Z, reports core_ready /
  COORDINATOR_OPERATIONAL / coordinator_failure_category NONE.
- Selected instance remains `2414c73c2fbb47f4b664c1bdbcad5969`, activation epoch
  `4ad2120d1559487f8e54c015685496f6`, selected/target generation poc.43.
- Manifest/lock, project MCP config, selected pointer, instance manifest,
  generation manifest, stable wrapper and generation helper source still match
  every protected-after hash in DELIVERY-RECOVERY-RECEIPT.json.
- Recovered stable helper SHA-256 remains
  `de2366310169830738ceef4cba4d24e2b54da72f6a8a11ec8c564b4dc298d07f`.
- Query sample SHA-256 remains
  `76442fb3d5d7c950f8836f152bfd273c9b9a00c06d1d287eba036dc6e5d23842`.

The old-package path refusal is no longer displayed, and current retained
Coordinator observation no longer reports the previous startup failure. No
additional recovery or Installer action was performed by the parent.

Next: CLIENT-ATTEMPT-02-HANDOFF.md prepares a fresh target-project Codex chat
with at most one status call and one conditional literal text search. The human
must initiate that attempt; no chat dispatch or MCP call occurred in this pass.
Source/fixture, delivered-artifact closure, historical recovery, human compile/
UI and actual client query evidence remain distinct. Clean first Install,
performance, public distribution, cross-version upgrade and release acceptance
are not established by this checkpoint.

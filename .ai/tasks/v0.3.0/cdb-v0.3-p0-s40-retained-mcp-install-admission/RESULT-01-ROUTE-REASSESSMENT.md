# S40 Coder result: retained MCP Install admission

Status: ROUTE_REASSESSMENT_REQUIRED. Stable, uncommitted Coder snapshot; not
source-accepted, delivered, or real-lifecycle accepted.

## Change

Base/HEAD: `c848049d90fbdf618905be25225580642d98d987`.
Branch: `codex/retained-mcp-install-admission`.
Checkout: `<repository-root>/.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission`.

The engine separates Install admission from deletion authority for a normal,
same-Package UNINSTALLED/PENDING instance. It admits only validated MCP lease
holders with matching live PID/start and registered Node wrapper invocation,
inactive registration, no selected instance, and no active runtime writers.
Unknown identities, failed preparation and conflicting execution remain denied.
The existing all-holders-clear deletion rule and immutable worker are unchanged.
The contract clarification and two focused function-harness tests are included.
Exact four-file hashes are in SOURCE-SHA256.json; untracked tests are included.

## Evidence

All run paths below are relative to
`<repository-root>/.artifacts/tests/s40-retained-mcp-install/`.

| Scenario | Result | Evidence |
| --- | --- | --- |
| PowerShell 5.1 admission controls | PASS, 16 cases | `l0-ps51-c/result.json`, `run.log` |
| Existing S32 admission/history controls | PASS, 25 cases | `s32-regression-a/run.log` |
| Original convergence, injected candidate failure | PASS, no selection and UNINSTALLED preserved | `l1-ps51-b/run.log` |
| Original convergence, new instance/epoch | PASS; old intent and all old-instance file hashes preserved | `l1-ps51-b/run.log` |
| Full convergence cleanup expectation | FAIL: expected PENDING, actual COMPLETE | `l1-ps51-b/cleanup-observation.json`, `run.log` |
| Original worker request binding | PASS, 6 cases | `l1-ps51-b/worker-result.json`, `worker-run-c.log` |
| PowerShell parse, Node syntax, diff whitespace | PASS | Final focused source checks |
| PowerShell 7.6.5 fixture path | NOT COMPLETED: existing strict JSON object type mismatch before admission | `l0-ps7-a/run.log` |

Evidence class: HARNESS / CONTRACT_ISOLATED. Production functions, serialized
records and immutable worker code were used; machine prerequisites, PID/start,
command inventory and provider lookup were synthetic. Candidate verification
used PocFixture. Worker checks use original functions in a VM, with no running
MCP transport, Provider, or IPC. They do not establish real client concurrency,
provider query availability, or physical cleanup after lease release.

Earlier runs remain: `l0-ps51-a` missing registration helper import;
`l0-ps51-b` expected-message mismatch; `l1-ps51-a` incorrect test epoch property.
The corrected epoch assertion uses production `ActivationEpoch`.
Worker attempts A/B had missing process.versions and missing fixture coordinator
directory; both were mechanical fixture corrections. All logs were retained.
No assertion was weakened to accept COMPLETE while the old lease remains.

## Coupled issue and route decision

The final original convergence path creates a distinct READY instance and epoch.
Its normal removal intent and live synthetic old MCP lease remain. Observations:

- `Get-InstanceCleanupState`: PENDING.
- `Get-VersionedInstanceRetirementCleanupState`: COMPLETE.
- Command cleanup and desired-state cleanup: COMPLETE.
- Old intent and old lease: present; old files unchanged before worker fixtures.

The source explains the mismatch: activation initially accounts for removal
intents as PENDING (engine around line 3595). Post-activation
`Get-CombinedInstanceCleanupState` consults versioned retirement and legacy
generation cleanup, omitting the normal-removal instance cleanup calculation.
When the new activation has no retirement intent/control marker, the versioned
calculation returns COMPLETE despite the retained normal-removal closure.
This is not an unconditional PocFixture cleanup return. The earlier admission
block prevented this test from reaching the inconsistent aggregation.

Recommended next slice: account for existing authenticated removal-intent
instance cleanup in the final aggregate; preserve PENDING while holders remain.
Keep deletion authorization, process control, worker binding and protocol
unchanged. Test retained holder => PENDING and existing no-retention => COMPLETE;
only add cleanup-after-drain evidence if explicitly included in that slice.
Do not add marker prerequisites to normal Uninstall or fabricate COMPLETE.

The approved task explicitly excluded cleanup changes and required a scope
decision when they became necessary. Therefore this Coder stopped product edits
at that boundary. The original full assertion remains failing and delivery is
not recommended. Independent GUARDED review is not dispatched or completed.

The PS7 strict-parser observation is a separate compatibility follow-up, not
repaired here and not represented as a PS7 PASS.

## Preserved boundaries

Primary dirty state, prior checkouts and external `CodedbTest_2` were preserved.
No Unity, real Install/Uninstall, external MCP/Provider execution, process stop,
configuration switch, cleanup, commit, export, push or release occurred. All
fixture mutations were repository-local test-owned outputs. A task-owned
worker fixture temporarily changed only its synthetic selection and restored it.

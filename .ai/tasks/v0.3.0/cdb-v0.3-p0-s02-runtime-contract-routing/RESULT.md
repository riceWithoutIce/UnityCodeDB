# Result: cdb-v0.3-p0-s02-runtime-contract-routing

Status: COMPLETE for the frozen routing slice.

## Scope completed

- C# Launcher and Bridge now read the Package runtime contract and use its
  ControlContract to derive the Supervisor namespace, state path, pipe identity,
  retirement path, and empty-bootstrap check.
- The Node Supervisor reads and validates the Package control_contract, derives
  the expected namespace, and rejects fixed, legacy, or mismatched --runtime
  values before creating runtime evidence.
- Supervisor state, lock, status, and Bridge status parsing carry and validate
  the control-contract identity and namespace.
- Focused tests cover derived namespace agreement, canonical pipe identity,
  legacy/mismatched runtime rejection, and no-mutation rejection behavior.
- The legacy control/supervisor namespace remains diagnostic-only; no legacy
  evidence was removed, rewritten, or quarantined.

## Contract evidence

- Contract id: v0.3-control
- Contract version: 1
- Contract schema: 1
- Contract SHA-256:
  7c85ebc534091fcb53d40eedd9eadf869c09caf77fb56a35aeb22e0e8aea09a1
- Derived Supervisor namespace:
  AIWork/.runtime/codedb/control/contracts/v0.3-control/v1/supervisor
- Legacy diagnostic namespace:
  AIWork/.runtime/codedb/control/supervisor

## Changed files

- com.rice.ai-codedb/Editor/AICodedbSupervisorLauncher.cs
- com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs
- com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
- com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
- com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1
- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs

The protected contract authority and persisted state were not changed:
AICodedbControlContract.cs, Payload~/payload-manifest.json,
current-instance.json, immutable generations, and legacy evidence.

## Focused evidence

Final L0 commands, executed as one bounded batch:

    node com.rice.ai-codedb\Tests~\test-codedb-project-supervisor.mjs
    powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1

Final output:

    [PASS] Supervisor Package-root routing, runtime contract, asynchronous operation polling, single-flight reuse, terminal failure, reconnect continuity, authenticated shutdown, offline retirement, activation handoff, strict evidence, and immutable closure boundaries.
    [OK] Standalone CodeDB package boundary passed.

The first invocation stopped before any fixture or Supervisor case was
created at the deterministic pipe fixture assertion. It reported actual
8ef262de0ef456d71b2b versus the stale expected 266b1ec226f1e4371ef5. The
constant was corrected once, and the single subsequent full L0 batch passed.
No further L0 rerun was made.

## Batch limits

- Completed L0 batch count: 1 full focused batch.
- L0 invocation note: 2 total invocations, consisting of one pre-fixture
  deterministic assertion correction and one completed batch. This used one
  allowed corrective retry and did not expand the test set.
- Affected L1 batch count: 0, DEFERRED. The bounded test inventory contains
  Unity Editor tests but no standalone non-Unity C# editor compile/test
  harness. EditMode authorization was NOT_REQUESTED, and the task forbids
  launching Unity or substituting a direct probe.
- Not run: full Editor tests, full repository regression, Unity EditMode,
  cold-start/Play, real Codex, third-party Package acceptance, commit, and
  push.
- No Unity, Unity MCP, background Unity validation, endpoint retry, or direct
  replacement probe was performed.

## Risks and deferred gates

- The changed C# signatures and Editor integration have no compile or
  EditMode evidence in this task; this remains an explicit deferred gate.
- Migration classifier results are still not wired into lifecycle or Manager
  state.
- Activation journal/epoch, explicit Reinstall, real Unity/Codex acceptance,
  and release acceptance remain separate tasks.
- Current execution observed HEAD
  d0e8a14367798b775c024167add7a7fae1924e61. The task snapshot
  25209d931d449a5002d888ba127dfb7e69584bc0 is an ancestor; the intervening
  commit only changes unrelated documentation, which was preserved.

## Completion Routing

Current task: cdb-v0.3-p0-s02-runtime-contract-routing
Current status: COMPLETE
Next notification: UnityCodeDB v0.3 Planner
Next action: review RESULT.md and route this frozen snapshot to Verifier for a targeted read-only review, or record the bounded disposition; do not rerun unchanged Coder L0 tests.
Human decision or authorization required: Planner review and disposition; any commit, push, EditMode, Unity, or release acceptance requires separate explicit authorization.

## Bounded Finding Repair 01

- Corrected only the canonical pipe expectation in
  `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`: the
  versioned control-contract runtime now expects
  `codedb-supervisor-8ef262de0ef456d71b2b` instead of the legacy
  `control/supervisor` value `codedb-supervisor-0ca345c1003467dd849d`.
- Static comparison: the C# expectation at line 310 matches the deterministic
  Node assertion in `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
  at line 1268.
- `git diff --check`: PASS.
- No L0 batch was rerun. C# Affected L1 / Unity EditMode remains DEFERRED.
- No Unity or Unity MCP operation was performed. No commit or push was made.

## Repair Completion Routing

Current task: cdb-v0.3-p0-s02-runtime-contract-routing
Current status: COMPLETE
Next notification: UnityCodeDB v0.3 Planner
Next action: route the repaired same snapshot to Verifier for targeted read-only re-review
Human decision or authorization required: Planner routing; commit/push/EditMode remain separately gated

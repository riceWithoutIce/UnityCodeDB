# Task: cdb-v0.3-p0-s15-query-first-lifecycle-maintenance-queue

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: `READY`
- Planner: UnityCodeDB v0.3 Planner
- Coder: `v0.3.coder.deep`
- Verifier: `v0.3.verifier.deep` after a stable result and Planner routing
- Review mode: RELEASE
- Execution profile: `v0.3.coder.deep`
- Session policy: `REUSE_ONLY`
- Predecessor: `cdb-v0.3-p0-s14r-operational-readiness-authority-refactor`
  (`IMPLEMENTATION_STABLE / UNITY_EVIDENCE_DEFERRED`)
- Roadmap position: Runtime Release Gate, Delivery Sequence item 8;
  Discover Read has not started
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-supervisor-runtime-recovery.md`;
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`;
  - the predecessor S14r task and its consolidated result.

## Baseline Gate

Planner has now frozen the S14r source snapshot as an explicit uncommitted
handoff. This is a baseline freeze, not an acceptance or release claim:

- Current branch HEAD is the workflow commit
  `a60b92f36679834d1696e4133561bbbc770139be`.
- The S14r implementation still has an uncommitted ten-file source/test
  snapshot. Its affected EditMode evidence is deferred because no approved
  Unity Editor entry was available.
- Baseline mode: explicit uncommitted S14r handoff.
- The fixed S14r path order contains exactly 10/10 modified paths, with no
  missing or unexpected path:
  1. `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
  2. `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
  3. `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  4. `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  5. `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
  6. `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  7. `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  8. `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  9. `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  10. `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Baseline HEAD: `a60b92f36679834d1696e4133561bbbc770139be`.
- Ordered ten-file binary diff identity:
  `5ac13d9be475cafa7d2fb0c1e12b223b243ae1bc`.
- S14r affected EditMode remains `DEFERRED`; this baseline does not claim
  S14r release acceptance. Coder must preserve the inherited bytes and keep
  S15 changes distinguishable from that baseline.
- Coder must not clean, reset, revert, or silently commit the baseline, and
  must not infer repository-wide cleanliness from this scoped handoff.

The baseline decision is separate from this task's implementation objective.
It must not be solved by reverting, cleaning, or silently committing S14r.

## Objective

Move lifecycle and maintenance requests onto one query-first, serialized
execution contract while preserving the Supervisor as the only heavyweight
runtime owner:

1. Unity Bridge/Lifecycle/Manager emit lifecycle intent, cache observations,
   and render UI; they do not perform CodeDB filesystem, process, synchronous
   IPC, indexing, or full-status work on Unity's main thread.
2. One project-local Supervisor request queue owns admission, priority,
   coalescing, cancellation, epoch invalidation, and one-heavy-job-at-a-time
   execution. A second queue or hidden parallel maintenance owner is not an
   acceptable compatibility path.
3. Query/status observations remain eligible while maintenance is deferred or
   suspended. Heavy work serializes across compilation, asset updates, Play,
   Domain Reload, reconnect, and shutdown boundaries.
4. A valid stale index remains queryable with explicit freshness. A missing
   index reports bounded startup/readiness rather than blocking the Editor.
5. Reconnect reuses a healthy authenticated Supervisor and never authorizes a
   duplicate backend or duplicate operation owner.
6. Final shutdown cancels/awaits only authenticated Package-owned work and
   preserves external MCP clients and unrelated processes.

Unity Editor version is not an input to any of these product or runtime
decisions. Any Unity evidence uses the workflow's declared compatibility level,
not an ad hoc environment alias.

## Contract And Scope

### Required Contract Table

Before implementation, append a compact table to `RESULT.md` naming one owner
and every consumer for each fact:

| Fact | Sole owner | Consumers |
| --- | --- | --- |
| Request admission, key, priority, and epoch | Project Supervisor queue | Lifecycle bridge and Supervisor worker |
| Heavy operation execution and result | Project-local Supervisor | Queue completion and status cache |
| Lifecycle transition intent | Unity Editor Lifecycle | Queue adapter |
| Query freshness/readiness observation | Supervisor authority | Bridge, Lifecycle, Manager |
| User presentation | Manager from one cached snapshot | Human UI |
| Shutdown ownership | Authenticated Supervisor/Package lease | Lifecycle shutdown path |

The table may be refined after direct inspection, but it must not describe two
competing runtime-readiness or maintenance authorities.

### In Scope

- Consolidate or extend the existing Supervisor request queue and its direct
  lifecycle adapter; do not build a global daemon.
- Define bounded request kinds/keys, query-versus-maintenance priority,
  duplicate coalescing, epoch cancellation, and transition suspension.
- Make compile/asset/Play/Domain Reload/reconnect/shutdown callers enqueue
  intent instead of invoking heavyweight work directly.
- Preserve cache-only Manager presentation and revision-consistent snapshots.
- Add focused direct tests for queue ordering, coalescing, cancellation,
  suspension/resume, stale-result rejection, query availability, reconnect,
  and authenticated shutdown ownership.
- Keep all diagnosis, implementation, same-cause correction, and focused
  evidence in this one task and one `RESULT.md`.

### Allowed Files

Only the files below may be changed; touching every file is not required:

- `com.rice.ai-codedb/Editor/AICodedbSupervisorRequestQueue.cs`
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- this task's `RESULT.md` and a `CHECKPOINT-NN.md` only for a real external
  interruption, unavailable prerequisite, or session handoff.

Direct read-only inputs are the roadmap, Supervisor recovery companion,
workflow, predecessor route/result, and named symbols/direct references. Do not
reload all historical checkpoints or perform a repository-wide search.

### Protected And Out Of Scope

- Do not enumerate, read, edit, stage, clean, or make identity claims about
  `UnityValidationProject/.codex/` or `UnityValidationProject/AIWork/`.
- Preserve unrelated changes in
  `UnityValidationProject/ProjectSettings/ProjectSettings.asset`.
- Do not create, copy, regenerate, or substitute a Unity project.
- Do not redesign selected-instance, control-contract, migration, activation,
  retirement, lease, Provider, index format, or Discover Read contracts.
- Do not add a global daemon, global MCP registration, or a second maintenance
  authority.
- Do not make product behavior conditional on Unity Editor version, create an
  `UNITY_EDITOR_*` alias, or search/install an Editor automatically.
- Do not commit, push, operate Unity/Unity Hub, use Unity MCP, inspect raw
  protected runtime state, or stop a human/external process.
- Full Node/PowerShell suites, full EditMode, PlayMode Test Runner, consumer or
  third-party Package validation, release publication, and real Codex Desktop
  injection remain outside this slice.

## Execution Envelope

### Coder Actions

1. Require human confirmation that `UnityValidationProject/` is closed before
   non-Unity work; perform at most one passive process check.
2. Resolve the Baseline Gate before reading or changing S15 implementation
   files. If it is unresolved, return `BLOCKED / BASELINE_NOT_FROZEN` without
   touching source.
3. Read this card once and inspect only named symbols/direct references.
4. Write the contract table, then implement one complete vertical queue slice.
   Do not split each symptom into a new microtask or preserve a competing
   compatibility branch.
5. Keep same-cause fixture/command corrections inside this envelope and return
   one stable snapshot to Planner. Do not contact Verifier directly.

### Focused Evidence

- Static/source batch: one bounded syntax and source-contract batch over actual
  changed files.
- L0: one tightly coupled serial batch containing only the queue-related Node
  Supervisor test filter and, if the queue contract crosses the materializer,
  one narrowly focused PowerShell mode. If a focused mode does not exist, add
  only the test-only mode needed for this task; do not run a broad existing
  matrix merely for coverage.
- L0 budget: initial batch `1`; at most one same-cause corrected attempt. A
  corrected attempt reruns only the failed member and directly dependent member
  whose input changed.
- Affected C# L1: direct methods in
  `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests` and
  `Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests`. Coder must return the
  exact test names and filter before any Unity run. Default Editor compatibility
  level is `LINE`; use `PINNED` only if the criterion explicitly requires it.
  Initial invocation `1`; same-cause corrected invocation at most `1` after
  separate human authorization.
- Visible lifecycle acceptance is a later, separately authorized gate. It is
  not silently started as part of this implementation task.
- Record each approved command, exit, wall time, concise output, and cleanup
  result once. Do not capture a full repository diff.

### Stop And Escalation

- Stop on baseline drift, protected-state access, required work outside the
  allowlist, sensitive output, external process control, or an immutable
  generation change.
- Return `ROUTE_REASSESSMENT_REQUIRED` instead of adding a patch when the queue
  needs a second authority, mixes epochs, creates an unbounded retry loop, or
  requires a special-case hole to pass.
- A failed command is evidence within this task, not an automatic new task.
  Exhausted attempts, unavailable evidence, or unrelated failures return one
  consolidated result; do not create symptom-sized checkpoints.
- Timeout returns process ownership to the human and never authorizes
  `Stop-Process`.

## Definition Of Done

- One queue/owner serializes lifecycle and maintenance intent with explicit
  priority, key, epoch, cancellation, and stale-result behavior.
- Query/status observations remain available while maintenance is deferred, and
  stale/missing index semantics are explicit and bounded.
- Compile, asset, Play, Domain Reload, reconnect, and shutdown callers do not
  perform heavyweight work on Unity's main thread or create duplicate owners.
- Manager remains cache-only and consumes one revision-consistent observation.
- Focused Node/PowerShell evidence and authorized affected C# evidence pass on
  one stable snapshot, or each deferred boundary is explicitly recorded.
- No Unity-version condition, global daemon, protected-project mutation, or
  unrelated contract redesign is introduced.
- `RESULT.md` records the contract table, changed paths, identity, budget,
  evidence limits, and a clear next-owner handoff.

## Handoff

- Current task: `cdb-v0.3-p0-s15-query-first-lifecycle-maintenance-queue`
- Current status: `READY`
- Next notification: `v0.3.coder.deep`
- Next action: dispatch this single continuous slice against the frozen
  uncommitted S14r baseline; any Unity evidence level is declared separately.
- Human decision or authorization remains separately required for task dispatch,
  affected EditMode, visible lifecycle, Verifier routing, commit, push, and
  publication.

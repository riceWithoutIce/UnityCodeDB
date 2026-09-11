# Task: cdb-v0.3-p0-s15-maintenance-ownership-transition-fix

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep after a stable result and Planner routing
- Review mode: RELEASE
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s15-query-first-lifecycle-maintenance-queue`
  (`FAIL`; two P1 findings in `VERIFICATION.md`)
- Roadmap position: Runtime Release Gate, Delivery Sequence item 8
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p1-supervisor-queue.md`
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`
  - predecessor `TASK.md`, `RESULT.md`, and `VERIFICATION.md`

## Human Authorization

- On 2026-09-11 the user approved a structural FIX for both P1 findings and
  explicitly approved expanding the allowlist to include
  `com.rice.ai-codedb/Editor/AICodedbActions.cs`.
- This authorizes the task scope only. It does not authorize Unity, Unity MCP,
  EditMode, commit, push, or publication. Task dispatch remains a separate
  manual routing action.

## Objective

Restore one Supervisor-owned execution authority for the normal Manager
maintenance paths and wire compilation/asset-update boundaries into the same
maintenance suspension and generation-invalidation contract. Preserve the
query-first queue, cache-only presentation, and all accepted S15 behavior.

This is one continuous structural repair. Do not split the two findings into
independent symptom patches or preserve a competing maintenance lane.

## Confirmed Findings

### P1-01: Manager maintenance bypass

The frozen S15 snapshot still routes Refresh If Stale, Refresh/Clean/Rebuild
Index, and Build Shader Adapter through `RunAction`/`Task.Run` and direct
`AICodedbActions` script runners. The completion path then invokes a separate
`AICodedbStatusSnapshot.RefreshAsync` filesystem/hash/full-status pass.
Relevant symbols are in `AICodedbManagerWindow.cs` and
`AICodedbActions.cs`. This is a second heavyweight lane outside Supervisor
admission, coalescing, owner epoch, and ordering.

### P1-02: Compile/asset transition not wired to active maintenance

`AICodedbEditorLifecycle.OnEditorUpdate` currently passes only the Play
transition to maintenance suspension. `isCompiling` and `isUpdating` defer new
starts but do not suspend active maintenance or invalidate its generation.
An update-only boundary can therefore allow a late result across the
transition. Relevant symbols are in `AICodedbEditorLifecycle.cs` and its direct
tests.

## Scope

### In Scope

- Route the normal Manager maintenance actions identified by P1-01 through the
  existing Supervisor request/intent adapter and its single-owner queue.
- Remove the Manager-side heavyweight execution and duplicate full-status lane
  for those paths; present completion from the queue-owned, revision-consistent
  observation/cache.
- Connect compilation and Asset Update transitions to the existing maintenance
  suspension and local-generation invalidation behavior, while keeping query
  observations eligible.
- Add or adjust only the focused direct tests/source assertions needed to prove
  Manager ownership and compile/update stale-result rejection.
- Preserve the accepted S15 queue priority, key/coalescing, epoch, reconnect,
  shutdown, and query-first contracts.

### Out Of Scope

- A new Supervisor, daemon, queue, compatibility branch, or global authority.
- Redesign of selected-instance, control-contract, migration, activation,
  retirement, lease, Provider, index format, or Discover Read behavior.
- Unity-version conditions, Unity project creation, Unity/MCP operation, or
  protected validation-project/runtime state access.
- Full Node/PowerShell suites, broad repository scans, PlayMode, consumer or
  third-party Package validation, release publication, commit, or push.

### Allowed Files

The fixed order below is the complete source/test allowlist for this repair.
`AICodedbActions.cs` is newly allowlisted by explicit user authorization; it
must remain byte-identical unless the structural repair genuinely requires a
change to remove or bind its direct execution API.

1. `com.rice.ai-codedb/Editor/AICodedbSupervisorRequestQueue.cs`
2. `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
3. `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
4. `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
5. `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
6. `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
7. `com.rice.ai-codedb/Editor/AICodedbActions.cs`
8. `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
9. `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
10. `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
11. `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
12. `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`

Only this task's `RESULT.md` may be appended for execution evidence. Do not
create checkpoint files unless a real interruption, unavailable prerequisite,
or handoff requires one.

### Protected State

- Preserve all inherited S14r/S15 uncommitted bytes outside the explicitly
  changed allowlist paths.
- Do not read, enumerate, edit, or make identity claims about
  `UnityValidationProject/.codex/` or `UnityValidationProject/AIWork/`.
- Preserve unrelated `UnityValidationProject/ProjectSettings/ProjectSettings.asset`
  changes and all other dirty worktree paths.
- Do not alter workflow, roadmap, prior task, or prior verification records.

### Snapshot Binding

- Baseline HEAD: `a60b92f36679834d1696e4133561bbbc770139be`
- Inherited S15 ordered eleven-path identity:
  `e1c372816afb57450379fb0ec4fa5cf6dac38dcd`
- Expanded ordered twelve-path identity at admission:
  `e1c372816afb57450379fb0ec4fa5cf6dac38dcd`
- The identities are equal because the newly allowlisted
  `AICodedbActions.cs` was byte-identical to HEAD at admission. The inherited
  S15 source/test changes remain uncommitted and must be preserved.

## Execution

### Coder Actions

1. Require confirmation that `UnityValidationProject/` is closed and perform
   at most one passive matching-process check.
2. Read this card once, the workflow, profile map, and the named predecessor
   findings. Inspect only named symbols and direct references.
3. Verify the snapshot binding before touching source. Any drift returns
   `BLOCKED / BASELINE_NOT_FROZEN` without edits.
4. Implement one complete structural repair across the two findings. Prefer
   existing queue/adapter APIs; do not introduce a second owner or a special
   case solely to satisfy a marker.
5. Change `AICodedbActions.cs` only if required to make the Manager path use the
   single Supervisor authority. If it is not required, leave it unchanged and
   record that fact.
6. Keep all same-cause test/fixture corrections in this task and return one
   stable uncommitted snapshot to Planner. Do not contact Verifier directly.

### Focused Evidence

- Static/source batch: one bounded batch over the actual changed files proving
  no direct Manager maintenance lane remains, the cache-only completion path,
  and compile/update suspension plus generation invalidation.
- L0: reuse the accepted S15 `request-queue` result when the Node queue source
  is unchanged. If Node/PowerShell source changes, run only one tightly coupled
  focused member covering the changed contract; do not rerun the broad suite.
- Scoped whitespace check: one `git diff --check` over the fixed twelve-path
  list after the final snapshot.
- Affected C# L1/EditMode: `NOT_REQUESTED` for this task unless the user later
  authorizes the exact methods, filter, project, and wait limit. Return the
  exact affected methods and filter rather than starting Unity.
- Record each approved command, exit, wall time, compact output, and cleanup
  result once. Do not capture a repository-wide diff.

### Budgets And Stop Conditions

- Static/source batch: initial `1/1`; at most one same-cause corrected attempt
  after separate Planner authorization.
- Focused L0: initial `1/1` only when a changed Node/PowerShell contract needs
  it; at most one directly dependent corrected attempt after authorization.
- Scoped `git diff --check`: `1/1`; no blind rerun after failure.
- Stop on snapshot drift, protected-state access, an unexpected path, an
  unresolved second authority, a required change outside the allowlist, a
  timeout, sensitive output, or a proposal to launch/control Unity or another
  external process.
- Timeout returns process ownership to the human and never authorizes
  `Stop-Process`.

### Escalation Guards

- Structural repair count at start: `1/2` (S15 implementation already
  accepted as a predecessor snapshot).
- Consecutive diagnostic-only checkpoint count at start: `0/3`.
- If the queue cannot own both paths without a second authority, return
  `ROUTE_REASSESSMENT_REQUIRED` instead of adding a compatibility hole.
- No automatic model escalation; the selected profile is already
  `v0.3.coder.deep`.

## Definition Of Done

- Every P1-01 Manager maintenance path is admitted and serialized by the sole
  Supervisor queue; no independent `Task.Run`/script lane remains for those
  actions.
- Manager consumes one revision-consistent cached observation and does not run
  a duplicate filesystem/hash/full-status pass after the action.
- Compilation and Asset Update suspend active maintenance and invalidate the
  obsolete local generation; query observations remain eligible and late
  maintenance results are rejected.
- Focused source evidence and any necessary changed-contract L0 pass on one
  stable snapshot, or each deferred boundary is explicitly recorded.
- No unrelated contract, Unity-version condition, protected state, commit, or
  push is introduced.
- `RESULT.md` records the final path set, identity, evidence ledger, deferred
  boundaries, and the next-owner footer.

## Handoff

- Current task: `cdb-v0.3-p0-s15-maintenance-ownership-transition-fix`
- Current status: `READY`
- Next notification: `v0.3.coder.deep`
- Next action: perform the bounded preflight, implement the single structural
  repair, run only the declared focused evidence, and return `RESULT.md` to
  UnityCodeDB v0.3 Planner.
- Human decision or authorization required: task dispatch, any C# L1/EditMode
  or Unity run, Verifier routing, commit, push, and publication remain
  separately gated.

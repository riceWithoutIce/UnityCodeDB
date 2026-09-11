# Task: cdb-v0.3-p0-s16-manager-cache-runtime-isolation

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: `v0.3.coder.deep`
- Verifier: `v0.3.verifier.deep` after a stable result and Planner routing
- Review mode: RELEASE
- Execution profile: `v0.3.coder.deep`
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s15-maintenance-ownership-transition-fix`
  (`ACCEPT`, commit `0b9aeac`)
- Roadmap position: Runtime Release Gate, Delivery Sequence item 9
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p1-supervisor-lifecycle.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s15-maintenance-ownership-transition-fix/DECISION.md`

## Objective

- Close one continuous runtime-isolation outcome: Manager remains a cached
  Supervisor client and the fresh local integration proves zero prohibited
  CodeDB I/O on Unity's main thread.
- Carry the inherited S14r operational-readiness path into this evidence
  without reopening its historical patch loop or creating a second authority.
- If a direct defect prevents the outcome, diagnose and correct it coherently
  inside this task; do not create command-level or assertion-level subtasks.

## Baseline And Handoff

- Committed baseline: branch `codex/v0.3.0-legacy-workflow`, HEAD
  `0b9aeac` (`feat(v0.3): close S15 maintenance ownership transition`).
- S15 source/test behavior is accepted and must remain the predecessor
  contract: one Supervisor-owned maintenance queue, revision-bound cache-only
  Manager presentation, and compile/update invalidation.
- The current working tree also contains inherited, unaccepted S14/S14r state.
  It is a read-only baseline for this task and must not be cleaned, reverted,
  or silently included in the S16 patch:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s14-coordinator-operational-ready-closure/`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s14r-operational-readiness-authority-refactor/`
  - `UnityValidationProject/ProjectSettings/ProjectSettings.asset`
  - `UnityValidationProject/.codex/`
  - `UnityValidationProject/AIWork/`
- Freeze the exact S16 source identity once at the bounded preflight. Do not
  perform repository-wide identity, diff, or log scans.

## Scope

### In Scope

- Direct Manager, lifecycle, Bridge, Supervisor queue, and operational-readiness
  consumers needed to prove the objective.
- Focused static/source checks and only the nearest changed-contract tests.
- One fresh, human-owned local integration against the standard validation
  project after a separate Unity authorization.
- Bounded evidence that Manager open/repaint/tab observation is cache-only,
  query observations remain available during one queue-backed maintenance
  operation, and all instrumented prohibited main-thread counters stay zero.
- The same continuous visible scenario may cover cold start, Manager
  observation, one Play/Domain Reload reconnect, return to Edit Mode, and
  normal shutdown. It is one scenario, not a full lifecycle matrix.

### Allowed Files

Writable only when a direct finding requires it:

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorRequestQueue.cs`
- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- one directly paired Editor-only instrumentation source and its `.meta`, only
  when existing counters cannot prove the declared main-thread criterion
- the S16 `RESULT.md` and checkpoint records

`com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` is protected inherited
state, not an S16 allowlist path. A required change to it first returns to
Planner for explicit scope expansion or route reassessment.

### Protected State And Out Of Scope

- Do not modify `UnityValidationProject/Assets/`, `Packages/`, or
  `ProjectSettings/`; generated `Library/`, logs, and test output remain
  ignored and human-owned.
- Do not read or mutate protected runtime documents, tokens, raw command lines,
  user-profile paths, or unrelated process state.
- Do not create, copy, repair, or substitute a Unity project. Do not install or
  resolve an Editor automatically, and do not add a Unity-version environment
  alias or product-version branch.
- Discover Read, query corpus/performance, third-party Package acceptance,
  consumer projects, Codex Desktop injection, full regression, publication,
  commit, and push are out of scope.

## Execution

### Coder Actions

1. Perform one bounded preflight of the declared baseline and direct source
   paths. Confirm the selected profile and inherited dirty-state boundary.
2. Reuse accepted S15 evidence where source is unchanged. Inspect only the
   direct Manager/cache/main-thread seams and the nearest tests.
3. Implement one coherent correction only if a direct S16 criterion fails.
   Preserve single-owner Supervisor routing, fail-closed behavior, external
   process isolation, and revision-bound observations.
4. Run the declared lower-cost evidence, then return one consolidated
   `RESULT.md` with identities, counters, attempts, limitations, and the next
   owner. Do not contact Verifier directly.

### Focused Test Plan

```text
L0 tests:
  Existing Supervisor/package-boundary or source instrumentation checks only
  when an actual S16 source change affects them; reuse unchanged S15 evidence.

Affected L1 tests:
  Only direct AICodedbEditorLifecycleTests and AICodedbManagerUiTests cases
  implicated by an actual edit or by the declared cache/main-thread criterion.

Additional evidence:
  One explicitly authorized visible UnityValidationProject integration scenario.

Explicitly not run:
  Full EditMode/PlayMode suites, third-party Package acceptance, consumer
  projects, Discover Read, performance, Codex Desktop, hidden/background Unity,
  Unity MCP substitution, and repository-wide scans.

Test rationale:
  Item 9 is a cross-layer runtime gate. The smallest useful evidence is the
  direct cache/queue contract plus one continuous local observation; unrelated
  neighboring tests do not increase confidence in this criterion.
```

### Unity Evidence Gate

EditMode is `NOT_REQUESTED` at task creation and must not start during normal
implementation. A later human authorization, recorded before process start,
must use:

```text
Project path: <repository-root>/UnityValidationProject/
Purpose and criterion: prove Manager cache-only observation and zero prohibited
  Unity-main-thread CodeDB I/O in the one continuous local scenario above
Editor compatibility level: LINE
Exact command and test boundary: focused affected tests only; no full suite
Evidence class: fresh local Unity runtime integration
Expected duration / maximum wait: 300 seconds per bounded startup or transition
Cleanup and ownership handoff: human opens and closes the visible project;
  never terminate Unity automatically after a timeout
```

Coder and Verifier must not launch Unity, create a project, use a hidden or
background process, or reconnect to Unity MCP. If the approved MCP surface is
unavailable, preserve the original error and return this evidence class as
`BLOCKED` or `DEFERRED`.

### Budgets And Stop Conditions

- Static/source evidence: initial `1/1`, with at most one same-cause corrected
  attempt after a new Planner authorization.
- Focused L0: initial `1/1` only when a changed contract requires it, with at
  most one directly dependent corrected attempt after authorization.
- Affected L1: initial `1/1` when applicable; no blind rerun of unchanged tests.
- Visible Unity scenario: initial `1/1`; at most one same-cause corrected
  scenario after separate authorization. Each bounded wait stops at `300 s`;
  timeout returns process ownership to the human.
- Scoped final status/diff check: one bounded check over actual S16 paths.
- Stop on identity drift, an unexpected path, protected-state access, a second
  authority, sensitive output, unavailable evidence, timeout, or a required
  change outside the allowlist. Preserve `BLOCKED`/`DEFERRED` evidence.
- Starting structural repair count: `0/2`. Starting diagnostic-only checkpoint
  count: `0/3`. A second independent authority or repeated patch loop requires
  `ROUTE_REASSESSMENT_REQUIRED`.
- No automatic model escalation. Profile changes require a Planner/User
  checkpoint and explicit approval.

### Side-Effect And Git Rules

- No commit, push, publish, stash, reset, clean, or global configuration change
  during implementation. A commit proposal may be recorded, but commit remains
  a separate human action.
- Keep output bounded to the workflow limits; summarize logs instead of dumping
  them. Do not poll or wait from the Planner after dispatch.

## Definition Of Done

- Manager opening, repainting, and tab/cache observation consume one coherent
  lifecycle-cached Supervisor observation and perform no prohibited main-thread
  CodeDB filesystem, hash, lock, process, synchronous IPC, or full-status work.
- One queue-backed maintenance/query overlap remains serialized and query-first,
  with no duplicate Supervisor/materializer owner and no late-result corruption.
- The authorized local scenario either proves the criterion or records a
  concrete `BLOCKED`/`DEFERRED` boundary without claiming release success.
- Existing S15 ownership, fail-closed, external-process, and version-neutral
  Unity boundaries remain intact.
- `RESULT.md` records exact changed paths, frozen identity, focused evidence,
  attempt/retry ledger, deferred boundaries, and the completion-routing footer.
- After Planner confirms a stable result, route once to
  `v0.3.verifier.deep` for targeted read-only RELEASE review. Verifier does not
  rerun unchanged tests or directly dispatch repairs.

## Handoff

- Current task: `cdb-v0.3-p0-s16-manager-cache-runtime-isolation`
- Current status: `READY`
- Next notification: `UnityCodeDB v0.3 Planner`
- Next action: perform one bounded target-session check, then manually dispatch
  this frozen card to `v0.3.coder.deep`; request Unity evidence separately only
  after lower-cost evidence is stable.
- Human decision or authorization required: task dispatch, Unity/EditMode run,
  any allowlist expansion, Verifier routing, commit, push, and publication.

# Task: cdb-v0.3-p0-s12-fresh-lifecycle-integration

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep after a stable result and Planner routing
- Review mode: RELEASE
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s11-full-editmode-code-freeze` (`ACCEPT`)
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-supervisor-runtime-recovery.md`;
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p1-supervisor-lifecycle.md`;
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`.

## Objective

- Close the next roadmap validation gate as one continuous engineering outcome:
  one fresh visible Unity lifecycle pass covering cold start, cached Manager
  observation, Play, a proved Domain Reload, return to Edit Mode, and final
  Editor shutdown.
- Prove that those lifecycle transitions reuse one authenticated project
  Supervisor and selected instance, do not duplicate backend/materializer work,
  do not stop an external MCP client, and do not perform the prohibited CodeDB
  work synchronously on Unity's main thread.
- If the current code lacks the minimum reusable observation surface needed to
  prove the criterion, add that instrumentation and validate it inside this
  same task. Do not create a separate readiness, instrumentation, Play, reload,
  or shutdown task.

## Scope

### Continuous scenario

1. Start the existing `UnityValidationProject/` visibly from a proved closed
   state and wait for Package compilation and CodeDB lifecycle status to
   stabilize.
2. Observe the Manager while closed, then open it, repaint it, and change tabs.
   These UI reads must use cached state and must not start migration,
   materialization, another Supervisor, or full status work.
3. Enter Play, prove the managed Domain Reload occurred, remain in stable Play,
   then return to Edit Mode. Reconnect to the same authenticated Supervisor and
   selected instance without duplicate backend startup.
4. Close the visible Editor through its normal UI path. The exit callback must
   remain non-blocking and request shutdown only for authenticated project-owned
   backends. Do not stop or signal an external MCP client or unrelated process.
5. Collect the bounded final evidence and return one consolidated result.

### Allowed implementation surface

Only when direct inspection or scenario evidence requires it:

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorRequestQueue.cs`
- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- at most one new Editor-only instrumentation source, its Unity `.meta`, and
  one directly paired Editor test source when no existing observation seam can
  prove the required main-thread boundary.

The instrumentation must report bounded counters/events for the declared
callbacks and forbidden work categories. It must not expose machine paths,
tokens, command lines, user-profile data, raw runtime documents, or become a
second lifecycle authority.

### Out of scope

- Discover Read tools, query corpus, `rg` comparison, query performance, or
  changing the formal CodeDB usage rule.
- The full stale/missing-index matrix, a new indexing policy, Provider rewrite,
  activation/control schema redesign, or another immutable generation.
- Real new-Codex-task injection, consumer-project validation, third-party
  Package-only acceptance, concurrent Editor/elevation matrices, publication,
  deployment, or release.
- Creating, copying, repairing, or substituting a Unity project.

## Frozen Starting Snapshot

- Branch: `codex/v0.3.0-legacy-workflow`.
- HEAD: `9aada838e26879810a4f79760273ca66340ebf12`.
- Committed Package tree:
  `69d2c3e970813c44b7f458bdc686da7fac354b52`.
- Accepted S11 decision:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s11-full-editmode-code-freeze/DECISION.md`;
  - bytes `7358`;
  - SHA-256
    `1d5bc18612b5d1e3c3c5002413db26a9567f8e8c3c840ade8193e11d9b7e7a65`.
- Accepted uncommitted S11 repair inputs:
  - `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`, bytes
    `61326`, SHA-256
    `46177ac8900bc63f1c83da4c6688a251e199f5c17dd176d9007c1029537877db`;
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`, bytes
    `185969`, SHA-256
    `de69f380869044165415f2f5a69fd9780630fb21c54f0a97b5ede742cacd54cc`.
- A commit is not an admission prerequisite. Preserve the exact accepted S11
  repair while applying only S12 changes inside the allowed surface.

Protected validation inputs:

| Repository-relative path | Expected status | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `UnityValidationProject/Packages/manifest.json` | clean | `308` | `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd` |
| `UnityValidationProject/Packages/packages-lock.json` | clean | `1377` | `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913` |
| `UnityValidationProject/ProjectSettings/ProjectVersion.txt` | clean | `85` | `f450bbe4b5dc999988f56dff01af912886a765726ca3240d157357cff10517bf` |
| `UnityValidationProject/ProjectSettings/ProjectSettings.asset` | ` M` | `23135` | `9b1debf0b71ede99cbef5291d8aa9f5f3dac0a68c519ef60e2d70cf1638015e7` |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | clean | `378` | `8e18b1c820e9c09e16bbd1f1b7842e9fb3b0158a0921b0964e0b8fa12c6e2c01` |

- Preserve the existing `ProjectSettings.asset` serialization modification;
  do not normalize, stage, revert, or include it in a commit.
- `com.rice.ai-codedb/Documentation~/development-workflow.md` is a protected
  unrelated workflow edit. Do not change it during S12.
- Do not directly enumerate, read, edit, clean, stage, or make byte-identity
  claims about `UnityValidationProject/.codex/` or
  `UnityValidationProject/AIWork/`. Natural product-owned runtime writes caused
  by the authorized visible lifecycle are permitted, but evidence must come
  from the bounded instrumentation, Unity log, UI state, and process ownership
  observations declared here.

## Execution Envelope

### Human authorization

- On 2026-09-08 the user explicitly authorized the complete visible Unity
  scenario requested by this task card.
- The authorization covers normal visible startup of `UnityValidationProject/`,
  Manager observation, entering and exiting Play, a proved Domain Reload,
  normal Editor close, one initial complete scenario, and at most two corrected
  same-scope scenarios.
- This authorization does not permit hidden/background Unity, Unity MCP, Unity
  Hub launch, another project, an unchanged rerun, process termination, direct
  inspection or cleanup of protected `.codex/` or `AIWork/`, commit, push,
  Verifier dispatch, publication, or release.

### Before Unity authorization

- Task-card creation and dispatch do not authorize Unity.
- The project must remain closed. Do not launch Unity, Unity Hub, Unity MCP, a
  Supervisor, Node, PowerShell materializer, Provider, or another product
  process during implementation/readiness inspection.
- Inspect only the direct lifecycle/Manager/Supervisor callback and existing
  diagnostic seams. If instrumentation is required, implement it and run only
  applicable non-Unity syntax/L0/compile evidence before requesting the visible
  scenario.

### Requested one-time human authorization

One authorization should cover the whole visible scenario envelope:

```text
Project path: UnityValidationProject/
Purpose: fresh cold-start, Manager-cache, Play, Domain Reload, reconnect, and
  authenticated final-shutdown integration acceptance
Operation: start the registered Unity 2022.3.47f1 Editor visibly; operate only
  this project; enter and exit Play; trigger/prove the declared Domain Reload;
  close through normal UI after evidence capture
Evidence class: fresh local Unity runtime lifecycle acceptance
Scenario attempts: one initial complete scenario plus at most two corrected
  same-scope scenarios; never rerun unchanged evidence
Maximum wait: 300 seconds for each bounded startup or transition wait
Cleanup ownership: never terminate Unity or another process on timeout; return
  visible Editor/process ownership to the human
```

- Coder operates the visible Editor using approved UI control. If visible UI
  control is unavailable, stop once and request a human operator handoff; do
  not substitute BatchMode, hidden/background Unity, Unity MCP, or a synthetic
  project.
- Parser, escaping, path-normalization, or admission command construction may
  receive at most two recorded mechanical corrections before side effects;
  those do not consume a Unity scenario attempt.
- A Unity scenario rerun requires a concrete same-cause code, instrumentation,
  fixture, or prerequisite correction. The maximum is an envelope, not a
  requirement to consume all attempts.

### Admission and evidence

- Parse the frozen task identities from this card instead of manually copying
  them into a new command. Require the exact branch, HEAD, S11 decision,
  accepted S11 repair inputs, protected validation inputs, Unity project
  version/revision, and repository-local Package manifest/lock binding.
- Resolve Unity from Hub `editors-v2.json` structurally. For the exact declared
  version, accept either a direct existing `Unity.exe` location or an Editor
  root containing that executable. Require exactly one match; do not start Hub
  or search disks.
- Before each visible scenario, perform one passive point-in-time check and
  require no matching Unity process for `UnityValidationProject/`.
- Record bounded, sanitized lifecycle events and counters sufficient to prove:
  callback identity and duration; zero prohibited main-thread CodeDB work;
  one Supervisor/selected-instance continuity across reload; no duplicate
  backend/materializer; Manager cache-only reads; and final authenticated
  shutdown disposition.
- Read each task-owned Unity log/evidence artifact once with structured or
  bounded aggregation. Do not dump logs or repeatedly scan the repository.
- At final handoff, run one scoped status/diff review and one scoped
  `git diff --check` over actual allowed changes. Do not run full-repository
  status/diff or recompute unchanged identities at every transition.

## Test Plan

```text
L0 tests: only direct instrumentation/lifecycle pure-logic or Supervisor syntax
  tests required by an actual S12 edit; reuse S11 evidence for unchanged code
Affected L1 tests: only direct lifecycle/Manager tests implicated by an actual
  edit; do not rerun the full EditMode suite
Additional evidence: the explicitly authorized visible Unity lifecycle
  scenario described above
Explicitly not run: full EditMode, PlayMode Test Runner, Unity MCP, another
  Unity project, real Codex Desktop, third-party Package-only, query corpus,
  performance, publication, deployment, and release acceptance
```

## Stop Conditions

- Unity authorization is absent; the validation project is already open; a
  frozen/protected identity drifts; Package binding or Unity version is wrong;
  or a foreign matching Unity process exists.
- Continuing requires direct inspection or mutation of protected `.codex/` or
  `AIWork/`, process termination, an external-client signal, global
  configuration, a new project, or a file outside the allowed implementation
  surface.
- A visible Unity transition times out, UI control is unavailable, evidence is
  missing/corrupt, the authorized scenario envelope is exhausted, or an
  unrelated engineering objective appears.
- On timeout or uncertain ownership, do not stop a process. Preserve the
  classifiable evidence and return ownership to the human.

Completed failing scenarios are classified inside this same task as
`COMPLETE / TEST_FAILURE_CLASSIFIED` or
`COMPLETE / INFRASTRUCTURE_FAILURE_CLASSIFIED`; they are not automatically
`BLOCKED` and do not create S12a. Use `BLOCKED` only when the unavailable
condition prevents a classifiable result or further progress.

## Definition Of Done

- One final authorized visible lifecycle scenario completes every declared
  transition and its bounded evidence checks.
- Cold start reaches a stable cached product state without an unnecessary
  manual Reinstall or duplicate command owner.
- Manager observation remains cache-only; Play and proved Domain Reload reuse
  the same authenticated Supervisor/selected instance; no duplicate backend or
  materializer is launched.
- Instrumentation records zero prohibited CodeDB filesystem, hash, process,
  lock, synchronous IPC, PowerShell/Node, indexing, or full-status work on
  Unity's main thread for the declared callbacks.
- Final Editor shutdown is non-blocking, affects only authenticated
  project-owned backends, preserves external/unrelated processes, and leaves no
  matching Unity process.
- Protected tracked inputs remain unchanged; remaining runtime, consumer,
  third-party, Discover Read, and release boundaries are explicitly deferred.

## Result And Verification

- Coder writes one `RESULT.md` containing the consolidated diagnosis, actual
  changes, bounded non-Unity evidence, each visible scenario result, final
  identities, and deferred boundaries. Same-cause corrections remain in this
  task; create a checkpoint only for a real interruption or ownership handoff.
- After Planner confirms a stable result, route the exact snapshot once to
  `v0.3.verifier.deep`. Verifier performs targeted read-only review and reuses
  the Coder runtime evidence; it does not rerun Unity or another test.
- Do not commit, push, publish, or dispatch Verifier automatically.

## Handoff

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`  
Current status: `READY_AUTHORIZED`  
Next notification: `v0.3.coder.deep`  
Next action: execute the complete continuous S12 task from bounded readiness
inspection through the authorized visible lifecycle scenario and return one
consolidated result to Planner  
Human decision or authorization required: only a scope/authority expansion,
external blocker, exhausted scenario envelope, human UI takeover, commit, push,
Verifier routing, or later roadmap gate returns to Planner/User

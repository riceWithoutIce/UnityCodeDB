# VERIFICATION - cdb-v0.3-p0-s16-manager-cache-runtime-isolation

## Verdict

`PASS`

This is the single targeted `RELEASE` / read-only review authorized by
`Planner Authorization - FIX 01 RELEASE Verification`. The review is limited to
the original main-thread identity-Hash finding and its direct fallback,
worker-ownership, instrumentation, and nearest-test regressions. No unrelated
S15 or S16 requirements were reopened.

Findings: `none`.

## Frozen admission

- Branch: `codex/v0.3.0-legacy-workflow`
- Expected HEAD: `0b9aeac6c3586d65c041cc11cc1d232454618909`
- Observed HEAD: `0b9aeac6c3586d65c041cc11cc1d232454618909`
- HEAD admission: `PASS`
- Frozen ordered paths:
  1. `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  2. `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Expected canonical two-path identity:
  `9c7e47b8fd011f4875258b6de5b8b166eec8e4e9`
- Observed canonical two-path identity:
  `9c7e47b8fd011f4875258b6de5b8b166eec8e4e9`
- Canonical identity admission: `PASS`

The identity was checked once with the only authorized method:

```powershell
git diff HEAD --binary -- "com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" | git hash-object --stdin
```

The task records' historical `patch-id --stable` value was not used for
admission. Task records and inherited S14/S14r/validation-project state were
excluded from the identity.

## Targeted review

### 1. Published identity and bounded cache miss: `PASS`

`TryGetPersistedProductState` first calls
`TryGetPublishedProjectIdentityForDisplay` with the requested root and the
lifecycle-published root/identity. The selector rejects an empty requested
root, empty published root, or empty published identity, and rejects roots
whose normalized values differ case-insensitively. Only the exact non-empty
published identity is then used as the `SessionState` key. The output state is
initialized to `Starting`; absent or mismatched evidence therefore remains a
bounded cache miss rather than deriving a replacement identity.

The nearest source tests cover:

- missing published identity -> `false` and `Starting`;
- mismatched published root -> rejection;
- equivalent normalized root -> exact published identity reuse;
- persisted Ready lookup through explicit published evidence; and
- the Manager-facing method's rejection of `TryResolveProjectIdentity`,
  `CreateProjectIdentity`, and `AICodedbLifecycleWorkKind.Hash` fallback.

Relevant source/test anchors: `AICodedbEditorLifecycle.cs` lines 2170-2206
and 2281-2324; `AICodedbEditorLifecycleTests.cs` lines 1785-1873.

### 2. Display-only main-thread boundary: `PASS`

The reviewed display selector performs only string validation and path
normalization. It does not validate directories, read files, acquire locks,
inspect processes, invoke IPC/materializers, index, construct a hash, or build
a full status snapshot. `TryGetPersistedProductState` reads only
`SessionState` after identity selection and keeps the `Starting` fallback.

The Manager's parameterless `RefreshStatus` consumes the lifecycle-published
cache/persisted hint and does not call the synchronous full-status overload.
The direct full-status overload remains instrumented and has no Manager call
site in the reviewed path. `AICodedbStatusSnapshot.RefreshAsync` retains the
filesystem/hash/full-status work inside its `Task.Run` worker, so the
instrumentation remains observable rather than suppressed.

Relevant source anchors: `AICodedbManagerWindow.cs` lines 301-347, 447-465,
509-590; `AICodedbStatusSnapshot.cs` lines 442-461.

### 3. Worker ownership and identity authority: `PASS`

`PrepareLifecycleInitialization` remains the worker boundary for project-root
validation, canonical identity construction, and process identity capture. The
existing general resolver remains available to lifecycle callers that require
it; the Manager-facing persisted-state method no longer re-enters that
resolver. No second identity authority, counter reset, or diagnostic
suppression was introduced by FIX 01.

Relevant source anchors: `AICodedbEditorLifecycle.cs` lines 125-166 and
273-287 for worker preparation, lines 2131-2167 for the general resolver, and
lines 2175-2206 / 2297-2324 for the bounded display path.

### 4. Fresh human runtime evidence: `PASS`

The accepted terminal `CODEDB_S12_EVIDENCE` record in `RESULT.md` has
`checkpoint=manager_closed` and reports:

- Unity compilation disposition: `PASS`;
- `manager_open_count=1`, `manager_enable_count=1`;
- `manager_repaint_count=609`, `manager_tab_change_count=17`;
- `manager_cache_read_count=595479`, `manager_close_count=1`;
- `main_thread_work_counts=[0,0,0,0,0,0,0,0]`;
- `main_thread_violation_count=0`; and
- `manager_status_refresh_in_flight_count=0` after close.

This satisfies the authorized restored-window rule. The earlier record with
`manager_open_count=0` is not reused as a failure; the later terminal record
contains positive Manager activity and is the applicable evidence.

### 5. Nearest regression disposition: `PASS`

The source/test review preserves the lifecycle cache handoff and the existing
worker instrumentation. The nearest tests are present for missing identity,
root mismatch, normalized-root matching, exact published identity, persisted
Ready fallback, and rejection of display-path identity derivation/Hash work.
No second cache or identity authority is introduced.

## Reused evidence

No existing evidence was rerun or promoted beyond its declared scope:

- FIX 01 scoped `git diff --check`: recorded `PASS` with no output;
- FIX 01 canonical two-path identity: admitted above;
- fresh human Unity `manager_closed` runtime evidence: recorded `PASS` in
  `RESULT.md`;
- the repeated static/source selector is permanently classified
  `DEFERRED / UNSUITABLE_EVIDENCE_HARNESS` and was not executed or required.

The source review above is a direct read-only review, not a rerun of that
selector or a claim that its failed harness reached a PASS result.

## NOT RUN / DEFERRED

- Unity, Unity MCP, CUA/computer-use, BatchMode, and external probes: `NOT RUN`.
- C# compile, EditMode, L0/L1, and full regression: `NOT RUN` / `DEFERRED` by
  the authorization boundary. The reported human Unity compilation disposition
  is reused evidence, not independently rerun here.
- The repeated ad hoc static/source selector: `DEFERRED /
  UNSUITABLE_EVIDENCE_HARNESS`; no retry was attempted.
- `git diff --check`: not rerun; recorded result reused.
- Process/application inventory, Console/Editor-log reads, protected runtime
  reads, repository-wide search, full diff, source/test edits, commit, push,
  publication, and Coder contact: `NOT PERFORMED`.

## Residual risk

The targeted release conclusion is supported by direct source review and the
accepted human runtime record, while independent C# test execution and the
failed static selector remain outside this review. Those boundaries are
explicitly deferred and do not represent additional product findings in the
frozen FIX 01 scope.

## Routing

Current task: `cdb-v0.3-p0-s16-manager-cache-runtime-isolation`
Current status: `PASS`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner/User disposition
Human decision or authorization required: `ACCEPT / FIX / DEFER / STOP`

# Task: cdb-v0.3-p0-s10j-supervisor-schema-expectation-fix

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: none for this bounded test-only fix
- Review mode: GUARDED
- Complexity: Low
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10i-editmode-artifact-classification`
  (`COMPLETE`; corrected Unity run produced 68/69 passing cases and one stale
  schema expectation).
- Human authorization: on 2026-09-07 the user explicitly approved this
  single-file, single-assertion test-only fix.

## Objective

- Correct the one stale EditMode expectation that caused the S10f corrected
  run to return exit code `2`.
- Preserve the independent protocol oracle: the test must assert the
  Supervisor *state schema* value `3`, while the separate
  `supervisor_protocol_version` remains `2`.
- Produce a bounded static proof suitable for a later, separately authorized
  `39-method / 69-case` Unity rerun.

## Confirmed Finding

- Failing method:
  `SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady`
- Current assertion in the frozen test file:

```csharp
Assert.That(snapshot.SupervisorSchemaVersion, Is.EqualTo(2));
```

- The direct protocol contract establishes:
  - `SupervisorStateSchemaVersion = 3`;
  - `SupervisorVersion = 2` for the different `supervisor_protocol_version`
    field.
- The response fixture already writes
  `supervisor_schema_version` from `SupervisorStateSchemaVersion`; the current
  assertion is therefore the stale test oracle, not a production regression.

## Scope

- Only code file allowed to change:
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Only source edit allowed:
  - change the exact `SupervisorSchemaVersion` assertion in the named method
    from `Is.EqualTo(2)` to `Is.EqualTo(3)`.
- Only evidence file allowed:
  - this task's `RESULT.md`
- Production files, other tests, fixtures, configuration, validation-project
  files, earlier task records, XML/log artifacts, and workflow files are
  protected and read only.
- Do not modify SetUp/TearDown, response construction, protocol constants, or
  any other assertion.

## Frozen Input

- Expected HEAD:
  `6408b0d540b32584147588efb67ecc5ba12b2fda`
- Current test file before this task:
  - bytes: `183864`;
  - SHA-256:
    `8048a39235dc115465cf972441135e328de81a6af3a96b126ce0f8f81b8c411f`;
  - expected scoped status: ` M`.
- S10i result identity:
  - bytes: `5528`;
  - SHA-256:
    `cf9bb220cc32b67653db227986746845996a6f3c87bc3798e38753f328e90a34`.
- S10f result identity (the run being repaired):
  - bytes: `6985`;
  - SHA-256:
    `11ca24094fe57de81e0a8c492046f877d8bbc118a1b0e6f081a93f7ba24e0ff1`.
- Preserve all existing modified and untracked worktree paths. A commit is not
  an execution prerequisite.

## Admission

- Read this task once and perform one bounded admission check.
- Require exact HEAD, the frozen test-file bytes/hash/status, and the S10i/S10f
  result identities above.
- Require zero `Unity.exe` processes whose command line names the relative
  validation project `UnityValidationProject/`.
- Check only the declared test file status; do not run full status or diff.
- Any mismatch returns `BLOCKED` without editing or testing.

## Implementation

- Use `apply_patch` for exactly one replacement in the named method:

```diff
-            Assert.That(snapshot.SupervisorSchemaVersion, Is.EqualTo(2));
+            Assert.That(snapshot.SupervisorSchemaVersion, Is.EqualTo(3));
```

- Before applying the edit, require the old line to occur exactly once in the
  named method and the new line to be absent there.
- After applying it, require the old line to be absent from that method and the
  new line to occur exactly once.
- Do not alter whitespace, line endings, comments, method order, or any other
  file content intentionally.

## Static L0 Evidence

- Run one self-contained static block, batch `1/1`, retry `0/0`.
- Read the current file and its exact `HEAD:path` blob as normalized text.
- Locate the named method exactly once with a balanced-brace scan.
- Replace only the target assertion line in both texts with a stable sentinel
  and require the remaining normalized file text to be ordinally identical.
  This proves the single-line delta is the only source change.
- Require direct facts in the current method:
  - `SupervisorSchemaVersion` expectation `3` exactly once;
  - no `SupervisorSchemaVersion` expectation `2`;
  - no new production or fixture expression.
- Read the directly referenced production constant only as a narrow fact and
  require `SupervisorStateSchemaVersion = 3`; require the distinct
  `SupervisorVersion = 2` fact remains unchanged. Do not scan unrelated code.
- Emit only compact assertion names and PASS/FAIL results; do not print full
  source, paths, or diff content.

## Final Evidence

- After static L0 passes, run exactly once:

```powershell
git diff --check -- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
```

- Record in this task's `RESULT.md`:
  - final HEAD and test-file bytes/SHA-256/scoped status;
  - exact method and one-line change;
  - production schema/protocol direct facts;
  - static L0 and diff-check exits/wall times;
  - batch/retry/output ledger and actual profile;
  - explicit `NOT RUN` / `DEFERRED` boundaries and completion-routing footer.
- Use repository-relative paths only. Do not record absolute machine,
  repository, Unity executable, temporary, user-profile, or synthetic paths.
- Do not claim the Unity rerun passed; that run is a separate task.

## Prohibited Actions

- Do not modify production code, any other test, task record, XML/log,
  configuration, or validation-project file.
- Do not start, stop, attach to, poll, or control Unity, Unity Hub, Unity MCP,
  Package Manager, Supervisor, or another process.
- Do not run Unity, EditMode, C# compilation, any other test, L0/L1 harness,
  broad search, full diff/status, or artifact reread.
- Do not retry after a failed static block or diff-check.
- Do not commit, push, stash, reset, clean, rebase, amend, or contact Verifier.

## Stop Conditions

- Frozen identity/status or no-Unity admission differs.
- The old assertion is absent/duplicated, the production constants differ, or
  the requested edit would touch another line/file.
- Static L0 or scoped diff-check fails, output truncates, or a retry would be
  needed.
- Any Unity or broader test action is proposed.

## Definition Of Done

- Exactly one test assertion changes from `2` to `3`.
- Static proof and single-file diff-check pass.
- All prior evidence and worktree state remain unchanged and uncommitted.
- A new corrected Unity run can be authorized separately with no unresolved
  test-oracle blocker.

## Handoff

Current task: cdb-v0.3-p0-s10j-supervisor-schema-expectation-fix
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.standard
Next action: apply the single-line test-only correction, produce bounded static evidence, and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: corrected Unity/EditMode rerun, Verifier routing, manual Unity acceptance, commit, or push remains separately gated

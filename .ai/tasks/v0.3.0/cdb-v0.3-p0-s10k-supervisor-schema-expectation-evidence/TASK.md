# Task: cdb-v0.3-p0-s10k-supervisor-schema-expectation-evidence

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: none for this bounded evidence recapture
- Review mode: GUARDED
- Complexity: Low
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10j-supervisor-schema-expectation-fix`
  (`BLOCKED` only because its static proof compared the post-S10c file to HEAD
  after masking the S10j line, instead of accounting for the four accepted S10c
  method changes).
- Human authorization: on 2026-09-07 the user authorized this independent
  bounded evidence attempt.

## Objective

- Prove the already-applied S10j one-line test correction without changing it or
  any earlier record.
- Account explicitly for all four accepted S10c method changes when comparing
  the current file with the frozen HEAD blob.
- Run the deferred single-file `git diff --check` so Planner can decide on a
  separately authorized corrected Unity rerun.

## Confirmed Fix

- Reviewed method:
  `SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady`
- Current target assertion must be exactly:

```csharp
Assert.That(snapshot.SupervisorSchemaVersion, Is.EqualTo(3));
```

- The S10j change is the only change added after the accepted S10c patch. The
  four pre-existing S10c method changes remain part of the current snapshot and
  must not be reverted, rewritten, or treated as new drift.

## Scope

- Only code input/read-write file:
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Only evidence output:
  - this task's `RESULT.md`
- The code file may be edited only if the exact S10j target line is not already
  the required `3`; if it is already correct, leave it unchanged. No other
  source line may be edited.
- Production files, other tests, S10c/S10j records, Package/configuration,
  validation-project files, XML/log artifacts, and workflow files are protected
  and read only.

## Frozen Input

- Expected HEAD:
  `6408b0d540b32584147588efb67ecc5ba12b2fda`
- Test file before S10j (accepted S10c state):
  - bytes: `183864`;
  - SHA-256:
    `8048a39235dc115465cf972441135e328de81a6af3a96b126ce0f8f81b8c411f`.
- Current test file at S10k admission (S10j state):
  - bytes: `183864`;
  - SHA-256:
    `ce5784f90d4cdc18ffe4668329924557f909dc5a9280276d44907240d93d691b`;
  - expected scoped status: ` M`.
- S10c sanitized result:
  - bytes: `2772`;
  - SHA-256:
    `8dd6133a6d55aaef17caa28ee3351616c9e8ed5a2d20e59bd7691cb43701b3a5`.
- S10j result:
  - bytes: `3204`;
  - SHA-256:
    `15c8ace221f5fcdac792f146855f53c8057eaa324eeea4e6ae5658f6c090c8be`.
- Preserve every existing modified and untracked worktree path. A commit is
  not an execution prerequisite.

## Admission

- Read this task once and execute one bounded admission stage.
- Require exact HEAD, the current test-file bytes/hash/status, and S10c/S10j
  result identities above.
- Require zero `Unity.exe` processes whose command line names the relative
  validation project `UnityValidationProject/`.
- Query only the target test-file status; do not run full status or a broad
  diff. Any mismatch returns `BLOCKED` without editing or testing.

## Implementation Guard

- Inspect the target method once. Require exactly one occurrence of the old
  line with `Is.EqualTo(2)` or exactly one occurrence of the corrected line
  with `Is.EqualTo(3)`.
- If the corrected line is already present, perform no code edit.
- If the old line is present, use `apply_patch` for that exact one-line
  replacement only. Any other form, duplicate, or missing target is `BLOCKED`.

## Static L0 Evidence

- Run one self-contained static block, batch `1/1`, retry `0/0`.
- Read the current file and the exact `HEAD:path` blob as normalized text.
- Construct an expected post-S10j text in memory from the HEAD blob using only
  these explicitly count-checked transformations, in this order:

  1. Replace exactly three occurrences of
     `var root = Path.Combine(Path.GetTempPath(), "CodeDB-Bridge-Fixture", "FixtureProject");`
     with `var root = _projectRoot;` in the three S10c status/handshake methods.
  2. Replace exactly one wrong-root expression using the temporary fixture
     parent with `var wrongRoot = Path.Combine(_projectRoot, "OtherProject");`
     and insert exactly one `Assets`, one `Packages`, and one `ProjectSettings`
     marker creation call in that same method.
  3. Replace exactly one legacy literal
     `codedb-supervisor-f08a16463cf35b32cdab` with
     `codedb-supervisor-928a30ffe326434cc56f`.
  4. Replace exactly one target schema assertion from `Is.EqualTo(2)` to
     `Is.EqualTo(3)`.

- Every transformation must verify its exact old count and resulting new count
  before proceeding. If any count is different, stop `BLOCKED`.
- Compare the resulting expected text with the current normalized file using
  ordinal equality. This proves the current file consists of the four accepted
  S10c changes plus the one S10j line and nothing else.
- Independently extract the four S10c methods and the S10j method with a
  balanced-brace scan, and require:
  - three status methods use `_projectRoot` exactly once;
  - only wrong-identity uses `_projectRoot/OtherProject` and the three marker
    calls;
  - `CodeDB-Bridge-Fixture` is absent from all four S10c bodies;
  - the new legacy literal occurs exactly once in its intended method;
  - `SupervisorSchemaVersion` expects `3` exactly once and never `2` in the
    intended method.
- Read only the direct production constants as a narrow contract fact and
  require `SupervisorStateSchemaVersion = 3` and distinct `SupervisorVersion =
  2`. Do not inspect unrelated production code.
- Emit compact assertion names and PASS/FAIL only; do not print full source or
  patch content.

## Final Evidence

- After static L0 passes, run exactly once:

```powershell
git diff --check -- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
```

- Record in this task's `RESULT.md`:
  - final HEAD, test-file bytes/SHA-256/scoped status;
  - whether the one-line edit was applied or already present;
  - exact five-change expected-text proof (four S10c + one S10j);
  - direct schema/protocol constants;
  - static L0 and diff-check exit codes/wall times;
  - batch/retry/output ledger, actual profile, and deferred boundaries.
- Use repository-relative paths only; do not record machine, user-profile,
  temporary, executable, or synthetic absolute paths.
- Preserve the standard completion-routing footer and state that Unity rerun,
  Verifier, commit, and push remain separately gated.

## Prohibited Actions

- Do not alter production code, any test line other than the exact target, or
  any prior task/result record.
- Do not start, stop, attach to, poll, or control Unity, Unity Hub, Unity MCP,
  Package Manager, Supervisor, or another process.
- Do not run Unity, EditMode, C# compilation, any other test, L0/L1 harness,
  broad search, full status/diff, or artifact reread.
- Do not retry after a failed admission, static block, or diff-check.
- Do not commit, push, stash, reset, clean, rebase, amend, contact Verifier, or
  dispatch a rerun.

## Stop Conditions

- Frozen identity/status or no-Unity admission differs.
- Any S10c transformation count, method extraction, contract fact, or expected
  text comparison fails.
- Static L0 or scoped diff-check fails, output truncates, or a retry is needed.
- The target requires more than the one declared line or another file.

## Definition Of Done

- Current test file is proven to contain exactly the accepted S10c patch plus the
  corrected S10j schema expectation.
- Static L0 and one-file diff-check pass.
- No Unity/test execution or unrelated modification occurs.
- Planner can authorize a fresh corrected `39-method / 69-case` Unity run.

## Handoff

Current task: cdb-v0.3-p0-s10k-supervisor-schema-expectation-evidence
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.standard
Next action: execute the bounded five-change static evidence recapture and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: corrected Unity/EditMode rerun, Verifier routing, manual Unity acceptance, commit, or push remains separately gated

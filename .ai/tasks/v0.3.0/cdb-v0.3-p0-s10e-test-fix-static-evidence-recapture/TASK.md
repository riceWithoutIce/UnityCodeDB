# Task: cdb-v0.3-p0-s10e-test-fix-static-evidence-recapture

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: none for this evidence-only recapture
- Review mode: GUARDED
- Complexity: Low
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10d-test-fix-static-evidence`
  (`BLOCKED` by a false-negative semantic-delta assertion after report
  sanitization and oracle recomputation had passed).
- Human authorization: on 2026-09-07 the user approved this new independent,
  bounded static-evidence recapture.

## Objective

- Recapture the missing static evidence for the already-frozen S10c test-only
  patch without changing any code or prior task record.
- Prove the four allowed method-local changes using method boundaries and
  direct before/after facts, avoiding S10d's brittle reconstructed-method
  equality assertion.
- Run the one deferred single-file `git diff --check` after the static block
  passes so Planner can authorize the corrected Unity/EditMode run separately.

## Scope

- Read-only code input:
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - the exact HEAD version of that same file
- Read-only task evidence:
  - S10c `RESULT.md`
  - S10d `TASK.md`
  - S10d `RESULT.md`
- Only allowed write:
  - this task's `RESULT.md`
- Reviewed methods:
  - `SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady`
  - `SupervisorProtocol_StatusHandshakeBlocksWrongProjectIdentity`
  - `SupervisorProtocol_ReadyWithoutProviderHandshakeIsBlocked`
  - `SupervisorProtocol_UsesCanonicalPipeIdentityAndRecognizesExactV1Handoff`
- All source, tests, earlier task records, Package and validation-project
  configuration, workflow files, and ignored Unity artifacts are protected and
  read only.

## Frozen Input

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Current S10c-patched test file:
  - bytes: `183864`;
  - SHA-256:
    `8048a39235dc115465cf972441135e328de81a6af3a96b126ce0f8f81b8c411f`;
  - expected scoped status: ` M`.
- Sanitized S10c `RESULT.md`:
  - bytes: `2772`;
  - SHA-256:
    `8dd6133a6d55aaef17caa28ee3351616c9e8ed5a2d20e59bd7691cb43701b3a5`;
  - expected scoped status: untracked.
- S10d `TASK.md`:
  - bytes: `8191`;
  - SHA-256:
    `e6d824816cba8528af056071b2f244f063539dfc54b17520f79facbad88a60f9`;
  - expected scoped status: untracked.
- S10d `RESULT.md`:
  - bytes: `2929`;
  - SHA-256:
    `9f3bf12870c1017df7e6c94f14f855bb9ebe4e5e3c06eca3b87f3de99bcffabc`;
  - expected scoped status: untracked.
- Preserve all existing unrelated modified and untracked paths. A commit is not
  an execution prerequisite.

## Admission

- Read this task once and perform one bounded admission check for:
  - exact HEAD and all four frozen file identities;
  - exact scoped status of those four paths;
  - absence of a `Unity.exe` process whose command line names the relative
    validation-project directory `UnityValidationProject/`.
- The process check is a single point-in-time read, not polling. Do not start,
  stop, attach to, signal, or otherwise control any process.
- Any mismatch returns `BLOCKED` without writing `RESULT.md` beyond the
  immutable failure record and without running the static block.

## Static L0

- Run one self-contained PowerShell static block, batch `1/1`, retry `0/0`.
- Read the current test file as a raw string and read only its exact HEAD blob
  using the scoped `HEAD:path` form. Normalize CRLF/LF to LF in memory.
- Locate every reviewed method exactly once by its exact signature and extract
  each complete method with a balanced-brace scan.
- Replace the four extracted methods in the baseline and current strings with
  distinct stable sentinels. Require all remaining text to be ordinally equal.
  This is the only whole-file equality assertion and establishes that no code
  outside the four reviewed methods changed.
- For literal counts use direct string APIs or
  `[regex]::Matches($text, [regex]::Escape($literal)).Count`. Do not pipe method
  text through `Select-String`.
- Do not reconstruct an expected complete method with chained replacements and
  do not compare such a reconstructed method to the current body; that is the
  S10d assertion shape being retired.

### Direct Baseline Facts

- In the HEAD bodies of the two ordinary status tests, require exactly one:
  `var root = Path.Combine(Path.GetTempPath(), "CodeDB-Bridge-Fixture", "FixtureProject");`
- In the HEAD wrong-identity body, require that same primary-root line and
  exactly one old `wrongRoot` expression using `Path.GetTempPath()` and the
  `CodeDB-Bridge-Fixture` parent. Require no marker-directory creation there.
- In the HEAD legacy-pipe body, require the old literal
  `codedb-supervisor-f08a16463cf35b32cdab` exactly once and the new literal
  absent.

### Direct Current Facts

- Each of the three current status/handshake bodies must contain exactly one
  `var root = _projectRoot;` and must not contain the old primary-root line.
- Only the current wrong-identity body may contain exactly one
  `var wrongRoot = Path.Combine(_projectRoot, "OtherProject");`.
- That body must contain exactly one creation call for each nested
  `Assets`, `Packages`, and `ProjectSettings` directory. Those three exact
  marker calls must be absent from the other reviewed bodies.
- `CodeDB-Bridge-Fixture` must be absent from all four current bodies.
- The old legacy literal must be absent from the current file.
- `codedb-supervisor-928a30ffe326434cc56f` must occur exactly once in the
  current file and must occur in the current legacy-pipe body.
- Reuse, without recomputation, S10d's frozen successful independent-oracle
  evidence. The exact S10d result identity in Admission binds that evidence.
- Emit only compact assertion names and PASS/FAIL results. Do not emit complete
  methods, paths, source bodies, or a patch.

## Final Evidence

- Only after the static L0 passes, run exactly once:

```powershell
git diff --check -- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
```

- Record in this task's `RESULT.md`:
  - final HEAD, test-file bytes/SHA-256/scoped status;
  - the four exact method names;
  - out-of-scope sentinel comparison and direct-fact results;
  - reused S10d oracle identity;
  - static L0 and diff-check exit codes and wall times;
  - batch/retry ledger and actual execution profile;
  - explicit `NOT RUN` / `DEFERRED` boundaries and standard routing footer.
- Use repository-relative paths only. Do not record an absolute machine,
  repository, Unity executable, temporary, user-profile, or synthetic path.
- Captured output: `16 KiB` per command and `64 KiB` aggregate. Normal command
  maximum: `60 seconds`.

## Prohibited Actions

- Do not modify production code, test code, S10c/S10d records, configuration,
  or any existing artifact.
- Do not start, stop, attach to, poll, or control Unity, Unity Hub, Unity MCP,
  Package Manager, Supervisor, or another process.
- Do not run EditMode, C# compilation, another L0/L1 harness, or any other test.
- Do not use a full diff/status, repository-wide search, broad log read,
  duplicate identity check, or reconstructed-method equality assertion.
- Do not commit, push, stash, reset, clean, rebase, amend, contact Verifier, or
  dispatch the future Unity run.

## Stop Conditions

- Frozen admission or Unity-process admission differs.
- Method extraction, out-of-scope comparison, or any direct fact fails.
- Static L0 or scoped diff-check fails, output truncates, a retry is needed, or
  another independent blocker appears.
- Any conclusion would require editing a protected file or running Unity.

## Definition Of Done

- The existing four-method S10c patch has one successful, reproducible static
  evidence record without modifying the frozen snapshot.
- No source text outside those methods differs from HEAD.
- The three owned project-root fixtures, nested wrong-identity markers, and
  independent legacy oracle literal are directly proven.
- The single-file `git diff --check` passes.
- Planner can create the corrected 39-method / 69-case synchronous Unity run
  task without another static repair/evidence attempt.

## Handoff

Current task: cdb-v0.3-p0-s10e-test-fix-static-evidence-recapture
Current status: READY
Next notification: v0.3.coder.standard
Next action: execute the bounded read-only static-evidence recapture and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: corrected synchronous Unity/EditMode execution, any Verifier routing, commit, or push remains separately gated

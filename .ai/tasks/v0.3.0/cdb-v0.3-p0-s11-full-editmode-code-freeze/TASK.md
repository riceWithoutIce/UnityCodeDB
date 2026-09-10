# Task: cdb-v0.3-p0-s11-full-editmode-code-freeze

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep after Planner routing, only if the result is
  stable
- Review mode: RELEASE
- Complexity: High
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10-control-plane-focused-editmode` (`ACCEPT`).
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-control-contract-migration.md`;
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`.
- Human authorization: on 2026-09-08 the user confirmed
  `UnityValidationProject/` was closed and explicitly authorized this one-shot
  full EditMode execution.

## Objective

- Execute the roadmap's one fresh full Unity EditMode pass on the committed
  control-plane code-freeze snapshot.
- Prove that the complete discoverable package Editor test suite compiles and
  passes through `UnityValidationProject/`, without a method or class filter.
- Preserve the committed Package tree and the validation project's tracked
  contract across the run.
- Produce development code-freeze evidence only; do not claim runtime,
  consumer, Codex Desktop, or release acceptance.

## Scope

- Validation project: `UnityValidationProject/` only.
- Test surface: every EditMode test discoverable in the validation project.
- Expected topology at admission:
  - exactly one package test assembly:
    `com.rice.ai-codedb/Tests/Editor/Rice.AICodedb.Editor.Tests.asmdef`;
  - assembly name: `Rice.AICodedb.Editor.Tests`;
  - `optionalUnityReferences` includes `TestAssemblies`;
  - no test assembly exists below `UnityValidationProject/Assets/`.
- Source, tests, Package files, validation-project configuration, workflow, and
  prior task records are read only.
- Allowed durable output:
  - this task's `RESULT.md`.
- Allowed ignored run artifacts:
  - `UnityValidationProject/TestResults-S11-full-editmode.xml`;
  - `UnityValidationProject/Logs/S11-full-editmode-code-freeze.log`.
- Do not create, copy, repair, regenerate, or substitute a Unity project.

## Full-Regression Authorization Boundary

- This is the explicitly requested roadmap code-freeze exception to the normal
  focused-test rule. It is not an implementation slice and has no source edit.
- Exact test filter: none. The Unity command must omit `-testFilter` and
  `-assemblyNames`; the single validation project and its sole test assembly
  define the full EditMode surface.
- Additional tests: the complete discoverable EditMode suite.
- Code change they cover: committed S02-S10 v0.3 control-plane snapshot.
- Direct impact relationship: this is validation order item 4 after the
  accepted focused EditMode pass.
- Risk if not run: undiscovered cross-suite or non-focused regressions remain
  outside the code-freeze evidence.
- Creating this task card does not authorize starting Unity. The run requires a
  separate explicit human authorization after reviewing this exact request.

## Frozen Snapshot

- Expected branch: `codex/v0.3.0-legacy-workflow`.
- Expected HEAD:
  `9aada838e26879810a4f79760273ca66340ebf12`.
- Expected Package tree:
  `69d2c3e970813c44b7f458bdc686da7fac354b52`.
- Accepted S10 decision:
  - path:
    `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10-control-plane-focused-editmode/DECISION.md`;
  - bytes: `5138`;
  - SHA-256:
    `2982dbfad319524a68195d42a325c4d4573afd2ea7cf5d82b5a24a29d01069b5`.
- Validation inputs:

| Repository-relative path | Expected status | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `UnityValidationProject/Packages/manifest.json` | clean | `308` | `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd` |
| `UnityValidationProject/Packages/packages-lock.json` | clean | `1377` | `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913` |
| `UnityValidationProject/ProjectSettings/ProjectVersion.txt` | clean | `85` | `f450bbe4b5dc999988f56dff01af912886a765726ca3240d157357cff10517bf` |
| `UnityValidationProject/ProjectSettings/ProjectSettings.asset` | ` M` | `23135` | `9b1debf0b71ede99cbef5291d8aa9f5f3dac0a68c519ef60e2d70cf1638015e7` |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | clean | `378` | `8e18b1c820e9c09e16bbd1f1b7842e9fb3b0158a0921b0964e0b8fa12c6e2c01` |
| `com.rice.ai-codedb/package.json` | clean | `723` | `4932ecb76b699ae3d917d4fbbde9513691bc8b62f2a0f1e39bf4b3bf70d31957` |
| `com.rice.ai-codedb/Tests/Editor/Rice.AICodedb.Editor.Tests.asmdef` | clean | `511` | `5d9bf681a3f5f233f5dc25ec1acf55e30abf39bed2f6b7b429b0bf5663228c78` |

- The existing `ProjectSettings.asset` modification is protected Unity
  whitespace serialization state. Do not normalize, stage, revert, or include
  it in a commit.
- `UnityValidationProject/.codex/` and `UnityValidationProject/AIWork/` are
  pre-existing local untracked state outside this gate's snapshot. Do not read,
  clean, stage, or make acceptance claims about them.
- Preserve every unrelated modified and untracked path. A commit is not an
  execution prerequisite.

## Unity EditMode Request

```text
Project path: UnityValidationProject/
Purpose and criterion: one fresh full EditMode code-freeze pass; all discovered
  cases pass, the repository Package compiles and resolves locally, and tracked
  inputs remain unchanged
Exact command and test filter: one synchronous Unity Test Runner invocation;
  EditMode; no -testFilter and no -assemblyNames
Evidence class: full development EditMode code-freeze acceptance
Expected duration / maximum wait: 60-240 seconds / 300 seconds
Cleanup and ownership handoff: wait only on the exact returned Unity process;
  never terminate on timeout; on timeout return ownership to the human; after a
  normal exit require one passive check showing no matching Unity process
```

- EditMode authorization: `authorized`.

## Admission

- After explicit authorization, read this task once and execute one bounded
  read-only admission stage.
- Require the exact branch, HEAD, Package tree, S10 decision identity, seven
  validation-input identities, and declared statuses above.
- Query status only for `com.rice.ai-codedb/` and the seven declared validation
  inputs. Require the Package tree to have no tracked or untracked worktree
  entry and the validation inputs to contain only the declared
  `ProjectSettings.asset` modification.
- Require project version `2022.3.47f1`, revision `88c277b85d21`.
- Parse `manifest.json` and `packages-lock.json` structurally. Require the exact
  `file:../../com.rice.ai-codedb` dependency, one matching `testables` entry,
  and a local depth-zero lock with no dependencies.
- Require the test topology declared in Scope and no `-testFilter` or
  `-assemblyNames` in the planned arguments.
- Require both S11 artifact paths to be absent. Do not delete or overwrite an
  existing artifact.
- Resolve exactly one matching Unity editor from the current Unity Hub registry
  without starting Hub or persisting its machine path.
- Perform one point-in-time passive process check and require zero `Unity.exe`
  processes whose command line resolves to `UnityValidationProject/`.
- Any mismatch is `BLOCKED`; do not launch Unity, retry, repair, or investigate.

## Single Synchronous Unity Invocation

- Continue only after admission passes.
- Launch exactly once with `Start-Process -PassThru`, retain the returned
  process object, and wait only on it with `WaitForExit(300000)`.
- Arguments must be exactly:

```text
-batchmode
-projectPath <UnityValidationProject/>
-runTests
-testPlatform EditMode
-testResults <UnityValidationProject/TestResults-S11-full-editmode.xml>
-logFile <UnityValidationProject/Logs/S11-full-editmode-code-freeze.log>
```

- Do not add `-testFilter`, `-assemblyNames`, `-quit`, `-nographics`, another
  test argument, a background job, hidden process, Unity MCP, or Unity Hub.
- Full EditMode batch: `1/1`. Retry: `0/0`. Maximum wait: `300s`.
- Do not globally poll while waiting. On timeout record `TIMEOUT / BLOCKED`, do
  not parse incomplete artifacts, do not stop or signal Unity, and return
  process ownership to the human.

## Post-Run Evidence

- Continue only after the exact Unity process exits within `300s`.
- Parse the XML structurally exactly once and require:
  - root result `Passed`;
  - total is greater than zero and passed equals total;
  - failed, skipped, and inconclusive are all zero;
  - every test case belongs to the sole package Editor test assembly and a
    `Rice.AI.Codedb.Editor.Tests` fixture;
  - record actual suite, fixture, method, and case counts without imposing a
    precomputed count.
- Read the Unity log exactly once with bounded aggregate extraction and require:
  - exactly one local `com.rice.ai-codedb` Package record;
  - strip the literal `file:` prefix before normalizing the source path, then
    require source and location to equal the repository Package;
  - zero `error CS####` records and zero immediate compiler-error summaries;
  - zero fatal/abort/crash markers;
  - exactly one `Saving results to:` target equal to the S11 XML.
- Known compiler warnings may be counted and reported but do not fail this gate
  unless they prevent a clean compile or test execution.
- Recompute the exact Package tree/status and all seven validation input
  identities/statuses once. Any drift is `FAIL`; preserve it without repair.
- Perform one final point-in-time passive matching-Unity process check and
  require zero. Do not stop or control a remaining process.
- Do not reread artifacts, change patterns, investigate a failure, or retry.

## Result Contract

- Write this task's `RESULT.md` using repository-relative paths only.
- Record authorization, frozen admission, sanitized invocation shape, exact
  process exit/wall time, XML counts, Package/compile/fatal/completion results,
  pre/post identities/status, final process disposition, batch `1/1`, retry
  `0/0`, output ledger, actual profile, and `NOT RUN / DEFERRED` boundaries.
- Do not record machine, user-profile, executable, Package, temporary, or
  synthetic absolute paths.
- Do not claim manual UI, lifecycle/runtime, consumer, Codex Desktop,
  third-party Package-only, publication, or release acceptance.

## Test Plan

```text
L0 tests: reused from accepted S08d/S10; not rerun
Affected L1 tests: reused from accepted S10; not rerun separately
Additional tests: one full validation-project EditMode batch with no filter
Explicitly not run: PlayMode, cold start, Domain Reload, runtime-isolation,
  real Manager/Supervisor/Codex/MCP, consumer, third-party Package, performance,
  publication, deployment, and release acceptance
Test rationale: this is the separately requested roadmap code-freeze gate after
  focused convergence, not routine implementation regression
```

## Prohibited Actions

- Do not modify source, tests, Package/configuration, validation settings,
  workflow, task history, or existing local state.
- Do not create a project, use Unity MCP, run another test/filter/compiler/L0,
  retry, perform full repository status/diff, or broadly dump the log.
- Do not stop, signal, attach to, or otherwise control Unity or another process.
- Do not commit, push, stash, reset, clean, rebase, amend, publish, contact
  Verifier, or dispatch repair work.

## Stop Conditions

- Authorization is absent, the validation project is open, or any admission
  identity/status/topology/Package/editor/artifact/process condition differs.
- Unity times out or exits nonzero; XML/log is missing or invalid; any case
  fails, skips, or is inconclusive; a foreign test assembly appears; Package or
  compilation evidence fails; a tracked input drifts; or a matching process
  remains.
- Any retry, second process, alternate filter, investigation, edit, cleanup,
  termination, or scope expansion would be required.

## Definition Of Done

- One explicitly authorized full EditMode Unity process exits normally within
  `300s`.
- Every test discovered in the sole package Editor test assembly passes with no
  failure, skip, or inconclusive result.
- The repository Package resolves locally and compiles with zero errors.
- Package and validation tracked inputs remain at their frozen identities and
  no matching Unity process remains.

## Verification

- After Planner confirms a stable COMPLETE result, route this exact snapshot to
  `v0.3.verifier.deep` for one RELEASE-mode targeted read-only review.
- Verifier reuses the Coder XML/log/result and does not rerun Unity or another
  test. Any fix or rerun requires a new Planner/user decision.

## Handoff

Current task: cdb-v0.3-p0-s11-full-editmode-code-freeze
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.deep
Next action: execute the authorized one-shot full EditMode code-freeze gate and
return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: Verifier routing, any fix/rerun,
commit, and all later runtime or release gates remain separately gated

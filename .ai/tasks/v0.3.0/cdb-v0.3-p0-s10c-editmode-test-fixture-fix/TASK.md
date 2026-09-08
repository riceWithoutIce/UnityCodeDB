# Task: cdb-v0.3-p0-s10c-editmode-test-fixture-fix

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: v0.3.verifier.standard after Planner routing, if required
- Review mode: GUARDED
- Complexity: Medium
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10b-editmode-evidence-extraction`
  (`BLOCKED` after conclusively classifying four test-only failures).
- Human authorization: on 2026-09-07 the user approved this single-file,
  test-only FIX task.

## Objective

- Repair exactly four stale/broken test expectations exposed by the first S10
  Unity run, without changing production behavior or running Unity.
- Three Supervisor status tests must use valid, test-owned Unity project roots.
- The canonical/legacy pipe test must retain its independent exact legacy V1
  hash oracle, updated to the value implied by the current serialized root and
  runtime contract.

## Scope

- Only code file allowed:
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Only evidence file allowed:
  - this task's `RESULT.md`
- Allowed test methods:
  - `SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady`
  - `SupervisorProtocol_StatusHandshakeBlocksWrongProjectIdentity`
  - `SupervisorProtocol_ReadyWithoutProviderHandshakeIsBlocked`
  - `SupervisorProtocol_UsesCanonicalPipeIdentityAndRecognizesExactV1Handoff`
- All production files, other tests/methods, Package/validation-project
  configuration, S10/S10a/S10b records, workflow, and ignored Unity artifacts
  are protected and read only.
- Do not add a persistent fixture directory, Unity project, shared test helper,
  or production fallback.

## Frozen Input

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Initial test file SHA-256:
  `064477ab5068532e175faaf2e6a73e9349c5bd5f5c1fd3b465356ed99395892b`.
- Expected test-file scoped status: clean.
- S10b `RESULT.md`:
  - bytes: `11651`;
  - SHA-256:
    `95801bafce6b0bd84574f44db259888089a3119a4709809b39155d098e90b325`.
- Preserve the accepted five existing modified files and all unrelated
  task/worktree state. A commit is not an execution prerequisite.

## Required Changes

1. Valid primary roots:
   - In the three failing status/handshake methods, replace the fixed absent
     `CodeDB-Bridge-Fixture/FixtureProject` root with the test class's existing
     `_projectRoot`.
   - `SetUp` already creates `_projectRoot/Assets`, `_projectRoot/Packages`, and
     `_projectRoot/ProjectSettings`; `TearDown` already recursively removes the
     root. Do not duplicate those markers or change SetUp/TearDown.
2. Wrong-identity root:
   - In `SupervisorProtocol_StatusHandshakeBlocksWrongProjectIdentity`, place
     `wrongRoot` below `_projectRoot` using a stable test-only leaf such as
     `OtherProject`.
   - Create exactly its `Assets`, `Packages`, and `ProjectSettings` marker
     directories before building the wrong-identity response.
   - Rely on the existing recursive `_projectRoot` TearDown. Do not add a second
     cleanup path.
3. Legacy pipe oracle:
   - Independently compute SHA-256 over the exact test inputs
     `serializedProjectRoot + "\n" + serializedRuntime`, UTF-8 encoded, and take
     the first 20 lowercase hexadecimal characters with prefix
     `codedb-supervisor-`.
   - Confirm the result is
     `codedb-supervisor-928a30ffe326434cc56f` before editing.
   - Replace only the stale legacy expected literal
     `codedb-supervisor-f08a16463cf35b32cdab` with that confirmed value.
   - Keep the exact literal assertion as an independent compatibility oracle;
     do not replace it by asserting the production method against itself.

## Execution And Evidence

- Read this task once and perform one bounded admission check for HEAD, initial
  test hash/status, S10b result identity, and absence of a Unity process whose
  command line names `UnityValidationProject/`. Any mismatch returns `BLOCKED`.
- Use `apply_patch` and change only the four declared method bodies.
- Run one static L0 block that proves:
  - the three methods use `_projectRoot` as their primary root;
  - only the wrong-identity method creates the nested `OtherProject` markers;
  - no declared method retains `CodeDB-Bridge-Fixture`;
  - the old pipe literal is absent and the independently recomputed new literal
    occurs in the intended method;
  - SetUp/TearDown and all production files remain untouched.
- Run one scoped `git diff --check` for the single test file.
- Record the final test-file SHA-256, its scoped status, exact changed methods,
  independent hash computation, command exits/wall times, batch/retry ledger,
  actual profile, and deferred boundaries in `RESULT.md`.
- L0 batch: the single static block above, `1/1`.
- Retry: `0/0`.
- Affected L1/EditMode: `DEFERRED`; this task does not authorize Unity.
- Captured output: `16 KiB` per command and `64 KiB` aggregate. Normal command
  maximum: `60 seconds`.

## Prohibited Actions

- Do not start, stop, attach to, poll, or control Unity, Unity Hub, Unity MCP,
  Package Manager, Supervisor, or another process.
- Do not run EditMode, C# compilation, L0/L1 harnesses outside the declared
  static block, or any other test.
- Do not modify production behavior, weaken project-root validation, remove the
  legacy exact-hash oracle, broaden filters, or repair unrelated tests.
- Do not read broad logs/diffs, regenerate ignored artifacts, or update the
  frozen S10 task/result history.
- Do not commit, push, stash, reset, clean, rebase, amend, or contact Verifier.

## Stop Conditions

- Frozen input or Unity-process admission differs.
- The independently computed legacy value is not exactly the declared value.
- A fix requires another file/method, shared helper, production change, Unity,
  retry, or further investigation.
- Static L0 or scoped diff check fails, output truncates, or another independent
  blocker appears.

## Definition Of Done

- The three tests use valid, owned, automatically cleaned project roots.
- The wrong-root identity remains genuinely distinct and valid.
- The legacy V1 hash assertion remains independent and matches the current exact
  serialized inputs.
- Only the declared single test file changes and all changes remain uncommitted.
- Future corrected-filter Unity execution remains separately authorized.

## Handoff

Current task: cdb-v0.3-p0-s10c-editmode-test-fixture-fix
Current status: READY
Next notification: v0.3.coder.standard
Next action: implement the bounded single-file test-only correction and return
`RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: Planner review, any Verifier routing,
future corrected Unity/EditMode run, commit, or push remains separately gated

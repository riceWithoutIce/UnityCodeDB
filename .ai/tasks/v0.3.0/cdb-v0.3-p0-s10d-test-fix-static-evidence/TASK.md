# Task: cdb-v0.3-p0-s10d-test-fix-static-evidence

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: none for this evidence-only attempt
- Review mode: GUARDED
- Complexity: Low
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10c-editmode-test-fixture-fix`
  (`BLOCKED` only because its static-check command was malformed after the
  intended single-file test patch had been applied).
- Human authorization: on 2026-09-07 the user approved this independent,
  bounded static-evidence attempt and report-only path sanitization.

## Objective

- Close only the static-evidence gap left by S10c without changing its test
  patch or rerunning Unity.
- Prove that the current test-file delta is limited to the four S10c methods
  and that their exact intended fixture/oracle corrections are present.
- Sanitize the two synthetic absolute-path inputs printed in the S10c result
  while preserving its historical `BLOCKED` outcome and evidence meaning.

## Scope

- Read-only code input:
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- Allowed report-only update:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10c-editmode-test-fixture-fix/RESULT.md`
- Allowed new evidence output:
  - this task's `RESULT.md`
- The only code methods under review are:
  - `SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady`
  - `SupervisorProtocol_StatusHandshakeBlocksWrongProjectIdentity`
  - `SupervisorProtocol_ReadyWithoutProviderHandshakeIsBlocked`
  - `SupervisorProtocol_UsesCanonicalPipeIdentityAndRecognizesExactV1Handoff`
- All production code, test code, other task records, Package and validation
  project configuration, workflow files, and ignored Unity artifacts are
  protected and read only.

## Frozen Input

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Current patched test file:
  - bytes: `183864`;
  - SHA-256:
    `8048a39235dc115465cf972441135e328de81a6af3a96b126ce0f8f81b8c411f`;
  - expected scoped status: ` M`.
- S10c `TASK.md`:
  - bytes: `6836`;
  - SHA-256:
    `631648e7297779a64e63122ad31ebc935f15b8ab4c28848697ea5855eb79e306`.
- S10c `RESULT.md` before report-only sanitization:
  - bytes: `2834`;
  - SHA-256:
    `ea28a5318d39017fe329d09b24808e09d5f2bf06f5ae92ecfacf222ae8344c1e`;
  - expected scoped status: untracked.
- Preserve every existing unrelated modified or untracked path. A commit is
  not an execution prerequisite.

## Admission

- Read this task once and perform one bounded admission check for:
  - exact HEAD and the three frozen file identities above;
  - exact scoped status of the test file and S10c result;
  - absence of a `Unity.exe` process whose command line names the relative
    validation-project directory `UnityValidationProject/`.
- This is one point-in-time read-only process check, not polling. Do not start,
  stop, attach to, signal, or otherwise control any process.
- Any mismatch returns `BLOCKED` without editing or testing.

## Report-Only Sanitization

- Before replacing them, use the two exact inline synthetic inputs already
  recorded in S10c's `Independent Oracle Evidence` as in-memory inputs for one
  independent UTF-8 SHA-256 recomputation. Require the first 20 lowercase hex
  characters with prefix `codedb-supervisor-` to equal
  `codedb-supervisor-928a30ffe326434cc56f`.
- Do not print or copy either absolute input into commands, console output,
  S10d `RESULT.md`, or any new task record.
- In S10c `RESULT.md`, replace only those two inline path values with:
  - `<SYNTHETIC_PROJECT_ROOT>`
  - `<SYNTHETIC_SUPERVISOR_RUNTIME>`
- Preserve the computed pipe value, all outcomes, timings, status, and wording
  other than the minimum grammar needed for the placeholders.
- Record the S10c result pre/post byte count and SHA-256 in S10d `RESULT.md`.
  S10c remains historical `BLOCKED`; do not rewrite its routing footer.

## Static L0

- Run one corrected, self-contained static block. It must use raw strings plus
  direct string or regex APIs; do not pipe method text through `Select-String`.
- Read the current test file and the exact HEAD version of that same file only.
  Normalize newline form in memory, locate each declared method exactly once by
  its exact signature, and extract its complete balanced-brace method body.
- Replace the four extracted methods with stable sentinels in both versions and
  require all remaining file text to be identical. This proves SetUp,
  TearDown, every other test method, and file-level structure are unchanged.
- Require the current four method bodies to prove all of the following:
  - each of the three status/handshake methods uses `_projectRoot` as its
    primary root;
  - only the wrong-identity method derives `_projectRoot/OtherProject` and it
    creates exactly the `Assets`, `Packages`, and `ProjectSettings` marker
    directories for that nested root;
  - none of the four method bodies retains `CodeDB-Bridge-Fixture`;
  - the old legacy literal is absent from the file;
  - `codedb-supervisor-928a30ffe326434cc56f` occurs exactly once and only in
    the declared legacy-pipe method;
  - the independently recomputed value from the sanitization stage equals that
    exact literal.
- Require the baseline-to-current semantic deltas inside the four methods to
  be exactly the S10c fixture/oracle changes. Do not modify the test file when
  an assertion fails; return `BLOCKED` for Planner disposition.
- Static L0 budget: one block, `1/1`. Retry: `0/0`.

## Final Evidence

- After the static block passes, run exactly one single-file check:

```powershell
git diff --check -- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
```

- Record the final test-file byte count, SHA-256, scoped status, the four exact
  reviewed method names, static assertions, oracle result, command exits and
  wall times, batch/retry ledger, actual profile, and deferred boundaries in
  this task's `RESULT.md`.
- Do not include an absolute machine, repository, Unity executable, temporary,
  user-profile, or synthetic test path in the result. Use repository-relative
  paths and the declared placeholders only.
- Captured output: `16 KiB` per command and `64 KiB` aggregate. Normal command
  maximum: `60 seconds`.

## Prohibited Actions

- Do not modify any production or test code, including the current S10c patch.
- Do not start, stop, attach to, poll, or control Unity, Unity Hub, Unity MCP,
  Package Manager, Supervisor, or another process.
- Do not run EditMode, C# compilation, L0/L1 harnesses outside the declared
  static block, or any other test.
- Do not use a full diff/status, repository-wide search, broad log read, or
  repeated Git identity check.
- Do not commit, push, stash, reset, clean, rebase, amend, contact Verifier, or
  dispatch the future Unity run.

## Stop Conditions

- Frozen admission or Unity-process admission differs.
- Independent oracle recomputation differs.
- Sanitization would require changing evidence beyond the two declared values.
- The code patch differs from the four exact S10c method changes.
- Static L0 or scoped diff check fails, output truncates, a retry is needed, or
  another independent blocker appears.

## Definition Of Done

- S10c's report is path-sanitized without changing its historical result.
- The existing four-method test-only patch has deterministic static evidence
  and no change outside those methods.
- One single-file `git diff --check` passes and all identities are recorded.
- Unity/EditMode remains separately authorized and has not been started.
- Planner can create the corrected 39-method/69-case synchronous Unity run
  task without another static repair attempt.

## Handoff

Current task: cdb-v0.3-p0-s10d-test-fix-static-evidence
Current status: READY
Next notification: v0.3.coder.standard
Next action: execute the bounded report-sanitization and static-evidence attempt, then return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: the corrected synchronous Unity/EditMode run, any Verifier routing, commit, or push remains separately gated

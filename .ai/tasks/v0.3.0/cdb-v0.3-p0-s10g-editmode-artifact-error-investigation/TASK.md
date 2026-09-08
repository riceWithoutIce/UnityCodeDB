# Task: cdb-v0.3-p0-s10g-editmode-artifact-error-investigation

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AUTHORIZED
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: none for this investigation
- Review mode: GUARDED
- Complexity: Medium
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10f-corrected-focused-editmode`
  (`BLOCKED` after its exact Unity process exited with code `2`).
- Human authorization: on 2026-09-07 the user explicitly authorized this
  separate bounded artifact/error investigation.

## Objective

- Determine, from the immutable S10f XML and Unity log, why the sole corrected
  EditMode invocation returned exit code `2`.
- Establish the actual test counts/filter coverage, Package origin, compiler
  disposition, and first actionable error without starting Unity or changing
  the frozen snapshot.
- Complete the post-run identity and process checks that S10f correctly skipped
  at its abnormal-exit stop condition.

## Scope

- Read-only task inputs:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10f-corrected-focused-editmode/TASK.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10f-corrected-focused-editmode/RESULT.md`
- Read-only run artifacts:
  - `UnityValidationProject/TestResults-S10f-control-plane.xml`
  - `UnityValidationProject/Logs/S10f-control-plane-corrected-editmode.log`
- Read-only frozen identity inputs: the ten files listed below and S10e
  `RESULT.md`.
- Only allowed write:
  - this task's `RESULT.md`
- No source, test, task history, XML, log, Package file, validation-project
  setting, or ignored runtime state may be changed.

## Frozen Input

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- S10f task:
  - bytes: `18493`;
  - SHA-256:
    `e95fc74d0a2de361ece19074ce13af30ca170c3bee622411ea7edfba174d785b`.
- S10f result:
  - bytes: `6985`;
  - SHA-256:
    `11ca24094fe57de81e0a8c492046f877d8bbc118a1b0e6f081a93f7ba24e0ff1`.
- S10f XML:
  - bytes: `56814`;
  - SHA-256:
    `17c2ee3e3de5f9706ff7c495332cfaa57e217569d4a4cc8cde4c28d406d59b54`.
- S10f Unity log:
  - bytes: `93990`;
  - SHA-256:
    `e0090227db5666dfc985bc332cb137a7498a25e01897de501c1d804ab8834b25`.
- S10e result:
  - bytes: `4019`;
  - SHA-256:
    `b930d672dd02237ce452491e0f976af72fc4a02a8bb63ca232f17a7bb7f7c8ec`.
- Frozen tracked files:

| Repository-relative file | Bytes | SHA-256 |
| --- | ---: | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `249662` | `cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `733447` | `ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `183864` | `8048a39235dc115465cf972441135e328de81a6af3a96b126ce0f8f81b8c411f` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `156471` | `9d6b1c13e35562162b34d1e59c1d36bf28b7e1df7113793029a6e6dbc026898d` |
| `com.rice.ai-codedb/package.json` | `723` | `4932ecb76b699ae3d917d4fbbde9513691bc8b62f2a0f1e39bf4b3bf70d31957` |
| `UnityValidationProject/Packages/manifest.json` | `308` | `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd` |
| `UnityValidationProject/Packages/packages-lock.json` | `1377` | `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913` |
| `UnityValidationProject/ProjectSettings/ProjectVersion.txt` | `85` | `f450bbe4b5dc999988f56dff01af912886a765726ca3240d157357cff10517bf` |
| `UnityValidationProject/ProjectSettings/ProjectSettings.asset` | `23135` | `9b1debf0b71ede99cbef5291d8aa9f5f3dac0a68c519ef60e2d70cf1638015e7` |
| `UnityValidationProject/ProjectSettings/TagManager.asset` | `378` | `8e18b1c820e9c09e16bbd1f1b7842e9fb3b0158a0921b0964e0b8fa12c6e2c01` |

- Expected relevant scoped status remains exactly the seven modified paths
  recorded by S10f; do not infer acceptance of their content from this task.
- Preserve all unrelated modified and untracked paths. A commit is not an
  investigation prerequisite.

## Admission

- Read this task once and execute one bounded admission stage.
- Require exact HEAD, all five task/evidence identities, and all ten tracked
  file identities.
- Require zero `Unity.exe` processes whose command line resolves to the
  relative validation project `UnityValidationProject/`.
- Require the relevant scoped status to equal S10f's seven-path admission state
  using only the exact declared paths/directories. Do not use full status or
  any diff.
- This process check is one point-in-time passive read, not polling. Do not
  start, stop, attach to, signal, or control a process.
- Any mismatch returns `BLOCKED` without reading XML/log content.

## XML Evidence Stage

- Read the frozen XML bytes exactly once, verify its frozen SHA-256 in memory,
  and parse it with an XML parser. Do not use regex to parse XML.
- Read the frozen S10f task once and extract the exact `39` filter identities
  from its `Corrected Focused Filter` text block. Require `39` total and `39`
  distinct names.
- Select all `test-case` elements and structurally report:
  - XML root result and root counters when present;
  - actual case-node total and counts for `Passed`, `Failed`, `Skipped`,
    `Inconclusive`, and any unexpected result;
  - distinct matched filter-method count;
  - filter methods with no represented case;
  - cases that do not map to exactly one filter identity.
- A case maps only when its full name equals a filter identity or starts with
  that identity followed by the parameterized-case suffix. Ambiguous or
  unmatched mapping must be reported, not guessed.
- For every failed case, record its full repository test identity. Extract
  failure text through XML nodes (`failure/message` and
  `failure/stack-trace`) and reject missing or empty evidence.
- Record complete failure messages up to `2 KiB` per case and `12 KiB`
  aggregate. Record only the first relevant repository-relative stack frame.
  If evidence exceeds the cap, record the exact failure count, all identities,
  the first bounded records, and mark the remainder truncated without reread.
- Do not inspect source/test bodies in this task.

## Unity Log Evidence Stage

- Read the frozen log bytes exactly once after the XML stage, verify its frozen
  SHA-256 in memory, and perform only these in-memory checks:
  - repository Package resolution;
  - `error CS####` compiler entries and immediate compiler-error summaries;
  - Unity fatal/abort/crash markers;
  - test-run completion/failure markers relevant to exit code `2`.
- Parse `manifest.json` and `packages-lock.json` structurally once and resolve
  their `file:../../com.rice.ai-codedb` reference in memory.
- Require exactly one Package record shaped as:

```text
com.rice.ai-codedb@file:<resolved-source> (location: <resolved-location>)
```

- Normalize both captured paths and compare them with the repository Package
  directory. Do not emit their absolute values.
- Record compiler/fatal marker counts and only the first bounded actionable
  excerpt for each nonzero category. Sanitize machine paths to
  repository-relative paths or placeholders.
- Do not rerun the search with a replacement pattern. An ambiguous Package or
  error classification is a `BLOCKED` investigation result.

## Classification

- Classify exit code `2` using this evidence precedence:
  1. compiler or Unity fatal/abort evidence;
  2. complete XML with one or more failed/skipped/inconclusive cases;
  3. complete passing XML followed by a runner/cleanup error;
  4. incomplete or contradictory artifacts.
- State the narrow immediate cause and the next bounded action. Do not infer a
  product defect when evidence only identifies a test fixture, expectation,
  environment, runner, or infrastructure issue.
- `COMPLETE` means this investigation obtained an unambiguous disposition; it
  does not mean S10f passed. Use `BLOCKED` when evidence is incomplete,
  ambiguous, malformed, or identity has drifted.

## Post-Run Snapshot Evidence

- Within the same one-pass evidence batch, recompute the ten tracked file
  identities and S10e result identity once and require every value to match the
  frozen table.
- Run one relevant scoped status check over only the declared paths/directories
  and require the same seven modified paths as S10f admission.
- Perform one final point-in-time matching-Unity process check and require zero.
- Do not use full status, diff, history, blame, or a second hash/status/process
  pass. Preserve any drift and report it without repair.

## Execution Budget

- Read-only investigation batch: `1/1`, containing Admission, one XML parse,
  one log pass, classification, and one post-run snapshot check.
- Retry: `0/0`.
- No Unity, Unity MCP, EditMode, C# compile, Package Manager operation, L0/L1
  harness, or other test is authorized.
- Captured output: `16 KiB` per command and `64 KiB` aggregate. Keep raw content
  in its existing artifact and write only bounded evidence to `RESULT.md`.
- Normal command maximum: `60 seconds`.

## Result Contract

- Write this task's `RESULT.md` with:
  - stable identities and admission result;
  - XML result/counters, exact method/case coverage, and bounded failures;
  - Package/compile/fatal/test-completion log disposition;
  - explicit exit-code classification;
  - post-run identity/status/process result;
  - batch/retry/output ledger, actual profile, and all `NOT RUN` / `DEFERRED`
    boundaries;
  - the standard completion-routing footer.
- Use repository-relative paths only. Do not record an absolute machine,
  repository, Unity executable, Package, temporary, or user-profile path.

## Prohibited Actions

- Do not modify or delete any existing file other than creating this task's
  `RESULT.md`.
- Do not launch, stop, signal, attach to, poll, or control Unity, Unity Hub,
  Unity MCP, Supervisor, or any other business/runtime process.
- Do not run any test, compiler, Package operation, source probe, or alternate
  evidence command.
- Do not inspect source bodies, broaden logs/search, use full diff/status, or
  investigate beyond the frozen XML/log.
- Do not commit, push, stash, reset, clean, rebase, amend, contact Verifier, or
  dispatch a fix/rerun.

## Stop Conditions

- Admission identity/status differs or a matching Unity process exists.
- XML/log identity differs, parsing fails, output truncates, evidence is
  contradictory, or a second pass would be required.
- Post-run frozen identity/status differs or a matching Unity process exists.
- A conclusion requires source inspection, modification, Unity, another test,
  another artifact pass, or retry.

## Definition Of Done

- Exit code `2` has an evidence-backed immediate classification.
- Exact XML case/filter coverage and bounded failure details are recorded.
- Repository Package origin and compiler/fatal disposition are established.
- S10f's skipped post-run identity/status/process checks are completed once.
- Planner can choose a narrowly scoped FIX, corrected rerun, Verifier route, or
  stop without another broad investigation.

## Handoff

Current task: cdb-v0.3-p0-s10g-editmode-artifact-error-investigation
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.standard
Next action: execute the single bounded read-only artifact/error investigation and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: any source/test/config fix, Unity rerun, Verifier routing, manual Unity acceptance, commit, or push remains separately gated

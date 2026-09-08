# Task: cdb-v0.3-p0-s10i-editmode-artifact-classification

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
- Predecessor: `cdb-v0.3-p0-s10h-editmode-artifact-error-recapture`
  (`BLOCKED` by an invalid PowerShell object-equality assertion after admission
  and XML structure checks passed).
- Human authorization: on 2026-09-07 the user explicitly authorized this new
  bounded artifact-classification attempt.

## Objective

- Extract and persist the exact S10f XML result and failure evidence.
- Complete one bounded Unity-log classification for Package origin, compiler
  and fatal markers, and the immediate cause of Unity exit code `2`.
- Complete the frozen post-run snapshot evidence without starting Unity,
  modifying code, or rerunning any test.
- Eliminate S10h's invalid direct equality comparison between separately
  materialized PowerShell JSON objects.

## Scope

- Read-only inputs:
  - S10f `TASK.md` and `RESULT.md`;
  - S10h `TASK.md` and `RESULT.md`;
  - S10e `RESULT.md`;
  - `UnityValidationProject/TestResults-S10f-control-plane.xml`;
  - `UnityValidationProject/Logs/S10f-control-plane-corrected-editmode.log`;
  - `UnityValidationProject/Packages/manifest.json`;
  - `UnityValidationProject/Packages/packages-lock.json`;
  - `com.rice.ai-codedb/package.json`;
  - the remaining frozen tracked files listed below.
- Only allowed write:
  - this task's `RESULT.md`
- All existing files are protected and read only.

## Frozen Input

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.

| Evidence/task input | Bytes | SHA-256 |
| --- | ---: | --- |
| S10f `TASK.md` | `18493` | `e95fc74d0a2de361ece19074ce13af30ca170c3bee622411ea7edfba174d785b` |
| S10f `RESULT.md` | `6985` | `11ca24094fe57de81e0a8c492046f877d8bbc118a1b0e6f081a93f7ba24e0ff1` |
| S10h `TASK.md` | `11450` | `04b25cfaf235edf7d7fe28c57ff13e52e591cd8b29767d28f594f49da2e56507` |
| S10h `RESULT.md` | `4275` | `1df567c73b9fae68418593d2ecc37d7de741f8bd1b02384b44f8a0ad0e45a5f2` |
| S10e `RESULT.md` | `4019` | `b930d672dd02237ce452491e0f976af72fc4a02a8bb63ca232f17a7bb7f7c8ec` |
| S10f XML | `56814` | `17c2ee3e3de5f9706ff7c495332cfaa57e217569d4a4cc8cde4c28d406d59b54` |
| S10f Unity log | `93990` | `e0090227db5666dfc985bc332cb137a7498a25e01897de501c1d804ab8834b25` |

| Repository-relative tracked file | Bytes | SHA-256 |
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

## Admission

- Read this task once and perform one bounded admission stage.
- Require exact HEAD, all seven task/evidence identities, and all ten tracked
  file identities.
- Query only the ten tracked paths with NUL-delimited porcelain v1. Preserve
  the first two characters of every record; never trim leading whitespace.
- Parse each record as status code `Substring(0, 2)` and normalized path
  `Substring(3)`. Compare unordered path sets.
- Require exactly these seven ` M` records:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`;
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`;
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`;
  - `UnityValidationProject/Packages/manifest.json`;
  - `UnityValidationProject/Packages/packages-lock.json`;
  - `UnityValidationProject/ProjectSettings/ProjectSettings.asset`;
  - `UnityValidationProject/ProjectSettings/TagManager.asset`.
- Require no status record for the other three frozen tracked files.
- Perform one passive point-in-time check and require zero `Unity.exe`
  processes whose command line resolves to `UnityValidationProject/`.
- Do not poll or control a process. Any mismatch stops before artifact reads.

## XML Evidence

- Read the frozen XML bytes exactly once, verify its SHA-256 in memory, and
  parse it with `XmlDocument`.
- Read the frozen S10f task once and extract the exact `39` filter identities
  from its `Corrected Focused Filter` block. Require `39` total and distinct.
- Select all `test-case` nodes and persist, even if a later stage fails:
  - XML root result and all available root counters;
  - actual node counts for `Passed`, `Failed`, `Skipped`, `Inconclusive`, and
    unexpected results;
  - distinct matched filter count;
  - missing filter identities;
  - unmatched or ambiguously mapped case identities.
- A case maps only if its full name equals a filter identity or begins with that
  identity followed by its parameterized-case suffix.
- For every failed case, record the complete test identity and non-empty
  `failure/message` text. Record only the first repository-relative frame from
  `failure/stack-trace`.
- Bound each message to `2 KiB` and aggregate failure excerpts to `12 KiB`.
  Preserve exact counts and all failure identities if excerpts exceed the cap.
- Do not inspect source or test bodies.

## JSON Semantics

- Parse manifest, lock, and Package JSON once with structured JSON APIs.
- Require:
  - manifest dependency and lock version both exactly
    `file:../../com.rice.ai-codedb`;
  - manifest `testables` contains `com.rice.ai-codedb` exactly once;
  - lock `source` is `local` and integer `depth` is `0`;
  - the lock entry contains a non-null `dependencies` object with exactly zero
    properties;
  - Package JSON either has no `dependencies` property or has a non-null
    dependency object with exactly zero properties;
  - resolving the manifest file reference relative to `Packages/` equals the
    repository Package directory.
- Determine counts only with `@($object.PSObject.Properties).Count` after
  explicit null checks.
- Do not compare `PSCustomObject` instances, dependency objects, serialized
  JSON strings, or object references for equality. Empty and absent Package
  dependency declarations both mean zero declared dependencies here.

## Unity Log Evidence

- Read the frozen log bytes exactly once after XML/JSON, verify its SHA-256 in
  memory, then perform only these in-memory checks:
  - repository Package resolution;
  - `error CS####` and immediate compiler-error summary markers;
  - fatal, abort, or crash markers;
  - test completion/failure markers relevant to exit code `2`.
- Require exactly one line matching:

```text
com.rice.ai-codedb@file:<resolved-source> (location: <resolved-location>)
```

- Normalize both captured path fields and require both to equal the repository
  Package directory from JSON semantics. Do not emit absolute paths.
- Record marker counts and only the first bounded actionable excerpt for each
  nonzero category. Sanitize all machine paths.
- Do not reread the log or use a replacement pattern. Ambiguous evidence is
  `BLOCKED`.

## Exit Classification

- Classify S10f exit code `2` by this precedence:
  1. compiler or Unity fatal/abort evidence;
  2. complete XML containing failed, skipped, or inconclusive cases;
  3. complete passing XML followed by a runner/cleanup failure;
  4. incomplete or contradictory artifacts.
- State only the immediate evidence-backed cause and the next smallest action.
- `COMPLETE` means the investigation is conclusive, not that S10f passed.

## Frozen Snapshot Completion

- The Admission identity/status/process checks are the sole snapshot check for
  this read-only task. Do not repeat them after parsing because this task starts
  no external process and writes only its own result.
- In `RESULT.md`, explicitly state that S10f's frozen ten-file identity and
  seven-path status were observed after its Unity process had exited, and that
  zero matching Unity processes remained at S10i admission.
- If an artifact stage detects its own frozen hash mismatch, report `BLOCKED`;
  do not perform a second global snapshot pass.

## Budget And Result Contract

- Investigation batch: `1/1`, comprising Admission, one XML parse, one JSON
  parse set, one log read, and classification.
- Retry: `0/0`.
- Captured output: `16 KiB` per command and `64 KiB` aggregate. Normal command
  maximum: `60 seconds`.
- Only create this task's `RESULT.md`. Use repository-relative paths and
  sanitized bounded evidence.
- Persist completed stage evidence even if a later independent stage fails.
- Include identities, status/process disposition, XML counts/filter coverage,
  failures, JSON/Package/compile/fatal evidence, exit classification, ledger,
  actual profile, deferred boundaries, and the standard routing footer.

## Prohibited Actions

- Do not modify or delete any existing file.
- Do not launch or control Unity, Unity Hub, Unity MCP, Package Manager,
  Supervisor, or another runtime process.
- Do not run tests, compilation, source probes, alternate artifact reads, full
  status/diff, broad logs/search, or a retry.
- Do not inspect source/test bodies, commit, push, stash, reset, clean, rebase,
  amend, contact Verifier, or dispatch a fix/rerun.

## Stop Conditions

- Frozen admission or artifact identity differs.
- XML/JSON/log evidence is malformed, ambiguous, contradictory, or truncated.
- A second pass, alternate assertion, source read/edit, Unity action, broader
  command, or retry would be required.

## Definition Of Done

- Exact XML case/filter coverage and bounded failures are durably recorded.
- Package origin plus compiler/fatal disposition are established.
- Exit code `2` has a conclusive immediate classification.
- S10f's post-exit frozen snapshot and no-running-Unity evidence are recorded.
- Planner can choose the smallest FIX, rerun, Verifier route, or stop.

## Handoff

Current task: cdb-v0.3-p0-s10i-editmode-artifact-classification
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.standard
Next action: execute the single bounded read-only artifact classification and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: any source/test/config fix, Unity rerun, Verifier routing, manual Unity acceptance, commit, or push remains separately gated

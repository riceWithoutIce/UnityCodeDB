# Task: cdb-v0.3-p0-s10h-editmode-artifact-error-recapture

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
- Predecessor: `cdb-v0.3-p0-s10g-editmode-artifact-error-investigation`
  (`BLOCKED` by a false-negative scoped-status comparison before any artifact
  content was read).
- Human authorization: on 2026-09-07 the user explicitly authorized this new
  independent bounded investigation attempt.

## Objective

- Complete the S10f artifact/error investigation on the unchanged frozen XML,
  Unity log, and tracked snapshot.
- Replace only S10g's status-admission implementation with an already checked
  NUL-delimited porcelain parser that preserves the leading status column.
- Classify Unity exit code `2` without starting Unity, modifying files, or
  rerunning any test.

## Scope

- Read-only task/evidence inputs:
  - S10f `TASK.md` and `RESULT.md`;
  - S10g `TASK.md` and `RESULT.md`;
  - S10e `RESULT.md`;
  - `UnityValidationProject/TestResults-S10f-control-plane.xml`;
  - `UnityValidationProject/Logs/S10f-control-plane-corrected-editmode.log`;
  - the ten tracked files listed below.
- Only allowed write:
  - this task's `RESULT.md`
- All existing source, tests, task history, XML/log artifacts, Package files,
  validation-project settings, workflow files, and ignored runtime state are
  protected and read only.

## Frozen Input

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.

| Read-only input | Bytes | SHA-256 |
| --- | ---: | --- |
| S10f `TASK.md` | `18493` | `e95fc74d0a2de361ece19074ce13af30ca170c3bee622411ea7edfba174d785b` |
| S10f `RESULT.md` | `6985` | `11ca24094fe57de81e0a8c492046f877d8bbc118a1b0e6f081a93f7ba24e0ff1` |
| S10g `TASK.md` | `11577` | `530a5a20dc1969c547a994a9c25591c96b0c9df64cde30dc9804e4c4ac6594ee` |
| S10g `RESULT.md` | `2845` | `2deec28c2411b7583bd0a2ebc9fbca1d63e01bc16cf266852aca41fe342b59f7` |
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

## Exact Scoped Status Contract

- Query only the ten tracked paths above with:

```powershell
$rawParts = @(& git -c core.quotepath=false status --porcelain=v1 -z -- $paths)
if ($LASTEXITCODE -ne 0) { throw 'Scoped status command failed.' }
$raw = $rawParts -join "`n"
$records = @($raw -split "`0" | Where-Object { $_.Length -gt 0 })
$parsed = foreach ($record in $records) {
    if ($record.Length -lt 4) { throw 'Malformed porcelain record.' }
    [pscustomobject]@{
        Code = $record.Substring(0, 2)
        Path = $record.Substring(3).Replace('\', '/')
    }
}
```

- Do not call `Trim()`, `TrimStart()`, or otherwise remove the leading status
  character before reading `Substring(0, 2)`.
- Require exactly seven records, all with status code ` M`, for exactly:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`;
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`;
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`;
  - `UnityValidationProject/Packages/manifest.json`;
  - `UnityValidationProject/Packages/packages-lock.json`;
  - `UnityValidationProject/ProjectSettings/ProjectSettings.asset`;
  - `UnityValidationProject/ProjectSettings/TagManager.asset`.
- Require no record for the three clean paths:
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`;
  - `com.rice.ai-codedb/package.json`;
  - `UnityValidationProject/ProjectSettings/ProjectVersion.txt`.
- Compare normalized path sets, not formatted display lines or enumeration
  order. Planner has already checked this parser shape against the frozen
  snapshot and obtained `7 modified / 3 clean`.

## Admission

- Read this task once and perform one admission stage.
- Require exact HEAD, all seven evidence/task identities, and all ten tracked
  file identities.
- Apply the Exact Scoped Status Contract once.
- Perform one point-in-time passive check and require zero `Unity.exe`
  processes whose command line resolves to `UnityValidationProject/`.
- Do not poll, start, stop, attach to, signal, or control any process.
- Any mismatch returns `BLOCKED` before XML/log content is read.

## XML Evidence Stage

- Read the frozen XML bytes exactly once, verify the frozen hash in memory, and
  parse with an XML parser. Do not parse XML with regex.
- From the frozen S10f task, extract the exact `39` filter identities from its
  `Corrected Focused Filter` block. Require `39` names and `39` distinct.
- Select all `test-case` elements and report:
  - root result/counters when present;
  - actual node counts for `Passed`, `Failed`, `Skipped`, `Inconclusive`, and
    unexpected results;
  - distinct matched filter-method count;
  - filters with no represented case;
  - cases that do not map to exactly one filter.
- Map a case only when its full name equals a filter identity or begins with
  that identity followed by its parameterized-case suffix. Report ambiguity;
  do not guess.
- For every failed case, record its complete test identity. Read message and
  stack text only through `failure/message` and `failure/stack-trace` XML
  nodes, rejecting missing or empty evidence.
- Bound failure messages to `2 KiB` each and `12 KiB` aggregate. Record only
  the first repository-relative stack frame. If the cap is exceeded, preserve
  exact counts/all identities and mark the bounded remainder without reread.
- Do not inspect source or test bodies.

## Unity Log Evidence Stage

- Read the frozen log bytes exactly once after XML, verify its hash in memory,
  and perform only in-memory checks for:
  - repository Package resolution;
  - `error CS####` and immediate compiler-error summaries;
  - Unity fatal/abort/crash markers;
  - test completion/failure markers relevant to exit code `2`.
- Parse manifest and lock JSON once. Require their declared local Package
  reference, source, depth, dependencies, and resolved directory to retain the
  S10f admission contract.
- Require exactly one Package record shaped as:

```text
com.rice.ai-codedb@file:<resolved-source> (location: <resolved-location>)
```

- Normalize both captured values and compare them to the repository Package
  directory. Never print or persist their absolute values.
- Record marker counts and at most the first bounded actionable excerpt from
  each nonzero category. Sanitize every machine path.
- Do not use a replacement pattern or second log read. Ambiguous evidence is
  `BLOCKED`.

## Classification

- Classify exit code `2` by this precedence:
  1. compiler or Unity fatal/abort evidence;
  2. complete XML with failed/skipped/inconclusive cases;
  3. complete passing XML followed by a runner/cleanup error;
  4. incomplete or contradictory artifacts.
- State only the immediate evidence-backed cause and next bounded action.
- `COMPLETE` means this investigation is conclusive; it does not mean S10f
  passed. Do not infer a product defect when evidence identifies a test,
  fixture, environment, runner, or infrastructure issue.

## Post-Run Snapshot

- In the same investigation batch, recompute the ten tracked identities and
  S10e identity once and require the frozen values.
- Apply the same Exact Scoped Status Contract once after evidence extraction.
- Perform one final point-in-time process check and require zero matching Unity
  processes.
- Do not perform another hash/status/process pass, full status, diff, history,
  or blame. Preserve any drift without repair.

## Budget And Result Contract

- Investigation batch: `1/1`, comprising Admission, one XML parse, one log
  pass, classification, and one post-run snapshot stage.
- Retry: `0/0`.
- Captured output: `16 KiB` per command and `64 KiB` aggregate. Normal command
  maximum: `60 seconds`.
- Write only this task's `RESULT.md`, using repository-relative paths and
  sanitized bounded evidence.
- Include stable identities, XML counts/filter coverage, failure evidence,
  Package/compiler/fatal disposition, exit-code classification, post-run
  identity/status/process evidence, ledger, actual profile, deferred
  boundaries, and the standard routing footer.

## Prohibited Actions

- Do not modify or delete any existing file.
- Do not launch or control Unity, Unity Hub, Unity MCP, Package Manager,
  Supervisor, or another runtime process.
- Do not run tests, compilation, source probes, alternate evidence commands,
  full status/diff, or broad logs/search.
- Do not inspect source/test bodies, retry, commit, push, stash, reset, clean,
  rebase, amend, contact Verifier, or dispatch a fix/rerun.

## Stop Conditions

- Admission, structured status, artifact parsing, Package evidence, or
  post-run snapshot is mismatched, ambiguous, malformed, or truncated.
- A second pass, retry, source read/edit, Unity action, or broader command is
  required.

## Definition Of Done

- Unity exit code `2` has one unambiguous evidence-backed classification.
- Exact case/filter coverage and bounded failure details are recorded.
- Package origin and compiler/fatal disposition are established.
- S10f's deferred post-run identity/status/process checks are complete.
- Planner can select a narrow FIX, rerun, Verifier route, or stop.

## Handoff

Current task: cdb-v0.3-p0-s10h-editmode-artifact-error-recapture
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.standard
Next action: execute the single bounded read-only artifact/error recapture and return `RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: any source/test/config fix, Unity rerun, Verifier routing, manual Unity acceptance, commit, or push remains separately gated

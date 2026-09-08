# Result: cdb-v0.3-p0-s10i-editmode-artifact-classification

## Outcome

- Status: `COMPLETE`.
- Unity exit code `2` is conclusively classified as a completed EditMode run
  containing one failed test case. There is no compiler-error or Unity
  fatal/abort/crash evidence, and the repository Package origin is correct.
- This investigation does not classify the observed assertion mismatch as a
  production defect. The next smallest action is to review that single test
  expectation against the frozen protocol contract and, if confirmed stale,
  dispatch a one-method test-only fix.
- No existing file was modified. This task created only this `RESULT.md`; all
  pre-existing worktree state remains preserved and uncommitted.

## Admission And Frozen Snapshot

- Admission: `PASS`; wall time `0.493374s`.
- HEAD matched `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- All seven frozen task/evidence byte-count and SHA-256 identities matched:
  S10f TASK/RESULT, S10h TASK/RESULT, S10e RESULT, S10f XML, and S10f Unity
  log.
- All ten frozen tracked-file byte-count and SHA-256 identities matched.
- The NUL-delimited porcelain-v1 scoped status contained exactly seven ` M`
  records and three declared clean paths, matching the frozen unordered path
  set.
- These ten-file identities and seven-path status were observed after S10f's
  Unity process had exited. The passive S10i admission check found zero
  `Unity.exe` processes matching `UnityValidationProject/`.
- No process was started, stopped, attached, signaled, controlled, or polled.

## XML Evidence

- XML stage: `PASS`; wall time `0.148880s`; frozen SHA-256 matched before
  `XmlDocument` parsing.
- Root: `test-run`; result `Failed(Child)`.
- Root attributes/counters:
  - `id=2`, `testcasecount=69`, `total=69`;
  - `passed=68`, `failed=1`, `inconclusive=0`, `skipped=0`, `asserts=0`;
  - `engine-version=3.5.0.0`, `clr-version=4.0.30319.42000`;
  - `start-time=2026-09-07 10:06:51Z`,
    `end-time=2026-09-07 10:06:56Z`, `duration=4.940922`.
- Actual `test-case` nodes: 69 total; 68 `Passed`, 1 `Failed`, 0 `Skipped`,
  0 `Inconclusive`, and 0 unexpected results.
- Corrected filter: 39 identities, 39 distinct, 39 distinctly represented.
  Missing filters: none. Unmatched cases: none. Ambiguous cases: none.
- XML completeness: `PASS`; root total, actual nodes, and result-category sum
  all equal 69.

### Failed Case

- Identity:
  `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady`
- Complete failure message, 26 UTF-8 bytes, not truncated:

```text
Expected: 2
But was:  3
```

- First repository-relative stack frame:
  `at Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady () [0x000fa] in com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs:538`

## JSON And Package Evidence

- Structured JSON stage: `PASS`; wall time `0.036117s`.
- Manifest dependency and lock version both equal
  `file:../../com.rice.ai-codedb`.
- Manifest `testables`: 1 total; `com.rice.ai-codedb` occurs exactly once.
- Lock entry: `source=local`, integer `depth=0`, non-null dependency object
  with 0 properties.
- Package JSON has no `dependencies` property, representing 0 declared
  dependencies. No JSON object/reference equality comparison was used.
- Resolving the manifest reference relative to `UnityValidationProject/Packages/`
  equals the repository Package directory.
- Unity log Package record: exactly 1; both captured source and location
  normalize to the repository Package directory. Absolute values were not
  persisted.

## Log And Exit Classification

- Unity log stage: `PASS`; wall time `0.031727s`; frozen SHA-256 matched and
  the log was read exactly once.
- `error CS####` entries: 0. Immediate compiler-error summaries: 0.
- Unity fatal/abort/crash markers: 0.
- Bounded test-marker matches: 1; first excerpt:
  `DisplayProgressbar: Test Runner`.
- Exit code: `2`.
- Classification: `COMPLETE_XML_NONPASSING_CASES`.
- Immediate cause: the complete 69-case XML contains the single failed test
  recorded above. Under the frozen precedence, that failure explains exit code
  `2`; no higher-priority compiler or Unity fatal/abort evidence exists.

## Ledger And Boundaries

- Investigation batch: `1/1`; `PASS`; command exit `0`; tool-observed wall
  time `0.872565s`; internal batch wall time `0.742495s`; output complete and
  untruncated.
- Retry: `0/0`; no alternate assertion, artifact reread, or replacement search
  was used.
- Actual execution profile: `v0.3.coder.standard`; model/effort:
  `gpt-5.6-sol` / `high`.
- `NOT RUN`: Unity, Unity Hub, Unity MCP, EditMode rerun, C# compilation,
  Package Manager operations, other tests, source/test method-body reads,
  broader logs/search/status/diff, Verifier, commit, and push.
- `DEFERRED`: disposition of the single assertion expectation, any test-only
  fix, corrected Unity rerun, runtime acceptance, Verifier routing, and release
  evidence.

Current task: cdb-v0.3-p0-s10i-editmode-artifact-classification
Current status: COMPLETE
Next notification: UnityCodeDB v0.3 Planner
Next action: review the single failed expectation against the frozen protocol contract and choose the smallest test-only disposition before any separately authorized Unity rerun
Human decision or authorization required: any source/test/config fix, Unity rerun, Verifier routing, manual Unity acceptance, commit, or push remains separately gated

# Task: cdb-v0.3-p0-s10a-editmode-evidence-investigation

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: none for this evidence-only investigation
- Review mode: GUARDED
- Complexity: High
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10-control-plane-focused-editmode`
  (`BLOCKED` by its sole authorized run).
- Human authorization: on 2026-09-07 the user explicitly authorized this
  separate bounded read-only evidence investigation.

## Objective

- Explain the exact boundary of the S10 result without starting Unity or
  changing the snapshot.
- Deliver four items to Planner:
  1. the identities and bounded messages for exactly four failed Lifecycle
     cases;
  2. Package-resolution and compiler disposition from the existing Unity log;
  3. the correct declaring-class names for the 17 omitted Manager methods;
  4. a corrected foreground synchronous Windows launch/wait contract for a
     separately authorized future run.

## Frozen Inputs

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Read-only predecessor records:
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10-control-plane-focused-editmode/TASK.md`
  - `.ai/tasks/v0.3.0/cdb-v0.3-p0-s10-control-plane-focused-editmode/RESULT.md`
- Read-only ignored evidence:
  - `UnityValidationProject/TestResults-S10-control-plane.xml`
  - `UnityValidationProject/Logs/S10-control-plane-focused-editmode.log`
- Frozen artifact identities:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| predecessor `RESULT.md` | 7073 | `9a60754e604a3e34db03271ad5843c3f506e55c1ac71f084b9341a9955dcd2ca` |
| NUnit XML | 29297 | `e826513cc4abfba4cae1e54b30f2a3d518fedb034ef596a1a8c386f9f30136f9` |
| Unity log | 94435 | `f3d8c00640502b4dcd32d30daa9288c9ec425ed2a76fd2a8ea69e530236fc9d7` |

- Expected post-S10 relevant scoped status remains exactly:
  - modified `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`;
  - modified
    `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`;
  - modified `UnityValidationProject/Packages/manifest.json`;
  - modified `UnityValidationProject/Packages/packages-lock.json`;
  - modified `UnityValidationProject/ProjectSettings/TagManager.asset`;
  - no modified Package Editor source or Editor test source.
- The seven expected content hashes remain those frozen in the predecessor
  `TASK.md`. Recompute them once; do not recompute the S08 diff identity.

## Known Planner Findings To Confirm

- The 17 omitted filters use the nonexistent type name
  `Rice.AI.Codedb.Editor.Tests.AICodedbManagerUiTests`. That is a source filename,
  not a declared test class. The file contains multiple actual test classes.
- The PowerShell call operator returned after about `0.388s`, while the XML
  records a test duration of about `3.423s` and completed later. Treat the
  original invocation wall time as launcher-return time, not synchronous Unity
  completion evidence.
- No matching validation-project Unity process remained when Planner performed
  the post-result safety check.
- These are execution-contract findings. They do not explain or dismiss the
  four Lifecycle failures.

## Allowed Reads

- Parse the NUnit XML with an XML parser. Read only:
  - root run attributes and timing;
  - the 26 returned test-case identities/results;
  - failure message and the first relevant in-repository stack location for the
    four failed cases;
  - suite/type metadata needed to bind method names.
- Read only the four failed test method bodies and their directly named local
  production call sites when necessary to classify a failure. Do not perform a
  repository-wide search or general source audit.
- In `AICodedbManagerUiTests.cs`, map only the 17 methods named by the S10 task
  to their enclosing declared classes. Confirm each corrected fully-qualified
  method exists exactly once and preserve the expected 43-case Manager total.
- Search the frozen Unity log only for:
  - the bounded local-package registration/resolution record for
    `com.rice.ai-codedb`;
  - C# compiler errors matching `error CS` and Unity's immediate compiler-error
    summary markers;
  - process/test start and finish timestamps needed to characterize the
    asynchronous launcher return.
- Do not copy a machine path into the report. Replace the resolved repository
  and Package locations with `UnityValidationProject/` and
  `com.rice.ai-codedb/` respectively.

## Execution

- Perform one admission check for HEAD and the three exact artifact hashes and
  lengths. Any mismatch returns `BLOCKED`; do not continue on a replacement
  artifact.
- Parse the XML once and emit a compact four-row failure table. Limit each
  failure message plus stack excerpt to `2 KiB`; total failure evidence must
  remain below `8 KiB`.
- Perform one bounded Manager declaring-class mapping pass. Return the corrected
  17 fully-qualified names and totals: Manager methods `17`, Manager cases `43`,
  combined methods `39`, combined cases `69`.
- Perform one targeted Unity-log pass. Report counts plus at most the first
  relevant compiler error if any; do not return unrelated log content.
- Perform one post-run snapshot check for the seven content hashes and relevant
  scoped status. Do not use `git diff`, full status, blame, or history.
- Specify a future Windows invocation contract that actually waits for the
  exact launched Unity process. It must:
  - run in the foreground with no hidden window, background job, detached task,
    Unity MCP, or alternate endpoint;
  - retain the same `-batchmode`, project, platform, result, log, and corrected
    exact filter arguments;
  - wait on the launched process identity for at most `300 seconds`;
  - capture the real process exit code and elapsed time;
  - on timeout, return ownership to the human without terminating or signalling
    Unity;
  - avoid claiming completion merely because a GUI launcher call returned.
- The investigation may recommend one of: product/test FIX, corrected-filter
  rerun, environment repair, or further bounded evidence. It must not perform
  the recommendation.
- Write only this task's `RESULT.md`. Use repository-relative paths and append
  the standard completion-routing footer.

## Prohibited Actions

- Do not start, stop, attach to, signal, poll, or otherwise control Unity,
  Unity Hub, Unity MCP, or any business/runtime process.
- Do not rerun EditMode, compilation, Package Manager, L0/L1, or any other test.
- Do not edit production, test, Package, validation-project, workflow, S10
  records, XML, or Unity log files.
- Do not delete or regenerate ignored artifacts.
- Do not investigate passed cases, unrelated warnings, theoretical hardening,
  broader regressions, or release behavior.
- Do not commit, push, stash, reset, clean, rebase, amend, or contact Verifier.

## Budgets And Stop Conditions

- Read/analysis batch: `1/1`; retry: `0/0`.
- Normal command maximum: `60 seconds`.
- Captured output: `16 KiB` per command and `64 KiB` aggregate.
- Stop after the first artifact/identity drift, parse ambiguity, output
  truncation, unrelated second blocker, or need for Unity/source modification.
- Do not turn this evidence investigation into an S10 retry.

## Definition Of Done

- All four failed case identities and bounded failure reasons are preserved.
- Package resolution and C# compile disposition are established from the
  existing log without rerunning Unity.
- The 17 corrected Manager fully-qualified names and 39-method/69-case total are
  mechanically validated.
- Post-run seven hashes and relevant scoped status are recorded.
- The launcher-return defect and corrected synchronous ownership contract are
  explicit, with no claim that a future run has been authorized.

## Handoff

Current task: cdb-v0.3-p0-s10a-editmode-evidence-investigation
Current status: READY
Next notification: v0.3.coder.deep
Next action: perform the bounded read-only investigation and return `RESULT.md`
to UnityCodeDB v0.3 Planner
Human decision or authorization required: after Planner review, any source/test
FIX, corrected Unity rerun, Verifier routing, commit, or push remains separately
gated

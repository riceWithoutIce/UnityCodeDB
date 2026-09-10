# Checkpoint 01: S11 Existing-Artifact Failure Classification

Status: COMPLETE

## Authorization

- On 2026-09-08 the user approved a simplified continuation of the existing
  S11 task instead of creating S11a.
- Continue under task ID `cdb-v0.3-p0-s11-full-editmode-code-freeze` with the
  same `v0.3.coder.deep` owner.
- This checkpoint authorizes read-only classification of the artifacts already
  produced by S11 and completion of the skipped post-run state checks.
- It does not authorize another Unity invocation, a code/configuration edit,
  process termination, Verifier routing, commit, or push.

## Frozen Inputs

- HEAD: `9aada838e26879810a4f79760273ca66340ebf12`.
- S11 `TASK.md`: `13069` bytes, SHA-256
  `b80acd6762b3406545bae4f9f83ba39c761a0c8099d3a929371a2fef03604bd4`.
- S11 `RESULT.md`: `7180` bytes, SHA-256
  `f68242439d70831e755eb85f6b279304ca4f9230f6d8bce7fcf8b27254e8e9bd`.
- S11 XML: `UnityValidationProject/TestResults-S11-full-editmode.xml`,
  `344100` bytes, SHA-256
  `21892e5fc9352e6d236b2fd28352a2c9d3e53a004f63249802c87ddd507ad81c`.
- S11 log: `UnityValidationProject/Logs/S11-full-editmode-code-freeze.log`,
  `81960` bytes, SHA-256
  `e259f5a4f37a0b3298787cc3a232c94ac8cf57eabcbac051a8840375a9bd60c6`.
- Existing S11 execution evidence: one unfiltered full EditMode Unity process,
  exact-object wait, exit `2`, wall time `36.0479897s`, batch `1/1`, Unity retry
  `0/0`.
- Preserve every existing modified and untracked path. Do not read or clean
  `UnityValidationProject/.codex/` or `UnityValidationProject/AIWork/`.

## Outcome

Determine one of these terminal classifications from the frozen artifacts:

- `TEST_FAILURE_CLASSIFIED`: XML is valid and identifies one or more failed,
  skipped, or inconclusive tests.
- `INFRASTRUCTURE_FAILURE_CLASSIFIED`: Package resolution, compilation, Unity
  fatal/crash, or result persistence explains the nonzero exit.
- `EXIT_CONTRADICTION_CLASSIFIED`: XML is fully passing but another bounded log
  fact explains or preserves the exit-code contradiction.
- `BLOCKED`: only when a frozen input drifted, an artifact is missing/corrupt,
  or the bounded evidence cannot support any classification.

A completed failing test run is `COMPLETE / TEST_FAILURE_CLASSIFIED`, not a
workflow `BLOCKED` state. Do not repair the failure in this checkpoint.

## Read-Only Evidence Work

1. Confirm HEAD and the four frozen input identities once.
2. Parse the XML structurally. Record root result; total, passed, failed,
   skipped, and inconclusive counts; and actual assembly, fixture, method, and
   case counts.
3. Group non-passing cases by normalized first failure-message line. Report at
   most 10 groups, at most 3 fully qualified representative cases per group,
   and at most 500 characters of message plus 3 stack lines per group. Do not
   dump the XML.
4. Read the log once and aggregate only:
   - the single local `com.rice.ai-codedb` Package record;
   - Package source/location after removing the literal `file:` prefix before
     filesystem normalization;
   - `error CS####`, immediate compiler-error summaries, and compiler warnings;
   - fatal/abort/crash markers;
   - the `Saving results to:` target and any bounded line directly explaining
     exit `2` when XML does not already classify it.
5. Complete the skipped post-run snapshot checks once:
   - HEAD and `HEAD:com.rice.ai-codedb` tree remain the S11 frozen identities;
   - `com.rice.ai-codedb/` has no worktree entry;
   - among S11's seven validation inputs, only the pre-existing
     ` M UnityValidationProject/ProjectSettings/ProjectSettings.asset` remains,
     with every byte/hash matching the S11 task table;
   - one passive point-in-time query finds zero `Unity.exe` processes whose
     command line resolves to `UnityValidationProject/`.

Use structured XML/path APIs and semantic fields. Do not depend on Markdown
heading extraction or a generic log-completion phrase.

## Simplified Budget

- This is one outcome-oriented read-only continuation, not a chain of command
  tasks.
- Active time limit: `20 minutes`.
- Captured output: at most `16 KiB` per command and `32 KiB` total.
- Artifact parsing: one initial attempt plus at most one corrected parser
  attempt when the first attempt fails because of parser construction, XPath,
  escaping, or path-normalization code.
- A corrected parser attempt must record the concrete parser error and
  correction in this checkpoint. It is not a Unity/test retry and needs no new
  human authorization.
- Evidence disagreement is not a reason to retry until it passes. Preserve and
  classify the disagreement.
- Unity invocation budget remains exhausted at `1/1`; Unity retry remains
  `0/0`.

## Prohibited Actions

- Do not start Unity, Unity Hub, Unity MCP, EditMode, a compiler, Package
  Manager, Supervisor, Node, or a product PowerShell probe.
- Do not modify source, tests, Package/configuration, validation settings,
  S11 `TASK.md`, S11 `RESULT.md`, XML, log, or other prior records.
- Do not perform full repository status/diff, broad repository search, broad
  artifact output, or repeated post-state/process checks.
- Do not stop or control a process, fix code, create another task, contact
  Verifier, commit, push, stash, reset, clean, rebase, or amend.

## Result Contract

- Update this checkpoint's top `Status` to `COMPLETE` or `BLOCKED` and append a
  concise `Evidence Result` section.
- Record the terminal classification, XML counts, bounded failure groups,
  Package/compiler/fatal/result-save facts, post-run snapshot/process result,
  parser-attempt ledger, output/time ledger, and explicit deferred boundaries.
- Use repository-relative paths only; never persist machine or user-profile
  paths.
- If a real failure is classified, name the smallest likely repair surface but
  do not inspect beyond direct evidence or propose unrelated hardening.

## Handoff

Current task: cdb-v0.3-p0-s11-full-editmode-code-freeze
Current checkpoint: CHECKPOINT-01
Current status: READY_AUTHORIZED
Next notification: v0.3.coder.deep
Next action: classify the existing S11 artifacts and complete post-run evidence
without rerunning Unity, then return this checkpoint to UnityCodeDB v0.3 Planner
Human decision or authorization required: any source/test/configuration fix,
Unity rerun, Verifier routing, commit, push, or later roadmap gate remains
separately gated

## Evidence Result

### Terminal Classification

- Checkpoint result: `COMPLETE / TEST_FAILURE_CLASSIFIED`.
- The frozen S11 XML is valid and records a completed full EditMode run with real test failures. Unity exit `2` is therefore classified by the non-passing test result, not as an unclassified workflow or infrastructure failure.
- Existing Unity execution evidence remains: one unfiltered full EditMode invocation, exact-process wait, exit `2`, wall time `36.0479897s`, batch `1/1`, Unity retry `0/0`.

### Frozen Inputs

- HEAD matched `9aada838e26879810a4f79760273ca66340ebf12`.
- S11 `TASK.md`: `13069` bytes, SHA-256 `b80acd6762b3406545bae4f9f83ba39c761a0c8099d3a929371a2fef03604bd4`.
- S11 `RESULT.md`: `7180` bytes, SHA-256 `f68242439d70831e755eb85f6b279304ca4f9230f6d8bce7fcf8b27254e8e9bd`.
- `UnityValidationProject/TestResults-S11-full-editmode.xml`: `344100` bytes, SHA-256 `21892e5fc9352e6d236b2fd28352a2c9d3e53a004f63249802c87ddd507ad81c`.
- `UnityValidationProject/Logs/S11-full-editmode-code-freeze.log`: `81960` bytes, SHA-256 `e259f5a4f37a0b3298787cc3a232c94ac8cf57eabcbac051a8840375a9bd60c6`.
- All four frozen artifact identities matched before parsing; no replacement artifact was accepted.

### XML Result

| Field | Result |
| --- | ---: |
| Root result | `Failed(Child)` |
| Total cases | `461` |
| Passed | `449` |
| Failed | `12` |
| Skipped | `0` |
| Inconclusive | `0` |
| Assemblies | `1` (`Rice.AICodedb.Editor.Tests`) |
| Fixtures | `16` |
| Distinct methods | `270` |
| Duration | `21.8527167s` |

The 12 failures form five normalized groups. Temporary project identities were replaced with `<temporary-project>` when grouping and reporting.

| Count | Normalized first message line | Representative cases, at most 3 | Bounded stack evidence |
| ---: | --- | --- | --- |
| `5` | `Expected: Invalid` | `AICodedbEditorLifecycleTests.HostGenerationStore_RejectsDuplicateCurrentPointerProperty`; `AICodedbEditorLifecycleTests.HostGenerationStore_RejectsWrongTokenTypeInCurrentPointer`; `AICodedbHostUpgradeStatusStoreTests.Parse_FailsClosedForInvalidCleanupState("UNKNOWN")` | `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs:1490` |
| `1` | `Expected string length 42 but was 36. Strings differ at index 3.` | `AICodedbHostPayloadStatusBuilderTests.Build_MapsLayeredMissingPrerequisiteClearly` | `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs:2115` |
| `1` | `Expected string length 58 but was 31. Strings differ at index 1.` | `AICodedbHostPayloadStatusBuilderTests.Build_MapsLayeredNeedsAttentionInsteadOfUnrecognizedResult` | `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs:2096` |
| `1` | `Expected: greater than or equal to 0` | `AICodedbEditorLifecycleTests.HostGenerationStore_RejectsDuplicateGenerationManifestProperty` | `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs:4041`; caller `:1525` |
| `4` | `Unity project marker is missing: <temporary-project>/Packages/manifest.json` | `MissingPrerequisite_RealEditorStatusPathRechecksOnceWithoutEarlyProjectWrites("PROVIDER_INVALID")`; same method with `"PROVIDER_MISSING"`; same method with `"PROVIDER_HASH_MISMATCH"` | `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs:1175` |

- The fifth group also includes the same parameterized method with `"NODE_MISSING"`.
- The bounded evidence proves real test failures but does not determine which expectation or production behavior is authoritative for every group. No passed case or unrelated source was inspected.

### Package, Compiler, Fatal, And Result Persistence

- Local `com.rice.ai-codedb` Package records: exactly `1`.
- After removing the literal `file:` prefix and normalizing in memory, both Package source and location equaled the repository `com.rice.ai-codedb/` directory.
- `error CS####` records: `0`.
- Immediate compiler-error summaries: `0`.
- Compiler warnings matching `warning CS####`: `0`.
- Fatal/abort/crash markers: `0`.
- `Saving results to:` records: exactly `1`; its normalized target equaled `UnityValidationProject/TestResults-S11-full-editmode.xml`.
- Conclusion: Package resolution, compilation, fatal-state, and result persistence do not explain exit `2`; the XML test failures do.

### Post-Run Snapshot And Process

- HEAD remained `9aada838e26879810a4f79760273ca66340ebf12`.
- `HEAD:com.rice.ai-codedb` remained tree `69d2c3e970813c44b7f458bdc686da7fac354b52`.
- `com.rice.ai-codedb/` had no scoped worktree entry.
- All seven validation inputs retained the exact S11 bytes and SHA-256 identities.
- The only scoped validation input status remained the pre-existing ` M UnityValidationProject/ProjectSettings/ProjectSettings.asset`.
- The single passive point-in-time check found `0` matching `Unity.exe` processes for `UnityValidationProject/`.
- `UnityValidationProject/.codex/` and `UnityValidationProject/AIWork/` were not read or cleaned.

### Parser, Time, And Output Ledger

- Artifact parser attempt `1/2`: exit `1`, wall time `0.2960773s`. PowerShell rejected `Sort-Object Count -Descending,Name` with `Missing argument in parameter list`; the command failed during parser construction before reading frozen artifacts.
- Corrected parser attempt `2/2`: exit `0`, wall time `0.8871947s`. The correction used explicit Count-descending and Name-ascending property expressions; no evidence criterion or artifact changed.
- This parser correction was not a Unity/test retry. Unity invocation remained `1/1`; Unity retry remained `0/0`.
- Corrected attempt captured `1311` tool-reported tokens, below `16 KiB`; aggregate parser output remained below `32 KiB`. No truncation occurred.
- Active checkpoint execution remained below the `20 minute` limit.

### Smallest Next Action And Deferred Boundaries

- Smallest likely repair surface: the directly implicated Editor test/fixture expectations in `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` and `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`, together with only their directly asserted Package Editor parsers/status builders where evidence shows an expectation may be stale. The four missing-marker parameter cases first require a valid disposable Unity-project fixture contract.
- Next role/action: return to `UnityCodeDB v0.3 Planner` to group these five failure families into the smallest separately frozen test/product FIX task. Any source/test/configuration change and any Unity rerun require new authorization.
- `NOT RUN`: Unity, Unity Hub, Unity MCP, EditMode, compiler, Package Manager, Supervisor, Node, product PowerShell probe, or any other test/process invocation.
- `NOT RUN`: full repository status/diff, broad search, passed-case investigation, source fix, cleanup, commit, push, or Verifier routing.
- `DEFERRED`: repair validation, a fresh full EditMode rerun, manual Unity UI, runtime/consumer/Codex Desktop/third-party Package-only, publication, and release gates.
- Verifier contact: not performed.

Current task: `cdb-v0.3-p0-s11-full-editmode-code-freeze`  
Current checkpoint: `CHECKPOINT-01`  
Current status: `COMPLETE / TEST_FAILURE_CLASSIFIED`  
Next notification: `UnityCodeDB v0.3 Planner`  
Next action: freeze the minimum repair task for the five bounded failure groups, then separately decide whether to authorize a full EditMode rerun.  
Human decision or authorization required: any FIX, Unity rerun, Verifier routing, commit, push, or later roadmap gate remains separately gated.

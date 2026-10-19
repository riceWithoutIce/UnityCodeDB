# S36 Coder Result

## Outcome And Stable Snapshot

- Status: COMPLETE / SOURCE_IMPLEMENTED_WITH_EXECUTION_LIMITS.
- Role: authorized task-scoped Coder; no child delegation.
- Model/reasoning: inherited parent session with no override. Exact underlying
  model identifier and reasoning setting are not reliably exposed to this child;
  no catalog default or inferred model is reported as actual runtime metadata.
- Baseline HEAD: `d4a097d20af598ca760163867a3394ff5efb116d`.
- Both allowlisted C# files were clean at admission. Only those files and this
  result were edited by Coder. Unrelated working-tree changes were preserved.
- Source/test writes stopped at this snapshot; no commit was created.

| File | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `07594a7b236465e26ca91ab2832b9c82d694728a64a3004dac5144d2c0f691a6` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `2d635f6e858184d11ad28e88c3afd7031ea2945e0c2e766d69ba92f4bf95cc8b` |

Narrow diff against HEAD: production `+38/-13`; tests `+294/-0`.

## Implementation

The no-backend-reconcile branch now calls
`RefreshCachedLifecycleRemovalPreflight` instead of passing the old command
through `RememberLifecycleProductStatus` again.

The helper reads the complete lifecycle cache tuple under its existing lock,
including revision, paired snapshot and terminal failure. It only proceeds for
an existing Ready projection without a retained terminal failure. It calls the
existing preflight projection and keeps its cancellation/context checks. Under
the cache lock, it publishes only when the captured revision remains current
and cancellation has not been requested. The only assigned payload field is
the preflight-updated product status; the cache revision advances once.

The original command, paired Supervisor snapshot, observation identity/revision,
observation timestamp, has-status flag and terminal-failure field remain in
place. No current Bridge snapshot is read to reinterpret the old command.
A newer Ready, authoritative Uninstalled, terminal failure or invalidation
therefore defeats a pending preflight-only publication.

Strict `BindProductStatusToSupervisorObservation` matching, terminal admission,
full-observation behavior and Manager freshness policy are unchanged. An old
Ready tuple remains old; the existing Manager display boundary still rejects
expired evidence. This change does not establish fresh operational readiness.

## Focused Evidence

- PASS, L0 whitespace: `git diff --check --` restricted to both allowlisted
  files, exit 0.
- PASS, C#9 syntax only: reused the existing generic parser, without changing
  or rebuilding it:

  ```text
  dotnet .artifacts/tests/s29-optional-flat/syntax/bin/Debug/net10.0/Syntax.dll com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
  [CS_SYNTAX_ONLY] files=2 errors=0; consumer_execution=NOT_RUN
  ```

- PASS, bounded static review: production diff is limited to the preflight-only
  caller and helper. Existing strict-binding and coherent-Uninstalled tests are
  untouched. Direct Manager consumption uses the cached paired snapshot and
  `ObservedAtUtc`; display expiry precedes its unchanged-revision gate. Existing
  stale/foreign/incomplete and shared-freshness tests were read, not executed.
- NUnit/Unity semantic execution: DEFERRED. The inspected historical semantic
  harness depends on an old removed acceptance project and rewrites lifecycle
  worker behavior, so it is not a valid unchanged harness for this claim. No new
  simulated Unity or machine environment was built. Syntax PASS does not imply
  successful compilation, NUnit PASS or real idle stability.

Added `AICodedbPreflightRefreshTests`, containing four focused test methods and
10 parameterized scenarios:

1. A command paired with observation A remains paired when Bridge advances to
   B, for available/unavailable preflight and expired observation age. The same
   test confirms true revision mismatch rejection and unchanged freshness.
2. A newer Uninstalled, Ready, terminal-failure or invalidated publication wins
   over the pending old preflight update.
3. A retained terminal failure prevents preflight-only clearing even when a
   Ready projection is present.
4. Cancellation or lost context prevents publication.

The tests use the existing owned `AICodedbTestWorkspace`, seed an unexpired
preflight cache to avoid executing materializer commands, and restore lifecycle
fields (including cache revision), preflight cache and Bridge snapshot in
`Dispose` under their corresponding locks. No test was run in this task.

## Limits And Completion Routing

No Unity/EditMode/MCP/BatchMode, lifecycle action, live RPC/probe, process
control, export, project-reference switch, network operation or commit ran.
Exported package, Unity projects, receipts and runtime state were not modified.
S35 Uninstall/reinstall remains paused; this result does not accept source or
close the human idle-regression gate.

- Current task: `cdb-v0.3-p0-s36-preflight-refresh-observation-coherence`.
- Current status: COMPLETE / SOURCE_IMPLEMENTED_WITH_EXECUTION_LIMITS;
  stable Coder snapshot ready for admission.
- Next notification: current parent Planner.
- Next action: admit the hashes and narrow claims, then use the already
  authorized independent read-only Verifier for one targeted review.
- Human decision or authorization required: none for that frozen review;
  subsequent source acceptance, delivery and human Unity gates remain separate.

## Approved NUnit Compatibility Repair — 2026-10-19

The original source result above is historical evidence. Subsequent human
compilation on the exact delivered artifact failed with CS0246 because the
actual NUnit dependency does not expose `NonParallelizableAttribute`; the
earlier syntax-only PASS did not establish referenced-type compatibility.
The failure and failed artifact remain recorded in DELIVERY-RESULT.md.

User explicitly approved the single-attribute fix and sequential reuse of
Coder -> read-only Verifier. Repair baseline was clean HEAD
`4291e80795681ad0057518b5ecd6c04e3c9ca92b`, with both original C# hashes matched
before this repair. Inherited model/reasoning metadata remains as reported
above; no override, dependency update or delegation occurred.

Only source change: replace `[NonParallelizable]` with
`[Parallelizable(ParallelScope.None)]` on `AICodedbPreflightRefreshTests`.
The exact diff is `+1/-1` in the test file. Its using directive already imports
`NUnit.Framework`, and the unchanged test assembly definition declares
`optionalUnityReferences: TestAssemblies`. All ten scenarios, fixtures and
production bytes remain unchanged.

Read-only metadata inspection loaded the actual consumer assembly from
`.artifacts/unity-projects/s35/Library/PackageCache/com.unity.ext.nunit@1.0.6/net35/unity-custom/nunit.framework.dll`:

- SHA-256 matched
  `e388e140954de12970384331d1730e95b4613ef53c3326b6f8fa0fffdbc9314f`.
- Assembly version: `3.5.0.0`.
- `NonParallelizableAttribute` absent: true.
- `ParallelizableAttribute(ParallelScope)` public constructor present: true.
- `ParallelScope.None` enum member present: true; numeric value `0`.

The replacement names the supported constructor with scope None, retaining
explicit nonparallel scheduling intent without removing the decoration or
upgrading NUnit. This metadata check validates the replacement API surface;
it does not execute NUnit scheduling or establish successful Unity compilation.

Checks completed:

- PASS: narrow diff/numstat showed exactly the one replacement above; no other
  source hunks. The production file is clean and retains its admitted hash.
- PASS: `git diff --check -- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`,
  exit 0.
- PASS, syntax only: reused the unchanged existing C#9 parser on the changed
  test file, exit 0:

  ```text
  dotnet .artifacts/tests/s29-optional-flat/syntax/bin/Debug/net10.0/Syntax.dll com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
  [CS_SYNTAX_ONLY] files=1 errors=0; consumer_execution=NOT_RUN
  ```

Stable repair snapshot (source writes stopped):

| File | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` (unchanged) | `07594a7b236465e26ca91ab2832b9c82d694728a64a3004dac5144d2c0f691a6` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `3a2d379799924e62bd482b28f369d61f2e0915ea06d0d4482b979e5e67b87d2f` |

Semantic compilation, NUnit execution and human Unity/idle acceptance remain
DEFERRED. No Unity launch, lifecycle action, live operation, process control,
new harness, package extraction edit, commit/export/reference switch or network
operation ran during this repair. Existing failed delivery and protected state
were preserved. The previous delivery authorization was not reused.

- Current task: S36 direct NUnit compatibility repair, iteration 1/2.
- Current status: COMPLETE / ONE_ATTRIBUTE_FIX_WITH_EXECUTION_LIMITS.
- Next notification: current parent Planner.
- Next action: admit this stable single-line snapshot and reuse the already
  authorized read-only Verifier for original CS0246 compatibility finding,
  nonparallel intent and unchanged test/production review only.
- Human decision or authorization required: none for the approved narrow review;
  source disposition and new delivery/human execution retain separate gates.

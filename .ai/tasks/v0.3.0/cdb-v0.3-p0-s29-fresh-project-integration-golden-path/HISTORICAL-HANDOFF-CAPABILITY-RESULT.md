# S29 historical-handoff capability Coder result

## E-04 authorized retained-entry fixture correction — PASS 2026-10-13

Status: E04_SOURCE_AND_ORIGINAL_TEST_COMPILE_PASS / PATH_PROVENANCE_PASS /
STABLE_TERMINAL. Only the approved fixed-path samples in
`Tests~/test-codedb-retained-entry-routing.ps1:181` changed. The invalid
question-mark and NUL samples now derive from the owned `$fixtureContainer`
(`Join-Path $fixtureContainer 'bad?root'` and `Join-Path $fixtureContainer
'bad'` plus NUL), while relative, drive-relative, root-relative, UNC and
different-root rejection cases remain. No rejection was removed and no
production path comparator or other fixed path changed.

Exclusive immutable overlay:
`.artifacts/tests/s29-historical-handoff-capability/evidence-e04-a1/com.rice.ai-codedb`.
The changed script worktree/overlay SHA256 is
`719661e6d0dc409de4c889019e8686819564ed3810f20b78c5784fb1d5bd2eac`.
All seven scoped files (the six earlier files plus E-03 ManagerUi test) equal
the E-04 overlay; no dirty Payload was consumed. HEAD remains
`9eac17cfdb741f89d33a4b7c2ddf6261abcb9566`, index is empty, and diff check
passed. No HH-01 rerun, Unity/MCP/CUA/BatchMode, real action, commit, export or
reference switch occurred.

Evidence commands, each a single initial attempt in distinct E-04 logs:

- Script parse: `test-codedb-retained-entry-routing.ps1` and
  `compile-tests-exact.ps1` both parsed with zero PowerShell syntax errors.
- `powershell -NoProfile -ExecutionPolicy Bypass -File E04/compile-tests-exact.ps1`:
  Unity 2022.3.62f3 NetCoreRuntime/dotnet + DotNetSdkRoslyn/csc, original S29
  Bee Editor.Tests response with all four test source bindings directed to E-04,
  prior exact Editor.ref DLL. Exit 0 / errors 0. Log
  `E04/logs/tests-compile-a1.log`; DLL/ref DLL/rsp retained.
- `powershell -NoProfile -ExecutionPolicy Bypass -File E04/com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`:
  exit 0, `[PASS] Package path provenance`, and helper/caller binding counts
  passed. Log `E04/logs/path-provenance-a1.log`. This closes the prior E-03
  `ManagerUiTests.cs:1845` and retained-entry `:181` path-gate failures.

E-04 artifact hashes:

`c709f50583ca42c3c9b5bd42c6eaa6a94618156678caa41359e2f5ab3c46395c`
`Rice.AICodedb.Editor.Tests.dll`; `5e46162a0f8b5df4e2418c5f21b130fdde1a02b7cc2feb81cdd283328968e186`
`Rice.AICodedb.Editor.Tests.ref.dll`; `f9d11387647dc9a41750601fab2a23db6316cc3c880316a4784283aa5fdef33f`
`Rice.AICodedb.Editor.Tests.rsp`; `04e870e815b8a54dc8ccad1ee31fedb29ce0ee96daf641b320b90a3bd475e592`
`compile-tests-exact.ps1`; `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b`
`logs/tests-compile-a1.log`; `ad19e1143c6d924e8b003fe779679a8bb4eeff171f54028de7b53062293e5fd8`
`logs/path-provenance-a1.log`.

This completes the authorized E-04 evidence. No Verifier was contacted; parent
may now admit the stable snapshot for read-only review. Unity EditMode execution
of the workspace-owned tests remains a separate human gate.

## E-03 authorized ManagerUi fixture correction — stable stop 2026-10-13

Status: E03_SOURCE_AND_ORIGINAL_TEST_COMPILE_PASS / PATH_PROVENANCE_NOT_PASS /
PURE_COMPARATOR_METHOD_NOT_RUN. This is the later E-03 disposition, retaining
all evidence-a1 and earlier records below without overwriting or replaying them.

Only `Tests/Editor/AICodedbManagerUiTests.cs` method
`RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot` changed.
Its base root now derives from `AICodedbTestWorkspace.ProjectRoot` within the
existing workspace.Run owner. Both platform branches use that runtime-owned
root. Windows same-root, case, slash/backslash and trailing separator acceptance
remains bidirectional; different-root, relative, drive-relative, root-relative,
double-colon, question-mark, incomplete-UNC and empty-string refusals remain
bidirectional. Unix same-root/trailing separator acceptance and case/relative
refusals remain. No production AICodedbPaths comparator or other fixed path was
modified. This is fixture portability, not weakened product identity admission.

Exclusive Package input:
`.artifacts/tests/s29-historical-handoff-capability/evidence-e03-a1/com.rice.ai-codedb`.
It copies the prior immutable evidence-a1 Package and overlays only this named
test file. Its SHA256 is
`f3236e62297e19b1d7cf569dbe25580133a06ef4a4d0f826ef0ebcdbc54457a8`, equal to
the worktree. Original ManagerUi baseline
`d599a155ae69548927779c37a6336bc1d0f23495df14716797a4f71fbacdd44c` remains in
evidence-a1. The six previous authorized source files match new overlay bytes;
dirty Payload was not consumed. HEAD remains 9eac17cfdb741f89d33a4b7c2ddf6261abcb9566;
staged index is empty. Scoped diff whitespace check passed.

Actual commands and new distinct logs (E03 denotes evidence-e03-a1 above):

- `powershell -NoProfile -ExecutionPolicy Bypass -File E03/compile-tests-exact.ps1`.
  Script parse: zero errors. Uses original S29 Bee
  `Library/Bee/artifacts/1900b0aEDbg.dag/Rice.AICodedb.Editor.Tests.rsp`, rebinds
  all four complete delivered test source files to E03 Package, and references
  prior exact original-byte `evidence-a1/Rice.AICodedb.Editor.ref.dll` (production
  is unchanged). Unity 2022.3.62f3 NetCoreRuntime/dotnet.exe +
  DotNetSdkRoslyn/csc.dll compile without source/AST/assertion rewrites.
  Exit 0 / errors 0 / no diagnostics. Original affected test assembly PASS;
  log `E03/logs/tests-compile-a1.log`; generated rsp/DLL/ref DLL retained.
- `powershell -NoProfile -ExecutionPolicy Bypass -File E03/com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`.
  Actual PowerShell exit 1 / NOT PASS; log
  `E03/logs/path-provenance-a1.log`. The gate passed the corrected ManagerUi
  file and next refused the unchanged outside-allowlist
  `Tests~/test-codedb-retained-entry-routing.ps1:181`: invalid-input fixtures
  contain `G:/bad?root` and `G:/bad` + NUL + `root`. These are the next literal
  provenance violation, not an E-03 runtime failure. No other fixed path was
  modified, bypassed, enumerated for a repair campaign or retried.

The pure comparator test method itself is NOT RUN in this envelope. The original
workspace owner constructor requires actual Editor main-thread
UnityEngine.UnitySynchronizationContext and Application.dataPath; running the
method without native workspace construction would require replacing/skipping
the owner or fabricating context. Parent expressly directed retaining that
original owner and reporting NOT RUN. No alternate caller, rewritten assertion,
fake owner, Unity launch or native call was used. Human exact method remains:
`AICodedbProjectSettingsTests.RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot`.
The earlier workspace-based
`RemovalIntegrationArguments_RequireHandoff` likewise remains a human Unity gate.

E-03 ledger: one initial affected original-byte compile, one initial provenance
attempt, zero corrections/retries and zero comparator execution attempts.
Historical attempts are not reset. HH-01's prior 22 cases/producer were not rerun.
Stable terminal is returned to parent for disposition/admission; no Verifier
contact, further source work, real action, process control, cleanup, commit,
export, reference switch, push or publication was performed. Package path gate
still lacks PASS and S29/release remain PARTIAL.

## Authorized evidence continuation — stable terminal 2026-10-13

Status: HH01_COMPILE_AND_EXACT_SEAM_PASS / PACKAGE_PATH_GATE_NOT_PASS.
This section supersedes the old evidence-stop status only for the explicitly
renewed envelope. The old failed runs, exhausted ledger, invalid harness outputs
and overwritten-log limitation below remain historical facts, not valid PASS.
No production change was made during this continuation. Two approved fixture
corrections were made: HistoricalProbeOnly now includes its existing upstream
prerequisite CURRENT marker before the unchanged production writer output;
RemovalIntegrationArguments_RequireHandoff uses AICodedbTestWorkspace.ProjectRoot
instead of G:/fixture/project, preserving the missing-handoff refusal assertion.

Exclusive immutable Package input: `.artifacts/tests/s29-historical-handoff-capability/evidence-a1/com.rice.ai-codedb`.
It was copied from `.artifacts/s29-upgrade-callsite-fix-34b3a65/review/com.rice.ai-codedb`
and overlaid only with the six authorized source/test files. All six terminal
worktree/overlay SHA256 pairs match. Accepted Package Payload hashes and both
S29 reference-file hashes still match their recorded bindings. Dirty worktree
Payload was not consumed. HEAD remains 9eac17cfdb741f89d33a4b7c2ddf6261abcb9566;
staged index is empty. No commit/export/reference switch occurred.

### Actual renewed commands and results

All paths below are relative to the repository; owned evidence root is
`.artifacts/tests/s29-historical-handoff-capability/evidence-a1` (E).

- PS syntax: changed fixture script and the exclusive compile/run scripts parsed
  with zero errors.
- Producer command: `powershell -NoProfile -ExecutionPolicy Bypass -File E/com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 -HistoricalProbeOnly -CanonicalPayloadRoot E/com.rice.ai-codedb/Payload~ -RetainedFixtureRoot E/probe`.
  Exit 0; `E/logs/ps-producer.log`; `E/probe/probe-output.txt` starts with
  `[PRODUCT_LAYER PREREQUISITE] CURRENT` and preserves real writer controlled
  removal/reinstall wording. Synthetic selected instance/machine prerequisite
  boundaries remain explicit; no live Probe or Provider was executed.
- Path command: `powershell -NoProfile -ExecutionPolicy Bypass -File E/com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`.
  Exit 1 / NOT PASS; `E/logs/path-provenance.log`. The newly authorized fixed
  preflight path is removed, but the next unchanged accepted-Package violation
  is Tests/Editor/AICodedbManagerUiTests.cs:1845 (`G:/RiceProject/Retained`, with
  adjacent fixed literals). This file is outside the continuation edit allowlist;
  it was not modified, skipped or retried. This is a remaining Package gate gap.
- Original-byte compilation: `powershell -NoProfile -ExecutionPolicy Bypass -File E/compile-exact.ps1`.
  Unity 2022.3.62f3 NetCoreRuntime/dotnet.exe + DotNetSdkRoslyn/csc.dll consume the
  existing S29 Bee `1900b0aEDbg.dag/Rice.AICodedb.Editor[.Tests].rsp`; original
  source bindings are redirected to E Package without rewriting source bytes.
  Complete delivered Editor (30 files) and Tests (4 files, including affected
  lifecycle/preflight and existing workspace/ManagerUi) compile exit=0/errors=0.
  Tests reference E's freshly compiled Editor.ref.dll. Logs are
  `E/logs/Rice.AICodedb.Editor.log` (3 existing warnings) and
  `E/logs/Rice.AICodedb.Editor.Tests.log` (no diagnostics). Generated rsp/DLL
  bindings are retained in E. This is not Unity import or EditMode execution.
- Exact seam: `powershell -NoProfile -ExecutionPolicy Bypass -File E/run-seam.ps1`.
  The exclusive Roslyn extractor is built by installed .NET SDK 10.0.300. It
  slices original AST member spans without any AST/member/body rewrite and
  re-parses/checks exact text equality for all 18 extracted declarations.
  `E/logs/exact-ast-binding.txt` binds source/member hashes and reports
  EXACT_MEMBER_TEXT_EQUALITY PASS. Extracted production members are
  TryRouteHistoricalRemoval, its four pure prerequisite dependencies,
  ResolveCurrentInstanceConvergencePlan's three overloads and two supporting
  enums. Extracted tests are the original four HistoricalRemovalRouting methods,
  HistoricalIntegration/Migration/Selection helpers and Result, with original
  NUnit assertions/test data untouched. No SetUp/TearDown/native initializer
  is extracted; no initializer is rewritten or replaced.
  Unity csc compiles `E/Seam.cs` + exclusive `E/Runner.cs` to
  `Rice.AICodedb.Editor.Tests.exe`, referencing the just compiled original-byte
  `E/Rice.AICodedb.Editor.dll` and original Unity package nunit.framework.dll.
  Expected CS0436 warnings select the local extracted lifecycle type; product
  parser, status/identity types, command result and authenticated-preflight reader
  remain the original Editor DLL, not stubs. Compilation exit 0.
  Unity's standalone MonoBleedingEdge/bin/mono.exe executes this exe with
  RICE_HH01_PROBE_OUTPUT=E/probe/probe-output.txt. Original 22 cases PASS (4 cold/
  repeated/lease, 9 guards, 8 refusal/cancellation, 1 real producer-byte reader).
  Logs: `E/logs/extractor-a1.log`, `seam-compile-a1.log`, `seam-run-a1.log`.
  No NativeBoundaryRewrite, old retained runner, assertion adapter or native shim
  was used. This tests the worker's directly called pure seam and production
  reader, not actual worker IO, lease deletion, IPC, Provider or Unity lifecycle.

### Ledger and remaining limits

Original C# attempts 1+2+3 remain exhausted/invalid as documented below.
This expressly authorized renewed envelope used one producer attempt, one path
attempt, one full compile and one exact seam execution, all at distinct new log
paths. No failure replay, retry or additional scenario was run.

RemovalIntegrationArguments_RequireHandoff was fully compiled and statically
checked, but NOT EXECUTED: its existing owner requires the actual Editor main
thread UnitySynchronizationContext and Application.dataPath. Unity/native
automation is forbidden in this envelope; those requirements were not replaced
with a fabricated context or path. Record it as a remaining human Unity gate,
not PASS. PathProvenance remains NOT PASS on the unchanged ManagerUi fixture.

HH-01 source is stable for parent's independent evidence review. S29/release
remain PARTIAL; Unity/NUnit runner, live Probe/Provider, real Install/Upgrade/
Remove, operational process control and delivery gates were not run. Deferred
RequireReady wording was untouched. Old artifacts/logs were preserved.

## HH-01 correction — stable stop, evidence NOT ACCEPTABLE

Date: 2026-10-13. Status: SOURCE_IMPLEMENTED / REQUIRED_EVIDENCE_NOT_PASS.
Parent explicitly stopped further L1 attempts after the execution deviations
below. No independent review or new source acceptance is claimed.

Production correction is limited to Lifecycle.cs: RunReconcileWorker now calls
TryRouteHistoricalRemoval immediately after the existing migration/current
selection readers, before lease admission, operational-start enablement,
Supervisor Probe and the backend no-reconcile return. This directly consumed
seam only intercepts Installed + TrustedPrevious + usable migration. It blocks
operational admission/deletes the owned tracked lease, reads the existing
DryRun prerequisite, rejects unavailable/failed/timed-out/ambiguous evidence,
preserves MissingPrerequisite, and invokes existing WithRemovalPreflight only
after trustworthy current prerequisite. Cancellation/stale worker context stops
publication. Current/missing/v1/invalid/uninstalled and blocked migration fall
through to their original guards; no bootstrap permit is loosened. The former
late TrustedPrevious branch was removed.

LifecycleTests adds directly consumed seam cases for cold/repeated/existing
lease, removal preflight pass/refusal, current/missing/invalid/v1/uninstalled/
invalid-integration/invalid/transient/obsolete migration, missing/absent/
duplicate/timed-out/failed prerequisites, cancel-before/after and stale context,
plus actual product-reader input. The PS test adds HistoricalProbeOnly, extracting
unchanged production Write-InstanceProductStatus from the immutable overlay;
selected identity and machine prerequisite are explicit synthetic boundaries.
No production schema/authentication/writer change was made.

Owned input overlay:
`.artifacts/tests/s29-historical-handoff-capability/hh01-a2/com.rice.ai-codedb`,
copied from the exact accepted upgrade-callsite-fix-34b3a65 Package, with only
the five accepted/task-authorized source/test files overlaid. Dirty Payload and
OwnerIdentity fixtures were not consumed. Payload/generation identities remain
unchanged. The overlay was used by the PS producer and correct provenance run.

### Actual commands, limits and deviations

- Path gate first mistakenly invoked the working-tree
  `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`;
  then invoked the same command with the exact owned overlay script path.
  Both exited 1. The exact accepted Package's unchanged
  `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs:43`
  contains `G:/fixture/project`, refused by the path gate. Logs:
  `hh01-a2/logs/path-provenance.log` and `path-provenance-overlay.log`.
  Gate is NOT PASS. No exemption, deletion or source edit was made to this
  outside-allowlist file. The two runs are recorded, not claimed as a valid
  retry or compliant single-overlay attempt.
- PS L1 corrected attempt 2 command:
  `powershell -NoProfile -ExecutionPolicy Bypass -File <overlay>/Tests~/test-codedb-host-payload-materializer.ps1 -HistoricalProbeOnly -CanonicalPayloadRoot <overlay>/Payload~ -RetainedFixtureRoot <owned-run>/probe`.
  Exit 0, log `hh01-a2/logs/ps-l1-a2.log`; actual output bytes are
  `hh01-a2/probe/probe-output.txt`. Writer emits NeedsAttention and controlled
  removal/reinstall with no automatic-handoff promise. However, the fixture
  sets MachinePrerequisiteStatus non-null and does not emit its upstream
  prerequisite marker. Production writer thus correctly omits a duplicate
  marker; downstream real C# product-reader prerequisite becomes Unknown.
  Full producer-to-reader gate is NOT PASS. No further PS repair was made.
- `dotnet build .artifacts/tests/s29-retained-disposition-fix/compile/Focused.csproj --no-restore --nologo`
  built the old harness project only (exit 0, `semantic-hh01.log`). This is NOT
  the required actual Unity/Bee full-byte source compilation.
- Coder then mistakenly edited/reused the old
  `.artifacts/tests/s29-retained-disposition-fix/compile/Runner.cs` and invoked
  `dotnet run --project <old>/Focused.csproj --no-restore` with
  RICE_HH01_PROBE_OUTPUT bound to owned PS output. This old harness uses
  NativeBoundaryRewrite (static initializer/Unity/Assert adaptation), contrary
  to the promised exact AST pure-method extraction. The first run stopped at
  the old RetainedDispositionOnly ignored prerequisite. Coder then changed
  only runner selection to HH-01 names and ran again; original-source Roslyn
  reported SEMANTIC errors=0, and 21 routing cases printed PASS, but the real
  product-reader case failed Unknown != Current. These outputs are invalid
  auxiliary information, NOT acceptable HH-01 L1 PASS.
- Both mistaken C# executions wrote `hh01-a2/logs/mono-seam-hh01.log`; the
  second overwrote the first raw log. The first raw failure is not recoverable
  from that file; its observed RetainedDispositionOnly exception is preserved
  here and in the tool/session output. Do not claim immutable attempt evidence.
- Runner.cs was restored to the exact text read before edits. Restored SHA256:
  `a8a477ca85d56fc58626f463bd1ee7b9e45482f3d1f2e1ca77571b40b5b076fb`.
  No historical logs were cleaned. Running the old harness also changed its
  generated build outputs, so no blanket protected-artifact preservation claim
  is made. This was an execution-boundary deviation, not authorized task work.
- A new `hh01-a2/compile-exact.ps1` was prepared but NOT EXECUTED when parent
  stopped the work. Full-byte Unity csc/Bee compile and permitted exact AST
  Mono adaptation are therefore NOT RUN. No claimed Mono PASS is admissible.

Attempt accounting does not reset: original C# initial 1 + mistaken corrected
executions 2 and 3 consume all three available execution attempts. Both
corrected executions were semantic runner invocations despite invalid harness
selection/adaptation. Prior `dotnet build` is a harness-build check, not a
semantic test attempt. PS initial GenerationAlignment 1 + HistoricalProbe
attempt 2 consumed; no third run. PathProvenance ran twice and remains failed.
No further test/diagnostic/iteration is authorized after the parent stop.

### Required next disposition / prerequisites

The source snapshot is stable for a bounded read-only HH-01 review. Completion
cannot claim the frozen evidence envelope: it needs explicit renewed evidence
authority/budget for full-byte Unity csc/Bee compilation, a new immutable
exact-AST pure-method harness without native/assertion rewrites, and causally
corrected upstream prerequisite output for producer -> real reader. It also
needs a separate allowlist decision for the pre-existing path-provenance
failure in PreflightHandoffTests.cs, or an explicit declared gate disposition;
this task does not edit or bypass it. No new product architecture is required
by the observed missing marker; it is a fixture binding error.

SOURCE-SHA256 now binds terminal HH-01 bytes and retains every accepted
narrowed-A baseline/source-stop binding. Scoped diff whitespace passed; HEAD
is still 9eac17cfdb741f89d33a4b7c2ddf6261abcb9566. No commit/export/reference
switch, Unity/MCP/BatchMode/CUA, native Provider/live Probe, real action or
process control was performed. RequireReady wording FOLLOW-UP was untouched.

## Snapshot binding correction — 2026-10-13 13:24 +08:00

The lifecycle terminal hash was captured before Coder's final intended
`DeleteEditorLease();` insertion in the TrustedPrevious branch (source mtime
2026-10-13 04:43:51 UTC). Coder did not refresh that terminal binding after
the insertion. The current scoped diff contains exactly the intended narrowed
changes. Removing only this insertion in memory reproduces the stale recorded
hash `a8712d0be560fb195bbbad9b282daea7f877faac98ce6ef6dc2f674254e0c2d3`;
current source is `c0ac0acf5f28726940f59b5baa51dec3cbe35b31b9538112eb8b95c851704a24`.
The terminal record now binds current bytes and retains the superseded hash as
provenance. No production/test edits, semantic reruns or wording changes were
made in this correction. Base HEAD remains
`9eac17cfdb741f89d33a4b7c2ddf6261abcb9566`.

## Narrowed implementation outcome (2026-10-13)

User-approved outcome A was applied. A Package-declared `TrustedPrevious`
instance is now historical/removal evidence only: it cannot publish an Editor
lease, scheduled reconcile does not request convergence for it, convergence is
blocked before lease/start and automatic Deploy/Upgrade, and the lifecycle
retains the authenticated removal preflight path. Current and missing routes,
v1 obsolete handling and strict backend activation checks remain in place.
Probe text now says controlled removal/reinstall and no longer promises
automatic handoff. The C# fixture expectation was changed accordingly; the
PowerShell historical fixture no longer performs the deferred Upgrade or drain
mutation and verifies the retained closure remains byte-exact.

Changed allowlisted files: `Editor/AICodedbProjectIntegrationState.cs`,
`Editor/AICodedbEditorLifecycle.cs`, `Tools~/codedb-instance-engine.ps1`,
`Tests/Editor/AICodedbEditorLifecycleTests.cs`, and
`Tests~/test-codedb-host-payload-materializer.ps1`. No new schema, capability,
transport or persistence field was added. The original scope-stop record and
its original clean hashes remain attributable below; terminal hashes are in
`HISTORICAL-HANDOFF-CAPABILITY-SOURCE-SHA256.txt`.

## Focused evidence

- PowerShell parser: PASS for the changed engine and focused test script.
- Roslyn semantic compile using the existing focused harness: `SEMANTIC errors=0`.
  The standalone runner then reached its pre-existing ignored
  `RetainedDispositionOnly` prerequisite and is recorded as NOT PASS; no source
  assertion was rewritten to manufacture a PASS.
- GenerationAlignmentOnly attempt was stopped by the harness's explicit
  predecessor/target fixture binding assertion before the narrowed scenario;
  this is NOT PASS and no retry or input mutation was performed.
- Unity/NUnit, live Probe/Provider, real Remove/Install/Upgrade and package
  gates remain unrun by authorization.

Date: 2026-10-13. Status: SCOPE_STOP / NO_SOURCE_CHANGE.
Base and terminal HEAD: 9eac17cfdb741f89d33a4b7c2ddf6261abcb9566.
Role: task-scoped depth-one Coder, user-approved transport exception.
Inherited model/reasoning: no authoritative runtime setting was exposed to this
child; unknown, not guessed. No model/profile override or recursive delegation.

## Terminal outcome

The frozen card requires a demonstrated independent supported-handoff authority
and explicitly stops on an unprovable supported handoff or a newly required
reader/architecture. Direct boundary inspection reached that stop condition
before production edits. Existing historical identity and Supervisor identity
readers do not provide the strict generic next-change admission result to C#.
No source acceptance or focused-test PASS is claimed. Parent was notified and
asked for one consolidated minimum-scope report; no Verifier is needed for this
unchanged source snapshot.

## Producer / consumer decision map captured before editing

| Input / producer | Current real consumer | What it proves / permitted route |
| --- | --- | --- |
| Package bootstrap transition tuple, stable wrapper hash and retained generation bytes | AICodedbPackageRuntimeContractStore.Read -> AICodedbCurrentInstanceStore.ValidateTrustedPreviousIdentity | Exact historical identity/closure. Existing lifecycle incorrectly treats TrustedPrevious as Deploy and lease eligibility. This is not automatic-upgrade authority. |
| Optional source_runtime_contract_sha256 in exact delivered poc.42 transition | PowerShell payload reader -> historical Get-RemoveIntegrationActivationState | Historical runtime evidence for the explicit removal context only. C# does not currently project this field. Presence or equality alone is neither Upgrade nor removal permission. |
| Supervisor namespace owner/state, process evidence and authenticated IPC | AICodedbControlContractMigrationStore.Read -> Current/CompatibleStale | Supervisor control authority. The reader does not authenticate the generic activation pair and operation namespace; this result cannot substitute for next-change admission. |
| Current Manifest runtime context plus activation.json/operation.json, their pair, candidates, operation/retirement namespace and retained evidence | Assert-InstanceNextChangeAdmission -> Get-InstanceActivationContractState/RecoveryState -> Invoke-InstanceConvergence | Actual generic backend admission. A different runtime authority is refused. Existing strict implementation stays protected. There is no C# upgrade eligibility result transport. |
| Historical removal authority + preflight handoff | ReadRemoveIntegrationPreflight -> HasAuthenticatedRemovalPreflight -> WithRemovalPreflight / Manager presentation | Remove Integration availability only; command revalidates. Cannot be repurposed as an Upgrade permit. |
| Probe/DryRun selected predecessor | Write-InstanceProductStatus -> AICodedbProductStatusBuilder.Build | NeedsAttention and old automatic-handoff prose; no independently authenticated automatic-handoff result. Old Provider Ready cannot establish target Ready. |
| Missing/current selected instance | Existing first-install/current convergence branches | Preserve these existing routes. Current generic backend rules remain authoritative. |
| Legacy flat and poc.33 prior-generation fixtures | Existing UpgradeOnly tests | These are historical scenarios, not a demonstration of a compatible selected-v2 activation. Do not claim a current PASS or turn them into v2 evidence. |

The old C# CurrentInstanceStore_TrustedPoc33PlansAutomaticPoc34Handoff test
uses a schema-1 fixture without v2 owner_identity_version/activation_epoch.
The PowerShell Install-TrustedPreviousInstanceFixture likewise writes schema-1
instance/current selection and no v2 activation pair. Its UpgradeOnly historical
expectation does not establish the required selected-v2 compatible handoff.
No test was run or rewritten to force that interpretation.

The installed42 -> delivered43 case is already decisively different-runtime:
source authority 538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d,
target authority 69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.
The existing GenerationAlignment test also explicitly expects generic
next-change refusal while historical removal admission succeeds. That source
expectation is evidence of the intended separation, not a new execution PASS.

## Minimum choices returned to Planner/User

A. Narrow this task to treating selected previous-v2 as removal-only, preserving
missing/current and already supported flat routes; make supported previous-v2
automatic handoff a separately designed future capability. This avoids inventing
a permit, but withdraws the frozen promise to preserve a demonstrated compatible
previous-v2 handoff. It is a requirement change, not authorized implementation.

B. Design a read-only, transient, identity-bound automatic-handoff observation
from the existing strict backend admission, consumed before lease/start. This
preserves the possibility of proven compatible handoff without weakening backend
authentication. It needs explicit approval of the output/reader contract and
focused evidence; the current card forbids silently adding that contract.

The narrowest B transport to evaluate first is the existing DryRun route:

- Tools~/codedb-instance-engine.ps1: Write-InstanceProductStatus (currently 5368)
  can be the observation producer, reusing Assert-InstanceNextChangeAdmission
  and its strict activation readers. Their validation remains unchanged.
- Tools~/materialize-codedb-host-payload.ps1: existing DryRun dispatch invokes
  that producer (currently 12159); it is a read-only reference, and an extra
  action or edit to this entry need not be assumed if DryRun can carry the result.
- Editor/AICodedbHostPayloadMaterializer.cs: existing ReadStatus(context, token)
  is the direct DryRun caller. A dedicated real reader must reject absent,
  duplicate, malformed, conflicting or foreign output; product Ready is separate.
- Editor/AICodedbEditorLifecycle.cs: RunReconcileWorker must consume eligibility
  after reading currentInstance and before its current prerequisite-to-
  TryRefreshEditorLeaseForAdmission path (currently 993-1071). A previously
  published lease must not skip this check. Reopen/scheduled reconcile and later
  RefreshEditorLeaseForIntegrationState must share the same distinction.
- Editor/AICodedbProjectIntegrationState.cs: retain historical identity separately
  from operational lease eligibility; do not let an unbound status enum/bool mint
  capability. The proposed observation must bind current project, Package/runtime,
  selected identity/activation and freshness, with actual backend revalidation at
  mutation. Exact fields/rules remain a design decision, not an implemented schema.
- Existing allowlisted focused C#/PowerShell tests must connect producer bytes
  to the real reader and prove both accepted and refused admission, before lease,
  repeated reconcile, and authenticated removal presentation.

If DryRun cannot provide a sufficiently bounded/identified observation, a
dedicated read-only action would additionally require materializer entry/action
allowlist changes. That is a larger fallback, not the proposed minimum.
An alternative direct C# activation reader would duplicate the backend admission
surface and also requires a newly approved reader design; it is not silently
substituted here.

Recommendation: retain strict backend authentication. Have Planner choose A's
explicit compatibility limit or freeze B's minimal observation/consumer contract;
do not use tuple trust, hash equality, Supervisor Current or removal preflight
as automatic Upgrade permission.

## Read-only/refusal proof and limits

Assert-InstanceNextChangeAdmission is documented in production as a read-only
admission check under the existing project-lock owner. It reads desired/current/
LKG, intents, retirement controls, activation state/recovery and instance trees;
with no Candidate it does not publish or recover records. Get-InstanceActivation-
ContractState/RecoveryState validate existing bytes; Invoke-InstanceActivation-
ContractRecovery performs mutation and must not be included in a proposed reader.
The actual mutation remains locked and revalidated by Invoke-InstanceConvergence.
The full child does not claim a race-free read-only observation without an
approved binding/freshness contract. No live backend function was executed.

Different-runtime activation fails strict trusted-context comparison. Missing
one activation record, orphaned/mismatched operation evidence, ambiguous roots,
foreign project/owner or unresolved retained effects also cannot become a permit.
Unavailable observation stays closed; historical classification only recommends
the controlled removal route and never enables its button without preflight.

## Stable source and protected state

The seven existing allowlisted source/test files were clean at entry; five were
changed by approved outcome A and their terminal hashes are recorded in
SOURCE-SHA256. The optional new focused test file was not created. Only this
RESULT and SOURCE-SHA256 were added as Coder evidence.
Accepted delivered manifest and predecessor/target generation hashes were read
and match the frozen bindings. S29 manifest/lock match their earlier documented
hashes. There was no protected-state write; no bulk scan of active machine state
or assertion that its live timestamps were frozen.

Inherited dirty Payload, OwnerIdentity fixture, project/config/docs and untracked
files remain untouched. No overlay candidate or generation/schema/persistence
change was made.
No Unity/MCP/BatchMode/CUA, Provider/IPC/live Probe, process control, real mutation,
Install/Upgrade/Remove/Uninstall, export, reference switch, commit or cleanup.

L0 PowerShell syntax and Roslyn semantic compilation passed; the standalone
focused runner stopped at its pre-existing ignored RetainedDispositionOnly
prerequisite, and GenerationAlignmentOnly stopped at its explicit fixture
binding assertion. Those L1 gates are NOT PASS. Semantic attempts: 1;
mechanical corrections: 0. Several bounded source reads exceeded their chosen
output caps and were followed by targeted reads; no blanket output-budget
compliance is claimed.
Real Unity reopen, controlled removal/fresh43 Install, continuous Ready,
NONZERO_EXIT attribution, CleanupMono and release remain deferred. S29 PARTIAL.

## Source disposition — 2026-10-13

User accepted this bounded implementation after independent Verifier review
(`PASS_WITH_LIMITS`). The `RequireReady` handoff wording remains a FOLLOW-UP.
Commit, export, reference switching, Unity and real operational gates remain
separate and unauthorized.

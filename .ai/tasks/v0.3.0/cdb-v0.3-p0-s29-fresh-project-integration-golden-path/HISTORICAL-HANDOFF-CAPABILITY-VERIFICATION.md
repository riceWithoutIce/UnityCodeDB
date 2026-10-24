# S29 HH-01 targeted read-only verification

Date: 2026-10-13. Role: task-scoped Verifier. Review: original HH-01 and nearest regressions only.

**Source HH-01: CLOSED at the reviewed source level. E-01/E-02: CLOSED WITH LIMITS by the renewed evidence-a1 envelope. E-03 Package path blocker: CLOSED by the authorized E-04 PathProvenance evidence. E-04 fixture correction: CLOSED; original-byte Tests compilation: CLOSED WITH LIMITS. The Unity comparator remains HUMAN-UNITY-PENDING.** Current evidence disposition is `PACKAGE_PATH_GATE_PASS / HUMAN_UNITY_PENDING`. This is not Unity/EditMode acceptance, delivery approval, S29 completion or release acceptance.

## Prior evidence-stop review history (superseded only where stated below)

The following snapshot and E-01/E-02/E-03 findings record the prior HH01 evidence-stop envelope. They remain attributable historical facts; the authorized evidence continuation at the end of this report gives the current disposition. Old invalid outputs are never promoted to PASS.

## Snapshot admission

The five live source SHA-256 values exactly match the terminal section of HISTORICAL-HANDOFF-CAPABILITY-SOURCE-SHA256.txt:

| File relative to com.rice.ai-codedb | Terminal SHA-256 |
| --- | --- |
| Editor/AICodedbProjectIntegrationState.cs | 3b82a99822118a9e5836a11242550d6707e1e9d5766aacca6970adcefb9cad84 |
| Editor/AICodedbEditorLifecycle.cs | f4fe900d94b1662a40f595b8e8649cc1491f4c7e79632918266c1239832b024e |
| Tools~/codedb-instance-engine.ps1 | 95e302d8ad90a47cc2a08b76d42a30413cb011478880658ac34a8ce946500acf |
| Tests/Editor/AICodedbEditorLifecycleTests.cs | cac46933a227cb5092b7b4b2b9fdc9fa9c2f434bc67f44f0b172351a64d361e4 |
| Tests~/test-codedb-host-payload-materializer.ps1 | 8a8bf223518b35a5eee7559c3d20984444806696713cd799644fbd24863e27fc |

HEAD remains Base SHA `9eac17cfdb741f89d33a4b7c2ddf6261abcb9566`; the ordinary index is empty. The two accepted production files outside HH-01's permitted production edit match their accepted hashes. Parent reported six protected S29 reference/desired/current/activation/operation hashes unchanged; this review consumes that admission evidence and does not independently scan live runtime state. The previous VERIFICATION.md was read for its hash only and was not edited (SHA-256 `dc3f1752f940d1246d636998181aa572d1812c3b37ceb3c36917e9076c8c2062`).

## HH-01 source closure and adjacent guards

The original finding in HISTORICAL-HANDOFF-CAPABILITY-DELIVERY-PREPARATION.md described a normal no-lease return and an existing-lease no-reconcile return that preceded the removal-only branch. Both ordering counterexamples are closed by the directly consumed production seam:

- RunReconcileWorker calls TryRouteHistoricalRemoval at Editor/AICodedbEditorLifecycle.cs:982 immediately after the existing selection read, before independent lease admission at :1031, automatic-start enablement at :1277, BackendNeedsReconcile/no-reconcile at :1280, and the Supervisor Probe/Upgrade branches. The former late branch is gone.
- The seam at :1548 intercepts only Installed + TrustedPrevious + the existing IsUsableForAutomaticStart migration classification. Current, missing, v1 obsolete, invalid, uninstalled, invalid integration and blocked migration fall through to existing guards. The migration property's existing Missing/Current/CompatibleStale definition is unchanged (Editor/AICodedbControlContract.cs:207). The initial NotIntegrated and transient authentication retry guards remain before the new call (:948-973).
- The worker's block delegate (:988-994) clears automatic start, prerequisite lease eligibility and recovery attempts, and deletes the owned tracked lease before reading the prerequisite. It does not depend on force, prior readiness, or lease presence; cold/repeated/existing-lease routes therefore share the same disposition and cannot reach automatic Deploy/Upgrade on this intercepted path.
- TryRouteHistoricalRemoval (:1555-1575) checks cancellation/context before and after the read. It uses the real product builder plus the existing trustworthy prerequisite reader (:1932), which rejects absent, timed-out, failed or invalid command evidence and requires an unambiguous consistent marker. Missing prerequisite retains the observed MissingPrerequisite status; untrusted evidence becomes blocked NeedsAttention without preflight or Ready.
- Only trustworthy Current prerequisite reaches removalPreflight (:1578-1585). The production delegate uses existing WithRemovalPreflight (:986), whose availability comes from HasAuthenticatedRemovalPreflight (:1641) or its existing bounded cache. Historical identity itself does not mint availability. The worker rechecks cancellation/context before publishing (:998) and records Blocked before returning (:1000-1005).

Tests/Editor/AICodedbEditorLifecycleTests.cs:160-264 authors directly consumed seam coverage for repeated/cold/existing-lease ordering, preflight marker pass/refusal, fall-through guards, missing/ambiguous/failed prerequisites and cancellation. The selected identity, lease and preflight are synthetic inputs; fixture.binding is a synthetic handoff marker, not proof of a real backend authorization. No claim that these cases passed in an admissible harness is made. No new source defect was established in HH-01 or its nearest inspected regressions.

## BLOCKER E-01 — required C# compile and routing execution evidence unmet

Coder RESULT's stable-stop section records two corrected C# executions using the old retained-disposition harness. Read-only inspection confirms `.artifacts/tests/s29-retained-disposition-fix/compile/Focused.cs:25-28` invokes NativeBoundaryRewrite; :54-57 declares the rewrite and removes the Lifecycle static initializer. This is contrary to the frozen exact-AST adaptation boundary. The 21 PASS lines in `hh01-a2/logs/mono-seam-hh01.log` are invalid auxiliary output and cannot establish HH-01 routing L1 PASS. `semantic-hh01.log` shows a successful build of the old Focused harness, not the required complete original-byte csc/Bee compilation. Coder records the prepared compile-exact.ps1 was not executed; complete original-byte csc and permitted exact-AST execution are **NOT RUN**. Original plus two corrected C# execution attempts exhausted the existing budget; no new Coder attempt is requested by this report.

## BLOCKER E-02 — actual producer-to-real-reader gate failed

Owned output `.artifacts/tests/s29-historical-handoff-capability/hh01-a2/probe/probe-output.txt` contains NeedsAttention and the controlled removal/reinstall text, but contains no `[PRODUCT_LAYER PREREQUISITE]` marker. The recorded reader failure in `hh01-a2/logs/mono-seam-hh01.log` is `actual=Unknown constraint=<equal Current>` from HistoricalRemovalRouting_ConsumesProductionProbeBytes; the real reader parses prerequisite from that marker (Editor/AICodedbHostPayloadMaterializer.cs:844, :895).

This is attributable to the fixture binding: Tests~/test-codedb-host-payload-materializer.ps1:93 sets MachinePrerequisiteStatus non-null and :94 directly invokes the extracted producer without upstream marker output. The unchanged immutable-overlay writer emits its own prerequisite marker only when MachinePrerequisiteStatus is null (Tools~/codedb-instance-engine.ps1:5421-5423). Thus the producer correctly avoids duplicating the upstream marker while this fixture omitted it. PS `ps-l1-a2.log` reports writer-only PASS with synthetic prerequisite/selection boundaries; the combined producer-to-reader gate is **NOT PASS**. This is evidence failure, not evidence of a new production parser defect or a need for new architecture. The failed reader run also used the inadmissible C# harness; it cannot be promoted to accepted L1 evidence.

## BLOCKER E-03 — frozen Package path-provenance gate failed

`hh01-a2/logs/path-provenance-overlay.log` records failure in unchanged Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs. Direct inspection of the owned immutable overlay confirms `G:/fixture/project` at :43. Coder records the first path run mistakenly used the working-tree script and the second used the owned overlay. Neither is PASS; the outside-allowlist file was not changed or exempted. This is a pre-existing frozen-input gate failure, separate from HH-01 source closure. Resolving its disposition or allowlist requires User/Planner direction; this Verifier does not bypass it.

## Evidence integrity limitation and retained FOLLOW-UP

Coder records that the second C# execution overwrote the first raw mono-seam-hh01.log. The surviving log contains the second run; the first RetainedDispositionOnly failure is preserved only in RESULT/session output. Immutable per-attempt raw evidence is therefore incomplete. The restored old Runner.cs does not undo changed historical generated build outputs; blanket protected-artifact preservation is not claimed.

The previous RequireReady wording remains **FOLLOW-UP**, unchanged and outside HH-01: Tools~/codedb-instance-engine.ps1:5431 still says `requires handoff from the trusted previous generation` while its normal marker says controlled removal/reinstall. This review does not reassess or repair it.

## Terminal disposition and limits

HH-01 source ordering is CLOSED; required focused evidence remains unmet for the separately identified reasons above, so overall acceptance cannot be PASS. Findings return together to User/Planner for source/evidence disposition. No repairs were assigned to Coder and no further test, compilation or provenance execution was performed. Only this report was written; prior VERIFICATION.md remains preserved. No Unity/MCP/BatchMode/CUA, native Provider/IPC, live Probe/Ensure, real Install/Upgrade/Remove, process control, commit/export/reference switch, cleanup, push or publication was performed. Real Unity reopen/removal/fresh installation, continuous Ready, CleanupMono and S29/release gates remain deferred.

## Authorized evidence continuation — targeted re-review, 2026-10-13

Current disposition: **HH-01 source CLOSED; E-01 CLOSED WITH LIMITS; E-02 CLOSED WITH LIMITS; E-03 REMAINS BLOCKED. Overall PACKAGE_PATH_GATE_NOT_PASS.** Scope was only these findings and their direct regressions. Verifier read source, scripts, response files and existing logs; no tests, compilation, extractor or provenance gate was executed. The prior failures, exhausted original ledger and overwritten-log limitation above are preserved.

### Renewed snapshot and artifact attribution

All six active terminal source hashes and 17 additional artifact/script/log bindings read from SOURCE-SHA256 match live bytes (23 checks, zero mismatches). All six worktree source files also match exclusive evidence-a1 overlay bytes. Production ProjectIntegrationState, Lifecycle and instance-engine and the Lifecycle tests retain their prior HH01 hashes. Only the authorized marker fixture and preflight owner fixture changed:

- Tests~/test-codedb-host-payload-materializer.ps1: `42d66aec012407c52b6f9cc45a59d8b55141dac1d0fbd0d862ef79f48a8b6aac`.
- Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs: `50e78911f9967cbd644a24f70bb103167a51a5f1c7c43a0dc05d8a289cf5448a`.

HEAD remains `9eac17cfdb741f89d33a4b7c2ddf6261abcb9566` and staged index is empty. Parent's stable admission also reports diff-check=0 and protected reference bindings unchanged; no real runtime scan was repeated. Evidence root E is `.artifacts/tests/s29-historical-handoff-capability/evidence-a1/`. Artifacts of particular relevance:

| Artifact under E | Verified SHA-256 |
| --- | --- |
| Rice.AICodedb.Editor.dll | bbc6c5baba17e4194df02b692fb0316a62081d4252ee4aa4fda67e94e4442859 |
| Rice.AICodedb.Editor.ref.dll | bd306ac9936a187b2a16eafc6e3126eab119637889b6900c7a896134c611cf0d |
| Rice.AICodedb.Editor.Tests.dll | f85c95b6f2c6ffe1d4b90c5fdc3971bfc1f9219afd24e63cb27b9d5936cfe764 |
| Rice.AICodedb.Editor.Tests.exe | fd3e6f9df691efe0dc9abfdf03d7220797194dba5d793a77a4bc6dfdd2e903eb |
| Seam.cs | b13a294614266ec97879aa51461670ffcb20f6d39316b9a7c1e6ea211dc1d951 |
| probe/probe-output.txt | 520afe24c2d157303271194b997fc4f4f5eef5253552bdc7999d64fde7c7a219 |
| logs/seam-run-a1.log | 0573ca76a4ff20c6101d2f3e7676eb4ec63f64d4d929c33b4a5e4c18f52d12fc |

### E-01 closed within original-byte compile and pure-seam limits

E/compile-exact.ps1 reads the existing S29 Bee response files and redirects only output/refout, Package source paths and the Tests reference to the newly produced Editor.ref.dll. Comparison with the original response files found the same line counts (400 Editor / 366 Tests), 32 and 7 expected redirect differences, and zero unexpected option changes. Retained response files enumerate 30 original-byte Editor source files and four test source files, including Lifecycle, PreflightHandoff, ManagerUi and workspace owner. No source bytes are rewritten by this compiler script. The compiler is Unity 2022.3.62f3 NetCoreRuntime/dotnet + DotNetSdkRoslyn/csc; RESULT attributes exit=0/errors=0 for both runs. The retained Editor log contains only three existing warnings; Tests log contains no diagnostics. These logs and DLLs match recorded hashes. This closes the prior missing original-byte compilation requirement for the delivered assembly source set, without claiming Unity import or Editor execution.

E/extractor/Extract.cs obtains original AST member spans with source.Substring(member.Span.Start, member.Span.Length), retains attributes and NUnit assertions, wraps only the selected members in isolated classes, reparses, and requires exactly one member with identical text for each original. E/logs/exact-ast-binding.txt binds the original Lifecycle/Test source hashes and 18 member hashes and reports EXACT_MEMBER_TEXT_EQUALITY PASS; E/logs/extractor-a1.log agrees. The 18 consist of ten production declarations (routing method, four prerequisite helpers, three convergence overloads, two enums) and eight test/helper declarations. There is no NativeBoundaryRewrite, assertion adapter, fake native shim or rewritten initializer in this exclusive extractor/seam. This is exact member-text evidence, not an assertion that the enclosing original class/initializer is executed.

E/Runner.cs reflects the four original HistoricalRemovalRouting methods, enumerates their original TestCase arguments, executes each with the real NUnit framework, exits on an invocation exception, and requires count==22. E/logs/seam-run-a1.log records all 22 cases: four lease/preflight/repetition cases, nine fall-through guards, eight prerequisite/cancel cases, and one producer-byte reader case. E/run-seam.ps1 binds the newly compiled Editor.dll in seam-a1.rsp, then executes the emitted exe with Unity standalone Mono and the owned output environment variable. Expected CS0436 compiler warnings select the extracted Lifecycle type; other production status/result/reader types resolve to Editor.dll. The local NUnit DLL exactly matches the referenced Unity NUnit DLL (both SHA `e388e140954de12970384331d1730e95b4613ef53c3326b6f8fa0fffdbc9314f`). Original assertions/test inputs were not edited by the harness.

This valid renewed 22-case result closes E-01's missing pure-seam execution. It does **not** validate actual RunReconcileWorker IO, real lease deletion, Supervisor/IPC/Provider or Unity lifecycle/reopen behavior. The old NativeBoundaryRewrite executions and their 21 auxiliary PASS lines remain invalid historical outputs, and the first old raw-log overwrite remains unrecoverable in that file.

### E-02 closed within producer/real-reader fixture limits

The authorized fixture correction at Tests~/test-codedb-host-payload-materializer.ps1:88 prepends the existing upstream `[PRODUCT_LAYER PREREQUISITE] CURRENT` marker before calling the unchanged production writer. Selected-instance and machine prerequisite boundaries remain synthetic and declared. E/probe/probe-output.txt now includes that marker plus the production NeedsAttention, controlled-removal/reinstall wording and no Ready. The script extracts the real writer body from the exclusive immutable overlay; it does not rewrite it.

The original HistoricalRemovalRouting_ConsumesProductionProbeBytes method is retained text-identically in E/Seam.cs. E/run-seam.ps1 sets RICE_HH01_PROBE_OUTPUT to this owned output, while seam-a1.rsp references E/Rice.AICodedb.Editor.dll, not a shim reader. Seam.cs defines only the extracted Lifecycle and test fixture; AICodedbProductStatusBuilder.Build remains the real original-byte Editor DLL implementation. The surviving renewed run log records PASS for that method. This closes the previous marker-binding/Unknown!=Current failure for the declared producer-fixture-to-real-reader scenario, without claiming an actual live materializer Probe or independent machine/selection authentication.

### E-03 remains BLOCKED: correct overlay Package path gate NOT PASS

The approved preflight fixture repair uses AICodedbTestWorkspace.Run and workspace.ProjectRoot at Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs:37-46. Its original Assert.Throws<ArgumentException> for RemoveIntegration without a handoff is retained. This source was included in original-byte Tests compilation, but the test was **NOT EXECUTED**: the existing workspace owner requires Editor-main-thread UnitySynchronizationContext and Application.dataPath (AICodedbTestWorkspace.cs:49-51). No fabricated Unity owner was supplied. Treat its compile/static result separately from human Unity execution.

E/logs/path-provenance.log records the correctly bound exclusive-overlay PathProvenanceOnly command failing on unchanged Tests/Editor/AICodedbManagerUiTests.cs. Direct read confirms `G:/RiceProject/Retained` at :1845 and adjacent equivalent fixed literals at :1846-1847. This is outside the continuation edit allowlist and was not edited, skipped or exempted. The earlier PreflightHandoff literal is repaired, but the whole Package gate is still **NOT PASS**; no unconditional source/evidence completion or delivery PASS can absorb that failure.

### Current acceptance boundary

The unchanged HH-01 production snapshot remains source CLOSED and now has attributable original-byte assembly compilation, exact pure-seam 22/22 execution and real product-reader evidence. Those bounded source findings are suitable for a new User source disposition **with the declared limits**. Source ACCEPT is the user's decision; this report does not grant it. E-03 remains the Package gate blocker and requires separate User/Planner gate/allowlist disposition before claiming that gate complete. Preflight owner test execution, actual worker/Unity lifecycle, real Remove/fresh Install, live Provider, continuous Ready, CleanupMono, delivery and release remain unrun/deferred. The old RequireReady wording remains FOLLOW-UP. No new defect or repair was dispatched; stop this targeted review here.

## E-03 authorized narrow fixture correction — targeted closure review

Current disposition: **E-03 source-local fixture correction CLOSED; original-byte Tests compilation CLOSED WITH LIMITS; comparator execution HUMAN-UNITY-PENDING; Package PathProvenance gate REMAINS NOT PASS.** This section reviews only the named `RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot` fixture and direct rejection assertions. It does not rerun the gate, compile, or test.

The current worktree and evidence-e03-a1 overlay `Tests/Editor/AICodedbManagerUiTests.cs` hash is `f3236e62297e19b1d7cf569dbe25580133a06ef4a4d0f826ef0ebcdbc54457a8`; the prior evidence-a1 baseline remains preserved at `d599a155ae69548927779c37a6336bc1d0f23495df14716797a4f71fbacdd44c`. Only the named method changed. It now derives `Retained` from `AICodedbTestWorkspace.ProjectRoot` inside the existing workspace owner. Windows bidirectional case/slash/trailing-separator equivalence and bidirectional rejection for different, relative, drive-relative, root-relative, malformed/double-colon, question-mark, incomplete-UNC and empty roots remain. Unix same-root/trailing acceptance and case/relative rejection remain. The neighboring missing-handoff/refusal assertions are retained.

The production comparator `AICodedbPaths.AreSameAbsoluteProjectRoot` is unchanged: current worktree, evidence-a1 and evidence-e03-a1 all hash `db15186a3a61f066d10ba1c023b6ada633ebef11cd760d4c84a6440e8fc40ac2`. This is fixture portability only; no product identity admission exception was added.

`evidence-e03-a1/compile-tests-exact.ps1` binds the original S29 Bee Tests response file (366 lines), redirects only output/refout, replaces source paths with the exclusive overlay and references the prior exact original-byte `evidence-a1/Rice.AICodedb.Editor.ref.dll`. Read-only comparison found seven expected redirect changes and zero unexpected option changes. RESULT records Unity csc/Bee exit 0 with zero errors and no diagnostics; the emitted Tests DLL/ref DLL and compile log are hash-bound. The full four delivered test sources remain included. This is compilation evidence only.

The comparator method is **NOT RUN**. Its existing `AICodedbTestWorkspace.Run` owner requires actual Editor-main-thread `UnityEngine.UnitySynchronizationContext` and `Application.dataPath` (AICodedbTestWorkspace.cs:49-51). The neighboring `RemovalIntegrationArguments_RequireHandoff` likewise remains a human Unity gate; no fabricated owner was used.

The corrected ManagerUi literal no longer blocks PathProvenance, but the correctly bound evidence-e03-a1 gate still exits 1 at the next unchanged, outside-allowlist `Tests~/test-codedb-retained-entry-routing.ps1:181`. That line contains intentional invalid samples `G:/bad?root` and `G:/bad` + NUL + `root`; parent’s read-only extension scan reports exactly one matching file and one matching line. This remains a Package gate boundary, not an E-03 comparator regression. No source edit, exclusion, bypass or retry was made.

Therefore E-03’s approved fixture portability fix is source-locally closed and its original-byte compilation is attributable, while the actual comparator test remains pending human Unity execution and the Package PathProvenance gate remains NOT PASS. Overall acceptance remains `PACKAGE_PATH_GATE_NOT_PASS`; this review does not grant source, delivery, Unity or release approval. Prior invalid NativeBoundaryRewrite runs, old log overwrite history and RequireReady FOLLOW-UP remain preserved.

## E-04 authorized retained-entry fixture correction — targeted closure review, 2026-10-13

Current disposition: **E-04 source-local fixture correction CLOSED; original-byte Tests compilation CLOSED WITH LIMITS; Package PathProvenance PASS and prior E-03 Package path blocker CLOSED; comparator execution remains HUMAN-UNITY-PENDING.** This review consumed the stable Coder snapshot and existing evidence only. It did not rerun script parsing, tests, compilation, PathProvenance or Unity, and did not expand into a new HH-01 audit.

The only E-04 source difference is the former fixed-drive invalid samples in `Tests~/test-codedb-retained-entry-routing.ps1:181`: current :181-183 builds `$invalidQuestionRoot` with `Join-Path $fixtureContainer 'bad?root'` and `$invalidNulRoot` with `Join-Path $fixtureContainer 'bad'` plus `[char]0` and `root`. Both keep the malformed character, use the existing owned fixture container and remain in the unchanged bidirectional rejection assertion at :184. Relative, drive-relative, root-relative, incomplete UNC and different-root samples remain, as do the adjacent slash/case/trailing equivalence checks and the retained admission scenarios. No rejection or product identity check was removed. Current worktree and E-04 overlay script SHA-256 both equal `719661e6d0dc409de4c889019e8686819564ed3810f20b78c5784fb1d5bd2eac`.

Read-only byte checks confirm the seven prior scoped worktree sources plus the E-04 script equal the exclusive `evidence-e04-a1/com.rice.ai-codedb` overlay (eight comparisons, zero mismatches). Production `Editor/AICodedbPaths.cs`, including `AreSameAbsoluteProjectRoot`, is unchanged: worktree, E-03 overlay and E-04 overlay all hash `db15186a3a61f066d10ba1c023b6ada633ebef11cd760d4c84a6440e8fc40ac2`. The E-03 ManagerUi fixture retains hash `f3236e62297e19b1d7cf569dbe25580133a06ef4a4d0f826ef0ebcdbc54457a8`. HEAD remains `9eac17cfdb741f89d33a4b7c2ddf6261abcb9566`, staged index is empty, and the old `VERIFICATION.md` remains hash `dc3f1752f940d1246d636998181aa572d1812c3b37ceb3c36917e9076c8c2062` and was not edited.

`evidence-e04-a1/compile-tests-exact.ps1` uses Unity 2022.3.62f3 NetCoreRuntime/dotnet and DotNetSdkRoslyn/csc with the original S29 Bee Editor.Tests response. The retained response has 366 lines and the same four original-byte test source bindings redirected to the E-04 overlay; output/refout and the reference to prior exact `evidence-a1/Rice.AICodedb.Editor.ref.dll` are the only other redirects. Read-only comparison found seven expected differences and zero unexpected option changes. Coder RESULT records exit 0/errors 0; the retained compile log is one newline with no diagnostics. This closes attributable Tests compilation only; no test execution is inferred.

The existing `evidence-e04-a1/logs/path-provenance-a1.log` contains `[PASS] Package path provenance.` and the helper/caller binding PASS (`projections=3`, PS bindings=2, Node bindings=2). Coder RESULT attributes exit 0 to the single correctly bound E-04 `-PathProvenanceOnly` attempt. The unchanged gate script runs against the exclusive overlay without exclusions or a changed gate rule. This closes the prior E-03 retained-entry :181 Package path failure; the earlier E-03/evidence-a1 failures remain historical NOT PASS records, not retroactive PASS.

All six E-04 artifact/log/script hashes match SOURCE-SHA256 and RESULT:

| Artifact under evidence-e04-a1 | Verified SHA-256 |
| --- | --- |
| Rice.AICodedb.Editor.Tests.dll | c709f50583ca42c3c9b5bd42c6eaa6a94618156678caa41359e2f5ab3c46395c |
| Rice.AICodedb.Editor.Tests.ref.dll | 5e46162a0f8b5df4e2418c5f21b130fdde1a02b7cc2feb81cdd283328968e186 |
| Rice.AICodedb.Editor.Tests.rsp | f9d11387647dc9a41750601fab2a23db6316cc3c880316a4784283aa5fdef33f |
| compile-tests-exact.ps1 | 04e870e815b8a54dc8ccad1ee31fedb29ce0ee96daf641b320b90a3bd475e592 |
| logs/tests-compile-a1.log | 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b |
| logs/path-provenance-a1.log | ad19e1143c6d924e8b003fe779679a8bb4eeff171f54028de7b53062293e5fd8 |

The comparator test and neighboring workspace-owned preflight test remain **NOT RUN / HUMAN-UNITY-PENDING** because their existing owner requires the real Editor-main-thread UnitySynchronizationContext and Application.dataPath. E-04 compilation and PathProvenance do not substitute for that execution, actual worker IO, Unity reopen, removal/fresh installation, continuous Ready, CleanupMono, delivery or release acceptance. E-01/E-02 limits, invalid NativeBoundaryRewrite history, overwritten historical log limitation and RequireReady FOLLOW-UP are unchanged. No new finding was established in this targeted E-04 review, no repair was dispatched, and this review terminates with `PACKAGE_PATH_GATE_PASS / HUMAN_UNITY_PENDING`.

# S29 version-transition wrapper handoff — targeted read-only verification

Date: 2026-10-14, Asia/Shanghai. Role: task-scoped Verifier. Scope is limited to the wrapper-handoff finding and its nearest regressions under VERSION-TRANSITION-WRAPPER-HANDOFF-TASK.md. No broad historical-observation audit was performed.

Disposition: **SCOPED_SOURCE_REVIEW_PASS_WITH_LIMITS / SYNTHETIC_HANDOFF_PASS / PATH_PROVENANCE_PASS / UNITY_AND_REAL_READER_NOT_RUN.** No source blocker was established. The prior failure-before-wrapper chronology is now represented by the focused 32-check fixture; the original install-before-failure chronology remains covered by its 27-check control. These are production-function extraction/PocFixture observations, not live Unity, native, Provider, IPC or real Install/Remove acceptance.

## Stable snapshot and attribution

HEAD is `14444cf1ad179fe29e067e8dcfdc7b0b5496e230`; the ordinary index is empty. The stable overlay is `.artifacts/tests/s29-version-transition-wrapper-handoff/coder-a1/com.rice.ai-codedb`, copied from the exact target baseline `.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb` with only the two allowlisted files overlaid. Current source hashes are:

| File | SHA-256 |
| --- | --- |
| Tools~/codedb-instance-engine.ps1 | 5a00e3c5351ea10cd532cdd3b31a25305f2e1d2e885412119ff2af91d3487a39 |
| Tests~/test-codedb-host-payload-materializer.ps1 | 6340ad4298c528edbb9be85abaf26255bf6ff5a0da9bea227cc18d96bfe23bfc |
| Tests/Editor/AICodedbManagerUiTests.cs (unchanged consumer) | cc9e994996a4a38a78f3ec51928bd6e8e9d6bbdc08298ab45f51ea13c963aaab |

The source diff is confined to the engine's explicit historical-observation scope and the focused fixture's before-install scenario/negative checks. Manager UI, Journal, materializer, lifecycle, prerequisite and Payload bytes remain outside this repair. Protected before/after snapshots are identical (`2fd1f36ad3ba94afd7b2a34974c16204f10a3502f009c8ff4747fa83d42e949f`) across 2844 bounded protected-file/absent-root entries. No commit, export, reference switch, cleanup, process control, or product action was performed.

## Wrapper authority and the two intent reads

The static cause is addressed at both dependency points. `Get-InstanceRetainedEffectsObservation` validates current/LKG first and passes `-HistoricalObservation:$historicalSelection` into its initial `Get-InstanceRemovalIntents` call. `historicalSelection` is true only when the validated current selection has `GenerationDisposition -ceq 'TRUSTED_PREVIOUS'`; missing, CURRENT or invalid selection cannot opt into this path (engine :3398-3405).

The same explicit scope is carried into `Assert-InstanceNextChangeAdmission` at the observation's second read (engine :3432). Its guard requires both `HistoricalRemoval`, a current selection and `TRUSTED_PREVIOUS` before any historical intent read (engine :3323-3328). Default callers do not set `HistoricalObservation`. Existing real historical-removal callers still use their prior default intent behavior and retain their own independent preflight path.

`Assert-FailedPreparationWrapper` accepts this scope only through `Get-InstanceRemovalIntent`/`Get-InstanceRemovalIntents`. Under the scope it obtains `Get-ValidatedRemoveIntegrationSelection -OwnerIdentityVersion 2`, requires `Generation.Disposition == TRUSTED_PREVIOUS`, and then calls the existing `Get-RemoveIntegrationActivationState -AuthorityKind VERSIONED_V2` (engine :2003-2042). The historical reader derives runtime authority from the Package-declared predecessor tuple and cross-checks the selected instance, committed paired activation/operation, epoch, operation identity, generation manifest and actual stable wrapper bytes. It returns only the read-only `COMMITTED` disposition; it does not rewrite the failed intent or grant mutation permission.

The default branch still calls `Get-InstanceActivationContractState -Manifest $Manifest` and therefore remains target-context strict. There is no broad catch fallback from target failure to historical trust, no new serialization field, and no new authority service. The selected predecessor's original `CURRENT`-relative evidence is compared as a constructed selection evidence object; the persisted historical documents remain unchanged.

## Strict nearest regressions

The ordinary `Assert-InstanceNextChangeAdmission` path retains its default target authority and refuses the target43 context when the selected42 activation does not match it. The historical scope guard itself rejects calls without `HistoricalRemoval` or without an independently validated trusted predecessor. This preserves ordinary Install/admission and avoids making historical observation a mutation permit.

The wrapper handoff does not relax `ACTIVATING` or pending activation. `Get-RemoveIntegrationActivationState` requires both activation and operation to be `COMMITTED`, matching epoch and selected evidence; the focused fixture's paired-activating case remains blocked with the existing committed-evidence reason. Real removal still performs authenticated preflight/handoff, lock-time and commit-time authority checks and calls `Assert-InstanceNextChangeAdmission -HistoricalRemoval` without the new observation scope; this review does not claim real removal success.

Current/Ready behavior remains strict: target readiness and ordinary activation continue to require `GenerationDisposition == CURRENT`. The observation's installed predecessor output remains SAFE only as historical ownership/effects information and `InstallEligible=false`; it does not clear a handoff, produce Ready, release an index or permit Install/Remove. Holder/live/unknown-candidate checks and foreign project/selection checks remain before a SAFE observation.

## Existing focused evidence

The exact overlay's `path-provenance-a1.log` records `[PASS] Package path provenance.` and helper projections=3, PowerShell decoding/admission bindings=2 and Node caller bindings=2. This is reused evidence; no provenance command was rerun by Verifier.

`before-install-a2.log` records 32 checks and ends with `VERSION_TRANSITION_OBSERVATION PASS cases=32 failed_before_install=True native_children=0 PocFixture=true external_process_observation=synthetic`, binding fixture `wrapper-handoff-a2/r-25c90177`. It establishes the formerly missing chronology: a schema-2 PROVISIONING failed candidate and intent are serialized before wrapper publication with an empty original wrapper hash; exact original42 production Install then commits a distinct READY selected instance; current42 wrapper authentication returns COMMITTED; target43 default intent remains strict; explicit historical intent and the repeated historical admission read authenticate the committed predecessor; target43 observation is SAFE with `InstallEligible=false`.

`original-a1.log` records 27 checks and ends with `VERSION_TRANSITION_OBSERVATION PASS cases=27 failed_before_install=False ...`, binding `wrapper-handoff-a2/r-29ff7bce`. It preserves the original install-before-failure chronology and verifies the unchanged ORIGINAL wrapper route. Both scenarios retain same-version CURRENT control, ordinary target-strict refusal, wrong/missing/undeclared predecessor authority, foreign project, wrong generation/epoch, mismatched operation/runtime, paired ACTIVATING, immutable worker drift, arbitrary wrapper bytes, live/unknown holder and unbound relevant-candidate refusals. Both report BLOCKED, empty ids and `InstallEligible=false` for refusals, preserve the actual safety reason, preserve fixture bytes, and leave the failed intent byte-identical after observation.

The synthetic cases use the existing production serializers, Package payloads, holder readers and PocFixture seam. `native_children=0`, synthetic prerequisite/process identity and the retained cleanup warning are explicit limits. READY lines in the logs describe synthetic original42 setup; they are not target43 Ready or live Editor acceptance. No actual product reader/Probe, Provider/IPC, Install, Remove, cleanup or process observation ran.

The Coder RESULT reports final PowerShell AST syntax, scoped diff-check and exact overlay PathProvenance PASS. C# was unchanged, so no new C# compilation was needed for this repair. The prior consumer ManagerUi test remains unchanged and was not rerun. Unity/EditMode, MCP, CUA and BatchMode remain NOT RUN.

## Findings and terminal handoff

No actionable source BLOCKER was found within the frozen wrapper-handoff scope. The two intent reads now carry the same explicit historical scope, and the Package-bound predecessor committed reader is used only after trusted-previous selection. Ordinary/current/ACTIVATING/real-removal boundaries remain strict in source and in the focused synthetic refusals.

- **FOLLOW-UP — synthetic evidence boundary:** the 32/27 cases are isolated production-function extraction with synthetic prerequisite/process identity and zero native children. They support source and fixture behavior, not live Unity or real removal acceptance.
- **FOLLOW-UP — separate runtime gates:** MissingPrerequisite diagnostics, prior real removal-preflight exit 4, CleanupMono, consumer Journal/session/UI execution, delivery and release remain independent and unresolved. This repair does not claim to close them.

Only this report was written. No source, test, Payload, project or protected artifact was modified; no unchanged tests or gates were rerun. Findings return together to User/Planner and this targeted Verifier review terminates here.

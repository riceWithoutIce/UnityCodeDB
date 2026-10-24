# S29 version-transition observation — targeted read-only verification

Date: 2026-10-14, Asia/Shanghai. Role: task-scoped Verifier. Authority: VERSION-TRANSITION-OBSERVATION-TASK.md and stable Coder RESULT/SOURCE-SHA256; guarded review of the frozen behavior and nearest regressions only.

Disposition: **SCOPED_SOURCE_REVIEW_PASS_WITH_LIMITS / PS_SYNTHETIC_OBSERVATION_PASS / PATH_PROVENANCE_PASS / CONSUMER_EXECUTION_NOT_PASS.** No source BLOCKER was established. The selected42/target43 retained-observation cause is closed at source and isolated PowerShell evidence level. Full production emitted-output → Parse → blocked Journal → Session → UI execution has no admissible PASS. This report returns that exact gap; it grants no source acceptance, Unity acceptance, delivery, S29 recovery or release approval.

## Stable snapshot admission

HEAD remains `c6c2f036aa3c5d08a2334118d9049eff9dd3b875`; staged index is empty. All four worktree hashes match Coder SOURCE-SHA256 and the exclusive `coder-a1/com.rice.ai-codedb` overlay:

| Scoped file under com.rice.ai-codedb | SHA-256 |
| --- | --- |
| Tools~/codedb-instance-engine.ps1 | 9b44744eba5f9e987e49eaa6f4b46c07f070b2d03952a03bfddfd2f520fed957 |
| Editor/AICodedbManagerActionJournal.cs | 6d2937b3df6e9d5aebd454e4971200c1bace52c0c107216f8c9af7a3a1aa2090 |
| Tests~/test-codedb-host-payload-materializer.ps1 | fa180901ea1f10c4d7d1db899f1531698c03a62206cbbc6f204bf67f891012bb |
| Tests/Editor/AICodedbManagerUiTests.cs | cc9e994996a4a38a78f3ec51928bd6e8e9d6bbdc08298ab45f51ea13c963aaab |

Against the exact delivered startup-auth-boundary-c6c2f03 Package, scoped differences are engine +13/-4, Journal +10/-6, PowerShell fixture +91/-5 and ManagerUi test +77/-0. Production differences are confined to retained observation and two Journal message projections; no mutation or authority-reader body changed. The overlay's payload-manifest, materializer, HostPayloadMaterializer, ManagerWindow, ProjectIntegrationState and Lifecycle retain the delivered bytes. Target manifest hash is `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.

Existing protected-before/after manifests are byte-identical (SHA-256 `bf847d1bceabd89af56f1a6ee25379e4e8d93b4e2f62d4ffa983130ea7c56030`). Their recorded scope includes S29 references/runtime, dirty Payload, OwnerIdentityV2Status, delivered target, original42 and Manager action storage. This consumes the captured preservation envelope; Verifier did not rescan live runtime or recapture it.

## Historical ownership and strict admission

`Get-InstanceRetainedEffectsObservation` first authenticates removal intents, rejects duplicates, validates retained failed candidates and refuses live/ambiguous holders (:3377-3386). It then validates current/LKG and refuses any retained failed candidate selected by either (:3389-3392). Only a validated current selection with `GenerationDisposition == TRUSTED_PREVIOUS` chooses the historical branch (:3396-3399); missing, CURRENT or invalid selection is not relabeled historical.

The branch reuses `Get-ValidatedRemoveIntegrationSelection -OwnerIdentityVersion 2` and `Get-RemoveIntegrationActivationState -AuthorityKind VERSIONED_V2`. The existing selection reader binds project, instance path/id, v2 epoch, instance manifest and generation closure (materializer :10353-10430). Its runtime reader obtains authority from `Get-InstanceGenerationPackageIdentity` and the exact Package predecessor tuple, not from the activation record's old hash (materializer :10828-10845; engine :3642-3689). Missing/invalid predecessor runtime authority refuses. The historical activation reader passes that Package runtime context to the unchanged activation/operation reader, requires paired COMMITTED records, matching selection epoch, and matching instance/generation/immutable hashes; nonempty committed operation evidence also refuses (materializer :10885-10925).

The historical observation alone supplies the existing `HistoricalRemoval` switch to next-change admission (:3407). That read-only admission still validates relevant intents/current/LKG/retirements, enumerates every candidate, refuses unbound evidence or manifest drift, and retains its fingerprint boundary (:3288-3369). Ordinary callers retain their default false switch and target runtime contract. Pending current activation still blocks; pending historical activation fails the existing committed historical reader before SAFE.

The seven-field observation contract is unchanged. SAFE reports independent historical ownership; it emits no Ready, index release, handoff token or mutation permission. Install eligibility remains the existing explicit UNINSTALLED or first-install predicate (:3408-3412), so installed predecessor42 remains `install_eligible=false`. Ordinary availability still requires CURRENT and returns NeedsAttention/unavailable for TRUSTED_PREVIOUS (:5429-5442); target activation verification still requires CURRENT (:5040-5042). No Ready/classification body was changed.

## Journal projection and nearest regressions

The two modified Journal branches (:221-225 and :934-938) retain Conflict and their historical result/index attribution, but use `Retained effects safety check is blocked: <actual observation.Detail>` when an independently bound observation is unsafe. They retain the ownership-ambiguity wording for a genuine unowned candidate without a blocked observation. Original failed/unknown outcomes are not rewritten as success. `ReadEffectsOnly` already reports the actual observation reason and is unchanged (:958-973).

Foreign context remains rejected: Parse requires one complete successful seven-field observation, exact project/Package context, finite unique ids and consistent BLOCKED flags; Journal discards an observation with foreign context (:112-116). SAFE exempts only its authenticated candidate ids, while unrelated candidates retain the existing classifier/refusal (:976-1023). Holder and unknown-candidate refusals remain active before SAFE.

Session and UI bodies are unchanged. RestoreDurable retains Conflict as recovering evidence conflict, manufactures no original command result, and SAFE does not clear an unattributed pending action (:3636-3705). Fresh Install UI still requires SAFE + InstallEligible + NeedsAttention with no attention reason + SetupRequired + exact context (:2463-2480). Historical identity alone satisfies none of the missing operational conditions.

Historical removal preflight remains independent and unchanged. It retains Supervisor/selected-holder checks, authenticated owner/configuration plan, initial and lock-time handoff validation, historical next-change fingerprint and commit-time authority revalidation (materializer :10792-10809, :11530-11560, :11579, :11624-11631). This task does not prove the prior screenshot exit 4 cause or real removal success, and does not alter that route.

## Existing evidence and exact limits

Evidence root: `.artifacts/tests/s29-version-transition-observation/coder-a1`.

`fixture-a4.log` ends with `PASS cases=24 native_children=0 PocFixture=true external_process_observation=synthetic` and binds `fixtures/r-c56cb129`. These are 24 Check assertions, not 24 independent live actions. The fixture uses original42 to create a committed selected installation, then exact target43 authority and an independently serialized failed predecessor candidate/intent. Its context records original runtime `538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d` and distinct target runtime `69d731...55559a`. The final single-line SAFE/BLOCKED output is emitted by the extracted original materializer Write-Host statement, not prebuilt SAFE text.

The log covers historical SAFE without Install, same-version CURRENT observation control, strict ordinary next-change refusal, missing/wrong runtime authority, undeclared predecessor, wrong selected project/generation/epoch, wrong paired operation, wrong activation runtime, paired pending activation, immutable worker drift, live/unknown retained holder, unbound relevant candidate and restored fixture-byte digest. The synthetic machine prerequisite/process identity and PocFixture candidate verification are explicit boundaries; there is no live Provider, IPC or external process observation. Its initial installation READY lines describe synthetic original42 setup, not target43 Ready. The fixture did not exercise actual historical removal preflight.

Old attempts are preserved: a1 failed predecessor serialization after target prefix switch; a2 lacked the text-adapter contract function; a3 passed 23 checks; a4 added pending-activation coverage and exact production output capture and passed 24. The ledger attributes the two setup corrections and later evidence-completion change; no Verifier retry was performed.

Original-byte Editor and Tests compilation uses existing Unity 2022.3.62f3 csc/Bee response files. Read-only comparison found 400/366 lines, 32/7 expected source/output/reference redirects and zero unexpected option differences. Coder reports both exit 0/errors 0; retained Editor log has three existing warnings, Tests log one newline/no diagnostics. This is compilation, not Unity import or test execution.

`extractor/Extract.cs` selects original Roslyn nodes, retains method/assertion bodies and excludes only unused mutation entry TryAdmit from the extracted Journal. The test-owned SessionState adapter supplies isolated string storage; other product types resolve to the original-byte Editor DLL. Read-only checks of all 47 recorded source spans confirmed their recorded text hashes and presence in Seam.cs (47/0 mismatches). Audit reports `EXACT_ORIGINAL_NODE_TEXT_EQUALITY PASS nodes=47`. This establishes selected text integrity, not original enclosing-class/static-initializer execution or Unity SessionState behavior.

**Consumer chain: NOT PASS.** The only retained `logs/consumer-run-a1.log` records FileNotFound for `r-59d0824b/safe-observation-output.txt`. RESULT/execution-ledger declare a later final-fixture run reached SAFE Parse/Journal, then hit `Application.get_isBatchMode` internal-call failure through lifecycle-backed manifest parsing before completing blocked Journal → Session → UI. No second raw runtime log substantiates that claim. Therefore partial assertion success and the internal-call cause remain Coder declarations, not independently confirmed runtime evidence; the complete consumer test has no attributable PASS. This is an execution/evidence limitation, not an established production source defect. Unity execution remains NOT RUN.

The final Coder RESULT supplement and existing `logs/path-provenance.log` record the exact overlay `test-codedb-package-boundary.ps1 -PathProvenanceOnly` PASS, including helper projections=3, PS decoding/admission bindings=2 and Node caller bindings=2. The final supplement also records changed PowerShell syntax checks and scoped diff-check PASS. These are reused focused L0 records; no unchanged gate was rerun by Verifier. Existing `logs/tests-final-exact.log` has no diagnostics for Coder's declared final test recompile; no runtime assertion is inferred.

## Findings and terminal handoff

No source BLOCKER or actionable production repair was established in the frozen behavior and nearest regressions.

- **FOLLOW-UP — consumer execution evidence incomplete:** final runtime failure/partial assertion claims lack a corresponding preserved raw log; the full Parse/blocked Journal/Session/UI combination remains unverified. Keep NOT PASS/NOT RUN in any user disposition. The newly authored test primarily routes through ReadLegacyPending with an empty created index directory; the retained-current-index message branch has static review only.

Only this report was written. No source change, test/compile/extractor/provenance execution, Coder work request, Unity/MCP/CUA/BatchMode, real Install/Remove/Probe/Ensure, process control, cleanup, commit/export/reference switch/push/publication was performed. Actual Unity, real recovery/removal, continuous Ready and release remain NOT RUN/deferred. Findings return together to User/Planner; this guarded review stops here.

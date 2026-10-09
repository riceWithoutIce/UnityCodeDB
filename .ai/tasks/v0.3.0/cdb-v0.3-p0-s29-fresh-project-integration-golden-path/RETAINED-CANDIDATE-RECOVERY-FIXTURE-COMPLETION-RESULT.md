# S29 frozen-fixture completion result

2026-10-09. Stable Coder handoff: FOCUSED_PS_PASS.
The complete scoped PowerShell fixture now finishes. Overall frozen acceptance
remains PARTIAL / NO_SOURCE_PASS because C# execution and other declared gates
below are not run. Parent owns admission and independent Verifier scheduling.

## Changes and actual evidence

Only Tests~/test-codedb-host-payload-materializer.ps1 changed in this window:
1. Removed unsupported TargetRoot from the existing Invoke-InstanceConvergence
call; actual production convergence still runs with its existing signature.
2. Reused the existing exact installed-removal v1 document/writer/reader assertion
after actual fresh handoff in the repository-local focused fixture. This avoids
dependency on the unresolved OLD compressed-wrapper fixture without weakening its
hash or changing the runtime contract.

No production implementation edits, Payload writes or C# edits were made.
No additional fixture correction/retry was needed. PowerShell parse errors0.

Command:
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File
'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'
-RetainedCandidateRecoveryOnly
*> '.artifacts/tests/rc41-retained-candidate-recovery/ps-fixture-completion.log'

Actual shell output EXIT=0. Execution session13335 completed naturally.
The full retained log contains41 successful assertion labels and an actual
EMITTED_PROOF context. No test process was killed or externally managed.

## Original frozen cases and evidence boundaries

| Frozen case | Current evidence |
| --- | --- |
| Original failed INSTALL with advanced effect-shaped candidate | Actual focused fixture ran producer-derived config/adapter/index/log/lifecycle shapes through production classification. Native process identity uses existing synthetic seams; no Provider process ran. |
| Confirmed Uninstall / UNINSTALLED PENDING early v2 CURRENT wrapper | Actual focused scenario completed successfully; earlier publication-window log also records exact early v2 assertions. |
| Interrupted publication after real second intent commit | Actual focused scenario completed; final marker emission reached subsequent fresh Install. |
| Two retained closures / original older intent hash | PASS: two-retained-closures-preserve-old-intent=True. |
| Explicit disposition completion / original terminal hash and incomplete failure | PASS: explicit-disposition-completion-preserves-original-incomplete-failure=True. It remains the original failed result, not fabricated success. |
| Actual next-change reader/admission after completed disposition | Actual Assert-InstanceNextChangeAdmission completed before context emission and real convergence. |
| Fresh distinct Install handoff / older closure preservation | PASS: real-fresh-distinct-Install-handoff-preserves-both-closures=True. Actual production convergence ran. |
| Existing installed-v1 exact production reader | PASS: emitted-installed-v1-reader-compatible=True, using the existing assertion recipe. |
| Adjacent wrong project / generation hash / path / activation conflict / live or ambiguous holder / unowned mutable bytes | PASS in the existing focused classification suite; corresponding labels checked True. The aggregate successful run covers41 assertions. |
| Current-selection conflict neighbor | Existing authored loop runs this together with activation conflict and complete suite exited0. A summary query mistakenly searched conflicting-current.json and returned False; no individual current filename assertion is claimed from that incorrect label search. |
| Advanced-specific pending mismatch / false receipt or intent hash / full C# wrong-proof consumers | NOT independently executed in this window. Authored consumer coverage is not runtime acceptance. |
| Early v2 ABSENT / OLD wrappers and wrapper-transaction interruption | NOT RUN in this focused CURRENT window. Existing earlier OLD compressed-wrapper byte/hash failure remains preserved and is not relabeled PASS. |
| Actual PS emitted final resolved marker context | PRODUCED. The preserved fixture subsequently completed fresh handoff, so C# can inspect actual PowerShell evidence in the resulting state. |
| C# journal/history/session release, original failed/incomplete projection and wrong-proof refusals | Authored tests remain; C# execution and compile NOT RUN. |
| C# lifecycle cached preflight / cancellation / Manager presentation | Authored test remains; C# execution and Unity presentation NOT RUN. |
| Exact extracted Package parity | NOT RUN; no export authorized or performed. |
| Real project / receipts / Provider / external process operations | NOT RUN and prohibited; repository-local synthetic context only. |
| Unity / runtime / device / performance / release acceptance | NOT RUN. |

This is a producer-derived fixture plus actual production reader/writer/
classification/convergence evidence, not an actual producer execution or a
real-project recovery. No successful result is inferred for the unrun gates.

Actual emitted context:
G:\RiceProgram\UnityCodeDB\.artifacts\tests\rc41-retained-continuation-eac47b87fe14472f8715bfda7a440307\emitted-record-context.json
Preserved fixture:
.artifacts/tests/rc41-retained-continuation-eac47b87fe14472f8715bfda7a440307

## Stable source identity

Snapshot:
.artifacts/tests/rc41-retained-candidate-recovery/fixture-completion-source.sha256
SHA256 44d592d02a4a28c99428310241b71e45b5b8921aefb80985b1352bdc616e02fa.

Only the focused test hash differs from the prior publication-fix snapshot
2b5fbab23ac7b77845ca261b9165bfadf40fb831d3c5a3c72cf7f11e72b0059e.
All other10 file hashes remain stable. Actions.cs is unchanged.

```text
cd84670a62ea4fe25e2e4406f1aaab10400bd05481bc1132e8a2e0359c98798e  Tools~/codedb-instance-engine.ps1
fe6510d3e9d7c59a437f38dd9c3a18d89f29e89022b4df8c7752092b995d9d41  Tools~/materialize-codedb-host-payload.ps1
f8b7db6134658ba88e82e04947a5cfec420f16145dba68d6b6efe81c217b7693  Editor/AICodedbManagerActionJournal.cs
1a6809780f87679cbfc2087bfefeb54ea16605c96c2b6486c0bae71de7f4d264  Editor/AICodedbManagerWindow.cs
ab117a4335eb07bc67927899fee019033b4b6878b90292d2d56dccb62c320ec9  Editor/AICodedbEditorLifecycle.cs
fe354865c3e8a7f5023f92fe2726a836da02785e7c71f920b1c44c98f64d3007  Editor/AICodedbHostPayloadMaterializer.cs
3d57d7c463aab77dd539890f084dea6452b2f42f6471d9e0003ab6def3c3f1ff  Editor/AICodedbActions.cs
df2b34783992ffa6473dcb85c71e6072c30b999ca13a42cbffde7b43e8050c61  Editor/AICodedbProcessRunner.cs
e46ae6549acf4100548e5874a1f0ab378c5cdabf67e6c9b2b387c08e75c28d32  Tests~/test-codedb-host-payload-materializer.ps1
035791251a75afd614ef7d5893d1a6e5412528285061ee0ac6dcb7beff9c0365  Tests/Editor/AICodedbManagerUiTests.cs
ccb017209dc7e85cecb886d06134947fc3f347b17ad2ec33cc2f850780547c18  Tests/Editor/AICodedbEditorLifecycleTests.cs
```

## Budget and preserved limitations

Current directed window used two fixture adjustments, one focused test run and
one parser check. Elapsed collection interval was approximately
297seconds, within the20minute target.
Returned UTF8 read-output ledger: 16175bytes, below16384bytes.
Every selected read result was checked before emitting and below4096bytes/call.
No whole source/RESULT or large base64 output was emitted; no new budget requested.
Earlier stopped reports and per-call breaches remain unchanged.

No Unity, real state/process management, export, commit, remote operations or
new agents. Protected Payload was not edited; no new aggregate baseline claim is
made in this window. Stop at this stable evidence for Parent admission and a
separate independent Verifier decision.

# S29 retained-candidate publication fix result

2026-10-09. Coder stable handoff: **PARTIAL / NO_SOURCE_PASS**.
This window continues the authorized source fix from admitted snapshot
cd69e7175bf741116e80e15599ed0d82f13850b2a214063780ea29cab2bf60c5.
It does not supersede earlier stopped reports or their disclosed deviations.

## Concrete repair and actual result

One causal production correction was applied before this resumed segment:
Tools~/materialize-codedb-host-payload.ps1, Publish-FailedCandidateEffectsRetained.
An already existing pending disposition now goes through the bounded strict JSON
reader, exact field-count and every-field comparison except observed_at_utc;
the original timestamp is parsed and existing pending bytes are reused.
Publication still uses the strict durable writer for new pending bytes and the
existing final Move. The durable helper itself was not loosened.

The existing focused PowerShell scenario naturally exited 1. Actual log evidence
shows the repaired interrupted-publication transition now completed:
- actual intent commit happened before the intentional disposition interruption;
- two retained closures preserved the previous intent;
- FAILED_CANDIDATE_EFFECTS RETAINED was published;
- explicit-disposition-completion-preserves-original-incomplete-failure passed.

The next existing fixture command failed with NamedParameterNotFound:
"A parameter cannot be found that matches parameter name 'TargetRoot'."
No correction was attempted after the parent instructed freezing on insufficient
or failed evidence without another source-location read/window. No full source
pass, independent verification, compile, Unity or release acceptance is claimed.

## Frozen acceptance status

| Frozen case / evidence boundary | Status and actual limit |
| --- | --- |
| Early CURRENT wrapper v2 logical Uninstall | Actual focused log passed production-confirmed-logical-removal-PENDING, emitted-v2-identity-no-fake-activation-fields, actual-wrapper-observation-separated-CURRENT, actual-intent-consumer-retains-lease-and-candidate. This is a scoped source fixture, not real-project recovery. |
| Interrupted advanced candidate disposition completion | Actual focused PASS for the repaired transition and preserved original incomplete failure. |
| Second retained closure with unchanged old intent | Actual focused PASS in the same scenario. |
| Pending mismatch / false receipts / false intent proof refusal | Authored coverage exists in the stopped draft; complete current execution/read evidence is unavailable. NOT COMPLETE. |
| Same next-change reader / admission after completed disposition | Test stopped at the next fixture command with TargetRoot binding failure; NOT COMPLETE. |
| Fresh distinct INSTALL / READY / COMMITTED wrapper handoff | NOT RUN to completion in this window. |
| All adjacent advanced unowned/hash/project/current/live-holder refusals | Complete current suite proof NOT AVAILABLE. Do not infer PASS from the early v2 labels. |
| Earlier v2 ABSENT and OLD wrapper scenarios / interrupted wrapper restoration | NOT RUN in this RetainedCandidateRecoveryOnly window. The earlier OLD compressed-wrapper fixture mismatch remains unresolved evidence. |
| Existing installed-v1 reader regression | NOT RUN. New focused helper returns before the legacy v1 assertion. |
| Actual final emitted record context for authored C# consumers | PRODUCED and path fields read from actual emitted-record-context.json. The helper subsequently failed before fresh Install handoff, so this context covers the UNINSTALLED retained disposition only. C# execution remains NOT RUN. |
| C# journal/history/session original failed outcome, wrong hash refusals and release consumer tests | Authored draft only; execution NOT RUN, no compile proof. |
| C# lifecycle cached preflight / cancelled dispatch presentation | Authored draft only; execution NOT RUN, no compile proof. |
| Exact extracted Package reader/writer parity | NOT RUN; no export authorized or performed. |
| Real consumer receipts / Provider / process interactions | NOT RUN and prohibited in this window. Native identity seams only. |
| Unity / runtime / device / performance / release | NOT RUN. |

Fixtures are producer-derived shapes with production classification/readers;
they are not a real Provider run or a runtime/adapter producer integration.

## Command, logs and stable source

Command (repository working directory):
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File
'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'
-RetainedCandidateRecoveryOnly
*> '.artifacts/tests/rc41-retained-candidate-recovery/ps-publication-fix.log'

Actual EXIT=1. Execution session19661 completed naturally; no process was killed.
Full verbose evidence remains at the log above. Preserved failed fixture:
.artifacts/tests/rc41-retained-continuation-379fb8329d724102adf96d72c99b66a7

Actual emitted C# proof context exists at that fixture root's
emitted-record-context.json. It references the preserved synthetic receipts,
resolved-action marker and repository Package for action
28fdd85bc1b345e5955ae0f480efa12f; it is not a fresh READY handoff context.

Fresh11-file snapshot:
.artifacts/tests/rc41-retained-candidate-recovery/publication-fix-source.sha256
SHA256 2b5fbab23ac7b77845ca261b9165bfadf40fb831d3c5a3c72cf7f11e72b0059e.
Only the materializer hash differs from the admitted prior11-file snapshot.
Actions.cs remains unchanged.

```text
cd84670a62ea4fe25e2e4406f1aaab10400bd05481bc1132e8a2e0359c98798e  Tools~/codedb-instance-engine.ps1
fe6510d3e9d7c59a437f38dd9c3a18d89f29e89022b4df8c7752092b995d9d41  Tools~/materialize-codedb-host-payload.ps1
f8b7db6134658ba88e82e04947a5cfec420f16145dba68d6b6efe81c217b7693  Editor/AICodedbManagerActionJournal.cs
1a6809780f87679cbfc2087bfefeb54ea16605c96c2b6486c0bae71de7f4d264  Editor/AICodedbManagerWindow.cs
ab117a4335eb07bc67927899fee019033b4b6878b90292d2d56dccb62c320ec9  Editor/AICodedbEditorLifecycle.cs
fe354865c3e8a7f5023f92fe2726a836da02785e7c71f920b1c44c98f64d3007  Editor/AICodedbHostPayloadMaterializer.cs
3d57d7c463aab77dd539890f084dea6452b2f42f6471d9e0003ab6def3c3f1ff  Editor/AICodedbActions.cs
df2b34783992ffa6473dcb85c71e6072c30b999ca13a42cbffde7b43e8050c61  Editor/AICodedbProcessRunner.cs
d1fde2caedf8e7f3edd9e8e4ea23ce540eca799196ba05d0047a50dab1136433  Tests~/test-codedb-host-payload-materializer.ps1
035791251a75afd614ef7d5893d1a6e5412528285061ee0ac6dcb7beff9c0365  Tests/Editor/AICodedbManagerUiTests.cs
ccb017209dc7e85cecb886d06134947fc3f347b17ad2ec33cc2f850780547c18  Tests/Editor/AICodedbEditorLifecycleTests.cs
```

No Payload writes were performed. Current enumeration has417 files.
This segment recomputed a local alternate aggregate
f0ec37ada78ed0be02bfd22ba71e0655188f604ace0eefbfc5f0ef2ba96bebcb
(Payload-root relative paths, forward slashes, lowercase file SHA, UTF8 LF with
trailing LF). It did not reproduce the prior digest's exact recipe
d395508812c306439d4c392ab26d492bd2346e579f64c0d563f67a697c7bb84a;
therefore this report does not claim a newly verified equal protected-Payload
aggregate. There were no consumer operations, Unity launches, commit, export,
remote writes or additional agents.

## Window deviations and stop

At most two corrections were allowed: one was applied; no second correction.
Recorded resumed elapsed test/collection interval was approximately139seconds;
the pre-summary part of the same window also remains part of its timing.

Two resumed source-location calls were overbroad:
- rg location search returned8107 UTF8 bytes and was tool-truncated.
- combined source ranges returned12907 UTF8 bytes and were tool-truncated.
Both exceeded the6KiB per-call limit; necessary complete verification cannot be
claimed from these outputs. They were disclosed immediately and source reads
stopped. No retrospective compliance is claimed. Cumulative returned read-output
ledger at freeze is 31047 UTF8 bytes, including the inherited2923-byte
publication-task read and its resumed reread. Total remains below32768bytes;
this does not cure the per-call breaches. Output from hash/log follow-ups was
checked before emitting. Earlier continuation/initial breaches remain preserved
in their original reports.

Stop at this stable PARTIAL snapshot. Original failed result is still failed.
Parent/User owns the next decision. This handoff is not eligible for SOURCE_PASS
or a successful frozen acceptance declaration.

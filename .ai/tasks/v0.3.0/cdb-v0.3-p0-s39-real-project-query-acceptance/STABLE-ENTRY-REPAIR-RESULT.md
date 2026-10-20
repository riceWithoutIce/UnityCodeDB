# S39 stable-entry repair result

Date: 2026-10-20. Status: SOURCE_FOCUSED_PASS.
Workflow: codedb-workflow-v2 revision 2.7; NORMAL / DURABLE_SESSION.
Base HEAD: ccf75ae. Changes remain uncommitted in the existing dirty worktree.
No independent Verifier was requested or dispatched.

## Resulting behavior

The activation transaction publishes the Package-owned shared instance decoder
before the stable wrapper and final instance selection. Its pre-image, staged
bytes and rollback use the existing transaction. Missing dependencies can be
published during clean activation; existing unknown/drifted files are refused.

PowerShell, Supervisor and C# operational readers validate the imported decoder
against authenticated selected-generation bytes. Historical self-contained
wrappers retain their original closure. C# historical removal retains its
missing-path semantics without accepting an existing drifted dependency.

Legacy retirement preserves both bootstrap files. Explicit removal inventories
authenticate the dependency and existing transactions remove it. Failed-candidate
snapshots treat the decoder as shared bootstrap: every observation rechecks its
ownership, fixed shared ancestors can appear during Install handoff, and old
serialized dependency observations/fingerprints remain unchanged.

Candidate-worker probing remains. A second probe uses the real stable entry after
activation commits. Failure reports BLOCKED / INSTANCE_STABLE_ENTRY_FAILED /
PENDING, preserving COMMITTED activation, selected pointer and candidate effects.
It does not emit the final Ready outcome or claim rollback. Both probe launchers
select the first Node application on PATH; the local runner exposed two Node
applications and a multi-result Source value could not bind to FilePath.

## Focused evidence

Canonical run: `.artifacts/tests/s39-stable-bootstrap/r-feec0c06/`.
Receipts: `result.json`, `run.log`, `stable-entry-success.json`,
`stable-entry-missing.json`. Earlier task-owned runs contain diagnostic fixture
failures and are not additional acceptance attempts. Baselines of the seven
previously existing edited files remain under the family's `baseline/` directory.

| Evidence | Result | Boundary |
| --- | --- | --- |
| PowerShell AST, three changed PS files | PASS | Syntax only |
| Node syntax, Supervisor and new JS fixture | PASS | Syntax only |
| Scoped whitespace check | PASS | Edited production/docs surface |
| Production PS publisher/readers/lifecycle/rollback | 25 checks PASS | Synthetic prerequisite, candidate preparation and process observations; no Provider |
| Production Supervisor selected reader | 3 cases PASS | Unchanged function bodies in VM; no daemon or process/network APIs |
| Real stable wrapper / parser / bounded probe | 2 cases PASS | Synthetic generation worker; initialize/tools/status/query success and missing-decoder pre-initialize failure |
| Production PS stable-entry probe/native collector | 1 case PASS | Real Node child and actual wrapper; synthetic downstream worker |
| Standalone C# contract compilation/execution | 6 cases PASS | Real runtime contract, strict JSON and control identity; fixture filesystem boundaries; not Unity compilation |

The PS cases cover dependency-before-wrapper/pointer ordering, missing/drifted
operational closure, unknown-file refusal, authenticated removal, failed-effect
reauthentication and historical snapshot preservation, legacy retirement,
rollback of both newly created and replaced bootstrap files, and post-commit
failure retaining committed selection/effects with BLOCKED outcome.

The retirement-loop cases supply synthetic marker/transition reader inputs.
The removal case uses the actual authenticated inventory and transaction
publisher. These are focused lifecycle cases, not a real project uninstall.
Full automatic cleanup remains PENDING in the convergence fixture because the
fixture deliberately refuses external process observation; no cleanup-runtime
acceptance is claimed. All spawned fixture probes exited; no broad process
enumeration/termination or external client retry was performed.

## Input provenance and delivery limitation

Initial fixture validation refused the current development payload with
`Payload source hash mismatch: Generations/poc.42/coordinator/codedb-watch-coordinator.mjs`.
That pre-existing dirty payload and its manifest were preserved. PowerShell 7
also failed the existing strict JSON/object boundary; production PS scenarios
use Windows PowerShell 5.1, and PowerShell 7 is used only for standalone C#.

The successful fixture reads immutable input from the already frozen external
delivery `d856a8f/com.rice.ai-codedb/Payload~` (preview.5 / poc.43), then writes
only task-owned repository fixtures. Its manifest SHA-256 is
`69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
New source Tools/C# plus frozen immutable payload are a behavioral fixture, not
proof that the current development Package is exportable or released.

The canonical stable wrapper and decoder were not edited; current hashes remain
`7f209316005ffd02bccd01c78ae1773d695694a77817d99f1753041b6aef4399` and
`de2366310169830738ceef4cba4d24e2b54da72f6a8a11ec8c564b4dc298d07f`.
No generation, payload manifest or Package version was rewritten by this repair.

## Changed source snapshot

Paths are relative to `com.rice.ai-codedb/`.

| File | SHA-256 |
| --- | --- |
| Tools~/codedb-instance-engine.ps1 | d251bd60595cf48f4c5b4ad9c06d4b75ec8ffa5a9ab816e6b153baa65c5fbf5f |
| Tools~/materialize-codedb-host-payload.ps1 | 9aae07427d5a567a059a692ca0992300adca8170614d2df7a3d61f5832c4ab7e |
| Tools~/codedb-project-supervisor.mjs | 6a076ce6cfbf73c87f271ad42db85657d6793352f366b0adc2da63ad1ad122d8 |
| Editor/AICodedbPackageRuntimeContract.cs | 1f233834e3efbf6bfd836edf3932d497d8341097b2a6e0a81e6dec5faaf50193 |
| Editor/AICodedbHostGenerationStore.cs | c337c2882f9ea271c337cc181c8943b683b5cbd51ac80a39ba58b501d45de1df |
| Editor/AICodedbProjectIntegrationState.cs | 8bb36b2ee0befc26dc4b716ee6d2712770d91d59771cf144034776d5c730c734 |

New harnesses: `Tests~/test-codedb-stable-bootstrap.ps1` and
`Tests~/test-codedb-stable-bootstrap.mjs`. The project-integration/reinstall
contract contains the narrow stable-entry closure amendment.

## Remaining gates

S39 real-client query remains BLOCKED, with original status/query call counts
zero. The external project, delivered artifact and failed attempt 01 were not
modified or replayed. Unity compilation, real Provider, Codex tool exposure,
response identity, client lease, performance, cross-version upgrade and release
acceptance remain unrun.

Next route: agree the exact source/payload delivery closure and recovery of the
existing consumer, then authorize the next client attempt. Existing
`CodedbTest_0` remains suitable for regression; no new Unity project is needed
for that route. Its missing dependency has not been repaired by this source-only
task. Normal operational readers now fail closed on that state, so do not
assume ordinary Reinstall/Uninstall will bypass the missing dependency. Any
scoped bootstrap restoration/removal requires its own exact recovery plan.
A separate real clean-install acceptance, if requested, remains a later gate;
the isolated clean-publication fixture does not replace it.

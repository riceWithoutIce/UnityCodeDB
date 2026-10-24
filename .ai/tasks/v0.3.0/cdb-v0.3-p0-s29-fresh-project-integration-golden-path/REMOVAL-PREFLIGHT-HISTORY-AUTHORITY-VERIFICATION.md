# S29 v2 removal history authority — independent verification

Date: 2026-10-15 (Asia/Shanghai)  
Base: `544be4f7e339acefb47137b188cdc85e22483efb`  
Disposition: **SOURCE_AND_ISOLATED_PASS**  
Findings: **0 BLOCKER, 0 FOLLOW-UP** within this GUARDED scope.

## Admission and review boundary

The TASK, authorized PLAN/addendum, diagnosis, Coder RESULT and source hashes,
workflow path gate, workspace contract, roadmap runtime-identity section, and
the directly coupled prior process-identity record were read. The Coder had
terminated and supplied a stable three-file snapshot before this independent
read-only review. No source was edited, test or compiler was rerun, Coder was
not contacted, and no Unity, MCP, IPC, product process, cleanup, delivery or
release action was performed. The only write is this report.

The working tree was already dirty outside the task allowlist. Those changes
were preserved. HEAD remains the admitted base and the index remains empty.

The three changed Package files independently hash to the Coder snapshot:

| Path relative to `com.rice.ai-codedb` | SHA-256 |
| --- | --- |
| `Tools~/materialize-codedb-host-payload.ps1` | `2fb1ab328213bda1a2a3c45d4891604deefa55fdb1a88e0c4f6dc78ed1f5b99a` |
| `Tests~/test-codedb-host-payload-materializer.ps1` | `397635c916d6a1fdb8b1cf6d1eb3baa8008b4565553d0f10acc1d1f9b319134d` |
| `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs` | `cf8ebddd4ac0b10d2e9b7e7fee9888d5762ab3e19fd50c99cf1363707be6c0eb` |

The frozen evidence manifest contains 24 entries; every entry independently
matches its recorded SHA-256. The protected before/after snapshots have the
same SHA-256 (`8be038a346061846b224a4a1c1d9327ee0e38b25993f2261598a0fbf9e040c53`),
and the retained comparison reports 5,818 protected entries unchanged.

## Frozen behavior verified

`Get-RemoveIntegrationHistoryAuthorities` derives at most two authenticated
tuples: the selected instance origin and the one exact current Package origin
when the selected instance is a validated predecessor. It deduplicates the
current tuple, rejects same-hash generation ambiguity, missing/invalid current
identity and non-unique transitions, and does not scan directories or accept a
record's self-declared trust. The tuple carries target generation, runtime
contract hash and disposition together.

Terminal operation validation retains its existing schema and project,
namespace, selected-instance, terminal-state, child-process and preserved
history constraints. Since that schema has no target or activation fields, its
runtime hash is accepted only from exactly one derived history authority. Owner
validation similarly requires target, hash and disposition from one tuple while
retaining activation epoch, control identity, pairing, fingerprint and process
rules. Legacy, v1, generic, lease, holder and ordinary activation/Install/Ready
paths remain unchanged. Handoff, lock, before-mutation, before-commit, terminal
and recovery paths consume the same authority validation.

## Mandatory and directly coupled evidence

Evidence root: `.artifacts/tests/s29-removal-history-authority/coder-a1`.
The following are inspected Coder results; they were not rerun by this Verifier.

| Gate | Attributable result |
| --- | --- |
| PowerShell syntax, scoped diff and exact Package `PathProvenanceOnly` | PASS — `l0-a1.log`, `path-final617.log`, and `source-overlay-check.log`; final overlay is exactly 617 files with only the three allowed source changes. |
| Original-byte Editor and Editor.Tests compilation | PASS — `Rice.AICodedb.Editor-compile-a1.log` and `Rice.AICodedb.Editor.Tests-compile-a1.log`; warnings are retained and no compile errors appear. |
| Isolated production removal call chain | PASS200 — `scenario-a1.log`; copied-project-only and `native_children=0`. |
| Exact C# diagnostic/cache/UI consumer seam | PASS — `seam-run-a1.log`, `seam-compile-a1.log`, `exact-ast-binding.txt`, `Runner.cs` and extractor; original 13 members/assertions remain bound. |
| Source scope and protected state | PASS — `source-overlay-check.log`, `protected-comparison.log`, independent hash checks above. |

The PASS200 fixture covers current and trusted-predecessor mixed history,
current/stale owners, cross target/hash/disposition combinations, foreign and
unknown authority refusal, lock/mutation/commit provenance drift, rollback,
terminal/recovery retained-history checks, and the existing child/process,
active/malformed/holder and namespace refusals. The production refusal is
consumed by the existing bounded diagnostic, cache and UI path; no new secret,
argv, delete target or persisted authority is introduced.

## Attempts, limits and stop

The first local scenario shell was interrupted by an accidental Ctrl+C before
terminal assertion output. Its partial fixture remains preserved and is not
claimed as PASS. The unchanged source was then run in `scenario-a2` and
completed PASS200; the retained log name is `scenario-a1.log`, while its final
root identifies `scenario-a2`. The first seam invocation rejected setup because
its copied expected parent still named scenario-a1; one input-binding-only
correction changed it to scenario-a2, after which the seam passed. No semantic
assertion or production correction was made.

The canonical directory was observed with one additional untracked Unity
`.cs.meta` file. The accepted ZIP and final overlay are both 617 files; the
sole meta file was removed only from the owned overlay, with canonical input
untouched. Compilation, seam and PASS200 ran against the 618-file tree before
that mechanical correction. The final 617 overlay differs from that tested
tree only by this non-code meta file; no retroactive compile or semantic PASS
is claimed. The affected path-provenance gate was rechecked and passed.

Bootstrap cleanup remains a synthetic `PENDING` warning, not cleanup PASS.
Missing child records, actual history admission/removal unlock, Unity/runtime,
device/performance, real product processes, human acceptance and release remain
explicitly deferred or unrun. These are frozen scope limits, not findings and
do not waive any mandatory source or isolated gate reviewed above.

No further in-scope work remains. Findings are returned once and review stops;
source acceptance and delivery authority remain with the User/Planner gates.

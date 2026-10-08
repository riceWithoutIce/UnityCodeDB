# S29 operation result semantics implementation plan

Date: 2026-10-08. State: SOURCE_EXECUTION_AUTHORIZED.
User approved the semantic agreement and explicitly said "同意 请你开始执行".
Mode: FAST_SUBAGENT for this bounded source/review window only. Delegation:
STANDING_WORKFLOW / ACTIVE, also explicitly approved for the proposed pipeline.
Human Unity and later delivery remain separate evidence stages.
Baseline HEAD: 3b09859045d0d4547d9ba2cef332a550e8530f99.
Branch: codex/v0.3.0-legacy-workflow. Preserve inherited dirty state.

## One outcome

Close the diagnosed writer/consumer/test mismatch in one S29 source task.
Recognize the authenticated historical Install/DryRun/Upgrade chain with the
contract's permitted BLOCKED or FAILED shapes. Return the original unsuccessful
Install and its PENDING effects, through both direct recovery and resolved-history
restoration. Do not infer successful integration or permission for a new mutation.

Authority: Documentation~/v0.3.0-p0-host-action-execution.md, S29 Operation Result
Semantics Agreement. Evidence baseline: HISTORICAL-RECEIPT-OUTCOME-DIAGNOSIS.md.
No whole-Host redesign, new protocol/schema, runtime relocation or journal rewrite.

## Frozen source ownership and allowlist

Paths relative to com.rice.ai-codedb/:

- Editor/AICodedbHostPayloadMaterializer.cs: shared semantic entry alongside the
  existing command-result model/parser; retain strict decoding responsibility.
- Editor/AICodedbActions.cs: consume the shared Install classification.
- Editor/AICodedbProcessRunner.cs: consume the shared Upgrade classification;
  retain existing authenticated chain recognition and original-result ownership.
- Tests/Editor/AICodedbManagerUiTests.cs: actual-result and historical-chain
  regressions, journal/session/removal-gate coverage and adjacent negative cases.
- Tests~/test-codedb-host-payload-materializer.ps1: focused production-output
  evidence route using actual writer function bodies, not copied serialization.

Read-only direct dependencies: ManagerActionJournal, ManagerActionSession in
ManagerWindow, existing test workspace/strict JSON helpers, the materializer
production script, and directly invoked functions needed by its result writer.
Journal/Manager behavior is verified through existing consumers; changing those
files is not assumed necessary. Existing immutable generations, payload/pointer
metadata and production writer remain outside the proposed write scope.

Coder owns RESULT-SEMANTICS-RESULT.md and RESULT-SEMANTICS-IDENTITY.json here;
Verifier owns RESULT-SEMANTICS-VERIFICATION.md. Planner owns this plan and TASK.md.
Any newly proven design or ownership expansion returns to Planner as one finding.

## Producer-to-consumer evidence map

| Boundary | Production authority | Consumer | Required evidence |
| --- | --- | --- | --- |
| Command-result bytes | Write-MaterializerCommandResult in Tools~/materialize-codedb-host-payload.ps1 | AICodedbMaterializerCommandStatusParser | Actual writer output parses with original fields retained |
| Completed unsuccessful operation | Action-specific combinations in the Host Action contract | Shared semantic entry, Actions and ProcessRunner | BLOCKED and FAILED accepted only in allowed combinations; contradictory or unsupported results rejected |
| Three-stage interpretation | Validated admitted/claim/terminal records | RecoverManagerAction | Real-shaped NEEDS_ATTENTION DryRun plus original Install and refused Upgrade; original result/PENDING preserved |
| Resolved history and next-action boundary | Existing journal and original result | Journal -> session -> removal admission/presentation | No false marker conflict for supported shape; no automatic replay or bypass of current safety admission |

Required negative coverage is bounded to the changed predicates and their chain:
exit/outcome disagreement, wrong action/phase/scopes/cleanup, incomplete terminal
output, and existing duplicate/extra/unbound-stage refusal. Reuse existing tests;
do not enumerate unrelated formats or introduce a general test platform.

## Evidence execution and delivery

Use an isolated focused harness to obtain actual production writer bytes. It must
not execute the materializer's live Install/Upgrade entry or operate on real project
state. The existing PowerShell test harness has function-AST extraction machinery;
reuse that route where applicable, retaining writer dependencies and defaults.
The real C# parser, semantic classifier and recovery consumers must consume the
generated output. Handwriting equivalent JSON is insufficient for this boundary.
Historical-shape fixtures separately preserve the diagnosed field relationships
under fixture-owned identities, never real machine journal/project paths.

Before implementation, Coder identifies whether the direct closure already has
an executable isolated C# harness. If not, report the execution gap and propose
the smallest route using existing Editor tests; do not substitute static source
matching for semantic PASS or invent an external compiler/test platform. Any
dependency on a later human Unity run must remain explicit in the handoff and
delivery decision. Source review alone does not close that gate.

All test files/outputs stay within the existing test-workspace contract. Preserve
the accepted short-path layout, full semantic identities and Unity Test Framework
entry compatibility. No system TEMP, hardcoded drive fixture or live record writes.

Run only relevant focused checks, diff validation and final source fingerprints.
No unchanged full-suite repeats; follow existing workflow attempt/output bounds.
An independent Verifier reviews the stable snapshot, this finding and adjacent
regressions once. Findings return to the user together; no concurrent Coder edits.
Use the standing FAST_SUBAGENT pipeline when source execution is activated:
one Coder, then an independent read-only Verifier; no child delegation.

After source acceptance, apply the user's standing prerequisite authorization to
the normal scoped commit/export/extracted-artifact checks. Do not switch a live
Unity project's reference until its closed state is confirmed. Preserve separate
byte and semantic closure evidence. Consolidate the later human test inventory and
Manager observation into one cycle; exact method/case counts come from final code.
No new permission prompt is needed for prerequisites already authorized, but no
real Install/Remove/replay is implied. S29 remains PARTIAL until its separate real
integration acceptance is actually achieved.

## Active execution bounds

One depth-one Coder, then one independent Verifier after a stable fingerprinted
handoff. Inherit parent model and effort; no child delegation or cross-session
messages. Coder source window 60 minutes; Verifier 30 minutes. Normal reads target
80 lines/4 KiB, searches 50 matches/16 KiB, total visible output 128 KiB per role;
summarize evidence instead of raw dumps. One initial focused evidence attempt plus
at most two failure-driven corrections; no rerun after unchanged PASS. No Unity,
MCP, BatchMode, live receipt inspection/mutation, process probes, install/removal,
commit/export or package-reference switch by either child.

Record source/static PASS separately from any unexecuted C# or Unity evidence.
If no existing isolated C# harness exists, author the bounded Editor tests and
report the pending human gate; do not leave authorized source work unfinished
solely because Unity is human-owned. New authority/design expansion or inability
to preserve safety invariants stops dependent work with a concise handoff.

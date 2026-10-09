# S29 retained recovery top-level entry closure

2026-10-09. FROZEN / IMPLEMENTATION_AUTHORIZED by user `好的 同意授权`.
FAST_SUBAGENT / STANDING_WORKFLOW ACTIVE; depth-one sequential Coder -> fresh
read-only independent Verifier -> Planner/User. Base:
a06944c1cb7e29ff0b2b209eebe6ca4fe502de85. Preserve all inherited dirty state.

## Original defect and coherent scope

REAL-RECOVERY-PREFLIGHT-20261009.md records the one actual read-only attempt:
UNINSTALLED/PENDING desired state rejects UninstallPreflight in the early switch
before its dedicated candidate/action/process validator. No safety preflight
was performed. The retained-path human tests PASS remain valid but did not
exercise this top-level dispatch. Current old candidates/receipts stay protected.

Make retained-candidate read-only UninstallPreflight reach its existing dedicated
validator while desired state is UNINSTALLED. Inspect and prove the adjacent
confirmed Uninstall entry follows the existing retained action/effect disposition
flow. Preserve no-reinstall policy for unrelated actions, mutation confirmation,
candidate/action/project/hash linkage, live or ambiguous process/holder refusal,
original failed/incomplete command result and immutable intent/history bytes.
No direct backend bypass, manual receipt repair, new schema, generation change,
broader historical framework, automatic replay or unrelated warning cleanup.

## Producer/consumer and evidence map

| Boundary | Existing owner | Required proof |
| --- | --- | --- |
| actual CLI parameters / UNINSTALLED dispatch | materialize-codedb-host-payload.ps1 top-level entry | dedicated read-only preflight reached rather than generic reinstall refusal |
| candidate/action/process/holder preflight | existing materializer and engine validators | correct retained action accepted only with real validator evidence; mismatch/unknown candidate refuses |
| explicit confirmed Uninstall | same entry -> Invoke-InstanceUninstall | current effects bound to existing original failed INSTALL, original failure preserved |
| resulting marker/intent | existing readers/writers, unchanged | receipt/hash/intent links preserved; no manufactured terminal or EOF |
| Manager preflight request | AICodedbHostPayloadMaterializer.ReadUninstallPreflight | calls the same production CLI action with original action id, no new UI action |

## Ownership and allowlist

Coder owns only necessary changes to:
- com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1.
- com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1.
- Optional focused new com.rice.ai-codedb/Tests~/test-codedb-retained-entry-routing.ps1
  if a standalone narrow harness avoids modifying the large existing fixture.
- RETAINED-ENTRY-ROUTING-RESULT.md in this folder.
- fresh ignored .artifacts/tests/s29-entry/ evidence and source.sha256.

Other production files are read-only. A necessary engine/UI/schema change
requires scope reassessment, not silent expansion. Planner owns task/contracts/
status/decision/delivery. Verifier owns RETAINED-ENTRY-ROUTING-VERIFICATION.md only.
No child agents, commit/export, downloads, Unity/MCP/CUA/BatchMode, real project
runtime/receipt access, process termination or remote writes by either child.

## Focused execution

Use Windows PowerShell5.1 and repository-local dynamically bound fixture roots,
short enough for legacy Windows/Unity paths. No system TEMP or fixed fake-drive
project roots. Exact production entry dispatch must execute, not another call
only to imported validator functions. Prefer actual CLI invocation with synthetic
owned identities. If liveness/service seams are required, document them exactly;
they may replace native services but not the top-level desired-state/action
switch, dedicated preflight, action binding or record decoding. Do not edit a
copied production body to manufacture reaching the validator.

Required bounded scenarios:
- UNINSTALLED + authentic retained candidate + matching action: preflight
  AVAILABLE after dedicated validators; compare fixture file bytes before/after
  to show no project/receipt changes.
- Same state + mismatched action or unknown candidate: BLOCKED, no mutation.
- Same state + live/ambiguous relevant execution: retain existing refusal (one
  directly coupled fixture seam is sufficient; no process inventory exposure).
- Existing explicitly confirmed Uninstall through actual entry produces retained
  disposition bound to original action; absent confirmation refuses before
  mutation. No fresh Install or physical deletion is necessary for this task.
- One representative disallowed automatic/reinstall action remains refused by
  unchanged no-reinstall policy; do not sweep all actions/formats.

Avoid repeating old PS39/41 or C#32 suites unchanged. Existing reader assertions
may be reused for emitted new marker links. Full Unity and real preflight are
separate evidence classes. Coder records command exit, scenario assertion counts,
seams/attempts, source snapshot SHA256 (changed paths plus protected three Payload
identities), base HEAD and unrun limits. Stop with stable bytes for review.

Standard window Coder30min / Verifier15min. Initial plus2causally corrected
non-Unity attempts per declared scenario; no blind reruns. Keep output bounded
<=6KiB/source read, <=50search matches, <=128KiB cumulative; report deviations.
Test wait120swarn/300sstop; do not terminate external processes. A structural
testability or semantic conflict triggers one consolidated reassessment, not
another generic harness or weaker proof.

## Handoff and real operation boundary

Independent review is only original defect and adjacent frozen regressions.
Findings return once to User, not direct Coder instructions. After acceptance,
standing pre-human grant covers Parent scoped commit/new immutable export/input
preparation; never overwrite old Packages. S29 currently open, no new normal-close
confirmation received. Reference switch/launch remains under existing human
environment boundary. Real retained recovery still needs its concrete reviewed
operation authorization after authentic current preflight passes. S29 PARTIAL.

# CodedbTest_2 delivery result — 2026-10-26

Outcome: `DELIVERY_PASS`. One delivery, exit 0, no retry or rollback.
User approved delivery and confirmed "已关闭，可以交付" immediately before it.
Paths use `<repository-root>` or the existing user-designated `<external-test-root>`.

- Candidate: `11056964da1143955ed69a067361622799e3d6f2`.
- Delivered exact validated Package to
  `<external-test-root>/Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
- All 669 source/destination file hashes and exact inventory match the accepted
  exported artifact. ZIP source hash reconfirmed:
  `8a3fcad610093f17eca062726cd5412ad47a64bf565e835690e69b9de8329ef8`.
- CodeDB reference in both `CodedbTest_2/Packages/manifest.json` and
  `CodedbTest_2/Packages/packages-lock.json` now:
  `file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
- Both references resolve to the delivered directory. Unrelated JSON bytes
  preserved by exact one-reference replacement; original file bytes backed up.
- Previous package directory retained, with no write to that destination.
- Registration, selected pointer and both existing probe hashes unchanged.
  Pointer SHA-256 remains
  `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.
- Primary source HEAD/index unchanged. Only task records/scripts added/updated;
  no commit or remote push in this delivery stage.

Evidence under
`.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/delivery-1105696/`:
`journal.json`, `receipt.json` (including before/after reference and protected
file hashes), and `preimages/Packages/manifest.json` / `packages-lock.json`.
`pre-open-diagnostics-baseline.json` retains the existing manager-transition
sidecar names/hashes before the human reopens Unity. No diagnostic files deleted,
global Editor.log read, UI observation or automatic observer started.

Package delivery does not establish runtime acceptance. Unity compilation,
Manager Ready, real MCP, EditMode and lifecycle acceptance remain NOT_RUN.
No Unity/MCP/component start, Install/Repair/Restart/Uninstall, registration,
pointer/instance/probe write or cleanup. Old package and backups remain available;
rollback requires the agreed explicit closed-Editor restoration step.

Next human step: manually open CodedbTest_2 and report compilation result and
Manager state after startup. Do not invoke installation as part of this package
switch. Any compile error or unexpected state is a new observed result for
bounded analysis, not permission for automatic repair/restart. Real MCP receives
its own bounded target-client task after the candidate Editor result is known.

## Human Editor result — 2026-10-26

User report after opening the delivered candidate: "没有报错 ready了".
Record as **HUMAN_CONFIRMED: no compilation errors reported; Manager Ready**.
This advances the preceding NOT_RUN Editor step on the basis of the user's
observation; no automated Unity launch, compilation or UI read was performed.
No startup duration, continuous stability, log suppression or EditMode result
is inferred. Real MCP, response identity and lifecycle gates remain unexecuted.

Next bounded client procedure is prepared in `TARGET-CLIENT-TASK.md` for the
user to forward to the existing CodedbTest_2 chat. The development chat does not
message that chat or substitute its other visible CodeDB services.

## Target client result — 2026-10-26

User forwarded the completed target-chat receipt: status=1 PASS, fixed
text_search=1 PASS, other MCP=0, retries=0. On-disk candidate binding and final
pointer stability PASS; response identity attribution LIMITED because formal
project_identity/instance_id/activation_epoch were not supplied by either tool.
Complete supplied raw response text and boundaries are in TARGET-CLIENT-RESULT.md.
The development chat did not rerun calls, independently inspect that chat,
or infer a new connection or loaded Editor code from this result.

Current stage: source/export/delivery PASS, Editor result HUMAN_CONFIRMED,
real client functionality PASS. Default-diagnostic publication in live Unity,
full candidate lifecycle and release acceptance remain open; no automatic
experiment, lifecycle action, commit/push or release follows from receipt intake.

## F01 output observation — 2026-10-26

Subsequent separately authorized one-shot read-only check passed: transition
sidecars 0 before open and 0 at snapshot; the current Editor.log's own single
startup command line binds it to CodedbTest_2, and the observed file contains
zero CODEDB_S12_EVIDENCE document records. Candidate compile/build success and
domain reload are present. See F01-LIVE-CHECK-RESULT.md for timing and limits.
This is bounded output evidence, not a continuous or exhaustive lifecycle test.
No further runtime action was performed; next staged acceptance is a human-owned
close/reopen cycle of this same candidate before the destructive lifecycle steps.

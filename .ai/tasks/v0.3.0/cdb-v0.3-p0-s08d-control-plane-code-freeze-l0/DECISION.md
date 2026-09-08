# Decision: cdb-v0.3-p0-s08d-control-plane-code-freeze-l0

Status: ACCEPT

## Disposition

- Human decision: ACCEPT the frozen S08d non-Unity L0 code-freeze evidence
  after Coder completion, Planner review, and GUARDED evidence-only verification.
- Decision date: 2026-09-07.
- Accepted HEAD:
  `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Accepted combined two-file patch identity:
  `aae922016172611d6742e7d878cf1d9e6378c617`.
- Accepted per-file identities:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`:
    `fbad2e20bf6059912a930d0db61ae54cfc154ad6`;
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`:
    `5af62c199883b33458b0b776e922b7cdaca202c5`.
- Accepted evidence: all eight declared L0 commands ran once in order and
  exited `0`; batch `1/1`, retry `0/0`, aggregate child wall time
  `253.7986394s` of `420s`, longest child `90.0205170s` of `180s`, complete
  untruncated output, and no reported fixture cleanup failure.
- Pre/post HEAD, combined/per-file identities, exact two-file Package status,
  and protected materializer cleanliness matched.
- `verifications/VERIFICATION-01.md` reported `PASS` with no `BLOCKER`, `P1`,
  `P2`, or `FOLLOW-UP` and did not rerun any command.

## Accepted Boundary

- The frozen non-Unity L0 gate is accepted for machine prerequisite,
  Uninstall/Install handoff, activation contract, activation transaction and
  recovery, holder-aware retirement, explicit obsolete-contract Reinstall,
  Supervisor runtime behavior, and Package/hash boundary coverage.
- The incomplete historical S08 attempts are not reused as current evidence;
  S08d supplies the complete `1/8` through `8/8` serial result.
- S08d itself changed no production or test file.
- Exact captured byte counts were unavailable. The accepted record preserves
  that limitation and reports only complete, untruncated output plus the tool's
  token count; it does not relabel tokens as bytes.

## Boundaries

- This decision accepts only the exact frozen non-Unity L0 evidence and its
  bound combined S08a/S08b/S08c snapshot.
- C# compilation, focused EditMode in `UnityValidationProject/`, Unity, Unity
  MCP, PlayMode, cold start, Domain Reload, real Manager/Supervisor/Codex/MCP,
  consumer/third-party Package, full regression, release, publication, and
  deployment remain `NOT RUN` / `DEFERRED`.
- Acceptance does not authorize commit, push, another test, Unity process,
  Unity MCP, publication, release, or deployment.

## Handoff

Current task: cdb-v0.3-p0-s08d-control-plane-code-freeze-l0
Current status: ACCEPTED
Next notification: UnityCodeDB v0.3 Planner / Human
Next action: align a separately authorized C# / Unity EditMode validation slice
using `UnityValidationProject/` as the only default EditMode project.
Human decision or authorization required: next-task creation and execution;
commit remains a separate optional human decision.

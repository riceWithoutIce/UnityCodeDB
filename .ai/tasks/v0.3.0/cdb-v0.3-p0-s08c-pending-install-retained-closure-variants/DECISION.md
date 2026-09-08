# Decision: cdb-v0.3-p0-s08c-pending-install-retained-closure-variants

Status: ACCEPT

## Disposition

- Human decision: ACCEPT the combined S08a/S08b/S08c frozen snapshot after
  Coder completion, Planner review, and GUARDED directed verification.
- Decision date: 2026-09-07.
- Accepted HEAD:
  `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Accepted two-file patch identity:
  `aae922016172611d6742e7d878cf1d9e6378c617`.
- Accepted per-file identities:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`:
    `fbad2e20bf6059912a930d0db61ae54cfc154ad6`;
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`:
    `5af62c199883b33458b0b776e922b7cdaca202c5`.
- Accepted Coder evidence: two-file AST parse exit `0`; one focused
  `-UninstallOnly` invocation exit `0`, wall time `105.4148265s`, batch `1/1`,
  retry `0/0`, complete output; two-file scoped `git diff --check` exit `0`
  with no output.
- `verifications/VERIFICATION-01.md` reported `PASS` with no `BLOCKER`, `P1`,
  `P2`, or `FOLLOW-UP`, and independently confirmed that the frozen identities
  did not drift.

## Accepted Boundary

- Completed-Uninstall fresh Install and pending-Uninstall Install handoff are
  accepted for the reviewed authority model.
- A present prior instance remains subject to complete retained-instance and
  committed-candidate identity validation.
- An absent prior instance is admitted only from the exact authenticated
  `UNINSTALLED + PENDING` transition, exact missing-path evidence, absent
  current/last-known-good selections, and unchanged committed contract/state-id
  evidence rechecked under the operation lock before activation.
- Candidate verification remains before selection and desired-state mutation.
  An obsolete cleanup bound to the old state id cannot delete the new selected
  instance or MCP state.
- The absent variant does not recreate the prior instance, mint retirement
  authority, stop a holder, or change the retained generation, lease, MCP/user
  configuration, or unrelated bytes.

## Boundaries

- This decision accepts only the combined S08a/S08b/S08c two-file snapshot and
  its frozen focused evidence.
- The final dynamic `-UninstallOnly` fixture directly covers the absent-instance
  variant. Present-instance and additional invalid, non-directory, reparse,
  access-error, incomplete, and identity-mismatch variants retain their strict
  source and adjacent-evidence disposition; this decision does not claim new
  standalone dynamic coverage for them.
- The complete eight-command S08 L0 code-freeze batch has not passed and must be
  restarted from command `1/8` against this accepted snapshot. It may not resume
  from command `3/8` or reuse the failed S08 batch as a complete result.
- C# compilation, EditMode in `UnityValidationProject/`, Unity, Unity MCP,
  PlayMode, cold start, Domain Reload, real Manager/Supervisor/Codex/MCP,
  consumer/third-party Package, full regression, release, publication, and
  deployment remain `NOT RUN` / `DEFERRED`.
- Acceptance does not authorize commit, push, another test, Unity process,
  Unity MCP, publication, release, or deployment.

## Handoff

Current task: cdb-v0.3-p0-s08c-pending-install-retained-closure-variants
Current status: ACCEPTED
Next notification: UnityCodeDB v0.3 Planner / Human
Next action: align and separately authorize a fresh evidence-only complete S08
L0 code-freeze batch bound to the accepted combined snapshot.
Human decision or authorization required: next-task creation and dispatch;
commit remains a separate optional human decision.

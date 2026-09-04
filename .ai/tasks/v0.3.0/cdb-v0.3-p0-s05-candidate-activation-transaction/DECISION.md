# Decision: cdb-v0.3-p0-s05-candidate-activation-transaction

Status: ACCEPT

## Disposition

- Human decision: ACCEPT the frozen candidate-to-activation transaction
  snapshot after the bounded CHECKPOINT-10 correction and GUARDED Verifier
  review.
- Decision date: 2026-09-04.
- Accepted base: `HEAD 769e5c12c7678e490dd25845c9d60c04d4a2b17e`.
- Accepted implementation/test snapshot:
  - `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` at SHA-256
    `6d57dd50326e606ea863767d87b8fd268135e076b2254fbbf2df332625d4959b`;
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
    at SHA-256
    `6fdc7f830c7c838395f91350665c0ffa95eaa11b853f086ae95a1c500cd25d9f`.
- Accepted evidence: CHECKPOINT-10 placement gate and AST/scoped diff checks
  passed; the final one-shot `-ActivationTransactionOnly` L0 passed with exit
  `0`, wall time `21.9956949s`, `1/1` batch, and `0` retry; the Verifier
  reported `PASS / NO FINDING` in `verifications/VERIFICATION-01.md` without
  rerunning the Coder test.
- The candidate-before-selection, phase-aware operation-directory,
  interruption recovery, commit, idempotent retry, conflicting-journal, and
  fixture-context findings are closed within this accepted task boundary.
- CHECKPOINT-09's misplaced fixture entry and inaccurate placement statement
  remain historical evidence and are explicitly corrected by CHECKPOINT-10.

## Boundaries

- This decision accepts only the S05 candidate-to-activation transaction and
  its direct S04 versioned-contract dependency on the declared uncommitted
  snapshot.
- C# compilation, Unity/EditMode, Unity MCP, real prerequisite/Codex behavior,
  actual restart/runtime integration, consumer and third-party Package
  behavior, and full regression remain `DEFERRED` / `NOT RUN`.
- Retirement, lease drain, physical old-instance cleanup, consumer routing,
  Install/Upgrade/Reinstall UI behavior, release, publication, and deployment
  acceptance remain separate work.
- Acceptance does not authorize Unity, Unity MCP, an external process,
  commit, push, publication, release, or deployment actions.

## Handoff

Current task: cdb-v0.3-p0-s05-candidate-activation-transaction
Current status: ACCEPTED
Next notification: UnityCodeDB v0.3 Planner / Human
Next action: separately decide whether to commit the exact accepted S05
working-tree snapshot or align the next roadmap task.
Human decision or authorization required: commit authorization or next-task
selection.

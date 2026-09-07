# Decision: cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall

Status: ACCEPT

## Disposition

- Human decision: ACCEPT the frozen obsolete-control-contract explicit
  Reinstall snapshot after bounded FIX 01 and GUARDED directed re-review.
- Decision date: 2026-09-07.
- Accepted base and HEAD:
  `8ccaec40df8773ee0296c4160f8357d5fd7125d3`.
- Accepted six-file patch identity:
  `e7443205eeff78aafbb4783af1a192e68cec9691`.
- Accepted evidence: the authorized corrected
  `-ControlContractReinstallOnly` run passed with exit `0`, wall time
  `16.8788779s`, cumulative focused batch `1/1`, and corrected retry `1/1`;
  the final scoped six-file `git diff --check` passed with exit `0` and no
  output.
- `verifications/VERIFICATION-02.md` reported `PASS` with no `BLOCKER`, `P1`,
  `P2`, or `FOLLOW-UP`. The original `VERIFICATION-01.md` P1 is `CLOSED`.
- The accepted fixture evidence proves that a second explicitly confirmed
  Reinstall request is rejected after migration becomes `Current`, before a
  materializer invocation, without a second activation/operation or changes
  to current selection, contract, authenticated legacy evidence, or the
  unrelated sentinel.

## Boundaries

- This decision accepts only the frozen S07 explicit human-confirmed
  obsolete-contract Reinstall route and its direct regression evidence.
- C# compilation, focused EditMode execution in `UnityValidationProject/`,
  Unity, Unity MCP, real Manager/Supervisor/fallback routing, real obsolete
  project migration, runtime and holder behavior, consumer/third-party
  Package acceptance, full regression, release, publication, and deployment
  remain `DEFERRED` / `NOT RUN`.
- Acceptance does not authorize a commit, push, Unity process, Unity MCP,
  additional test run, publication, release, or deployment action.

## Handoff

Current task: cdb-v0.3-p0-s07-obsolete-contract-explicit-reinstall
Current status: ACCEPTED
Next notification: UnityCodeDB v0.3 Planner / Human
Next action: separately decide whether to commit the exact accepted S07
working-tree snapshot or align the next roadmap task.
Human decision or authorization required: commit authorization or next-task
selection.

# Decision: cdb-v0.3-p0-s15-maintenance-ownership-transition-fix

## Disposition

- Decision: `ACCEPT`
- Decision owner: `UnityCodeDB v0.3 Planner / User`
- Decision date: `2026-09-11`
- Accepted snapshot HEAD: `a60b92f36679834d1696e4133561bbbc770139be`
- Accepted canonical 12-path identity:
  `afae3d2bf8c95306920d032a2f9d7d1ba8e7debc`

## Accepted Scope

This decision accepts the S15 structural FIX for the two original P1 findings:

- Manager maintenance actions use the single Supervisor-owned queue and no
  longer use the removed independent maintenance lane or duplicate full-status
  refresh path.
- Compilation and Asset Update boundaries participate in maintenance
  suspension, local-generation invalidation, and late-result rejection while
  query observations remain eligible.
- The Verifier's targeted RELEASE review found no BLOCKER, P1, P2, or
  FOLLOW-UP finding in the declared scope.

## Evidence Boundary

The decision relies on the recorded Coder static/source batch, focused
`request-queue` L0, scoped 12-path `git diff --check`, and the Verifier's
identity-reconciled read-only review. No evidence command was rerun for this
decision.

The following remain explicitly deferred and are not accepted as passed:

- C# compilation and affected EditMode tests;
- Unity, Unity MCP, visible lifecycle, and real transition acceptance;
- PowerShell materializer, full Node/PowerShell suites, full regression,
  consumer/third-party Package validation, and release publication.

## Git And Handoff

- Source and test snapshot remains uncommitted.
- No push or publication was performed.
- Commit is a separate human-initiated action and is not implied by this
  acceptance.
- Next owner/action: `UnityCodeDB v0.3 Planner` aligns the next roadmap task;
  no automatic repair or Verifier reroute is created by this decision.

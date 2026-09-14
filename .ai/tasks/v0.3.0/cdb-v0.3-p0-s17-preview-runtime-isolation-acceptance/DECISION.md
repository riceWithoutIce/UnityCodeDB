# Decision: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance

## Disposition

- Decision: `ACCEPT`
- Decision owner: `UnityCodeDB v0.3 Planner / User`
- Decision date: `2026-09-14`
- Accepted snapshot HEAD:
  `5587f4739426f11fa859ced02e5e6164b0429a63`
- Accepted Phase A candidate identity:
  `af645f364fb41202ef3b56d7113b5d29aa6aef32`
- Accepted targeted six-path identity:
  `970b95b826a5aefa7130a17a813a5fc3240337cb7d616f0fc2459ec517095a04`

## Accepted Scope

This decision accepts the frozen S17 engineering checkpoint:

- the local `0.3.0-preview.1` Package candidate and immutable successor
  generation `poc.35` are internally bound to the reviewed schema-2 Provider
  artifact, protocol, capability, payload, pointer, and predecessor contracts;
- recovered materializer verification consumes the authenticated Supervisor
  observation without introducing a second operational-readiness authority;
- lifecycle owns the validated terminal-convergence envelope while Snapshot
  and Manager remain projection/cache consumers;
- terminal replacement and authenticated Ready clearing compare
  `SupervisorId` plus `OwnerEpoch`, requiring a newer revision only within the
  same authority epoch;
- authoritative Uninstalled completion publishes one coherent cache tuple and
  clears the persisted terminal envelope before persisting Uninstalled state;
- the forwarding `TryGetPersistedProductState` overload closes the observed
  compile error without adding identity derivation or main-thread I/O;
- human compilation reported zero visible errors and the seven exact affected
  EditMode tests reported `7/7 PASS`;
- targeted Verifier review admitted the frozen identities, returned `PASS`,
  and reported no one-time BLOCKER, P1, P2, or FOLLOW-UP finding.

The accepted `CS0414` unused retry-counter warning remains a non-blocking
code-freeze follow-up and does not reopen S17.

## Evidence Boundary

This disposition reuses the Phase A focused evidence, final scoped
`git diff --check`, human compile and exact affected EditMode attestation, and
the Verifier's claim-bounded read-only review. No test is rerun for close-out.

The following remain explicitly `NOT RUN / DEFERRED` and are not promoted to
PASS by this decision:

- full runtime convergence and the complete Phase B lifecycle scenario;
- full EditMode and all PlayMode coverage;
- real Provider and clean third-party Package-only consumer acceptance;
- Unity MCP and real Codex-client tool acceptance;
- publication, promotion, release artifact verification, tag, push, and
  broader environment matrices.

This is an accepted local engineering checkpoint, not a published release or
an assertion that the original end-to-end release objective is complete.

## Git And Handoff

- The user separately authorized one local close-out commit containing the
  accepted S17 Package/source/test/documentation changes, the S17 task records,
  and the previously authorized Workflow v2 transition records.
- Inherited S14/S14r task records and all `UnityValidationProject` dirty or
  generated state are excluded from the commit and preserved unchanged.
- No tag, push, publication, or release promotion is authorized.
- Next owner/action: `UnityCodeDB v0.3 Planner` aligns the next roadmap task;
  this acceptance does not automatically dispatch another role.

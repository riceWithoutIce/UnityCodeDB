# Decision: cdb-v0.3-p0-s16-manager-cache-runtime-isolation

## Disposition

- Decision: `ACCEPT`
- Decision owner: `UnityCodeDB v0.3 Planner / User`
- Decision date: `2026-09-11`
- Accepted snapshot HEAD:
  `0b9aeac6c3586d65c041cc11cc1d232454618909`
- Accepted canonical two-path binary identity:
  `9c7e47b8fd011f4875258b6de5b8b166eec8e4e9`

## Accepted Scope

This decision accepts S16 FIX 01 within its frozen RELEASE scope:

- Manager display-only persisted-state lookup consumes only a non-empty
  lifecycle-published project identity bound to the same normalized project
  root.
- Missing or mismatched published identity returns a bounded cache miss with
  `Starting`; it does not derive or hash project identity on Unity's main
  thread.
- Project validation, identity construction, hashing, and full observation
  remain owned by the lifecycle worker path without a second authority or
  instrumentation suppression.
- The nearest lifecycle tests cover the published-identity selection and
  bounded fallback contract.
- Fresh human `manager_closed` evidence reports all eight
  `main_thread_work_counts` as zero, `main_thread_violation_count=0`, complete
  Manager activity, and no status refresh left in flight.
- The targeted RELEASE Verifier review admitted the frozen HEAD and identity,
  returned `PASS`, and reported no BLOCKER, P1, P2, or FOLLOW-UP finding.

## Evidence Boundary

The decision relies on the Coder's scoped `git diff --check`, the human-reported
Unity compilation disposition and terminal Manager runtime record, and the
Verifier's direct read-only source/test review. No evidence command was rerun
for this decision.

The following remain explicitly deferred and are not promoted to independent
PASS evidence:

- the ad hoc static/source selector, classified as
  `DEFERRED / UNSUITABLE_EVIDENCE_HARNESS`;
- independent C# compile, EditMode, L0/L1, and full regression runs;
- Unity MCP, BatchMode, external probes, consumer/third-party Package
  validation, release publication, and broader S14/S14r acceptance.

## Git And Handoff

- The user separately authorized one local close-out commit containing only
  the two accepted FIX 01 source/test paths and this S16 task directory.
- Inherited S14/S14r, validation-project, and other dirty state is excluded.
- No push or publication is authorized by this decision.
- Next owner/action: `UnityCodeDB v0.3 Planner` aligns the next roadmap task;
  this acceptance does not automatically dispatch another role.

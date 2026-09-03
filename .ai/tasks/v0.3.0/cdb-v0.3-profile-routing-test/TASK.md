# Task: cdb-v0.3-profile-routing-test

## Metadata
- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: v0.3.verifier.standard
- Review mode: GUARDED
- Execution profile: v0.3.coder.standard
- Session policy: REUSE_ONLY
- Requirement source: `com.rice.ai-codedb/Documentation~/development-workflow.md`; `.ai/workflows/codedb-workflow-v1/profile-map.md`

## Objective
- Single outcome: verify the bounded profile-pool routing contract without
  creating sessions, changing source code, or starting Unity.

## Scope
- In scope:
  - Resolve each of the four declared v0.3 profiles to its logical role and
    configured model/reasoning level.
  - Confirm the expected behavior for an idle binding, a busy binding, an
    unknown binding, and a missing profile.
  - Confirm the completion footer preserves the next-role handoff chain.
- Out of scope:
  - Creating, renaming, replacing, or deleting Codex sessions.
  - Automatic wrapper implementation, API retries, broad session polling, or
    concurrent dispatch.
  - Package/runtime source changes, Unity, EditMode, MCP, consumer acceptance,
    commit, push, or release work.
- Allowed files: `.ai/workflows/codedb-workflow-v1/profile-map.md` and this task's
  task records only; no implementation files.
- Protected state: all existing Codex sessions, active development worktrees,
  frozen task cards, and current repository changes remain untouched.
- Snapshot binding: not applicable; this is a routing-contract dry run.

## Execution
- Coder actions:
  - Read this task and the profile map once.
  - Perform one bounded dry-run/admission matrix covering standard and deep
    profiles without sending a development task.
  - Record the observed route, model/effort declaration, and any mismatch in
    `RESULT.md`; do not create a session or commit.
- Focused tests:
  - L0 tests: one dry-run matrix for the four profile rows and the busy/missing
    binding guards.
  - Affected L1 tests: none.
  - Explicitly not run: Unity/EditMode, Unity MCP, package or repository tests,
    source compilation, full session polling, concurrent dispatch, and release
    acceptance.
  - Test rationale: this slice validates routing metadata and guard behavior;
    no product code or live Unity evidence is needed.
- EditMode authorization: NOT_REQUESTED
- Stop conditions:
  - A check would create, interrupt, or send work to a session.
  - The profile map and observed session names/model settings disagree.
  - A status is unknown and resolving it would require repeated polling.
  - The dry run would exceed one bounded matrix or require a second retry.
- Escalation triggers:
  - A profile maps to the wrong role or wrong configured effort.
  - A busy/missing binding permits creation, duplication, interruption, or
    silent fallback.
  - A completion footer bypasses Planner routing.
- Model escalation: request-only

## Definition Of Done
- Expected result: all four profile rows resolve to the intended role and
  provisional model level; no guard path creates or duplicates a session; the
  handoff footer names exactly one next owner and bounded action.
- Required evidence: a concise matrix in `RESULT.md`, actual model/effort if a
  session is used for the dry run, and the completion-routing footer.
- Deferred risks: automatic wrapper/dispatcher behavior, live thread binding
  persistence, and cross-session platform reliability remain unverified.

## Handoff
- Current task: cdb-v0.3-profile-routing-test
- Current status: READY
- Next notification: Human (manual)
- Next action: authorize one bounded routing dry run; do not create sessions or
  dispatch a product task.
- Human decision or authorization required: authorize the dry run and decide
  whether any observed profile mismatch should update the map.

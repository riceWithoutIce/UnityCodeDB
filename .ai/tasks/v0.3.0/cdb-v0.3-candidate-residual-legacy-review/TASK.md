# Task: cdb-v0.3-candidate-residual-legacy-review

## Metadata

- Product: UnityCodeDB
- Version: v0.3; inspected Package declaration is 0.3.0-preview.5.
- Created: 2026-10-25 (Asia/Shanghai).
- Workflow: codedb-workflow-v2, revision 2.7.
- Status: COMPLETE / F01_F02_SCOPED_FIX_AND_REVIEW_PASS.
- Planner: current UnityCodeDB development session.
- Coder: current session for the later authorized F01/F02 repair only.
- Verifier: current session, acting as source reviewer; no independent agent.
- Review mode: GUARDED; bounded source review, not formal release acceptance.
- Execution mode: DURABLE_SESSION.
- Execution profile: v0.3.verifier.standard; logical routing only, no model change.
- Delegation authorization: NOT_AUTHORIZED for this task.
- Session policy: REUSE_ONLY; no new chat or subagent created.
- Requirement source: current user's review scope and responsibility boundaries;
  `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md` remains the product
  requirement authority. Follow the development workflow for execution.
- Paths in this record are relative to `<repository-root>`.

## Objective

Produce one consolidated, prioritized review of temporary test/diagnostic
residue and historical implementation patterns that could affect the current
v0.3 Package's normal operation or delivery. Give the user enough evidence to
choose FIX_NOW, DEFER, or ACCEPT_RISK before candidate freeze and lifecycle
acceptance. This task does not implement those decisions.

## Snapshot And Admission

- Frozen primary review commit: `fe08d6e0961189cedd467487675062564c470644`.
- Primary Package Git tree: `8d0db4404025fd1db607770fc38d6a9d8427cd84`.
- Supplementary comparison snapshot: primary checkout commit
  `f7634d29664e6557308938068814d5d2d1c0fd5c`, Package tree
  `54b34bd561015cd3e390e7dcba9cae1e50b76127`. Inspect its independent
  writer-lifetime WIP and integration differences without merging them.
- Authorized rebind, 2026-10-25: after the candidate comparison, the user replied
  "好的 同意" to reviewing the delivered fe08d6e baseline and separately
  disposing of primary-only WIP before source integration. The original task
  creation binding was f7634d2; it is preserved here as comparison history.
- Branch at creation: `codex/v0.3.0-legacy-workflow`.
- Creation preflight: tracked/untracked worktree clean before this task file.
- The commits identify inspection snapshots, not accepted release artifacts.
  The preceding read-only comparison matched all 669 delivered Package files
  to fe08d6e; an additional consumer test .meta file was recorded separately.
  This is disk provenance, not process/runtime or response identity evidence.
- Before review, confirm the snapshot and whether independent Code development
  is active. If it is active, collect read-only candidates only; do not interrupt
  it, append work, or request immediate fixes. Consolidated assessment waits for
  its stable snapshot. Do not silently rebind this review to newer source.
- Existing task evidence may be reused only with its candidate and limitations.
  A missing log or deleted historical artifact is an evidence gap, not proof of
  a product defect and not permission to regenerate it.

## Scope

In scope:

1. Temporary test/diagnostic behavior reachable in normal Editor, installation,
   Supervisor, wrapper or query execution: forced outcomes/state, bypasses,
   test-specific paths/markers, default high-frequency logging, diagnostic
   switches and cleanup hooks.
2. Historical implementation with concrete current reachability: superseded
   entry points, duplicated decision authority, obsolete configuration fallback,
   repeated maintenance/cleanup and conflicting lifecycle/status decisions.
3. Delivery separation: assembly definitions, test isolation, fixture ownership,
   payload/generation selection and direct export references. Distinguish
   included files from files actually loaded or invoked.

Read-only dependency closure:

- Primary: `com.rice.ai-codedb/Editor/`, `Tools~/`, `Payload~/`, `Tests/`,
  `Tests~/`, package metadata and assembly definitions.
- Start with normal entry points, declared delivery/generation selection and
  test/diagnostic references; trace only direct producers, consumers and callers
  needed to establish impact. Do not deeply audit every historical generation.
- Direct repository delivery consumers and `.ai/tasks/` evidence are readable
  only when explicitly referenced by an in-scope path or claim; record that
  dependency in the review. No repository-wide historical investigation.

Out of scope:

- Style modernization, broad architecture redesign, exhaustive race analysis,
  new requirements, comprehensive security/performance audits or full regression.
- Automatic removal of tests, old generations or compatibility code based on
  names, age, apparent duplication or lack of obvious callers alone.
- Reopening accepted S39/S40/S41 functional gates merely to repeat evidence, or
  reopening the staged heartbeat/identity investigation without a concrete
  newly evidenced in-scope effect.
- External Unity projects, live runtime/lease/process/log collection, MCP calls,
  global configuration, GitHub board changes, commits, push, exports or release.

Protected state: all product/test source, immutable generations, consumer
references, working changes, fixtures, retained evidence, runtime state,
`.worktrees/`, `.artifacts/` and `.backups/`. No deletion or automatic cleanup.

Change allowlist:

- Task creation: this `TASK.md` only.
- During the later review: this directory's `VERIFICATION.md` only, plus a
  Planner-owned status/handoff update to this task. Do not create empty results.

Identity authority route: existing canonical contracts, read-only.
Generation transition: NONE. No identity literals, hashes or manifests changed.

## Review Evidence And Classification

For each material finding, provide the snapshot, repository-relative file and
line, reachable trigger/call chain, concrete consequence, supporting evidence,
uncertainty, and minimum proposed disposition. A keyword match alone is not a
finding. Distinguish static reachability from observed runtime behavior.

Keep findings separate from retained-purpose code and unresolved candidates:

- Retain legitimate regression tests, required fixtures, supported compatibility
  behavior and bounded diagnostics unless concrete evidence supports a change.
- BLOCKER: normal user flow unavailable; possible data/configuration damage;
  possible termination of external processes; or a critical declared release
  promise lacks evidence. Bind missing evidence to that actual promise.
- CURRENT_FIX_CANDIDATE: evidenced local impact with a bounded repair proposal;
  the user decides whether it belongs in this candidate.
- FOLLOW-UP: theoretical hardening, rare races, style/refactoring, or requirements
  not frozen for this release. These do not block the current release by default.

Return all material findings once to the user. Do not send fixes to an active
development task or start repairs. If repairs are later authorized, review only
the original findings and their nearest regressions, then stop when agreed
blockers/tests/dispositions are resolved.

## Execution Envelope

- Original user grant: "同意 那请你先建立一个任务" authorized creation only.
  The later "好的 同意" approves the proposed candidate-aligned read-only
  review before any source integration; execution now proceeds in this session.
- Planned reviewer actions: read-only snapshot admission, targeted source search,
  direct call/reference tracing and evidence correlation; one final report.
- L0 / affected L1 / EditMode / runtime / MCP: NOT_RUN; no tests authorized.
- Test rationale: this stage identifies evidence-backed repair candidates;
  verification commands belong to any separately agreed repair/acceptance plan.
- Delivery authorization: NONE. Side effects: task/report records only.
- Path-provenance, identity and release-closure gates: inspect existing contracts
  and evidence only; do not execute harnesses, generators or export commands.
- Active time budget: STANDARD_30M for the later review. No budget extension or
  exhaustive audit; unresolved items retain explicit coverage limitations.
- Output budget: V2_DEFAULT; one concise report with coverage and findings.
- Broad search/full diff/full regression: FORBIDDEN; scoped discovery inside the
  named closure is allowed, including targeted diagnostic/test-reference search.
- Mechanical read-command corrections: at most 2 per scenario.
- Semantic repair attempts: NOT_APPLICABLE; product repair authorization NONE.
- Model escalation: REQUEST_ONLY; no implicit delegation or model override.
- Stop when the bounded checklist is covered and findings can be returned, or
  the budget expires. Report unfinished coverage without claiming clean code.
- If snapshot drift, missing authority or a required dependency outside the
  closure prevents assessment, report that limitation; do not repair, expand
  scope, mutate the environment or create fallback worktrees.

## Definition Of Done

- One `VERIFICATION.md` identifies the inspected snapshot, scope/coverage,
  evidence class, consolidated prioritized findings, retained-purpose code,
  limitations and proposed user dispositions.
- No product, test, runtime, consumer or configuration modifications.
- No assertion of long-term stability, complete residue elimination, lifecycle
  acceptance or release readiness from static review alone.
- User decides findings together before any repair or lifecycle experiment.

## Handoff

- Current task: cdb-v0.3-candidate-residual-legacy-review.
- Current status: F01_F02_SCOPED_FIX_AND_REVIEW_PASS.
- Next notification: user.
- Next action: return RESULT.md and targeted review; stop this repair/review.
- Human decision or authorization required: subsequent source integration,
  delivery or Unity acceptance; no subagent or new chat authorized.

## Authorized F01/F02 Repair — 2026-10-25

The user's "需要处理 f01 \\ f02" selects FIX_NOW for both findings and supersedes
the read-only restriction only for the following bounded repair. Current session
acts sequentially as Coder and targeted reviewer; no independent review claim.

Change allowlist:

- In `.worktrees/cdb-identity-handoff-heartbeat-followup/`:
  `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` only. F01: default-off
  sidecar/full-document publication; retain counters, SessionState restoration,
  formal tests and product failure logs. Use one explicit domain-cached opt-in
  `CODEDB_EDITOR_DIAGNOSTICS=1`; no per-Repaint environment/disk lookup.
- In the primary checkout: `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs`
  and `com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1` only. F02:
  exclude the exact writer-lifetime WIP by restoring these two verified files
  to fe08d6e bytes. Preserve recoverability in immutable f7634d2 and record hashes.
- This task directory: TASK.md, VERIFICATION.md, RESULT.md and one focused
  offline verification script. Generated evidence only under primary
  `.artifacts/tests/cdb-v0.3-candidate-residual-legacy-review/`.

Read closure: the named files, direct Manager consumers, existing diagnostic
helper/tests and original finding evidence. Freeze existing dirty file hashes
before edits and verify preservation afterwards. No wholesale integration.

Evidence scenarios: execute actual diagnostic factory/checkpoint bodies in a
bounded BCL/stub harness, default/off/explicit-on; verify enabled sidecar still
publishes and disabled paths do not log/write while counters/SessionState remain;
C# syntax and PowerShell parse checks; F02 exact Git-byte equality and recovery
provenance; scoped diff/whitespace and pre-existing dirty-state preservation.
These are offline/source checks, not Unity/EditMode/runtime evidence.

Budget: STANDARD_30M; at most two mechanical corrections per scenario and two
local semantic repairs. Stop after original findings and adjacent checks close.
No Unity/MCP/process control, consumer changes, export, commit/push or release.
Existing dirty source/fixtures, historical evidence and unrelated docs protected.

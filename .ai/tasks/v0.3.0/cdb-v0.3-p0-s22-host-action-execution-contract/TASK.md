# Task: cdb-v0.3-p0-s22-host-action-execution-contract

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Workflow: codedb-workflow-v2, revision 2.3
- Status: DRAFT / BASELINE_ADMISSION_PENDING
- Review mode: GUARDED
- Execution mode: DURABLE_SESSION candidate; select at admission
- Requirement source:
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-host-action-execution.md`

## Objective

Make one Manager-initiated Host or dependency action attributable from click
through authoritative command result and visible product terminal state,
without Unity-main-thread external work, duplicate execution authority, or
false Ready/failed presentation.

## Admission Gate

- S21 FIX 04 receives independent targeted review and human disposition.
- Any accepted S21 source is committed as a stable baseline before this task
  admits implementation. Record that exact commit, Package identity, and the
  status of the S21 Unity golden path; do not assume source checks closed Unity.
- Perform a bounded action inventory against the product contract. Freeze the
  exact source/test allowlist, direct dependencies, protected state, and
  evidence scenarios from that inventory before Coder dispatch.
- If S21 FIX 04 is rejected or its baseline changes, keep this task draft and
  re-evaluate the contract against the new baseline. This draft grants no
  source edit, Unity, external action, commit, or publication authority.

## Continuous Scope After Admission

- Include Manager Host payload actions, Configure Dependencies, and shared
  Manager execution/result presentation used by neighboring commands.
- Inventory each action's effect class and authorization source. Preserve the
  existing Provider, Supervisor, activation, retirement, and materializer
  authorities; do not move their decisions into the Manager.
- Trace one immutable context through admission, worker command, structured
  result, post-action status, and visible terminal state.
- Repair demonstrated gaps in this one causal chain, including adjacent tests.
  Do not split by button, language, or individual symptom.

## Explicit Exclusions

- No redesign of Supervisor query-first scheduling, Provider compatibility,
  Owner Identity migration, or Package identity authority.
- No broad cleanup, automatic retry of external actions, process termination,
  real-project state repair, Unity MCP, BatchMode, push, or publication.
- A new effect or authority outside the frozen inventory requires route
  reassessment, not an implicit allowlist expansion.

## Evidence And Done

- Required focused evidence: action/effect/authority inventory; source and
  affected Editor tests for thread boundary, reentry, result provenance,
  terminal-state separation, reload/timeout behavior, and backend refusal;
  adjacent materializer/Provider tests only where implementation changes them;
  scoped diff check and exact Package closure.
- After code acceptance and a commit-derived Package, one separately
  authorized human-owned Unity scenario checks import/compile, Manager action
  terminalization, Ready-only tab/Play/Edit behavior, and normal shutdown.
- Report C# compile, EditMode, Unity, external Provider, and release gates as
  NOT RUN / DEFERRED until actually executed. Do not infer them from L0.
- Done means each in-scope action has one declared effect and authorization
  route, command evidence is preserved, command completion is distinct from
  product readiness, and the visible action cannot remain indefinitely busy
  or silently create a second owner.

## Handoff

- Current status: DRAFT / BASELINE_ADMISSION_PENDING.
- Next actor: Planner after S21 FIX 04 disposition.
- Next action: freeze baseline and bounded inventory, then request a separate
  implementation authorization. Do not dispatch Coder from this draft.

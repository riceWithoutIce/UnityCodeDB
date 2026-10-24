# Task: cdb-v0.3-p0-s22-host-action-execution-contract

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Workflow: codedb-workflow-v2, revision 2.3
- Status: GUARDED_FIX_01_COMPLETE / VERIFIER_REVIEW_IN_PROGRESS
- Review mode: GUARDED
- Execution mode: one continuous bounded Coder slice, then independent read-only Verifier
- Requirement source:
  `com.rice.ai-codedb/Documentation~/v0.3.0-p0-host-action-execution.md`

## Objective

Make one Manager-initiated Host or dependency action attributable from click
through authoritative command result and visible product terminal state,
without Unity-main-thread external work, duplicate execution authority, or
false Ready/failed presentation.

## Admission Gate

- Branch: `codex/v0.3.0-legacy-workflow`; committed baseline:
  `6b64f27adb51eeab8394aac6bca722117ac6863c`.
- Source Package identity: `com.rice.ai-codedb` `0.3.0-preview.5`, current
  Host generation `poc.39`. This is a source baseline, not a newly exported
  commit-derived Package or a Unity acceptance result.
- S21 FIX 04 targeted Verifier verdict remains `FAIL/P1-01`; the user accepted
  that known risk for the source baseline. Its Editor partial-v1 presentation
  can offer removal where backend admission rejects it. Do not call this fixed
  or passing, and do not enlarge backend deletion authority in S22.
- S21 Unity golden path, C# compile, EditMode, real-project removal, and
  release acceptance remain incomplete or deferred. S22 does not inherit a
  Unity PASS from S21.
- This bounded source inventory admits the task card only. Source edits,
  tests, Unity, external actions, commit, export, and publication require
  separate implementation or later-stage authorization.

## Frozen Action Inventory

| Manager entry | Effect class | Authorization source |
| --- | --- | --- |
| Host files Inspect/DryRun, Verify | Observation; no project mutation | Package materializer read contract |
| Host Payload Upgrade | Lifecycle-authorized activation or recovery mutation | Current Package contract and instance/Supervisor authority; no button confirmation |
| Redeploy host, Sync host files, Remove host files | Confirmed project mutation | Main-thread user confirmation plus materializer's fresh ownership/holder/target checks |
| Install CodeDB, Uninstall CodeDB, Remove CodeDB Integration | Confirmed project integration mutation | Main-thread user confirmation; Supervisor/materializer and fresh backend admission remain authoritative |
| Configure Dependencies | Machine Provider installation, followed by Host admission/reconcile | User click plus fixed Provider installer contract; lifecycle owns the post-install Host decision |
| Prepare/Regenerate runtime, watcher controls, index maintenance, diagnostics/probes | Mixed project/runtime effects or observation; not implicitly read-only | Existing Package scripts or Supervisor queue; retain their current action-specific authority |

The last row is adjacent only because these commands share the Manager action
envelope. Inventory their actual effect before changing that envelope; do not
redesign their backend policy. Probe can publish availability state, while
DryRun and Verify must remain observations. A successful command is not proof
that the product is Ready.

## Frozen Implementation Boundary

The allowlist below records the original implementation/FIX 01 boundary; it
does not authorize REDESIGN edits. The exact potential REDESIGN allowlist in
`ROUTE-REASSESSMENT.md` supersedes it only after separate implementation
authorization.

- Editable Package source allowlist: `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`,
  `com.rice.ai-codedb/Editor/AICodedbActivityPanel.cs`,
  `com.rice.ai-codedb/Editor/AICodedbActions.cs`,
  `com.rice.ai-codedb/Editor/AICodedbPaths.cs`,
  `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`,
  `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs`, and
  `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`.
- Editable direct tests: `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  and `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`.
- Direct dependencies for read-only contract checks: Package-owned
  `Tools~/materialize-codedb-host-payload.ps1`,
  `Tests~/test-codedb-host-payload-materializer.ps1`,
  `Tests~/test-codedb-package-boundary.ps1`, and the current Package runtime
  contract/Host pointer. Backend edits or additional paths require route
  reassessment before modification.
- Protected state: the human Unity project, selected instance, generation,
  journals, Provider installation, MCP clients, external processes, and all
  unrelated dirty worktree content. No cleanup or migration is implied.
- Demonstrated source gap to address: ordinary `RunAction` invokes no-argument
  actions in `Task.Run`, while some paths then call `CaptureExecutionContext`,
  which uses Unity APIs. Capture immutable context on the main thread and
  carry it into the worker; verify the complete call chain before changing it.
- Ownership gap to prove or repair: `_userActionInFlight` is window-local and
  `RunUserActionAsync` returns when the window is destroyed. A close, reload,
  or timeout must not silently make a second mutation owner or erase the
  authoritative command outcome. Existing lifecycle/operation authority must
  remain the source of truth; no automatic external-action retry.

## Focused Evidence Scenarios

1. A click captures one project/Package identity and action/effect/authority
   record on the main thread; overlapping clicks are rejected. Worker paths
   do not call Unity APIs or display UI, including Provider and Host actions.
2. Preserve actual exit code, stdout, stderr, elapsed time, timeout, and
   structured backend outcome; invalid or absent outcome is not success.
   Distinguish command success plus Needs Attention from Ready.
3. Completion, failure, timeout, cancellation, window close, compilation,
   and Domain Reload clear transient progress or show bounded pending/recovery
   without claiming rollback or starting a second mutation.
4. Backend refusal after changed selection, ownership, holder, or target
   remains visible and fail-closed. Existing Provider and materializer focused
   tests are run only if touched by the authorized implementation.
5. Run focused Editor tests, any directly affected Package L0, scoped
   `git diff --check`, and exact Package closure on the frozen source. Report
   C# compile/EditMode/Unity/external Provider/release gates as NOT RUN until
   separately performed. Unity acceptance follows an accepted commit-derived
   Package and its own human authorization.

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

- Current status: GUARDED_FIX_01_COMPLETE / VERIFIER_REVIEW_IN_PROGRESS.
- The original implementation and FIX 01 remain an uncommitted frozen
  diagnostic snapshot in `RESULT.md`. Targeted `VERIFICATION-02.md` closed
  unsafe re-admission but found unresolved recovery liveness after Domain
  Reload. The human selected REDESIGN and froze its design boundary; see
  `ROUTE-REASSESSMENT.md` for the screened receipt location, writer lifetime,
  exact potential allowlist, evidence budget, and stop conditions.
- The user separately authorized the one continuous REDESIGN implementation
  on 2026-09-24. Coder may edit only the exact source/test allowlist in
  `ROUTE-REASSESSMENT.md` and run only its bounded non-Unity evidence. This
  does not authorize real Provider installation, consumer-project mutation,
  Unity, Verifier routing, commit, Package export, push, or publication.
- Next actor: `v0.3.coder.deep` for implementation and `RESULT.md` handoff.
  C# compile/EditMode and Unity remain separate evidence gates. Stop at the
  first need to expand authority, edit surface, or external side effect.
- The REDESIGN checkpoint in `RESULT.md` is BLOCKED after writer L0 2/2 and
  corrected retry 1/1; it is not Verifier-ready. The user authorized the
  bounded Writer Continuation 01 recorded in `ROUTE-REASSESSMENT.md`. This
  overrides no production authority or protected-state boundary.
- Writer Continuation 01 passed its corrected writer, Supervisor correlation,
  Manager source, and Package-boundary evidence, then stopped before release
  closure comparison because its command omitted explicit `-PackageRoot`.
  The user authorized only Closure Evidence Recapture 01 in
  `ROUTE-REASSESSMENT.md`; no source change or other test retry is admitted.
- Closure Evidence Recapture 01 passed the actual Package content comparison,
  scoped tracked diff-check, untracked writer whitespace check, and final
  identity on the unchanged source snapshot. The user separately authorized
  one GUARDED, read-only S22 source verification. The Verifier writes only
  `verifications/VERIFICATION-03.md`; C# semantic compile, Editor tests,
  EditMode, Unity, real external actions, commit, and publication remain
  NOT RUN / separately gated.
- `VERIFICATION-03.md` found one P1: terminal receipt recovery does not
  validate the complete admitted/claim/terminal envelope. The user selected
  `FIX`; this is a bounded correction of that finding and its immediate
  negative recovery regression only. No new architecture or authority is
  admitted.
- FIX 01 completed within the two-file boundary. The source/negative-recovery
  batch, scoped diff-check, and final identity passed; actual Editor tests,
  C# semantic compile, EditMode, Unity, and live reload remain NOT RUN.
  Next decision is a read-only re-review of only VERIFICATION-03 P1-01 and its
  immediate regression.
- The user authorized one independent read-only Verifier re-review of only
  the original P1-01 and its immediate negative recovery regression. The
  Verifier may write only `verifications/VERIFICATION-04.md`.

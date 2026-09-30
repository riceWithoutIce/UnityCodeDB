# Task: cdb-v0.3-p0-s27-historical-manager-action-reconciliation

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0 P0
- Workflow: codedb-workflow-v2, revision 2.3
- Status: ACCEPTED / FOCUSED_CSHARP_EDITOR_GATE_PASS / REAL_S25_GATE_BLOCKED
- Planner: UnityCodeDB v0.3 Planner
- Coder: Planner-local source implementation; no separate Coder session
- Verifier: independent targeted review after a stable source snapshot
- Review mode: GUARDED
- Execution mode: CONTINUOUS_WITHIN_SCOPE
- Requirement source: `com.rice.ai-codedb/Documentation~/v0.3.0-p0-host-action-execution.md`, Historical Unknown-Action Reconciliation Amendment; S25 Gate C diagnosis

## Objective

Provide one evidence-qualified route to reconcile a historical Manager action
whose command outcome remains unknown, without forging a command result or
replaying the old mutation. Make S25's old pending Remove either safely
reconcilable under the frozen proof or explicitly remain blocked. This is one
continuous contract, implementation, focused-evidence, and review task, not a
sequence of symptom-specific FIX cards.

## Scope And Protected State

- Start with a bounded, read-only feasibility pass over the exact S25 action
  envelope, S25 Package writer, S26 journal, and directly coupled materializer
  state/lock contracts. Determine whether writer/child quiescence and project
  state can be proved without inventing a receipt or relying on status alone.
- If proof is feasible, implement an append-only, identity-bound
  `CommandOutcomeUnknown` administrative disposition and its fail-closed
  admission/recovery flow. Preserve ordinary terminal and pre-effect behavior.
- Authorized design/implementation allowlist under `com.rice.ai-codedb`:
  `Editor/AICodedbManagerActionJournal.cs`,
  `Editor/AICodedbProcessRunner.cs`,
  `Editor/AICodedbHostPayloadMaterializer.cs`,
  `Editor/AICodedbActions.cs`, `Editor/AICodedbManagerWindow.cs`,
  `Tools~/materialize-codedb-host-payload.ps1`,
  `Tests/Editor/AICodedbManagerUiTests.cs`,
  `Tests~/test-codedb-package-boundary.ps1`, and
  `Tests~/test-codedb-host-payload-materializer.ps1`. Any change to
  `codedb-instance-engine.ps1`, Supervisor, project mutation semantics, or a
  new resident process requires another route reassessment before editing.
- Read-only dependency closure: S25 `TASK.md`/`RESULT.md`, S26 `TASK.md` and
  accepted verification, S25/S26 Package writer, project-integration reinstall
  contract, and directly referenced control/intent/lock readers.
- Protected: original S25 admission/claim, all receipts and historical action
  directories, `UnityValidationProject` runtime/selection/Package settings,
  immutable generations, holder and external processes, Provider, and
  unrelated dirty work. No cleanup, process stop, old-command replay, real
  Remove/Install, Unity/MCP, commit, push, or publication in the source gate.
- Baseline HEAD: `1be11d911c05db4b7752122bf761e61fac47ef3c`;
  freeze a fresh scoped source/test identity at implementation handoff.

## Execution Envelope

- One continuous Coder pass may implement and run directly adjacent synthetic
  tests within the allowlist. The source-only feasibility pass found no native
  process launch reachable from `RemoveIntegration`; the exact old business
  child remains identifiable by its admitted `powershell.exe -File` command.
  This does not prove present-day quiescence; real OS observation is a later
  separately authorized human-owned gate.
- A proof must bind the original project/Package/action/stage/writer/command,
  exclude still-capable writer/child execution, independently classify the
  project mutation state under its lock, and recheck both before publication.
  A missing or inaccessible observation blocks; age, PID absence, UI error,
  and `INSTALLED` alone do not pass.
- A reconciled marker is not a terminal receipt or pre-effect refusal. It
  retains the old outcome as unknown and can release only this exact old
  admission. No automatic second owner or fresh Remove follows publication.
- Focused evidence: synthetic positive/negative fault matrix from the product
  amendment, PowerShell parse and bounded L0 where affected, directly affected
  Editor tests when separately human-authorized, scoped diff-check, and a
  frozen identity for independent Verifier review. No broad regression.
- Stop at conflicting evidence, incomplete process visibility, project-state
  drift, need for a wider mutation authority, or inability to preserve the
  old evidence. Do not replace a failed proof with a manual acknowledgement.

## Definition Of Done

- Source gate: one coherent, reviewed implementation proves exact historical
  reconciliation or reports a structural blocker with no production edit.
- Real S25 gate remains separate: after a commit-derived Package and human
  authorization, observe the exact old action and its project state. Only a
  proved administrative reconciliation may permit a separately confirmed
  fresh Remove; fresh Install still waits for `UNINSTALLED / PENDING`.
- Deferred: Unity integration, real process observation, real Remove/Install,
  full EditMode, consumer testing, release, push, and publication.

## Handoff

- Current status: ACCEPTED for the frozen source and focused-evidence gate;
  `verifications/VERIFICATION-01.md` is PASS with no findings. The human
  reported zero C# compile errors and the S27-added single EditMode test PASS
  on the temporarily source-bound validation project; its Package files were
  restored to their pre-gate hashes. The old S25 Remove outcome remains
  unknown and S25 Gate C remains BLOCKED.
- Next notification: UnityCodeDB v0.3 Planner/User
- Next action: separately authorize a scoped commit and commit-derived Package
  closure before proposing the human-owned real S25 proof gate. Acceptance of
  this source gate does not authorize reconciliation or a fresh Remove/Install.
- Human decision or authorization required: commit, Package export, Unity/real
  process observation, real reconciliation, Remove/Install, push, and
  publication.

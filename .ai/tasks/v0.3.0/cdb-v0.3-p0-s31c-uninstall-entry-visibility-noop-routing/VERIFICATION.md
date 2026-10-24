# Verification: cdb-v0.3-p0-s31c-uninstall-entry-visibility-noop-routing

## Outcome

- Verdict: **FAIL — one bounded P2 contract finding; source acceptance remains a User decision.** No confirmed BLOCKER under the user's severity boundary.
- Workflow: `codedb-workflow-v2`, revision `2.6`; review mode `GUARDED`.
- Actual route: task-scoped sequential `FAST_SUBAGENT`, independent read-only Verifier, inherited configured model/reasoning without override; no recursive delegation.
- Delegation: `TASK_SPECIFIC`, user approval on 2026-10-17.
- Frozen identity: unchanged HEAD `279b442c657676d1adbda7d15151a3770682a674` plus the four final hashes in `SOURCE-SHA256.md`. All four current file hashes match. Incoming Manager edits remain included; HEAD alone is not this snapshot.
- Reviewed claims: frozen UI labels/callbacks, unconditional header request, repeated-request protection, canonical local no-op/refusal, exact action evidence and durable release, and the stated evidence limits.

## Evidence

- Reused final `-c` Editor and EditorTests compilation logs: PASS; three existing-site warnings in Editor compile, no test-compile errors.
- Reused `-b` execution: 22 focused method/case invocations passed before the canonical-reader/native boundary; overall exit **1**, not PASS.
- Rechecked manifest/driver hashes against `SOURCE-SHA256.md`; examined `-b`/`-c` source entries. Product/UI sources match across both; the changed test-source hash belongs to the unexecuted full-session method described by Coder.
- Targeted static checks only: four-file diff and named direct dependency excerpts (canonical integration/current readers, action context/result, Manager resolver/session/journal, and existing uninstall authority/observation).
- Path provenance: task-local driver/output are repository-local; reused manifests identify original source inputs, references, tools and environment redirects. No generated production substitute or Unity-native replacement was admitted.
- Scoped `git diff --check`: PASS.
- Tests rerun: **none**. Unity, Provider, real Install/Uninstall, process control, package/export, commit and reference switching: **NOT RUN / NOT AUTHORIZED**.

## Findings And Limits

### F1 — P2: COMPLETE desired state is treated as sufficient proof of no uninstall work

Location: `com.rice.ai-codedb/Editor/AICodedbActions.cs:210-213`.

The new shortcut returns successful `NoActionNeeded` for every canonical
`UNINSTALLED / COMPLETE` document before reading current-instance evidence.
The canonical integration reader validates that document's identity/schema;
it does not reconcile it with current selection or prove that relevant effects
are absent (`AICodedbProjectIntegrationState.cs:211-229`). Thus a valid COMPLETE
document plus a valid selected/current instance is reported as nothing to
uninstall instead of the frozen contract's explicit conflict refusal.

This is a concrete semantic difference from the existing backend: its
`Get-CurrentProjectRemovalAuthority` rejects UNINSTALLED plus selected authority
(`codedb-instance-engine.ps1:5205-5210`). The Manager's retained-effects
observation binds selected resources but does not replace that desired-state /
selected-authority consistency check. The local shortcut prevents that check
from running. It cannot be justified by saying that the canonical document
reader has already authenticated absence.

This was established by source tracing, not by an executed Unity scenario.
No new deletion/termination authority is introduced, so this finding is not
classified as a confirmed data-loss/process-safety BLOCKER. User/Planner should
choose FIX, DEFER, or accept the narrower no-op guarantee. A bounded correction
would preserve the existing canonical no-install proof while returning an
explicit refusal or the existing backend route when COMPLETE is contradicted
by current evidence; it need not add historical recovery or new authority.
The existing COMPLETE test (`AICodedbManagerUiTests.cs:89-92`) does not cover
this selected-instance conflict and did not execute past the native boundary.

### F2 — FOLLOW-UP: small pre-admission busy-projection window

Locations: `AICodedbManagerWindow.cs:2344-2355`, `:2921-2966`.

`TryStart` creates a running session before the asynchronous durable-admission
read, but `_userActionInFlight` is set after that await. The busy predicate
does not directly include `session.IsRunning`; it relies on the next Editor
update to attach the session. A callback in that short projection gap can show
another confirmation. `TryStart` still refuses a second session/writer, and
ordinary Editor updates close the gap. This is a timing-hardening follow-up,
not a current blocker or evidence of duplicate mutation. The executed counter
test proves behavior for an already-true supplied busy flag only.

### Passing source-review scope

- Ready Overview label and callback route to Uninstall; NotIntegrated and
  Uninstalled retain Install. NeedsAttention preserves fresh-install recovery
  priority, then eligible Remove Integration, otherwise Uninstall.
- Header Uninstall is unconditionally added and invokes the internal confirmed
  action; cached readiness/preflight does not hide it.
- Already-busy callbacks observe progress before confirmation; session start
  and durable journal admission prevent a second writer.
- Local outcomes carry the ambient exact action ID, explicit
  `PreEffectRefusal`, and neither authoritative-terminal nor terminal-for-action
  flags. AsyncLocal action context flows through the read task.
- The existing resolver accepts matching local evidence before looking for a
  writer. Exact journal release, session completion, and no-reconcile checks
  accept this existing boundary without fabricating an UNINSTALLED terminal.
  Release failure retains recovery rather than permitting an unproven next
  mutation. This chain is **static evidence only**.
- Invalid integration and Installed with missing/invalid current evidence
  return Blocked. UNINSTALLED/PENDING proceeds to existing internal admission.

### Evidence limits retained

The first canonical fresh-reader assertion encountered Unity's unavailable
`Application.isBatchMode` native initializer under standalone Mono. Remaining
reader cases, resolver/journal execution, full session completion and repeat
session startup are compiled but **NOT RUN**. This is the frozen
`ENVIRONMENT_INCOMPLETE` evidence boundary, not a product finding or a reason
to repair/retry the isolation environment. Human Unity and real uninstall
acceptance remain open. S31-B runtime-stop/deactivation/Provider work and
historical/reconnect cleanup remain deferred.

## Handoff

- Current task/status: S31-C source review complete, findings returned once;
  source not accepted by this review.
- Next notification: Planner/User; no repair request sent to Coder.
- Next action: decide `FIX | DEFER | ACCEPT | STOP`, preserving the native
  evidence limits. Any repair review covers F1 and its adjacent regression
  only; F2 stays FOLLOW-UP unless User includes it.
- No delivery, commit, package or Unity authority follows from this report.

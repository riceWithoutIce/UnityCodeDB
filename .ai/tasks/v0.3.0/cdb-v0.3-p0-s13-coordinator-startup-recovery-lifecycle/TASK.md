# Task: cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle
\n+## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY_AWAITING_AUTHORIZATION
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: v0.3.verifier.deep after a stable passing result and Planner routing
- Review mode: RELEASE
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`
  (`FIX_REQUIRED / CLOSED_WITH_CLASSIFIED_FAILURE`)
- Roadmap position: Runtime Release Gate; Discover Read has not started
- Requirement sources:
  - `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`;
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p0-supervisor-runtime-recovery.md`;
  - `com.rice.ai-codedb/Documentation~/v0.3.0-p1-supervisor-lifecycle.md`;
  - `com.rice.ai-codedb/Documentation~/development-workflow.md`.

## Objective

- Close the persistent selected-coordinator startup failure exposed by S12,
  then complete one fresh visible Unity lifecycle pass from Cold Start through
  Manager observation, Play with proved Domain Reload, return to Edit Mode,
  and normal Editor shutdown.
- Keep failure attribution, production correction, direct fixture evidence,
  and visible lifecycle acceptance inside this one continuous engineering
  task. Do not create command-level, instrumentation-only, or rerun subcards.
- Preserve the authenticated outer Supervisor, selected immutable instance,
  main-thread zero-I/O, external-process isolation, and fail-closed contracts
  already established by S02-S12.

## Starting Failure

- S12 exhausted its three authorized visible scenario attempts and is closed.
  No fourth S12 scenario is allowed.
- The final S12 Editor compiled without a current C# compiler error, but Cold
  Start remained `NeedsAttention` with no operational selected coordinator.
- Manager reported `Selected instance coordinator is not operational.` The
  outer Supervisor and selected instance remained identifiable, with no
  observed duplicate owner, manual Reinstall, or main-thread violation.
- A focused Node fixture proved the S12 routing repair: admitted
  `materialize:Probe` and `materialize:Upgrade` retry coordinator admission
  before materialization and fail closed without invoking the materializer
  when coordinator admission fails.
- A later fresh Supervisor used that repaired Package script and still could
  not start the real selected coordinator. The remaining blocker is therefore
  the persistent coordinator startup cause, not stale Supervisor code or a
  missing re-admission opportunity.

## Frozen Starting Snapshot

- Branch: `codex/v0.3.0-legacy-workflow`.
- Committed HEAD: `9aada838e26879810a4f79760273ca66340ebf12`.
- S12 decision:
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s12-fresh-lifecycle-integration/DECISION.md`;
  bytes `6353`; SHA-256
  `85908c712c49f712e888897c117af0d11b25297059325e03f3593512c490f425`.
- S12 result:
  `.ai/tasks/v0.3.0/cdb-v0.3-p0-s12-fresh-lifecycle-integration/RESULT.md`;
  bytes `31852`; SHA-256
  `1262a60123fa184aec6965e9528369fc7cac5c1237d0c32214fe9e635eb6281e`.
- Admission must parse and verify every frozen source/test identity in the S12
  decision table. Do not manually reconstruct those identities in a command.
- Reuse the five protected validation-project identities recorded in the S12
  task. `UnityValidationProject/ProjectSettings/ProjectSettings.asset` remains
  an unrelated modified input. Preserve it byte-for-byte.
- `com.rice.ai-codedb/Documentation~/development-workflow.md` remains an
  unrelated modified workflow input. Do not change it in this task.

## Continuous Scope

### Phase A: Closed-Project Diagnosis And Correction

1. Require `UnityValidationProject/` to be closed and confirm zero matching
   Unity processes once before source work.
2. Preserve the existing S12 coordinator-readmission repair. Trace the direct
   selected-coordinator launch contract from the authenticated Supervisor to
   the Package-owned immutable coordinator and classify the persistent startup
   failure before changing recovery policy.
3. Use existing bounded status/error paths first. If the terminal cause cannot
   be attributed without protected runtime inspection, add only a stable,
   sanitized failure category to the authenticated Supervisor/Bridge/S12
   evidence path. It may expose a reviewed reason code and child exit category;
   it must not expose tokens, command lines, raw stderr, user-profile paths,
   runtime documents, or machine-specific absolute paths.
4. Correct the confirmed cause only inside the writable surface below. Do not
   convert a persistent failure into an unbounded retry, another command owner,
   direct materializer fallback, or automatic Reinstall.
5. Complete the direct static evidence and one focused Node L0 batch before
   requesting visible Unity. A same-cause mechanical fixture correction may
   receive one retry; an independent failure stops the phase.

### Phase B: Human-Visible Runtime Evidence

1. After Phase A passes, return one `HUMAN_UI_ACTION_REQUIRED` handoff. The
   human opens only the existing `UnityValidationProject/` with the registered
   Unity `2022.3.47f1`; Coder never substitutes BatchMode, hidden Unity, Unity
   MCP, Unity Hub, or another project.
2. A bounded diagnostic opening is permitted only when Phase A had to add the
   sanitized failure category and the cause still requires one real capture.
   It must produce a classifiable cause and then return to a proved-closed
   baseline before correction. It is not an unchanged rerun.
3. After the confirmed correction, execute one fresh complete scenario:

```text
Cold Start -> stable Ready with operational coordinator
-> Manager closed baseline -> open/repaint/tab observation
-> Play -> proved Domain Reload -> stable Play
-> return to Edit Mode -> normal Editor shutdown
```

4. Capture one bounded evidence aggregate at each handoff. Manager observation
   must not trigger migration, materialization, a second Supervisor, or full
   status work. Play/reload must preserve the authenticated Supervisor and
   selected instance. Final shutdown must remain non-blocking and affect only
   authenticated project-owned backends.
5. The visible envelope contains at most one diagnostic opening when required
   and one corrected complete scenario. There is no unchanged rerun. Each
   startup or transition wait is bounded to 300 seconds; timeout returns
   process ownership to the human and never authorizes termination.

## Source Boundary

Writable only when required by the confirmed cause:

- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`

Direct read-only immutable inputs:

- `com.rice.ai-codedb/Payload~/payload-manifest.json`
- `com.rice.ai-codedb/Payload~/Generations/poc.34/generation-manifest.json`
- `com.rice.ai-codedb/Payload~/Generations/poc.34/coordinator/codedb-watch-coordinator.mjs`
- `com.rice.ai-codedb/Payload~/Generations/poc.34/scripts/manage-codedb-project-watch.ps1`

`Payload~/Generations/poc.34/` is immutable. If the confirmed repair requires
changing any byte in that generation, stop with
`IMMUTABLE_GENERATION_TRANSITION_REQUIRED` and return one bounded transition
proposal to Planner. Do not edit the generation in place, mint an undeclared
generation, or expand the task automatically.

## Protected And Out-Of-Scope Boundaries

- Do not enumerate, read, edit, clean, stage, or make byte-identity claims
  about `UnityValidationProject/.codex/` or `UnityValidationProject/AIWork/`.
  Natural product-owned writes during an authorized visible lifecycle are
  permitted, but evidence must use the authenticated/sanitized surface.
- Do not change current-instance/control/activation/retirement schemas,
  selected-instance identity, immutable generation policy, Provider behavior,
  query/index policy, or the formal CodeDB usage rule.
- Discover Read, query corpus, `rg` reminders, stale/missing-index matrices,
  third-party Package-only acceptance, real Codex Desktop/MCP injection,
  publication, deployment, and release are out of scope.
- Do not stop Unity, a Supervisor, coordinator, Provider, external MCP client,
  or unrelated process. Normal final Editor UI shutdown is human-owned.
- Do not reset, clean, stash, rebase, revert, normalize protected inputs,
  commit, push, or contact Verifier automatically.

## Test And Evidence Plan

- Static batch: one bounded syntax/source-contract batch over actual changed
  files, including sanitized-field exclusions and coordinator-before-
  materializer ordering when those paths change.
- Node L0: one focused Supervisor/coordinator batch for the confirmed cause;
  at most one same-cause fixture correction and retry.
- Affected C# L1: only direct lifecycle/evidence/Manager tests when C# behavior
  changes. EditMode still requires explicit human authorization and must use
  `UnityValidationProject/`; never start it automatically.
- Runtime: the human-visible Phase B envelope above, with one bounded read of
  each task-owned log/evidence window and no repository-wide log scan.
- Final: one scoped status review and one scoped `git diff --check` over actual
  task changes. Do not run full EditMode, the full Supervisor suite, PlayMode
  Test Runner, another Unity project, Unity MCP, or a broad regression.

## Stop Conditions

- A frozen identity drifts, the validation project is open during Phase A, or
  Package/Unity binding differs from the declared project/version.
- Attribution requires direct protected-runtime inspection, raw sensitive
  diagnostics, global configuration, process termination, or a file outside
  the declared boundary.
- The repair requires immutable `poc.34` mutation or a new generation without
  a separate Planner/User decision.
- Focused evidence exposes an independent production failure, the permitted
  retry is consumed, UI control/human handoff is unavailable, a visible wait
  times out, or the visible envelope is exhausted.
- A completed failing runtime scenario is recorded as
  `COMPLETE / TEST_FAILURE_CLASSIFIED` or
  `COMPLETE / INFRASTRUCTURE_FAILURE_CLASSIFIED`; it is not silently rerun.

## Definition Of Done

- The persistent coordinator startup cause is identified with sanitized,
  source-backed evidence and corrected without weakening ownership or
  fail-closed behavior.
- Fresh Cold Start reaches stable Ready with one authenticated Supervisor, one
  operational selected coordinator, one selected instance, no duplicate
  backend/materializer, and no manual Reinstall.
- Manager observation remains cached and all prohibited main-thread counters
  remain zero.
- Play and proved Domain Reload reconnect to the same Supervisor and selected
  instance, then return cleanly to Edit Mode.
- Normal final Editor shutdown is non-blocking, requests shutdown only for
  authenticated project-owned backends, preserves external/unrelated
  processes, and leaves zero matching validation-project Unity processes.
- Protected tracked inputs remain unchanged; all deferred runtime, consumer,
  third-party, Discover Read, and release boundaries are explicit.

## Result And Verification

- Coder writes one `RESULT.md` containing diagnosis, actual changes, bounded
  static/L0 evidence, each human handoff, the final visible scenario, frozen
  identities, and deferred boundaries. Same-cause work remains in this task.
- After Planner confirms one stable passing snapshot, route it once to
  `v0.3.verifier.deep` for targeted read-only RELEASE review. Verifier reuses
  runtime evidence and does not rerun Unity or the focused tests.
- Findings return once to Planner/User for `ACCEPT / FIX / DEFER / STOP`.

## Authorization Gate And Handoff

Current task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`  
Current status: `READY_AWAITING_AUTHORIZATION`  
Next notification: `UnityCodeDB v0.3 Planner / Human`  
Next action: authorize the continuous S13 envelope, then dispatch once to
`v0.3.coder.deep` while `UnityValidationProject/` remains closed  
Human decision or authorization required: S13 implementation/non-Unity
evidence, any affected EditMode batch, the human-visible runtime envelope,
immutable generation transition, Verifier routing, commit, push, publication,
and release remain explicitly gated

# Result: cdb-v0.3-p0-s12-fresh-lifecycle-integration

Status: BLOCKED
Classification: `BLOCKED / VISIBLE_UI_CONTROL_UNAVAILABLE`

## Task Admission Boundary

- The task card was read completely before implementation or Unity activity.
- Task-card identity matched the frozen dispatch: `14703` bytes, SHA-256
  `ca73b65c2d5c0c4477eff62b1bf15a43af89c6b925592b7bab557b66bd0ed423`.
- Requested execution profile: `v0.3.coder.deep`.
- The runtime did not expose a separately reportable model/reasoning identifier.

## Blocking Evidence

- The required visible-UI control readiness check used the approved
  `computer-use` surface inventory once.
- The returned native application inventory was empty: `apps: []`.
- Only browser surfaces were available. No native Unity application target or
  launch/control surface was available in this Coder session.
- TASK.md requires an immediate stop and human operator handoff when visible UI
  automation is unavailable. BatchMode, hidden/background Unity, Unity MCP,
  terminal-driven UI substitution, or another project are explicitly invalid
  substitutes.

## Changes And Execution

- Source changes: none.
- Test changes: none.
- Instrumentation changes: none.
- Workflow/configuration/validation-project changes: none.
- `RESULT.md` is the only file created by S12.
- Bounded admission was not executed after the UI-control stop condition.
- Visible Unity scenario attempts: `0/3`.
- Mechanical command corrections: `0/2`.
- L0 batches: `0`.
- Affected L1 batches: `0`.
- Unity, Unity Hub, Unity MCP, Supervisor, Node, Provider, and product
  PowerShell processes were not started.

## Protected And Deferred Boundaries

- `UnityValidationProject/.codex/` and `UnityValidationProject/AIWork/` were
  not enumerated, read, edited, or cleaned.
- No process was stopped, signaled, or otherwise controlled.
- No commit, push, publish, Verifier dispatch, task split, or checkpoint was
  performed.
- `NOT RUN`: frozen branch/HEAD/S11 repair/protected-input admission, visible
  cold start, Manager observation, repaint/tab changes, Play, proved Domain
  Reload, return to Edit Mode, normal Editor close, scoped lifecycle evidence,
  final identity/status/diff checks, and `git diff --check`.
- `DEFERRED`: all S12 lifecycle, instrumentation, Supervisor continuity,
  main-thread boundary, authenticated shutdown, consumer/runtime,
  third-party Package-only, publication, deployment, and release evidence.

## Completion Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`  
Current status: `BLOCKED / VISIBLE_UI_CONTROL_UNAVAILABLE`  
Next notification: `UnityCodeDB v0.3 Planner`  
Next action: arrange an approved human operator takeover, or re-dispatch the
same frozen S12 task to a Coder session with native visible Unity UI control;
then perform the bounded admission before any Unity launch and continue the
single authorized scenario envelope.  
Human action required: the visible Unity UI must be operated by a human or a
session with a targetable native-app control surface. Verifier routing,
commit, push, publication, release, or any substitute validation remains
unauthorized.

## Continuation Preparation

- Reused the previously admitted frozen task identity without repeating the
  admission check: TASK.md `14703` bytes, SHA-256
  `ca73b65c2d5c0c4477eff62b1bf15a43af89c6b925592b7bab557b66bd0ed423`;
  branch `codex/v0.3.0-legacy-workflow`; HEAD
  `9aada838e26879810a4f79760273ca66340ebf12`; package tree
  `69d2c3e970813c44b7f458bdc686da7fac354b52`; Unity
  `2022.3.47f1 (88c277b85d21)`; matching Unity process count `0`.
- Preparation changes remain limited to the S12 allowlist: lifecycle,
  manager, status snapshot, supervisor bridge, lifecycle evidence, and the
  two direct Editor test files. The added behavior is sanitized lifecycle
  evidence and bounded event/callback counters, main-thread prohibited-work
  tracking, Manager observation/cache/request counters, Supervisor and
  shutdown disposition evidence, initialization-path project identity
  validation, atomic quitting lease handoff, Supervisor PID/selected-instance
  snapshot parsing, removal of automatic Manager watcher refresh from
  observation paths, retention of explicit Refresh requests, and pure
  lifecycle/Manager source-contract coverage.
- Evidence completed: C# AST parse passed for all seven changed/new C# files;
  scoped source-contract checks passed for Manager observation versus explicit
  Refresh behavior, quitting-path filesystem/process/pipe exclusion, and
  sensitive-field exclusion from instrumentation; scoped `git diff --check`
  passed. The first two AST command attempts had Roslyn loading/path errors;
  the final command reused the loaded Roslyn assemblies and passed.
- No C# compilation, Unity, Unity Hub, Unity MCP, Supervisor, Node, Provider,
  materializer, external process, EditMode, L0, or L1 test was run. No process
  was stopped and no protected `UnityValidationProject/.codex/` or
  `UnityValidationProject/AIWork/` path was enumerated or read.
- Existing unrelated/accepted worktree changes were preserved, including
  ProjectSettings, workflow documentation, and HostPayloadMaterializer.
  No reset, clean, stash, rebase, revert, commit, push, or Verifier dispatch
  was performed.
- Stop condition remains active: `HUMAN_UI_ACTION_REQUIRED` under the already
  recorded `BLOCKED / VISIBLE_UI_CONTROL_UNAVAILABLE` classification. The
  prepared snapshot is not presented as runtime-validated; no further Coder
  action is authorized until the human-visible Unity lifecycle action is
  available.

## Continuation Completion Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`

Current status: `BLOCKED / VISIBLE_UI_CONTROL_UNAVAILABLE`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: visibly open the existing `UnityValidationProject/` with the
registered Unity `2022.3.47f1`. The expected first observation is that
compilation completes and CodeDB reaches a stable cached state without manual
Reinstall or a duplicate owner. After that human-visible action, Planner may
re-dispatch or resume the same frozen S12 bounded scenario envelope; Verifier
routing remains a Planner decision.

## Cold Start Continuation Attempt 1

Status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

- Planner resumed the same frozen S12 task after the human visibly opened the
  existing validation project. The previously passed admission and frozen
  identities were reused; admission was not repeated.
- One bounded passive process observation found target Unity PID `25400` with
  project path `G:\RiceProgram\UnityCodeDB\UnityValidationProject` and
  executable `F:\unity\unity-2022.3.47f1\Editor\Unity.exe`. This matches the
  frozen project and Unity `2022.3.47f1`. A separate Unity PID `4664` belonged
  to another project and was not a matching validation-project process.
- Because the target identity and version matched and the visible startup had
  begun, this Cold Start is recorded as Unity scenario attempt `1/3`.
- The bounded Unity Editor log read showed that Package compilation did not
  complete successfully. An earlier product-assembly pass reported
  `AICodedbManagerWindow.cs(2592,68): error CS0103: The name
  'AICodedbManagerObservationKind' does not exist in the current context`.
  Unity subsequently imported the new evidence source and reloaded the product
  assembly, but the final Editor test assembly compilation remained failed:
  `AICodedbManagerUiTests.cs(157,40): error CS0117: 'Is' does not contain a
  definition for 'Greater'`. The same compilation output also reported
  duplicate `System.IO` and `System.Text` using-directive warnings at lines 6
  and 7.
- The latest sanitized `CODEDB_S12_EVIDENCE` checkpoint was
  `reconcile_completed`: `domain_reload_count=1`,
  `reconcile_started_count=2`, `reconcile_completed_count=2`,
  `last_product_state=NeedsAttention`, `materializer_command_count=1`,
  `direct_materializer_fallback_count=0`, `supervisor_ensure_count=2`,
  `supervisor_missing_state_ensure_count=1`,
  `supervisor_observation_count=2`, `supervisor_identity_change_count=0`,
  `supervisor_pid=16752`, `coordinator_pid=0`,
  `selected_instance_id=7f02adc0f68f43c3888bf9375cc865ec`, and
  `selected_generation_id=poc.34`.
- All eight reported prohibited main-thread work counters were `0`, and
  `main_thread_violation_count=0`. Manager open, enable, repaint, tab-change,
  cache-read, automatic-status, explicit-status, and watcher-status counters
  were all `0`, consistent with the Manager remaining closed.
- No manual Reinstall event or Supervisor identity change was observed in the
  bounded evidence. The single reported Supervisor PID and zero identity
  changes do not indicate a duplicate owner, but the compilation failure and
  `NeedsAttention` state prevent a successful stable-cached Cold Start claim.
- The passive process/log command completed with exit code `0` in approximately
  `4.2` seconds. No Unity UI operation, Unity/Hub/MCP launch, process start,
  process stop, process close, alternative process, direct protected-path
  inspection, source fix, test rerun, commit, push, or Verifier dispatch was
  performed.

## Cold Start Failure Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`

Current status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

Scenario attempts: `1/3`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: review the classified Editor test compilation failure and decide
whether to authorize a concrete same-cause correction inside the same frozen
S12 task before any corrected visible scenario. Manager observation, Play,
Domain Reload continuation, shutdown, Verifier routing, commit, and push were
not reached. Visible Editor and process ownership remain with the human.

## Same-Cause Correction Attempt

Status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

- Applied exactly the authorized one-line test-only correction in
  `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`: changed
  `Is.Greater(refreshStart)` to `Is.GreaterThan(refreshStart)` at the declared
  assertion. No production file, duplicate using warning, or other source was
  changed.
- The open Unity Editor was left untouched to detect the file naturally. No
  Unity UI operation, launch, close, process control, Unity MCP, test runner,
  L0/L1 test, commit, push, or Verifier dispatch was performed. This hot
  recompilation correction does not consume corrected scenario attempt `2/3`.
- One bounded passive log/evidence check was run after an 8-second natural
  recompilation allowance. Command:
  `Start-Sleep -Seconds 8; Get-Content -LiteralPath
  "$env:LOCALAPPDATA\Unity\Editor\Editor.log" -Tail 1800 |
  Select-String -Pattern "error CS|CODEDB_S12_EVIDENCE|ScriptCompilation|Finished
  compiling graph|Tundra build failed|Compilation failed|ReloadAssembly"`
  Exit code `0`; wall time approximately `7.33s` as reported by the command
  runner.
- The bounded output still contained the original
  `AICodedbManagerUiTests.cs(157,40): error CS0117: 'Is' does not contain a
  definition for 'Greater'` (reported more than once). Therefore this check
  did not prove that the original error disappeared. No new independent first
  compiler error was acted upon; the task stops here without investigation or
  retry.
- The latest available sanitized evidence remained
  `last_product_state=NeedsAttention`, with `materializer_command_count=1`,
  `supervisor_pid=16752`, `supervisor_identity_change_count=0`, and
  `main_thread_violation_count=0`; Manager counters remained zero. Stable
  cached Cold Start is still unproven.
- One scoped command was run:
  `git diff --check --
  'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs'`
  Exit code `0`; wall time approximately `0.27s`. Retry count remains `0`.

## Same-Cause Correction Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`

Current status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: review why the bounded post-correction log still reports the
original `Is.Greater` compile error and decide the next authorized same-scope
step. Do not treat this as corrected scenario attempt `2/3`; no Manager, Play,
Domain Reload, shutdown, Verifier, commit, or push action was reached.

## Corrected Cold Start Attempt 2

Status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

- Planner supplied the required proved-closed boundary before this attempt:
  the matching `UnityValidationProject/` Unity process count was `0`, after
  which the human visibly opened the same project. This is the formal
  corrected Cold Start scenario attempt `2/3`; admission was not repeated.
- One bounded passive process check found exactly one matching target process,
  PID `27776`, with project path
  `G:\RiceProgram\UnityCodeDB\UnityValidationProject` and executable
  `F:\unity\unity-2022.3.47f1\Editor\Unity.exe`. The target identity and
  frozen Unity version matched.
- After a bounded 12-second natural compile/import allowance, one filtered
  Unity Editor log/evidence read found no `CS0117` for
  `AICodedbManagerUiTests.cs:157` and no current `error CS` line in the
  returned tail. The corrected test assertion was therefore no longer
  reported by this bounded window. No new first compiler error was observed.
- The latest sanitized `CODEDB_S12_EVIDENCE` was a
  `reconcile_completed` checkpoint with `domain_reload_count=1`,
  `reconcile_started_count=2`, `reconcile_completed_count=2`,
  `last_product_state=NeedsAttention`, `materializer_command_count=2`,
  `direct_materializer_fallback_count=0`, `supervisor_pid=11892`,
  `supervisor_identity_change_count=0`, selected instance
  `7f02adc0f68f43c3888bf9375cc865ec`, and selected generation `poc.34`.
  All eight prohibited main-thread work counters were `0`, and
  `main_thread_violation_count=0`. Manager open/enable/repaint/tab/cache and
  status-request counters were all `0` because Manager observation was not
  entered.
- No manual Reinstall or duplicate-owner signal was observed in the bounded
  evidence. Supervisor/selected-instance identity stayed stable within the
  observed startup/reconcile window. However, `NeedsAttention` does not prove
  the required stable cached product state, so the corrected Cold Start did
  not pass the task's entry criterion and no Manager action was requested.
- The bounded process/log command exited `0` with wall time approximately
  `14.1s` (including the 12-second natural compile allowance). No UI action,
  Unity/Hub/MCP launch, process control, test runner, L0/L1 test, protected
  path inspection, source repair, commit, push, or Verifier dispatch occurred.
  This attempt consumed corrected scenario attempt `2/3`; no retry was made.

## Corrected Cold Start Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`

Current status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

Scenario attempts: initial `1/3`; corrected `2/3`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: review the remaining `NeedsAttention` product state as the
precise Cold Start failure and decide whether a concrete same-scope correction
is authorized before the final available corrected attempt. Manager closed
observation/open/repaint/tab change, Play, Domain Reload continuation,
shutdown, Verifier routing, commit, and push were not reached.

## Bounded Read-Only Production Diagnosis

Status: `COMPLETE / TEST_FAILURE_CLASSIFIED` (diagnosis only; scenario `3/3`
not started)

- The human Manager diagnosis was recorded as the runtime symptom:
  `Host payload = Needs Setup / Checking`, detail `Selected instance
  coordinator is not operational.`, with Current instance, Host generation,
  Provider executable, Project MCP config, and MCP availability also at
  `Needs Setup / Checking`. Control-contract migration was
  `Inactive / Not required`. The supplied evidence remained Supervisor PID
  `11892`, coordinator PID `0`, selected instance
  `7f02adc0f68f43c3888bf9375cc865ec`, generation `poc.34`, reconcile `2/2`,
  materializer command count `2`, and main-thread violation count `0`.
  The task-owned engine script was not read; this diagnosis used the supplied
  Manager detail and only the direct S12 files listed below.

### Findings

1. `AICodedbEditorLifecycle.ShouldReconcileCoordinator` contains the expected
   `coordinatorPid <= 0 => true` branch at the current source decision, along
   with invalid pointer, generation mismatch, and dead-process branches.
   However, a bounded repository search found this helper referenced only by
   `AICodedbEditorLifecycleTests.cs`; there is no production caller. Therefore
   coordinator PID `0` does not itself trigger the production lifecycle path.

2. The actual lifecycle path is bounded and fail-closed. The worker first runs
   `materialize Probe`, then builds product status. With a current selected
   instance, current prerequisite/installed/configured layers, and unavailable
   MCP evidence, `ResolveCurrentInstanceConvergencePlan` selects
   `RecoverAvailability`. That path calls `watcher Ensure` before a second
   `materialize Probe`, increments a bounded recovery counter, schedules a
   retry only while the counter is below
   `MaximumCurrentInstanceAvailabilityRecoveryAttempts` (`3`), and finally
   returns `NeedsAttention` without replacing the current instance. The
   observed materializer count of `2` is consistent with the initial Probe and
   one recovery Probe; no unbounded loop or replacement deployment was
   inferred.

3. The outer Supervisor can remain alive while its selected coordinator is
   unavailable. On daemon startup, `codedb-project-supervisor.mjs` refreshes,
   calls `ensureCoordinator` once, catches a coordinator-start failure by
   emitting `coordinator_start_failed`, refreshes again, and continues serving
   its own authenticated pipe. Its `materialize` dispatch admits the operation
   and calls `runMaterializer` directly; it does not call `ensureCoordinator`
   before `Probe` or `Upgrade`. The Bridge correspondingly ensures/connects the
   outer Supervisor and sends the command, but has no selected-coordinator
   retry in that command path. This explains Supervisor continuity with
   `coordinator_pid=0` and the materializer's selected-coordinator error.

4. The direct tests cover the pure PID decision, watcher-before-availability
   ordering, current-instance recovery plan, and Supervisor offline retirement.
   They do not cover the transition “initial `ensureCoordinator` fails, outer
   Supervisor remains alive, coordinator later becomes startable, then a
   `materialize Probe/Upgrade` request re-ensures the coordinator before
   invoking the materializer.”

5. This is classified as an existing route gap exposed by the fresh Cold Start,
   not as a demonstrated S12 regression. The Node Supervisor file has no
   worktree diff. The relevant Lifecycle and Bridge diffs add evidence
   instrumentation around the existing worker/command paths; they do not
   change the `RecoverAvailability` order or add/remove the Node
   `ensureCoordinator` call. This is source-based diagnosis only; no new
   runtime claim was made beyond the supplied Manager/evidence output.

### Minimal Correction Proposal

Within the existing S12 allowlist, update the Node Supervisor maintenance
route so admitted `materialize:Probe` and `materialize:Upgrade` operations first
perform the existing authenticated `ensureCoordinator` step, then invoke
`runMaterializer`. A failed coordinator ensure must complete the operation as a
terminal fail-closed error and must not invoke the materializer. Existing
Supervisor single-flight admission, coordinator ownership/authentication, and
the current `watcher Ensure` ordering remain unchanged. Add one direct fixture
regression proving the initial coordinator-start failure leaves the outer
Supervisor alive, and that a later Probe/Upgrade retries coordinator admission
before the materializer and does not create a duplicate owner.

This proposal is limited to `Tools~/codedb-project-supervisor.mjs` and its
direct `Tests~/test-codedb-project-supervisor.mjs` fixture. It does not require
changing C# authority, the control contract, the selected-instance state, or
the Manager. It is a proposal only; no source was modified in this diagnosis.

### Non-Unity Evidence Plan

- First perform a bounded AST/source-contract check for the dispatch ordering
  and the terminal failure branch.
- Run one focused fixture-owned Node Supervisor L0 scenario covering the
  initial failed coordinator start, outer Supervisor liveness, later
  re-admission, ordering, and duplicate-owner exclusion. Do not start Unity or
  use Unity MCP.
- Reuse the existing C# pure decision evidence for
  `ShouldReconcileCoordinator`, `ResolveCurrentInstanceConvergencePlan`, and
  `RunWatcherThenAvailability`; do not run EditMode or a full regression.
- Only after Planner reviews the focused evidence should the human-owned
  Manager/Unity state be considered for the final corrected scenario `3/3`.

### Diagnosis Boundary And Routing

- No Unity UI action, Manager command, process start/stop/control, Unity MCP,
  test execution, source modification, admission rerun, protected-path read,
  log clearing, commit, push, or Verifier dispatch was performed.
- Current S12 status remains `COMPLETE / TEST_FAILURE_CLASSIFIED`; corrected
  scenario `2/3` remains the last executed scenario. The current Manager and
  Unity ownership stays with the human.
- Next notification: `UnityCodeDB v0.3 Planner`. Planner must decide whether
  to authorize the proposed direct Node Supervisor correction and focused
  non-Unity evidence before any scenario `3/3`; no automatic retry or UI action
  is requested by this diagnosis.

## Bounded Production FIX Attempt

Status: `BLOCKED / FOCUSED_L0_FIXTURE_FAILURE`

- Implemented only the approved production routing change in
  `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`: admitted
  `materialize:Probe` and `materialize:Upgrade` operations now await the
  existing `ensureCoordinator(context, operation)` before calling
  `runMaterializer`. A coordinator ensure rejection completes the admitted
  operation terminally and prevents materializer invocation. All other
  materializer actions retain their direct route; watcher, shutdown,
  control-contract, C# authority, Manager, and selected-instance semantics
  were not changed.
- Added only the direct fixture and focused filter in
  `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`. The fixture
  uses a temporary synthetic project, one fixture-owned coordinator server,
  synthetic ensure gates, materializer counters, same-owner assertions, and
  cleanup through the existing harness finally path. The first fixture
  correction synchronized the synthetic coordinator script and both
  generation-manifest hashes after the script was replaced.
- Bounded AST/source-contract check: one command covering both JS files with
  `node --check` plus source assertions for Probe/Upgrade preflight ordering,
  unchanged non-Probe/Upgrade routing, and the focused filter. Exit `0`;
  wall time was not captured by the command wrapper and is recorded as
  `unavailable` rather than estimated.
- Focused Node Supervisor L0 batch, first run, exactly once before correction:
  `$env:RICE_CODEDB_SUPERVISOR_TEST_FILTER='coordinator-readmission'; node
  com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`. Exit `1`,
  wall `0.4697781s`. This was a fixture-only mechanical failure before the
  scenario reached the intended assertions: selected-generation closure
  validation rejected the replaced coordinator script because its manifest
  hash was stale.
- One authorized corrected retry of that exact focused batch was run, with no
  further retry. Exit `1`, wall `0.4886341s`. The retry reached the fixture
  start path but exposed a second independent fixture-construction failure:
  `Selected instance does not match the Package-owned immutable generation
  closure.` at the new scenario assertion path. Per budget and stop
  conditions, no investigation or additional repair was performed.
- Final scoped check, exactly once:
  `git diff --check --
  com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
  com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`. Exit `0`,
  wall `0.2504807s`.
- Batch/retry ledger: AST/source-contract `1`; focused Node L0 `1`; corrected
  retry `1/1` permitted and consumed; additional retries `0`; Unity/EditMode,
  C# L1, other L0, full Supervisor batch, Unity MCP, UI actions, and product
  process validation `0`.
- The production change is not dynamically accepted because the focused L0
  did not reach a valid terminal fixture result. Scenario attempt `3/3` was
  not started. Current visible Unity and Manager ownership remains with the
  human; no Unity, Manager action, protected-path read, process control,
  commit, push, or Verifier dispatch occurred.

## Bounded FIX Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`

Current status: `BLOCKED / FOCUSED_L0_FIXTURE_FAILURE`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: review the two fixture-construction failures and decide whether to
authorize a new bounded harness correction attempt. Do not establish a proved-
closed baseline or begin corrected scenario `3/3` until the focused fixture
passes on a separately authorized run. Verifier routing remains deferred;
there was no commit or push.

## Independent Harness Correction And Evidence Attempt

Status: `COMPLETE / FOCUSED_L0_PASS`

- This was a new independent harness-only attempt. The production
  `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` was not modified in
  this attempt; its prior bounded FIX remains the only production change.
- Modified only `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`:
  the generated coordinator script now uses ESM
  `import fs from 'node:fs';`; after replacing the synthetic coordinator bytes,
  both Package and Project generation-manifest entries are refreshed, then the
  existing Project generation manifest hash is written to
  `instance.json.generation_manifest_sha256`, and finally the current-instance
  selection is rewritten with the current `instance.json` hash. Existing fake
  coordinator server, ready-marker state transition, same-owner assertion,
  focused filter, and `finally` cleanup were preserved.
- Bounded static fixture self-consistency check: one command with `node
  --check` plus source assertions for ESM/no CommonJS require, ordered
  generation -> instance -> selection hash-chain updates, focused filter, and
  fixture cleanup. Exit `0`; wall time was not captured by the wrapper and is
  recorded as `unavailable`, not estimated.
- Focused Node L0 batch, exactly once, command:
  `$env:RICE_CODEDB_SUPERVISOR_TEST_FILTER='coordinator-readmission'; node
  com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`. Exit `0`, wall
  `2.9515044s`; output:
  `[PASS] Supervisor coordinator re-admission precedes Probe/Upgrade
  materialization and blocks materializer on ensure failure.` The fixture
  proved initial ensure failure with the outer Supervisor still alive, later
  Probe and Upgrade re-admission before materializer, materializer ordering and
  count, terminal fail-closed ensure failure with no materializer increment,
  unchanged coordinator owner, and unchanged outer Supervisor PID.
- Retry ledger for this independent attempt: focused L0 `1`, retry `0/0`.
  The earlier attempt's retry budget is not reused or extended here.
- Final scoped check, exactly once:
  `git diff --check --
  com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
  com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`. Exit `0`, wall
  `0.2618469s`.
- No Unity/Manager UI action, scenario `3/3`, Unity MCP, EditMode, C# test,
  full Supervisor suite, other L0/L1, protected-path read, product process
  control, commit, push, or Verifier dispatch was performed. Current Unity and
  Manager ownership remains with the human.

## Independent Harness Evidence Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`

Current status: `COMPLETE / FOCUSED_L0_PASS`

Scenario attempts: initial `1/3`; corrected `2/3`; scenario `3/3` not started.

Next notification: `UnityCodeDB v0.3 Planner`

Next action: review the focused production-routing evidence, establish a new
proved-closed baseline through the human-owned Unity/Manager lifecycle only if
the frozen task process permits it, and separately decide whether to authorize
scenario `3/3`. Verifier routing remains a Planner decision; no automatic UI
action or further Coder retry is requested.

## Final Corrected Cold Start Attempt 3

Status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

- Planner supplied a proved-closed boundary before this final corrected
  scenario: matching `UnityValidationProject/` Unity process count was `0`,
  then the human visibly opened the existing project with Unity
  `2022.3.47f1`. This is the final authorized continuous scenario attempt
  `3/3`; admission was not repeated and no fourth attempt is permitted.
- One bounded passive process check found exactly one matching target process,
  PID `4752`, executable
  `F:\unity\unity-2022.3.47f1\Editor\Unity.exe`, with project path
  `G:\RiceProgram\UnityCodeDB\UnityValidationProject`. Unity identity and
  project identity matched the frozen task.
- One bounded Editor.log tail aggregation found no current `error CS`, no
  `Tundra build failed`, and no additional red C# compiler error in the
  returned window. The script compilation marker reported `0.567698s`.
- The latest sanitized `CODEDB_S12_EVIDENCE` was
  `checkpoint=reconcile_completed` with `domain_reload_count=1`,
  `reconcile_started_count=2`, `reconcile_completed_count=2`,
  `last_product_state=NeedsAttention`, `materializer_command_count=1`,
  `direct_materializer_fallback_count=0`, `supervisor_ensure_count=2`,
  `supervisor_missing_state_ensure_count=1`,
  `supervisor_observation_count=2`, `supervisor_pid=26672`,
  `coordinator_pid=0`, `supervisor_identity_change_count=0`, selected instance
  `7f02adc0f68f43c3888bf9375cc865ec`, and selected generation `poc.34`.
- All eight prohibited main-thread work counters were `0`, and
  `main_thread_violation_count=0`. Manager open/enable/repaint/tab/cache and
  automatic/explicit/watcher status-request counters were all `0`; Manager
  was not entered. No manual Reinstall action or duplicate Supervisor-owner
  signal was observed in the bounded evidence, but the coordinator remained
  unavailable.
- Cold Start therefore failed the required Ready gate specifically because
  the product state remained `NeedsAttention` and
  `coordinator_pid=0`. The focused Node correction passed its synthetic
  re-admission L0, but this visible Cold Start did not provide evidence that
  the selected coordinator recovered in the current project.
- The combined passive process/log command exited `0`; command-runner wall
  time was not captured and is recorded as `unavailable`, not estimated. No
  UI operation, process start/stop/control, Unity MCP, test execution,
  protected-path read, source repair, retry, commit, push, or Verifier dispatch
  occurred.

## Final Scenario Routing

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`

Current status: `COMPLETE / TEST_FAILURE_CLASSIFIED`

Scenario attempts: initial `1/3`; corrected `2/3`; final corrected `3/3`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: review the precise final Cold Start failure
(`NeedsAttention` with `coordinator_pid=0`) and decide task disposition. The
scenario envelope is exhausted; no Manager stage, Play/reload/shutdown stage,
fourth scenario, automatic repair, or Verifier routing is requested by this
Coder result.

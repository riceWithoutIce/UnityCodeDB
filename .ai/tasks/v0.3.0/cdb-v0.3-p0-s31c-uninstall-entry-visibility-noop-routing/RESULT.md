# Result: cdb-v0.3-p0-s31c-uninstall-entry-visibility-noop-routing

## Outcome

- Status: `F1 REPAIR SNAPSHOT READY FOR TARGETED RE-REVIEW / PASS WITH LIMITS — NOT ACCEPTED`.
- Workflow: `codedb-workflow-v2`, revision `2.6`.
- Actual execution route: user-approved task-scoped `FAST_SUBAGENT`, one Coder;
  inherited configured model/reasoning, no override and no recursive agent.
- Base/Head SHA: `279b442c657676d1adbda7d15151a3770682a674` (unchanged).
- Dirty source identity: latest F1 section of [SOURCE-SHA256.md](SOURCE-SHA256.md)
  binds pre/post-repair source and driver/manifest hashes; original snapshot is
  preserved there. Incoming Manager UI
  edits were preserved and completed; HEAD alone is not this snapshot.
- Product source changes are limited to the four TASK allowlisted files.
- No real Install/Uninstall, Unity, Provider, runtime stop, export, reference
  switch, commit, network acquisition or external-process control was performed.

## Implemented Contract

- Ready Overview exposes `Uninstall CodeDB from Project` and its callback.
- NotIntegrated/Uninstalled retain `Install CodeDB`. NeedsAttention retains
  fresh-install recovery priority, then the existing eligible Remove Integration
  route, otherwise Uninstall. Label and enabled predicate agree.
- The incoming unconditional header-menu Uninstall route is preserved.
  Cached preflight/ownership never hides or disables its request entry.
- Presentation disables an in-flight primary action; the actual menu callback
  independently guards busy requests before confirmation. Repeated clicks
  observe the existing session without another confirmation or dispatch.
- Asynchronous uninstall reads the existing canonical integration reader.
  Only canonical NotIntegrated returns local `NoActionNeeded`. Uninstalled,
  including COMPLETE, proceeds to existing backend consistency checks after F1.
  Invalid integration or missing/invalid current-instance
  evidence for Installed return `Blocked`. Pending cleanup remains on the
  existing admission path; no removal authority was introduced. Clicking after
  an explicit completed uninstall is therefore decided by the existing backend,
  rather than a new local absence assertion based solely on its document.
- Local decisions use existing `PreEffectRefusal` evidence, the exact action ID,
  no authoritative writer terminal and no terminal-for-action bit. The existing
  Manager resolver accepts this boundary, releases the exact admitted index,
  and completes the session. It does not wait for an undispatched writer or
  claim that an actual uninstall happened. Local decisions do not request
  post-command reconciliation. This chain is statically inspected; its full
  native completion has not run in this envelope.
- New tests cover labels, busy callback counts, canonical fresh/invalid/missing/
  complete/pending classifications and full local session release. Lifecycle
  test changes only update directly availability-coupled assertions.

## F1-only Repair And Evidence

- Authorization: user accepted FIX F1 only; parent recorded TASK/DECISION.
  F2 remains FOLLOW-UP. No ManagerWindow/Lifecycle/runtime/PowerShell change.
- Fix: removed COMPLETE as sufficient local absence proof. The real
  `ReadUninstallLocalDisposition` reads canonical integration/current status
  and calls the same extracted typed `GetUninstallLocalDisposition` component.
  All Uninstalled states now return no local result, so the existing async
  dispatcher/backend performs admission. No new current read occurs for
  Uninstalled, and no new authority or historical path was introduced.
- Adjacent tests: five existing current-state variants paired with COMPLETE
  all require backend routing; fresh NotIntegrated remains a local successful
  pre-effect no-op, and Invalid remains a local refusal. Existing canonical
  fixture test expects COMPLETE and PENDING to reach the dispatcher.
- Evidence class: pure original action-classification component; test inputs
  are typed status values, not substitute readers or an environment simulation.
- Actual compile: original Editor source and all Editor test source PASS with
  the same 3 existing-site warnings. F1-only test invocation PASS, exit **0**:
  5 COMPLETE current-state cases and 1 adjacent fresh/invalid method.
- Output: `.artifacts/tests/s31c-f1-20261017-a/manifest.json`,
  `editor-compile.log`, `tests-compile.log`, `focused-test.log`.
- F1 attempts: one build and one focused component run; no correction/retry.
- Native canonical reader/session, actual backend, real uninstall and Unity
  remain NOT RUN. The previous 22 passing invocations were not repeated.
- Scoped source `git diff --check`: PASS. Pre/post hashes and unchanged
  protected UI/lifecycle hashes are recorded in SOURCE-SHA256.
- Parent may now admit the latest snapshot for F1-only read-only re-review.
  Component PASS does not close the frozen native/environment or human gates.

## Initial Evidence (preserved; not rerun for F1)

Evidence level: `HARNESS / focused original-source contracts`; not Unity or
production-equivalent acceptance. Reproducible entry: [run-focused.ps1](run-focused.ps1).
Outputs remain under `<repository-root>/.artifacts/tests/s31c-entry-20261017-*`.
Original current C# files and existing Unity managed references were compiled;
no source substitutes, fake Unity APIs, downloaded tools or product replacements
were used. Generated C# is only the small test invocation driver.

| Scenario | Actual result |
| --- | --- |
| Current original Editor sources compile | PASS on final `-c`, 3 warnings at pre-existing async call/unused-field sites |
| All current Editor test sources compile | PASS on final `-c`, including canonical-reader/full-session tests |
| Busy callback confirmation/dispatch/observation counters | PASS |
| Ready/NotIntegrated/Uninstalled/NeedsAttention/fresh-recovery labels | PASS, 5 cases |
| Existing contextual primary-action TestCases | PASS, 11 cases |
| Menu visibility/unknown cached status/preflight independence | PASS, 3 focused methods |
| Adjacent Ready/NeedsAttention Provider presentation | PASS, 2 focused methods |
| Canonical fresh-project reader execution | ENVIRONMENT_INCOMPLETE; first assertion blocked by Unity native initializer |
| Invalid/missing/complete/pending reader scenarios | NOT RUN after first reader boundary |
| Local evidence resolution and durable journal release | NOT RUN after native boundary |
| Full session completion and repeat-session start | Compiled; NOT RUN outside Unity |
| Unity, real lifecycle and human acceptance | NOT RUN / NOT AUTHORIZED |

The `-b` driver passed 22 method/case invocations before the reader boundary.
Its overall exit is **1**, not PASS. The canonical reader invokes
`AICodedbEditorLifecycle.ValidateProjectRoot`; that type's initialization calls
`Application.isBatchMode`, whose native internal call is unavailable in standalone
Mono. The reader safely returned Blocked with the initializer error; the fresh
NoActionNeeded assertion could not be evaluated in this environment. This is an
environment limitation, not evidence of a Unity product defect.

Frozen evidence (`-c` compiles the final snapshot; `-b` preserves execution):

- `.artifacts/tests/s31c-entry-20261017-b/manifest.json`
- `.artifacts/tests/s31c-entry-20261017-b/editor-compile.log`
- `.artifacts/tests/s31c-entry-20261017-b/tests-compile.log`
- `.artifacts/tests/s31c-entry-20261017-b/focused-test.log`
- `.artifacts/tests/s31c-entry-20261017-c/manifest.json`
- `.artifacts/tests/s31c-entry-20261017-c/editor-compile.log`
- `.artifacts/tests/s31c-entry-20261017-c/tests-compile.log`
- Earlier `s31c-entry-20261017-a` is preserved: Editor compile passed; initial
  test-driver compilation referenced methods through the wrong fixture class.
  One mechanical correction selected their real class and froze fresh `-b`
  output. Final static inspection added an explicit task-owned receipt-root
  scope to the still-unexecuted full-session Editor test; final `-c` compilation
  passed. Only that unexecuted method changed between `-b` and `-c`; executed
  product and UI methods are unchanged. No tests or native path were retried.

## Bounds And Disposition

- Mechanical corrections: `1/2`, driver fixture-class selection.
- Corrected semantic attempts: `0/2`; one native-reader attempt, then stopped.
- Independent product causes: `0/2` established by tests.
- Diagnostic-only terminal checkpoints: `0/3`; consolidated source handoff.
- Parent agreed to freeze the native boundary and continue only static review
  and records; no substitution, environment repair or lifecycle source change.
  The affected evidence path remains `ENVIRONMENT_INCOMPLETE`.
- Scoped `git diff --check`: PASS. Unrelated dirty source and earlier artifacts
  remain untouched. New durable output is repository local.
- Deferred: owned-runtime stop, PID handling, deactivation, Provider readiness,
  historical/reconnect paths, real uninstall, Unity and release gates.

## Handoff

- Current task: S31-C uninstall entry visibility/no-op routing.
- Current status: F1 repair stable; full behavior evidence remains incomplete.
- Next owner/action: parent admits the exact hash snapshot and routes targeted
  read-only Verifier re-review of F1 and its adjacent regression only.
- Verifier retains native-reader/session limits and reviews the original scope
  only. This does not authorize another isolation-environment repair task.
- Later source ACCEPT, delivery and human-owned Unity evidence remain separate.
  No gate is implied by compilation or lower-class focused passes.

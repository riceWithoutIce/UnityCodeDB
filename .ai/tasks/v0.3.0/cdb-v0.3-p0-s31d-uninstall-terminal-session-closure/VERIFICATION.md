# Verification: cdb-v0.3-p0-s31d-uninstall-terminal-session-closure

## Outcome

- Verdict: FAIL — one material P1 finding against the frozen post-retirement
  closure promise; findings disposition belongs to User/Planner.
- Workflow: codedb-workflow-v2, revision 2.6; review mode GUARDED.
- Actual execution: task-scoped FAST_SUBAGENT, independent read-only Verifier,
  inherited model/reasoning settings, no override. Exact runtime model/effort
  metadata was not exposed to this role.
- Delegation authorization: TASK_SPECIFIC, as admitted in TASK.md.
- Coder was stopped before admission. No Coder contact, repair dispatch,
  source/test edits or additional agent delegation occurred.

## Frozen Identity And Evidence

The reviewed identity is the dirty working-file snapshot in RESULT.md, not HEAD
alone. Base/Head remains `cc49c95e84945308385f64640963716d93d070ea`.
Independent SHA-256 comparison matched all ten final files in RESULT.md, including
the new validator/meta. The unchanged Lifecycle hash also matches:
`86dc783bd612c35d6c973007e665688785b9465d479186398a268ca3865f71bf`.
All 35 source entries in the final attempt-c manifest match the current bytes.

Reused task-owned evidence under
`.artifacts/tests/s31d-uninstall-terminal/attempt-c/`:

| Record | Independently matched SHA-256 |
| --- | --- |
| manifest.json | 49b62cbc8705b6a7304b83fca259159375520f786fc07097b0e78296bc35998c |
| focused-test.log | 6e3bdda1cf9d160b9e817710588133d89d66a399f8ccc2626c2c7d2e61e3bb3c |
| editor-compile.log | 5d1a633fe6ed36c4238cd3bed094674a58587822dbf02f64bc78b591da14512d |
| tests-compile.log | 7eb70257593da06f682a3ddda54a9d260d4fc514f645237f5ca74b08f8da61a6 |

The task driver hash matches RESULT:
`1c44e14da3ad9dca4d6904e3bbbb245d0d1ff7f95b74f0a93864401fb02cb00e`.
Logs and driver support the reported original-source Editor/test compilation,
three existing warnings, and focused isolated test PASS. Tests rerun: NONE.
Parent admission supplies preservation of the incoming ProcessRunner timeout
hunks and seven original S30 copied records; this review did not mutate them.

## Targeted Checks

- Read TASK.md and RESULT.md fully, the verification template, scoped changed
  bytes, the task driver, final logs/manifest, and direct producer, Bridge,
  Lifecycle, metadata/index, strict JSON, resolver and release references.
- The shared reader checks current admitted Uninstall title/action, project and
  Package identity, canonical runtime, singleton action-map membership, exact
  operation filename/ID, command key and complete normalized child argv/hash.
  Map/operation original owner/request/selection/contract anchors must agree;
  the normal Bridge supplies captured authenticated expected anchors.
- Terminal state/phase, timestamps, exit-code agreement and explicit false
  timeout/overflow/drain flags are required. Only this reader constructs typed
  terminal provenance. Generic Supervisor booleans cannot construct it.
- Manager preserves the bound result after checking direct-writer recovery;
  explicit binding rejection cannot silently fall through to offline recovery.
  Reopen uses the same strict reader without initializing Lifecycle or starting
  Supervisor. Existing competing-route guards and exact journal release remain.
- Inspected the fixture selection and actual driver assertions: production
  compactResult/persistOperation/action-map helpers serialize synthetic original
  inputs, the real C# reader consumes them, and real Manager resolver/journal
  methods release the exact index. Complete failure preserves exit 7. The
  normal resolver is exercised after hiding history; repeated reopen reads,
  negative identity/completeness cases and direct receipt-directory conflict are
  exercised. The direct-writer negative inserts an unexpected record; it does
  not execute a second authenticated writer's complete terminal chain.

## Finding F1 — P1: Handoff Failure Is Replaced By Backend Success

Location: package-relative
`Editor/AICodedbSupervisorBridge.cs:2095`, together with `:420-421`;
direct consumer `Editor/AICodedbManagerWindow.cs:2866-2873` and `:3035`.

For an attributable successful Uninstall with `handoff_queued=true`, the Bridge
first obtains a successful `boundTerminalResult`. If
`CompleteSupervisorHandoff` then returns false because the previous Supervisor
did not retire within its bounded window, the explicit
`SUPERVISOR_HANDOFF_FAILED` response still carries that successful result at
line 2095. `ToCommandResult()` unconditionally returns the carried result before
considering the response's failure/exit 4/error. Lifecycle returns it unchanged;
Manager recognizes the typed complete terminal and can release the exact index.
The handoff failure is consequently lost to the command/session consumer.

This is a concrete changed control-flow branch, not a demonstrated live incident
or a speculative process race. It contradicts TASK Objective and the original
alignment's promise to close the current session after Supervisor retirement.
Backend completion remains a valid separate fact; it does not establish the
explicitly failed retirement. No claim of process termination or actual config
damage is made.

The focused harness obtains its normal result directly from the offline reader
and passes it to Manager; it does not exercise this Bridge response-conversion
branch. Its PASS therefore does not discharge F1. Expected acceptance behavior:
the explicit handoff failure remains visible and cannot be converted into a
fully accepted post-retirement success merely by carrying the backend terminal.
Any bounded repair review should cover F1 and its adjacent successful-handoff,
confirmed-backend-failure and no-second-lookup behavior only.

## Limits And Disposition

The isolated producer/reader/resolver/release claims match the actual checks,
subject to F1. CONTRACT_ISOLATED/HARNESS is the supported evidence level.
Operation admission, live authenticated IPC/handoff, actual child capture,
backend effects, real runtime/config writes, Unity/MCP/BatchMode, delivery and
actual reinstall acceptance were NOT RUN. No unchanged Coder test or full suite
was rerun; no process was controlled.

Older S30 evidence lacks the new map bindings and explicit completeness flags.
It intentionally remains unconfirmed; no historical compatibility finding,
backfill, original-index release or replay is requested. Source acceptance does
not imply delivery authority. No additional findings or theoretical hardening
items are raised. No review-mode promotion is required.

## Handoff

- Current task: S31-D uninstall terminal/session closure.
- Current status: VERIFIER COMPLETE / FAIL / STOPPED; one P1 finding, F1.
- Next notification: current parent Planner/User, consolidated once.
- Next action: User decides ACCEPT / FIX / DEFER / STOP for F1; Planner routes
  that decision within the declared workflow.
- Human decision required: findings disposition. Delivery and real operations
  retain their separate authorization gates.

Verification is read-only and claim-bounded. Only this VERIFICATION.md was
created. No repair was assigned to Coder. Review stops at this terminal report.

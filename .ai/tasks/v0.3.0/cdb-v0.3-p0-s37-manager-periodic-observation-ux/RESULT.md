# S37 read-only diagnosis — 2026-10-19

## F1 fixture repair — 2026-10-19

After user alignment and approval, the parent repaired only the existing
`--s32-disposition-fixture` branch of
`com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`:

- renamed the process-evidence stub to `getProcessEvidence` and made the
  evidence/executable stubs asynchronous;
- awaited existing admission and evidence-capture calls;
- replaced synchronous exception assertions with awaited `assert.rejects`.

No production source, scenario inventory, expected outcomes, fixture path
policy or package identity configuration changed in this repair. The fixture's
existing scenarios cover live/unknown prior identity and proven process exit;
this run does not add or claim a new PID-reuse scenario.

Validation: the existing producer-only fixture passed once with
`node --unhandled-rejections=strict`, exit 0. Evidence is under
`.artifacts/tests/s32-install/s37-f1-efc7f69ee88a46eba6148f9acf0e8938/`,
with generated case records in `run/` and the existing sibling
`admission-project/` entirely beneath that new owned directory. No Supervisor,
Provider, Unity, runtime child or server was started by this fixture.
Test-file syntax and scoped whitespace checks also passed. The previously
blocked full Supervisor harness was not retried.

Frozen working-tree repair snapshot against HEAD
`554070ee2e1c0df4cc6aa919dc2ad77b18b07fde`:

- production SHA-256 (unchanged):
  `63537CF98AD82C37077FC4C312C7521DBBBAA61CCBC02C69A477AF45D8FED1F1`;
- test SHA-256:
  `230754F6F4C7C16EC90B08869F66AD631698F93AAB4F17AF052F4C1200C22208`.

The already authorized read-only Verifier completed the focused re-review:
F1 CLOSED, no remaining finding, overall PASS_WITH_LIMITS. Production and test
hashes and all seven existing fixture records were checked; no test rerun was
required. See VERIFICATION.md. The narrow source snapshot is ready for the
user's acceptance decision. No commit, export, reference switch or real
lifecycle operation is included; broader S37 separation and live latency/Unity
acceptance remain unproven.

## Approved narrow repair — 2026-10-19

The approved repair was applied only to `Tools~/codedb-project-supervisor.mjs`:

- authenticated `status` requests now return the in-memory Supervisor snapshot
  directly; the Coordinator refresh remains a best-effort background query;
- Windows process identity and executable lookup use asynchronous child-process
  APIs, so PowerShell/Get-CimInstance cannot synchronously block the Supervisor
  IPC event loop;
- existing process identity fields, ownership checks, PID/start-identity checks,
  fail-closed branches, query/maintenance queues, and timeout constants were
  preserved.

Validation:

- `node --check com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` PASS;
- `git diff --check -- com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` PASS;
- focused Supervisor harness was attempted but stopped before exercising this
  change because the current dirty package snapshot fails its existing fixture
  identity precondition: `Selected stable wrapper does not match the
  Package-declared runtime identity.` No retry or package mutation was made.

Current source SHA-256:

`Tools~/codedb-project-supervisor.mjs`
`63537CF98AD82C37077FC4C312C7521DBBBAA61CCBC02C69A477AF45D8FED1F1`

No Unity, Install/Uninstall, package export, reference switch or commit was
performed. Read-only review of this exact working-tree snapshot is still
required before delivery decisions.

## Outcome and evidence boundary

Source inspection confirms incomplete isolation of lightweight observation from
heavy work. It does not establish which callback caused the reported real-Editor
timeout, or the exact elapsed time to recovery. No live trace, reproduction,
test, Unity launch, lifecycle operation, source repair, package export, reference
switch or commit was performed in this pass. No child agent was dispatched.

Inspected snapshot: `.artifacts/s36-preflight-refresh-46fdba6/review/com.rice.ai-codedb`,
the S36 delivery identified by source commit
`46fdba68cec69e9b07a957d10a5b5e9b9f9ddb84`. Inspection used extracted source;
this pass did not re-export or independently rehash the complete delivery.
All paths below are relative to that package root.

## Confirmed findings

1. **Query priority is implemented, but status has head-of-line waiting.**
   `Tools~/codedb-project-supervisor.mjs:1118-1186` maintains a bounded query
   queue, shares an identical key's promise until completion, and runs one query
   callback at a time. Active asynchronous maintenance does not itself prevent
   draining queries. However, `status`, `operation`, forwarded `query`, watcher
   Status and internal Coordinator `refresh` use that same serial lane
   (`:1505-1572`). A status response copies memory only after admission to this
   lane; it then queues another refresh. The Supervisor timer queues refresh
   every 1000 ms (`:35`, `:1662-1665`). A refresh awaits Coordinator status with
   a 1500 ms timeout (`:1243-1268`, `:2535-2542`), equal to the Bridge exchange
   deadline (`Editor/AICodedbSupervisorBridge.cs:2509-2538`). Therefore a delayed
   Coordinator refresh can consume the outer status/operation response budget.
   Coalescing prevents duplicate execution; it does not eliminate this wait.

2. **Heavy work can synchronously block the Supervisor event loop.**
   Delaying identity capture until after admission does not move it off that
   event loop. `queueChildEvidenceCapture` runs a timer callback which calls
   `recordChildEvidence` and `getProcessEvidenceSync`
   (`Tools~/codedb-project-supervisor.mjs:2411-2505`). On Windows this executes
   PowerShell/Get-CimInstance via `execFileSync`, with a 5000 ms limit
   (`:50`, `:2608-2630`). While this synchronous call runs, Node cannot service
   another pipe callback or queue drain. Prior-child identity checks can use
   the same synchronous path. This is a concrete implementation conflict with
   the intended responsive observation boundary, not proof that any particular
   inspection lasted five seconds in the reported incident. Ownership/PID
   authentication must be preserved if execution is later moved off-loop.

3. **The photographed error identifies a command path, not uniquely a heartbeat.**
   `SUPERVISOR_IPC_TIMEOUT` is produced by `SendCommandWorker`'s timeout catch
   (`Editor/AICodedbSupervisorBridge.cs:2148-2164`). A timeout during accepted
   operation polling also exits through this catch (`:2296-2338`); the error
   alone does not distinguish admission from polling or reveal the command.
   Plain reconnect status uses different error reduction (`:1450-1513`).
   A later successful reconnect can refresh the Supervisor cache without
   replacing a failed product command. Product recovery may await another
   lifecycle reconciliation and Probe, so reconnect success does not alone
   mean Manager must immediately return Ready.

4. **The current periodic path still mixes observation and heavier policy.**
   `Editor/AICodedbEditorLifecycle.cs:420-470` ticks every 5 seconds; scheduled
   reconciliation is eligible every 30 seconds (`:31`, `:489-504`), guarded by
   `_reconcileInFlight`. Its completion requests reconnect (`:715-728`).
   Even the healthy fast path can run removal preflight after a 120-second
   cache expiry (`:1279-1292`, `:1599-1675`). That path invokes the package
   materializer through PowerShell (`Editor/AICodedbHostPayloadMaterializer.cs:171-182`).
   Other reconciliation branches may run Probe/Ensure or pending retirement.
   These mechanisms can explain why a visible check occurs minutes later;
   they do not prove the precise 3-5 minute trigger or recovery duration.

5. **Coordinator status itself does not await Provider tools.**
   `Payload~/Generations/poc.43/coordinator/codedb-watch-coordinator.mjs:1518-1524`
   returns its memory snapshot for status; Provider queries have a separate
   promise tail/map (`:735-808`). There is no direct Provider tools/list or
   tools/call dependency in the status handler. It still depends on the
   Coordinator event loop being able to service the connection.

6. **Cleanup Pending is not evidence of active cleanup execution.**
   `Editor/AICodedbStatusSnapshot.cs:955-967` renders persisted cleanup Pending
   as `Background cleanup / In progress`, including while retired leases wait.
   The screenshot therefore cannot establish that cleanup blocked IPC or that
   a heartbeat failure initiated cleanup.

Existing query-priority fixture coverage uses a responsive fake Coordinator
and checks a query during asynchronous maintenance
(`Tests~/test-codedb-project-supervisor.mjs:1393-1474`). Source inspection of
that scenario does not establish real Windows status latency under delayed
Coordinator responses or synchronous process inspection. It was not rerun.

## Recommended next alignment

Treat S37 as one bounded separation of runtime observation from lifecycle work,
not repeated timeout increases or historical compatibility repairs:

- Serve authenticated project/instance/owner-bound status from memory without
  waiting behind Coordinator refresh or other forwarded queries.
- Keep potentially slow process identity collection off the IPC event loop;
  preserve the existing authentication and fail-closed mutation rules.
- Separate periodic runtime observation from full Probe, removal preflight,
  cleanup and index refresh. Keep project-local single-flight/cancellation and
  lease ownership explicit; Manager remains a cache consumer.
- Model transport uncertainty separately from installation damage. Do not pin
  stale Ready indefinitely or grant mutation from cached/unknown evidence.
- Freeze focused evidence for delayed Coordinator response, slow identity
  collection, same-key sharing, project isolation and recovery publication
  before implementation. Keep real Editor latency acceptance separate.

This is a recommendation, not a frozen source-change envelope. Exact allowed
files, status policy and evidence plan still require alignment. No changes to
1500 ms, 30-second or 120-second constants are proposed as a diagnosis shortcut.
CleanupMono, log reduction, historical recovery and Provider/model work remain
out of scope. Original incident attribution remains unconfirmed.

## Handoff

- Current task: S37 manager periodic observation.
- Current status: ALIGNMENT_PENDING; authorized read-only pass complete.
- Next notification: User.
- Next action: align one bounded observation-separation repair and its evidence.
- Human authorization required: production implementation and any delegation;
  no delivery or Unity/lifecycle action is included.

## Exact delivery — 2026-10-19

The approved narrow snapshot was committed without staging unrelated dirty
state:

- Commit: `f5abf2a2e0042f4ee90f1c9bbd7671fd36f1de11`
- Message: `fix: decouple supervisor status observation`
- Allowlist: the Supervisor production source, its focused fixture test, and
  the three S37 task records.

The existing commit-derived exporter was run once against that commit into
`.artifacts/s37-manager-periodic-observation-f5abf2a/`:

- commit-stage production admission: PASS;
- exact ZIP production admission: PASS;
- byte closure: PASS, 60 declared payload sources, zero mismatches;
- native binding checks: PASS;
- extracted Package files / ZIP entries: 623 / 623;
- ZIP SHA-256:
  `9f719b4a560935798620eeae7814ad51b94645ffa1402c6ddaffe94ad6814197`.

No Unity, lifecycle command, process termination, Install/Uninstall or push
was performed during this delivery step. This documentation-only record is
kept separate from the code-bearing commit.

## S35 reference switch — 2026-10-19

The active S35 acceptance project was confirmed closed before mutation: no
Unity process matched its project root and neither `Temp/UnityLockfile` nor
`Library/EditorInstance.json` existed.

The original package consumers were backed up under
`.backups/s37-manager-periodic-observation-0ef48d6/`:

- `manifest.json` before SHA-256:
  `40948247A542C76D7D9BDF66A74ACC482EFCCA79329BA4DFDDE692FD0EA5740D`;
- `packages-lock.json` before SHA-256:
  `06F7BAC62C84EAAA928E048003E4D846D696F866A791FA6836691B5EF606D7C2`.

Only the CodeDB local reference changed in each file. Both parsed consumers
now resolve to:

`<repository-root>/.artifacts/s37-manager-periodic-observation-b7b1bd6/review/com.rice.ai-codedb`

The new reference exists, both manifest and lock values match, testables remain
unchanged, and byte comparison after replacing the single old reference with
the new one is exact. No Unity launch, Test Runner, Install/Uninstall,
process termination or runtime-state rewrite was performed.

The next step is human acceptance on S35: open the project, confirm compile and
focused tests, then Manager reopen/tab behavior and the bounded idle observation.

## Human acceptance closure update — 2026-10-19

The user reports that acceptance passed: the periodic `NeedsAttention` state
did not recur, Manager close/reopen and tab switching were normal, and Unity
close/reopen was normal. This closes the current human acceptance evidence for
the narrow Supervisor observation repair as `PASS_WITH_FOLLOWUP`.

The user also observed that Manager can remain visibly `Starting` for a long
time when first opened. The screen explicitly allows continued Unity use, and
no command failure or persistent readiness error was reported. This is recorded
as a non-blocking startup UX follow-up. It is deferred until after the current
task acceptance and does not authorize a threshold change, source repair,
package export, reference switch, or another lifecycle operation.

## Human acceptance observation — 2026-10-19

The user reported that the first S35 opening had no compile error, but Manager
initially showed `Needs attention` with
`SUPERVISOR:SUPERVISOR_IPC_TIMEOUT`; Host payload, Current instance and related
rows were `Not evaluated`. The state later recovered to `Ready` without an
Install/Uninstall action.

Read-only runtime evidence at `2026-10-19T18:27:17+08:00` showed the same S35
Supervisor process and Coordinator alive, Supervisor `readiness_state=core_ready`,
`reason_code=COORDINATOR_OPERATIONAL`, revision `295`, and Coordinator
`provider_state=ready`. The latest completed Probe had exit code `0`; the first
Probe after startup failed once before two later Probe attempts completed.

This is recorded as `HUMAN_ACCEPTANCE_PARTIAL / RECOVERED_READY`: the recovery
path is usable, but the initial timeout remains an observed runtime failure and
the result does not claim that the intermittent timeout is eliminated. Manager
reopen/tab, bounded idle recurrence and normal Unity close remain separate
human evidence items.

## Follow-up source repair prepared — 2026-10-19

The user authorized a narrow repair after the S35 same-version Install
preflight blocker. The Supervisor exception terminal path now emits the
complete output-observation fields while preserving fail-closed unknown-child
admission. A focused fixture covers the real exception branch; syntax, focused
execution and whitespace checks pass.

This is a working-tree source snapshot only. It does not rewrite the existing
S35 failed record, export a package, switch the project reference or authorize
another Install attempt.

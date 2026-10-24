# Proposed startup diagnosis and repair gates — 2026-10-21

Status: ALIGNMENT_PROPOSAL / NO_LIVE_CAPTURE_AUTHORIZATION.
Stage 1 was subsequently explicitly approved and completed. See
HOST-DIAGNOSTIC-CAPABILITY-RESULT.md: existing native evidence remains incomplete;
no live route, logging override or external tool was admitted/executed.
Origin: user requests alignment on locating the failure and handling it.
Baseline: CLIENT-STARTUP-STATIC-ANALYSIS.md and exact-thread Attempt 03 records.

## Objective and evidence classes

Locate why the actual CodedbTest_1 Codex connection closes before initialize
and before an attributable bootstrap diagnostic. Do not use query retries as
a diagnostic loop. Do not fold the deferred Ready/Unconfirmed task into this.

Wanted facts, correlated to one target startup event:

| Fact | Purpose | Evidence caveat |
| --- | --- | --- |
| Parent/child PID, creation time and resolved executable | Identify whether/what was launched | Host starting is not child-creation proof |
| Effective cwd and entry arguments | Test actual relative entry resolution | Chat cwd and config text are not child observations |
| Bounded child stderr | Obtain loader/validation error instead of generic handshake error | Existing host summary lacks this field |
| Actual child exit/signal and timing | Distinguish natural failure from observation/host termination | Requested wrapper code is not observed process exit |
| Relevant entry/import open failure if stderr unavailable | Narrow a loader/path failure | File attempts alone do not prove complete error semantics |
| Target thread/server and pre-existing bootstrap baseline | Attribute observations | New file/time proximity alone is insufficient |

## Stage 1: select an evidence-capable route without live startup

Do a bounded read-only inspection of the installed host's supported diagnostic
surface and existing logging settings/records. Determine whether stderr from
stdio MCP children is already retained and where, or whether a documented,
bounded host-native collection can capture it on the unchanged launch path.
Inspect relevant settings only; no raw user/global configuration dump, guessed
RUST_LOG switch, host source modification or undocumented flag experiment.
Existing exact-thread/window log search already done is not repeated unchanged.

If an additional passive tool is needed, first establish actual available
fields, required permissions and output filtering, without installation or
recording. A candidate must provide child launch/path evidence or relevant
entry-file failures. Procmon is only an unselected example until availability
and field coverage are established; it was not found in the earlier bounded
inventory. No download/tool integration is authorized by this proposal.

Exit this stage with a concrete route/field/permission table. Stop route
discovery if the needed data is unavailable and report that gap; do not cycle
through new tools or spend a live startup on a recorder known not to answer it.
The existing process-only ETW inventory lacks cwd/stderr and is insufficient
as the sole route for that evidence. Do not promise those missing fields.

## Stage 2: separately authorized one-window actual-host observation

Only after a concrete recorder/reader and its scope are reviewable:

1. Freeze relevant project config, pointer, wrapper/helper, manifest reference
   and diagnostic/lease baseline. Confirm expected identities without writing
   project runtime/config. Use uniquely owned repository-local evidence paths.
2. Keep original registration name, command, cwd, arguments, stdio and inherited
   environment unchanged for the preferred native/passive route. Keep Unity
   in its current state; do not elevate/restart it or Codex to obtain a trace.
3. The human initiates one fresh target-root diagnostic chat. Its instruction
   permits normal host initialize/discovery side effects but no status/search
   tools, manual wrapper/probe/Provider commands or query substitution.
4. Observe at most one agreed window, maximum 60 seconds, ending on the first
   attributable failure or successful startup. Preserve naturally occurring
   host restart events distinctly; do not manually trigger another connection,
   create another chat or claim a single child spawn if the host made more.
5. Stop only the uniquely owned recorder, never another recording/session or
   the target/external process. Capture at most 32 KiB/200 lines of displayed
   stderr/evidence and mark truncation. No tokens, full env/argv dumps or
   unrelated process/file/network/registry history. Limit launch fields to the
   reviewed target command/path evidence. Keep partial results on timeout.
6. Verify protected project inputs; no automatic retry or repair. Return
   cause evidence and limitations. A diagnostic connection succeeding is not
   an actual status/search acceptance result.

Where a recorder cannot enforce collection filtering before capture, disclose
the unavoidable raw scope before authorization; post-filtering is not a promise
of target-only collection. Evidence retention and recorder lifecycle must be
reviewable before this gate, not invented during capture.

If the native/passive route cannot supply the decisive information, stop and
align an explicit alternative. A temporary intermediary capture changes the
registration/launch topology and timing. The historical shim is not selected,
not automatically refreshed/reused, and cannot establish untouched-path
acceptance. Any such alternative requires its own tested plan and byte-exact
restore boundary; do not treat it as a no-impact logging switch.

## Stage 3: cause-specific bounded repair proposal

| Observed cause | Proposed handling, subject to agreement |
| --- | --- |
| Entry path/cwd resolution is wrong | Repair the responsible registration/path contract and its generator; use a portable design, not a machine-specific permanent absolute path |
| Wrong Node executable/version/options | Repair prerequisite/discovery/guidance at the responsible boundary; distinguish stale parent environment from Package behavior; no silent global PATH change |
| Entry/import/package file loading fails | Fix Package dependency/materialization closure or the evidenced loader compatibility issue; preserve immutable-version authority and normal delivery gates |
| Worker Provider/environment failure | Fix the evidenced prerequisite/context path; keep Provider identity/hash checks, no alternate Provider or validator bypass |
| Diagnostic write fails | Handle the narrow observability failure as needed, while locating the primary startup failure separately |
| Host closes/kills an otherwise initialized connection | Analyze target transport/host lifecycle evidence before changing Package startup; do not infer this solely from EOF |
| Evidence remains inconclusive | Stop with explicit missing facts; no speculative fix/reinstall/query loop |

Freeze the smallest responsible change and focused tests before coding. Existing
dirty state, old-project evidence, project registration ownership and immutable
activation contracts remain protected. If a source fix requires delivery or
identity change, align those gates explicitly instead of modifying installed
bootstrap bytes directly. No migration/product-scope expansion by implication.

## Stage 4: separate verification and acceptance

First verify the corrected cause and its adjacent regression with focused
isolated checks. Then obtain explicit exact-delivery authority if needed.
Finally perform a fresh human-approved actual-client status/search attempt on
the normal production startup path. Report source/diagnostic/startup/query/
response-identity evidence separately. No new Unity project is currently
needed merely to observe this startup failure; keep CodedbTest_1 as the target
and decide identity handling only if the evidenced repair requires it.

## Authorization at this alignment boundary

Current work records the plan only. Proposed immediate next step is Stage 1,
read-only capability selection without starting real MCP or a recorder. Live
capture, new diagnostic chat, temporary config, elevation, software install,
repair, commit and delivery are not granted by discussing this document.
Do not auto-create a task/chat, dispatch an agent or schedule a reminder.

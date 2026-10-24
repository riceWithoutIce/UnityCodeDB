# S39 preparation result

Date: 2026-10-20.
Current status: `FRESH_PROJECT_FUNCTIONAL_PASS / COMPLETE_SESSION_IDENTITY_DEFERRED`.
Latest accepted CodedbTest_2 first-install/client/status/C# query evidence:
`../cdb-v0.3-p0-s39-mcp-cwd-registration-fix/ACCEPTANCE-CLOSURE.md`.
The historical results below are preserved; their old "current" status and
next-action statements are superseded by that bounded closure. No old attempt
or trace is resumed, and complete response/session identity is not claimed.
The initial nested-project preparation below is historical and superseded by
the external-route update at the end of this record.

## Prepared changes

- Frozen task envelope in TASK.md.
- Added project `Assets/CodeDBAcceptance/S39QueryProbe.cs`, a seven-line static
  C# class with no Unity callback, scene attachment or external dependency.
- Prepared the human import checkpoint and exact new-chat instruction in
  CLIENT-HANDOFF.md. No new chat was created or messaged by the parent.

## Static evidence

- The literal marker occurs once in project Assets C# source, on line 5:
  `        public const string Marker = "CODEDB_S39_CURRENT_LIFECYCLE_20261020";`
- Sample SHA-256:
  `8724e76c9d937318d2cd24cc897cb74ef7ad16744af98b43e8efd3d932d1cf47`.
- Manifest and lock both reference
  `file:../../../s37-supervisor-terminal-result-d856a8f/review/com.rice.ai-codedb`;
  the reference resolves to the existing Package.
- Project MCP configuration still registers `codedb-current-lifecycle` with
  the project wrapper and a 120-second startup timeout.
- Selected instance and activation epoch match the task's S38 binding.
  The actual `instance.json` SHA-256 matches the pointer:
  `b448c2c6a2df05a48fc2e58af249a05a491e3116fd1eaf816999643f5f47f453`.
- Sample line/content and uniqueness assertions passed. Scoped whitespace
  checks passed for the initial task, handoff and sample.

These checks prove preparation and on-disk bindings only. Unity import/C#
compilation, client tool injection, live status identity and query execution
have not been observed in S39. No direct wrapper probe or runtime RPC ran.
Unity-generated metadata is owned by the human import step.

## Handoff

Configuration clarification after user review: the nested project path is not
an isolated Codex configuration environment. A targeted ancestor-file check
found only the Unity project's `.codex/config.toml` in the inspected chain;
there was no repository-root or intermediate project config. This does not
exclude user-level configuration or establish the effective config in a new
client. CLIENT-HANDOFF.md now explicitly requires target-server binding checks
and forbids treating a new chat as proof of configuration isolation. No project
move, runtime reset or configuration edit was performed.

- Current task: S39 real project Codex query acceptance.
- Current status: PARTIAL / HUMAN_IMPORT_AND_NEW_CHAT_PENDING.
- Next notification: User.
- Next action: in the exact current-lifecycle Unity project, allow import and
  compilation; confirm no new errors and Manager Ready. Then create a new
  Codex chat at that project root and paste CLIENT-HANDOFF.md's instruction.
- Human action required: import checkpoint and target-root chat provisioning.
  The agreed single status/query sequence needs no repeated authorization.

Keep S38 lifecycle PASS and the periodic-status FOLLOW-UP separate. This result
does not close standalone external-project discovery, performance or release.

## External-route update — user-selected CodedbTest_0

The user chose standalone acceptance outside the repository and created
`<external-acceptance-root>/CodedbTest_0`. Its exact local binding is in the
user message. TASK.md and CLIENT-HANDOFF.md now target this project; the earlier
current-lifecycle sample/result remains historical. No S38 state was copied.

Read-only baseline:

- Unity 2022.3.62f3 (96770f904ca7), no CodeDB manifest dependency, no AIWork,
  no project Codex configuration, and no Assets C# source.
- No `.git`, `AGENTS.md` or `.codex/config.toml` was found on the inspected
  project-to-drive-root ancestor chain. User/global config is not excluded.
- Editor PID 37824 and import workers 54196/44644 were running at inspection;
  `Temp/UnityLockfile` existed. No process was stopped.
- Original manifest SHA-256:
  `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1`.
- Original lock SHA-256:
  `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6`.

External delivery preparation completed:

- Copied the existing exact S37 ZIP to
  `<external-acceptance-root>/Packages/d856a8f/com.rice.ai-codedb.zip` and
  extracted it there; no new source build/export occurred.
- Original and copied ZIP SHA-256 both match
  `97aecd28ff47656a9b6cd66666f6c9030b95a8f4b5a98cf8cf68f588058031a9`.
- All 623 extracted files match their ZIP entry SHA-256. Entries were checked
  to remain under the new delivery directory before extraction. Existing
  destination overwrite was forbidden.
- Extracted metadata is `com.rice.ai-codedb`, `0.3.0-preview.5`.
- Proposed `file:../../Packages/d856a8f/com.rice.ai-codedb` resolves from this
  project's Packages directory to the independent extraction.
- Project configuration and Assets have not been changed. Backup and sample
  preparation wait for the closed-Editor checkpoint. No runtime probe ran.

Current task: S39 independent Package consumer and Codex query acceptance.
Current status: EXTERNAL_PROJECT_CONFIGURED / HUMAN_IMPORT_PENDING.
Next notification: User.
Next action: open CodedbTest_0, wait for Package import and C# compilation,
then report the Console and Manager baseline before Install.
Human action required: import/compile checkpoint. First Install and real-client
query remain subsequent human/client gates; none is claimed passed here.

## External project configuration result — 2026-10-20

The human reported that CodedbTest_0 was closed. A read-only checkpoint found
zero Unity processes for that project and no Unity lock file. The original
manifest and lock hashes matched the external baseline. The parent then made
the authorized consumer configuration change:

- Backups were written under `<external-acceptance-root>/.backups/` with the
  original manifest hash
  `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1` and
  lock hash
  `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6`.
- Manifest and lock now reference the independently extracted Package through
  `file:../../Packages/d856a8f/com.rice.ai-codedb`; the lock entry is local,
  depth 0, and has no child dependencies. The Package resolves and reports
  `0.3.0-preview.5`.
- The manifest testable list now contains `com.rice.ai-codedb`.
- Added the inert sample `Assets/CodeDBAcceptance/S39QueryProbe.cs`. Its marker
  occurs once and its SHA-256 is
  `76442fb3d5d7c950f8836f152bfd273c9b9a00c06d1d287eba036dc6e5d23842`.
- Configured manifest SHA-256:
  `6ff38dacfb02aaebc7122ac24e1ec0677b1e66f4f06fdaef923fc62a077a8f51`.
- Configured lock SHA-256:
  `e39be4e16dd7c41024445132a6b32725ed328c30e63503c94fb856ead82b7200`.

Static reference, lock/source/depth, testable, package-resolution, sample
uniqueness and backup checks passed. Unity import, compilation, Manager state,
first Install, generated registration, runtime identity and real-client query
remain unobserved. No Unity process was launched or stopped by the parent.

## Human import baseline — 2026-10-20

The user reports that CodedbTest_0 opened with no errors. The attached Manager
screen shows the expected fresh-project surface: Package `0.3.0-preview.5`,
`Not installed`, `Install CodeDB` available and no recent command. It also shows
the generic uninstalled-state wording that setup could not finish. Because no
Install action has occurred in this project, this wording is retained as a
baseline diagnostic and is not classified as an Install failure.

The parent read-only checkpoint found one Unity process for CodedbTest_0,
`Temp/UnityLockfile`, no `AIWork/` and no project `.codex/`. Manifest/lock
hashes remain unchanged from the configured S39 values and the sample exists.
See `INITIAL-HUMAN-RESULT.md` for the attributable human evidence.

Current status: `IMPORT_BASELINE_PASS / FIRST_INSTALL_PENDING`.
Next action: human performs the one agreed first Install; parent then checks
the original terminal, selected instance and independent Ready observation.

## First Install and Ready closure — 2026-10-20

The human reports Ready and supplies the installed Manager screenshot. The
parent correlated the successful original Install terminal (exit 0, no timeout
or output loss), selected READY instance, committed activation and generated
project-local registration. Details and original receipt hashes are retained
in `FIRST-INSTALL-HUMAN-RESULT.md`. The screenshot is a cached UI Ready
observation; no new parent readiness probe was performed. Original cleanup
status remains `PENDING` and is not a cleanup-complete claim.

- Actual server: `codedb-codedbtest-0`.
- Selected instance: `2414c73c2fbb47f4b664c1bdbcad5969`, generation `poc.43`.
- Activation epoch: `4ad2120d1559487f8e54c015685496f6`.
- Sample hash, unique occurrence at line 5, Package references and manifest/lock
  hashes remain consistent with the configured external-project baseline.
- Replacement parent chat: `01a158ae-66a6-78d3-8200-f1061a98f503`, replacing
  `01a1574f-99dd-7463-a495-3ce0d736e0d6` after predecessor service failures.

Current status: `PARTIAL / FIRST_INSTALL_READY_PASS / REAL_CLIENT_QUERY_PENDING`.
Next action: human creates the target-root client chat and uses the finalized
CLIENT-HANDOFF.md instruction. No repeat Install is required. Real client tool
injection/status/query, performance and release acceptance are not claimed.

## Client attempt 01 — stopped before tool invocation

The human returned the completed result from `验收 S39 MCP 查询`, chat
`01a158b6-693a-7901-9da3-fda6d8a55490`. Its cwd and on-disk configuration,
pointer, manifest hash and expected identities match. Target project tools were
not exposed. Both target status and query call counts are zero; there is no
query response or attributable new client lease. No substitute services were
called. This is not an empty-query result.

Parent read-only inspection of that chat's desktop startup log then found
`codedb-codedbtest-0` starting at `2026-10-20T09:48:32.126Z` and failing at
`09:48:32.371Z` with `handshaking with MCP server failed: connection closed:
initialize response`. The target registration therefore reached the client's
startup path. The failure is before successful initialize/tool exposure, not
an established post-tools-list injection failure. The deeper process/stdio
cause is unproven. The user config currently marks this exact project trusted;
that current observation does not reconstruct every effective startup layer.

See CLIENT-ATTEMPT-01-RESULT.md for attribution, exact log message, limitations
and route handoff. First Install/Ready remains PASS. Real-client acceptance is
BLOCKED; the approved single client attempt has ended. No parent runtime probe,
retry, configuration/source change, process termination or new chat was made.

Current status: `PARTIAL / FIRST_INSTALL_READY_PASS / REAL_CLIENT_QUERY_BLOCKED`.
Next action: User/Planner alignment on a bounded startup/initialize diagnosis
envelope. A new external validation attempt is a separate gate.

## Authorized diagnosis 01 — source cause identified

The user approved read-only diagnosis. STARTUP-DIAGNOSIS-01.md records the
confirmed defect: the installed stable wrapper statically imports a sibling
shared module that is present in the delivered payload but absent in the
project. The instance activation publisher writes the stable wrapper without
that dependency; candidate MCP verification directly probes the generation
worker and bypasses the registered stable entry. Wrapper hash-only validation
does not catch the missing module.

Evidence is source/filesystem/retained-log evidence, not a fresh runtime
reproduction. Current source and frozen delivery match for the wrapper and
instance engine. No implementation, consumer runtime change or client retry
occurred. Continue using CodedbTest_0 for diagnosis and eventual client
regression; a separate clean-install gate depends on the agreed repair.

Current status: `REAL_CLIENT_QUERY_BLOCKED / SOURCE_CAUSE_IDENTIFIED / REPAIR_SCOPE_PENDING`.
Next action: align the stable-entry dependency design and narrow repair
envelope before implementation/delivery or another client attempt.

## Authorized stable-entry source repair — completed

The user approved the frozen repair scope. STABLE-ENTRY-REPAIR-RESULT.md records
SOURCE_FOCUSED_PASS: transactional dependency publication/rollback, operational
closure validation, lifecycle preservation/removal, and a real stable-entry
post-commit probe that preserves COMMITTED effects on failure. Focused evidence:
25 PS checks, 3 Supervisor cases, 2 Node entry cases, 1 production PS probe case,
and 6 standalone C# contract cases. This is not Unity compilation or real
Provider/Codex acceptance.

Current development payload hash inconsistency was preserved; successful
fixtures use the existing frozen immutable delivery as read-only input. Exact
Package delivery closure and existing-consumer bootstrap recovery need an
explicit next route. No consumer, frozen delivery, version or generation was
changed; no export, commit, push, Unity run or real-client retry occurred.

Current status: `PARTIAL / SOURCE_FOCUSED_PASS / REAL_CLIENT_QUERY_BLOCKED`.
The existing CodedbTest_0 is sufficient for the later regression; a new Unity
project is not required by this result. CLIENT-HANDOFF.md remains historical.

## Delivery preparation — candidate verified

DELIVERY-RECOVERY-PLAN.md freezes the exact candidate and proposed delivery/
single-module historical recovery. The candidate uses HEAD's coherent poc.43
payload and only this repair's delta, preserving all unrelated dirty work.
Its release closure (60/60 sources), production admission, path provenance,
and own focused harness PASS; focused run r-5110a391. No version/generation
regeneration is required by this Package-side change. Test-root resolution was
adjusted to keep extracted-candidate fixtures inside the enclosing repository.

Current status: `SOURCE_AND_CANDIDATE_FOCUSED_PASS / DELIVERY_AUTHORIZATION_PENDING /
REAL_CLIENT_QUERY_BLOCKED`. No commit, export, external reference switch,
bootstrap restoration, Unity execution, MCP attempt or process stop occurred.

## Authorized exact delivery and historical recovery completed

The user approved the concrete sequence and confirmed Unity closed. Commit
c07bb5903b5b3fcda7d97f5238c2915e3c566cf8 was created without push. Final ZIP
production admission/60-source byte closure, path provenance and the exact
extracted artifact's focused run r-32cd4765 PASS. The new external 630-file
Package inventory matches the ZIP; the old delivery inventory is unchanged.
CodedbTest_0 manifest/lock now reference c07bb59, and the one authenticated
missing bootstrap module was restored. Original selection, instance, epoch,
generation, wrapper and MCP registration hashes are unchanged. Original
reference files and receipts are protected under .backups/s39-delivery-c07bb59/.

See DELIVERY-RECOVERY-RESULT.md and DELIVERY-RECOVERY-RECEIPT.json. This is
historical recovery, not real clean-install acceptance. No Unity, real Provider,
real Codex query, Install/Reinstall/Uninstall, process stop or push was run.
Current status: DELIVERY_AND_HISTORICAL_RECOVERY_PASS / HUMAN_UNITY_CHECK_PENDING /
REAL_CLIENT_QUERY_PENDING. Human next: HUMAN-POST-DELIVERY-CHECKLIST.md.

## Human reopening result: compile reported clean, Manager blocked

The human reports no compilation errors; screenshot shows Needs attention /
INVALID_OR_AMBIGUOUS: Supervisor process command identity is invalid. A bounded
read-only diagnosis identifies the authenticated old d856a8f Supervisor still
alive after Unity closure and Package-reference switching. Its process start,
executable and both command fingerprints match owner evidence, but the new
Package refuses its old script path. Delivery preflight missed this independent
owner; the original installation and restored helper hashes remain intact.
See POST-DELIVERY-HUMAN-RESULT.md and the proposed SUPERVISOR-HANDOFF-PLAN.md.
No process control, runtime mutation, production command or query was performed.
Current status: HUMAN_COMPILE_NO_ERRORS_REPORTED / MANAGER_NEEDS_ATTENTION /
SUPERVISOR_HANDOFF_AUTHORIZATION_PENDING / REAL_CLIENT_QUERY_BLOCKED.

## Authorized Supervisor handoff: owner already exited before invocation

The user approved SUPERVISOR-HANDOFF-PLAN.md and confirmed Unity closed. Fresh
observations found original PID 75380 absent, no Node command targeting this
project, no Unity process/lock and no Supervisor state/lock. The last retained
event is supervisor_retiring / authenticated_shutdown at
2026-10-20T13:27:57.080Z. The actor initiating shutdown was not independently
attributed; observed exit and that retained event are the evidence.
No stop was invoked (zero calls), and no substitute owner was targeted.
All protected delivery/reference/selection/config hashes and the restored
helper still match. Supervisor event and remaining Coordinator logs were
preserved under .backups/s39-supervisor-handoff-observed-exit-20261020/.
SUPERVISOR-HANDOFF-RECEIPT.json records the result. No external files, source,
process state or runtime selection were changed by this pass.
Next: human reopen and Console/Manager observation. Coordinator/Manager Ready
and real Codex query remain unverified; no Install/Reinstall is authorized.

## Human Ready after reopening; new client attempt prepared

Human screenshot/report shows Ready after reopening. The UI labels this as
Last verified/cached. A bounded read-only file/process observation finds a new
c07bb59 Supervisor PID 30756 and retained core_ready / COORDINATOR_OPERATIONAL
with Coordinator failure category NONE; original instance/epoch/generation,
protected hashes and query sample are preserved. See POST-HANDOFF-READY-RESULT.md.
CLIENT-ATTEMPT-02-HANDOFF.md prepares a fresh human-initiated target-root Codex
chat with one status and one conditional search. No chat was dispatched and
no production command, process control, Installer action or MCP call occurred.
Actual client query remains pending; historical recovery is not clean-Install
acceptance. The old Attempt 01 instruction remains historical.

## Attempt 02 stopped; existing host startup logs inspected

Human returned Attempt 02 from chat 01a15985-a8e4-77b1-a999-6dd631bfff6b. Target
tools absent, status/query calls zero, disk identity consistent, query and
response identity gates incomplete. Existing exact-thread desktop records show
target startup followed after 102/155 ms by initialize connection closure;
readonly existing-log DB inspection corroborates a runtime startup failure.
Actual child cwd/executable/stderr/exit were not found in these bounded records.
See CLIENT-ATTEMPT-02-RESULT.md. The former handoff is now historical.

HOST-STARTUP-CAPTURE-PLAN.md and an inert repository-local capture script prepare
one actual-host startup observation with original cwd/args, no tool calls,
single-spawn admission and exact temporary-config restoration. The script only
passed node --check; no authorization file, config edit, production command,
process control or MCP retry occurred. Evidence snapshot:
.artifacts/tests/s39-attempt02-host-startup-evidence.json. This is S39-owned
protected diagnostic evidence; no cleanup authorized. Next: explicit user
decision on that concrete diagnostic envelope, not another query attempt.

## Passive diagnostic capability inventory complete, no recording

User asked to discuss preserving real registration/MCP timing and approved
only read-only installed-capability inspection. WPR/ETW/WPA/logman are present;
WPR reports no recording. Local Kernel-Process metadata supplies process
start/stop, parent/image/timing and exit code, but lacks command line/cwd/stderr.
WMI start/stop metadata is present; live command-line snapshots can race the
100-ms exit. Current process is not elevated, Security log access is denied,
Sysmon channel is not found, Kernel-Process Analytic is disabled and unchanged.
Procmon was not found in PATH/checked common locations; no exhaustive search.
See PASSIVE-TRACE-CAPABILITY-ASSESSMENT.md and the structured artifact receipt.

No trace, subscription, privilege elevation, event-channel change, new chat,
MCP connection or external write occurred. Shim proposal remains deferred.
Next is route/field/permission/observation-window alignment, not another retry.

## Approved source diagnostics completed; real-client gate unchanged

The user selected static analysis, then approved the bounded bootstrap
diagnostics proposal. The stable wrapper now writes one best-effort record at
wrapper error or worker exit, with no startup writes or protocol inspection.
The availability probe preserves bounded child stderr and exit/termination
attribution on failure. Worker exit, requested wrapper exit code and externally
observed child-process exit are distinct facts; zero does not prove initialize.

BOOTSTRAP-DIAGNOSTICS-RESULT.md records the source snapshot and 15 passing
isolated scenarios, syntax, scoped whitespace and Package path provenance.
The initial fixture's natural-exit expectation was corrected without changing
the existing stdin connection behavior. Final evidence:
.artifacts/tests/s39-bootstrap-diagnostics/r-b90d9fa3-6c2d-4722-8c3c-21a635f884d2/.

This supersedes prior next-action suggestions to activate the capture shim or
system tracing. Both remain deferred. No real project, delivery or registration
was changed; no Unity/Provider/real MCP, commit/export or retry occurred. Existing
dirty generation/manifests remain protected and no new release closure is
claimed. Current status: BOOTSTRAP_DIAGNOSTICS_SOURCE_FOCUSED_PASS / NOT_DELIVERED /
REAL_CLIENT_QUERY_BLOCKED. Next: User disposition on source result; delivery and
human-owned real-client acceptance retain separate authority.

## Local diagnostic delivery preparation complete; fresh project recommended

A HEAD-based repository-local candidate contains exactly six Package deltas,
with canonical regenerated metadata and unchanged immutable generation and
host-current bytes. Candidate release closure (60/60), materializer/native
bindings, candidate-own 15 diagnostic scenarios and path provenance PASS.
The harness gained only explicit enclosing-repository portability support;
production wrapper/probe bytes are unchanged from the prior source result.

Production-reader proof rejects the old wrapper under the candidate Package.
A fixture-only wrapper replacement preserves selected instance/epoch but its
old activation contract is still refused. Protected fixture records stay
unchanged. A separate fresh synthetic Install commits and both readers admit
it. These fixtures do not establish real Install/Ready or the startup root cause.

DIAGNOSTICS-DELIVERY-PREPARATION-RESULT.md records hashes and evidence;
DIAGNOSTICS-DELIVERY-PLAN.md proposes an exact local commit/export/package-copy
grant, followed by separately aligned human CodedbTest_1 creation and first
Install. Original CodedbTest_0 and delivery remain protected. No external write,
staging, commit, formal export, process inventory/control, real runtime or MCP
retry occurred. Current status: LOCAL_CANDIDATE_CLOSURE_PASS /
SAME_GENERATION_HANDOFF_NOT_ADMITTED / FRESH_INSTALL_FIXTURE_PASS /
NOT_DELIVERED / REAL_CLIENT_QUERY_BLOCKED. Next decision belongs to User.

## Fresh diagnostic project created by human; preflight complete

The user chose CodedbTest_1, supplied its root and reported Unity closed.
Read-only checks confirm 2022.3.62f3, no CodeDB dependency/AIWork/project MCP
config, and no UnityLockfile. Baseline manifest/lock/version hashes are recorded
in DIAGNOSTICS-DELIVERY-PLAN.md. No external writes or process inventory occurred.
All six candidate hashes still match; HEAD is unchanged and the index is empty.

The plan now concretely proposes grant B: after grant A delivery, add the exact
Package dependency and a query sample only; let normal human Unity import
generate the lock/.meta state. Grants A/B can be explicitly initiated together,
then execution stops before human compilation/first Install. Project selection
and creation do not independently authorize the repository-required exact
commit. No commit/delivery/project preparation has yet been performed.

## Exact diagnostic delivery and fresh-project preparation authorized

The human replied `批准` to the exact local commit, Package export/validation/
external copy and CodedbTest_1 manifest/sample preparation sequence described
in DIAGNOSTICS-DELIVERY-PLAN.md grants A/B. Execution is in progress. No push,
old-project write, automated Unity/Install or real MCP retry is authorized.
The terminal gate is the human's compile/first-Install observation.

## Exact diagnostics delivery and CodedbTest_1 preparation completed

Created the one approved commit 237c72d9980114b99887fb8e805658447dd8d4fd, with
exactly six Package paths/seven task records and no push. Exported that commit;
both commit archive and exact ZIP pass 60/60 closure, materializer/native
admission. The ZIP's own 15 diagnostics scenarios and path provenance PASS.
ZIP SHA-256: f6c1811ddd65f229f995192918940e1d07ac98bb8f5482aae6c01f890ebdcf7e.
All 631 external copied files match the approved candidate and ZIP extraction.

CodedbTest_1 now references file:../../Packages/237c72d/com.rice.ai-codedb and
has the query sample at Assets/CodeDBAcceptance/S39QueryProbe.cs, marker line 5.
Lock/version remain unchanged and normal Unity import owns lock/.meta updates.
Original Package inventory and selected CodedbTest_0 protected file hashes are
unchanged. Unrelated working bytes/deletions were preserved through commit and
delivery; post-delivery task-record changes remain uncommitted. Index empty.

See DIAGNOSTICS-DELIVERY-RESULT.md and the retained execution receipts. Next:
human uses DIAGNOSTICS-HUMAN-FIRST-INSTALL-CHECKLIST.md. No automated Unity,
real Provider/MCP, process control, Install or retry occurred. Status:
EXACT_DIAGNOSTICS_DELIVERY_PASS / FRESH_PROJECT_PREPARATION_PASS /
HUMAN_COMPILE_AND_FIRST_INSTALL_PENDING / REAL_CLIENT_QUERY_BLOCKED.

## CodedbTest_1 human first Install Ready; actual-client handoff prepared

On 2026-10-21 the human screenshot shows Install CodeDB completed / Ready,
17.41 s, version preview.5 and generation poc.43. A separate Console-clean
report was not supplied. Read-only observation confirms manifest/lock 237c72d,
installed diagnostic wrapper hash, new READY instance d442deda8b914a7bad6af7dd79e2d50c
and epoch 5b1c035c0fd44ea095d045ab4f5c79ba. The pointer stayed unchanged and
its instance-manifest hash matches. Registration is codedb-codedbtest-1.

One existing bootstrap worker_exit record confirms diagnostic writing through
normal use. It predates the upcoming client attempt; caller attribution and
protocol success are not inferred from exit zero. Install availability receipt
also predates activation and is not a Codex response. See
CODEDBTEST-1-FIRST-INSTALL-RESULT.md for the exact baseline/hashes.

CLIENT-ATTEMPT-03-HANDOFF.md prepares a human-initiated fresh target-root chat,
one status/conditional search and stop-on-first-failure rules with a single
optional read-only failure diagnostic snapshot. No chat dispatch, real MCP,
wrapper/probe/Provider launch, external write or process control occurred.
Status: HUMAN_INSTALL_READY_OBSERVED / DISK_BINDING_MATCH /
ATTEMPT_03_PREPARED_NOT_DISPATCHED / REAL_CLIENT_QUERY_NOT_EXECUTED.

## Deferred UI observation recorded — 2026-10-21

User reports Ready -> Unconfirmed checking -> Ready shortly after first
Install. Screenshot captures Host payload STARTING / missing authenticated
Supervisor observation and MCP availability Pending. Exact timing and cause
are unmeasured. Recorded separately in
`../cdb-manager-ready-unconfirmed-followup/TASK.md` as DEFERRED / FOLLOW-UP /
RECORD_ONLY. Resolution time remains for later user arrangement. No diagnosis,
reproduction or source/runtime change was performed; Attempt 03 stays pending.

## Attempt 03 stopped at wrong-workspace preflight

The human returned an acceptance-chat report with actual cwd CodedbTest_0,
not required CodedbTest_1. The chat stopped before reading project inputs,
with status/search each zero calls and no original responses. Target tools
were absent in that wrongly bound chat; this does not establish a target
CodedbTest_1 startup failure. No hashes/lease/diagnostic snapshot were obtained.
See CLIENT-ATTEMPT-03-RESULT.md; its former instruction is now historical.

CLIENT-ATTEMPT-04-HANDOFF.md prepares a fresh bounded attempt with explicit
workspace-selection precondition. No chat, runtime, query or process operation
is dispatched by this parent, and no environment/registration fix is proposed.
The deferred Unconfirmed item remains untouched. Status:
ATTEMPT_03_STOPPED_WRONG_WORKSPACE / TARGET_CALLS_ZERO /
ATTEMPT_04_PREPARED_NOT_DISPATCHED / REAL_CLIENT_QUERY_NOT_EXECUTED.

## Separate correct-root Attempt 03 report; host startup failure established

The human returned another report labelled Attempt 03, this time rooted in
CodedbTest_1. App thread inspection identifies `执行 S39 外部工程验收`, id
01a15c2e-25ee-7620-9cad-ade624685b4a, independently from the earlier wrong-root
chat. Both records remain preserved. Correct-root disk binding passed, target
status/search each zero calls, baseline diagnostic only and no attributable
new lease/response. See CLIENT-ATTEMPT-03-CODEDBTEST-1-RESULT.md.

Existing exact-thread desktop log lines 4948/4958 show codedb-codedbtest-1
starting at 01:58:10.813Z then failed at 01:58:10.987Z (174 ms), initialize
connection closed. This narrows registration uncertainty: the host did reach
target startup. Actual child cwd/executable/stderr/exit remain unavailable;
no new diagnostic cannot prove no execution. Filtered source records retained
under .artifacts/tests/s39-attempt03-codedbtest1/. No real retry, startup,
external mutation or process control occurred. Attempt 04 placed on hold;
next step is diagnostic alignment, not another unchanged acceptance attempt.

The retained full exact-thread filter also contains a second existing startup
pair at lines 5011/5012, 01:58:12.493Z -> 01:58:12.578Z (85 ms), same error.
Its initiating actor is not attributed; these are host events, not target tool
calls or retries made by this development session.

## Read-only startup-chain analysis completed

User requested analysis. CLIENT-STARTUP-STATIC-ANALYSIS.md maps pre-body import/
root-validation coverage limits against normal wrapper/worker failure logging.
Current wrapper/helper/worker/import bytes match the delivered Package; no
diagnostic ancestor reparse points observed. This does not prove actual child
cwd/entry/Node or successful log access during the failed connection.

Located a separate active <codex-home>/logs_2.sqlite, unlike the previously
inspected older sqlite/logs_2.sqlite. Readonly bounded rows 98064591/98064593
confirm failed initialize and tool omission without an exact ready client.
Retained only exact-thread/server events. Most useful missing evidence is
actual child stderr plus resolved entry/cwd/Node and exit; no root cause or
environment fix is claimed. No live capture, startup, retry or external edit.

## Diagnostic and repair sequence proposed for alignment

CLIENT-STARTUP-DIAGNOSTIC-PLAN.md defines four separate gates: read-only route
selection; one specifically authorized actual-host startup observation; evidence-
specific narrow repair; focused checks/delivery and actual-client acceptance.
Prefer host-native stderr/launch evidence or a field-verified passive route,
preserving production registration/environment. Existing process-only ETW
does not promise cwd/stderr. A shim remains an explicitly separate fallback,
not a default or authorized operation. No new project or query retry proposed.
Current activity is plan recording only; no live collection/tool installation,
configuration change, repair, dispatch or schedule was executed.

## Approved Stage 1 host diagnostic capability check completed

HOST-DIAGNOSTIC-CAPABILITY-RESULT.md records installed metadata, bounded shipped
code/string inspection, help-only CLI calls and existing-window stderr search.
Native MCP stderr messages exist in the installed binary, but actual failed
stream sink/level and a supported collection method remain unverified. Shipped
app-server launch code defaults RUST_LOG to warn unless inherited; actual failed
parent setting and applicability are not observed. No override/restart made.

No stderr rows in the bounded active log window. Existing WPR/logman route
lacks cwd/stderr; Procmon was not found in PATH/limited common directories.
No complete live route is admitted. Recommend separately aligning passive
process/file-tool capability/permission/filter assessment before installation
or capture. No real MCP, recorder, new chat, process control, external config/
runtime mutation, download, elevation, repair or commit occurred.

## Approved Procmon read-only screening completed — 2026-10-21

PROCMON-DIAGNOSTIC-ASSESSMENT.md records current Microsoft documentation,
fresh OS version confirmation, candidate comparison and hard-gate disposition.
Official Procmon v4.12 lists Windows 11+ clients; this host is Windows 10/19045.
Documented support gate fails, without claiming execution is impossible.
The official non-destructive filter description also does not establish
target-only raw collection. Exact cwd/exit field coverage, stderr facility,
rights/driver lifecycle and measured overhead remain unverified.

Decision DEFER / NO_CAPTURE_ROUTE_ADMITTED. No acquisition, recorder startup,
MCP attempt, restart, external configuration/environment/runtime change,
elevation or production repair. Attempt 04 stays on hold; CodedbTest_1 remains
the target and no new Unity project is required for diagnosis. Further choices
are explicit compatible official-tool provenance/isolation research or a
separately reviewed host-logging experiment with possible restart/environment
effects; neither is automatically executed. Unconfirmed remains deferred.

## Approved historical Procmon provenance/isolation check completed

Official MicrosoftDocs historical revisions establish v4.04/v4.01 Windows 10
support. Both link an unversioned ZIP/Live executable, not a frozen old binary;
no pinned official artifact/digest was established by this bounded search.
Microsoft's startup-troubleshooting article confirms elevated operation and
normally automatic capture, so launching it for menu inspection would itself
cross the capture boundary. Its broad-capture/post-filter example does not
establish target-only raw retention. Exact cwd/exit-code/stderr delivery,
version-specific exclusion and overhead remain unverified. See the cited
follow-up in PROCMON-DIAGNOSTIC-ASSESSMENT.md.

Procmon remains DEFER, with historical-version discovery now closed. Recommend
next assessing a supported host-native stderr control/sink and restart/output
impacts read-only; no guessed logging override or real-host experiment. No tool
acquisition, capture, elevation, restart, MCP/client attempt or project changes.
Only records edited, no commit/push. Attempt 04 remains on hold and the
Unconfirmed FOLLOW-UP stays deferred; root cause/query acceptance remain open.

## Native stderr route read-only checkpoint — 2026-10-21

The installed Codex `app.asar` was read at bounded byte contexts only. Its
`StdioConnection` attaches a handler to the spawned child's `stderr` stream,
stores the latest trimmed message as `lastStderrMessage`, and uses that value as
the close reason. This proves a host-side stderr read path exists. It does not
prove that target MCP stderr is persisted to desktop logs/SQLite, that every
stderr line is retained, or that the relevant connection uses this exact sink.

The same static launch code sets `LOG_FORMAT=json` and defaults `RUST_LOG` from
the inherited environment to `warn`; this is observed implementation context,
not an approved setting change or proof of the target MCP's effective filter.
The bounded active `logs_2.sqlite` query for the exact CodedbTest_1 window still
contains only the server-start failure and the subsequent no-ready-client
omission. No target stderr row was found. Desktop log rows likewise contain the
generic initialize closure only.

Conclusion: the “host never reads stderr” hypothesis is rejected, while the
“stderr is available for retrospective diagnosis” hypothesis remains unproven.
No logging override, restart, MCP retry, environment/configuration change or
process operation was performed. The next alignment item is whether a supported
host control can expose this already-read stderr before a separate one-window
diagnostic startup; do not guess `RUST_LOG` or treat this static evidence as a
runtime setting contract.

## Public CLI logging-control check — 2026-10-21

Read-only help was collected from the installed Codex CLI for the top-level
command, `app-server`, `app-server daemon`, `debug app-server`, `doctor`, and
`mcp`. The public help exposes no option for MCP stderr export, child-stderr
retention, log-level selection, or log-file routing. `app-server daemon` exposes
only lifecycle operations such as start/restart/stop; none was executed.

This does not prove that no internal setting exists. It does establish that no
documented CLI switch is available in the inspected version, so a guessed
`RUST_LOG`, `-c` key, daemon restart or hidden flag cannot be promoted to the
next diagnostic plan. The host-native route remains **read-only capability
identified, supported stderr exposure unavailable**. Any setting/restart test
would be a separately approved experiment that changes the parent environment.

## Baseline correction — v0.2 is not a valid A/B control — 2026-10-21

The user clarified that v0.2 carries Git and strict initialization prerequisites
that cannot complete in this test environment; this incompatibility is one reason
for the v0.3 upgrade. Therefore v0.2 success/failure cannot serve as a controlled
same-environment comparison and must not be used to attribute the current
initialize closure to a v0.3 regression.

The diagnostic baseline is now the v0.3 contract itself: project-local wrapper,
relative cwd/entry resolution, supported Node/Provider prerequisites, selected
instance/lease validation, stdio initialize and tool publication. The next
diagnostic step, if authorized, must isolate one of those v0.3 boundaries while
preserving the target project and normal registration. No v0.2 package switch,
new Unity project or historical initialization workaround is proposed.

## Target-session self-check handoff prepared — 2026-10-21

`CLIENT-CODEDBTEST-1-SELF-CHECK-HANDOFF.md` contains a user-forwardable,
read-only checklist for a fresh session rooted at CodedbTest_1. It checks actual
cwd, project registration, manifest/lock, Node path/version, process cwd,
selected instance, wrapper hash, exact visible tool namespace and bounded target
logs. It explicitly requires zero CodeDB calls and forbids wrapper/process
launch, retry, configuration changes and substitutes. The parent has not sent
the instruction or started a target session. Self-check output remains local
environment evidence and cannot substitute for MCP response identity.

## Target-session self-check returned — 2026-10-21

The user forwarded the handoff to a fresh CodedbTest_1 session. It reported the
correct external project cwd and matching project registration, manifest/lock,
Package path/version, Node resolution (`F:/Program/nodejs/node.exe`, v24.14.1),
process cwd, LOCALAPPDATA presence, selected pointer/instance identities and
wrapper SHA-256. The target namespace `mcp__codedb_codedbtest_1__*` was not
exposed; the session stopped immediately with status=0, query=0 and no other
CodeDB calls. It did not read logs, start wrapper/worker, or run a substitute.

This is strong v0.3 project-context evidence: the ordinary session cwd and Node
environment agree with the project contract, and the static Package/instance
inputs are internally consistent. It substantially lowers the probability that
the failure is caused by a malformed project config, wrong Package path or wrong
Node selection. It still does not prove the host-spawned MCP child was created,
nor does it provide MCP response identity, stderr or exit evidence. The missing
`activation_epoch` in instance.json is expected by the contract and is not a new
conflict; the pointer is its authority.

The diagnostic focus is now the Codex host startup boundary: child creation,
effective launch path/cwd, earliest wrapper/import behavior and initialize
transport. Do not repeat the project self-check or attempt a query. No new Unity
project is needed; CodedbTest_1 remains the target.

## Authorized process observation 01 stopped; recorder cleaned

See PROCESS-OBSERVATION-01-RESULT.md. One real logman start returned access
denied (0x80070005), but partially created the uniquely named session. Subsequent
verification found and stopped that exact owned session; absence was confirmed.
ETL decoding showed one header and zero Kernel-Process events. No target chat
was requested/attributed and zero CodeDB calls were made. The partial session
file timestamps span about 62 seconds, exceeding the intended 60-second bound;
the receipt correction explicitly records this instead of claiming compliant
capture. No second real start or provider-enable retry occurred.

The observer's failed-start cleanup was repaired and checked with syntax plus
two mocked cases (partial session cleanup and existing-session isolation).
Elevated provider enable/field delivery remains untested. A separate-admin-
terminal procedure and target-chat instruction are reviewable in
PROCESS-OBSERVATION-ADMIN-HANDOFF.md; they are not executed. This stopped run
does not authorize a fresh observation. Only the recorder would be elevated;
Codex/Unity/environment/registration remain unchanged.

Interpretation correction to earlier native-stderr wording: inspected desktop
StdioConnection handles app-server child stderr, not proven direct target MCP
stderr. The claim that target stderr was already read and merely not persisted
is not established. Raw ETW scope is system-wide process metadata; no target
absence inference is admitted without provider delivery/loss and attribution.

## Observation 02 authorized; awaiting human administrator terminal

The user explicitly approved the new administrator-recorder run. The reviewed
handoff is updated and a prefilled machine-local launch script is prepared under
`.artifacts/tests/s39-process-observation/`, with run id
6b144c9ac2b34dcc921c447585171f8c. It validates elevation before any ETW command,
refuses reuse of an existing run directory and invokes the corrected observer.
No administrator terminal or recorder has been started by this development
session; the next required action is the human terminal launch, followed by one
normal CodedbTest_1 chat only after OBSERVER_READY. The existing authorization
persists; no new confirmation is required for those steps. No target query,
process restart, environment change or additional window is granted.

## Observation 02 stopped at observer preflight; repair checked

User screenshot/receipt show OBSERVER_ERROR before OBSERVER_READY. The initial
query returned 0x80300002 (session absent), but the observer rejected the output's
English-text condition. No ETW create occurred, no ETL exists and exact-name
query confirms absence. This is an observer defect, not a CodeDB startup result.
The original query text was not retained, so localization is not proven as its
exact character-level trigger. See PROCESS-OBSERVATION-02-RESULT.md.

Numeric absent-session checks now replace English text checks; initial output
is retained, exceptions are displayed and unknown cleanup states are explicit.
Four mocked cases passed under both Windows PowerShell 5.1 and PowerShell 7,
with zero real ETW calls. Old evidence remains intact; observation 03 has a new
prepared launcher/id but is not run or authorized. No project/source/runtime,
MCP registration, environment, Codex/Unity privileges or target calls changed.

## Observation 03 authorized; corrected launcher awaiting human execution

The user explicitly approved observation 03 after the preflight repair. The
prefilled launcher `launch-03-eae4fb16d8894512967086c76f0ceaab.ps1` is now
authorized for one execution in the separate administrator terminal. Its new
session/output identity preserves previous evidence. The human creates one
normal CodedbTest_1 chat only after OBSERVER_READY. No recorder, target startup
or retry was executed by this development session; no further confirmation is
needed for these authorized steps. An error or timeout stops the window.

## Observation 03 captured and analyzed — target PID remains a candidate

See PROCESS-OBSERVATION-03-RESULT.md. The human's administrator run succeeded,
recording 7.6860557 seconds; its owned session was stopped and absence confirmed.
Tracerpt reports zero lost events and 42 process events. A trace-metadata schema
warning remains; both readers agree on process counts/candidate lifecycle fields.
Target thread was recovered and matched to the human's chat, cwd and report.

Node PID 70836, parent app-server PID 75104, used the expected Node image and
exited with code 1 after 227.8245 ms, 1.2267 ms before the target host initialize
failure. This is highly correlated; a second same-image Node child existed and
there are no argv/cwd/service fields to establish direct target-PID ownership.
Do not promote candidate timing into proof of target wrapper execution or a
specific failure stage. No stderr/new bootstrap was obtained. Input hashes
remained unchanged and all CodeDB tool calls were zero.

Capture is complete; no repeat observation/query is authorized. Next evidence
must bind the target server to a PID/entry and provide cause-bearing launch
details or stderr. No Package/environment repair or root-cause conclusion is
justified yet. Query/response identity, performance and release gates stay open.

## Command-line trace route assessed — no new capture

COMMANDLINE-TRACE-ASSESSMENT.md records the documented native Process_V2
command-line family, local schema check, WPR/private-system-session comparison
and hard gates. A uniquely owned system session with the documented process
flag is the preferred preparation candidate. WPR instance naming alone does
not establish underlying kernel-session isolation. Target-only raw acquisition
is not established: start/end rundown can include existing process command
lines and other schema fields. This broader data boundary must be aligned
before any capture. A controller and offline error/cleanup checks would precede
a separately approved bounded live window. No controller/profile, ETW session,
new target chat/startup, config/environment change or CodeDB call occurred.
No new causal evidence was obtained; the root cause remains open.

## Native command-line observer prepared and checked offline

User agreed to proceed with preparation. Separate native controller/core/entry
and read-only XML summarizer now exist. Windows PowerShell 5.1 and PowerShell 7
each passed 24 simulated/fixture checks, with zero native ETW calls. An initial
PS5 fixture delegate-conversion issue was repaired and the final snapshots pass
on both hosts. See COMMANDLINE-OBSERVER-PREPARATION-RESULT.md for evidence and
limits, including the independent stop timer and possible native blocking or
cleanup failure. Source hashes are pinned by the one-run machine-local launcher.
COMMANDLINE-OBSERVATION-04-HANDOFF.md defines the proposed single live window,
system-wide full-command-line/rundown scope, human trigger and no-retry rule.
It remains PREPARED / NOT_AUTHORIZED; no recorder or target startup was run.
Existing observation-03 evidence, Package and project registration are intact.
No new cause-bearing evidence or query/identity acceptance was obtained.

## Process observation 04 authorized; awaiting human launch

The user explicitly authorized the proposed single real window, including
system-wide process command lines and rundown. Four source pins match; the
external Unity project exists and the unique live evidence directory remains
absent. The launcher/handoff status is updated to authorized, not started.
The human launches only the independent administrator recorder and creates one
normal CodedbTest_1 chat after OBSERVER_READY. No new confirmation is needed
for those steps. No real ETW call, target startup/query, configuration change
or retry occurred during this authorization handoff.

## Process observation 04 completed — expected argv captured, cause still open

See PROCESS-OBSERVATION-04-RESULT.md. The human's one authorized capture and
target chat completed. Native capture elapsed 6.8837564 seconds, 4.25-MiB ETL,
zero loss counters; start/stop succeeded and owned-session absence was
independently confirmed. Five input hashes stayed unchanged; target CodeDB=0.

Three short-lived Node processes carry the exact expected relative wrapper
entry and --root . args under the Codex parent, all exit 1. Existing host logs
correlate two startups to the supplied target chat (the later one labelled
runtime refresh in the runtime DB), and one to another host thread. This is
argv-to-PID evidence plus host temporal correlation, not direct service/cwd
identity. No manual retry by the target was observed. Actual cwd/resolved file,
primary stderr and executed wrapper stage remain unverified. No new bootstrap
record; bounded existing runtime rows provide only generic closure/omission.

The native logger also emitted 539 automatic SystemConfig events, beyond the
process-only expectation; broader raw metadata is retained locally and not
displayed. Tracerpt process payloads decode but a header-schema warning remains;
Get-WinEvent corroborates process event headers, not argv payloads. Time-rendering
differences preclude precise submillisecond creation-latency claims. Preserve
these limits; do not repeat the collector under an isolation claim.

Capture is closed and the handoff marked DO_NOT_RERUN. Review existing static
cwd/entry/import resolution next; no repair/new project/Package switch or new
operational window is justified. Query/identity and release gates remain open.

## Cwd/import static analysis: path-contract coverage gap identified

CWD-AND-IMPORT-STATIC-ANALYSIS.md records the delivered generator, validator
and probe comparison. The probe explicitly chooses projectRoot cwd/resolved
entry; config tests assert literal cwd=".". Their PASS does not validate
Codex's relative-cwd base. Current official OpenAI pages fetched successfully
describe a general .codex-relative project path rule, but MCP cwd is a legacy
string field and its exact installed-native normalization remains unknown.
Selected installed app JS does not close that gap. This is a concrete
compatibility/acceptance concern, not proof of the failed child's cwd or cause.

Six installed entry/import/manifest files match delivered Package bytes; strict
UTF-8/BOM/import-edge and pointer/instance/generation/worker hash checks agree.
No missing static dependency/current corruption found. No module was executed,
test suite run, startup repeated, project/Package/config edited or process
controlled. Root cause remains open; prioritize original cwd/error evidence or
a separately scoped single-variable cwd experiment. No permanent ".." or
machine-specific config/product fix is selected. Unconfirmed remains deferred.

## Cwd experiment 01: applied, awaiting the one human-created chat

User agreed to the temporary one-variable experiment. See
CWD-EXPERIMENT-01-HANDOFF.md and CWD-EXPERIMENT-01-RESULT.md. Exact bytes and
bootstrap/input baseline retained; only target cwd was replaced with the
confirmed absolute external root at 2026-10-21T06:25:17Z. Original config hash
cc266892...038b, experiment hash 42699413...f93e; manifest, lock, pointer and
wrapper match all four baselines. A preparation-only helper fault was recorded
and corrected before the first config replacement. Target runtime not manually
started; CodeDB calls remain zero. Host adoption/startup remains unverified.

State APPLIED_AWAITING_HUMAN_CHAT / RESTORE_PENDING. One normal human-created
target chat is next. Close its observation before exact guarded restore; any
native refresh caused by restoration remains outside this experiment outcome.
Attempt 04 query acceptance remains ON_HOLD; no permanent product correction.

## Cwd experiment 01 closed: six tools visible, original config restored

See CWD-EXPERIMENT-01-RESULT.md. The app lookup and read verified the one human
chat `01a15d25-ef86-7c31-82c6-641fb3d664c0`, title `观测 MCP 启动状态`: correct
cwd, report of six tools in the exact target namespace, no directly supplied
startup error, CodeDB=0, completed/idle. This is positive visibility evidence
with absolute cwd, supporting the relative-cwd/path compatibility direction.
It does not prove historical child cwd or a fresh target initialize handshake.

The bounded 180-second existing runtime-log window contains one service row:
cached catalog use in a DIFFERENT thread, not attributable target startup.
Expected desktop day logs are stale; no wider search was substituted. No new
bootstrap diagnostic. Target observation closed before restoration. Original
config bytes restored and verified 2026-10-21T06:32:50Z; four protected input
hashes match. Restoration refresh, if any, is outside the experiment outcome.
State COMPLETE / ORIGINAL_BYTES_RESTORED / DO_NOT_RERUN. Query/identity and
release gates remain open; no product source fix or further run performed.

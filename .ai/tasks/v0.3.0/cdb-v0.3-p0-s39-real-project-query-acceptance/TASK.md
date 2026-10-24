# S39 independent Package consumer and Codex query acceptance

Date: 2026-10-20.

## Current checkpoint — 2026-10-21

FRESH_PROJECT_FUNCTIONAL_PASS / COMPLETE_SESSION_IDENTITY_DEFERRED.
The latest accepted consumer is CodedbTest_2 with source commit c848049,
Package 0.3.0-preview.5 / poc.44. Human first Install reached Ready; the new
client exposed all six target tools and completed one status call plus one
actual C# text-hit query. Complete raw transferred responses and evidence limits
are recorded in
`../cdb-v0.3-p0-s39-mcp-cwd-registration-fix/ACCEPTANCE-CLOSURE.md`.

This checkpoint supersedes old "current" diagnostic/next-action instructions
below for the functional discovery/status/query objective. They remain retained
historical records, not an instruction to resume Attempt 04 or old traces.
Earlier failed attempts are not relabeled as passed. Missing independent
response/session identity remains explicit; no overall release/upgrade PASS.
No more calls are needed for the completed bounded fresh-project gate.
The accepted source branch still awaits separately aligned primary-checkout
integration; see SOURCE-INTEGRATION-PLAN.md in the cwd-fix task.

## Metadata

- Product/version: UnityCodeDB v0.3.0, preview.5.
- Workflow: codedb-workflow-v2, revision 2.7.
- Status: FRESH_PROJECT_FUNCTIONAL_PASS / COMPLETE_SESSION_IDENTITY_DEFERRED
  (current checkpoint above; historical attempts below remain unchanged).
- Planner/Coder: current parent; independent Verifier: not requested.
- Review mode: NORMAL; execution mode: DURABLE_SESSION.
- Delegation authorization: NOT_AUTHORIZED; session policy: MANUAL_PROVISION.
- Requirement source: roadmap P0 Project-local Codex MCP Discovery and
  `Documentation~/v0.3.0-p0-codex-client-discovery.md`.

## Objective

Latest diagnostic checkpoint (2026-10-21): the approved Procmon read-only
screening is complete. See PROCMON-DIAGNOSTIC-ASSESSMENT.md. Official current
v4.12 lists Windows 11+ while this host is Windows 10/19045; target support
gate fails, raw exclusion/rights/overhead remain unverified. Decision DEFER,
no live route admitted. Attempt 04 remains on hold. The subsequently approved
historical provenance/isolation check is also complete: v4.04/v4.01 officially
documented Windows 10 support, but historical links are mutable and no fixed
official binary or verified pre-retention exclusion was established. Procmon
remains deferred; stop historical-tool discovery. Recommended next step is a
bounded host-native logging-control/sink assessment, without any settings,
restart, acquisition or execution grant. See the assessment's follow-up section.

Prove that the existing exact Package can be consumed in the user's independent
non-Git Unity project, complete its first Install/Ready, then expose project
tools and a correct bounded source query in a real new Codex chat.

The user replaced the nested-project route with independent external acceptance
and created `CodedbTest_0`. This supersedes the previous S38-root S39 handoff;
the initial preparation remains historical evidence in RESULT.md. S38's
lifecycle result and runtime are not migrated or reinterpreted.

## Scope and binding

- External acceptance root: user-selected `CodedbTest` directory, outside the
  development repository. Machine-local absolute binding is in the user message.
- Project: `<external-acceptance-root>/CodedbTest_0`, Unity 2022.3.62f3.
- Source ZIP: `.artifacts/s37-supervisor-terminal-result-d856a8f/com.rice.ai-codedb.zip`;
  delivery commit `d856a8f0916253f45369ae3fde7f4a2a6b26b9cb`, preview.5/poc.43.
- Consumer delivery: `<external-acceptance-root>/Packages/d856a8f/`, containing
  the byte-identical ZIP and `com.rice.ai-codedb/` extracted from that ZIP.
- Expected manifest reference: `file:../../Packages/d856a8f/com.rice.ai-codedb`,
  resolved from the Unity project's Packages directory before writing.
- Server name/namespace: derive from actual installed project registration and
  verify against CodedbTest_0; never reuse current-lifecycle's registration.
- Expected instance: `2414c73c2fbb47f4b664c1bdbcad5969`; activation epoch:
  `4ad2120d1559487f8e54c015685496f6`. First-install evidence is recorded in
  `FIRST-INSTALL-HUMAN-RESULT.md`; client identity correlation remains pending.
- Change allowlist: this task directory, validation-project index, external
  consumer delivery directory, project Packages manifest/lock and
  `Assets/CodeDBAcceptance/S39QueryProbe.cs`; temporary original-config backup
  under `.backups/s39-external-project-baseline-20261020/`.
  Unity owns generated meta files.
- Read-only dependency closure: project manifest/lock, project MCP registration,
  selected pointer/instance manifest, delivered wrapper tool schema, sample.
- Protected state: all other source, configuration, runtime and prior evidence.
- Generation transition: NONE in the Package; a fresh independent project
  installation creates a new project-bound instance. No runtime state is copied.

## Execution envelope

The user approved S39 preparation and query acceptance, then selected the
external-project route and supplied the created project. Continue reversible
delivery preparation and task alignment. Unity operations and the real Install
remain human-owned. No parent-created chat, cross-chat message or delegation
is authorized. Provision the client chat only after import and first-install
identity evidence are recorded; do not reuse the old pasted instruction.

- Parent: copy/hash-check and safely extract the exact ZIP in the external
  delivery directory, compare extracted contents; after the human closes this
  Editor, recheck process/lock state, back up original configuration, configure
  only the local CodeDB dependency and prepare the inert C# sample.
- Human: close the Editor for configuration, reopen for import/compile and
  clean uninstalled Manager baseline; then perform the single agreed first
  Install. Report its terminal result and Ready before client provisioning.
- Parent: bind the new installation's action/result, selected instance and
  independent Ready evidence, then finalize the exact client handoff.
- Acceptance chat: confirm cwd and selected pointer, discover actual available
  project tools, call project `codedb_status` once and, if usable and correctly
  bound, project `codedb_text_search` once. Compare the result to source.
- Sample query: literal `CODEDB_S39_EXTERNAL_20261020`, limit 5,
  `regex=false`. Expected file: `Assets/CodeDBAcceptance/S39QueryProbe.cs`.
- L0: sample content/unique occurrence, expected line, SHA-256, manifest/lock
  reference resolution and selected-instance manifest hash, scoped whitespace.
- Affected L1: human Package import, one human first Install and independent
  Ready, followed by the single real-client status/query sequence above.
- Explicitly not run: Unity automation, EditMode, full regression, direct
  wrapper substitution, periodic performance tests, Uninstall/reinstall,
  physical cleanup, new Package exports, commits, uploads or publication.
- Rationale: test independent consumption of the exact existing artifact and
  real client injection without changing runtime implementation. Original
  lifecycle PASS remains separate from this new project's first-install gate.
- The configured client startup bound is 120 seconds. Honor host tool deadlines;
  do not add polling or automatic retries. A tool absence, semantic failure,
  timeout, identity mismatch or unexpected empty query result stops dependent
  calls and preserves the original result. This approved first-failure rule
  preserves one attributable client attempt; mechanical pre-dispatch command
  corrections remain allowed under the workflow.
- Normal wrapper connection may create its own lease/log state and start its
  managed dependencies. No manual runtime writes, process termination,
  registration changes, global overrides or product repair are authorized.

## Definition of done

Record actual cwd, actual tool exposure, original status and query responses,
selected identity correlation, sample hash and matching path/line/text. Report
PASS only for this project's real-client query route. Missing identity fields
must be recorded; a disk pointer alone does not prove which instance answered.
No secret-bearing full runtime-state dumps are permitted.

S38 lifecycle PASS is retained. Its periodic Checking delay remains FOLLOW-UP
unless it causes this attempt to fail. An external directory removes inheritance
from the development repository, not user/global configuration. Record actual
config sources and do not claim absence of user-global registration without
evidence. This gate covers standalone project consumption of a local delivered
artifact; public distribution/download/update, performance, cross-version
upgrade and release acceptance remain separate.

## Handoff

- Current task: S39 independent Package consumer and Codex query acceptance.
- Current status: DELIVERY_AND_HISTORICAL_RECOVERY_PASS /
  HUMAN_COMPILE_NO_ERRORS_REPORTED / HUMAN_MANAGER_READY_REPORTED /
  NEW_PACKAGE_OWNER_OBSERVED / CLIENT_ATTEMPT_02_STOPPED /
  INITIALIZE_CONNECTION_CLOSED / BOOTSTRAP_DIAGNOSTICS_SOURCE_FOCUSED_PASS /
  LOCAL_DIAGNOSTICS_CANDIDATE_CLOSURE_PASS / SAME_GENERATION_HANDOFF_NOT_ADMITTED /
  FRESH_DIAGNOSTICS_DELIVERY_PASS / CODEDBTEST_1_HUMAN_INSTALL_READY_OBSERVED /
  ATTEMPT_03_CORRECT_ROOT_INITIALIZE_CLOSED / ATTEMPT_04_ON_HOLD /
  REAL_CLIENT_QUERY_BLOCKED.
- Next notification: User.
- Next action: disposition on HOST-DIAGNOSTIC-CAPABILITY-RESULT.md. Approved
  read-only Stage 1 is complete; no complete live route admitted. Recommended
  next preparation is field/filter/permission assessment of a passive process/
  file-access tool, not installation, recording or an unchanged query retry.
  CLIENT-ATTEMPT-03-CODEDBTEST-1-RESULT.md records the correct-root failure.
  Two chats used Attempt 03; preserve
  the wrong-root and correct-root records separately by thread id. Correct-root
  target startup failed after 174 ms with initialize connection closure;
  no new attributable bootstrap record or response. Attempt 04 is on hold.
  Human first Install Ready and
  new disk identity are recorded in CODEDBTEST-1-FIRST-INSTALL-RESULT.md.
  Parent has not dispatched or executed the attempt. Earlier handoffs remain
  historical; no Install retry or registration/environment workaround.
  Passive tracing and the shim remain deferred; Attempt 02 is stopped with
  zero target calls. Do not retry old handoffs.
- Human first-Install UI gate: Ready screenshot received on 2026-10-21;
  separate explicit Console-clean report not supplied. Preserve
  CodedbTest_0. Another actual client attempt remains separately authorized.

## Bootstrap termination diagnostics — approved 2026-10-20

The user's final `同意` approves the concrete preceding diagnostic proposal:
source implementation, isolated fixtures and consolidated result only. Mode:
CONTINUOUS_WITHIN_SCOPE; current parent is Coder, no delegation or independent
Verifier. Review NORMAL, standard profile, workflow revision 2.7.

- Outcome: retain attributable wrapper termination evidence and probe child
  stderr/exit facts without changing registration, stdio transport or lifecycle.
- Allowlist: stable wrapper under `Payload~/AIWork/codedb/wrapper/`, Package
  availability probe, one focused Node harness under `Tests~/`, the narrow
  stable-entry companion-contract section, this TASK/RESULT and one diagnostics
  result. No immutable worker/generation, generated manifest or external edits.
- Record: one per connection at wrapper error or worker exit (including zero);
  startup stages remain in memory. Root must be validated before writes under
  `AIWork/.runtime/codedb/diagnostics/bootstrap/`. Bound error text, use unique
  create-only files, reject reparse ancestors, no automatic historical cleanup.
  Missing/unwritable log storage must preserve original stderr/exit behavior.
- Fields: timestamp/correlation id, wrapper PID, startup cwd, Node version/path,
  last completed wrapper stage, validated selection identity or null, worker
  exit facts and bounded error. LOCALAPPDATA presence/absolute-shape only.
  No stdout logging, environment/argument dumps, protocol parsing or handshake
  success inference. Static import failures remain a declared coverage limit.
- Consumer map: wrapper writer -> focused fixture JSON reader (diagnostic-only,
  no operational reader); probe stderr/exit -> existing evidence.detail and
  additive bounded child facts consumed by its existing PS availability reader.
- Tests: production wrapper with synthetic workers: exact stdout forwarding,
  no startup writes, error and zero/nonzero exits, selection failure, rejected
  or unavailable log path preserving primary outcome, unique records. Production
  probe failure must retain stderr/exit; success remains callable with synthetic
  backend. Syntax, scoped diff and PathProvenanceOnly are L0. No real L1 run.
- Test root: unique run-owned child of repository `.artifacts/tests/`; verify
  containment/reparse ancestry and create/read/delete before fixture execution.
  Retain output as this task's evidence; no recursive cleanup or temp fallback.
- Protected: unrelated dirty state, old evidence, delivered ZIP/package and
  CodedbTest_0 configuration/runtime. Generated manifest closure is deferred to
  separately authorized delivery; do not regenerate the pre-existing dirty
  poc.42/poc.43 state or hand-edit hashes to claim a deliverable Package.
- No Unity, Provider, real MCP, OS trace, process inventory/control, new chat,
  Install/Reinstall, commit/export/reference switch/push. Delivery grant NONE.
- Local semantic corrections bounded to two per scenario, independent causes
  two; standard active budget 30 minutes. Stop on required scope expansion.
- Done: source-focused result with exact changed files, fixture evidence,
  limitations and source hashes; no root-cause or real-client PASS claim.

Implementation/verification completed: 15 scenarios, syntax, scoped diff and
Package path provenance PASS. See BOOTSTRAP-DIAGNOSTICS-RESULT.md. All consumer,
delivery and real-client gates remain separate; no automatic next execution.

## Local delivery preparation — 2026-10-20 continuation

The user's `好 我们继续` authorizes concrete repository-local preparation and
reviewable handoff evidence after the source result, not external delivery.
Create a unique candidate below `.artifacts/tests/s39-diagnostics-delivery/`
from HEAD plus only this diagnostic delta. Recompute metadata in that copy
through the canonical writer; immutable generation/host-current bytes must stay
unchanged. Do not edit the dirty worktree's generated metadata. Verify candidate
closure and its focused diagnostics, then test the proposed same-generation
bootstrap swap using production readers in an isolated installed fixture.

Allowlist addition: task-local preparation script, delivery plan/result and
evidence; the diagnostics harness may accept an explicit enclosing repository
root to verify its extracted candidate copy under the same owned test parent.
No new production repair or relaxed reader validation is authorized. Stop the
delivery proposal if existing activation ownership cannot admit the swap.
No actual commit/export/project switch, runtime bootstrap write, process stop,
Unity, Provider, trace or real MCP attempt is included. No old delivery grant
is reused for this diagnostic source change.

Preparation complete: canonical candidate closure (60/60), candidate-own 15
diagnostic scenarios and path provenance PASS. Production activation authority
rejects direct same-generation handoff after the wrapper/runtime-contract
change. A separate fresh synthetic Install commits and its readers admit it.
See DIAGNOSTICS-DELIVERY-PREPARATION-RESULT.md. Recommended route: retain the
original project and use CodedbTest_1 after authorized exact delivery. No
validator relaxation, external write, staging, commit or formal export occurred.

## Deferred Manager Unconfirmed observation — 2026-10-21

The user reports Ready -> brief Unconfirmed checking -> Ready after first
Install and explicitly requests recording only, with investigation scheduled
separately later. Independent FOLLOW-UP card:
`../cdb-manager-ready-unconfirmed-followup/TASK.md`. No reproduction, diagnosis
or fix is started; this record does not change the pending Attempt 03 gate.

Native stderr route checkpoint (2026-10-21): bounded static `app.asar` reading
shows the host StdioConnection attaches child stderr, stores the latest message
and forwards it as a close reason. Exact-thread desktop/SQLite records still
contain only generic initialize closure and no target stderr. Thus host-side
stderr reading exists, but retrospective persistence/access is unproven. No
logging override, restart, retry or runtime change; next step is alignment on a
supported host control/sink only.

Public CLI logging-control check (2026-10-21): installed help for the top-level
CLI, app-server, daemon, debug app-server, doctor and mcp exposes no supported
MCP stderr export, retention, log-level or file-routing switch. Daemon lifecycle
commands were not run. No hidden `-c` key or guessed `RUST_LOG` is admitted.

Baseline correction: v0.2 is not a valid A/B control for this target. Its Git
and strict initialization prerequisites cannot complete in the current test
environment and are part of the reason for upgrading to v0.3. Do not attribute
the current v0.3 initialize closure by switching to v0.2. Continue with a
v0.3-only startup-contract diagnosis under the existing CodedbTest_1 binding.

Prepared `CLIENT-CODEDBTEST-1-SELF-CHECK-HANDOFF.md` for a fresh target-root
session. It is read-only, makes zero CodeDB calls and forbids wrapper/process
launch, retry or configuration changes. The parent has not dispatched or
messaged the target session; the user may send the embedded instruction.

The target session returned its self-check: project cwd/config/manifest/lock,
Package, Node v24.14.1 path, pointer/instance and wrapper hash all matched;
target namespace absent; zero CodeDB calls; no logs or wrapper execution. This
closes the read-only project-context check. Continue only with host startup
boundary evidence; do not repeat self-check or query attempts.

Process observation 01 was explicitly authorized but stopped on provider-enable
access denied. A partially created owned ETW session was discovered and stopped;
absence confirmed, zero process-provider events and no target trigger. Actual
partial-file timestamps span about 62 seconds, exceeding the intended bound.
See PROCESS-OBSERVATION-01-RESULT.md and corrected receipt. Observer cleanup was
repaired and mocked checks passed; no real retry. Administrator-only recorder
handoff is prepared, not run, and needs a new observation authorization.

Observation 02 is now explicitly authorized by the user's subsequent
`同意授权`. A prefilled machine-local launcher is prepared for the independent
administrator PowerShell; see PROCESS-OBSERVATION-ADMIN-HANDOFF.md. Status:
AWAITING_HUMAN_ADMIN_TERMINAL / NOT_STARTED. Grant is one window and one normal
human-created target chat, not a retry loop. No permission request is repeated.

Observation 02 subsequently stopped before ETW create: initial query returned
0x80300002 but the observer's English-text condition rejected it. No session or
ETL exists. See PROCESS-OBSERVATION-02-RESULT.md. Numeric preflight/cleanup checks
and initial-query receipt retention are repaired; four mocked cases passed on
each of Windows PowerShell 5.1 and PowerShell 7 with zero real ETW calls.
Observation 03 has a new launcher/output identity prepared, not authorized or
run. No target chat should be triggered before its OBSERVER_READY.

The user's subsequent `同意授权` authorizes observation 03 using the corrected
launcher, one independent administrator-recorder window and one human-created
normal CodedbTest_1 chat. Status: AUTHORIZED_AWAITING_HUMAN_LAUNCH. No ETW start,
target trigger or additional retry has been performed by the development session.

Observation 03 completed by the human. Ready-to-end interval 7.6860557 seconds;
create/stop success and session absence verified; ETW reports zero lost events,
29 starts and 13 stops. Target chat/host failure identified by exact thread id.
Node PID 70836 (Codex app-server parent, expected image path) exited code 1 after
227.8245 ms, 1.2267 ms before the target host failure. Another same-image Node
child means target PID is still a correlated candidate, not proven. Inputs
unchanged, zero CodeDB calls, no stderr/new bootstrap record. See
PROCESS-OBSERVATION-03-RESULT.md. The window is closed; no rerun authorized.

Command-line route read-only assessment is complete; see
COMMANDLINE-TRACE-ASSESSMENT.md. A different native process event family
advertises full argv; it cannot enrich the existing ETL or supply cwd/stderr.
Prefer assessing a uniquely owned native system session over assuming WPR
instance-name isolation. Actual argv delivery remains untested. Raw scope can
include other running processes and their command lines at start/end, exceeding
observation 03's metadata scope. Capture is DEFERRED pending explicit scope;
no new controller, recording, target startup or query was executed.

The subsequent user continuation authorizes observer preparation/offline checks.
The separate native command-line observer, read-only XML summarizer and pinned
one-run launcher are now prepared. Each supported PowerShell host passed 24
offline cases with zero native ETW calls; see
COMMANDLINE-OBSERVER-PREPARATION-RESULT.md. Live process observation 04 and its
broader raw-command-line scope remain NOT_AUTHORIZED; see
COMMANDLINE-OBSERVATION-04-HANDOFF.md. No target startup/query, real recording,
Package/config/environment change or previous-observer edit occurred.

User subsequently explicitly authorized process observation 04 and the stated
system-wide full-command-line/rundown scope. Status:
AUTHORIZED_AWAITING_HUMAN_ADMINISTRATOR_LAUNCH. Four pinned source hashes
match; live run directory remains absent. Human launch and one normal target
chat after OBSERVER_READY are authorized without another confirmation. No
recorder, target startup or query was executed by this development session.

Process observation 04 is now COMPLETE / DO_NOT_RERUN. Human receipt and exact
target chat are verified; native elapsed 6.8837564 seconds, ETL 4.25 MiB,
zero reported loss and owned-session absence independently confirmed. Captured
PIDs bind to expected Node/relative wrapper/root argv and exit code 1. Host
records distinguish the target's first/later refresh startup and another host
thread. Cwd/resolved entry and primary stderr remain missing; root cause open.
Actual native raw trace additionally includes 539 automatic SystemConfig
metadata events, exceeding the process-only expectation. See
PROCESS-OBSERVATION-04-RESULT.md for scope and decoder caveats. No manual
retry, target CodeDB call, repair/config switch or new window occurred. Stop
unchanged capture attempts; next useful work is existing static cwd/entry/import
resolution evidence. Query acceptance Attempt 04 remains ON_HOLD.

User authorized cwd/import static analysis. See
CWD-AND-IMPORT-STATIC-ANALYSIS.md. Confirmed coverage gap: registration tests
require literal cwd="." while the install probe forces projectRoot cwd and
resolved entry, so neither proves actual Codex path-base behavior. Current
official general project-config docs use .codex as relative base, but MCP's
legacy string cwd and exact installed native resolver remain unverified; do
not declare cwd=.codex or change to ".." from this evidence. Six current
closure files and relative imports match delivery and manifest hashes. No
missing helper or byte mismatch found. Root cause still open, no new test/run,
source/consumer config change or fix authorized. Any cwd experiment needs its
own bounded backup/restore/refresh scope; portable product changes must align
generator, validator and real host coverage.

User subsequently agreed to the bounded single-variable absolute-cwd experiment.
See CWD-EXPERIMENT-01-HANDOFF.md and CWD-EXPERIMENT-01-RESULT.md. Exact original
config and candidate are retained; only target cwd was replaced and verified
at 2026-10-21T06:25:17Z. Four protected input hashes match. State:
APPLIED_AWAITING_HUMAN_CHAT / RESTORE_PENDING. A helper preparation fault was
corrected before the first actual config replacement; no target startup test
was retried. Human owns one normal target chat; CodeDB calls remain zero.
Close target observation before guarded restoration; restoration refresh is
outside outcome. No product fix or query acceptance is authorized by this run.

Cwd experiment 01 is COMPLETE / ORIGINAL_BYTES_RESTORED / DO_NOT_RERUN.
The one human-created target chat `01a15d25-ef86-7c31-82c6-641fb3d664c0`,
title `观测 MCP 启动状态`, was independently read: correct cwd, six exact-namespace
tools reported visible, zero CodeDB calls, completed/idle. This positive
visibility change supports the relative-cwd compatibility direction, without
proving failed historical cwd or fresh initialize/response identity. Bounded
runtime logs contain only a cached-catalog row belonging to another thread;
no directly attributable target initialize record was obtained. Bootstrap is
unchanged. Observation closed before guarded restore at 06:32:50Z; original
config hash and four protected inputs match. See CWD-EXPERIMENT-01-RESULT.md.
No runtime retry, query, source fix or additional experiment authorized.

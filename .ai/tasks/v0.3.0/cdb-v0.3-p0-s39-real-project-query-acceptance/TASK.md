# S39 independent Package consumer and Codex query acceptance

Date: 2026-10-20.

## Metadata

- Product/version: UnityCodeDB v0.3.0, preview.5.
- Workflow: codedb-workflow-v2, revision 2.7.
- Status: PARTIAL / FIRST_INSTALL_READY_PASS / REAL_CLIENT_QUERY_BLOCKED.
- Planner/Coder: current parent; independent Verifier: not requested.
- Review mode: NORMAL; execution mode: DURABLE_SESSION.
- Delegation authorization: NOT_AUTHORIZED; session policy: MANUAL_PROVISION.
- Requirement source: roadmap P0 Project-local Codex MCP Discovery and
  `Documentation~/v0.3.0-p0-codex-client-discovery.md`.

## Objective

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
  REAL_CLIENT_QUERY_BLOCKED.
- Next notification: User.
- Next action: execute the human-approved DIAGNOSTICS-DELIVERY-PLAN.md grants
  A/B, then stop at the human Unity gate. CodedbTest_1 is human-created/closed
  and its read-only preflight is complete. The human explicitly replied
  `批准` to this exact commit/delivery/project-preparation sequence.
  Same-generation wrapper swap is not admitted.
  Passive tracing and the shim remain deferred; Attempt 02 is stopped with
  zero target calls. Do not retry old handoffs.
- Human gate after authorized delivery/preparation: open CodedbTest_1 for
  compilation and one human first Install. Preserve
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

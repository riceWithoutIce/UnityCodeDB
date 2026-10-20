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
- Current status: PARTIAL / SOURCE_FOCUSED_PASS / REAL_CLIENT_QUERY_BLOCKED.
- Next notification: User.
- Next action: execute the explicitly authorized commit/export/reference-switch
  and single-module recovery sequence in DELIVERY-RECOVERY-PLAN.md. The user
  approved this sequence and confirmed CodedbTest_0 is closed on 2026-10-20.
- Human gate after delivery: open CodedbTest_0 for compilation and Manager
  observation. Another external client attempt remains separate; do not reuse
  CLIENT-HANDOFF.md as a retry grant.

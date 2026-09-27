# Task: cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0 preview
- Workflow: codedb-workflow-v2, revision 2.3
- Status: FIX_01_SOURCE_READY / COMMIT_EXPORT_PENDING
- Planner: UnityCodeDB v0.3 Planner
- Coder: not dispatched; source correction requires a stable finding and route decision
- Verifier: independent RELEASE review after a stable artifact and acceptance record
- Review mode: RELEASE
- Execution mode: DURABLE_SESSION (human Unity handoffs)
- Delegation authorization: NOT_AUTHORIZED for this external acceptance task
- Requirement source: `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`
  and `com.rice.ai-codedb/Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md`

## Objective

Take the user-accepted S24 source route through one attributable local Package
and one human-owned `UnityValidationProject` acceptance: compile and focused
EditMode, then authenticated project integration removal to
`UNINSTALLED / PENDING`, followed by fresh current-Package Install. This is one
continuous recovery outcome, not a set of per-error micro-tasks.

## Input And Protected State

- S24 accepted source base HEAD: `5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`.
- Accepted seven-path binary diff identity:
  `dd24b129403581169bcd3a286f78faa84f6f2868`.
- S24 `RESULT.md` and `verifications/VERIFICATION-01.md` / `VERIFICATION-02.md`
  preserve the original P1 and its closed FIX 01.
- The validation project currently points to the S23 local Package in
  `UnityValidationProject/Packages/manifest.json`; that Package is not S24
  acceptance evidence.
- Existing dirty/untracked work, previous artifacts, historical instances,
  immutable generations, user files, unrelated MCP entries, machine Provider,
  external clients, and real consumer projects are protected.
- Use repository-relative paths in task records and artifact references. Never
  publish machine-specific project roots or user-profile paths.

## Continuous Gates

### A. Source Attribution And Package Closure

- Read-only first: attribute the accepted S24 seven-path patch and directly
  coupled dirty source/test paths. In particular, inspect whether existing
  `AICodedbActions.cs`, `AICodedbControlContract.cs`, or lifecycle test changes
  are required for a compiling, attributable Package. Do not silently stage
  an entire dirty file or discard inherited work.
- Freeze the exact source/test and task-record commit scope. If the accepted
  identity does not form a coherent Package without unrelated bytes, stop for
  route reassessment; do not manufacture a passing artifact.
- The user authorized the exact 19-path Gate A commit after source closure
  reconciliation. A second separate authorization is required to export a
  new local Package from that commit. Apply the Package Identity Authority and Package Release Closure
  Gates to the extracted, single-root artifact, including every declared
  payload file/hash, generation/current pointer, runtime target, and ZIP bytes.
- Preserve the S23 artifact. No version/generation rewrite, manual hash edit,
  tag, push, or publication is included. A required new identity transition
  stops this gate for design review.

### B. Human Unity Compile And Focused EditMode

- Only after Gate A passes, and while the human confirms Unity is closed,
  explicitly authorize the validation-project maintenance change that switches
  only the CodeDB dependency in
  `UnityValidationProject/Packages/manifest.json` to the new relative artifact.
  Inspect the existing dirty manifest before changing it; preserve other
  entries and the tracked lockfile/project settings unless separately scoped.
- Human selects and visibly opens the existing `UnityValidationProject` with
  its declared Unity 2022.3 compatibility line. No agent-launched hidden Unity,
  BatchMode, Unity MCP substitution, or alternate project.
- Observe Package import and C# compilation. Require zero CodeDB C# errors.
  Then run one explicitly authorized focused EditMode boundary for the directly
  affected Manager/lifecycle tests, with the exact filter/command and attempt
  budget recorded before execution. Do not infer EditMode PASS from compile.
- Stop at the first product compile or EditMode failure. Preserve exact output;
  do not patch the consumed artifact in place.

### C. Human Project Integration Golden Path

- After Gate B passes, inspect Manager's stable state and the independent
  removal preflight without mutation. If ownership is blocked or ambiguous,
  stop and report the reason; do not delete runtime files manually.
- A separate explicit human confirmation is required before the real removal
  action. Run only the offered, authenticated project-integration route once.
  Verify the visible `Uninstalled` result and technical
  `UNINSTALLED / PENDING` evidence: no active selection or managed project MCP
  registration, durable removal intent, and old instance/index/generation
  closure retained byte-exact and inert. `PENDING` is valid; do not force
  physical cleanup or stop a holder.
- Only after that terminal state is proved, separately confirm one fresh
  `Install CodeDB`. Require a new current-Package instance and committed
  activation, restored project MCP configuration bound to the new instance,
  stable Manager `Ready`, and one bounded status/query check. Old activation,
  instance, index and intent must not be adopted or rewritten.
- Prefer one visible Unity session for B and C. Allow at most one controlled
  client reconnect/new task only if project MCP configuration is not reloaded
  dynamically; never require repeated Codex rebinding as the normal route.
- Stop at the first independent product failure. No automatic retries,
  process termination, hidden probes, third-party consumer test, Play/Edit
  full lifecycle, or release claim is included.

## Evidence And Completion

- Gate A records exact commit/path identity and extracted artifact closure.
- Gate B records human-visible compile result and executed focused EditMode
  results separately. The Unity request must declare the exact project path
  resolved from the repository root, Editor compatibility, filter/command,
  wait ceiling, attempt count, and human cleanup owner before it starts.
- Gate C records user action, visible result, and separate technical evidence
  at each removal/install transition. Do not ask the user to read hashes,
  leases, or internal JSON as the ordinary acceptance procedure.
- A RELEASE Verifier reviews the stable artifact identity and declared
  acceptance claims after the human scenario; it does not rerun Unity or
  contact Coder. Runtime isolation, third-party consumer, full regression,
  push and publication remain separate gates.

## Handoff

- Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
- Current status: FIX_01_SOURCE_READY / COMMIT_EXPORT_PENDING
- Next notification: UnityCodeDB v0.3 Planner/User
- Next action: commit the two-file FIX 01 source/test correction with S25
  records, export a new commit-derived local Package, and switch only the
  validation project's CodeDB manifest entry while Unity remains closed.
  Preserve the failed artifact. Unity compile remains unverified until the
  human visibly opens the new Package.
- Human decision or authorization required: human Unity compile/EditMode,
  real removal, fresh Install, Verifier routing, push, and publication.

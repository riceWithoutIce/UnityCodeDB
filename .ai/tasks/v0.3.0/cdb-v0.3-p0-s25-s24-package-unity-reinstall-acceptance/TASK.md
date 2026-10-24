# Task: cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0 preview
- Workflow: codedb-workflow-v2, revision 2.3
- Status: GATE_C_BLOCKED / INSTALL_OUTCOME_UNKNOWN / S28_PHASE_A_REVIEW_PENDING
- Planner: UnityCodeDB v0.3 Planner
- Coder: S28 Phase A source snapshot returned; legacy mutation proof unresolved
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
- Current status: GATE_C_BLOCKED / INSTALL_OUTCOME_UNKNOWN / S28_PHASE_A_REVIEW_PENDING
- Next notification: UnityCodeDB v0.3 Planner/User
- Next action: decide S28 Phase A's frozen targeted source review;
  new project changes remain refused until the legacy proof is sufficient.
  No new Install click or Unity open/close cycle is requested.
- Human decision or authorization required: later source review/disposition
  and real S25 acceptance; commit/export,
  Package switch, push, and publication retain their separate gates.

---

## Current Route Overlay - 2026-09-29

S26 is accepted and committed at
`1be11d911c05db4b7752122bf761e61fac47ef3c`. The prior S25 artifact and its
consumed/unconfirmed real Remove attempt remain historical evidence and must
not be replayed.

Gate A now uses one new artifact derived from that exact commit:

- Package root:
  `.artifacts/v0.3.0-preview.5-s26-host-action-1be11d-final/package/com.rice.ai-codedb`
- ZIP:
  `.artifacts/v0.3.0-preview.5-s26-host-action-1be11d-final/com.rice.ai-codedb.zip`
- ZIP SHA-256:
  `1fb85dc9bcca8405d688c487e1def6d2ebfe75fd17979f06dfdebfb93d0884c5`
- Closure: `source_count=46`, `files=482`, `bytes=9864772`,
  `zip_entries=482`, `mismatch_count=0` in both staged and exact-ZIP checks.
- Cross-hashes: generation
  `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`,
  host-current
  `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`,
  runtime contract
  `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`.

The canonical exporter and package-release-closure validator both passed.
Prior artifacts were preserved; no artifact was patched in place. Current
status is `GATE_A_PACKAGE_CLOSURE_PASS / GATE_B_AUTHORIZATION_PENDING`.
Gate B requires a separate authorization while Unity is closed to switch only
the validation project's CodeDB dependency to this artifact, followed by human
compile and the predeclared focused EditMode selections. No Remove or Install
is authorized by this route overlay.

---

## Current Gate C Overlay - Historical Unknown Action

The latest S25 `RESULT.md` read-only diagnosis remains
`BLOCKED / PRIOR_ACTION_CLAIM_WITHOUT_TERMINAL`. The old Remove has an
authenticated admission and writer claim but no command terminal or proved
pre-effect refusal. The S26 Package does not erase that uncertainty. The
historical-action reconciliation amendment in the Host Action Execution
Contract and the single S27 task govern any source route from here.

Do not click Remove or Install, replay the old action, synthesize a receipt,
or manually clear its evidence. S25 Gate C resumes only after the exact old
action is reconciled under the frozen proof and a separate human authorization
is given for the next real project mutation.

---

## Current Candidate Overlay - 2026-09-30

The old S25 Remove uncertainty was reconciled by accepted S27 evidence; a
subsequent authorized fresh Remove reached authenticated `UNINSTALLED /
PENDING`. The visible Gate C Install action was then blocked by Editor-lease
admission before the uninstalled-state branch. The lifecycle ordering fix and
Package path-provenance rule are committed at
`a02a68c45362bb7ca60e846bacbd101c4498979f` (ten-path patch identity
`3bf457c7370bfe25cea078955261baec9f83be2f`).

Candidate Package:

- Root: `.artifacts/v0.3.0-preview.5-s25-install-admission-a02a68c-candidate/package/com.rice.ai-codedb`
- ZIP: `.artifacts/v0.3.0-preview.5-s25-install-admission-a02a68c-candidate/com.rice.ai-codedb.zip`
- ZIP SHA-256: `7717eca61ce0c53f92621c766a8279de1ecbeceae4731931fe7cc1c41cba7bbd`
- Closure: commit-staged and exact-ZIP `source_count=46`, `mismatch_count=0`;
  `files=482`, `zip_entries=482`.
- Full Package-boundary: PASS on the exported Package.

Only the CodeDB dependency in `UnityValidationProject/Packages/manifest.json`
now points to this candidate. The validation project has not been opened for
this candidate; C# compile, EditMode, Manager visibility, fresh Install,
status/query, and RELEASE Verifier remain NOT RUN.

Human Gate B/C observation in one visible Unity session:

1. Open `UnityValidationProject` and wait for Package import/compilation to
   settle. Report the CodeDB C# error count; stop if nonzero.
2. Run `AICodedbLifecycleControlTests` and the directly new
   `CurrentUninstalledPendingState_ExposesInstallWithoutEditorLease` and
   `LifecycleSource_UninstalledStatePrecedesEditorLeaseRejection` tests. Also
   rerun `ControlContractMigration_PartialV1RequiresBoundCommittedEvidence`
   for the new artifact. Report each result; stop on failure.
3. Open CodeDB Manager and report the settled Overview and whether
   `Install CodeDB` is offered. Do not click Install, Remove, or another
   recovery action until the result is reviewed and the mutation is
   separately authorized.

---

## Current Gate C Route Overlay - 2026-10-01

This overlay supersedes earlier next-action instructions. The original Remove
was reconciled with its command outcome retained as unknown; fresh Remove
subsequently reached authenticated `UNINSTALLED / PENDING`. A later Install
has admission and claim without terminal evidence. Keep that Install result
unknown and do not click Install again or run S27's old Remove-only proof.

User agreed the bounded `REDESIGN` in `ROUTE-REASSESSMENT.md` and the Host
Action `Status, History, And Change Admission Amendment`. The continuous
implementation packet is
`../cdb-v0.3-p0-s28-manager-history-status-change-admission/TASK.md`.
S28 owns source and focused synthetic evidence; S25 retains the real-project
Package/Unity acceptance. Its source gate does not prove current Manager
Ready, authorize a runtime edit, or certify the old Install outcome.

Current source is HEAD `aaea58a0262c99a7901b39a8309e94b126111b00`.
The receipt-fix candidate and protected project state are recorded in
`ROUTE-REASSESSMENT.md`. Leave the current Package binding and human-owned
Editor session in place. No additional Unity open/close cycle or mutation is
requested during S28 preparation. Next action is the concrete S28 source
result and targeted review. User authorized the complete frozen source
envelope on `2026-10-01`; dispatch to the existing `v0.3.coder.deep` succeeded.
After its source-only proof stop, the user approved same-task status-first
ordering. S28 Phase A implements history/status while preserving new-mutation
refusal; Phase B legacy process-proof/recovery remains unresolved. Partial
source progress does not close S25 or authenticate the old Install result.

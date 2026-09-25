# Task: cdb-v0.3-p0-s23-s22-accepted-commit-package-unity-golden-path

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Workflow: codedb-workflow-v2
- Workflow revision: 2.3
- Status: FROZEN / READY_FOR_COMMIT_GATE
- Planner: UnityCodeDB v0.3 Planner
- Coder: optional bounded child under STANDING_WORKFLOW
- Verifier: optional after stable commit-derived evidence
- Review mode: RELEASE
- Execution mode: CONTINUOUS_WITHIN_SCOPE
- Execution profile: v0.3.coder.standard
- Delegation authorization: STANDING_WORKFLOW
- Session policy: SPAWN_BOUNDED
- Requirement source: accepted S22 FIX 02 source snapshot and
  `VERIFICATION-05.md`

## Objective

Move the accepted S22 Host Action Execution Contract source snapshot through
one continuous release-to-human gate: exact scoped commit, commit-derived
Package closure, and one visible `UnityValidationProject` golden path.

## Frozen Input

- Branch: `codex/v0.3.0-legacy-workflow`
- HEAD before commit: `6b64f27adb51eeab8394aac6bca722117ac6863c`
- Accepted S22 tracked 13-path diff blob:
  `15c9c267d03744eb47a6e2be5c408875728a8e17`
- Accepted S22 writer blob:
  `1072cb06b529fc47271c51a39025076252c5ab1e`
- Accepted S22 composite identity:
  `1a70e5814cec924e42edd40977227ec8413ac77a5ebf131d45ffeebbf824e003`
- Verifier report:
  `cdb-v0.3-p0-s22-host-action-execution-contract/verifications/VERIFICATION-05.md`
- Validation project: `UnityValidationProject`

The S22 snapshot is accepted source evidence, not yet a commit-derived
Package and not a Unity runtime result.

## Continuous Phases

### Phase A - Exact Commit Gate

- Stage only the frozen S22 source allowlist and the explicitly approved S22
  evidence records needed for traceability.
- Preserve all unrelated dirty files, S18/S19/S21 work, artifacts, and
  validation-project changes outside the commit.
- Verify staged path list, commit identity, and post-commit status before
  export. No push or tag is included.

### Phase B - Commit-Derived Package Closure

- Export one local Package from the Phase A commit into a new relative
  `.artifacts/` directory.
- Run the canonical Package boundary/release-closure validators against the
  commit and extracted single-root Package.
- Record Package version, source count, generation/pointer/runtime hashes,
  ZIP identity, and extracted closure. A failed or partial artifact is never
  used for Unity.

### Phase C - Human-Owned Unity Golden Path

- After Phase B closure PASS, update only the repository-relative
  `UnityValidationProject/Packages/manifest.json` reference to the new local
  Package, with the project closed before the change.
- Human opens the project visibly and waits for import/compile completion.
- Confirm zero CodeDB Package/C# errors and record unrelated warnings
  separately.
- Open CodeDB Manager and record the stable terminal state and Host Action
  terminal receipt. If an action is offered, click it once and stop at the
  first product failure.
- If Ready, switch Manager tabs, enter/exit Play once, confirm checking does
  not loop, and close Unity normally within the bounded shutdown window.

## Scope And Boundaries

- Commit source allowlist: the exact 13 tracked S22 paths declared in
  `cdb-v0.3-p0-s22-host-action-execution-contract/ROUTE-REASSESSMENT.md`
  plus the Package-owned
  `Tools~/invoke-codedb-manager-action.ps1` writer at the accepted bytes.
- S22 task records may be included only when explicitly named in the Phase A
  commit plan; no unrelated task, roadmap, workflow, artifact, or project
  files may be staged.
- Package export/closure scripts and the new artifact directory are local
  release evidence only; do not delete or replace older artifacts.
- Unity start, UI interaction, Play/Edit transition, and shutdown are
  human-owned. Do not launch hidden/background Unity, Unity MCP, BatchMode,
  process probes, alternate endpoints, or automatic retries.
- Do not clean instances, stop processes, reinstall Provider, repair runtime
  state, or mutate external projects without a new cause-specific task.
- Stop at the first independent commit, closure, or Unity product failure;
  preserve exact output and route reassessment instead of patching in place.

## Evidence Envelope

- Phase A: exact staged path check, commit hash, post-commit status, and
  accepted S22 identity comparison.
- Phase B: canonical source/payload/generation/pointer/runtime closure,
  extracted single-root validation, ZIP hash, and artifact path.
- Phase C: human screenshots/observations for import, Manager terminal state,
  action result, Ready/tab/Play/Edit behavior when reachable, and shutdown.
- No automatic full regression. C# semantic compile/EditMode beyond the normal
  Unity import gate, third-party consumers, publication, tag, and push remain
  deferred.

## Authorization Gates

- This task card freezes the route only; it does not authorize commit, export,
  Package replacement, Unity opening, or publication.
- Phase A commit requires a separate explicit human authorization naming the
  exact staged paths.
- Phase B export requires the Phase A commit and separate explicit approval.
- Phase C requires a valid commit-derived closure artifact and explicit human
  approval to update/open `UnityValidationProject`.
- Verifier routing is read-only and may review only the stable Phase A/B
  identity and declared closure evidence; it cannot approve Unity or release
  gates by inference.

## Definition Of Done

- A commit contains only the accepted S22 snapshot and explicitly approved
  records.
- One commit-derived local Package passes canonical closure validation with
  exact identity recorded.
- One human-owned Unity golden path reaches a stable terminal result or
  records the first exact product blocker without retries or hidden probes.
- All deferred gates and unrelated dirty state remain explicitly recorded.

## Handoff

- Current task: `cdb-v0.3-p0-s23-s22-accepted-commit-package-unity-golden-path`
- Current status: `FROZEN / READY_FOR_COMMIT_GATE`
- Next notification: UnityCodeDB v0.3 Planner
- Next action: review the frozen scope and request explicit Phase A commit
  authorization; do not dispatch or open Unity before that authorization.
- Human decision or authorization required: exact commit scope, export,
  UnityValidationProject update/open, Verifier routing, push, and publication.

## Phase C Addendum - Historical Supervisor Event Stream

The original handoff above records the initial S23 gate. After the human
compile passed, Manager reached a separate partial Owner Identity v1 control
blocker: the historical Supervisor event file contains multiple process
sessions whose sequence numbers each begin at one. The human approved one
continuous, same-S23 contract correction rather than separate micro-tasks.

- Treat the v1 append-only event file as session segments. Every reset must
  be a `supervisor_started` event with sequence one; each segment must be
  contiguous and timestamp-ordered. A previous segment may end abruptly.
- Only the final segment can corroborate the failed `operation.json` record.
  Require one unambiguous start/failure pair matching its name and UTC
  operation window, with no interleaved or later operation event. Historical
  same-name failures never confer authority.
- Keep all existing project/instance/activation bindings, holder checks,
  evidence fingerprints, and pre-mutation revalidation. Do not rewrite,
  truncate, or delete the historical event stream to make admission pass.
- Scope source/test changes to the Editor v1 reader, Package materializer v1
  removal reader, their adjacent tests, and the existing synthetic Supervisor
  restart test. Validate focused PowerShell and Node scenarios, C# syntax,
  and scoped diff. Unity compile/EditMode remains a separate human gate.
- After the stable source gate, form one exact commit-derived Package in a
  new relative `.artifacts/` directory, run both closure validators, then
  update only the repository-relative validation-project Package reference
  while Unity is closed. No push, tag, publication, process cleanup, Provider
  mutation, or real RemoveIntegration is authorized by this addendum.

# Task: cdb-v0.3-p0-s30-current-version-lifecycle-acceptance

## Metadata

- Product/version: UnityCodeDB `0.3.0-preview.5`; exact source `5b52c017e8415bb061f33a8380b3dcec2916411a`.
- Workflow: `codedb-workflow-v2`, revision `2.6`, including the 2026-10-15 acceptance-project amendment.
- Status: SOURCE_ACCEPTED / DELIVERY_REFERENCE_SWITCHED / HUMAN_REOPEN_BLOCKED — on reopening S30, the prior Package Supervisor remained alive and the new Package rejected its script-path identity; human confirms uninstall was not invoked and its entry remains absent. Dependent uninstall/reinstall are paused.
- Planner: current parent agent. Coder: existing historical_handoff_coder; Verifier: existing historical_handoff_verifier, read-only after stable Coder completion.
- Review mode: GUARDED for the source repair; lifecycle acceptance, not release promotion.
- Execution mode: DURABLE_SESSION / REUSE_ONLY; current parent coordinates human acceptance, no new session.
- Execution profile: no Coder profile activated for this planning/human-acceptance stage.
- Delegation authorization: TASK_SPECIFIC, user explicitly approved existing Coder → Verifier reuse for this bounded repair. No new session or further child delegation.
- Requirement source: [current roadmap disposition](../../../../com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md#current-disposition--2026-10-15), [workflow](../../../../com.rice.ai-codedb/Documentation~/development-workflow.md#acceptance-project-baseline-and-historical-recovery), and user's approval to continue current-version lifecycle planning.

## Objective

Prove one current-version lifecycle from a new, attributable project baseline:
first Install → Ready and usable status/query → Remove Integration →
Uninstalled → Install → Ready and usable status/query.

## Frozen inputs and proposed target

- Existing accepted ZIP: `<repository-root>/.artifacts/s29-removal-history-authority-5b52c01/com.rice.ai-codedb.zip`.
- ZIP SHA256: `7e39a1ab41fbe5da5417cc73557ec8e7f4bc5837a52180ed40caaace35183d32`.
- Independent S30 extraction, prepared from that ZIP without re-export:
  `<repository-root>/.artifacts/s30-current-version-lifecycle-5b52c01/review/com.rice.ai-codedb`.
- Package `0.3.0-preview.5`; target Host generation `poc.43`.
- Human-created project: `<repository-root>/UnityFreshLifecycleValidationProjectS30`.
  For this checkout: `G:/RiceProgram/UnityCodeDB/UnityFreshLifecycleValidationProjectS30`.
  Initially absent; user subsequently reported creation. Read-only inspection confirms a Unity project at this exact path; do not recreate or overwrite it.
- Editor compatibility: LINE, Unity `2022.3`; the human-created project's metadata records `2022.3.62f3 (96770f904ca7)`. The human retains Editor ownership; no automated selection or launch is authorized.
- No S29 Assets, configuration, Library, AIWork, runtime histories or installed instance is copied into the new project.

## Scope

- In scope: minimal new-project preparation after authorization, exact local Package reference, human lifecycle acceptance and directly attributable read-only evidence.
- Planning change allowlist: this task's `TASK.md` and `RESULT.md`, and the roadmap's current-route pointer.
- Authorized operational allowlist: new project's `Packages/manifest.json` and `Packages/packages-lock.json` for the exact Package reference; normal Unity import and CodeDB-owned project integration/runtime effects of the human-operated Install/Remove actions; initial Package backups under `.backups/s30-current-version-lifecycle-5b52c01/`; task-owned logs under `.artifacts/delivery/s30-current-version-lifecycle-5b52c01/`.
- Read-only dependency closure: exact Package's manifest, Manager/lifecycle evidence and availability probe; current responsibility/reinstall contracts; this task and its direct predecessor delivery identity records.
- Protected: all old validation projects, S29 history and artifacts, existing dirty source/Payload, machine Provider identity/configuration, external clients/processes and unrelated shared resources.
- Out of scope: historical recovery, cross-version replacement, physical cleanup, full regression, performance/corpus validation and release acceptance. Source repair is now limited to the packet below.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE.
- Initial grant: user `ok 我们继续` following the normal-lifecycle proposal authorized planning and reversible task-owned preparation. No new-project lifecycle grant is inferred from S29 grants.
- Subsequent user report: `UnityFreshLifecycleValidationProjectS30 已经创建`. Creation is human-reported and the baseline is read-only verified; this is not recorded as approval of all remaining operations.
- Delivery authorization: no commit, push, package export or publication. Original ZIP may be read and extracted to a new task-owned location; never replace the original.
- Combined risk-boundary grant: user `同意授权` in response to the explicit remaining-flow request authorizes configuring the existing new project's exact Package reference while the Editor is closed; human opens/closes it and performs first Install, Remove Integration and reinstall in order; parent gathers bounded read-only evidence and runs the Package-owned availability probe after each Ready checkpoint. Any failed checkpoint stops dependent steps.
- Unity ownership: human, using Unity Hub/Editor; no agent launch, MCP, CUA or BatchMode substitution.
- The combined grant is recorded. Continue its contained stages without repeated approval; wait for required human evidence before dependent operations.

### Acceptance sequence after authorization

1. COMPLETE: human creation and baseline check; initial manifest/lock backed up with matching hashes; exact S30 Package configured while no matching Unity process or UnityLockfile was observed. Of 27 baseline Assets/Packages/ProjectSettings files, only manifest and lock changed. No integration history was created manually. See RESULT.md for before/after identities.
2. Human opens/imports the project and checks compilation and Manager. Observe any automatic preparation as part of the first-install behavior. Use the offered supported Install action only when applicable; do not bypass missing buttons or backend refusal with direct mutation scripts.
3. COMPLETE: user reported Ready with screenshot; first Install terminal exit 0 / 17022 ms / INSTANCE_ACTIVATED, selected instance and committed activation bind the exact poc.43 manifests. Parent's fresh Package-owned probe passed initialization, exact tool list, usable `codedb_status` and bounded `codedb_text_search`. See RESULT.md. This is availability evidence, not corpus correctness or real Codex Desktop acceptance.
4. NEXT: human confirms logical removal through the Manager's supported current-state action. For a normal Ready installation its overflow-menu label is `Uninstall CodeDB from Project`; `Remove CodeDB Integration` is the alternate RequiresReinstall-state action, not a required button in this Ready state. Verify authenticated logical `UNINSTALLED` and inactive integration before proceeding. Physical cleanup may remain Pending only when the existing product contract admits it; do not manually delete remnants to make reinstall pass. UPM Package removal is not the action under test. If neither supported action is available, report the UI/refusal and stop rather than bypassing it.
5. Only after removal passes, human performs the offered Install. Verify a new attributable installation/activation targeting the same frozen Package/Host, Ready and the same availability criteria.
6. Human checks Manager close/reopen and tabs and closes Unity normally. Record shutdown behavior; prior CleanupMono observation remains deferred unless new evidence establishes a different in-scope product cause. Parent performs the directly scoped final read-only attribution.

- L0 preparation: original ZIP identity, exact extracted-byte closure, target nonexistence and documentation links.
- Affected L1: the declared real-project route only. No redundant Test Runner suite is requested for unchanged accepted source; any later repair needs its own approved evidence plan.
- Explicitly not run: Unity/EditMode, Install, Remove, live availability probe, source tests, full regression or historical process scans during preparation.
- Wait budget after authorization: at most 10 minutes for each import/Install/Remove checkpoint, and 60 seconds for each parent availability probe. A timeout is evidence, not retry or process-termination authority; human decides Editor/process disposition.
- Attempts: one semantic execution per lifecycle step, no automatic retry or extra reset. If a step fails, preserve evidence and stop dependent steps. Mechanical pre-side-effect corrections follow the workflow budget only.
- Active planning budget: STANDARD_30M. Output budget: V2_DEFAULT. Broad search/full diff/full regression: FORBIDDEN.
- Stop: target already exists unexpectedly; Package/source identity changes; unsafe/shared ownership; compile failure, missing supported action, refusal or failed checkpoint; a new side effect is required.
- Escalation: supported normal-path defects are reported as product issues; no fix is authorized by this acceptance card. Unrelated history returns the project-baseline choice to User; no historical fallback branches are appended.
- Structural counters: repair `0/2`, independent product causes `1/2` (normal uninstall preflight routed through handoff-required validation); initial diagnostic-only checkpoint `1/3`; immediate triggers still apply. No additional recovery or fixture reset is authorized.
- Model/mode escalation: none activated; any development/delegation route is separately aligned if a concrete defect is found.

## Definition Of Done

Record exact project/Editor/Package identities, first-install status/query,
logical removal evidence and reinstall status/query, with distinct human and
parent evidence. All declared lifecycle checkpoints must pass to claim this
route passed; partial results stay partial. This does not close S29 or prove
cross-version replacement, physical cleanup, Codex Desktop or release gates.

## Authorized source repair packet — 2026-10-15

User approved the bounded process correction (`好的 同意`) and separately
approved reuse of existing Coder → read-only Verifier. This is a task-local
execution-route exception using the existing completed task-scoped agents;
no durable-session creation/rebinding or new children. Inherit their current
model/reasoning settings unchanged; do not change models to follow the older
profile catalog. Parent remains active, consumes questions and waits for both
terminal results. Stable original-byte snapshot is required before Verifier.

### One outcome and required behavior

Restore normal current-version uninstall admission and explain unavailable
removal without silently hiding the lifecycle entry:

1. Validate normal `UninstallPreflight` against its actual producer contract
   (successful complete output, exactly one AVAILABLE classification, refuse
   blocked/duplicate/malformed/timeout/incomplete output). Explicit recovery
   `RemoveIntegrationPreflight` still requires its intact exact handoff; never
   globally relax the existing handoff validator. Failed-preparation fallback
   must retain existing attribution/proof checks.
2. Drive preflight validation by the declared action/route, not by whether a
   result happens to contain a handoff. Normal uninstall uses no forged token.
3. Separate lifecycle entry visibility from enablement. An installed/known
   relevant integration keeps an uninstall/removal entry when admission is
   pending, refused or an action is in flight; it is disabled with an explicit
   bounded reason. Keep no-integration/missing status non-actionable and do not
   invent an installed state from directory existence. Do not advertise a
   usable action when ownership is unknown. Current Ready output remains Ready
   even if a new-change preflight refuses; show refusal as action admission.
4. Consume existing cached status/diagnostic for presentation. No filesystem,
   PowerShell or Node work in OnGUI/menu construction; no new persistent state
   machine or recovery platform. A scoped explanatory row/help text beside
   the visible action/menu is sufficient if disabled menu tooltips are unreliable.
5. Preserve user confirmation and all execution-time backend authority,
   locking, admission, handoff and ownership checks. No actual mutation during
   tests except task-owned isolated fixtures.

### Change allowlist and protected inputs

Only these source/test files may change (not all must change):

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`

All six are clean at admission. Read direct consumers only: Actions, status
types/builders, exact materializer `UninstallPreflight`/`RemoveIntegrationPreflight`
producer and instance-engine removal authority/transaction; relevant focused
test helpers and directly required compile inputs. Do not modify materializer,
instance engine, Actions, Payload or unrelated dirty files. If those changes
become necessary, report the concrete dependency before expanding scope.

Canonical unchanged inputs are the exact 617-file S30 Package at
`.artifacts/s30-current-version-lifecycle-5b52c01/review/com.rice.ai-codedb`,
not dirty worktree Payload. Create an isolated source overlay under
`.artifacts/tests/s30-uninstall-admission/`; do not modify the selected Package
or its original ZIP. Prior exact-byte compile/seam helpers under
`.artifacts/tests/s29-removal-history-authority/coder-a1/` may be read/reused
with fresh task-owned outputs; don't overwrite prior evidence.

Both real S30 and S29 projects, their runtime histories and all external
processes are protected. Do not scan or hash the whole live project as a test
guard; target only boundaries needed for this repair. User need not repeat
first Install. Preserve first-install selection/activation as the later
delivery baseline; only the already planned post-uninstall Install remains.

### Focused evidence and role ownership

- Coder owns source and appends repair result/evidence to `RESULT.md`; parent
  owns TASK and roadmap. Do not concurrently edit each other's records.
- Evidence must join actual shipped producer output contract through original
  C# parser/lifecycle projection and menu enablement/disabled-reason consumers.
  Use an isolated actual-entry fixture if existing harness supports it without
  broadening, or an exact-source producer/seam harness with explicit limits;
  do not label hand-built AVAILABLE strings alone as production integration PASS.
- Cover normal AVAILABLE → enabled uninstall; normal refusal/malformed/duplicate
  and incomplete output → disabled entry with bounded cause; preflight not yet
  available → visible non-executable entry; confirmation cancellation/no
  integration → no mutation; explicit recovery missing/invalid handoff remains
  refused and valid handoff remains accepted. Include action-in-flight behavior
  if touched. Preserve nearest existing recovery tests.
- Compile original changed Editor and affected Editor.Tests bytes against the
  exact Package closure, no Unity launch. Run only declared targeted regression,
  no full suite or unrelated historical scenarios. Native/process calls must
  be isolated test-owned; no real preflight/removal/install/probe on S30.
- Freeze changed-file SHA256 and exact evidence paths in Coder result; then
  stop writing. Independent Verifier reads this packet, the stable snapshot,
  direct consumers and declared evidence once; no broad audit or rerun of
  unchanged tests. Findings together to parent/User, not repairs assigned to
  Coder. Review repair findings and nearest regressions only.
- No commit, export, Package reference switch, Unity, real product actions or
  cleanup in this source window. Delivery/source acceptance remains a later
  user decision. Active budgets: Coder DEEP_60M, Verifier 30M; V2 output and
  local evidence-attempt limits. Stop on expanded scope, incompatible input,
  budget boundary or unresolved structural conflict.

## Handoff

- Current task: S30 current-version lifecycle acceptance.
- Current status: SOURCE_ACCEPTED / DELIVERY_REFERENCE_SWITCHED / HUMAN_REOPEN_BLOCKED.
- Next notification: User.
- Next action: Hold real S30 acceptance while the agreed uninstall-workflow redesign is prepared as [S31](../cdb-v0.3-p0-s31-project-uninstall-workflow/TASK.md). See [route reassessment](ROUTE-REASSESSMENT.md). Preserve first-install evidence and the live baseline; no manual process workaround or repeated Install.
- Human decision or authorization required: S31 source/delegation route is approved and executing; later source acceptance, delivery and real lifecycle gates remain separate. The prior proposal to manually stop the live owner is superseded by this alignment.

## Delivery update — 2026-10-15

- User accepted the frozen source result (`同意 accept`). The six-file change was committed as `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6` with the unrelated dirty tree preserved.
- The commit-derived exact package was exported to `.artifacts/s30-current-version-lifecycle-ed97c38/`; the exporter reported 617 files, commit-staged and exact-ZIP byte closure PASS, production payload admission PASS, and native build binding PASS.
- Exact ZIP SHA256: `78cc1bea38e9a9ca5f057a916b5ea78c9a4427905d682c242dce52e430cdb08c`; review tree contains exactly 617 files. `package.json` SHA256: `fcb67de746dd681b4194ac2003a867a7be69079d9027fe81a4743b475352402a`.
- Before switching, S30 `Packages/manifest.json` and `Packages/packages-lock.json` were backed up under `.backups/s30-current-version-lifecycle-ed97c38/` with hashes `74197d58458d8347e0a31a928c4c549e0b01a1913a332fa17408b773e8086463` and `97d6a9d4ecd24c02c0d12806f4163243f01994f0da58190d291363de65121e9c`.
- S30 now references `file:G:/RiceProgram/UnityCodeDB/.artifacts/s30-current-version-lifecycle-ed97c38/review/com.rice.ai-codedb` in both manifest and lock; the target `package.json` exists. No matching S30 Unity process or S30 UnityLockfile was present during the switch. No first Install was repeated.
- Exact extracted Package `-PathProvenanceOnly` passed (exit 0). Comparison of all 617 shipped paths against the prior S30 extraction found exactly the six accepted source/test changes; the pre-existing Unity-generated extra meta remains only in the preserved old extraction. Git index is empty after the six-file commit.

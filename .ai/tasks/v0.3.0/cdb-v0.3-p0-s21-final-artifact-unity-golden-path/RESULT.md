# Result: cdb-v0.3-p0-s21-final-artifact-unity-golden-path

## Outcome

- Status: BLOCKED / POST_PROVIDER_ERROR_PROVENANCE_LOST
- Workflow: codedb-workflow-v2
- Workflow revision: 2.3
- Artifact identity: S20 source commit `399e81412820999889c7273e0f5489071e99218e`;
  ZIP SHA-256
  `a947ae36f24c1ab870567613abe9ca3df986f8ac5dd8a93903a02f8492a1c2a9`
- Validation project Package reference: updated to the repository-relative
  accepted S20 Package directory while Unity was confirmed closed.

## Evidence

- Package import/compile: PASS; human reported zero Console errors after the
  accepted Package import and compilation completed.
- Manager terminal state: `Needs attention / Host payload Needs Setup`; Runtime
  is `Ready`, Configuration is `Current`, Provider is `Inactive`, and
  `Configure Dependencies` is offered. This is the expected fresh-project
  prerequisite state and is not a closure/hash failure.
- Configure Dependencies: FAIL, exit `4`, attempt `1/1`, no retry. The only
  displayed error payload was the successful prerequisite observation:
  `[PRODUCT_LAYER PREREQUISITE] CURRENT - Node.js v24.14.1 and CodeDB Provider
  0.5.0-28e3912-c2 are verified.`
- Play/Edit lifecycle: NOT RUN
- Normal shutdown: NOT RUN

## Boundaries

- No Unity process was started or stopped by Planner/Coder.
- No Package source/test, artifact, runtime, Provider, or machine state was
  modified by this task initialization.
- Existing unrelated validation-project settings changes were preserved.

## Human Evidence 01 - Import And Fresh Setup

- Overview screenshot: 129,513 bytes, SHA-256
  `d99c24ad51705f30dd101428b670ffbb749ca0696da2fba2c08325ba418496f4`.
- Setup screenshot: 74,696 bytes, SHA-256
  `27b9363d21b5269011ecfe3b3b74730db1a382c0e2f71a8a869f6d2c25507ad6`.
- Console screenshot: 107,210 bytes, SHA-256
  `667a50cf57364b28357a53a205c6b1fd863b6f089669a98dc9991b370dd16c05`.
- Console: zero errors and four warnings. Visible warnings include the existing
  C# `CS4014` unawaited-call warning plus CodeDB lifecycle/prerequisite evidence;
  no Package import, payload hash, or compilation failure is visible.
- Package label shown by Manager: `v0.3.0-preview.5`.

## Human Evidence 02 - Configure Dependencies Failure

- Screenshot: 106,499 bytes, SHA-256
  `a62a7ab40d6f7fc88fe7fbb2cbb45069355fbd7ce35ff00e7ce3b13de2c788c0`.
- The user clicked `Configure Dependencies` exactly once. The Manager reported
  `Command failed with exit code 4` and remained `Needs attention`.
- Runtime remained `Ready`; Configuration remained `Current`; Provider was
  displayed as `Inactive`.
- The previous S19 payload source hash mismatch did not recur. No second click
  or automatic retry was performed.

## Bounded Source Diagnosis

- `AICodedbManagerWindow.RecheckHostPayloadAfterProviderAsync` synthesizes a
  new exit-4 result from `outcome.Detail` when reconcile is not Ready and does
  not preserve `outcome.LastCommandResult`.
- `AICodedbReconcileOutcome.Detail` is capped at 256 characters. The displayed
  result therefore cannot preserve the full failing command provenance.
- The observed prerequisite line proves machine prerequisite admission only;
  it does not identify the downstream materializer/instance failure.
- The underlying product cause remains unclassified. Guessing a runtime repair
  or repeating Configure Dependencies would violate the task boundary.

## Handoff

- Current status: BLOCKED / POST_PROVIDER_ERROR_PROVENANCE_LOST
- Next actor: human operator
- Next action: after Unity is closed and a bounded source FIX is authorized,
  preserve the post-Provider reconcile's authoritative failing command/result
  in Manager output. Only then may a new human-owned Configure Dependencies
  attempt be authorized to classify the underlying product cause.

## FIX 01 - Post-Provider Error Provenance

- Status: COMPLETE / STATIC_EVIDENCE_PASS / UNITY_RETRY_PENDING
- Frozen HEAD before and after:
  `9691074d48c68c0a4d27e61ce9b753912e0de78b`
- Ordered two-file binary diff identity:
  `f3bc47472324d2697da7c68c07793aeebde48bb9`
- Changed production method:
  `AICodedbManagerWindow.RecheckHostPayloadAfterProviderAsync`, with the
  result mapping isolated in
  `ResolvePostProviderReconcileResult`.
- Changed direct tests:
  - `PostProviderResult_FailingAuthoritativeResultIsPreservedExactly`
  - `PostProviderResult_SuccessfulCommandWithNonReadyOutcomeRetainsEvidenceAndFails`
  - `PostProviderResult_ReadyOutcomeReturnsBoundedSuccess`
  - `PostProviderResult_MissingAuthoritativeResultReturnsBoundedFailure`

### Implemented Behavior

- Provider failure remains unchanged and does not request lifecycle reconcile.
- Ready remains a bounded synthetic success.
- A Non-Ready authoritative failing result is returned as the same object,
  preserving exit code, stdout, stderr, timeout, elapsed time, and
  one-shot-fallback authorization exactly.
- A Non-Ready outcome whose last command succeeded becomes a bounded exit-4
  failure while retaining stdout, stderr, timeout, elapsed time, and fallback
  evidence and appending the terminal explanation.
- A null outcome or missing authoritative result remains a bounded synthetic
  failure.
- The result mapper does not parse command output or select a lifecycle,
  materializer, runtime, or mutation behavior.

### Evidence

- Bounded static/source assertions: PASS, exit `0`, `23/23`, command wall time
  `0.2019755s`.
- Exact two-file `git diff --check`: PASS, exit `0`, no output, command wall
  time `0.2244232s`.
- No corrected attempt or retry was used.

### Not Run / Deferred

- Unity, Unity MCP, EditMode, C# compilation, Package export, Provider
  installer, materializer tests, external Configure Dependencies retry,
  process probes, cleanup, full regression, commit, push, publication, and
  Verifier contact: NOT RUN / DEFERRED.
- The underlying post-Provider product cause remains unclassified until a new
  human-owned Unity attempt exposes the preserved authoritative result.

### FIX 01 Handoff

- Current status: COMPLETE / STATIC_EVIDENCE_PASS / UNITY_RETRY_PENDING
- Next actor: UnityCodeDB v0.3 Planner / human operator
- Next action: review this stable two-file snapshot and decide whether to
  authorize a new human-owned Unity golden-path attempt. Do not infer runtime
  acceptance from this static evidence.

## FIX 01 Commit, Package Export, And Validation Reference

- Source commit:
  `50b131667b076998f48fedc4f991ff99b0adbd73`.
- Commit message: `fix(v0.3): preserve post-provider failure evidence`.
- Commit scope: exactly the two authorized Manager production/test files.
- Artifact directory:
  `.artifacts/v0.3.0-preview.5-s21-provenance-50b1316-final/`.
- ZIP SHA-256:
  `a5c0e1ba4060c59ac8acba4e46f967446818d62806008d6526d61f3365d8d0dd`.
- ZIP bytes/entries: `2,132,148` / `477`.
- Extracted Package: single root, `477` files, `9,478,488` bytes.
- Commit-staged and exact-ZIP internal validators: PASS, `46/46` sources,
  `0` mismatches.
- Export attempts: `1/1`; no retry.
- Validation-project manifest and lock were updated while Unity was closed to
  the repository-relative S21 Package directory. `ProjectSettings.asset` was
  not modified by this task.

Current status: `READY / HUMAN_RETRY_PENDING`. The next human action is to open
UnityValidationProject, wait for compilation, confirm zero errors, then click
Configure Dependencies exactly once. If the action still fails, the complete
authoritative stdout/stderr should now be preserved; do not retry.

## FIX 01 Commit And Package Export

- Status: COMPLETE / COMMIT_DERIVED_PACKAGE_READY / HUMAN_SWITCH_PENDING
- Source commit:
  `50b131667b076998f48fedc4f991ff99b0adbd73`
- Commit message: `fix(v0.3): preserve post-provider failure evidence`
- Staged and committed path set was exactly:
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- S21 TASK/RESULT, validation-project files, artifacts, and all other dirty
  paths were excluded from the commit.

### Commit-Derived Artifact

- Export attempt: `1/1`; retry: `0`.
- Export command exit: `0`; wall time: `7.9292377s`.
- Artifact directory:
  `.artifacts/v0.3.0-preview.5-s21-provenance-50b1316-final/`
- ZIP:
  `.artifacts/v0.3.0-preview.5-s21-provenance-50b1316-final/com.rice.ai-codedb.zip`
- ZIP SHA-256:
  `a5c0e1ba4060c59ac8acba4e46f967446818d62806008d6526d61f3365d8d0dd`
- ZIP size: `2,132,148` bytes; ZIP entries: `477`.
- Extracted Package: one `com.rice.ai-codedb` root, `477` files,
  `9,478,488` bytes.
- Commit-staged closure validator: PASS, `46/46` sources, `0` mismatches.
- Exact emitted ZIP was extracted to the distinct review root; its internal
  validator also passed `46/46` sources with `0` mismatches.
- Deterministic exporter invariants remained active: ordinal entry ordering,
  fixed legal entry timestamps, commit-owned validator, and no export-time
  repair.
- Closure identities in both validator passes:
  - generation:
    `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`
  - host-current:
    `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`
  - runtime contract:
    `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`

### Export Boundaries And Handoff

- No test or static assertion was rerun during commit/export.
- Unity, Unity MCP, EditMode, external Configure Dependencies, Provider,
  materializer and other tests, tag, push, publication, and Verifier contact:
  NOT RUN / DEFERRED.
- Existing validation-project `manifest.json` and `packages-lock.json` changes
  were preserved and were not modified by this checkpoint.
- Current status: COMPLETE / COMMIT_DERIVED_PACKAGE_READY /
  HUMAN_SWITCH_PENDING.
- Next actor: UnityCodeDB v0.3 Planner / human operator.
- Next action: Planner may switch the validation project's relative Package
  reference to this artifact while Unity is closed, then authorize one new
  human-owned Configure Dependencies attempt. The underlying runtime cause is
  still unclassified until the preserved authoritative result is observed.

## Human Evidence 03 - Authoritative Instance Failure Exposed

- The human operator opened the validation project, waited for compilation,
  and clicked `Configure Dependencies` exactly once against the commit-derived
  S21 Package artifact.
- Manager screenshot 1: 165,829 bytes, SHA-256
  `e84f8b6fd3a85933e2ab8cce5f94746f271b8af8176db69a17db0abc728a67e1`.
- Manager screenshot 2: 118,629 bytes, SHA-256
  `b424dece984b5e9c3853b2ad68570bad2fd0dd7ef27b3a95c32d6ad45ba8b4f9`.
- Temporary screenshot paths are intentionally not recorded.
- The FIX 01 provenance change worked: Manager retained and displayed the
  authoritative exit code, elapsed time, product-layer states, and underlying
  instance failure instead of only the truncated prerequisite line.
- Exact terminal classification:

  ```text
  Command failed with exit code 4.

  Exit Code: 4
  Elapsed: 2.00 s

  Output:
  [PRODUCT_LAYER PREREQUISITE] CURRENT - Node.js v24.14.1 and CodeDB Provider 0.5.0-28e3912-c2 are verified.
  [PRODUCT_LAYER INSTALLED] BLOCKED
  [PRODUCT_LAYER CONFIGURED] BLOCKED
  [PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE
  [PRODUCT_STATE] NEEDS_ATTENTION
  [INSTANCE] INVALID - current instance selection is missing required property: owner_identity_version

  Error:
  [PRODUCT_LAYER PREREQUISITE] CURRENT - Node.js v24.14.1 and CodeDB Provider 0.5.0-28e3912-c2 are verified.
  ```

### Bounded Recovery-Design Assessment

- The machine prerequisite is already current. The observed failure is not a
  Provider installation failure and another `Configure Dependencies` attempt
  is not authorized.
- `AICodedbCurrentInstanceStore.Read` currently requires
  `owner_identity_version` before it can classify a selected instance and
  maps a missing property to the generic `Invalid` state.
- Lifecycle propagation preserves the generic attention reason for this
  invalid current instance, so `AICodedbProductStatus.RequiresReinstall`
  remains false.
- Manager currently offers `Configure Dependencies` for every
  `NeedsAttention` state, even when prerequisite evidence is current. This
  makes the visible recovery action misleading for the observed state.
- Existing explicit `Remove CodeDB Integration` admission is intentionally
  narrower: it requires a reinstall-required cached product status plus a
  freshly revalidated `ObsoleteReinstallRequired` control-contract state.
  The screenshot alone does not prove that this old current-instance pointer
  satisfies that removal authority.
- Therefore the observed state must remain fail-closed until a coherent
  recovery design distinguishes authenticated obsolete owner evidence from an
  arbitrary invalid or ambiguous selection. No runtime bytes were inspected,
  changed, or removed during this assessment.

### Current Handoff

- Status: `BLOCKED / INSTANCE_OWNER_IDENTITY_RECOVERY_UNCLASSIFIED`.
- Do not click `Configure Dependencies` again on this snapshot.
- A continuous S21 recovery-design FIX is required. It should classify only
  provably obsolete instance evidence as reinstall-required, expose the
  explicit removal/reinstall path, suppress dependency configuration when the
  prerequisite is already current, and preserve fail-closed behavior for
  arbitrary invalid or ambiguous evidence.
- Unity, Unity MCP, EditMode, runtime mutation, cleanup, retry, Provider
  installation, commit, push, publication, and Verifier contact were not
  performed by this assessment.
- Next actor: UnityCodeDB v0.3 Planner / human operator.
- Next action: close the validation project before any source FIX or protected
  runtime diagnosis, then freeze one coherent allowlist and evidence budget.

## FIX 02 - Obsolete Instance Recovery Contract

- Status: `COMPLETE / NON_UNITY_EVIDENCE_PASS / INDEPENDENT_REVIEW_PENDING`.
- Frozen HEAD before and after:
  `50b131667b076998f48fedc4f991ff99b0adbd73`.
- Ordered ten-file binary-diff SHA-256:
  `952b7d8f209be990187686328f4ca52491893527ded71c5c185d5a78576f367e`.
- The validation project remained closed. No validation-project runtime or
  protected state was read, changed, or removed.

### Implemented Contract

- `AICodedbCurrentInstanceStore` now distinguishes an exact Owner Identity v1
  selection from arbitrary invalid evidence. The v1 classification requires
  the exact legacy field set plus valid project identity, selection path,
  instance manifest hash, immutable generation closure, worker hash, and a
  Package-declared current or trusted-previous generation.
- Partial v2 fields, unknown fields, malformed identity, hash drift, escaped
  paths, unsupported generations, or conflicting closure remain `Invalid`.
- An authenticated v1 selection is read-only and classified as
  `ObsoleteReinstallRequired`; it cannot publish an Editor lease or enter
  automatic convergence.
- Lifecycle now resolves that state before Supervisor admission. With current
  prerequisite evidence and no retained control authority it publishes the
  distinct `InstanceIdentityReinstallRequired` reason. A conflicting current
  or ambiguous control contract remains fail-closed.
- Manager now offers `Configure Dependencies` only for an actual missing
  Provider prerequisite. Generic `NeedsAttention` and reinstall-required
  states no longer expose dependency installation as recovery.
- The authenticated obsolete-instance state exposes the existing explicit
  `Remove CodeDB Integration` primary action and reinstall guidance.
- C# admission re-reads project integration, control migration, and current
  instance state immediately before requesting removal. The orphaned v1 route
  requires installed integration, current prerequisite evidence, missing
  control authority, exact obsolete instance classification, and explicit
  human mutation confirmation.
- PowerShell removal preserves the existing authenticated Supervisor paths and
  adds one bounded `ORPHANED_V1_SELECTION` authority. It requires the exact v1
  selection and Package-owned closure, no retained contract files, clear
  holder evidence, and an exact selection fingerprint recheck immediately
  before mutation. It does not stop processes or delete immutable instances.

### Evidence

- Bounded static/source batch: PASS.
  - Production and fixture PowerShell AST parses: PASS.
  - C# routing/call-site assertions and exact enum/action references: PASS.
- Ten-file scoped `git diff --check`: PASS, exit `0`, no output.
- Focused command:

  ```text
  powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -OwnerIdentityRemovalOnly
  ```

- Focused Owner Identity removal L0: PASS, exit `0`, wall time `82,212 ms`,
  invocation `1/1`, retry `0`.
- Terminal output confirmed that the removal contract blocks live,
  unverifiable, mismatched, partial, and conflicting authority; admits only an
  exact orphaned v1 selection or authenticated Supervisor authority; preserves
  immutable instances, indexes, leases, retirement sentinels, user data,
  unrelated TOML, and processes; and preserves interrupted-removal recovery.
- Direct C# tests were added for exact v1 classification, unknown-field
  rejection, lifecycle attention routing, Manager action selection, and fresh
  removal admission. They were source-reviewed but not executed because Unity
  EditMode was outside this checkpoint.

### Boundaries And Handoff

- Unity, Unity MCP, EditMode, C# compile, BatchMode, Package export, real
  project removal, Provider operations, process termination, full regression,
  commit, tag, push, publication, and Verifier contact: NOT RUN / DEFERRED.
- No automatic retry was used and no second product cause was observed.
- Existing unrelated dirty files and artifacts were preserved.
- Next actor: UnityCodeDB v0.3 Planner / independent Verifier.
- Next action: perform one bounded read-only review of the frozen ten-file
  recovery contract and recorded evidence. Only after acceptance should the
  source be committed, a commit-derived Package be exported, and a new
  human-owned Unity scenario be authorized.

## Planner/User Disposition

- Verifier verdict: `PASS`.
- One-time findings: none (`BLOCKER`: none; `P1`: none; `P2`: none;
  `FOLLOW-UP`: none).
- Planner/User decision: `ACCEPT`.
- Accepted scope: S21 FIX 02 obsolete-instance recovery contract only.
- Current frozen HEAD remains
  `50b131667b076998f48fedc4f991ff99b0adbd73`; the accepted ten-file patch
  remains uncommitted with identity
  `952b7d8f209be990187686328f4ca52491893527ded71c5c185d5a78576f367e`.
- This acceptance does not imply Unity, EditMode, C# compile, Package export,
  Provider, publication, or consumer-project acceptance. Those remain
  `NOT RUN / DEFERRED` until separately authorized.
- Next workflow action: commit the accepted source/test slice, export a new
  commit-derived Package, then schedule one human-owned Unity golden-path
  attempt. No action was run automatically in this disposition step.

## Commit And Package Export

- Accepted source/test slice committed as:
  `2deb47bb833ac981a7d5f49c34bfc88da601ee15`
- Commit message: `fix(v0.3): route obsolete instance recovery`.
- Commit scope: exactly the ten FIX 02 allowlisted production/test paths;
  task records, S18 records, UnityValidationProject files, and historical
  artifacts were excluded.
- Commit-staged Package closure: PASS, source count `46`, mismatch count `0`.
- Exact ZIP closure: PASS, source count `46`, mismatch count `0`.
- Export attempt: `1/1`, retry `0`, exit `0`, wall time `6,962 ms`.
- Commit-derived artifact directory:
  `.artifacts/v0.3.0-preview.5-s21-fix02-2deb47-final/`.
- ZIP:
  `.artifacts/v0.3.0-preview.5-s21-fix02-2deb47-final/com.rice.ai-codedb.zip`.
- ZIP entries: `477`.
- Extracted Package files/bytes: `477` / `9,504,062`.
- ZIP SHA-256:
  `c8d9fcf7479598465b66c1e0d38fb7ed7e96356ff14491474a5f6d48455c110b`.
- Closure identities remained stable:
  - generation:
    `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`
  - host-current:
    `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`
  - runtime contract:
    `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`
- Current status: `COMPLETE / COMMIT_DERIVED_PACKAGE_READY /
  HUMAN_SWITCH_PENDING`.
- UnityValidationProject package reference was intentionally not changed in
  this step. Next action requires the human operator to switch the closed
  project to the new repository-relative Package path, open Unity, wait for
  compilation, and perform the single bounded golden-path attempt.

## Human Evidence 04 - Host Action Thread Violation

- The FIX 02 commit-derived Package was selected through the validation
  project's repository-relative `file:` reference and imported successfully.
- Human observation: Unity compiled with zero Console errors. CodeDB Manager
  showed Package `0.3.0-preview.5`, project-local runtime Ready, and Host
  payload Needs Setup / Not evaluated.
- `Inspect host files` (Host Payload DryRun) failed with exit `-1` and
  `DisplayProgressBar can only be called from the main thread`.
- A subsequent human `Sync host files` action returned the same exit `-1` and
  error. The exception occurs before the materializer process starts; neither
  command produced a Host script result.
- The displayed Host generation invalid state does not yet establish a
  separate production finding because Host initialization did not run.
- The human closed the Unity validation project before source work.
- Current golden-path status: `BLOCKED / HOST_ACTION_MAIN_THREAD_UI_VIOLATION`.

## FIX 03 - Host Action Thread Boundary

- Base HEAD: `2deb47bb833ac981a7d5f49c34bfc88da601ee15`.
- Changed only the Package Editor command helpers and direct Manager UI test:
  `Editor/AICodedbHostPayloadMaterializer.cs`, `Editor/AICodedbActions.cs`,
  and `Tests/Editor/AICodedbManagerUiTests.cs`.
- The synchronous Materializer command family no longer calls Unity's
  blocking progress bar. Argument validation, read/mutation timeouts,
  cancellation, and process-runner results are retained.
- The worker-reachable generic script and Provider helpers no longer call
  Unity's blocking progress bar. The unused watcher progress helper was
  removed. Manager already owns cached Last activity progress on the Editor
  thread.
- Added a direct source regression test checking the Manager worker lane,
  Activity panel, Host action routes, and absence of blocking progress calls
  from worker command helpers.
- Scoped source contract check: PASS, `7/7` assertions.
- Three-file `git diff --check`: PASS, exit `0`, no output.
- Package-boundary L0: PASS, exit `0`, output
  `[OK] Standalone CodeDB package boundary passed.`
- Package release closure on the worktree Package: PASS, `46/46` sources,
  `0` mismatches. Immutable generation, host pointer, and runtime contract
  hashes remain unchanged.
- Unity, EditMode execution, C# compilation of these new bytes, Unity MCP,
  real Host actions, and the remainder of the golden path: NOT RUN / DEFERRED.
- Next action: commit this exact three-file source/test slice, export and
  validate one commit-derived Package, then resume the human-owned Unity
  scenario from Host initialization.

### FIX 03 Commit, Export, And Validation Reference

- Source/test commit: `6cf673db600c02061a12684374d428d56e9cb5b3`
  (`fix(v0.3): keep host progress on manager thread`). The commit contains
  exactly the three FIX 03 allowlisted files.
- Commit-derived Package:
  `.artifacts/v0.3.0-preview.5-s21-fix03-6cf673d-final/package/com.rice.ai-codedb`.
- ZIP: `.artifacts/v0.3.0-preview.5-s21-fix03-6cf673d-final/com.rice.ai-codedb.zip`.
- Export: PASS, exit `0`, one attempt, no retry; `477` Package files and
  `477` ZIP entries.
- Commit-staged and exact-ZIP closure: both PASS, `46/46` sources, zero
  mismatches.
- ZIP SHA-256:
  `efe157619e329ba4ea375e596ca90995a4ec6c37c7de33f32f058d3ff1ec35b4`.
- Validation project's `Packages/manifest.json` and `Packages/packages-lock.json`
  now use the same repository-relative `file:` reference to this Package.
  Both parse as JSON, the resolved directory exists, and their scoped
  `git diff --check` passes. These validation-project files are not in the
  source/test commit.
- Current status: `COMPLETE / COMMIT_DERIVED_PACKAGE_READY /
  HUMAN_OPEN_PENDING`.
- Next action: human opens the validation project, waits for Package import
  and compile, then performs one Host inspection and follows only the action
  supported by its actual result. The Manager/Host runtime outcome remains
  unproved until that visible scenario runs.

## Human Evidence 05 - FIX 03 Host Inspect Result

- The human opened the validation project and ran `Inspect host files` once
  from CodeDB Manager using the FIX 03 Package.
- Host Payload DryRun completed successfully: exit `0`, elapsed `2.08 s`.
  The previous `DisplayProgressBar` thread exception did not recur.
- The full command output reported current Node.js and Provider prerequisites,
  followed by `INSTALLED BLOCKED`, `CONFIGURED BLOCKED`,
  `MCP_AVAILABLE UNAVAILABLE`, `PRODUCT_STATE NEEDS_ATTENTION`, and
  `[INSTANCE] INVALID - current instance selection is missing required
  property: owner_identity_version`.
- Exit `0` is the read-only diagnostic command result, not product readiness.
  The Host and instance golden path remains blocked before Coordinator and
  MCP availability acceptance.
- Source boundary check: ordinary PowerShell status reading requires Owner
  Identity v2. The FIX 02 recovery route admits only a fully authenticated
  exact v1 selection with its required closure. The visible output alone does
  not prove that this project's selection meets the recovery conditions.
- No Sync, Remove, reinstall, Provider operation, protected runtime read,
  process probe, Unity MCP, Play transition, or further scenario action was
  performed by the assistant after this finding.
- Current status: `BLOCKED / CURRENT_INSTANCE_SELECTION_INVALID`.
- Next action: preserve the state, close Unity normally, then conduct a
  separately bounded read-only inventory of the selection and its Package
  closure before deciding on any recovery or source change.

## Read-Only Inventory After Human Unity Shutdown

- Unity was reported closed before the inventory. Only the validation
  project's exact selection, instance, generation, and control-contract
  evidence was read; no command, process probe, cleanup, or mutation ran.
- `AIWork/.runtime/codedb/control/current-instance.json` has exactly the
  eight Owner Identity v1 selection fields. It has neither
  `owner_identity_version` nor `activation_epoch`; its instance path has the
  expected bounded shape and matches its instance ID.
- The selected `poc.34` instance is `READY`. Its `instance.json` hash matches
  the selection; its generation manifest and worker hashes match the
  instance record. The FIX 03 Package declares `poc.34` as a predecessor to
  current `poc.39`.
- The project stable wrapper at
  `AIWork/codedb/wrapper/codedb-project-wrapper.mjs` is absent. The Editor's
  exact v1 classifier requires this Package-owned wrapper identity before it
  can classify the selection as `ObsoleteReinstallRequired`.
- The versioned v1 control namespace is not empty. It contains an activation
  record and a `COMMITTED` `UPGRADE` operation, plus a failed Supervisor
  operation and events. The Supervisor state/lock pair is absent.
- The activation and operation IDs, activation epochs, and project identities
  agree. The activation's current instance, operation candidate, and failed
  Supervisor operation's selected instance all match the v1 current selection.
- The FIX 02 orphaned-v1 removal route requires no retained control-contract
  files; the versioned Supervisor route requires a complete state/lock pair.
  Neither route is admitted by the observed evidence. Missing wrapper bytes
  also prevent normal selected-instance authentication.
- This is a partial but durable v1 control state, not proof of a removable
  orphan or a safe Sync target. Holder status was not probed, and no cleanup
  authority was inferred from file names alone.
- Current status: `BLOCKED / PARTIAL_V1_CONTROL_RECOVERY_CONTRACT_REQUIRED`.
- Next action: design one continuous, evidence-bound recovery contract for
  this exact partial v1 state, including selection/generation/operation
  identity, missing-wrapper semantics, holder checks, and precise mutation
  scope. Review the contract and test evidence before any project mutation or
  further Unity golden-path attempt.

## FIX 04 - Partial V1 Control Recovery Source Handoff

- User authorized one continuous same-S21 source/test change while the
  validation project remains closed. No real project runtime state was read
  or changed in this implementation pass.
- Frozen HEAD: `6cf673db600c02061a12684374d428d56e9cb5b3`.
- Ordered seven-file binary patch identity:
  `c21502eb7d31bc3c2a058a53ef6e8198dcdbc9d8`.
- Changed Package files only: `Editor/AICodedbControlContract.cs`,
  `Editor/AICodedbHostGenerationStore.cs`,
  `Editor/AICodedbProjectIntegrationState.cs`,
  `Tests/Editor/AICodedbEditorLifecycleTests.cs`,
  `Tests~/test-codedb-host-payload-materializer.ps1`,
  `Tools~/codedb-instance-engine.ps1`, and
  `Tools~/materialize-codedb-host-payload.ps1`.
- The explicit removal path now recognizes only a complete v1 current
  selection with a Package-declared predecessor generation, no second
  selection, a unique failed Supervisor operation/events pair, bound
  COMMITTED v1 UPGRADE activation, and clear holders. It fingerprints the
  certified evidence and rechecks authority before transaction mutation.
  Only reviewed control/selection targets are removed; the instance and
  immutable generation remain unchanged. A missing stable wrapper is allowed
  only for obsolete-v1 classification and explicit removal. A present but
  drifted wrapper remains invalid.
- Historical `poc.34` COMMITTED v1 operation journals predate
  `retirement_intent_path` and `retirement_intent_sha256`. The engine accepts
  that exact old field shape only through the explicit removal switch;
  ordinary activation reading still rejects it. The C# Manager classifier
  independently rejects unknown partial-control entries, identity mismatch,
  malformed mutation-array type, and reparse operation/retirement roots;
  it does not itself grant mutation authority.
- Focused `-PartialV1RemovalOnly`: final exit `0`, about 30 seconds, with
  historical journal shape. It covers live holder, mismatched identity,
  unknown entry, missing activation, state-only rejection, ordinary-read
  rejection, and exact removal with preserved instance/generation bytes.
  The initial new-fixture attempt failed before product logic because the
  fixture omitted transaction globals; the fixture was corrected. The final
  focused scenario passed twice.
- Adjacent `-OwnerIdentityRemovalOnly`: exit `0`, about 117 seconds, covering
  existing v2 and orphaned-v1 behavior.
- Final AST parse of the three changed PowerShell files: PASS. Final scoped
  seven-file `git diff --check`: exit `0`, no output. No Package production
  or test bytes changed after these final checks.
- C# compile, EditMode, Unity, Unity MCP, other L0/L1, real-project removal,
  commit, push, and Package export: NOT RUN / DEFERRED. Existing unrelated
  dirty worktree content was preserved.
- Status: IMPLEMENTED / FROZEN_SOURCE_REVIEW_PENDING. Next actor: independent
  read-only Verifier for FIX 04 and adjacent regression only. Human disposition
  remains required before commit, Package export, or another Unity scenario.

## FIX 04 Targeted Review And User Disposition

- `verifications/VERIFICATION-02.md` records `FAIL` with one `P1-01` and no
  BLOCKER, P2, or FOLLOW-UP. Frozen admission passed: HEAD
  `6cf673db600c02061a12684374d428d56e9cb5b3` and ordered seven-file
  patch identity `c21502eb7d31bc3c2a058a53ef6e8198dcdbc9d8`.
- P1-01: Editor partial-v1 classification accepts some evidence that backend
  removal rejects. It checks that journal `mutations` is an array but not
  each mutation's schema/index/target/uniqueness, and it checks for a second
  selection with `File.Exists` only, missing a non-regular entry at that
  path. This can expose `Remove CodeDB Integration` when the backend will
  fail closed. The report found no expanded backend deletion authority.
- User disposition: `ACCEPT` the frozen FIX 04 source snapshot with this
  documented P1 risk. The Verifier verdict remains `FAIL`; P1-01 is accepted
  risk, not a fixed or passing assertion. No repair was authorized.
- Source status: `ACCEPTED_WITH_KNOWN_P1 / SOURCE_BASELINE`. C# compile,
  EditMode, Unity golden path, real-project removal, Package export, and
  release acceptance remain `NOT RUN / DEFERRED` as applicable.
- Next actor: Planner/User for a separately authorized next gate. This
  disposition does not authorize commit, push, Package export, Unity retry,
  publication, or another role dispatch. S22 Host Action Execution Contract
  remains draft until its own baseline admission is satisfied.

## Scoped Commit Authorization

- The user subsequently authorized one scoped commit and synchronization of
  the v0.3 roadmap and GitHub Project 7. This is separate from the earlier
  FIX 04 ACCEPT disposition and does not change the Verifier `FAIL/P1-01`.
- The commit scope is the frozen seven-file S21 source/test slice, S21 task
  and verification records, the S22 design-baseline task/contract, and the
  v0.3 roadmap checkpoint. Other dirty worktree content remains excluded.
- Push, Package export, Unity retry, publication, and S22 Coder dispatch are
  not implied by this commit authorization.

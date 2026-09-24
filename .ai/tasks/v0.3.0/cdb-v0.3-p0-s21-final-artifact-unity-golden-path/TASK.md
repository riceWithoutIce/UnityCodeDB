# Task: cdb-v0.3-p0-s21-final-artifact-unity-golden-path

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Workflow: codedb-workflow-v2
- Workflow revision: 2.3
- Status: FIX_04_ACCEPTED_WITH_KNOWN_P1 / SOURCE_BASELINE
- Planner: UnityCodeDB v0.3 Planner
- Coder: optional bounded child only after an observed product failure
- Verifier: optional after stable human evidence
- Review mode: RELEASE
- Execution mode: HUMAN_OWNED_UNITY_WITH_BOUNDED_SUBAGENT_SUPPORT
- Delegation authorization: STANDING_WORKFLOW
- Requirement source: accepted S20 commit-derived Package artifact

## Objective

- Validate the accepted S20 Package artifact through one continuous, visible
  UnityValidationProject golden path: Package import and compilation, Manager
  terminal state, Configure Dependencies when offered, lifecycle stability,
  and normal Unity shutdown.

## Frozen Input

- Package source commit:
  `399e81412820999889c7273e0f5489071e99218e`
- Package directory:
  `.artifacts/v0.3.0-preview.5-s20-zipfix-399e814-final/package/com.rice.ai-codedb`
- ZIP:
  `.artifacts/v0.3.0-preview.5-s20-zipfix-399e814-final/com.rice.ai-codedb.zip`
- ZIP SHA-256:
  `a947ae36f24c1ab870567613abe9ca3df986f8ac5dd8a93903a02f8492a1c2a9`
- Validation project: `UnityValidationProject`
- Package reference: repository-relative `file:` reference only.

## Continuous Scenario

1. Human opens `UnityValidationProject` visibly and waits for compilation and
   Package import to finish.
2. Confirm zero Package/C# errors. Record warnings separately; do not classify
   unrelated Unity warnings as a CodeDB failure.
3. Open CodeDB Manager and wait for checking to reach a stable terminal state.
4. If `Configure Dependencies` is offered, click it once and wait for its
   bounded command result. Do not repeat automatically.
5. Require the Package-owned Host runtime and selected instance to converge;
   capture the terminal Manager state and exact error text on failure.
6. If Ready, switch Manager tabs, enter/exit Play once, and confirm checking
   does not loop indefinitely or block normal Unity shutdown.
7. Human closes Unity normally and records whether shutdown completes within
   30 seconds.

## Boundaries

- Unity start, interaction, Play transition, and shutdown are human-owned.
- Do not start hidden/background Unity, Unity MCP, BatchMode, process probes,
  alternate endpoints, or automatic retries.
- Do not modify Package production/test bytes during the visible scenario.
- Do not clean existing runtime/instances, stop processes, reinstall Provider,
  or mutate machine state without a new cause-specific authorization.
- Stop at the first CodeDB product failure and preserve the full visible error.
- A failure after the S20 closure gate is a product/runtime finding; do not
  repair it as a packaging hash typo.

## Evidence And Done

- Required evidence:
  - Package import/compile result;
  - Manager cold terminal state;
  - Configure Dependencies result when offered;
  - Ready/tab/Play/Edit observations when prerequisites pass;
  - normal shutdown result;
  - exact artifact identity above.
- Expected result: one complete golden path reaches stable Ready and exits
  normally without Package errors, indefinite checking, or main-thread work
  regression.
- Deferred: third-party consumer project, publication/tag/push, full regression,
  and Unity MCP remain separate gates.

## Handoff

- Initial golden-path handoff: READY / HUMAN_OPEN_PENDING.
- Current handoff is superseded by FIX 04 below. Do not open the validation
  project until the frozen source review and subsequent human disposition.
- Human authorization required: any product fix, cleanup, retry, commit, push,
  publication, or expansion beyond this scenario.

## FIX 01 - Post-Provider Error Provenance

The first human Configure Dependencies attempt reached post-Provider reconcile
but returned exit `4` with only the successful prerequisite line. Bounded source
diagnosis confirmed that Manager discards `AICodedbReconcileOutcome.LastCommandResult`
and synthesizes a new result from the truncated `Detail` field.

- Status: AUTHORIZED / CODER_PENDING
- Frozen HEAD: `9691074d48c68c0a4d27e61ce9b753912e0de78b`
- Change allowlist:
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Required behavior:
  - Provider failure remains unchanged.
  - Ready reconcile still reports success.
  - Non-Ready reconcile returns the authoritative failing
    `LastCommandResult` when present, preserving exit code, stdout, stderr,
    timeout, elapsed time, and fallback authorization.
  - A successful last command with a Non-Ready terminal state must retain its
    command evidence and add a bounded terminal-state explanation without
    claiming success.
  - Null/missing authoritative result retains a bounded synthetic failure.
- Evidence: direct test/source assertions, C# source-level compile shape, and
  two-file scoped `git diff --check` only.
- Explicitly not run: Unity, Unity MCP, EditMode, Package export, materializer,
  Provider installer, external retry, process probes, and full regression.
- Stop conditions: need to change lifecycle/materializer/runtime contracts,
  second independent cause, or inability to preserve the exact authoritative
  result within these two files.

## FIX 02 - Obsolete Instance Recovery Contract

Human Evidence 03 proved that the current Package can encounter a
Package-owned legacy instance selection with no `owner_identity_version` while
the machine prerequisite is already current. The existing product model maps
that state to generic invalid evidence and incorrectly offers Configure
Dependencies. This FIX is one continuous recovery-contract change; it must not
be split into isolated UI, lifecycle, or cleanup patches.

- Status: COMPLETE / COMMIT_DERIVED_PACKAGE_READY / HUMAN_SWITCH_PENDING
- Frozen HEAD: `50b131667b076998f48fedc4f991ff99b0adbd73`
- Change allowlist:
  - `com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs`
  - `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
  - `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
  - `com.rice.ai-codedb/Editor/AICodedbActions.cs`
  - `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  - `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

### Required Classification

- A legacy current-instance selection is reinstall-required only when it has
  the exact Owner Identity v1 field shape and its project identity, selection,
  instance manifest, immutable generation, worker hashes, and Package-declared
  generation disposition all validate.
- A partial v2 shape, unknown field, malformed identity, hash drift, escaped or
  reparse path, untrusted generation, or mismatched closure remains generic
  invalid/ambiguous and must not gain removal authority.
- No compatibility conversion or in-place upgrade of the legacy selection is
  permitted. The supported recovery is explicit integration removal followed
  by Package reinstall.

### Required Action Routing

- An authenticated obsolete instance state must produce a distinct
  reinstall-required attention reason before automatic Supervisor admission.
- `Configure Dependencies` is offered only for an actual missing Provider
  prerequisite. A current prerequisite plus any `NeedsAttention` state must
  not expose dependency installation as the recovery action.
- The primary recovery action for authenticated obsolete evidence is
  `Remove CodeDB Integration`; arbitrary invalid/ambiguous evidence exposes no
  destructive primary action.

### Required Removal Authority

- Preserve the existing authenticated v1/v2 Supervisor-authority removal path.
- Add one exact orphaned-v1 path only when no Supervisor control authority is
  present, the complete v1 selection and Package-owned closure validate, and
  every selected-instance holder is absent or provably stale.
- Revalidate the same selection fingerprint immediately before mutation.
- Remove only the already reviewed integration-owned targets. Do not stop a
  process, infer ownership from filenames, delete an unverified instance, or
  treat arbitrary invalid evidence as removable.
- Multiple/unknown control namespaces, live or ambiguous holders, incomplete
  closure, or identity drift remain fail-closed with zero mutation.

### Evidence Budget And Stop Conditions

- One bounded static/source batch, one focused removal/recovery L0 batch, and
  one scoped diff-check over the allowlist.
- No Unity, Unity MCP, EditMode, BatchMode, runtime mutation in the validation
  project, process probing outside fixture-owned evidence, automatic retry,
  commit, push, publication, or Verifier contact.
- Stop on the first independent production failure, need for an
  out-of-allowlist change, or inability to prove orphaned-v1 authority without
  weakening existing fail-closed behavior.

## FIX 03 - Host Action Thread Boundary

The human validation project imported and compiled the FIX 02 Package with no
errors. In CodeDB Manager, both `Inspect host files` and `Sync host files`
failed before the materializer started: `DisplayProgressBar can only be called
from the main thread` (exit `-1`). The Manager dispatches user commands to a
worker while the synchronous materializer and other command helpers still use
Unity's blocking progress bar.

- Status: COMPLETE / COMMIT_DERIVED_PACKAGE_READY / HUMAN_OPEN_PENDING.
- Base source commit: `2deb47bb833ac981a7d5f49c34bfc88da601ee15`.
- Change scope: `Editor/AICodedbHostPayloadMaterializer.cs`,
  `Editor/AICodedbActions.cs`, and
  `Tests/Editor/AICodedbManagerUiTests.cs` under the Package root.
- Keep Unity UI and confirmation dialogs on the Manager thread; execute
  materializer, Provider, and Host scripts on the worker. The Manager's Last
  activity panel owns user-action progress.
- Remove blocking Unity progress-bar calls from all worker-reachable command
  helpers, including Inspect, Verify, Sync, Upgrade, Redeploy, Remove, Install,
  Uninstall, and Reinstall paths. Preserve command arguments, timeouts,
  confirmation, cancellation, and result semantics.
- Verify the thread-boundary regression source test, scoped diff, and
  Package closure before exporting one commit-derived local Package.
- Resume one human-owned Unity golden path from Host initialization. If a new
  product failure appears, stop and record its exact output before changing
  another contract.
- FIX 03 source commit: `6cf673db600c02061a12684374d428d56e9cb5b3`.
- Current validation Package reference:
  `file:../../.artifacts/v0.3.0-preview.5-s21-fix03-6cf673d-final/package/com.rice.ai-codedb`.

## FIX 04 - Partial V1 Control Recovery

The next human DryRun reached the materializer and reported a v1 current
selection without `owner_identity_version`. Read-only inventory after Unity
shutdown found a hash-matched `poc.34` selection and immutable generation,
but no project stable wrapper. The versioned v1 control namespace contains
matching `COMMITTED` activation/operation records and a failed Supervisor
operation; its Supervisor state/lock pair is absent. Existing removal routes
reject this combination.

- Status: ACCEPTED_WITH_KNOWN_P1 / SOURCE_BASELINE. The targeted Verifier
  verdict remains FAIL; the user accepted the frozen snapshot with P1-01
  documented.
- User authorization: same-S21 continuous recovery-contract change, with the
  validation project closed. Only Package production/test files and S21 task
  records may change; no project runtime mutation, Unity, MCP, commit, or export.
- Keep this work within S21 as one continuous recovery-contract change.
- Authenticate the exact v1 selection, instance and generation closure,
  committed activation/operation binding, partial Supervisor evidence, and
  Package-declared predecessor identity before offering a recovery action.
- Treat a missing project stable wrapper as permissible evidence only for
  explicit removal; it must not make the instance operational or enable
  automatic convergence.
- Require fresh, clear holder evidence and an unchanged selection/control
  fingerprint immediately before mutation. Ambiguous, live, mismatched, or
  additional control evidence remains fail-closed.
- The only product action is human-confirmed `Remove CodeDB Integration`,
  followed by ordinary Package reinstall. Preserve user and external data,
  immutable generation evidence, and external processes.
- Add focused C# and PowerShell regression coverage for the exact partial-v1
  admission plus adjacent rejection cases; review the frozen result before
  exporting a new Package or repeating the Unity golden path.
- No project cleanup, manual JSON repair, Sync, or Unity retry is part of this
  source task.
- Frozen handoff: HEAD `6cf673db600c02061a12684374d428d56e9cb5b3`;
  ordered seven-file binary patch identity
  `c21502eb7d31bc3c2a058a53ef6e8198dcdbc9d8`.
- Focused PowerShell and source checks are recorded in `RESULT.md`. C# compile,
  EditMode, and the visible Unity golden path remain deferred. The next actor
  is Planner for a separately authorized next gate. The ACCEPT disposition
  alone did not authorize a commit; the subsequent scoped commit request does.
  No repair, Package export, Unity retry, or project operation is authorized.

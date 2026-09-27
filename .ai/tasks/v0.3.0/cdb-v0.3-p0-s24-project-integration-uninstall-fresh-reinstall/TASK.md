# Task: cdb-v0.3-p0-s24-project-integration-uninstall-fresh-reinstall

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0 preview
- Workflow: codedb-workflow-v2
- Status: ACCEPTED / NON_UNITY_EVIDENCE_ONLY
- Planner/Coder: current task, single writer
- Verifier: separate guarded review after a stable source snapshot
- Review mode: GUARDED
- Execution mode: CONTINUOUS_WITHIN_SCOPE
- Requirement source: `Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md`, S23 read-only activation diagnosis

## Objective

Make incompatible preview state recoverable by a confirmed, authenticated
project integration uninstall, followed only after a proved `Uninstalled`
terminal state by a fresh current-Package install. Do not implement automatic
cross-version Package upgrade.

## Scope

- In scope: independent uninstall eligibility versus runtime readiness;
  historical selection/activation/Supervisor authority; explicit removal
  transaction and recovery; fresh-install admission; Manager presentation;
  direct adjacent tests.
- User-initiated Uninstall and incompatible-version Remove/Reinstall are two
  presentation contexts for one classifier, durable intent, transaction,
  recovery, and cleanup authority. Do not maintain parallel mutation paths.
- Change allowlist: `Editor/AICodedbControlContract.cs`,
  `Editor/AICodedbActions.cs`, `Editor/AICodedbManagerWindow.cs`,
  `Editor/AICodedbHostPayloadMaterializer.cs`,
  `Editor/AICodedbEditorLifecycle.cs`,
  `Tools~/materialize-codedb-host-payload.ps1`,
  `Tools~/codedb-instance-engine.ps1`,
  `Tests/Editor/AICodedbEditorLifecycleTests.cs`,
  `Tests/Editor/AICodedbManagerUiTests.cs`,
  `Tests~/test-codedb-host-payload-materializer.ps1`, and
  `Tests~/test-codedb-package-boundary.ps1` under `com.rice.ai-codedb/`.
- User-authorized S24 continuation: the two added Editor paths carry only
  the read-only removal preflight command bridge and worker-owned cached
  admission result. `AICodedbStatusSnapshot.cs` remains outside the change
  allowlist; Manager callbacks remain cache-only.
- Read-only dependency closure: direct references only.
- Protected state: `UnityValidationProject/**`, its ignored runtime,
  `.artifacts/**`, machine Provider/Node, external MCP clients, unrelated
  dirty or untracked work, immutable generation bytes, and all user data.
- No real project removal, provider operation, Unity launch, Unity MCP,
  commit, push, tag, or publication in the Coder phase.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE, one product outcome and one consolidated
  result. The S23 predecessor state is a read-only diagnostic input, not a
  mutable test target.
- Authenticate activation and later Supervisor operation as separate temporal
  records. The activation/journal pair must share its historical runtime
  contract and exact selection/closure bindings; the later Supervisor record
  must independently bind project, selected instance/generation, failure,
  events, and holder state. A changed runtime hash alone cannot authorize
  removal or suppress a fully authenticated removal path.
- Keep ordinary runtime admission fail-closed; the uninstall exception must
  not become permission to operate an obsolete instance. Preserve unknown,
  conflicting, malformed, redirected, live, or ambiguous evidence.
- Check the uninstall terminal state before Install; never infer an empty
  integration from missing files alone. Current-Package fresh installation
  must publish its own committed activation and never adopt the old journal.
- Persist an exact removal intent before deactivating old control records.
  Bind project/state/operation, predecessor selection and activation, retained
  instance/generation closure, and holder constraints. `UNINSTALLED / PENDING`
  is a logical terminal state only with no active control or managed MCP
  registration; `COMPLETE` additionally requires proved physical cleanup.
  Fresh Install may proceed from authenticated pending cleanup only while the
  retained closure stays inert and cannot be adopted. Invalid intent or
  incomplete removal remains fail-closed.
- Do not infer recursive deletion authority from holder drain. The existing
  focused fixture includes dynamic index/sentinel bytes within the old
  instance and requires their preservation. Retain that instance closure
  byte-exact and inert under `UNINSTALLED / PENDING`; reclaim only an
  individually authenticated, intent-bound subset. Do not use the recursive
  retired-instance helper on the old directory or report `COMPLETE` because
  control records disappeared or holders drained.
- Keep the stable project MCP entry/wrapper identity. Disable only proved
  project-local CodeDB keys on removal and restore them against the new
  committed activation on Install. Do not require repeated Codex rebinding;
  reserve one controlled reconnect/new task for the later human integration
  gate only if dynamic configuration reload is unavailable.
- L0: affected PowerShell AST and focused partial-v1/removal/install scenarios,
  plus scoped diff check. Affected C# syntax/source or direct tests as available.
- Unity semantic compile/EditMode, real removal, local Package export, human
  golden path, and full regression are separately gated and NOT RUN here.
- Stop on new authority, protected-state dependency, or a third independent
  product cause; route reassessment instead of another micro-fix.

## Definition Of Done

- The observed predecessor shape is classified as removable only after both
  historical activation and later Supervisor failure are independently
  authenticated; adversarial mismatch fixtures still refuse without mutation.
- A confirmed synthetic uninstall reaches a proved `Uninstalled` state and
  allows one fresh current-Package install. Cancellation/partial failure does
  not admit Install; live/ambiguous holders and unrelated content survive.
  Pending retained closure has one durable, exact cleanup authority; a later
  drain reclaims only proved CodeDB-owned content without touching mutable
  unproved bytes or the new installation.
- Manager communicates the two-step route and never advertises removal as
  available when its independent preflight cannot establish authority.
- Evidence and deferred gates are recorded once in `RESULT.md`.

## Handoff

- Current task: `cdb-v0.3-p0-s24-project-integration-uninstall-fresh-reinstall`
- Current status: ACCEPTED / NON_UNITY_EVIDENCE_ONLY
- Next notification: UnityCodeDB v0.3 Planner/User
- Next action: plan the separately authorized C# compile/EditMode and human
  Unity integration gates before claiming live uninstall/reinstall acceptance.
- Human decision required later: C# compile/EditMode, real Unity interaction
  or removal, commit/export, push, and publication.

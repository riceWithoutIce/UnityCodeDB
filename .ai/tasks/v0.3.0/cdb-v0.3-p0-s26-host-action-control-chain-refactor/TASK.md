# Task: cdb-v0.3-p0-s26-host-action-control-chain-refactor

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0 P0
- Workflow: codedb-workflow-v2
- Workflow revision: 2.3
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep (pending dispatch)
- Verifier: not yet dispatched
- Review mode: RELEASE
- Execution mode: DURABLE_SESSION
- Execution profile: v0.3.coder.deep
- Delegation authorization: STANDING_WORKFLOW exists; this card does not dispatch a child
- Session policy: REUSE_ONLY
- Requirement source: `com.rice.ai-codedb/Documentation~/v0.3.0-p0-host-action-execution.md`, S26 amendment; S25 Gate C evidence

## Objective

Repair the Manager-to-Host action control chain as one continuous outcome:
durable action correlation across Editor and Package transitions, no fallible
runtime compilation after writer claim, explicit non-effect/terminal/unknown
classification, and one authoritative result owner per route. Preserve the
existing project integration uninstall and fresh-install safety contract.

## Scope

- In scope: Manager direct-action admission, one-shot writer startup and
  receipt, project-scoped action recovery, exception classification, and the
  adjacent Supervisor lookup boundary. Implement and verify the fault matrix
  in the S26 contract within this same task.
- Out of scope: Provider installation policy, materializer/instance mutation
  rules, Supervisor query scheduling, immutable generation transitions,
  general MCP transport replacement, HTTP/stdio adoption, and automatic replay.
- Change allowlist: `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`,
  `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs`,
  `com.rice.ai-codedb/Editor/AICodedbPaths.cs`,
  `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs` and
  `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs.meta` if a
  dedicated journal type is warranted,
  `com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1`,
  `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`, and
  `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`.
- Read-only dependency closure: direct references in `AICodedbActions.cs`,
  `AICodedbHostPayloadMaterializer.cs`, `AICodedbEditorLifecycle.cs`,
  `AICodedbSupervisorBridge.cs`, `AICodedbSupervisorProtocol.cs`, the S22 Host
  Action route record, the S24 reinstall contract, and S25 `RESULT.md`.
- Protected state: existing S25 admission/claim evidence, all project runtime
  and Provider state, immutable instances/generations, unrelated dirty files,
  `UnityValidationProject`, and external processes. Do not clean, rewrite,
  terminate, or retry any of them.
- Snapshot binding: source/test baseline HEAD
  `f71129e35aa2487ce7f69b45131d2e7456d5a0a9`; require a fresh scoped
  identity at Coder start and frozen result handoff. No prior S25 artifact is
  accepted as evidence for modified source.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE; this one task owns diagnosis, implementation,
  directly coupled repair, focused evidence, independent review, and a later
  separately authorized human Unity acceptance gate.
- Coder actions: preserve old evidence; implement project-stable action lookup
  without synthetic IDs, prepare the direct runner before claim, make
  authority-bearing results explicit, and retain Supervisor ownership. The
  one-shot nonresident model is the default, not a reason to weaken outcomes.
- Evidence scenarios: every row of the S26 fault matrix, including claim-to-
  child startup failure, exception after dispatch, full Editor exit model,
  Package-root change, corrupt records, and command/product separation.
- L0 tests: one focused `test-codedb-package-boundary.ps1
  -ManagerActionWriterOnly` batch extended with fault injection; one scoped
  source/contract check if needed. Synthetic fixture processes and exact
  fixture cleanup only; no real project action.
- Affected L1 tests: directly affected `AICodedbManagerUiTests` cases. Unity
  compile/EditMode execution remains NOT_REQUESTED until the human-owned gate.
- Explicitly not run now: Unity, Unity MCP, real Remove/Install, Provider probe,
  broad L0/L1, full regression, Package export, commit, push, and publication.
- Test rationale: the current S25 failure is post-claim/pre-child; recovery
  after full exit and Package replacement is not covered by the existing
  Reload-only Manager tests.
- Package identity/release closure: required only after source review and a
  separately authorized commit; export one commit-derived Package and verify
  its closure before asking for real Unity validation.
- Unity/external acceptance ordering: after reviewed source and Package
  closure, request one human-owned validation session for compile, focused
  EditMode, Remove terminal, authenticated `UNINSTALLED / PENDING`, and then
  separately confirmed fresh Install. Stop at the first ambiguous result.
- Mechanical corrections per scenario: 2; corrected semantic attempts per
  local scenario: 2; independent product causes before reassessment: 2.
- Active time budget: DEEP_60M per active role window; keep continuation in
  this task rather than creating microtasks.
- Output budget: V2_DEFAULT; broad search/full diff/full regression: FORBIDDEN.
- EditMode authorization: NOT_REQUESTED.
- Side-effect authorization: task-owned synthetic L0 fixture processes only
  after Coder routing; no real Unity or project/Provider mutation.
- Stop conditions: identity drift, need for a new executable/resident service,
  broader Supervisor or backend mutation authority, non-allowlisted source,
  or uncertain real action evidence. Return for structural reassessment.
- Mode-promotion triggers: DEFAULT_V2_1; no recursive delegation or concurrent
  Coder/Verifier edits. Model escalation: REQUEST_ONLY.

## Definition Of Done

- Expected result: S26 fault matrix is met by one stable source snapshot, with
  no weakening of S22/S24 admission, holder, deletion, or replay constraints.
- Required evidence: focused L0 and directly affected L1 when authorized,
  scoped diff/identity, one targeted independent Verifier review, then exact
  commit-derived Package and human Unity acceptance as separate gates.
- Deferred risks: HTTP/stdio transport selection and automatic cross-version
  Package upgrade remain separate research, not S26 acceptance substitutes.

## Handoff

- Current task: `cdb-v0.3-p0-s26-host-action-control-chain-refactor`
- Current status: READY; design frozen, no implementation begun
- Next notification: UnityCodeDB v0.3 Planner/User
- Next action: dispatch the bounded Coder task after commit and Project update
- Human decision or authorization required: later Unity,
  commit, Package export, push, tag, and publication remain separate gates

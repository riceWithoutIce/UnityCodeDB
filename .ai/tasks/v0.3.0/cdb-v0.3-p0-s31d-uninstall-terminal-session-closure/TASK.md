# Task: cdb-v0.3-p0-s31d-uninstall-terminal-session-closure

## Metadata

- Product/version: UnityCodeDB v0.3
- Workflow: codedb-workflow-v2, revision 2.6
- Status: COMPLETE WITH LIMITS / DELIVERY COMPLETE / TESTS AND MANAGER PASS / SHUTDOWN FOLLOW-UP DEFERRED
- Planner: current parent; Coder: task-scoped implementation role
- Verifier: required independent targeted read-only review
- Review mode: GUARDED
- Execution mode: FAST_SUBAGENT; user-approved task-local exception to the
  cross-layer DURABLE_SESSION default on 2026-10-17
- Execution profile: bounded lifecycle repair, inherited model settings
- Delegation authorization: TASK_SPECIFIC; user `批准执行` on 2026-10-17
- Session policy: SPAWN_BOUNDED; one Coder then one read-only Verifier
- Requirement source: user-agreed uninstall-terminal repair on 2026-10-17;
  latest `好的 同意` accepts the proposed repair boundary
- Prior routes: S31-C complete; S31-B and historical reconnect deferred

## Objective

An attributable completed current Uninstall operation closes its exact Manager
action. Supervisor handoff is a separate observation: failure/unconfirmed exit
must remain visible without turning a known backend terminal into Unknown or
holding the whole Manager action open indefinitely. A subsequent mutation still
requires its own existing ownership/admission checks. Normal completion and
window-reopen recovery use the same terminal policy. Backend success, handoff,
retained-content cleanup and current readiness remain separate facts.

### User-approved F1 Disposition — 2026-10-17

Following discussion of VERIFICATION.md F1, user `好的 同意` approves the
separation above and this same-task bounded repair/review. It supersedes the
original requirement that action closure itself waits for confirmed Supervisor
retirement. F1's swallowed handoff information remains a defect to repair;
action release from a trusted complete terminal is now explicitly allowed even
when handoff observation fails. Do not reinterpret this disposition as relaxing
identity/completeness, allowing a new mutation, or permitting process control.

Expected behavior: backend success plus failed handoff is presented as completed
uninstall with an explicit separate handoff warning. The current response's
failure code/detail must survive conversion and Manager display; it must not
alter the recorded backend exit/stdout/stderr or claim the process is alive
merely because state/lock retirement was not observed. Successful handoff keeps
ordinary completion; confirmed backend failure remains failure. Preserve the
normal no-second-online-lookup path and existing downstream mutation admission.
Reopen must not invent successful handoff from backend completion. Use existing
result/session presentation or a bounded read-only observation if needed; do not
add a new durable result store, rewrite backend history from the Bridge, or
turn handoff into a new historical recovery subsystem.

Cause and protected real attempt:
`../cdb-v0.3-p0-s30-current-version-lifecycle-acceptance/UNINSTALL-TERMINAL-ALIGNMENT-2026-10-17.md`
and `UNINSTALL-ACCEPTANCE-RESULT-2026-10-17.md` in that directory.

## Frozen Consumer Map

Supervisor operation history remains the backend result producer; existing
Manager metadata/index remains admission/release authority. No second result
store, fabricated direct-writer receipt or new lifecycle authority.

| Binding | Existing producer/anchor | Required consumption |
| --- | --- | --- |
| Exact action/context | Manager `action.json` and index: action ID, project/Package roots and keys, title | Validate admitted metadata. New adoption route applies only to the current `Uninstall CodeDB from Project` session. |
| Exact operation | Supervisor `manager-actions/<actionId>.json`: action ID, `operation_ids`, `latest_operation_id`; exact `operation-history/<operationId>.json` | Require one unambiguous Uninstall operation, matching map membership, filenames and record IDs. Never read global latest `operation.json` as its result. |
| Project/runtime | Map and operation: `project_identity`, `root`, `runtime` | Match admitted context and canonical control-contract runtime; reuse bounded JSON and path/redirect guards. |
| Package/command | Operation `name=materialize:Uninstall`, `key`; child `normalized_argv`/`argv_sha256`, Package-derived materializer `-File` and `-PayloadRoot`, `-Action`, `-ProjectRoot`, `-OriginatingOperationId`, `-OriginatingActionId`, mutation confirmation | Close exact invocation against admitted Package/context and command. No substring/path-presence inference or exit-code-only authority. |
| Original execution | Operation `owner_epoch`, `request_id`, `selected_instance_id`, `selected_generation_id`, `runtime_contract_sha256`; authenticated online Bridge identity/request | Validate original bindings and required formats/agreements, without requiring live state or current-instance after uninstall. Never substitute a later owner/selection. |
| Terminal result | Operation `state`, `phase`, `completed_at_utc`, `result.exit_code/stdout/stderr/timed_out`; overflow/drain fields if produced | Only complete, non-timeout, non-truncated terminals release admission. Confirmed failure ends as failure, never as successful uninstall. |
| Normal return | Authenticated original command/operation response and validated bindings | Preserve explicit bound provenance through Bridge/Lifecycle/Manager; existing authoritative/evidence booleans alone are insufficient. No second live lookup for the already validated result. |
| Reopen/release | Exact-action durable evidence, same validator/policy; existing session release APIs | No Supervisor startup, Uninstall replay, new writer or index deletion. Preserve direct-versus-Supervisor conflict checks. |

First establish whether the existing invocation closes every required anchor.
Reuse it when sufficient. If explicit fields are necessary, add only the same
anchors to the existing Supervisor producer/public envelope and update its
direct consumers/tests together. RESULT must state the exact serialized field
map. Missing old anchors stay unconfirmed; never invent/backfill them. Stop if
the map cannot close within the existing authority. Automatic recovery of the
preserved pre-repair S30 action is not promised.

## Scope

Change allowlist, relative to `com.rice.ai-codedb/`:

- `Editor/AICodedbSupervisorBridge.cs`
- `Editor/AICodedbEditorLifecycle.cs`
- `Editor/AICodedbManagerWindow.cs`
- `Editor/AICodedbProcessRunner.cs`: command-result evidence type only, if
  needed; incoming timeout/runner hunks are protected
- Optional dedicated `Editor/AICodedbSupervisorTerminalEvidence.cs` and `.meta`,
  solely for shared validator/provenance representation
- `Tools~/codedb-project-supervisor.mjs`: coupled terminal binding/publication
  only, if needed
- `Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `Tests/Editor/AICodedbManagerUiTests.cs`
- `Tests~/test-codedb-project-supervisor.mjs`: focused terminal coverage and
  bounded selection entry only; do not run the full suite
- `Documentation~/v0.3.0-p0-host-action-execution.md`: append this terminal
  contract only; preserve incoming unrelated edits
- Role-owned task records and one task-local evidence driver

Read closure: DIRECT_REFERENCES_ONLY, including existing journal, receipt/action
metadata reader, paths, strict JSON, canonical control/runtime contracts,
instance identity and directly called Supervisor helpers. No broad audit.

Protected state: original S30 pending action and seven-record snapshot; real
project/machine runtime/config records; unrelated dirty files; all immutable
Payload generations; previous evidence; Provider assets and processes.
BASELINE-SHA256.txt binds incoming bytes. HEAD is
`cc49c95e84945308385f64640963716d93d070ea`, not the dirty snapshot.

Out of scope: historical compatibility/reconnect, Provider/S31-B, PID/process
termination, S30 reset/manual index release, UI redesign, generation migration,
real Install/Uninstall, Unity/MCP/BatchMode, commit/export/reference switching.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE
- Approved stages/user grant: `好的 同意` approved the narrow repair boundary;
  subsequent `批准执行` approves the proposed task-local Coder -> read-only
  Verifier route, including its FAST_SUBAGENT exception. Parent remains active,
  handles questions and waits through both terminal stages. No further stage
  approval is needed inside this unchanged envelope. The later F1 discussion
  and `好的 同意` approve the amended responsibility contract above, reuse of
  the stopped Coder, and F1-only independent repair review with the stopped
  Verifier. No repeat route approval is required for this same task.
- Delivery authorization: user explicitly accepted and authorized precise commit,
  exact export/checks and S30 reference switch on 2026-10-17 per DELIVERY-PLAN.md;
  no Unity launch, real lifecycle action, push, publication or release promotion
- Coder actions: shared bound terminal validation; preserve normal returned
  evidence; exact-action durable consumption on reopen; existing release and
  competing-writer guards; attributable snapshot and focused result
- L0: original affected Editor/tests compilation with existing local tools;
  focused validator and Manager-session tests
- Affected L1: production Supervisor serialization -> real C# reader -> exact
  session release on task-owned records with Supervisor state absent
- Scenarios: normal terminal with zero second online lookup; idempotent reopen
  with zero backend dispatch; complete failure remains failure; missing/pending,
  mismatched action/operation/project/Package/command/owner, competing writers,
  timeout and incomplete output cannot unlock
- Use the real producer/reader/release boundary; handwritten success strings
  or replacement readers are insufficient. Copied real evidence stays immutable.
- Existing tool bindings: compiler/reference declarations from
  `.artifacts/tests/s31c-f1-20261017-a/manifest.json` and response template
  `.artifacts/tests/s31b-r2/build/editor.rsp`; no new downloads/restore
- Output: fresh children of `.artifacts/tests/s31d-uninstall-terminal/`; no
  development artifacts in system TEMP, user profiles or global worktrees
- Native Unity boundary: classify a standalone native-session limitation once
  for later human Unity; no isolation repair or invented Unity stubs
- Paths: admitted context/canonical contracts; no machine-specific literals
- Generation transition: NONE; Package delivery gates deferred to a separately
  authorized exact accepted snapshot, never dirty Payload
- Mechanical corrections per scenario: 2
- Corrected semantic attempts per scenario: 2
- Independent product causes before reassessment: 2
- Active time budget: STANDARD_30M per owning execution window
- Output budget: V2_DEFAULT
- Broad search/full diff/full regression: FORBIDDEN
- EditMode authorization: NOT_REQUESTED
- Side effects: task-owned fixture/output files and bounded existing compiler/
  test tooling only; no real project/config/runtime writes or process control
- Stop: authority/file/side-effect scope expands; identity map cannot close;
  isolation becomes the objective; bounded attempts exhausted
- Mode-promotion triggers: DEFAULT_V2_1
- Structural guard: starting repairs 0/2, independent causes 1/2,
  diagnostic-only checkpoints 0/3; immediate structural triggers apply
- Model escalation: NONE

## Definition Of Done

Stable source snapshot, incoming/final hashes and changed-hunk ownership;
focused evidence with precise limits; one independent targeted Verifier report.
Return findings together for User ACCEPT/FIX/DEFER/STOP. State whether original
pre-repair records have sufficient anchors. Source/standalone evidence never
implies human Unity, delivery or actual reinstall acceptance.

## Handoff

- Current task: S31-D uninstall terminal/session closure
- Current status: COMPLETE WITH LIMITS / TESTS AND MANAGER PASS / SHUTDOWN MIXED;
  one additional user-reported shutdown blockage, follow-up remains deferred
- Next notification: current parent Planner/User
- Next action: align the next real lifecycle baseline/operation. HUMAN-RESULT.md
  records the user report, preserved old-action screenshot and read-only checks;
  DELIVERY-RESULT.md records the completed exact delivery.
- Human decision required: next bounded real-operation/baseline route; old-action
  reconciliation remains separate and is not implicitly authorized

### Stable Snapshot Admission — 2026-10-17

Coder reported terminal completion and stopped. Parent verified the ten final
file hashes in RESULT, unchanged Lifecycle hash, unchanged HEAD and final
attempt-c manifest hash. Scoped ProcessRunner diff preserves the three incoming
runner hunks; this task adds only command-result evidence fields. All seven
original copied S30 evidence hashes match the parent preflight. No unchanged
Coder test was rerun by parent. Independent review is admitted for the frozen
terminal claims only; no source delivery or real-operation authority is added.

F1 repair admission: Coder stopped after its first successful focused repair
run. Parent verified all ten final F1 file hashes, attempt-f1-a manifest, and
preservation of the original VERIFICATION.md and attempt-c manifest hashes.
ProcessRunner retains its incoming runner hunks; task edits remain within its
command-result type. No unchanged test was rerun by parent. The targeted repair
review evaluates the user-amended responsibility contract, not the superseded
post-retirement-only release requirement.

Final consolidation: VERIFICATION-F1.md reports PASS / F1 CLOSED / no new
findings and stops review. Parent confirmed the ten final file hashes remain
unchanged, HEAD remains the baseline and staged index is empty. All seven
original copied S30 evidence hashes still match preflight. No unchanged test
was rerun. Human Unity rendering, real handoff/backend and later-operation
acceptance remain deferred; the old S30 missing-evidence limitation remains.

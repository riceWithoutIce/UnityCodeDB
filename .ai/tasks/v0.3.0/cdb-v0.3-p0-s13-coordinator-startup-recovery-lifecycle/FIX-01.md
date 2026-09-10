# S13 FIX 01: Coordinator Bootstrap Admission

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Status: `READY_AWAITING_DISPATCH`
- Owner profile: `v0.3.coder.deep`
- Review profile: `v0.3.verifier.deep`, only after a passing corrected visible
  snapshot and explicit Planner routing
- Phase: Runtime Release Gate; Discover Read has not started
- Validation gate: Planner confirmed zero matching `UnityValidationProject/`
  Unity processes immediately before this card was created

## Frozen Input Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- Committed HEAD: `9aada838e26879810a4f79760273ca66340ebf12`

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/TASK.md` | `12747` | `a69f5f5561ec238198de730ccfd3265f77eddd39f3459671d00c17fb55e13da6` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/RESULT.md` | `15187` | `8c1afd2c739c440d261d3a2916de892b68f852c23ed8550100b1b9dc8313ce71` |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `143287` | `6e1af84a0e244440587d8349b680e1a63b8a8395c010de8402d316e85301ae70` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `189281` | `dcc5b4254b678ff3b8d4924ac32eb5ba7590fa42ddbd3b460a28eb47fc9734ea` |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | `25291` | `775142faa711431f89d80cfd4694eeb052b11a43f224ee284abf09bd208392e4` |
| `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs` | `47442` | `12b7ce93dd6dc168d35080e56394b1d2b40f6e9077b27a6554b5f351765cfa8e` |
| `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs` | `122662` | `efde2a5ca6318466ffe31b51172e49301dcff9656881e9f83179492b6bba3a7f` |
| `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` | `128166` | `d7567cda79add3a1717c861f542d9516e18cb483fe44220da1b704931c7dd176` |
| `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs` | `67313` | `82fe3eb07c3ef88dde193b73e00cb6377d24334bde0b4402e63f7ee3d9223a50` |

Identity drift before work is a hard stop. Do not repair drift, reset the
worktree, or substitute a different baseline.

## Confirmed Finding

The Phase A change did not close the fresh Cold Start path.

- The new admission path requires trustworthy current prerequisite evidence
  and an already-published Editor lease before the first Supervisor Probe.
- Lease refresh still publishes only when the current-instance store returns
  an instance whose reviewed contract permits Editor lease publication.
- The corrected visible Cold Start passed project/version and Package compile
  gates, then ended at `NeedsAttention` with `supervisor_pid=0`,
  `coordinator_pid=0`, no selected-instance evidence, no materializer command,
  and the detail `Selected instance coordinator is not operational.`
- The added tests inject `editorLeasePublished` as a Boolean. They do not
  exercise the real fresh-start path that must discover a valid lease target,
  publish the session lease, and then admit the Supervisor/coordinator.

The runtime aggregate proves that admission did not establish the Supervisor.
It does not prove why lease publication remained unavailable. Do not assume a
missing current instance, alter policy, or create a new lease authority before
the exact source-owned branch is classified.

## Objective

Close the bootstrap dependency without weakening ownership or fail-closed
behavior:

1. Determine the exact pre-Supervisor disposition after the independent DryRun:
   prerequisite not trustworthy/current, integration not eligible, current
   instance cannot publish a lease, lease publication did not produce this
   session's file, or a later admission gate suppressed the Supervisor.
2. Make that disposition deterministic and testable. If runtime evidence must
   expose it, add only a stable sanitized category or reason code. Never expose
   paths, command lines, raw stderr, tokens, runtime documents, or machine
   identity.
3. Correct only the confirmed branch so a valid installed fresh Cold Start can
   establish the reviewed Editor lease and admit exactly one authenticated
   Supervisor/coordinator.
4. Preserve the existing S12 Probe/Upgrade re-admission behavior and all
   prerequisite, migration, invalid-state, ownership, and main-thread safety
   boundaries.

## Required Regression Coverage

The focused tests must model the real ordering, not only the final Boolean:

- current prerequisite plus an eligible trusted current/previous instance can
  select the reviewed lease target, publish this session's lease, and then
  allow one Supervisor admission;
- absent, invalid, ambiguous, or ineligible instance evidence cannot fabricate
  a lease path or start the Supervisor;
- missing or untrustworthy prerequisite evidence remains fail-closed;
- failed lease publication remains fail-closed and does not enter an automatic
  retry, direct materializer fallback, or Reinstall path;
- an already-published authenticated session lease preserves the established
  admission path;
- the admitted path remains single-owner and performs no prohibited main-thread
  filesystem, process, lock, IPC, PowerShell/Node, indexing, or full-status
  work.

If the valid fresh-install state truly has no reviewed instance-scoped lease
target, stop with `BOOTSTRAP_AUTHORITY_DECISION_REQUIRED`. Do not invent a
project-level lease, weaken coordinator lifecycle demand, materialize before
authenticated admission, or mutate immutable coordinator policy.

## Writable Surface

Default expected writes:

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- the parent task `RESULT.md`, append-only for FIX 01 evidence

Conditional writes are permitted only when the confirmed branch requires a
sanitized disposition or an existing Supervisor contract correction:

- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`
- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`

Record why each conditional file became necessary before editing it. Any other
write requires a new Planner/User decision.

## Read-Only Boundaries

- The parent `TASK.md`, this `FIX-01.md`, the existing `RESULT.md`, and the S12
  `DECISION.md` may be read as task evidence.
- The exact coordinator entry points under
  `com.rice.ai-codedb/Payload~/Generations/poc.34/` may be read only to confirm
  their existing lifecycle-demand contract. The generation is immutable.
- Do not read or enumerate `UnityValidationProject/.codex/` or
  `UnityValidationProject/AIWork/`.
- Do not inspect user-level Codex configuration, raw runtime state, tokens,
  unrelated Unity projects, or unrelated repository changes.

## Execution Budget

- Use targeted symbol reads only inside the listed source/test files. No
  repository-wide search, full diff, or repeated Git inspection.
- Static/source-contract evidence: one accepted batch, maximum 60 seconds and
  24 KiB captured output.
- Focused Node L0: at most one batch, maximum 30 seconds and 16 KiB captured
  output, only if Node production/test changed or the exact correction depends
  on the preserved Supervisor admission contract.
- A command-construction or fixture-only failure may receive one corrected
  retry only when no production assertion ran. Any independent production
  failure stops the task.
- Run one final `git diff --check` scoped only to files changed by FIX 01.
- C# L1 and Unity EditMode are `NOT_AUTHORIZED / DEFERRED`. Request explicit
  human authorization later if focused EditMode becomes necessary.
- Do not start or operate Unity, Unity Hub, Unity MCP, BatchMode, or any
  background validation process. Do not stop any process.
- Do not commit, push, contact Verifier, or enter Phase B.

## Preserved Contracts

- `Payload~/Generations/poc.34/` remains byte-identical.
- No automatic Reinstall, direct materializer fallback, second command owner,
  unbounded retry, or materialization before authenticated admission.
- Missing prerequisite, Uninstalled, invalid integration, migration attention,
  and current-contract precedence remain unchanged.
- Existing authenticated Supervisor and selected-instance continuity remains
  preferred; unrelated/external processes are never stopped.
- Manager remains cache-only and all prohibited main-thread work remains zero.

## Stop Conditions

Stop and report without a partial policy workaround when:

- frozen input identity drifts;
- the exact blocked branch cannot be classified within the bounded source and
  sanitized evidence paths;
- the fix requires protected runtime inspection, a path outside the writable
  surface, a new lease authority, or changed immutable coordinator bytes;
- focused evidence exposes an independent production failure;
- the command/time/output/retry budget is exhausted.

## Completion And Handoff

Append one `S13 FIX 01` section to the parent `RESULT.md` containing:

- confirmed branch and why the previous Phase A diagnosis was incomplete;
- exact files changed and pre/post bytes plus SHA-256;
- static and conditional Node evidence with command, exit, wall time, batch,
  retry, and bounded output summary;
- explicit `NOT RUN / DEFERRED` boundaries;
- one status: `FIXED_READY_FOR_PHASE_B`, `BLOCKED`, or `FAILED`.

If `FIXED_READY_FOR_PHASE_B`, stop and notify `UnityCodeDB v0.3 Planner`. The
next action is a human decision to open the existing `UnityValidationProject/`
with Unity `2022.3.47f1` for one separately authorized corrected visible
scenario. Do not open it or dispatch Verifier automatically.

If `BLOCKED` or `FAILED`, stop and notify Planner with the exact decision
required. Do not continue into another fix or runtime attempt.

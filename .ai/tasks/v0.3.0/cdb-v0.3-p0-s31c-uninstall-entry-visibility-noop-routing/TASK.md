# Task: cdb-v0.3-p0-s31c-uninstall-entry-visibility-noop-routing

## Metadata

- Product/version: UnityCodeDB v0.3
- Workflow: codedb-workflow-v2, revision 2.6
- Status: COMPLETE / SOURCE ACCEPTED WITH LIMITS / DELIVERY PASS / HUMAN S31-C ACCEPTANCE PASS
- Planner: current parent
- Coder: task-scoped implementation role
- Verifier: required targeted read-only review after a stable Coder snapshot
- Review mode: GUARDED for the bounded UI/action contract
- Execution mode: FAST_SUBAGENT — task-local route exception approved after
  disclosure that historical Coder/Verifier instances were unavailable
- Delegation authorization: TASK_SPECIFIC, user approval on 2026-10-17
- Session policy: SPAWN_BOUNDED; one Coder then one read-only Verifier
- Requirement source: User-approved narrow uninstall-entry task after the S31-B
  Provider readiness route was deferred
- Related routes: S31-B remains `PARTIAL / BLOCKED — NOT ACCEPTED`; S31-A
  reconnect follow-up remains deferred

## User-aligned UI Contract — 2026-10-17

The user accepted the state-based wireframe and instructed continuation, with
human experience feedback after delivery:

- Ready: Overview primary action is `Uninstall CodeDB from Project`.
- NotIntegrated / Uninstalled: Overview primary action remains `Install CodeDB`.
- NeedsAttention: retain the existing fresh-install recovery priority; otherwise
  show Remove Integration when its existing route applies, or Uninstall.
- The header menu always offers Uninstall, independently of cached readiness,
  removal preflight, or ownership uncertainty. Admission remains inside the
  action; ambiguous evidence never grants mutation authority.
- A repeated click while an action is busy observes its progress and must not
  create another confirmation, session, or writer.
- A confirmed no-install request reports that nothing needs uninstalling. Use
  the existing canonical project-integration reader, not a new directory-based
  authority. Unknown/conflicting evidence must produce a clear refusal.
- A local no-op/refusal must complete through the existing Manager evidence
  boundary; it must not leave a durable action waiting for a writer that was
  never dispatched or manufacture a successful uninstall terminal.

## Objective

Make the CodeDB uninstall entry consistently discoverable and reachable while
keeping execution admission inside the uninstall action. The UI must not
silently hide the entry merely because the current product state is unknown,
uninstalled, unauthenticated, or awaiting preflight. A click must produce an
explicit internal outcome and must not start duplicate work while an uninstall
action is already running.

## Scope

- In scope:
  - narrowly separate uninstall-entry
    visibility from uninstall execution admission;
  - keep the Manager context/menu entry visible for the supported CodeDB
    surface, with execution reasons shown after clicking rather than disabling
    the entry based on cached admission;
  - route a click to the existing uninstall action/session boundary;
  - return an explicit no-op or blocked outcome for no installation, no current
    instance, or unresolved ownership instead of silently hiding the entry;
  - preserve the existing busy/in-flight guard so repeated clicks do not start
    concurrent uninstall actions;
  - add only focused Editor tests for visibility, click reachability, no-op or
    blocked classification, and duplicate-trigger prevention.
- Out of scope:
  - owned-runtime stop, PID or process termination, deactivation transactions,
    terminal readers, or reconnect recovery;
  - Provider/model readiness or any S31-B production-equivalent fixture;
  - real Install/Uninstall, Unity, MCP, BatchMode, package export, reference
    switching, release promotion, or human acceptance;
  - historical orphan/candidate recovery and compatibility fallbacks;
  - changing the product's ownership or identity authority.
- Change allowlist: `AICodedbManagerWindow.cs`, `AICodedbActions.cs`,
  `Tests/Editor/AICodedbManagerUiTests.cs`, and only assertions in
  `Tests/Editor/AICodedbEditorLifecycleTests.cs` directly consuming the changed
  availability predicate; task records and one task-local non-Unity evidence
  driver may be updated throughout. No PowerShell/runtime source changes.
- Read-only dependency closure:
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Editor/AICodedbActions.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
  - the current Manager action/session and product-status contracts directly
    called by those files
- Protected state: all unrelated dirty source, package generations, validation
  projects, S31-A/S31-B evidence, machine Provider files, and external
  processes.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE
- Approved stages and user grant: after diagnosis and the UI wireframe, the
  user said `好的 可以人工体验后再给反馈。我们继续` on 2026-10-17.
  This approves the bounded source implementation and focused non-Unity
  evidence above. The user subsequently approved `Coder → Verifier` after the
  parent disclosed that new instances were required. This authorizes the
  bounded sequential route only, with the current configured model inherited;
  it does not authorize delivery or a real operation.
- Delivery authorization: user `同意 accept` on 2026-10-17 accepts the reviewed
  four-file snapshot and authorizes DELIVERY-PLAN.md steps 1–4 together.
  This supersedes the original implementation-only exclusions for those steps;
  Unity, real Install/Uninstall, process termination, push and release remain excluded.
- Coder actions: inspect the current visibility predicate, menu/context
  construction, action/session entry point, and focused tests; produce an
  attributable snapshot only after implementation is explicitly authorized.
- Evidence scenarios:
  1. entry visibility for ready, uninstalled, unknown, and retained/recovery
     presentations;
  2. click reaches the existing uninstall action/session boundary;
  3. no-install/no-authority produces an explicit no-op or blocked result;
  4. repeated click while busy does not create a second action.
- L0 tests: compile current original C# source and execute only the directly
  affected UI/action tests with existing local compiler/runtime tools, without
  Unity Editor startup or package restore/network acquisition. Bind source
  inputs and references to the snapshot; preserve earlier evidence. Exercise
  the canonical reader on task-owned fresh/ambiguous fixtures, action dispatch
  counters, busy/duplicate behavior, and local disposition completion.
- Affected L1 tests: none authorized by this task.
- Explicitly not run: Unity, real Install/Uninstall, Provider, runtime stop,
  package export, reference switching, and release checks.
- Test rationale: prove the UI/action boundary without conflating visibility
  with deep lifecycle admission.
- Mechanical corrections per scenario: 2
- Corrected semantic attempts per local evidence scenario: 2
- Independent product causes before reassessment: 2
- Active time budget: STANDARD_30M
- Broad search/full diff/full regression: FORBIDDEN
- EditMode authorization: NOT_REQUESTED
- Side-effect authorization: NONE
- Stop conditions:
  - diagnosis shows the requested behavior depends on owned-runtime stop,
    Provider readiness, or a new authority;
  - the entry can only be made visible by weakening identity/ownership guards;
  - a test requires real project mutation or an external process;
  - the same focused path fails after the bounded allowance.
- Escalation triggers: any new external dependency, historical fallback,
  product-wide status redesign, or route reassessment under the isolation spec.
- Structural escalation guard: repairs <count>/2; independent causes <count>/2;
  diagnostic-only checkpoints <count>/3; immediate structural triggers apply.

## Definition Of Done

- Expected result: a stable, attributable source snapshot showing the uninstall
  entry's visibility and action admission are separate, with explicit no-op or
  blocked outcomes and duplicate-trigger protection.
- Required evidence: focused source diff, affected test results or a precise
  blocked classification, and a Coder RESULT containing Base SHA/Head SHA and
  hashes of the incoming dirty and final source. HEAD alone is not the dirty
  snapshot. No commit is authorized to establish provenance.
- Deferred risks: owned runtime stop, deactivation, Provider readiness, real
  Unity lifecycle, package/release gates, and reconnect recovery remain open.

## Handoff

- Current task: S31-C uninstall entry visibility/no-op routing
- Current status: COMPLETE / SOURCE ACCEPTED WITH LIMITS / DELIVERY PASS / HUMAN S31-C ACCEPTANCE PASS
- Next notification: current parent Planner/User
- Next action: align a separate bounded real-uninstall acceptance plan with
  User; no further S31-C repair, review or repeat testing. See HUMAN-RESULT.md.
  F2 stays FOLLOW-UP. Native reader/session and real backend/Unity remain
  NOT RUN; no further isolation repair or review is required for this route.
- Human decision or authorization required: none to close S31-C. A subsequent
  real-uninstall operation requires its own frozen scope and authorization.

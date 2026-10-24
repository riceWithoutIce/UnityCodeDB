# Task: cdb-v0.3-p0-s31a-durable-uninstall-request-ui-closure

## Metadata

- Product/version: UnityCodeDB v0.3.
- Workflow: `codedb-workflow-v2`, revision 2.6.
- Status: `PARTIAL / NOT_ACCEPTED`.
- Predecessor: S31 A2, `PARTIAL / INCOMPLETE / NOT_ACCEPTED`; see the
  [S31 result](../cdb-v0.3-p0-s31-project-uninstall-workflow/RESULT.md).
- Planner: current parent. Existing historical_handoff_coder is terminal;
  read-only Verifier was not admitted because the acceptance gate is incomplete.
- Execution mode: to be selected at dispatch; no durable-session rebinding or
  new child is authorized by this task card.
- Delivery/live authority: none. No commit, package export, reference switch,
  Unity operation, real Install/Uninstall, or live process control.

## Objective

Close only the project-scoped durable Uninstall request path from confirmation
through reload/reopen and terminal Manager presentation. One request must remain
the owner across windows and Domain Reload, prevent automatic mutations while it
is unresolved, and restore its truthful terminal disposition without replaying
effects. This task does not implement or re-audit runtime force-stop or the
complete configuration removal transaction; those belong to S31-B.

## Frozen behavior

1. A confirmed Uninstall creates or attaches to one project/request identity
   under the existing action index lock. Concurrent windows and repeated clicks
   attach to that request; they do not create a second writer, confirmation or
   cleanup pass.
2. `REQUESTED`, `EXECUTING`, `UNKNOWN` and terminal dispositions remain
   attributable across Domain Reload, Manager close/reopen and tab changes.
   Reload invalidates only local waiters; it does not release ownership or
   replay the request.
3. The startup/reconnect/Install/maintenance paths observe the same request
   fence. An unresolved request remains fenced. An Unknown or failed result is
   shown as such and requires a separately confirmed retry; it is never silently
   replayed or treated as Uninstalled.
4. The Manager restores the recorded terminal result after reopening and keeps
   the callable entry and correct enablement/reason visible. Terminal observation
   is read-only; repainting and tab switching never confirm or execute.
5. Existing Install, Remove and Repair action records continue to use their
   existing ownership and terminal readers. The S31-A change must not weaken
   their admission or turn a stale cached status into permission.

## Source/test allowlist

Only these files may change, and only where directly required by the behavior
above:

- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbActions.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorLauncher.cs`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorRequestQueue.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`

Read-only dependency closure is limited to direct status/context types, existing
action readers, the current locator/path helpers and the named test harnesses.
If a PowerShell, Node, materializer, generation, Payload or additional source
file is required, stop and report that concrete dependency before editing it.

## Evidence plan

Use original production writers/readers and focused task-owned fixtures. Do not
claim Unity or Editor runtime evidence from a compiler or a reflection runner.

- Original C# source and affected Editor.Tests compile from the accepted input.
- Two callers/windows admit the same request and observe one owner/action id.
- Domain Reload/reopen during `REQUESTED` and `EXECUTING` retains the fence and
  does not dispatch a duplicate.
- Terminal `Uninstalled`, `NoActionNeeded`, `Unknown` and failed dispositions
  restore through the existing Manager/session readers after reopen.
- Unknown/failed observation does not auto-replay; a separately confirmed retry
  creates the next admitted request only under the declared classification.
- Startup/reconnect/Install/maintenance admission remains fenced until the
  request reaches its allowed terminal disposition.
- Nearest Install/Remove/Repair journal and stale-UI regressions remain valid.

Semantic evidence must be run on the final source bytes. Compilation, source
regexes and hand-built success markers are insufficient. Unity/MCP/BatchMode,
real project lifecycle, native process control and Package delivery remain
unrun and out of scope.

## Protected state and stop rules

Preserve the original dirty G: workspace, accepted exact617/exact S30 Packages,
S30/S29 projects, receipts, Payload generations and all external processes.
Use an isolated overlay derived from the accepted source or the S31 A2 frozen
snapshot; do not copy WIP back into the main source tree as delivery.

Stop before editing when the fix requires S31-B runtime ownership/force-stop,
the complete uninstall transaction, a new generation, a new persistent queue,
or a broader compatibility route. Stop after the first unresolvable identity or
record-consumer contradiction and return it for alignment.

## Acceptance and handoff

Source acceptance requires the full frozen request/reload/UI behavior and its
focused semantic evidence on one attributable final snapshot. A partial result
remains `PARTIAL / NOT_ACCEPTED`; no subset is promoted. Only after a stable
Coder result may the already-authorized read-only Verifier be considered, and
only after an explicit dispatch decision. Delivery and human Unity acceptance
remain separate later gates.

Dispatch record — 2026-10-16: User explicitly authorized start. Existing
historical_handoff_coder is working in the isolated checkout
`<isolated-worktree>`, with a bounded
Coder ceiling of 60 minutes. The parent copied only the eight A2-frozen
allowlisted C#/test inputs and this task card into that checkout. No Verifier is
admitted yet; it requires a stable terminal Coder result and a separate parent
snapshot check. No delivery or live-environment authority was added.

Current task: cdb-v0.3-p0-s31a-durable-uninstall-request-ui-closure
Current status: PARTIAL / NOT_ACCEPTED
Next action: align an Editor-thread evidence continuation or defer this partial
snapshot; no Unity action or delivery is implied.

## Terminal handoff — 2026-10-16

Coder froze the isolated source at the bounded window with RESULT SHA256
`b9970d1c9e95421d3b431a15f3487c6848c5d815c32437eaf7314778380966ad` and stopped.
Editor and Editor.Tests compilation plus six focused seam tests passed. The
Editor-main-thread reload/session/terminal scenarios were UNRUN, so the full
S31-A gate is not met. No Verifier, Unity, real mutation, delivery or process
operation occurred. The exact RESULT was copied to this task directory; no
source was copied to the main worktree.


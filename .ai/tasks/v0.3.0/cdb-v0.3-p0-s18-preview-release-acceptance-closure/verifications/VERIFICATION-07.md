# S18 Bootstrap Admission Refactor - GUARDED Verification 07

## Verdict

BLOCKED / FROZEN_IDENTITY_DRIFT. Semantic review was not entered.

## Frozen identity admission

- HEAD: `8313d0902945632f72cce3b07ea4eda92da59631` (matches).
- `Editor/AICodedbActions.cs`: expected `b987efa1010b612fb4019109b43bd7574c05aa571d8b299f7febd32f566eea87`; observed `73a9d61eeb39089e6a0dd05a019de395f698bb5cb7a07b0a6e27e968450f7570` (drift).
- `Editor/AICodedbEditorLifecycle.cs`: expected and observed `a2bee0a036dde2f051c9b1d1468dcb6a8a71271955e3908ff60e06444f30119f`.
- `Editor/AICodedbManagerWindow.cs`: expected and observed `15b3a144bb6078c7044bce8c7897edd09fb9282d2fffb2c9450cd974bcb0757f`.
- `Tests/Editor/AICodedbEditorLifecycleTests.cs`: expected `98b49cc039d5f088e009f8882d533c37fb4292570a4ff5e46d699e88bc56c719`; observed `2d8f3c3c4878aa2c3fa0b9a15ca119c4884e846f5a6341f6f7cf8519e6d5a91a` (drift).
- `Tests/Editor/AICodedbManagerUiTests.cs`: expected `9371644718cd0e550072b1709f084bd4ec5ee60faec29eead0ef47862de9178e`; observed `a840d696dbfd3693187ae51cfc9bcfe5d07e43c9ae3a263ce740ee0d72353802` (drift).

## Findings and evidence boundary

The frozen input is not the stated five-file snapshot. No semantic BLOCKER/P1/P2/FOLLOW-UP finding is asserted; the identity admission failure alone blocks this verification. Coder's recorded static 14/14 and scoped diff-check cannot be attributed to the observed mixed identity. No tests were rerun. Unity/EditMode/C# compile, external project/runtime/Provider/process, Unity MCP/CUA, and full regression were NOT RUN / DEFERRED. No production or test files were changed.

## Next role

Planner should reconcile the Coder evidence with a single stable five-file snapshot and explicitly re-freeze its identity before Verifier re-entry. Planner/User then decides ACCEPT / FIX / DEFER / STOP; this report is not an acceptance verdict.

---

## Replacement Frozen Admission And Semantic Review - 2026-09-22

The replacement admission was checked once after the Coder stopped writing:

- HEAD: `8313d0902945632f72cce3b07ea4eda92da59631` (PASS).
- `AICodedbActions.cs`: `20dd66d7a5983de4fe359fd0d71989e84017191c569a3b81422e3c300aeed9b9` (PASS).
- `AICodedbEditorLifecycle.cs`: `a2bee0a036dde2f051c9b1d1468dcb6a8a71271955e3908ff60e06444f30119f` (PASS).
- `AICodedbManagerWindow.cs`: `15b3a144bb6078c7044bce8c7897edd09fb9282d2fffb2c9450cd974bcb0757f` (PASS).
- `AICodedbEditorLifecycleTests.cs`: `2d8f3c3c4878aa2c3fa0b9a15ca119c4884e846f5a6341f6f7cf8519e6d5a91a` (PASS).
- `AICodedbManagerUiTests.cs`: `a840d696dbfd3693187ae51cfc9bcfe5d07e43c9ae3a263ce740ee0d72353802` (PASS).

The five-path identity is now stable and matches the replacement Coder handoff. The direct review found no in-scope BLOCKER, P1, or P2 finding. The original identity-drift admission failure remains preserved above as historical evidence and is superseded by this replacement admission.

### Contract review

- Configure Dependencies no longer parses Host stdout/stderr and no longer selects `Probe`, `Install`, or a fallback mutation. Provider failure returns before Host admission; Provider success calls the typed Lifecycle request.
- The Lifecycle worker remains the convergence authority. The reviewed missing/current-instance plan sends default installed state through existing `Upgrade` then verification `Probe`; current instances are verified/idempotent, explicit `UNINSTALLED` is non-mutating, and invalid/ambiguous integration or selected-instance state is fail-closed.
- The real nonzero command shape (prerequisite marker on stdout and Host-runtime requirement on stderr) is represented in source tests as data passed through the typed outcome; no text marker drives mutation.
- `CreateReconcileTerminalOutcome` requires a newly published cache revision before returning a terminal result and carries epoch, disposition, product status, command result, revision, and bounded detail. Manager applies the published cache and keeps its observation path cache-only.
- Compilation, Play, domain reload, shutdown, cancellation, and bounded wait branches return `Deferred`/abort the local waiter without claiming success or terminating Supervisor-owned work.
- The synchronous `RunInstallProvider()` path performs only the synchronous Provider installer and then issues a best-effort non-blocking `RequestReconcile()`; it does not synchronously await the Unity Lifecycle task, so the reviewed path has no sync-over-async deadlock.

### Follow-up (non-blocking)

`BeginReconcile` calls `PostProviderReconcile.Complete(epoch, terminal)` before clearing `_reconcileInFlight` and starting a follow-up (see `AICodedbEditorLifecycle.cs` around lines 716-720). The gate itself is lock-protected and the normal Configure callback is Unity-main-thread serialized, so no reachable normal user path was established that can call `Request` in that instruction window. A cross-thread caller could theoretically create a new waiter after `Complete` but before `_reconcileInFlight` is cleared; its immediate `BeginReconcile` would observe the old in-flight flag and could require an additional wake-up. This is recorded as FOLLOW-UP only, not a release blocker; the current tests cover older-epoch follow-up and idle-start, but not this instruction-level interleaving.

### Reused evidence and boundaries

Reused the final Coder evidence: static/source `17/17` PASS and five-path scoped `git diff --check` PASS. No tests were rerun. C# compilation, EditMode, Unity, Unity MCP/CUA/BatchMode, Provider installer, external project/runtime/process, Package validation, full regression, commit, export, tag, push, publication, and promotion remain NOT RUN / DEFERRED. Static source assertions and NUnit method presence are not runtime execution evidence.

## Final verdict

`PASS` for the bounded Bootstrap Admission Refactor review; one theoretical FOLLOW-UP above, no BLOCKER/P1/P2 finding. Planner/User must decide `ACCEPT / FIX / DEFER / STOP`; no next role is dispatched by this report.

---

## Targeted FOLLOW-UP FIX Re-review - 2026-09-22

The user selected FIX for the sole FOLLOW-UP above. This section preserves the original review and closes only that finding and its directly adjacent behavior.

Frozen admission PASS: HEAD `8313d0902945632f72cce3b07ea4eda92da59631`; five-file SHA-256 values match the final Coder handoff exactly: Actions `20dd66d7a5983de4fe359fd0d71989e84017191c569a3b81422e3c300aeed9b9`, Lifecycle `33dcc9feefbf4bf7f63e16b0d24542471ccae11ed483cb2cc0a8b7d84eb8f2f8`, Manager `15b3a144bb6078c7044bce8c7897edd09fb9282d2fffb2c9450cd974bcb0757f`, Lifecycle tests `9d93e7ef5125e0cc50febb70420b138c9b3f7853bbeed8766e1f8ef8ac9`, Manager UI tests `a840d696dbfd3693187ae51cfc9bcfe5d07e43c9ae3a263ce740ee0d72353802`.

**Verdict: PASS / original FOLLOW-UP CLOSED. Findings: 无.**

`BeginReconcile` now releases `_reconcileInFlight` before testing the lock-protected `HasPendingStart` predicate and calling `BeginReconcile(true)`. A request between `Complete` and release that failed its own compare-exchange is therefore restarted. A request arriving after the predicate sees the released flag and can start independently. Concurrent duplicate starts still arbitrate through the same compare-exchange; `BeginEpoch` consumes the pending force exactly once. The older-epoch waiter remains attached to the next epoch and cannot be completed from the earlier one. `Abort` clears the waiter/pending flag and completes it as Deferred; the new predicate cannot revive that waiter. Cache publication remains before terminal `Complete`, and the new wake logic does not modify outcome or cache construction.

The adjacent NUnit test models `Complete -> Request -> new epoch` and asserts pending/forced/terminal behavior. It exercises the gate, not a running Unity Editor or the actual compare-exchange interleaving. Reused Coder's final targeted source-order PASS and two-path scoped diff-check PASS; no test was rerun. The earlier five-path `17/17` evidence belongs to the pre-FIX snapshot and is not claimed for these bytes. NUnit, C# compile, EditMode, Unity, external project/runtime/Provider, Unity MCP/CUA/BatchMode, full regression, commit/export/tag/push/publication/promotion remain NOT RUN / DEFERRED.

Next actor: Planner summarizes this bounded closure; Planner/User decides ACCEPT / FIX / DEFER / STOP. No repair or next-role dispatch was performed.

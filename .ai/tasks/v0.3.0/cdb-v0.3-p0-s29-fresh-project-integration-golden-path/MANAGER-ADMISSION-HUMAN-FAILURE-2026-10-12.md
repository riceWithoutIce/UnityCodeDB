# S29 Manager admission — human EditMode failure and read-only diagnosis

Date: 2026-10-12. Status: HUMAN_GATE_FAILED / SOURCE_REPAIR_NOT_STARTED.

## Exact evidence

- Source/package commit: `1889abe6926cdffab9da23f7a6ffe423d2d5698d`.
- User reported Unity EditMode failure in
  `ManagerActionSession_DurableRetainedResultReplacesStaleRecoveringSession`
  (0.033s), `AICodedbManagerUiTests.cs:1108`.
- Expected retained action: `25df69369ca84dc4bdfa88a7e966acb7`.
- Observed action: `aee7ae4feaea4114b299dde3430608e2`.
- User screenshot: `C:/Users/admin/AppData/Local/Temp/codex-clipboard-bb399f33-cf1b-4df4-a830-f1d049179005.png`.
- Package extraction and source test file both retain accepted SHA256
  `27e962563aef0eccf147945afd66e7b73ccdc6892d546cfa561d4f5c7896cc7b`.
  The reported stack points to the intended package extraction.

The screenshot's overall runner counters do not establish completion of all
eight selected methods / twenty cases. Other human checks are not newly claimed
as passed. No automated Unity execution or test rerun was performed.

## Finding — stale SessionState rehydrates after durable replacement

Priority: P1 for this scoped recovery behavior; the human gate cannot pass.

The test explicitly writes a stale pending action to an isolated project key,
restores that recovering session, then supplies a retained result with a
different action ID. Source inspection gives the following deterministic path:

1. `RestoreDurable`, `AICodedbManagerWindow.cs:3591`, replaces `_current` with
   the retained action and calls `TryCompleteRecovery`.
2. `TryCompleteRecovery`, line 3831, clears the pending SessionState key only
   if its value begins with the retained action ID. The stale ID differs,
   so the key remains even though the replacement is no longer recovering.
3. `CurrentFor`, line 3576, calls `RestorePending`. Its guard at line 3904
   protects running/recovering sessions only; the completed replacement is
   overwritten from the still-present stale pending marker.
4. The assertion at test line 1108 consequently sees the stale action ID.

This same sequence exists in the real window: `RestoreDurableActionAsync`
calls `RestoreDurable` and immediately calls `AttachCurrentActionSession`,
which calls `CurrentFor`. Thus this is a product recovery defect, not a basis
for weakening the test or treating the assertion as a random GUID mismatch.
Whether the current S29 project's real history reaches this Empty-with-result
branch is not asserted; its deferred orphan may still produce Conflict.

The fixture isolates `_current` and a unique project SessionState key under
the production gate, then restores the prior session. No fixture contamination
is needed to explain this failure.

## Evidence correction and proposed repair boundary

Historical source acceptance and package byte closure remain historical facts;
they do not override this Unity failure. The instance-ID Verifier executed four
methods / nine cases in its own scope, not this session regression. The earlier
history review described this test but did not establish its Unity execution.

Proposed repair is restricted to `AICodedbManagerWindow.cs` and adjacent tests
in `AICodedbManagerUiTests.cs`: reconcile the exact superseded same-project
pending marker only after durable recovery succeeds, preserve active owners,
Conflict behavior and unrelated project/session markers. Extend the regression
to assert pending-state disposition and repeated lookup/reopen behavior, with
adjacent negative coverage for the ownership boundary. Do not simply suppress
all pending restoration or blindly erase unknown SessionState.

Source repair needs a new bounded user grant under the current first-failure
workflow. No source, package, project reference, runtime receipt/candidate or
external process was changed during this diagnosis. No subagent was dispatched.
Commit/export/reference switching and another human gate are separate later
steps. Historical orphan and multi-failure selection stay deferred; S29/release
remain PARTIAL.

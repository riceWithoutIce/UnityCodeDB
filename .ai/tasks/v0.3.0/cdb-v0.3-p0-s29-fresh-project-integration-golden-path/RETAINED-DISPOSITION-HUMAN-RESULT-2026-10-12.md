# S29 retained-disposition human result and shutdown hang triage

Date: 2026-10-12.
Status: HUMAN_FOCUSED_TESTS_UI_PASS / SHUTDOWN_HANG_DEFERRED_OBSERVATION / CAUSE_UNPROVEN.
Source/package: 74c4db0cb44afd431b3b861439b3e6ef219d71f3,
.artifacts/s29-retained-disposition-74c4db0/review/com.rice.ai-codedb.
ZIP SHA256: 1325857c43a0f002f6feb25e1830efd00fc312e4e4de8120952d4963ef00e26c.

## Attributable human evidence

- Initial ProductionObservation test was Ignore because the Hub-launched Editor
  lacked CODEDB_RETAINED_OBSERVATION_FIXTURE. It was not counted as PASS.
- User explicitly asked parent to execute the documented PowerShell launch.
  Parent verified S29 closed, launched exact existing project with process-local
  fixture environment, observed PID 16436 (17:48:10 local); no tests/UI automated.
- User subsequently reported all focused tests passed, compilation passed and
  Manager reopen/tab checks passed. Test Runner screenshot shows 26 green,
  zero red; user result is 13 methods/26 cases against this package.
- Manager screenshot still shows current generation mismatch and historical
  ownership warnings. No actual Install/removal/migration/Ready acceptance claimed.
- Normal close hung at Application.Shutdown.CleanupMono, busy for 55 seconds
  in the supplied screenshot. User explicitly confirmed manual force termination.
  This is a failed normal-close gate, not successful exit or recovered crash.

## Read-only triage

- S29 no longer present in process enumeration; unrelated miniGame_int Editor
  and import workers were untouched.
- Windows Application Hang event 1002 at 17:51:45 and WER event 1001/AppHangB1
  at 17:51:47. Hang event application PID hexadecimal 4034 = decimal 16436,
  matching this exact S29 launch. WER report ID:
  db23270b-8a30-4520-b37c-687e85e53d4c.
- Shared Editor.log contains this S29 session's exact Package stack paths and
  quitting sequence before later unrelated miniGame logging. Read only bounded
  S29 signals; the shared log is mixed provenance, not all S29 evidence.
- CodeDB editor_quitting_entry/return observed once; recorded callback max
  1322 microseconds. At return, reconcile in flight=0, Manager refresh in flight=0,
  queue pending=0 and active=0, main-thread violations=0.
- shutdown_request_count=1; shutdown_disposition=NOT_EVALUATED at the recorded
  quitting checkpoint. This snapshot does not prove worker completion or failure;
  prior P1 fix deliberately makes post-quitting worker completion counter-only.
- ADB shutdown completed in about 0.037 seconds. Input shutdown and licensing
  disconnect precede Cleanup mono; Upm-16436 then reports IPC not connected.
  The UPM line is sequencing evidence, not proof of the blocking owner.
- No prior GetManagerFromContext/MonoManager-NULL/Crash!!! marker in the bounded
  S29 session segment. Exact emitted LifecycleEvidence retains the prior P1
  counter-only RecordShutdownDisposition fix. The old proven worker Debug.Log
  crash therefore cannot be assumed to be this AppHang's cause.
- One earlier already-disposed CancellationTokenSource warning has no attributable
  blocking stack. It remains a clue, not an established cause.
- WER report archive directory access denied. No hang dump/managed/native
  blocking stack obtained; no permission/ACL change attempted.
- Accepted worktree hashes still match 8/8; ZIP and exact package reference
  remain unchanged. No source/test/runtime/history repair, export, reference
  switch, commit, process stop or retry performed during triage.

## Interpretation and next proposed bounded diagnostic

The normal Editor exit failure is a P1 acceptance blocker. Existing test/UI PASS
is preserved, while S29/release remains PARTIAL. CodeDB's synchronous quitting
callback returned quickly, which rules out a persistent wait inside that callback
for this attempt but does not rule out detached worker/Mono teardown interaction.

The new Window regression constructs a managed uninitialized EditorWindow
(omitting native allocation); Mono teardown/test-lifetime interaction is an
unproved hypothesis. The existing asynchronous shutdown worker is another
unproved branch. No source fix is justified from this log alone.

Propose one fresh human comparison session on the same exact Package, with
dedicated repository-local Editor log:
.artifacts/delivery/s29-retained-disposition/shutdown-control/editor-no-tests.log.
Do not run any Test Runner methods. After compilation, open/reopen Manager,
switch tabs, observe about one minute and close normally. If hung, preserve
the window/evidence and return to parent before forcing termination when practical.
No full suite, operational buttons, generation migration, process control or
cleanup. This comparison separates no-test exit from the previous test-bearing
session; it is not a repeated release acceptance attempt or proof of root cause.

This new Unity launch/session requires explicit user authorization under the
workflow risk-boundary rule. It has not been started.

## Subsequent authorized no-test session

User authorized the proposed single comparison, then reported normal close.
Dedicated log confirms execution past Cleanup mono into final memory statistics;
PID 36064 absent and no matching post-launch Unity hang/crash event observed.
See SHUTDOWN-NO-TEST-CONTROL-2026-10-12.md for exact counters and log identity.
This success is preserved separately and does not supersede the forced-close
AppHang failure. Full Manager interaction equivalence is not established;
test isolation/object lifetime is a priority hypothesis, not confirmed cause.
P1 remains open pending attribution; no source repair or additional launch.

## User disposition — defer observation, 2026-10-12

User explicitly proposed deferring the shutdown hang and continuing observation
during later tests: the current sample is too small to determine whether this
development caused it. This disposition supersedes the immediate-blocker and
dedicated-investigation recommendation above. Retain the P1 history as an
unresolved deferred observation item; it does not block the current slice.

Keep the 26-test/compile/Manager PASS, the forced-close AppHang failure and the
successful no-test close as distinct evidence. Neither causation nor a shutdown
fix is claimed. No source change or additional dedicated Unity experiment now.
During subsequent separately authorized tests, record normal/abnormal shutdown
and its session context. If it recurs, collect available attributable logs and
timing read-only, then reassess priority and scope; process stops/dump collection
remain separate authorization boundaries. Generation alignment and S29/release
acceptance remain deferred independently of this observation item.

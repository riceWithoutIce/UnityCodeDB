# Task: cdb-v0.3-p0-s37-manager-periodic-observation-ux

## Metadata

- Product: UnityCodeDB, v0.3.0.
- Workflow: codedb-workflow-v2, revision 2.6.
- Status: HUMAN_ACCEPTANCE_PASS_WITH_FOLLOWUP for the narrow Supervisor repair;
  the observed periodic timeout did not recur in the latest bounded acceptance.
  A separate startup-UX follow-up remains deferred.
- Planner/Coder: current parent. Verifier: authorized S37 read-only child,
  completed including F1 re-review.
- Review mode: GUARDED; original finding F1 closed, review stopped.
- Execution mode: source review, exact commit/export and S35 reference switch
  completed under explicit delivery authorization. Human Unity acceptance is
  still a separate gate.
- Requirement source: follow-up requested by the user after S36 human smoke.

## Deferred observation

After the corrected S36 delivery, S35 reached Ready. When left idle for about
3-5 minutes, Manager performed another background observation and returned to
Ready. The visible Manager copy said the last verified Ready observation was
cached. No Install, Uninstall, compilation error or persistent NeedsAttention
was reported in this observation.

## Current interpretation

This is currently classified as an observed periodic refresh behavior, not a
confirmed product defect. The relevant existing boundaries are:

- Manager Ready display freshness is approximately 30 seconds.
- Removal preflight cache lifetime is 120 seconds.
- Manager transient refresh retry interval is 5 seconds.

The S36 repair keeps this refresh path coherent by preserving the command and
paired Supervisor observation; it does not remove normal background refreshes.
The screenshot/result therefore remains a human observation to discuss later,
not evidence that S36's cache-coherence fix failed.

## Scope for a future alignment

- In scope later: decide whether the refresh should remain silent, show a short
  Checking state, or expose a more explicit non-blocking status transition;
  define acceptable refresh frequency and visible behavior while Ready remains
  healthy.
- Evidence later: one bounded real-Editor observation covering the transition
  after the 120-second preflight boundary, final state, duration and any
  NeedsAttention detail, with the exact delivered package recorded.
- Out of scope until separately agreed: changing the 30-second freshness rule,
  changing the 120-second preflight lifetime, weakening observation identity or
  revision checks, removing background health checks, log reduction, CleanupMono,
  Install/Uninstall/reinstall and historical project recovery.
- No source edit, package export, reference switch, Unity launch or test run is
  authorized by this deferred record.

## Handoff

S38 later completed an attributable current-version Install -> Ready ->
Uninstall -> same-version Install -> Ready sequence against the `d856a8f`
delivery. Its post-reinstall human observation reports heavier recurring
checks and a `CodeDB status unconfirmed / Checking` Manager display lasting an
estimated 30-60 seconds before returning to Ready automatically. No Unity
stutter or abnormal interaction has been experienced so far. Record this as a
non-blocking periodic-status-delay FOLLOW-UP, without claiming a measured
Editor performance regression.
The bounded read-only record is in the S38
`PERIODIC-OBSERVATION-RESULT.md`. This reopens the existing periodic UX and
runtime-latency follow-up for alignment; it does not turn the S38 action
sequence into a failure or authorize another source repair.

- Current task: cdb-v0.3-p0-s37-manager-periodic-observation-ux.
- Current status: DEFERRED / ALIGNMENT_PENDING.
- Next notification: User, when choosing to reopen the refresh UX discussion.
- Next action: first align whether the current Ready -> background observation
  -> Ready behavior is acceptable, then freeze one narrow objective and evidence
  plan before implementation.
- Human decision or authorization required: future scope and execution grant.

## Human acceptance follow-up — 2026-10-19

The user reports that acceptance passed and the earlier periodic
`NeedsAttention` transition did not recur. Manager reopen/tab behavior and
Unity close/reopen were reported normal. On opening Manager, the visible
`Starting` state persisted longer than desired before readiness; the screen
states that Unity can continue to be used and no error or blocked command was
reported.

Disposition: record the prolonged `Starting` display as a non-blocking startup
UX follow-up. Complete the current S37 acceptance record first; do not reopen
the Supervisor timeout repair or change readiness thresholds based on this
observation alone. A future startup-UX task may measure the transition time
and decide whether to show a lighter progress state or improve readiness
publication.

## New human observation — 2026-10-19

After the same-version Install completed and Manager displayed Ready, the user
observed a repeatable transition after roughly 3-5 minutes to NeedsAttention.
The Manager detail identified `SUPERVISOR:SUPERVISOR_IPC_TIMEOUT` and stated
that the Supervisor IPC request timed out. Host payload, current instance,
generation and provider rows then showed `Not evaluated`, while Background
cleanup showed `In progress`. The state eventually returned to Ready, but only
after a long delay.

This is stronger evidence than the earlier transient Ready refresh observation:
it is a bounded availability/UX degradation in the periodic observation and
recovery path. It does not indicate that Install itself failed, and no data
loss or persistent terminal state was reported. Keep it outside the S36 fixture
repair; reopen S37 alignment before proposing a fix. The next read-only scope
should correlate the observation timeout, background cleanup lease state and
retry/recovery timing. No source edit, package delivery or lifecycle retry is
authorized by this observation alone.

## Read-only architecture alignment — 2026-10-19

The current implementation confirms the intended process boundary:

- `AICodedbEditorLifecycle.OnEditorUpdate` runs in the Unity Editor process and
  schedules a per-project lifecycle heartbeat every 5 seconds.
- Scheduled lifecycle reconciliation is separate; the Manager's 5-second
  update callback is cache-oriented and does not itself launch a materializer.
- `AICodedbSupervisorBridge` sends project-bound IPC from a worker to the
  external project Supervisor. The named pipe is derived from canonical project
  root and runtime, preserving multi-project isolation.
- The Supervisor contract defines a query lane separate from serialized
  maintenance, but this read-only pass did not prove that every observation is
  serviced by an independent non-blocking server path.
- The current Bridge exchange deadline is 1500 ms. A timeout means the worker
  did not receive a bounded Supervisor response; it does not by itself prove
  that the Supervisor is dead or that the project is uninstalled.

The next diagnostic should inspect the Supervisor query handler and queue state
at the timeout boundary, especially whether maintenance/cleanup holds the same
server-side execution path. It should also verify effective single-flight and
coalescing for repeated per-project observations. No threshold change or
status-policy relaxation is proposed until that evidence is available.

## Read-only diagnosis completed — 2026-10-19

The parent completed the authorized source inspection against the delivered
`.artifacts/s36-preflight-refresh-46fdba6/review/com.rice.ai-codedb` snapshot.
See [RESULT.md](RESULT.md) for confirmed queue/event-loop coupling, the command
timeout/recovery route, and the limits on attributing the human incident.

Correction to the earlier architecture shorthand: the 5-second Editor heartbeat
is a lifecycle scheduler tick, not an independent status IPC every 5 seconds.
Normal scheduled reconciliation is eligible every 30 seconds; its completion
queues a Bridge reconnect. The Supervisor also polls Coordinator status every
second. Manager open/close/repaint/tab activity consumes lifecycle cache; explicit
Refresh is a separate observation intent.

The agreed target remains separation of index refresh, runtime observation,
Editor lease and mutation/cleanup. Current source does not yet implement the
new lightweight-observation design. Status remains ALIGNMENT_PENDING; this
diagnosis grants no production repair, tests, delivery or lifecycle operation.

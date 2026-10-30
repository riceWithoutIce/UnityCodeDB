# Open defects from Test3 first Install

Recorded: 2026-10-26. Owner: v0.3 lifecycle acceptance task.
Local task registry only; no GitHub issue or Project update has been made.

## V03-INSTALL-HANDOFF-01 — Candidate Coordinator ownership handoff

- Status: OPEN / P0 for clean Install lifecycle acceptance; remediation deferred
  while the user elects to continue bounded functional acceptance after recovery.
- Candidate: `d84b5ca88b1adb57748b2988aa79cc9c7e6e8be9`, preview.5 / poc.44.
- Project: new external CodedbTest_3. First normal Manager Install, action
  `895fd7c278b048a0a214a4f9143ffe10`, exit 0, instance
  `bd0f2f01601b4b3990704ad9659f9348`.
- Trigger: candidate verification starts an exclusive candidate lifecycle;
  selection is activated and the normal Supervisor subsequently evaluates it.
- Observed: human Ready -> Needs attention -> Ready. Four Probe failures report
  `Coordinator query service configuration mismatch: exclusive lifecycle`.
  Original Coordinator exits on `last_editor_lease_gone`; replacement Coordinator
  and Supervisor become operational. No agent intervention or retry.
- Expected: verified candidate ownership has an explicit supported transition
  to normal operation, with attributable completion or an honest failure. Normal
  readiness must not depend on a stale candidate lease expiring as the handoff.
- Evidence: TEST3-FIRST-INSTALL-RESULT.md and its hashed sanitized snapshot.
  Source supports a success-path handoff gap; the original Coordinator's full
  initial state was not captured. Do not claim every historical heartbeat/UI
  incident has this cause.
- Impact: post-install availability interrupted; installer checks alone do not
  establish normal operation. Recovery does not close this defect.
- Continuation hazard: the first-Install snapshot also retains four failed
  pre-child Probe records with UNKNOWN execution disposition. The current
  Install admission rejects UNKNOWN history if those records remain and that
  admission path is used. No post-Uninstall Install was attempted. This needs
  explicit handling analysis; no history edit or NO_CHILD inference is granted.
- Follow-up analysis TEST3-UNKNOWN-PROBE-ANALYSIS.md confirms those four exact
  records remain after Uninstall and identifies the pre-child mismatch branch
  that preserves UNKNOWN. Normal retention does not retire failed UNKNOWN
  history. This is a producer/consumer evidence gap to address alongside the
  ownership handoff; existing-record recovery remains a separate policy decision.
- Repair boundary: agree release/promotion authority and bounded failure handling;
  preserve ownership safety and immutable payload rules. No broad refactor,
  relaxed identity check or manual process termination is authorized here.
- Closure: scoped source/adjacent tests plus separately attributable normal
  Install-to-Supervisor handoff on the fixed candidate, without this mismatch or
  dependence on stale-lease expiry; keep response identity and release separate.

## V03-CLEANUP-DIAGNOSTIC-02 — Cleanup scheduling unresolved

- Status: OPEN / TRIAGE. Priority awaits impact confirmation.
- Same candidate/project; successful post-recovery Probe retains
  `CLEANUP_SCHEDULING` disposition `Unresolved`, inputs empty, garbled binding
  error mentioning `Text`, and cleanup PENDING.
- Cause and exact binding site not established. PENDING is not inherently a bug;
  the unresolved diagnostic is the issue to investigate.
- Not established as the cause of the ownership mismatch. Do not combine the
  two defects without evidence or claim physical cleanup complete.
- Before another destructive lifecycle step, align retained-history handling and
  assess whether this prevents the promised Uninstall/Fresh Install behavior.
- Closure: establish origin/impact; fix only agreed scope and demonstrate valid
  empty-input behavior plus honest cleanup reporting. No cleanup replay is
  authorized by this record.

## Continuation decision

User: "先计入bug，然后继续我们当前的任务". Record both issues and retain
the failed/recovered first-Install outcome. Continue next bounded functional
gate under the recovered binding; do not reopen the failed attempt, infer a
repair grant, or close clean lifecycle/release acceptance. Target-client task:
TEST3-RECOVERED-TARGET-CLIENT-TASK.md. No Install/Uninstall or Unity cycle follows
automatically from that task.

The recovered target-client task completed with status/query PASS and formal
response identity LIMITED. Its result is recorded in
`TEST3-RECOVERED-TARGET-CLIENT-RESULT.md`; both Bugs remain OPEN.

The Uninstall attempt is recorded in
`TEST3-UNINSTALL-ATTEMPT-RESULT.md`: logical uninstall passed, cleanup remains
PENDING, and Supervisor handoff is UNCONFIRMED. This adds evidence to the
cleanup triage item and does not close either Bug. The bounded follow-up is in
TEST3-UNINSTALL-HANDOFF-CHECK-RESULT.md: exact terminal attribution and logical
deactivation confirmed; warning is a recovered-result evidence limitation, not
a proven handoff failure. PENDING cause and live holder state remain unverified.

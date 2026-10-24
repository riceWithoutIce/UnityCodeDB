# S38 post-reinstall periodic observation - 2026-10-20

Status: `HUMAN_UX_WARNING / RUNTIME_CAUSE_NOT_ATTRIBUTED`.

After the successful same-version reinstall, the user reports that checks
recurring roughly every 3-5 minutes feel heavier than after the first Install.
The supplied Manager screenshot (attachment ending
`d55df995-4812-47b6-bd26-15eafbb99739.png`, saved at approximately
`2026-10-20T07:20:33Z`) shows `CodeDB status unconfirmed`, Last activity
`Install CodeDB / Completed - checking status`, and multiple diagnostics in
`Checking`. The user subsequently estimates the visible check lasts about
30-60 seconds and then returns to Ready by itself. No Unity stutter or abnormal
interaction has been experienced so far. This is human perception, not a timed
trace or a systematic responsiveness test. It does not negate the original
Install terminal or independent Ready observation in `REINSTALL-RESULT.md`.

## Bounded read-only checks

- Desired state remained `INSTALLED`. Existing Supervisor snapshots sampled
  after the screenshot continued to bind the newly selected instance
  `fc7f8014b60b4b359f4582d06cdba2dd` and retained a `core_ready /
  COORDINATOR_OPERATIONAL` operational observation. The top-level Supervisor
  readiness sometimes showed `maintenance` while an automatic Probe or
  Upgrade was running. This does not establish that the Manager display was
  Ready at the exact screenshot time.
- The delivered Manager can display `Completed - checking status` after a
  command while product status has not been confirmed. Its cached `Starting`
  snapshot renders individual rows as `Checking`. The Manager consumes cached
  lifecycle status; its update/repaint loop is not itself a materializer
  launch. Scheduled lifecycle reconciliation may run heavier Probe, Upgrade,
  removal-preflight and retirement work; see the existing S37 periodic
  observation diagnosis. This is a source-path explanation, not attribution
  of this screenshot to one callback.
- In two 18-minute windows with operation history available, first-install
  window `05:44-06:02Z` recorded 62 completed Probes (median 3.82 s, total
  274.7 s) and 30 completed Upgrades (median 6.35 s, total 209.3 s).
  Post-reinstall window `07:14-07:32Z` recorded 65 completed Probes
  (median 4.07 s, total 314.2 s) and 33 completed Upgrades (median 8.05 s,
  total 269.8 s). These are operation wall times, not CPU time or Editor
  frame time. The windows were not controlled for Unity activity and the
  history does not retain the immediate post-first-Install window, so the
  difference is suggestive but not a measured reinstall cost.
- The current Unity Editor log contains 97 `CodeDB automatic uninstall cleanup
  failed` warnings saying the current instance pointer was absent, and three
  `CodeDB historical cleanup remains pending` timeout warnings with
  `SUPERVISOR_IPC_TIMEOUT`. Source inspection places the former in the
  `IsUninstalled` automatic cleanup branch, consistent with the interval
  between Uninstall and reinstall. The latter comes from the retirement
  branch. The log lines do not carry timestamps that bind an individual
  warning to this screenshot. No persistent `NeedsAttention` or failed
  post-reinstall Manager action was established by this check.
- All post-reinstall Probe and Upgrade operations retained in the sampled
  Supervisor history were terminal with exit 0. That record does not cover
  every Editor-side retirement attempt or measure Unity frame responsiveness.
- Persisted cleanup `PENDING` can render as `Background cleanup / In progress`
  without proving that physical cleanup is actively running. This observation
  does not establish the source of any IPC timeout or interaction latency.

Disposition: retain the core S38 lifecycle PASS for its attributable actions
and Ready observations, with a separate post-reinstall periodic-observation
warning. The reported recovery and absence of perceived interaction problems
support a non-blocking FOLLOW-UP for recurring status-display delay. Editor
performance regression is not established, and stable idle UX is not accepted
by the lifecycle result. The existing S37 periodic observation follow-up is
the appropriate design/diagnosis route; next evidence should correlate the
reported 30-60-second Checking window with Supervisor response latency and
retirement work. No status RPC, new test,
Unity automation, process control, source edit or lifecycle action was run.

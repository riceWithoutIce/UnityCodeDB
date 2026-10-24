# S33 reopen human result and UX alignment

Date: 2026-10-18.
Status: HUMAN_REOPEN_PASS_WITH_UX_ISSUES / NON_BLOCKING_FOLLOWUPS / SOURCE_REPAIR_NOT_AUTHORIZED.
Package baseline: b0462ed / 0.3.0-preview.5 / poc.43, unchanged delivery.

## Human evidence

User reports Manager close/reopen and tab switching normal, Unity close/reopen
normal, and eventual Ready after reopening Unity. User additionally reports
excessive logs and prolonged unconfirmed display on Manager reopen within one
Unity process. Screenshots ending 707ba867-997a-47ba-9d17-9aa6b264a909.png and
a51a622b-8b8b-4f32-a919-b8753ca246bc.png are the supplied evidence references.

The Console screenshot shows 565 informational entries, zero warnings/errors,
and repeated CODEDB_S12_EVIDENCE reconcile_completed messages. The Manager
screenshot shows status unconfirmed, last Install completed/checking status,
and loading diagnostic fields. The displayed activity duration is not a measured
Manager-reopen latency. No failed or repeated Install is established by this UI.

Normal shutdown is a passing sample; previously deferred CleanupMono/shutdown
investigation is not closed by this sample. No new test-run result was reported.

## Bounded exact-Package source diagnosis

- Editor/AICodedbLifecycleEvidence.cs PersistAndEmit persists the counters and
  directly Debug.Logs the complete snapshot. Lifecycle calls it at each completed
  reconcile; this success path has no Console-output opt-in. Counter collection
  and Console emission are currently coupled.
- Editor/AICodedbManagerWindow.cs OnEnable clears _statusBoundary. Its
  RestoreDurableActionAsync first runs materializer ReadStatus, then reads the
  action journal and captures the display boundary. ReadStatus invokes the
  materializer DryRun; it is not merely an in-memory snapshot lookup.
- TryApplyCachedLifecycleStatus rejects cached Ready while the window boundary
  is absent. Thus fresh lifecycle Ready can still be withheld pending restoration.
  A static last-known Ready cache also exists, but does not bypass that boundary.
- Ready observation freshness is 30 seconds. Lifecycle reconcile retry interval
  is also 30 seconds. Expired observations require a real fresh observation;
  reusing a window cache alone cannot guarantee immediate Ready in every case.
- These paths explain a plausible wait mechanism. There is no phase timing yet
  to attribute the user's full delay to DryRun, journal reading, observation age,
  or the next lifecycle publication. Screenshot counters are cumulative, not
  rates; they do not establish Manager-triggered repeated work or CPU cost.

## Proposed bounded handling, pending alignment

1. Keep diagnostic counters and explicit diagnostic access; make repeated full
   success snapshots opt-in for Console. Preserve actionable warnings/errors and
   command results. Reducing output alone is not a background-work optimization.
2. Separate current product observation/display admission from historical action
   restoration. A valid current-process authenticated observation should be usable
   independently of restoring the Last activity panel. Preserve project, Package,
   generation, contract, runtime and existing upstream identity validation.
3. Preserve original observation timestamps and freshness rejection. For expired
   evidence show an honest refreshing state and obtain fresh observation through
   the lifecycle-owned path with coalescing. Do not force Ready, renew timestamps
   on reads, launch competing Manager probes or relax authentication.
4. Before claiming latency improvement, use bounded phase timings to distinguish
   boundary restoration, status read and lifecycle publication. Stop for discussion
   if the cause expands into a backend/performance redesign.

Acceptance should cover fresh same-process reopen, expired/changed identity,
unchanged background ownership and explicit diagnostic opt-in. A full performance
audit, historical recovery, Install changes and shutdown diagnosis are outside
this proposal. The initial NotIntegrated description remains a separate recorded
wording follow-up. No source, delivered extraction, runtime, reference or process
was changed in this read-only diagnosis. Only task evidence records were updated.

Remaining lifecycle gates are logical Uninstall and same-version reinstall;
neither is authorized by this feedback or this record. Do not repeat Install.

## Non-blocking disposition - 2026-10-18

User explicitly classifies both issues as small, non-blocking observations and
asks whether to repair now or continue. Record both as NON_BLOCKING FOLLOW-UP:
repeated diagnostic Console output, and prolonged same-process Manager-reopen
unconfirmed display. Source repair remains unapproved.

Recommendation: preserve the current delivered baseline, proceed to alignment
and authorization for one logical Uninstall, then same-version reinstall. Review
these UX follow-ups together after the lifecycle route has its results. Revisit
earlier if Ready no longer converges, user actions become unavailable, or log
output causes an actual usability failure. Do not expand into historical repair
or general performance work. This disposition does not authorize a real action.

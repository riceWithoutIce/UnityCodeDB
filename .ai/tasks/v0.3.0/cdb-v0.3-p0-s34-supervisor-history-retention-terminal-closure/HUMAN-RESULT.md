# S34 human baseline result - 2026-10-19

Status: HUMAN_REPORTED_BASELINE_PASS_WITH_SHUTDOWN_EXCEPTION.
Source/delivery accepted; real same-version reinstall remains pending baseline
disposition and a separately authorized action. No real Install/Uninstall run
is claimed from this result.

## Human observations

User reports: Unity shutdown had an abnormality, no other abnormalities.
This is human baseline evidence for the requested compilation/Manager checks,
not an agent-run test suite or a new Ready/Install result.

- Manager screenshot shows CodeDB is uninstalled from this project, Install
  CodeDB available, and no recent command. This matches the intended baseline.
- Shutdown screenshot shows Hold on / Application.Shutdown.CleanupMono /
  Waiting for Unity's code to finish executing.
- User explicitly confirms manual force termination after the stall. Normal
  Unity shutdown did not pass in this sample; do not label it a normal exit,
  recovered shutdown or crash with a proven root cause.
- Previously agreed CleanupMono investigation deferral remains in effect.
  Record this sample without adding a shutdown fix or repeated repro to S34.
  A UI progress label alone does not establish CodeDB or S34 causal attribution.

## Bounded read-only follow-up

- No attributed S33 Unity process was observed after the report. Other Unity
  processes belonged to another project and were not touched. S33 UnityLockfile
  remained; no lock removal was performed.
- Manifest and lock both still reference
  `.artifacts/s34-supervisor-history-d4a097d/review/com.rice.ai-codedb`.
- Canonical operation `c61cdf881d39405f85d4f19ae8ac1076` remains failed /
  invalidated / UNKNOWN. Its SHA-256 matches the pre-switch protected baseline.
- History remains 5301 records; no count reduction or real retention run is
  claimed. No manual history cleanup, evidence backfill or action release.
- Shared Editor log inspection contained unrelated project/test activity; its
  tail is not admitted as an exact S33 shutdown trace or focused test PASS.
  No further shutdown log investigation was opened.

## Preserved screenshots

Hash-verified copies, repository-relative evidence directory:
`.artifacts/delivery/s34-supervisor-history-d4a097d/human-baseline-20261019/`.

| File | SHA-256 |
| --- | --- |
| codex-clipboard-df87a7da-e2c2-49e6-9b37-353be6865750.png | c8c8440ece9a024572bd1d975e08cc41c3ff41131bc10c365c1a46cfad788123 |
| codex-clipboard-68b5b529-6094-46c7-aef4-820a9a46fec8.png | 4d4fa105cf027e312ea09f33c83d342992d8bdc4d72a6b32eb7a3c888ff5de21 |

## Handoff

Compilation/Manager baseline is human-reported normal, with the shutdown
exception separately recorded and deferred. This does not certify the full
lifecycle, shutdown, runtime retention or reinstall. Next: align the bounded
disposition of the existing canonical UNKNOWN evidence before any real Install.
No repair, export, reference switch, process control, Unity launch or retry
is authorized by this report. No extra agent/test was started.

## Bounded baseline disposition diagnosis - 2026-10-19

User agreed to continue the read-only baseline assessment. No new source repair,
runtime mutation, test invocation or process operation was authorized or run.

Findings, consolidated rather than repaired sequentially:

1. Canonical `c61cdf881d39405f85d4f19ae8ac1076` belongs to the prior S33
   selection/owner epoch. Its exact error text and code match the delivered
   S32 producer's finishOperation -> invalidatePendingRequests ->
   failQueuedMaintenance branch after selected-instance change. That branch
   removes entries from pendingMaintenance. Old record still explicitly says
   UNKNOWN, phase invalidated, null start/child, and lacks overflow/drain flags.
   Source attribution explains the legacy shape; it does not rewrite the record,
   independently certify all execution, or authorize retrospective NO_CHILD.
2. Direct Supervisor event tail shows Uninstall completed before Supervisor
   retirement. Events contain only sequence/time/name/detail, with no matching
   operation or request ids for the canonical Probe. They supply chronology,
   not a new exact per-operation execution attestation. Successful Uninstall map
   references only its own operation, not the failed Probe.
3. The same Supervisor directory also contains two old takeover artifacts:
   supervisor-state.json.stale and supervisor.lock.stale with timestamp/token
   suffixes. Exact S34 Assert-ProjectInstallExecutionAdmission rejects such
   nonallowlisted owner/takeover files independently of the canonical terminal
   checks. Presence is not proof of a live process or permission to delete them.
   No attributed S33 Unity was observed; that does not prove every retained
   runtime child is absent, and no broader process audit was opened.

Conclusion: disposing of one UNKNOWN record alone is insufficient to restore
this baseline. Continuing S33 would require a wider historical takeover/runtime
disposition, beyond the accepted S34 source repair and this read-only assessment.
Stop this recovery branch under the agreed bounded historical-recovery policy.

Recommended next route for User decision: preserve S33 in place as historical
acceptance evidence, and use a new clean Unity acceptance project with the same
already delivered d4a097d Package. Run the complete first Install -> Ready ->
Uninstall -> same-version Install -> Ready sequence with separately authorized
real actions. A first Install alone cannot close reinstall acceptance. No new
export, historical compatibility fix or S33 history deletion is proposed.

Alternative: scoped reset of S33, requiring an exact backup/removal/ownership
plan and explicit user authorization first; it is not a one-record cleanup.
No archive, reset or new-project reference setup has occurred. Baseline choice
remains with User; keep CleanupMono and existing UX follow-ups deferred.

## Baseline route selected - 2026-10-19

User accepts the new-project route and proposes organizing accumulated validation
projects before creating more. S33 leaves the active acceptance route logically;
its results remain partial, with no retrospective reinstall or shutdown PASS.
It remains physically in place with protected runtime/evidence unchanged.

Concrete inventory, proposed future layout and exact physical archive mapping:
`../../shared/unity-validation-project-organization/TASK.md`.
Physical migration and new-project setup await their exact boundary decisions;
no additional historical recovery is opened.

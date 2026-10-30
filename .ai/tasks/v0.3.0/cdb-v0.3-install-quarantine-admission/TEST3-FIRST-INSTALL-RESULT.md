# Test3 first Install and post-install recovery

Date: 2026-10-26. Candidate commit:
`d84b5ca88b1adb57748b2988aa79cc9c7e6e8be9`.
Disposition: `INSTALL_COMMAND_PASS / POST_INSTALL_HANDOFF_ANOMALY / RECOVERED`.
This is a bounded read-only diagnosis, not a source repair or complete lifecycle
acceptance. Human confirms no compilation errors and observes Ready, Needs
attention, then Ready. The later screenshot confirms UI recovery separately
from disk state. The screenshot also explicitly describes cached Ready evidence;
it is not a new query or a fresh connection check.

## Attributable Install

Human action ID: `895fd7c278b048a0a214a4f9143ffe10`. Exit 0, elapsed 15.36s.
Command result: INSTALL / INSTALLED / COMPLETE / INSTANCE_ACTIVATED;
cleanup PENDING. Both installer candidate verification and stable-entry
verification reported initialize/tools/status/query success. These are installer
checks, not acceptance from a new target Codex task.

Selected instance: `bd0f2f01601b4b3990704ad9659f9348`.
Project identity:
`sha256:c2ad1085aca6ca5e8298cfe630b69c5b61242497f65c187eb08484f035ca6dd2`.
Activation epoch: `60d2810430de421abefbce55567cf9ec`.
Instance manifest hash:
`47a55412ee35f9f8b061e47c03b38dd6b248ab9b1ecff0920970d3a794b65b0e`.
Package preview.5 / generation poc.44. Disk instance originating action matches
the human Install. Target project is `<test-project-root>` (CodedbTest_3).

## Observed runtime sequence (UTC)

| Time | Evidence |
| --- | --- |
| 06:30:31.870 | Coordinator PID 123948 starts during candidate verification. |
| 06:30:34.0581555 | Selected instance activated. |
| 06:31:13.001–06:32:34.919 | Four retained Probe operations fail with `Coordinator query service configuration mismatch: exclusive lifecycle; stop the existing owned coordinator before starting this configuration.` |
| 06:32:44.648 | Coordinator reclaims one invalid/stale editor lease. |
| 06:32:44.780 | PID 123948 exits normally: `last_editor_lease_gone`, exit 0. |
| 06:32:50.510 | Earlier Supervisor retires: coordinator offline. |
| 06:33:13.650 | New Coordinator PID 125368 starts. |
| 06:33:14.203 | New Provider ready; adapter watching. |
| 06:33:18.478 | New Supervisor's Probe completes, exit 0. |
| 06:38:33 | Bounded snapshot sees Supervisor `core_ready`, reason `COORDINATOR_OPERATIONAL`; Coordinator lifecycle `unity-bridge`, exclusive false. |

The four failed operations retain `execution_disposition=UNKNOWN`, child null;
they fail at the Coordinator configuration check before child preparation in
`ensureCoordinator`. They must not be relabeled as successful or discarded.
The completed later Probe includes a child execution close record (exit 0), but
this alone does not close the original short-lived-child scenario or the entire
Install/Uninstall acceptance gate.

## Source-supported direction and limits

In the delivered candidate, `Tools~/codedb-instance-engine.ps1`:
`New-VerifiedInstanceCandidate` creates lifecycle `candidate-<instance-id>` and
starts Ensure with RequireNewOwner and ExclusiveOwner (lines 2795, 2830).
Its successful return exposes LifecycleId and ProbeLeasePath. The inspected
activation path publishes selection, probes the stable entry, then performs
retained cleanup. A named ProbeLeasePath has no other reference in this source.
The inspected source does not show a successful-path explicit release or
promotion of this candidate ownership. Failure-path cleanup does attempt a stop
using the expected candidate lifecycle.

`Tools~/codedb-project-supervisor.mjs:1967` rejects an exclusive Coordinator
whose lifecycle differs from the Supervisor lifecycle. `ensureCoordinator`
throws that mismatch before child preparation. This source path and runtime
error support a candidate-validation-to-normal-runtime ownership handoff gap.
The original Coordinator state/lease was not preserved before its exit, so its
complete initial ownership fields are not independently available in this
snapshot. Do not substitute source intent for a captured historical state.

Recovery involved a Coordinator exit and replacement; it was more than an
observed UI label change. PENDING alone is not proof of this cause. Do not infer
all older Test2 heartbeat/UI incidents share this mechanism.

A separate existing diagnostic is retained in the successful Probe stdout:
`CLEANUP_SCHEDULING` disposition `Unresolved`, inputs empty, with a garbled
parameter-binding message containing `Text` (apparently an empty-string issue).
Its origin and consequences are unverified. Runtime Ready therefore does not
prove cleanup completion. No additional cleanup attempt was started by the agent.

Next alignment: define explicit, bounded ownership handoff from candidate
verification to normal Supervisor operation, including failure retention and
which layer owns release. Preserve ownership checks. Do not simply ignore the
mismatch, hide Needs attention, wait out a lease as the intended solution, or
stop an owner without proving authority. Repair choice remains unapproved.

## Retained diagnostic evidence

Repository-relative artifact:
`.artifacts/tests/cdb-v0.3-install-quarantine-admission/test3-first-install-diagnostic-2026-10-26T06-38-33-077Z/snapshot.json`.
SHA-256:
`69388d707a09f1cc0e3d981e1d6220acc455e611cf72eafca763f7a83f2e47dc`.
17 file reads, including two pointer reads; five operation-history records, no
history truncation. Maximum per-file budget 1 MiB, history count limit 32.
Each file has its own observation time and raw-source hash. Reads are not an
atomic snapshot. Secret-valued keys are redacted and paths are symbolic.
Snapshot is sanitized evidence, not a byte-identical raw-file backup.

Pointer hash is identical at both snapshot reads:
`563fe18e496dbafb7d829e902f35c4d24d339f5329ed249083391cff3e5816f3`.
This proves stability between those reads only, not throughout the whole event.
No CodeDB MCP call, restart, service launch, process control, source edit,
consumer configuration edit, test rerun, commit, push or release performed in
this diagnosis. Only task-owned diagnostic files and this record were created.
Human Unity remains open; further lifecycle and new-client MCP acceptance are
not advanced through this anomaly.

## Subsequent user disposition

User subsequently elected to record the defect and continue current acceptance.
Open issues and boundaries are in BUGS.md. The next, separate recovered-baseline
functional gate is prepared in TEST3-RECOVERED-TARGET-CLIENT-TASK.md; it has not
been executed. This decision permits continuation planning and does not change
this attempt's anomaly/recovery result or authorize a repair/cleanup replay.

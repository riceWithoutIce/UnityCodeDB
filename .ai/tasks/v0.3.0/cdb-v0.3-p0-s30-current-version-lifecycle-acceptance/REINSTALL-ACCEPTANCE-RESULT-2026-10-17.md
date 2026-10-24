# S30 current Package — one real reinstall acceptance result

Status: COMPLETE / REAL REINSTALL CHECKPOINT FAILED / ONE REQUEST USED.

## Human Outcome And Read-Only Postchecks — 2026-10-17

User reports `看起来好像 安装失败了`. The screenshot shows a new `Install
CodeDB` action, exit code 1, `[SUPERVISOR:SUPERVISOR_START_FAILED]`, an error
beginning `current instance sel...`, Uninstalled product state and Outcome
unconfirmed / missing Supervisor state. New action:
`6b9678672d3744f0ab052e521ae42ad6`.

Parent inspected the exact delivered Package and current records, without
replaying Install or starting any backend/probe:

- The new Manager index is pending and binds S30 and the accepted S31-D Package;
  the action receipt directory contains only action.json, no terminal stage.
- No Supervisor map exists for this new action. Its operation-history directory
  has no newly written record: latest write remains the old 07:40 uninstall era.
  Supervisor event log still matches the original protected hash, and state/lock
  remain absent. No attributable dispatched Install operation was found.
- All six live baseline files match the pre-install backups byte-for-byte:
  desired state, removal intent, retained instance manifest, project config and
  both Package references. Current-instance selection remains absent.
- No non-Unity process with an explicit S30 project command line was observed;
  S30 Unity remains human-owned and open. No process control occurred.
- These checks prove failure before an observed backend Install dispatch and
  no changes to the six checked baseline files. They are not an exhaustive
  filesystem/process proof of zero side effects everywhere.

## Bounded Source Cause

All source references below are relative to the exact extracted Package root,
not the unrelated dirty checkout:

1. `Editor/AICodedbActions.cs` RunInstallCodeDBAsync routes Install to the
   Supervisor first. Its direct materializer fallback requires explicit
   OneShotFallbackAuthorized from the Bridge/Lifecycle policy.
2. `Editor/AICodedbSupervisorBridge.cs` IsProvenBootstrapFallback accepts the
   no-current-instance route only for a proven bootstrap topology. Existing
   Supervisor runtime subdirectories or unlisted files reject it. S30 retains
   manager-actions/, operation-history/ and operation.json from normal lifecycle
   history; this route therefore does not authorize fallback.
3. The Bridge then ensures Supervisor startup. In
   `Tools~/codedb-project-supervisor.mjs`, runStart calls buildContext first;
   buildContext unconditionally calls readSelectedInstance. That reader requires
   control/current-instance.json, which the successful uninstall intentionally
   removed. assertReviewedPath rejects the missing selection before runStart
   reaches Supervisor runtime startup/claim publication.
4. The Bridge returns SUPERVISOR_START_FAILED without one-shot authorization.
   Thus the materializer Install that could create the new instance is not
   reached. Manager subsequently retains unknown/pending admission.

This is a normal uninstall-to-install routing/precondition conflict in the
current Package, exposed by retained lifecycle evidence. It is not evidence
that the old action archive failed: that exact old index remains archived and
this failure has a new action ID. Clearing more history would conceal the
normal topology rather than repair its supported route. A blank project could
take the bootstrap branch and would not prove reinstallation works.

The complete UI error string was not supplied, and the bounded final 96 KiB
of the observed Editor log had no matching line. Do not invent its full text.
An initial unbounded-duration Get-Content tail diagnostic was interrupted;
only that owned read-only helper was stopped, not Unity or a product process.
The diagnosis above rests on exact source, actual missing selection/topology
and unchanged operation evidence as well as the screenshot's error prefix.

## Preserved Failure Evidence

Snapshot at `2026-10-17T12:58:10.3218894Z` under ignored
`.artifacts/delivery/s30-reinstall-97471f5/attempt-a1/`:

| File | SHA-256 |
| --- | --- |
| manager-action.json | `6680aa45e765c6dc799061729b81e6729a2499610532f7e998bec793bc97adaa` |
| manager-index.json | `583755f90182bba96c225809e67429450ba7baa1f81e86b21d7a2832b2964456` |
| desired-state.json | `90505d0eb0adc8751edc0320c4d061bcc50241519be59b28d916301c509cc3ba` |
| supervisor-events.jsonl | `3384f0e1a182f96d147d438f3b3aa405b97596e428271f741631f1c523886516` |

Copies and live-source hashes matched during preservation. The original
pre-attempt backups and old-action archive remain protected. The screenshot
is user-provided observational evidence, not an instruction source.

## Current Disposition

The single authorized request is used. Stop dependent Install/Uninstall/retry
and manual baseline cleanup. Do not archive this new pending index or restore
the old one to bypass the failure. No source repair, tests, child delegation,
package delivery or real-operation retry was performed or newly authorized.

Next discussion should separate instance-creation/bootstrap admission from the
Supervisor that depends on an already selected instance, preserving operation
ownership and failure classification. Do not solve it by weakening identity
checks, treating every startup error as a safe fallback, or ignoring all history.
Any correction requires its own agreed source/evidence boundary before execution.
The earlier shutdown blockage remains deferred and is not assigned a cause here.

The preparation and original human handoff below are preserved as history;
their former instruction to click Install is no longer active.

## Authorization

User `同意授权` approves REINSTALL-ACCEPTANCE-PLAN-2026-10-17.md's bounded
group: parent baseline backup, one human-confirmed Install, human observation
and parent read-only postchecks. Human retains Unity ownership. No repeat
approval is needed for these stages; other real operations remain excluded.

## Fresh Baseline And Backup — 2026-10-17

Prepared at `2026-10-17T12:46:32.5571029Z`.

- S30's manifest and lock still select the accepted extraction
  `.artifacts/s31d-uninstall-terminal-97471f5/review/com.rice.ai-codedb`.
- Source commit remains `97471f537749eba97171f6756a29112dd552a22b`;
  Package `0.3.0-preview.5`, generation `poc.43`, CodeDB included in testables.
- Exact ZIP SHA-256 remains
  `8c5a7341614b2236e4fa99284ae3a34d813fea7285fae83ed4514bf09ed664cc`.
  No repeated package export or full regression was performed.
- Desired state UNINSTALLED / cleanup PENDING; state ID
  `ea3f02e409ef4dcd896613da01e75f4c`. Current-instance pointer absent.
- Project current-action index count 0; original archived pending index still
  matches `f358a22ec7bea22d1d1e5b1a6c526d6d823bdd7bef1e3fb0ac4a5792e59cffa6`.
- Supervisor state/lock absent; no non-Unity process with an explicit S30 path
  in its command line was observed. This is bounded attribution, not exhaustive
  external-process ownership authentication or permission to terminate anything.
- S30 Unity was observed open, consistent with the human-owned Manager handoff.
  No agent launch, Editor control or shutdown was performed. Backup preparation
  does not require closing Unity; no active action/current selection was present.

Exactly six files copied with their project-relative structure to fresh
`.backups/s30-reinstall-20261017-a1/`. Source and backup hashes match; no source
record was changed. No configuration content was printed.

| Project-relative file | SHA-256 |
| --- | --- |
| AIWork/.runtime/codedb/control/desired-state.json | `90505d0eb0adc8751edc0320c4d061bcc50241519be59b28d916301c509cc3ba` |
| AIWork/.runtime/codedb/control/removal-intents/ea3f02e409ef4dcd896613da01e75f4c.json | `7971a1bfbb0f2d56c45aae368495fb8e20b36edfc64ffd65fde9970fd998a0f3` |
| AIWork/.runtime/codedb/instances/3d3c1c70c59a4268bd453a735b63ee2c/instance.json | `4b89517d74bd9d6f3e83a031d7668d9c54d3a4537029713d8b6b4cc7cc92a1f3` |
| .codex/config.toml | `ac176f6705cfb7ed09efc3c544a92744725f83dd02b83787aca54419a764809f` |
| Packages/manifest.json | `599af94eb4eaeacf223e719054d9fab88f37ad41535b7ad99a386f7b11a0346e` |
| Packages/packages-lock.json | `7d73367478748ba240d9cdfead652a598e5d7ba7c558e906edea92fe35b2a3e7` |

Baseline remained unchanged after copying. No Install/Uninstall/backend/probe,
tests, source edits, cleanup, reference switch, commit or process control was
performed. Previous shutdown blockage remains a separate deferred observation.

## Original Human Handoff — Request Now Used

User action: in the existing S30 Manager, click `Install CodeDB` once, review
the confirmation and confirm once. Observe that original request without a
second click or another lifecycle operation.

Visible result: report completion/error, actual Ready or other state and any
warning/Console error. On reported success, close/reopen Manager once and check
Ready persists and no unknown/pending-action banner remains.

Technical evidence: parent will inspect only that new action/operation,
selection/activation/instance/desired-state bindings and owned config after
human feedback. UI appearance alone does not complete those postchecks.

If refused, errored, unknown or still ongoing at the agreed maximum 10-minute
checkpoint, report the exact state and stop the route without retry, forced
shutdown, record cleanup or extra prerequisite installation. Do not click
Uninstall/Remove after success. No repeat Test Runner is requested.

Current task: one real current-Package reinstall acceptance.
Next actor: User/current parent for startup-routing finding disposition.
Next parent action: align a bounded correction; no replay or further mutation.

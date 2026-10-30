# Test3 exact-action Uninstall check

Date: 2026-10-26. Outcome:
`EXACT_ACTION_TERMINAL_MATCH / LOGICAL_DEACTIVATION_CONFIRMED / CLEANUP_UNRESOLVED`.
Grant: user "好的 继续" after the proposed bounded read-only check. No runtime
operation or diagnostic RPC was executed.

## Exact action and static state

Action `93bb43c28f80423094b4fe344c7b1b0e` maps to operation
`d7206415309d46adb8ab53dc1b8703a1`, maintenance materialize:Uninstall,
2026-10-26T07:15:36.516Z through 07:15:45.139Z. Map and operation have matching
project, Package, original owner/request/instance/generation/runtime identities.
Terminal is completed, exit 0, output complete, child close observed at
07:15:45.133Z, PID 106500, exit 0. Captured and intended argv both name the
expected Uninstall command and exact original operation/action. This is disk
attribution, not independent execution of the production terminal reader.

The Manager action manifest and resolved index bind the exact action/project/
Package; resolved disposition is CommandTerminal, current index absent.
Desired state is UNINSTALLED / PENDING, state ID
`32a9be7b4b1243bdb1e00f1967e81e76`. The removal intent names the prior selected
instance `bd0f2f01601b4b3990704ad9659f9348`, its recorded manifest and old
pointer hash. Project MCP registration is commented with that state ID and the
selected pointer is absent. This confirms logical deactivation. It does not
prove physical cleanup or disconnection of existing external MCP clients.

## Warning origin and handoff limits

Delivered `Editor/AICodedbSupervisorTerminalEvidence.cs:128` attaches
SUPERVISOR_HANDOFF_UNCONFIRMED to a successful recovered exact Uninstall terminal.
It is a limitation of recovered-result evidence, not an observed handoff error.
The original operation has handoff_queued=true, reason selected_instance_changed.
At the snapshot, Supervisor state/lock files are absent. This is disk presence
only: neither queued handoff nor absent files proves actual owner-process exit.
No process/lease liveness inspection was performed.

`Get-InstanceUninstallCleanupState` may legitimately return PENDING on retained
instance execution or later cleanup gates. This bounded snapshot does not
establish which gate retained this project. The earlier cleanup Text diagnostic
is not proved to be the cause of this Uninstall's PENDING or warning.

## Fresh Install risk from already retained evidence

The earlier hashed first-Install snapshot contains four failed Probe records:
008607a4424644afab1a7955d5acc823, 96aa2730203f42f4a143ed15bf44a972,
b6a3302c24af43ef8ab4cfb3bf9ba1ed, fa7c329609a54c9f857db0d8438d098b.
All have execution_disposition UNKNOWN, child null, no child_execution; errors
report exclusive lifecycle mismatch. These facts are from the earlier retained
snapshot, not a fresh post-Uninstall enumeration.

Current candidate `Assert-ProjectInstallExecutionAdmission` checks terminal
history dispositions; `Assert-ProjectInstallExecutionDisposition` rejects UNKNOWN
at codedb-instance-engine.ps1:5340. The historical check precedes relevance-based
child validation. It runs for Install when RICE_CODEDB_PROJECT_INSTALL_ADMISSION
is supplied. No actual new dispatch/admission was run in this check, so its
future environment, namespace contents and final verdict are not established.
If those UNKNOWN records remain and this admission path applies, they block
Fresh Install despite a successful logical Uninstall. This is a source-supported
continuation hazard from the original anomaly, not a newly observed Install
failure. Do not guess NO_CHILD or change/remove the records from this inference.

Recommend hold Fresh Install and align a narrow read-only investigation of
pre-child failure disposition production and the supported handling of existing
UNKNOWN records. Preventing future handoff mismatch alone may not resolve an
already affected project's history. This check does not authorize source repair,
history reclassification, deleting quarantine, draining clients or a new project.

## Evidence and execution boundaries

Artifact:
`.artifacts/tests/cdb-v0.3-install-quarantine-admission/test3-uninstall-handoff-01/snapshot.json`.
SHA-256:
`b1b873304861c56804aed45f29a683e3760e1b359e2ed9232805207c6ffed53a`.
One snapshot, 12 exact record/presence reads, metadata budget 256 KiB and
operation terminal budget 4 MiB, no directory/history enumeration in the checker.
Observed around 07:21:02Z (15:21:02 at UTC+8); per-record timestamps, not atomic.
Paths redacted; no Supervisor token-bearing state content captured. Source trace
used the delivered candidate-equivalent isolated source, without import/execution.
No CodeDB call, child service launch, process check/control, cleanup, source edit,
consumer edit, retry, Install, Unity cycle, commit, push or board update.

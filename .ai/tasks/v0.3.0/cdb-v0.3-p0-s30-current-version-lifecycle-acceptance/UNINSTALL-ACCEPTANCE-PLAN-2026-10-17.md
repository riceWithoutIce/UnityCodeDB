# S30 current delivered Package — one real uninstall acceptance proposal

Status: ONE HUMAN ATTEMPT USED / BACKEND UNINSTALL PASS / MANAGER CLOSURE BLOCKED.
S31-C source, delivery and agreed human entry/local-action checks are complete.
This plan resumes only the existing S30 normal lifecycle acceptance route.
It does not resume S31-B or Provider readiness, or reopen historical recovery.
Earlier S30 task handoff states remain historical; this dated plan records
the current baseline without rewriting those earlier failure observations.

## Read-Only Baseline

- Project: `<repository-root>/UnityFreshLifecycleValidationProjectS30`.
- Manifest and lock agree on
  `.artifacts/s31c-uninstall-entry-cc49c95/review/com.rice.ai-codedb`.
- Source commit: `cc49c95e84945308385f64640963716d93d070ea`.
- User already confirmed compilation, Test Run, Ready Overview/menu uninstall
  entries, Manager reopen/tabs and normal Unity exit all pass.
- During this preparation the S30 Unity lock was absent. Bounded observation
  of Unity/Node/PowerShell command lines found no explicit S30 project-path
  references. This is an observation, not process-ownership authentication,
  comprehensive descendant discovery, or permission to terminate a process.
- Desired state: INSTALLED; existing cleanup field PENDING. That field alone
  is not evidence of an unsuccessful first installation or new mutation rights.
- State ID: `ea3f02e409ef4dcd896613da01e75f4c`.
- Current instance: `3d3c1c70c59a4268bd453a735b63ee2c`, owner identity v2,
  activation epoch `26f187e4ea874164a103222905aada46`.
- Current selection hash:
  `4ddaaf30494676b32ad18380b514c7aaa5d9ff5aed5af40ca02f2592f51b3417`.
- Desired-state hash:
  `12ea9a95cdf65e2f6074597f668fde38644e18a0d4b57b36e0295ae545335ab9`.
- Actual instance.json hash equals selection's expected
  `4b89517d74bd9d6f3e83a031d7668d9c54d3a4537029713d8b6b4cc7cc92a1f3`.
- Installed identity is `0.3.0-preview.5 / poc.43`; its generation-manifest
  hash `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`
  matches the delivered generation. These targeted checks establish the named
  identity bindings, not a repeat full installation/materialization validation.
- Project `.codex/config.toml` exists. Its content was not dumped or changed.

## Meaning And Permitted Effects Of Proposed Operation

The existing confirmation describes logical project integration uninstall:
publish UNINSTALLED, remove current instance selection and only CodeDB-owned
project MCP registration keys. Backend may clean exact proven-owned content
under its existing retention rules or retain inert content with cleanup PENDING.
The Unity Package remains installed. Provider binaries, indexes, adapters,
custom runtime configuration, policy, business files, unrelated registration
and external processes remain protected. No manual deletion or blanket cleanup.

The shipped action calls the existing Supervisor/backend after local admission;
it is not the unfinished S31-B authenticated force-stop redesign. External
execution may be retained rather than forcibly stopped. A refusal remains a
failed/blocked uninstall attempt, not success merely because the entry works.

## Proposed Human Operation — Maximum One Confirmed Request

1. After User grants this plan, parent records a fresh targeted pre-operation
   baseline and repository-local copies of existing desired-state/current
   selection, selected instance manifest and project `.codex/config.toml` under
   a new `.backups/s30-uninstall-<run-id>/` root. Do not overwrite prior backups
   or create a machine-wide/project-wide snapshot. Backups stay local and are
   not committed. Unexpected selection/generation/reference drift stops this
   attempt for alignment; do not repair installation or rerun Install.
2. Human opens the existing S30 project and its Manager. Parent never launches
   Unity/MCP/BatchMode or executes the backend directly.
3. Human clicks Overview `Uninstall CodeDB from Project` once, reviews the
   existing confirmation and confirms once. Observe its original result.
   Do not repeat confirmation/clicks while busy or start another lifecycle action.
4. Human reports the exact result/detail and any Console error. Parent performs
   read-only checks of the named records and exact attributable operation
   evidence. No broad history recovery or whole-runtime scan.
5. For a successful result, human closes/reopens Manager to check the Install
   primary action and still-accessible menu Uninstall; do not click Install.
   Normal Unity shutdown is an observation; prior shutdown investigation stays
   deferred. Never force-close a potentially active mutation for this test.

No duplicate-click stress test, second uninstall, reinstall, version upgrade,
new project, package re-export/reference switch, custom process termination,
manual reset, physical archive or new subagent is part of this proposal.
If progress appears stuck, report the ongoing state without retry/force-stop.
The existing backend timeout is 600000 ms; no extra waiting/retry mechanism or
timeout modification is proposed. A timeout is not evidence of completion.

## Success And Stop Conditions

Success requires the attributable original operation to report UNINSTALLED,
the desired-state record to agree, current-instance selection to be absent,
CodeDB-owned MCP registration to be inactive/removed, protected unrelated
content to remain intact, and the Manager to offer Install for the uninstalled
project. UI text alone is insufficient. Cleanup COMPLETE and honestly reported
PENDING are distinct accepted logical-uninstall dispositions; PENDING does not
prove disk content or external processes have been removed.

NoActionNeeded with this installed baseline requires explanation; do not label
it a successful installed-to-uninstalled transaction without postconditions.
On Blocked/Unknown, error, timeout, partial result or ownership uncertainty,
stop the operation path, preserve exact evidence and analyze the bounded
cause before proposing any fix. No repeated attempts, environment reset,
identity bypass, external process kill or historical fallback is authorized.

Fresh Install after successful uninstall is a later separately aligned gate.
This plan does not assert that runtime stop, reinstall or version upgrade passes.

## Authorization And Handoff

User subsequently answered `好的 同意` to this concrete operation proposal.
That authorizes one human-confirmed logical-uninstall attempt plus the exact
local baseline backup and parent read-only postchecks above. No further
permission is needed for those steps. Human owns opening/operating Unity.
Parent does not launch Unity, run uninstall directly, terminate processes,
retry, reinstall or expand this operation into S31-B/historical recovery.

Preparation completed: fresh baseline matched; all four named files copied
and hash-verified under `.backups/s30-uninstall-20261017-152826/`. Backup content
is Git-ignored. The one human attempt has now been used. Backend logical
uninstall succeeded with cleanup PENDING, but Manager result closure is blocked.
See UNINSTALL-ACCEPTANCE-RESULT-2026-10-17.md. Do not retry or run Install;
next step is bounded repair alignment, not another lifecycle operation.

# S29 real uninstall/reinstall checkpoint evidence

2026-10-08. Authority: REAL-REINSTALL-VALIDATION-GRANT.md. Human operates Unity.
Candidate: d56f0e507b48af24a39f23411c06dbdd4e093084,
.artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb.

## Checkpoint 1 - Human uninstall completed

User supplied full command output and running/final Manager screenshots.
Action ID: 176147fac92b4e9ea205a7d1656eea30. Exit 0; elapsed 13.32 seconds.
The result is scoped to CodeDB-owned paths in this Unity project and reports:

```json
{"schema_version":1,"managed_by":"com.rice.ai-codedb","action":"UNINSTALL","outcome":"UNINSTALLED","phase":"COMPLETE","reason_code":"LOGICAL_UNINSTALL_COMPLETE","mutated_scopes":["instance_activation"],"cleanup_state":"PENDING","next_action":"The prior instance remains inert and pending; use Install CodeDB to create a fresh integration.","exit_code":0,"detail":""}
```

The output states no external MCP process was stopped. The final Manager shows
CodeDB uninstalled from this project, Package retained, automatic installation
and watcher attachment disabled, and an Install CodeDB button. This agrees with
the reported logical-uninstall result and the permitted inert PENDING closure.
It does not prove physical cleanup complete. The original historical failed
Install warning remains; it is not the new Uninstall result and is not erased.

Checkpoint disposition: HUMAN_UNINSTALL_RESULT_PASS. Evidence is the human-supplied
backend result plus UI, not a separate agent audit of every live file/process.
The existing backend must still enforce current ownership/removal-intent safety
when the next Install runs. No shell mutation, receipt rewrite, source fix or
agent-controlled Unity action was performed during this checkpoint assessment.

Next under the same grant: one human-confirmed Install CodeDB action, followed
by full output/new action ID and final Manager screenshot. No fresh authorization
required. Stop at first failure; no repeated click, cleanup shortcut or replay.
Install, new activation, Ready and client tool exposure remain unverified.

## UI follow-up - Progress indicator not visible

User reports the progress bar is missing. The in-progress screenshot at 7.4 seconds
shows In progress / Running and elapsed time, with disabled Uninstalling button,
but no visible progress bar in the activity region. Record P3 / FOLLOW-UP; the
operation reached its completed result and the supplied evidence shows no
execution failure or unsafe mutation attributable to this display issue.

Cause is not diagnosed from a static screenshot. No claim about animation across
frames or intentional conditional rendering is made. This does not block the
already-authorized fresh-install checkpoint. Later UI work should clarify the
running indicator in this activity region, without inventing completion percentages
or restoring the previously rejected header progress bar. No UI fix is authorized
by the current operational grant; return it with the final validation summary.

## Image provenance

- codex-clipboard-b335fc0f-9de7-4278-97a4-2008201dffb1.png (user Temp attachment):
  SHA256 4FF378DF0230024257A0C2029EDACBC376EEFDD7B763ECFCC3B3C747EB066BF1.
- codex-clipboard-e2a4308b-8657-4160-82b2-4f5bde798218.png (user Temp attachment):
  SHA256 1B22C26D9C0A442A2D72C9467457F1E132F43659A1EB5A192735F76041B0F532.

Status: HUMAN_UNINSTALL_RESULT_PASS / CLEANUP_PENDING /
AWAITING_HUMAN_FRESH_INSTALL_RESULT / UI_PROGRESS_FOLLOWUP / S29_PARTIAL.

## Checkpoint 2 - Fresh Install failed; operational sequence stopped

User reports Install failed and supplies complete copied output plus running and
final screenshots. Action: f14c0524af324b7a802335a393483fa0. Exit6, elapsed32.51s.
Output collection incomplete; project effects remain unproved. The reported
prerequisites are CURRENT (Node v24.14.1 / Provider0.5.0-28e3912-c2), and the
materializer reports publication of immutable generation poc.40. Candidate
cleanup was deliberately withheld because its execution effects were unproved.

Reported COMMAND_RESULT:

```json
{"schema_version":1,"managed_by":"com.rice.ai-codedb","action":"INSTALL","outcome":"BLOCKED","phase":"CANDIDATE","reason_code":"INSTANCE_EXECUTION_OBSERVATION_INCOMPLETE","mutated_scopes":["host_runtime","instance_candidate"],"cleanup_state":"PENDING","next_action":"Review the original failure and retained or unknown candidate effects before another confirmed project change; no automatic replay is authorized.","exit_code":6,"detail":"Instance Install failed without selecting an unverified candidate. Instance execution observation is incomplete; candidate effects remain unknown. Observed exit: 0. [Package-owned native client output remained locked after the direct process exited.] [Package-owned native client output remained locked after the direct process exited.]"}
```

Manager additionally reports: "Manager action output did not reach EOF after the
child exited; captured output may be incomplete." The final screenshot records
the new action outcome with uncertain admission/project effects and blocks new
project changes. The earlier failed Install history remains separately visible.
The Uninstalled presentation must not be interpreted as proof of an empty or
safe-to-retry project after this new candidate attempt.

### Bounded source-only correlation

The inspected source files match their exact delivered Package counterparts.
No live processes, handles, candidate files or receipts were inspected or changed.

- Tools~/materialize-codedb-host-payload.ps1, Invoke-BoundedNativeProcessWithFileOutput:
  Start-Process redirects stdout/stderr to files. After observing direct-child
  exit, output collection has a shared5second deadline. ReadAllText catches
  IOException and retries; at the deadline it marks collection incomplete and
  emits the quoted locked-output diagnostic. This label does not establish the
  exact exception cause or which process/handle holds a file.
- Tools~/invoke-codedb-manager-action.ps1: pipe reads have a5second drain window
  after child exit; unfinished reads produce outputDrainIncomplete and the quoted
  EOF diagnostic. This is a separate outer observation from native file reading.
- Tools~/codedb-instance-engine.ps1: an InstanceExecutionObservationIncomplete
  error maps to the reported reason code and BLOCKED result. A direct child's
  observed exit0 does not establish complete effects or successful installation.

Working hypothesis for further read-only diagnosis is output/process lifetime or
handle ownership across the execution chain, including descendants/redirection
resources. The actual holder and whether the two observations share a cause are
NOT PROVEN. Do not fix by silently sharing reads, extending waits, accepting exit0,
clearing history or killing unrelated processes without resolving the contract.
Previous45tests prove their bounded result-semantics cases, not this real native
process/drain path; prior evidence remains valid but real installation is blocked.

The same missing-progress-indicator symptom is visible during Install at3.9s,
with In progress/Running and elapsed time. Extend the existing P3/FOLLOW-UP to
both Uninstall and Install; do not create two independent UI repair tasks.
Current failure output also contains garbled warning text; record observation
without inferring its encoding cause or treating it as the installation cause.

Attachments:

- codex-clipboard-528e81c1-3139-455f-b174-8d0b84c86d7b.png:
  SHA2568F6940D1A99892D0437849B715D34CB62770AF79F0A3AB2A4C7193518A47A635.
- codex-clipboard-0ca6c5ff-6b18-4111-af77-bc91ec8f160b.png:
  SHA25685FB72C4D9893DA31E3512B50F42818851E93AD5F6805A1387158E8248E61D98.

Final checkpoint state: UNINSTALL_PASS / FRESH_INSTALL_FAILED /
EXECUTION_OBSERVATION_INCOMPLETE / CLEANUP_PENDING / S29_PARTIAL.
The authorized operation sequence stops on this first Install failure. No retry,
new uninstall, cleanup, candidate selection, source/UI fix, Unity/client restart,
commit or package/reference change was performed or authorized by this result.
Next proposed scope: bounded read-only execution/output ownership diagnosis,
then align a coherent repair and its actual-process regression coverage.

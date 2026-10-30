# Missing child identity: producer, recovery and Install - 2026-10-26

Outcome: `READ_ONLY_ANALYSIS / EXECUTION_CLOSURE_GAP_IDENTIFIED`.
No product edit, consumer mutation, test invocation, Install retry or process
control in this continuation. Existing uncommitted diagnostic repair is retained.

## Scope and sources

User authorized continued analysis after the missing-child diagnostic result.
Read closure: Supervisor producer/capture/finish/recovery functions, direct
Install/history-retention consumers, existing focused test cases, host-action
contract, workflow baseline rules and four already identified consumer records.
Source checkout: `<repository-root>/.worktrees/cdb-v03-install-quarantine-admission`,
base `09d345d96ec782be2ac101016d8b75b14bce6000` plus the diagnostic guard.
Consumer: `<external-test-root>/CodedbTest_2`.

## Observed retained records

All four named records were reread without mutation. Each is failed/failed,
has CHILD_ADMITTED and null child, and has false timed_out, output_overflow
and output_drain_incomplete. These fields do not prove child identity or exit.

| Operation id | Name | Error category | SHA-256 |
| --- | --- | --- | --- |
| `3d964e5ddbd8443d98e69f3c0754b361` | materialize:Probe | EDITOR_OFFLINE | `e080625e39ec50e88134dd3ef1ab52097dc03fb650ce78722f3b9d9e026a9ab9` |
| `812cc11bc11443e19e6e9cbe712d7110` | materialize:Probe | prior child admission unresolved | `7785650a50d8368b2f67bb0f3284cd986165b67bd037b912af806a53c5819fbd` |
| `ab14c017078c42c18b2bfde25262159d` | materialize:Upgrade | interrupted before durable child identity | `36cd40646c218dbdfa4751765e9eaec82c44c1d0e34a18efccfa1184dc77c82c` |
| `b5e149618d7444abb193b3ef6a325963` | materialize:Upgrade | EDITOR_OFFLINE | `5b702df0edc6976ca11ee3add4a1817328a9875677b7b49ba553f6f58d39260e` |

The records date to 2026-10-22, predating the new quarantine candidate. No
new runtime experiment was performed. Their terminal error strings cannot
identify the exact historical capture schedule, actual process lifetime or
Editor UI state. In particular, EDITOR_OFFLINE reports missing valid lease
evidence; it does not prove the user had closed Unity.

## Source chain

References below are to the isolated checkout's Package source.

1. `Tools~/codedb-project-supervisor.mjs:2551-2573`:
   prepareOperationChildEvidence publishes CHILD_ADMITTED and null child
   before spawn. An admitted prior child without identity blocks another spawn.
2. `Tools~/codedb-project-supervisor.mjs:2523-2548,2576-2618`:
   identity capture is delayed and reads OS evidence. If the exact ChildProcess
   has exited and the query says exists=false, capture resolves after persisting
   child_exited_before_identity_capture; child remains null. This is a current
   source path, not only a legacy-record format.
3. `Tools~/codedb-project-supervisor.mjs:3183-3239,1331-1357,2172-2184`:
   runChild waits for capture at close and returns output; finishOperation
   persists completed/failed and overwrites phase with that terminal label.
   It preserves CHILD_ADMITTED. The compact result does not carry a distinct
   durable certificate of the observed close or its relationship to admission.
   A complete command-output result is not a captured process identity.
4. `Tools~/codedb-project-supervisor.mjs:2432-2436`:
   recovery runs only for running operations; missing child becomes failed.
   It neither reconstructs missing identity nor downgrades to NO_CHILD.
   Already failed historical records do not enter this recovery branch.
5. `Tools~/codedb-instance-engine.ps1:5298-5356`:
   Install classifies every discovered history document's execution disposition
   before skipping unrelated deep validation. CHILD_ADMITTED requires child
   structure; a later successful canonical action/Uninstall does not supersede
   unresolved history. The new guard improves only the refusal message.
6. `Tools~/materialize-codedb-host-payload.ps1:10226-10335`:
   retention keeps unknown/incomplete records. It selects completed routine
   records only and calls the same execution-disposition guard. Neither elapsed
   time nor additional successful operations makes these four records eligible.

## Interpretation and limits

The pre-spawn durable admission is intentional crash safety. Refusing genuinely
unresolved execution is correct under the frozen contract. The gap is between
terminal child observation and the durable evidence accepted by later readers:
current source contains a non-crash, short-child-exit path which can retain the
same blocked representation as interrupted/unknown execution. This means a
clean project alone cannot demonstrate that the condition cannot recur.

This is source evidence of reachability, not a runtime reproduction or proof
that all four historical records came from the short-child branch. Their exact
origin remains limited by existing durable evidence.

`Tests~/test-codedb-project-supervisor.mjs:427-461` deliberately checks that
capture failure, admission error and missing second capture preserve sticky
CHILD_ADMITTED and block another child. Those tests establish conservative
refusal; they do not establish a normal short-child-close-to-later-Install
lifecycle closure. No unchanged tests were rerun for this analysis.

The host-action contract (execution-disposition amendment, lines 863-888)
explicitly prohibits inferring NO_CHILD or repairing old ambiguous records.
Any new durable terminal-proof route needs its producer/consumer contract and
test boundary aligned first. It must not reinterpret old null child records
as proof of no execution, or use success/exit code alone as ownership evidence.

## Recommended next bounded objective

1. Freeze the distinction among positively unstarted, spawned-and-observed-closed,
   and interrupted/unobservable execution. Reuse existing authority where
   sufficient; do not invent a new record format before checking that boundary.
2. Define a narrow isolated regression for pre-spawn failure, short child close
   before identity capture, crash before terminal persistence and identity-query
   failure. Verify both producer terminal evidence and the Install reader,
   with explicit synthetic/real-child evidence classes and no consumer replay.
3. Repair only the demonstrated missing closure. Preserve sticky refusal for
   genuinely unknown/crashed execution. This is a separate scope from the
   completed null-parameter diagnostic guard; no repair was implemented here.
4. Keep CodedbTest_2 as the historical blocked sample for now. Decide its
   preservation/recovery disposition separately. After current-source closure
   is verified, choose a clean normal-route acceptance baseline. A fresh-project
   PASS must not close this old project's recovery gate.

Workflow `safe-execution.md:361-428` requires bounded route reassessment when
historical state prevents exercising the intended normal route. It permits a
user-selected new project or bounded reset but does not authorize either here.
Do not deliver merely to replay a known refusal, delete historical records,
weaken missing-identity checks, or extend this analysis into all-history repair.

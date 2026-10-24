# Reopen Probe: unresolved prior child identity

Status: RECORDED FOLLOW-UP / NO IMPLEMENTATION OR REPRODUCTION GRANT.
Origin: ordinary CodedbTest_2 reopen after S40 delivery/reinstall, 2026-10-22.

User disposition on 2026-10-22: retain this issue and defer analysis to the
separate [identity-handoff/heartbeat task](../cdb-identity-handoff-heartbeat-followup/TASK.md).
The new task groups investigation entry points without claiming their causes
are shared. No further analysis or implementation starts under this record.

## Established facts

One Probe terminated with exit 1 and exact message:
`Prior child admission has unresolved identity; another child is blocked.`
Its terminal record has CHILD_ADMITTED and child=null. Manager displayed
Needs attention. A later automatic Probe/readiness observation succeeded;
the user reported Ready after approximately one minute. Full outcome/evidence
is in POST-REINSTALL-REOPEN-RESULT.md.

The exact guard is in the delivered `Tools~/codedb-project-supervisor.mjs`,
prepareOperationChildEvidence: a new child is refused when the prior admission
is CHILD_ADMITTED without durable child identity. This is not an instance
selection error or proof that installation was lost. The observation does not
establish whether a previous child was live, dead, unobserved or interrupted.

## Narrow static lead, not a proven complete cause

The Probe/Upgrade dispatcher calls ensureCoordinatorWithAttribution and then
runMaterializer under the same operation. Both can admit child processes.
queueChildEvidenceCapture has a path where a short-lived child exits before
identity capture: it persists child_exited_before_identity_capture and resolves
without a child identity. The guard still rejects another admission with
child=null. This is a plausible producer/consumer edge to trace, not a
reproduced explanation of this particular event. A failed terminal alone does
not establish which earlier path produced its missing identity.

If selected next, begin with bounded static tracing of that same-operation
child handoff and the existing close/identity evidence consumers. Determine
whether there is attributable exit evidence sufficient for a next child, while
preserving refusal for genuinely unknown/live children. Do not delete evidence,
weaken the guard, assume process disappearance equals success, or activate
older unaccepted writer-lifetime WIP as an expedient.

The Manager's eventual recovery and failure-display policy may need a separate
assessment after backend causality is clear. Do not silently broaden this to
Supervisor redesign, historical recovery, all unknown states or the deferred
Ready -> Unconfirmed task. Similar UI timing is not shared-cause evidence.

Current disposition: nonpersistent normal-startup warning with genuine failed
operation evidence. No data/config corruption, unsafe process stop or
continuing normal-path outage was established. This record neither promises
release readiness nor approves risk acceptance for a later release.

No reproduction, source change, harness run, new Package, consumer switch,
MCP call, client reconnect, Unity action or process control is authorized by
this record. Present any repair/test proposal to the user after static cause
alignment. Existing passed gates are not rerun merely to refresh this item.

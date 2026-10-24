# S40 ordinary reopen after reinstall

Date: 2026-10-22 (user local date).
Status: ORDINARY REOPEN EVENTUAL CONVERGENCE PASS / STARTUP WARNING RETAINED.
This is a qualified smoke result, not a clean startup or full lifecycle verdict.

## Human evidence

Following the ordinary close/reopen proposal, the user reported no errors but
Manager Needs attention. Screenshot diagnostics showed:

`Prior child admission has unresolved identity; another child is blocked.`

The user then reported return to Ready after approximately one minute and
provided the Ready screenshot. Duration is a human estimate, not a measured
transition trace. No extra close/reopen, manual recovery or button action was
reported between those observations. The development chat did not perform any
Unity, process-control, runtime-mutating or CodeDB-tool operation.

## Bounded read-only technical evidence

The selected pointer still named instance `a492a5e936c14e4da3ed7e4cc7c8c16c`,
epoch `063aa347f49a4b9f955a5447f293a0ac`, generation `poc.44`; desired state
was INSTALLED / cleanup PENDING. This is the post-S40 Install activation.
No dedicated pre-reopen baseline was captured before the human acted; existing
post-Install and target-chat records provide the preceding selection evidence.

The actual failed operation was `812cc11bc11443e19e6e9cbe712d7110`,
`materialize:Probe`, owner epoch `03e2797f6bf940b1a5df867305d2d57d`, terminal
exit 1 at 2026-10-22T02:35:55.223Z. It retained execution_disposition
CHILD_ADMITTED and child=null, with the exact error shown in the screenshot.
This was a real recorded Probe failure, not merely a conjecture from the UI.

An existing independently written Supervisor observation subsequently reported
the same selected instance/activation as core_ready / COORDINATOR_OPERATIONAL.
The retained sanitized snapshot was captured at 2026-10-22T02:38:22.575746Z;
its readiness observation was 2026-10-22T02:38:22.377Z, with completed Probe and
exit 0 under a later Supervisor owner epoch. Human final Ready agrees with this
operational record. Reading the screenshot itself does not perform a new check.

A stale prior Supervisor snapshot also retained a different running
`materialize:Upgrade` operation with CHILD_ADMITTED and child=null. It is a
separate operation, not proof of what happened to the failed Probe's child.
Its process liveness or exact exit was not authenticated in this observation.

## Disposition and retained question

The expected final Ready outcome recovered within the proposed observation
window, so the ordinary-reopen convergence checkpoint passes with a warning.
The startup warning and actual failed Probe remain evidence; do not relabel
this as an error-free startup. No continuing unavailability is established by
this run. Do not infer that live queries were available during the transition.

Record the narrow follow-up in REOPEN-CHILD-ADMISSION-FOLLOWUP.md. Do not merge
it into the earlier Ready -> Unconfirmed task merely because both recover.
Do not automatically repair, test again, clear records or change admission
guards. Existing Install and target-client functional PASS results remain valid.

This result does not close original live-old-reader regression coverage,
formal response/session identity, physical cleanup, PS7, full Domain Reload
identity, performance or public release. No second real lifecycle cycle ran.

Canonical evidence:
`<repository-root>/.artifacts/tests/s40-retained-mcp-install/post-reinstall-reopen-diagnosis-a/`:
snapshot.json contains selected safe fields/hashes, current-instance.json,
human-needs-attention.png, human-returned-ready.png and human-recovery.json.
Connection secrets and unrelated process command lines are excluded from the
retained diagnostic projection. Original failure and stale source files were
not modified. The recovery update uses the user's report and adds no new
runtime observation or tool call. Stop this bounded observation here.

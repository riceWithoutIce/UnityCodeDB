# S32 F2 history-execution semantics reassessment — 2026-10-18

## Trigger

- Blocked path: normal uninstall with retained Supervisor history -> new Install.
- Repair iterations: 2/2 (initial guard snapshot and user-approved F1/F2 repair,
  both followed by scoped acceptance review).
- Independent causes: original two findings; remaining issue is F2's immediate
  normal-history regression, not a new broad audit.
- Diagnostic-only checkpoints: 0/3.
- Repair attempts: two mechanical and two semantic correction allowances consumed
  in RESULT's repair ledger. No additional source/test run is authorized here.
- Structural signal: consumer equates missing child identity with unfinished
  execution, while the original producer deliberately emits no child for a
  normally completed attach/no-spawn operation. This needs a semantic boundary
  decision rather than another generic historical exception.

## Frozen State

The repaired source is bound by RESULT's original table plus two repaired hash
overrides. HEAD remains `97471f537749eba97171f6756a29112dd552a22b`.
repair-e HARNESS and immediate route/result regression passed. Independent
VERIFICATION-F1-F2.md is terminal and read-only. Both children stopped.
Parent verified 11 source/test hashes and ten protected inputs after review.
Real S30 pending action, runtime, config, backups and delivered Packages remain
protected and unchanged by this task. No delivery or real retry occurred.

## Causal Summary

- F1 original process-relevance defect is closed. Related unknown/live identity
  still refuses; unrelated inaccessible same-name processes no longer block.
- F2 unsafe incomplete-result acceptance is corrected. Complete terminal flags,
  structure, timestamps and referenced identity checks are enforced.
- F2 adjacent supported-history refusal remains: engine :4947 requires non-null
  child for every history record before inert/current-reference selection.
- Original Supervisor initializes child null, and ensureCoordinator returns
  success with action attached when the Coordinator is already ready (:1916),
  without spawning/capturing a child. finishOperation persists successful
  completed history. It remains after a later successful uninstall.
- That no-spawn record is rejected by the new Install guard. Existing harness
  constructs child-bearing records and does not cover this production shape.
- compactResult (:2060) stores exit/stdout/stderr/completeness but does not retain
  result.action=attached. No existing durable no-spawn discriminator has been
  established by this review; do not assume null child means no spawn.
- Pre-effect authority publication for original producers was checked and has
  no additional finding. No request for all-machine process guarantee follows.

## User Decision Needed

Recommend a bounded REFACTOR of the F2 producer/consumer execution semantics:
first determine whether original durable authority can distinguish a successful
no-spawn operation from missing post-spawn identity; if insufficient, present
the smallest explicit producer/consumer contract change and direct tests before
editing that currently out-of-scope producer. Preserve current unknown/live
refusal and do not migrate/backfill history or accept all null-child records.
Historical applicability and the current S30 pending action remain separately
declared; adding a future field does not make old ambiguous records proven.

This document records a recommendation, not authority to refactor, edit the
Supervisor, replay acceptance, clean history or continue tests. User chooses
CONTINUE_PATCH, REFACTOR, REDESIGN, DEFER or STOP before the dependent route resumes.

## Handoff

- Current task: S32 Install project-command closure
- Current status: ROUTE_REASSESSMENT_REQUIRED / source not accepted
- Next notification: User/current parent Planner
- Next action: align supported no-spawn versus unknown execution semantics
- Human decision required: route disposition and any revised bounded envelope

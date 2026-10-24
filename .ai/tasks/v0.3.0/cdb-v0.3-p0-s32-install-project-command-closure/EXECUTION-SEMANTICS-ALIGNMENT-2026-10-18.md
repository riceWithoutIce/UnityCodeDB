# S32 execution relevance and no-child semantics alignment

Status: APPROVED / bounded producer-consumer refactor in progress.

## Approved direction

Following ROUTE-REASSESSMENT.md, user `好的 同意` accepts the small-refactor
direction: select current/relevant execution authority before terminal validation;
distinguish proved no child, identified child and unknown execution; do not audit
every old generation or infer historical safety from a null child. The accepted
plan explicitly requires presenting a minimal producer/consumer scope if the
existing durable evidence is insufficient. No new source repair was performed.

## Bounded current-source findings

- Supervisor ensureCoordinator returns action=attached when already ready
  (`codedb-project-supervisor.mjs:1916`) without starting a child.
- compactResult (:2060) retains exit/output/completeness, but discards action.
  finishOperation (:1314) overwrites phase with completed/failed. Thus phase or
  terminal success is not an established durable no-child discriminator.
- prepareOperationChildEvidence (:2407) writes phase and child:null before spawn;
  capture (:2381) records actual identity afterward. Capture failure can leave
  child:null, and finishOperation erases the intermediate phase distinction.
- shutdown (:1630) removes its owned state and lock after a best-effort stop,
  without publishing an independently validated owner-epoch execution-closure
  record. File absence alone therefore cannot certify an old epoch as closed.
- Instance retirement controls bind instance/generation/manifest and retiring
  fences. Holder observation covers existing leases/editor leases/Coordinator.
  It does not add a durable all-Supervisor-operations-retired proof. Removal intent
  operation_id is its own removal state identity, not a Supervisor epoch closure.

Conclusion: current records establish useful project bindings but do not by
themselves close the specific no-spawn-versus-missing-capture distinction, or a
general historical epoch-closure exception. Do not grant either from absent
owner files, successful later uninstall, terminal labels or child:null alone.

## Minimal proposed scope for a new approved envelope

Keep existing operation history as the single result store. Add a small explicit
execution-disposition contract to those existing operation records and update
only its direct readers/tests. Exact field spelling/schema is to be frozen before
implementation; required semantics are:

- UNKNOWN is conservative default and applies to absent old fields.
- NO_CHILD is asserted only by an original branch that proves no child was
  admitted for that operation. It must never overwrite an earlier spawn admission.
- CHILD_ADMITTED is durably published before a managed child can start. Failed
  capture/timeout/error cannot turn it into NO_CHILD. Existing child identity is
  still required to prove a spawned execution is absent; repeated child admissions
  cannot discard an unresolved earlier child.
- The result's complete-success/failure semantics stay independent. NO_CHILD does
  not bypass identity, terminal completeness, owner/admission or instance checks.
- Current/referenced/unclosed authority is selected before detailed terminal/child
  validation. Minimal bounded project-local discovery must still detect unfinished
  operations hidden by an overwritten canonical record. Historical presence alone
  is not an active-execution claim; inert status needs the declared evidence.

Proposed production edits: existing Supervisor operation producer/serializer and
only its necessary strict operation readers, current Install admission helpers,
direct test fixtures and S32 contract append. Original writer/Manager route,
initialization, process control, generation identity and external state stay out
of scope. If this requires additional independent ownership infrastructure,
return the boundary instead of implementing it under this proposal.

Tests must use original production serialization of the already-ready no-spawn
route and child-admission/capture-failure route into the actual PowerShell
reader, plus current/inert/hidden-unfinished selection cases. Handwritten
child-bearing records alone are insufficient. Existing local tools and fresh
repository-local fixtures only; no real Coordinator/Provider or Unity launch.

## Existing historical state

No migration/backfill or implicit historical acceptance is proposed. Adding a
field fixes future attributable records; it does not prove old null-child
records safe or unblock the actual pending S30 action. Any irreducibly ambiguous
old relevant state needs separate user disposition; no automatic reset, cleanup,
new validation project, real retry or uninstallation is authorized.

## Handoff

- Current task: S32 execution relevance/no-child semantics
- Current status: read-only assessment complete; source unchanged
- Next notification: User/current parent Planner
- Next action: agree the minimum existing producer/consumer contract scope before
  new source/fixture repair and targeted independent review
- Human decision required: explicit producer/consumer scope approval; no delivery
  or real-environment authority is implied

User `批准` approves the concrete producer/consumer proposal and Coder -> targeted
Verifier on 2026-10-18. TASK.md and DISPOSITION-REFACTOR-PLAN.md now freeze its
contract, allowlist, evidence/budget and exclusions. Earlier pending language is
historical. No old record is newly considered safe by this approval.

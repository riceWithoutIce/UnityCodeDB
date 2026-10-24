# Route Reassessment: S25 Gate C Install Unknown Outcome

## Trigger

- Blocked acceptance path: the human-owned `Install CodeDB` action has a durable
  admission and writer claim but no terminal or start-failure receipt. Manager
  correctly reports `Outcome unconfirmed`; another Install is not admitted.
- Structural signal: S27's `ReconcileHistoricalUnknown` contract and Manager
  marker consumer are bound to one old `RemoveIntegration` action, stage, script
  identity, and `poc.34` project proof. Adding another hard-coded Install branch
  would repeat the same special-case design and cross-component classification.
- Repair iterations and diagnostic-only checkpoints: not used to justify this
  stop. The immediate structural trigger in Workflow v2.4 applies.
- Disposition: `ROUTE_REASSESSMENT_REQUIRED`. No reconciliation command, new
  Install, receipt synthesis, process termination, or runtime edit is authorized.

## Frozen Evidence

- Source HEAD: `aaea58a0262c99a7901b39a8309e94b126111b00`. Its four-file fix
  supplies the Supervisor owner command-line hash and bounds a child-output
  drain before the Manager writer publishes a terminal receipt. Source and
  extracted-Package focused tests passed, but the fix cannot retroactively
  create a receipt for an already consumed action.
- Commit-derived candidate ZIP SHA-256:
  `794196ff5c530ce2b12b4d79095b5dbc468502a22ecccfecee85496ea30908ee`.
  The validation project's CodeDB dependency points to that candidate; its
  Package and exact-ZIP closure passed. Unity has been human-opened. No new
  Install click is requested.
- Pending action ID: `efd96a0fe8aa41a898960749de6e6ecf`; stage ID:
  `59b833ddfdf6242bc0aa28e28ecaf265b19311f0a8a8ff98264357053d4ed7a7`.
  The original stage still contains only `admitted.json` and `claim.json`.
  The original writer is no longer visible. Neither fact proves its command
  outcome or independently proves the business child is quiescent.
- Project-side evidence is distinct from the missing command result: desired
  state is `INSTALLED / PENDING`; the current selection is instance
  `2a71af1adaa140ff9cf63f2451b1579e`, generation `poc.39`; the activation
  operation is `INSTALL / COMMITTED`. Selection, instance, generation manifest,
  and worker hashes matched during the preceding read-only check. This is not
  an authenticated terminal receipt for the Manager action.
- The new Package-owned Supervisor was observed on the current candidate. Its
  durable owner evidence includes `command_line_sha256`; after one automatic
  `materialize:Upgrade` exit 0, its durable readiness was `core_ready` with
  `COORDINATOR_OPERATIONAL`. Manager still displayed the old unknown-action
  block. Live MCP/query and stable Manager Ready remain NOT RUN.
- Inherited dirty task records, Package lockfile/project settings, immutable
  artifacts, historical action records, and the validation runtime are
  protected. No source or runtime mutation was made in this reassessment.

## Contract Conflict

- `Get-HistoricalUnknownActionEvidence` admits only old action
  `3049af7cfc9f4260928e3f89d18672c0`, old stage, one historical Package
  directory, `RemoveIntegration` arguments, and fixed writer/materializer
  hashes. The current index contains multiple historical Package directories.
- `Get-HistoricalUnknownProcessProof` excludes a live `RemoveIntegration`
  child, not an Install child. `Get-HistoricalUnknownProjectProof` requires
  `INSTALLED / COMPLETE`, no removal intent, and `poc.34`; the current project
  is `INSTALLED / PENDING` on `poc.39` and retains a prior removal intent.
- `AICodedbManagerActionJournal` likewise recognizes only the old S27 action,
  stage, proof source, and writer hash for an unknown-outcome marker. Merely
  publishing a new marker would be rejected or, if loosened locally, would
  create two competing proof authorities.
- More fundamentally, the current presentation and admission path lets the
  old command's missing receipt block independent current-state observation.
  Extending S27's Remove-specific marker to Install would repeat the coupling
  rather than answer whether the product is Ready now or whether a *new*
  project change is safe to admit.

## Recommended Route

Recommend limited-scope `REDESIGN` of three responsibilities, not a general
Manager action-framework rewrite or an expanded S27 reconciliation profile:

1. **Historical command outcome:** keep the exact Install admission, claim,
   action and stage identities, and absent terminal unchanged. Its command
   outcome remains `unknown`; do not forge a receipt, infer no effect, replay,
   clean up, or reclassify the S27 Remove marker.
2. **Current product status:** allow a fresh, authenticated, project-bound
   read-only status observation independently of that historical outcome.
   Manager may show Ready *only if the current status proves Ready*, alongside
   a separate, persistent warning that the old Install result is unknown.
   Current `INSTALLED / PENDING`, the committed activation record, or
   Supervisor `core_ready` alone do not establish Manager Ready. Status
   observation is not an Install or a mutation-admission grant.
3. **Next project change:** before a newly confirmed Remove, Install, or
   related project mutation, establish under the owning project/action
   boundaries that the relevant old writer and any business child capable of
   changing this project have stopped, then check current project state and
   operation lock for conflict. Incomplete process visibility or ambiguous
   state blocks that new change. Recheck immediately before admission and
   retain the backend's point-of-effect authority checks. A passing gate
   authorizes only ordinary fresh-action admission; it does not establish
   the old command's result or bypass Install's `UNINSTALLED / PENDING`
   precondition.

The bounded proof concerns this project and the old action relevant to the
proposed change. It does not require one historical Package directory, no
other retained removal intent, an exact `poc.39` generation, or the absence
of unrelated PowerShell processes. A retained intent blocks only when the
owning project-control contract determines it conflicts with the proposed
mutation. Do not terminate processes or modify historical records to make
the gate pass. Preserve the existing S27 Remove evidence and interpretation.

Implementation should stay within the Manager presentation/status adapter,
action admission, and directly owned project-control boundary needed for
these three responsibilities. Stop for a new route decision if a new daemon,
global process policy, general historical-action migration, or unrelated
mutation contract is required. Acceptance should separately cover unknown
history with fresh Ready/non-Ready status, read-only status while new actions
remain blocked, relevant live/stopped/unobservable writer and business child,
current project state/lock drift, unrelated historical Package/process data,
changed generation, old S27 marker compatibility, and normal fresh-action
preconditions. Focused source/synthetic evidence precedes an independent
review; real-project proof and human Unity observation are separately
authorized gates. No code edit, test, commit, Package switch, Unity action,
or publication follows from this route decision alone.

## Decision And Handoff

- User disposition: limited-scope `REDESIGN` agreed. This document and the
  Host Action contract record the design decision. The continuous eleven-path
  implementation and bounded evidence packet is now frozen in
  `../cdb-v0.3-p0-s28-manager-history-status-change-admission/TASK.md`;
  user authorized its complete envelope on `2026-10-01` and dispatch to the
  existing `v0.3.coder.deep` succeeded.
- Until implementation and its evidence are accepted, keep the current
  `Outcome unconfirmed` behavior and original action evidence unchanged.
  Do not use S27's old Remove-only command against this Install or request a
  new Install click.
- Next notification: UnityCodeDB v0.3 Planner/User after S28 returns its stable
  source snapshot and consolidated result. Verifier has not been notified.

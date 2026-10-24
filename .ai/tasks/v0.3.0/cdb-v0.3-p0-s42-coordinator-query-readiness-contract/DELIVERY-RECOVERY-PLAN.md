# S42 delivery and bounded recovery plan

Status: EXACT_COMMIT_EXPORT_COMPLETE / NO_CONSUMER_DELIVERY_OR_LIVE_ACTION_AUTHORIZED.
Date: 2026-10-22. Current user agreement covers this alignment/preparation.
Progress update: single ownership preflight is complete (see its RESULT);
exact candidate projection and offline retirement client are prepared (see
PREPARATION-RESULT.md). No formal commit/export or live retirement occurred.
Source contract PASS is recorded in RESULT.md. Do not treat source completion
or this plan as real-project recovery. This is an additive handoff envelope;
the completed implementation TASK is not reopened or broadened.

## Fixed candidate and protected state

- Source base: `186aacf0371ba64e47114306170b449dbca261c9`.
- Branch: `codex/coordinator-query-readiness`; checkout:
  `<repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract`.
- Commit scope: only Supervisor and its test harness from RESULT.md, with hashes
  `ac341b039f0840735801dc991e42a9ba7e313df0c82cca895d00dfc08a104fba` and
  `7bf20ca426419905b34bb3297af2f164be2946d50a3e95a9850de09fb77f468e` respectively.
- Identity remains Package `0.3.0-preview.5`, generation `poc.44`; no immutable
  payload change. Source commit and artifact SHA distinguish this host repair.
- Consumer remains `<test-projects>/CodedbTest_2`. Old Package reference is the
  historical baseline `file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb`;
  it must be read and revalidated later, not assumed current.
- Preserve primary dirty checkout/index, immutable generations, all existing
  Packages/runtime, S40/S41 and snapshot evidence, both probe files and .meta.
  No cleanup, reinstall, pointer edits, registration changes, timer changes or
  new Unity project. Durable plans use symbolic paths; runtime paths are derived.

## Consumer closure

| Boundary | Authority and current evidence | Delivery check |
| --- | --- | --- |
| Automatic start argv -> selected coordinator | Existing watch-manager parameter semantics; actual Supervisor launch captured by S42 | Repeat S42 from exact extracted candidate; check exported source hashes |
| Existing authenticated status -> attach/Ready | Existing schema-2 status and path/adapter semantics; actual immutable worker predicate exercised | Repeat bounded S42/S32 producer checks from exact candidate |
| Operational observation -> Bridge/Manager | Same schema/fields/reasons; context passed only inside producer. Bridge parser accepts existing core_ready/starting/degraded reasons and binds identity/revision/time; generic legacy predicate is unchanged | Preserve exact decoder bytes and document static binding; real C# compile/Manager remains human Unity gate, no claim of isolated C# execution |
| Operational observation -> materializer | Existing operational marker whitelist and ordinary provider-config launcher assertion remain unchanged | Production payload admission and Package byte closure; record separately from semantic source checks |

Pending/building with a ready worker is an existing query-operational state;
the generic Bridge can still display preparation/maintenance under its legacy
route. Do not require different samples to show identical UI labels or weaken
wrapper admission for this test. Source comparison establishes no new wire field,
schema or immutable generation. No independent full audit is proposed.

## Sequence and grants

1. **Next proposed gate: one read-only ownership preflight.** First ask the human
   for current Unity open/closed and Manager state; preserve that starting state.
   A fresh narrow task will name exact selected pointer/instance/Supervisor and
   coordinator records, process-identity probes and authenticated status requests.
   Read tokens only in memory; emit safe projections, no raw state/pipe/argv dumps.
   Establish current project/instance/activation/generation, old Package bytes,
   Supervisor owner identity, coordinator lifecycle and current operation disposition.
   No ensure/start, lease writes, query, retry, waiting loop or process control.
   This is a new live observation grant; the prior single-snapshot grant is spent.

2. **Commit/export gate, separately explicit.** Recheck isolated source hashes,
   base/branch and empty index. Commit only the two source paths on the isolated
   branch; no primary merge/sync/push. Export exact new commit using existing
   `Tests~/export-codedb-package.ps1` to fresh
   `<repository-root>/.artifacts/exports/s42-query-readiness-<sha7>/`.
   Require commit-stage and exact-ZIP byte closure plus production materializer
   read-only admission. Run only S42 query-readiness and S32 disposition checks
   from the exact extracted Package, using repository-owned fresh fixture roots.
   Record exported source hashes, ZIP hash and semantic results; no broad harness,
   Provider, Unity or MCP. Failed closure prevents copying/reference switching.

3. **Old service retirement gate, exact mutation grant.** Do not send an unbound
   Restart. A reviewed operation must target the live authenticated Supervisor
   and send `command=watcher`, `action=Stop`, with the authenticated coordinator's
   `expected_lifecycle_id`. Existing Supervisor forwards `-ExpectedLifecycleId`
   to the selected immutable watch manager; its coordinator CLI authenticates and
   serializes the expected identity; daemon rejects mismatch. That script also
   records manual-stopped state, so later restoration must account for it.
   The Supervisor protocol supports this request, but the normal Manager button
   does not expose this argument and the Supervisor CLI has no generic watcher
   command. Before the grant is executable, prepare/review a task-owned bounded
   client or an existing callable Bridge binding, with original owner validation,
   one request and safe terminal polling. Do not add production UI or bypass
   child admission to make recovery work. The preflight determines whether that
   route is viable. A task-owned client is now prepared and tested offline;
   its exact binding/limits are in PREPARATION-RESULT.md. It remains unexecuted
   live and requires a new explicit runtime grant.

4. **Closed-Unity Package switch gate.** After successful owned retirement, human
   closes Unity. Verify target process absence and no UnityLockfile before copying
   or reference mutation; don't close Unity automatically. Confirm normal old
   Supervisor retirement rather than assuming an acknowledgement proves exit.
   Copy exact ZIP extraction to fresh
   `<external-packages>/<sha7>-s42-codedbtest2/com.rice.ai-codedb/`; verify full
   inventory. Back up exact manifest/lock bytes. Change only their CodeDB local
   reference to `file:../../Packages/<sha7>-s42-codedbtest2/com.rice.ai-codedb`.
   Preserve other bytes and snapshot protected config/pointer/probe hashes.
   No automatic Install/Uninstall, runtime JSON patch or global Codex operation.

5. **Human reopen and bounded restoration.** Human opens Unity and reports compile
   errors and Manager state. Account explicitly for manual-stopped state from
   gate 3: use one authorized existing Start route with active Editor lease, or
   normal automatic demand only if no manual stop applies. No retry on failure.
   Verify full service shape once before the real-client gate; no blanket claim
   that the source fix proves all Unconfirmed/Needs attention feedback resolved.

6. **Real target-client gate.** Only the target CodedbTest_2 chat uses its exact
   namespace. Freeze one status and, after compatible success, one fixed original
   marker query; stop on first anomaly, retain original responses. Keep missing
   formal response identity fields separate from functional hit evidence.
   Do not write B or replay the S41 absent-file task. A-to-B freshness is a later
   distinct gate after service readiness and query availability are established.

These gates may be bundled in a later explicit grant once concrete preconditions
and the bounded recovery entry are reviewable; repeated approval within an
authorized stage is unnecessary. Current alignment performs none of gates 1-6.

## Stop and escalation

Stop the affected stage once on source/artifact drift, ambiguous ownership,
different project/lifecycle, unresolved live/unknown child, missing authentication,
unavailable owner, partial reference switch, timeout or query failure. Preserve
effects and return a concrete decision; do not auto-retry, fall back to another
CodeDB namespace, delete state or kill PIDs. Historical snapshot identities cannot
authorize current process control. If the expected-lifecycle route is unavailable,
return the missing prerequisite rather than defaulting to reinstall or resets.

## Preparation completed now

- Source/base/changed-path candidate read; no source modifications or commit.
- Existing command forwarding, coordinator expected-lifecycle rejection, Bridge
  request field, retirement and Manager routing statically traced.
- Required `-PathProvenanceOnly` PASS added to RESULT; no product changes needed.
- No consumer reads, process probes, status RPC, CodeDB calls, exports or mutations.

Current status: OWNED_RETIREMENT_NOT_ESTABLISHED / PACKAGE_NOT_DELIVERED.
The approved single Stop was executed once; later operation observation returned
`SUPERVISOR_COMMAND_FAILED`. The grant is consumed, with no replay. See
RETIREMENT-RESULT.md for the safe receipt, counts and evidence limits.
The subsequent read-only diagnosis and offline reproduction established a child
instance-context propagation defect. Its separately approved minimal source
repair passes focused offline verification; see INSTANCE-CONTEXT-REPAIR-RESULT.md.
Its separately approved exact commit/export is now complete at commit 4589249,
with all three artifact fixtures and closure PASS; see
INSTANCE-CONTEXT-DELIVERY-RESULT.md. Consumer delivery remains unperformed.
Human normal-close and its separately approved one-shot observation completed:
OBSERVED_RETIRED at 2026-10-22T06:14:36.844Z; see
NORMAL-CLOSE-OBSERVATION-RESULT.md. This does not change the failed manual Stop.
Consumer copy/reference-switch gate subsequently approved and completed once:
CONSUMER_REFERENCE_SWITCH_PASS_NOT_REOPENED. Both fresh retirement snapshots,
666-file exact inventory and reference-only byte verification passed; protected
inputs unchanged. See CONSUMER-SWITCH-RESULT.md. Next gate is human reopening
and compilation/Manager observation; Unity remains human-controlled.

Human reopening observation subsequently received: no errors reported, Manager
Needs attention -> Ready. Initial diagnostic SUPERVISOR_IPC_TIMEOUT retained;
later Ready explicitly cached. See HUMAN-REOPEN-RESULT.md. Next planned gate is
bounded read-only actual service-shape verification, then real target client;
neither has been executed from this human observation alone.

Subsequent authorized single service-shape capture completed: authenticated owners
and full query shape ready, matching deployed 4589249; pointer stable. See
REOPEN-SERVICE-SHAPE-RESULT.md. No real CodeDB call occurred. Next handoff prepared
in TARGET-CLIENT-REVALIDATION-TASK.md for human forwarding to the target chat.

Target chat result subsequently forwarded by human: exactly one successful
status and one successful original fixed query, no retries, pointer stable.
FUNCTIONAL_PASS_REPORTED; formal response identity fields not provided. See
TARGET-CLIENT-REVALIDATION-RESULT.md for provenance / raw-response limits.
Current delivery plus reopened service-shape and real-client functional gates
are complete at this evidence level. Timeout / heartbeat, manual Stop coverage,
formal response identity and S41 freshness remain separate open items.

Human subsequently agreed to the bounded retained-A-to-B flow. Fresh task:
../cdb-v0.3-p0-s41-code-change-query-freshness/RETAINED-A-TO-B-TASK.md.
Authorized for human transfer to the existing target chat; not executed here.
Maximum three conditional searches, one A-to-B save, one 15-second post-save
wait; first anomaly stops. Original failed S41 attempt remains unchanged.

Fresh retained-A attempt subsequently reported: A baseline PASS, then PowerShell
parser error before write. Writes/waits/B queries 0; stopped without retry.
See ../cdb-v0.3-p0-s41-code-change-query-freshness/RETAINED-A-TO-B-RESULT.md.
A-to-B freshness not tested. Forwarded protected-probe hash has 63 hex digits;
exact stability evidence needs later verification, not an inferred file mutation.
Prepare syntax-checked edit helper before aligning any fresh operational attempt.

Subsequent helper checks verified exact A/B byte behavior and the complete actual
protected-probe hash. Separately authorized retained-A attempt 02 completed PASS:
A hit -> one B save -> one wait -> B hit -> old A absent, three searches, no retry.
Save-to-B-call 33.434 seconds; this does not establish a 15-second SLA. Final
sample retained as B; pointer/protected sample stable. Development-session static
receipt reconciliation also PASS. See
../cdb-v0.3-p0-s41-code-change-query-freshness/RETAINED-A-TO-B-ATTEMPT-02-RESULT.md.
The scoped S41 edit observation is now complete; earlier failures remain historical
evidence. Timeout/heartbeat, response identity and manual Stop coverage remain
open; this stage does not authorize further live runs or cleanup.

Subsequent approved static startup analysis complete; see
STARTUP-IPC-STATIC-ANALYSIS.md. Seven delivered source files match frozen 4589249.
Observed exact timeout message narrows to a command-path post-connect message
exchange; initial acceptance vs operation lookup and write vs read remain unknown.
Generic timed-out-result projection explains Needs attention; later reconciliation
can publish Ready. No heartbeat failure or common cause is established. Next
proposed work is bounded existing historical log/operation extraction before
deciding on minimal phase diagnostics. No product or consumer change performed.

Authorized historical extraction subsequently complete in one capture; see
HISTORICAL-STARTUP-EXTRACTION-RESULT.md. Startup events retain completed Probe /
Upgrade work, but operation history lacks the selected window and Editor warnings
have no UTC/request-stage correlation. Editor lifecycle entries show repeated
Ready/NeedsAttention/Ready samples with the same reported PID pair, not sufficient
to attribute cause. No further log capture is active. Minimal client-only failure
phase proposal prepared in IPC-FAILURE-DIAGNOSTICS-PROPOSAL.md; not implemented.

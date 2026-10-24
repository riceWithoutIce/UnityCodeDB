# Task: cdb-v0.3-p0-s31-project-uninstall-workflow

## Metadata

- Product/version: UnityCodeDB v0.3 / 0.3.0-preview.5.
- Workflow: codedb-workflow-v2 revision 2.6.
- Status: PARTIAL / INCOMPLETE / NOT_ACCEPTED; A2 frozen, awaiting User disposition.
- Planner: current parent. Coder: existing historical_handoff_coder. Independent read-only Verifier: existing historical_handoff_verifier after stable Coder completion.
- Review mode: GUARDED. Execution mode: DURABLE_SESSION required by cross-layer process authority; user approved the task-local existing task-scoped Coder -> Verifier reuse exception. No new durable session or child creation.
- Execution profiles: coder.deep (DEEP_60M), verifier.deep (30M); retain existing role model/settings if reuse is granted. No model/session creation or rebinding is authorized by this card.
- Delegation authorization: TASK_SPECIFIC; user `批准` after the concrete S31 source/isolated-evidence and existing Coder -> read-only Verifier proposal.
- Session policy: REUSE_ONLY, existing roles retain their current settings.
- Requirement source: user decisions on always-accessible uninstall, internal classification, authenticated owned-process force stop, and repeated-click suppression; current roadmap S31 pointer.
- Predecessor: S30 normal-menu repair accepted at ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6; S30 reopen is blocked and its real uninstall/reinstall remain unrun.

## Objective

One coherent project-uninstall workflow: a permanent callable entry accepts a
confirmed request independently of runtime readiness, owns one durable execution
per project, quiesces attributable project execution, deactivates the owned
integration and reports the actual result. S30 later validates this behavior;
this source task does not operate S30.

## Frozen behavior

1. Keep `Uninstall CodeDB from Project` visible and clickable in every Manager
   state, including missing prerequisites, Not evaluated, NeedsAttention and
   Uninstalled. Opening/repainting/reloading is observation, never confirmation
   or execution. Remove the cached runtime/preflight gating from the request
   path as well as presentation; retain confirmation and backend effect checks.
   Existing recovery context may feed the same removal authority, never a second
   weaker engine. Explain the owned scope and conditional force stop to the user.
2. Backend classifies the request. Proved absence of integration AND absence of
   attributed pending installation effects returns a visible no-op. Already uninstalled
   returns its current disposition without initiating cleanup again. Missing
   status or selection alone does not prove absence; malformed/unknown authority
   returns a concrete blocked/unknown result with no unsafe effect.
3. Reuse existing project operation locks, action records, removal intents and
   transaction writers. Publish one attributable uninstall request/ownership
   before effects. Scope exclusion to the project, not the imported Package path
   or Manager window. Repeated clicks/windows attach to its progress/result;
   they do not allocate parallel uninstall writers, repeat confirmation for an
   already accepted request, or repeat process stops/deactivation/cleanup.
   Resolve competing confirmation callbacks atomically at backend admission.
4. Domain Reload, Manager reopening and caller interruption must not release
   execution ownership while effects may remain active. Do not automatically
   replay a failed or unknown operation. Observe and classify the original
   operation before a separately user-confirmed retry. Genuine process exit
   does not by itself prove uninstall completion.
5. Once accepted, prevent automatic startup/reconnect, new Install and maintenance
   from republishing runtime authority. Retain the fence across reload until a
   known disposition; a separately confirmed later Install may clear the
   appropriate terminal fence. Do not disable ordinary first Install forever.
   If a writer is active, use bounded safe completion/cancellation and existing
   serialization; never kill a configuration transaction mid-write, steal a
   live lock, or deadlock while waiting for an operation holding a needed lock.
6. Authenticate the exact project's runtime owner and its separately attributable
   owned children. A process from a prior Package directory is not rejected
   solely because its script path differs from the imported Package: classify
   its own captured invocation/project/runtime/contract and reviewed executable
   closure. Cover S30's same-byte Supervisor/different-Package-directory case.
   Do not infer ownership from a name, PID, directory, parent PID or equal script
   hash alone. Do not scan arbitrary old Packages or add generic legacy recovery.
7. For positively owned processes, request graceful shutdown with a bounded
   deadline. If still running, revalidate identity at the termination boundary
   and force-stop only the same authenticated execution. Avoid bare PID or
   blind process-tree termination; independently establish each child target.
   Absent/exited, original-live, PID-reused and identity-unknown are distinct.
   Never terminate a replacement process or unknown/external holder. Verify
   actual exit and inactive authority; shutdown acknowledgement is insufficient.
   Graceful/force deadlines are fixed, bounded and recorded in RESULT.
8. Reuse the removal transaction to revoke current selection, project runtime
   authority and owned project MCP registration, with fresh checks at effects.
   Publish Uninstalled only when those postconditions hold. Report stopped/
   partial/unknown effects honestly on failure. No synthetic successful terminal.
9. Separate logical uninstall from retained-data cleanup. Preserve user files,
   indexes/custom configuration and external-holder execution closures under
   existing retention rules. Do not retrigger physical cleanup on every click.
   Return visible No action needed, Uninstalled, Uninstalled with retained
   content, In progress, or Blocked/Unknown with a bounded cause; do not hide
   the entry after any result. Reinstall is a separate confirmed operation.

## Scope and ownership

Source/test change allowlist (relative to com.rice.ai-codedb; not all need edits):

- Editor/AICodedbManagerWindow.cs
- Editor/AICodedbEditorLifecycle.cs
- Editor/AICodedbActions.cs
- Editor/AICodedbHostPayloadMaterializer.cs
- Editor/AICodedbManagerActionJournal.cs
- Editor/AICodedbSupervisorBridge.cs
- Editor/AICodedbSupervisorLauncher.cs
- Editor/AICodedbSupervisorRequestQueue.cs
- Editor/AICodedbProcessRunner.cs
- Tools~/codedb-project-supervisor.mjs
- Tools~/codedb-instance-engine.ps1
- Tools~/materialize-codedb-host-payload.ps1
- Tools~/invoke-codedb-manager-action.ps1
- Tests/Editor/AICodedbManagerUiTests.cs
- Tests/Editor/AICodedbEditorLifecycleTests.cs
- Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs
- Tests~/test-codedb-project-supervisor.mjs
- Tests~/test-codedb-host-payload-materializer.ps1
- Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md
- Documentation~/v0.3.0-p0-codedb-responsibility-contract.md

Coder owns those implementation/test/contract hunks and S31 RESULT.md; Verifier
owns only S31 VERIFICATION.md. Planner owns TASK.md, S30 route record and roadmap.
Preserve existing dirty document hunks: hash their actual preflight bytes and
make only coupled amendments to the agreed uninstall behavior.

Read-only closure: direct callers/readers of these files, AICodedbPaths and
status/context/strict-JSON types, existing relevant test helpers and compiler
response inputs. No broad audit. Before editing, map request ownership, startup
fencing, process authentication/stop and deactivation to their existing writers;
name the persistent record readers and prove cross-layer consumer closure for
any changed record. Reuse existing mechanisms rather than a parallel platform.

Snapshot: HEAD ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6 and its exact 617-file
Package at .artifacts/s30-current-version-lifecycle-ed97c38/review/com.rice.ai-codedb.
Build isolated overlays from that accepted input, never dirty Payload. Evidence
root: .artifacts/tests/s31-project-uninstall-workflow/. Preserve old evidence.

Protected: all live projects/runtime/receipts, old ZIPs/extractions, unrelated
dirty source/docs, machine dependencies/configuration, Unity/Codex/external MCP
clients and unrelated processes. No live project scan or actual recovery.
Payload generations, identity manifests and metadata are excluded. If a correct
change requires immutable generation/identity changes or another source file,
report the concrete dependency before proceeding beyond this allowlist.

## Execution envelope

- Mode: CONTINUOUS_WITHIN_SCOPE; source/delegation grant recorded below.
- User approved the product direction and repeat-trigger rules in discussion;
  the latest `好的 我们继续` permits task preparation. This card does not turn
  agreement into authority to stop the live S30 owner or mutate its state.
- Approved grant: user `批准` authorizes source implementation, same-cause
  repair, declared isolated evidence, parent stable-snapshot admission and
  independent read-only review using the existing roles. No repeated approval
  between these stages; all real-project/process and delivery exclusions remain.
- Delivery authorization: NONE. No commit/export/reference switch/push/release.
- Side effects: task-owned isolated fixture files only. Synthetic process/IPC
  seams first; any fixture-native process must be created and identity-bound by
  the test, stay under the task closure and leave no external process changes.
  No native process census or termination outside those created fixtures.
- L0: changed script syntax/Node check; scoped diff check; exact-overlay
  Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly; unchanged identity
  metadata verification. No repair of metadata to conceal immutable drift.
- Affected L1: original-byte Editor/affected Editor.Tests compilation and the
  focused entry-to-transaction/owner-stop scenarios below. Extend existing named
  harness filters; do not run whole Supervisor/materializer suites by default.
- Evidence scenarios: all-state callable entry and cancellation; no-integration
  and already-uninstalled idempotent no-op; Not evaluated with installed authority;
  same-byte prior-directory Supervisor stop; graceful success; graceful timeout
  followed by identity-matching forced exit; reused PID and unknown owner refusal;
  duplicate requests across two callers and reload; active writer bounded handling;
  no automatic relaunch/Install until terminal disposition; partial/unknown result
  without replay; logical postconditions and retained external-holder content.
- Join actual original entry/admission/writer code across C#, Node and PowerShell.
  Hand-built success strings, source regexes or local predicate tests alone are
  insufficient. Label synthetic boundaries and unexecuted native GUI honestly.
- Explicitly not run: Unity/MCP/BatchMode/CUA, real Install/Uninstall/stop, S29
  history repair, global process control, physical cleanup or full regression.
- Budgets: Coder DEEP_60M; Verifier 30M; V2_DEFAULT output. Workflow mechanical
  corrections 2 and corrected semantic attempts 2 per evidence scenario apply.
  Stop on broader authority/surface, unsafe ownership, exhausted budget or
  structural escalation. Record actual counters; do not reset S30 history.
- Verification: Coder freezes source hashes and terminal RESULT, then stops.
  Parent checks stable identity before Verifier. Verifier reviews this declared
  change once; returns all findings to User and never instructs Coder to fix.

## Definition of Done and handoff

Source/isolated PASS requires the whole frozen request-to-result behavior and
its direct consumers, original-byte compilation, bounded evidence and protected
state retention. No real lifecycle or release PASS is inferred. After source
acceptance, delivery and human S30 validation retain separate explicit gates.

Current state: Coder returned its unique terminal PARTIAL / INCOMPLETE result
and stopped all writes/checks at the cumulative budget boundary. Parent checked
the final RESULT and all four source hashes against that terminal report; they
match. This WIP is not eligible for source acceptance or delivery. Independent
Verifier was not started because the frozen request-to-result implementation
and semantic evidence are incomplete. Real operational authority remains NONE.

## Approved direct-writer amendment — 2026-10-15

The original allowlist omitted two existing direct dependencies necessary to
meet frozen behavior 5 (no transaction killed during configuration publication):

- `Editor/AICodedbProcessRunner.cs`: dispatches the durable receipt writer and
  bounds its outer lifetime; the outer runner can terminate that writer.
- `Tools~/invoke-codedb-manager-action.ps1`: directly starts the materializer;
  its timeout/output-overflow and finally paths call child.Kill without a
  transaction-safe boundary (lines 334–340 and 359–362 at the base snapshot).

This shared execution/receipt surface was outside the original write grant.
User `ok 同意` approved the limited extension to the uninstall workflow's safe writer
lifetime/cancellation and truthful terminal/unknown ownership handling, including
an already-active writer affected by that workflow. Preserve unrelated command
semantics; no global timeout rewrite or parallel execution platform. Existing
allowed ManagerUiTests and materializer test harness cover the direct regression;
no additional test file, immutable Payload or live operation is proposed. The
approval does not authorize commit, export, reference switching, Unity or live
process control.

Earlier preflight RESULT SHA256 (historical; superseded by final checkpoint):
`9fd8a2d3362173bb6276557a3759dbbca3afc15025f0302d26619f82852020e0`.
Other consumer/identity closure remains unverified, as RESULT records. This
boundary report was not a source PASS. Active budget and cause counters carry
forward on continuation, rather than resetting on re-dispatch. The Coder resumes
with the two added direct dependencies. That continuation has now ended in the
partial checkpoint below; this historical amendment is not a new dispatch grant.

## Final partial checkpoint and continuation boundary — 2026-10-15

Final Coder RESULT SHA256:
`f4e844b42604f1662f6186c5c1492b03d97d2d2d58836a24cba1ecdb1c834628`.
Four source files remain WIP: ManagerWindow, ProcessRunner, the durable action
writer and instance engine. Full paths/hashes and evidence are in RESULT.md.
No test/contract changes or final Supervisor diff are present. Index is empty.
The parent performed bounded identity/result admission only, not independent
semantic review or a test rerun. Earlier over-limit captured output was
truncated; no complete-review claim is inferred from those excerpts.

Completed evidence: original-byte Editor and Editor.Tests compilation, final
PowerShell parse, exact-overlay PathProvenanceOnly and immutable equality.
No semantic/ joined integration test ran; existing cached-gate UI assertions
remain incompatible with the new presentation. No source/isolated PASS applies.

The current WIP removes immediate timeout termination of admitted mutation
writers but does not provide safe-point cancellation. Indefinite waiting,
retained locks and loss of drain/receipt observation remain possible; this is
not a completed writer-safety fix. Persistent startup exclusion, prior-directory
owner authentication and separately authenticated child shutdown remain absent.
The entry change alone therefore does not fix S30's blocked uninstall path.

Recommended next envelope for User decision: a bounded Planner-only read-only
design pass (30 minutes), with no Coder dispatch, source edits or new tests.
Use only the existing allowlist/direct consumers and evidence to freeze:

1. Existing persistent request/fence record, readers, terminal/retry rules and
   project-wide duplicate admission.
2. Writer transaction phases and safe completion/cancellation/observation rules;
   explicitly resolve perpetual lock and caller-loss behavior before code work.
3. Prior-directory owner and each owned child's identity evidence, bounded stop
   sequence and real uninstall postconditions; report any immutable-consumer
   dependency before proposing a scope amendment.
4. One subsequent implementation envelope and focused cross-layer scenarios,
   including Install/Remove/Repair regressions affected by the shared writer.

This proposal preserves the agreed product behavior. It does not authorize
expanding scope, resetting cause counters or silently renewing the exhausted
Coder budget. Any later implementation continuation needs an explicit budget
and concrete stable design packet; do not deliver a subset as the whole task.
Live S30, receipts, accepted Packages and unrelated dirty state remain preserved.

## Authorized read-only design result — 2026-10-15

User `同意` approved the parent-only 30-minute read-only design pass. Static
design is complete in PROTOCOL-DESIGN.md. No agent dispatch/source edit/new
test/live operation occurred. Four WIP hashes still match the Coder terminal.
Requirements remain frozen; the implementation remains partial and unaccepted.

Use the existing durable materializer for every Uninstall; Supervisor provides
authentication/quiescence/stop rather than owning an operation waiting for its
own exit. Reuse project action admission as the fence and the existing lock/
journal for transactions. Cooperatively cancel writers at safe boundaries;
Unknown retains original ownership without unsafe termination or replay.

Concrete scope dependency: accepted poc.43 coordinator uses independent watch
demand/restarts and lacks full per-child spawn identity evidence. The complete
new-runtime promise needs successor-generation coordinator/watch-manager
changes and generated identity closure. Do not edit accepted poc.43. Freeze
exact generation source/tool paths first; Payload exclusions remain in force
pending scope approval. An existing generation-authoring tool was not established
by this bounded pass; no invented command is authorised.

Current task: cdb-v0.3-p0-s31-project-uninstall-workflow
Current status: DESIGN_COMPLETE / SOURCE_PARTIAL / NOT_ACCEPTED
Next notification: WAITING_FOR_USER_DECISION; current parent Planner
Next action: decide runtime-producer scope and renewed budget, then freeze exact
generation source/tool paths before continuing the previously approved roles
Human decision or authorization required: successor-generation/identity scope
and proposed 120M Coder / 30M Verifier ceiling; no delivery or live operations

## Approved runtime-producer continuation — 2026-10-15

User `批准` approved PROTOCOL-DESIGN.md's runtime producer/successor identity
scope and additional Coder 120M / read-only Verifier 30M envelope. Continue the
already-approved existing roles without another stage approval. Prior elapsed
work and correction history remain recorded; this is not a reset of S30/S31.
Parent remains active through terminal results. No source ACCEPT, commit,
export, live state/process operation, Unity or reference switch is authorised.

### Isolated implementation checkout

Work only in managed checkout:
`C:/Users/admin/.codex/worktrees/s31-uninstall-workflow/UnityCodeDB`.
Base HEAD is ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6. Parent copies only the
four frozen WIP sources, current workflow and two pre-existing dirty contracts
as attributable starting inputs. The original G: workspace is protected from
Coder changes except its final S31 RESULT handoff after freeze. Parent owns
TASK/roadmap/route records. Do not restore or otherwise change the original
dirty poc.42/poc.43 tree or its reverted pointers.

The accepted ed97c38 exact617 Package is a read-only byte witness. Base checkout
Payload is the clean committed counterpart, not the dirty G: Payload. Record
initial source/contract hashes before edits. Keep original compiler rsp inputs
read-only; adapt existing compile checkpoint into task-owned evidence instead
of launching Unity. Tests must use isolated task-owned roots.

Parent admission verified all 478 Payload files in the isolated checkout equal
the accepted exact617 Package byte-for-byte. Three generation files appear
modified in git solely due to the existing mixed-line-ending checkout handling;
their actual hashes equal the accepted witness. Preserve them; do not normalise,
reset or include them as S31 implementation edits. Record this baseline in RESULT.

### Exact successor generation and identity route

Target candidate: package 0.3.0-preview.6, generation/payload poc.44, sequence 44,
bootstrap protocol 1. These values are defined once in canonical
`com.rice.ai-codedb/Payload~/payload-manifest.json`; language code derives them.
No poc.44 exists at admission. Protect all accepted predecessor generation bytes,
stable flat wrapper and unrelated flat payload bytes. Do not edit poc.43 in place.

Additional write paths, in this isolated checkout only:

- com.rice.ai-codedb/package.json: version and version-derived documentation URLs.
- com.rice.ai-codedb/Payload~/payload-manifest.json: canonical successor tuple,
  generated file hashes/paths and the single exact accepted poc.43 transition.
- com.rice.ai-codedb/Payload~/host-current.json: derived pointer/hash projection.
- com.rice.ai-codedb/Payload~/Generations/poc.44/generation-manifest.json.
- com.rice.ai-codedb/Payload~/Generations/poc.44/coordinator/codedb-watch-coordinator.mjs.
- com.rice.ai-codedb/Payload~/Generations/poc.44/scripts/manage-codedb-project-watch.ps1.
- com.rice.ai-codedb/Payload~/Generations/poc.44/scripts/codedb-project-common.ps1.
- com.rice.ai-codedb/Payload~/Generations/poc.44/shared/codedb-host-use-gate.mjs.
- com.rice.ai-codedb/Payload~/Generations/poc.44/wrapper/codedb-project-instance-worker.mjs.
- com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1: only successor
  identity/provenance and uninstall direct-consumer checks.

Seed poc.44 by byte-copying exactly the 29 implementation paths listed in the
accepted poc.43 generation-manifest, plus deriving a new generation manifest.
Only the five implementation paths above may change. Other copied paths,
including native binaries/build manifest, must remain byte-identical. No new
runtime/helper source file or native build is presently authorised. If another
producer file is needed, return the concrete dependency before changing it.

Generation-authoring method is a task-owned mechanical projection script:
`.artifacts/tests/s31-project-uninstall-workflow/coder-a2/prepare-successor-generation.ps1`
inside the isolated checkout. Create with apply_patch and preserve/hash it as
reviewable evidence. It is not a new production generation framework or executor.
It reads the one canonical payload tuple, copies the fixed predecessor closure
only into an absent successor directory, regenerates successor file hashes and
manifest from actual bytes, then derives pointer/payload inventory/package
metadata. After source edits it may refresh those derived successor projections
without recopying source or touching predecessor files. No arbitrary old-folder
scan, independent candidate constants, manual hash substitutions or packaging.
Copying generated files/projections is mechanical generation, not permission to
overwrite user changes. Abort if expected initial identities/paths differ.

Existing loaders remain the identity route: C# PackageRuntimeContractStore and
HostGenerationStore; PS materializer manifest loader and successor common.ps1;
Node Supervisor package contract loader and successor host-use-gate contract.
New instance identities are emitted by the actual materializer from that tuple.
The exact43 transition is compatibility classification/stop evidence only, not
automatic migration or readiness authority. No generic historical repair.

### Record consumer closure and implementation admission

Before source edits, Coder returns a compact concrete record map to parent:
field names/types/schema; existing production writer; actual C#/Node/PS decode
entry points; Package/generation owner; focused original-writer-to-reader case.
Parent freezes that encoding here as routine design admission without another
user approval, provided it implements PROTOCOL-DESIGN within this scope.

Required logical records and consumer groups:

| Record | Required shape/meaning | Writers and real readers |
| --- | --- | --- |
| Project action request/fence | One project/request/confirmation identity, compatible protocol, original owner, pending/active/known-terminal or Unknown phase; no mutable rewrite of an immutable original receipt. | Manager action journal; lifecycle/launcher/actions; Supervisor admission; PS writer/materializer; successor coordinator/watch demand/restart. |
| Cooperative cancellation/checkpoint | Action/stage/command/project binding, monotonic request/deadline, no-more-mutations and settled commit/rollback acknowledgement, actual exit evidence. | Existing durable writer and materializer; ProcessRunner, Supervisor mutation dispatcher and original-action observation. |
| Owned child execution evidence | Original PID + OS start + executable + invocation + project/instance/generation/owner epoch, explicit unknown/absent distinction. | Successor runtime spawn owners; original coordinator status/stop plus Package-side bounded identity/stop; retained/partial postconditions. |
| Identity projections | Canonical tuple + generated hashes, unchanged predecessor closure; new identity only from canonical contract. | Task mechanical generator and materializer; C#/Node/PS loaders; focused boundary and successor materialization evidence. |

Preserve no-op vs Unknown, safe transaction boundaries, same-project duplicate
attachment and the new runtime's no-restart fence. Use one direct admitted
Uninstall materializer route. No Supervisor self-wait, unbounded lock waits or
bare PID/tree kill. Separate Ready/IPC health from independently sufficient
owner evidence. Process handle/start identity must remain bound at force stop.
Old runtime without the new cooperation cannot be silently upgraded/enrolled;
bounded authenticated graceful stop or explicit Blocked/Unknown is acceptable,
not fabricated Uninstalled or another compatibility loop.

The proposed 30s writer safe-completion observation, 120s runtime graceful
phase, 10s forced-exit phase and 5s identity-query cap from PROTOCOL-DESIGN are
frozen maxima (cap by remaining monotonic deadline). Use synthetic time for
long-deadline scenarios; a genuinely stuck transaction remains Unknown, never
unsafe kill. Preserve unrelated command deadlines.

### Focused validation and stop rules

Reuse the original TASK evidence scenarios plus the new successor identity and
producer-to-consumer bindings. Extend existing named test harnesses/filters;
no whole-suite default. Allowed focused filters may be added to the existing
PS/materializer, Node/Supervisor and package-boundary files, and must be named
in RESULT before execution. Original-byte Editor/affected Editor.Tests compile
is required. Execute semantic assertions; compilation alone is not PASS.
Use original production writers/readers for integration, label native-process
and synthetic seams accurately. Only task-created fixture processes may be
started/stopped, with exact owned identities; never census or control live S30.

If the whole implementation cannot converge by the renewed 120M ceiling, stop
new experiments and consolidate PARTIAL with exact remaining gaps. Do not
silently renew budgets or promote a four-file/individual-slice subset. Coder
freezes one complete attributable snapshot and stops before parent admission
and already-authorised read-only Verifier. Verifier returns consolidated
findings to User, never directly requests Coder fixes. No auto-repair after
findings without a matching user disposition.

Current task: cdb-v0.3-p0-s31-project-uninstall-workflow
Current status: DOING / APPROVED_CONTINUATION / PREFLIGHT_RECORD_MAP
Next notification: existing Coder -> current parent Planner
Next action: freeze concrete record encoding, implement and validate boundedly,
then return one stable terminal snapshot for independent review
Human decision or authorization required: none inside this amended envelope;
new concrete scope/risk boundary or terminal source disposition still requires User

## Concrete record encoding admission — Coder A2

Parent admits the Coder's pre-edit map with the constraints below. This is
routine implementation design inside the approved scope, not independent
verification or new authority. Coder owns the exact source bindings/evidence.

| Record and version | Frozen fields/meaning | Production bindings |
| --- | --- | --- |
| Existing project index schema1, cooperative_protocol integer1, uninstall_request schema1 | project_key/root strings; request_action_id/confirmation_id hex32; request_package_root string; owner_action_id hex32; phase REQUESTED/EXECUTING/TERMINAL/UNKNOWN; outcome/reason nullable strings; host monotonic fields described below. Original manifest/claim/receipt remain immutable. | Journal create/attach/promote under index.lock; its ReadUninstallRequest projection to Manager/Actions/Lifecycle/Launcher; strict Node Supervisor and PS writer/materializer/engine reads; successor common/watch-manager and host-use-gate/coordinator/worker consumers. |
| Existing stage admission cooperative_protocol1 and writer claim extension; sibling cancel/checkpoint schema1 | Bind action/stage/command/project keys and writer PID/start. Cancel reason TIMEOUT/OUTPUT_OVERFLOW/OWNER_LOST/UNINSTALL. Checkpoint phases PREPARING/TRANSACTION/SETTLED_COMMIT/SETTLED_ROLLBACK/CANCELLED_SAFE/UNKNOWN; no_more_mutations boolean; journal_operation_id nullable string; child PID/start and bounded host deadline. | Existing durable wrapper emits cancel; materializer safe boundaries emit checkpoint; ProcessRunner recovery and Supervisor durable dispatch read original terminal plus checkpoint. Writer loss can be self-observed by child without forging a dead writer's cancellation request. |
| Successor coordinator state schema3, uninstall protocol1; execution_evidence object | owner_epoch hex32. coordinator/provider/adapter_worker/adapter_builder each carry schema1, classification NOT_STARTED/STARTING/OWNED/EXITED/UNKNOWN, PID/start/executable/normalized argv/argv hash/command-line hash, project identity/root/instance/generation/owner epoch. Null evidence in non-OWNED states must be explicit and cannot grant stop authority. | Original successor spawn owners capture/persist; coordinator status/stop and Package Node stop strictly decode; C#/PS actual coordinator-status consumers must be enumerated and closed before emitting schema3. Old schema2 remains old graceful/Unknown only. |

Monotonic representation is decimal-string integer nanoseconds, not JSON
floating point: accepted_monotonic_ns, deadline_monotonic_ns and an explicit
clock_kind WINDOWS_QPC_NS. PS converts Stopwatch timestamp/frequency using
integer arithmetic; C# uses the native Windows QPC source as clarified below.
Node uses hrtime.bigint only after a focused production
cross-language fixture proves the shared host origin/scale on this Windows
runtime (allow documented resolution tolerance). Do not assume origin equality.
Bind timing to the authenticated original owner PID/start/epoch; now before
accepted, incompatible clocks, absent/replaced owner or reboot uncertainty means
Unknown, never extended authority. If common origin cannot be proved, report
that concrete evidence boundary; do not improvise clock conversion. Request
fences do not expire merely because a deadline elapsed. Deadline expiration
never clears a fence, releases a lock or replays/promotes an unknown operation.

All parsing remains strict/bounded and validates original serialized hashes
before in-memory path comparison. Version bump does not excuse omitting an old
decoder on a normal path. Record exact real decoder entry points in the Coder
consumer map before altering that producer; stop on an out-of-scope consumer.
Source table grouping here does not claim those bindings are already verified.
Cancellation acknowledgements cannot be interpreted as permission to kill a
writer that can resume mutations; actual safe producer exit is still required.

Coder supplement admitted: the mutable request phase also allows SUPERSEDED,
only after a separately confirmed Install has classified the original terminal
and become the appropriate successor owner. Release/promotion preserves the
request fence atomically; a resolved marker may capture it on first publication,
but an already-published immutable resolved marker/receipt is never rewritten.
Keep any later SUPERSEDED disposition in the mutable admission/successor record.
Lock-free consumers must not see a permissive fence gap during promotion; an
intermediate ambiguous view stays fenced/Unknown. This is one existing journal
route, not a separate persistent request queue.

### Direct decoder routing admission

Coder identified the actual schema3 consumers before changing the producer:
C# Bridge ParseSnapshot (outer status remains schema2) and Lifecycle
ReadCoordinatorState; PS materializer authenticated-status validation and
Get-ValidatedGenerationWatcherCoordinatorState, instance-engine
Get-InstanceCoordinatorState; successor worker getReadyWatchCoordinatorState;
and Supervisor publicStatus projection. Their exact source bindings and
executed evidence remain Coder RESULT responsibilities.

The existing out-of-allowlist stop-codedb-legacy-watcher.mjs also sits on the
old materializer stop path. Keep that file unchanged and handling schema1/2.
For schema3, the direct materializer calls the already-allowed Supervisor's
owned-runtime stop implementation. Coder confirmed this reuses the stop work
required by this task without copying the legacy helper or adding another
execution engine. Supervisor provides identity/quiescence/stop only; Uninstall
does not become Supervisor maintenance and cannot wait for itself to exit.
This routing decision grants no additional file, live-process or delivery scope.

### Mono clock-source implementation clarification

The original production C# clock fixture on the task's Unity Mono runner
exposed a process-relative Stopwatch origin, unlike the host QPC origin used
by Windows PowerShell and Node. A simple Node >= C# ordering check did not
prove a shared origin and cannot count as clock-protocol PASS.

Within the existing Journal.cs allowlist, use Kernel32 QueryPerformanceCounter
and QueryPerformanceFrequency through P/Invoke, with integer conversion, to
produce the already-frozen WINDOWS_QPC_NS representation. Retain the failure
classification and require an actual original-production cross-language
bracketing fixture with documented tolerance. No relative-origin offset,
fallback to incompatible Stopwatch, new file or native build is authorized.
This is an implementation-source correction to the approved host clock;
phase budgets, identity bindings, scope and operational authority are unchanged.

## A2 terminal admission — 2026-10-15

The existing Coder returned its unique terminal PARTIAL / INCOMPLETE /
NOT_ACCEPTED and stopped. Source freeze: 15:53:44 UTC, about 71m38s after
14:42:06 UTC admission, before the 120-minute ceiling. The complete original
installed-uninstall transaction fixture exhausted two mechanical corrections
and remained invalid; this is not proved production transaction failure.
With implementation/consumer gaps still present, parent directed consolidation
instead of another equivalent experiment. No budget or cause counter resets.

Parent read the full current A2 result and verified 50 frozen input/source
hashes, all five fixture-script hashes and 476 protected predecessor/flat
Payload bytes against the accepted Package. All matched. This is identity/
handoff checking, not independent semantic verification. An oversized initial
status listing was truncated; no semantic conclusion relies on that listing.
One parent-only hash-command syntax error was corrected before execution;
it did not modify files or consume a product-test attempt.

Frozen RESULT SHA256:
89942d478973016fdc41484b7eaae2f5a1eb2046b5862d1d53dc101dec72b69f.
Frozen source manifest SHA256:
ed75b9542451747ce8e75860419122e6d4800a380dde8be2e9d925f1209e3224.
Its TASK input remains frozen in the isolated checkout at
d92c99d2b5184656bb333766cb405a6a6223a33389ba2d8ee8899b9a0953f0d2;
this parent terminal amendment is intentionally not copied over that witness.
The exact final RESULT was copied back to the main task only after checking
both its frozen hash and the unchanged historical main RESULT hash.

Core remaining implementation: reload/pending promotion and confirmed retry;
terminal UI/session observation; explicit UNINSTALL cancellation record;
strict cross-language/role-evidence consumer parity; missing-roster Unknown
classification. Core missing evidence: complete installed-uninstall transaction,
same-byte prior-directory native stop, full successor lifecycle, final receipt/
UI consumption and affected Install/Remove/Repair regressions. Earlier semantic
PASS cases are not all on final source bytes; RESULT labels their limits.

No Verifier was admitted because the complete stable implementation/evidence
prerequisite failed. Source remains in the isolated worktree, unaccepted and
uncommitted; main dirty source/Payload and S30 remain protected. No package,
reference switch, Unity, real Install/Uninstall or live process operation ran.

Current task: cdb-v0.3-p0-s31-project-uninstall-workflow
Current status: PARTIAL / INCOMPLETE / NOT_ACCEPTED
Next owner: User / current parent Planner
Next action: align a bounded completion/evidence plan and explicit correction
disposition before another implementation attempt; no subset ACCEPT or delivery
Human decision required: continuation/correction boundary; no current Unity action

## User-approved follow-up split — 2026-10-16

User accepted the bounded split proposed after the A2 terminal. S31 A2 remains
`PARTIAL / INCOMPLETE / NOT_ACCEPTED`; its isolated WIP and evidence are retained
for attribution and are not promoted to a deliverable. No source, package,
reference switch, Unity operation or live process authority is granted by this
split record.

### S31-A — durable request and terminal UI closure

Scope only the existing C# request/journal, reload/reopen/session readers,
startup fence, duplicate attachment, confirmed retry classification and visible
terminal result. Required evidence is the original C# producer/reader path,
Domain Reload/reopen semantic coverage, and the nearest Install/Remove/Repair
regressions. It does not add runtime force-stop authority or a new generation.

### S31-B — owned runtime stop and complete uninstall transaction

Scope only the authenticated prior-directory/native runtime roster, successor
spawn/stop lifecycle, safe writer settlement, deactivation transaction,
postconditions and retained-content behavior. Required evidence is the original
PowerShell/Node/C# production chain with task-owned processes and a valid
installed transaction fixture. It does not reopen UI presentation or historical
S29/S30 recovery.

Each follow-up requires its own frozen allowlist, evidence budget and terminal
disposition before implementation. They may reuse the A2 protocol and source
snapshot as read-only inputs, but neither may silently inherit A2's incomplete
evidence or correction counters as a source PASS. Delivery and Unity acceptance
remain separate later gates.

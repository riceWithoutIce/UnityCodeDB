# Task: cdb-v0.3-p0-s31b-owned-runtime-stop-uninstall-transaction

## Metadata

- Product/version: UnityCodeDB v0.3.
- Workflow: codedb-workflow-v2, revision 2.6.
- Status: PARTIAL / NOT_ACCEPTED; R3 complete, original F1 closed with limits.
- Planner: current parent; one Coder followed by one read-only Verifier.
- Review mode: GUARDED when a stable implementation snapshot is available.
- Execution mode: FAST_SUBAGENT, task-specific route approved with the proposed
  Coder -> Verifier grant; no durable session is created or rebound.
- Execution profiles: v0.3.coder.deep (60M), v0.3.verifier.deep (30M).
  Model settings are inherited as explicitly proposed, rather than historical
  catalog model bindings. Session policy: SPAWN_BOUNDED; depth one.
- Delegation authorization: TASK_SPECIFIC. User `好的 同意` on 2026-10-16
  accepts the concrete pending S31-B implementation/evidence/delegation grant.
  Earlier task-local grants are not used as authority.
- Requirement source: user-approved S31 A/B split; subsequent agreement to
  prepare S31-B's task card and read-only design boundary; S31-A freeze
  decision committed as `279b442c657676d1adbda7d15151a3770682a674`.
- Predecessors: S31 A2 and S31-A remain partial and not accepted. Historical
  reconnect is a deferred, non-blocking FOLLOW-UP.

## Objective

One independently assessable outcome: a confirmed, project-bound uninstall
settles protected writers, stops only authenticated owned runtime executions,
commits the existing deactivation transaction, and exposes its truthful result
through the existing production result reader.

This outcome is source/isolated-evidence work. It does not by itself accept the
whole S31 lifecycle or resume real S30 uninstall/reinstall.

## Scope

- In scope: owned runtime roster and termination identity;
  successor spawn/restart fencing; cooperative writer settlement; existing
  deactivation transaction and postconditions; retained-content/no-op behavior;
  original PowerShell/Node/C# producer-to-consumer evidence.
- Out of scope: Manager presentation/reload redesign, historical reconnect,
  historical S29/S30 recovery, arbitrary old Package discovery, physical
  cleanup campaigns, new executor/queue platforms and release promotion.
- Write allowlist: the exact implementation/test list below, only in the new
  repository-local checkout; task-owned evidence and Coder `RESULT.md`.
  Planner owns this TASK; Verifier owns only `VERIFICATION.md`.
- Read-only dependency closure: S31 `TASK.md`, `RESULT.md` and
  `PROTOCOL-DESIGN.md`; S31-A freeze/rebaseline records and hash lists; current
  development workflow and test-workspace contract; direct writers/readers
  identified below during implementation-scope preparation.
- Protected state: main dirty source/Payload, S31/S31-A snapshots, accepted
  Packages and immutable predecessor generations, existing evidence and failed
  fixtures, real validation projects, receipts and external processes.

### Input and identity binding required before implementation

Do not choose a baseline from a checkout name or the newest timestamp. Bind
the accepted commit/Package witness and any necessary unaccepted S31 WIP bytes
separately by provenance and hashes. S31-A's repo-local rebaseline is a frozen
partial input, not accepted source or proof of the complete runtime closure.
Do not restore, copy back, rebind or modify historical worktrees during planning.

All future durable outputs must use symbolic repository-local roots:
`<repository-root>/.worktrees/<task-id>/`,
`<repository-root>/.artifacts/tests/<task-id>/` and this task directory.
Unity-test temporary roots, if later authorized, follow the actual test
project's `Library/cdt/<run-id>/` contract. No system-temp fallback or
machine-specific paths in durable task records.

Identity authority remains `Payload~/payload-manifest.json` and its existing
C#/Node/PowerShell loaders. The A2 successor tuple is unaccepted WIP: inspect
and bind it before choosing a candidate. Do not invent another generation,
edit accepted predecessor bytes or substitute hashes manually. Any successor
source and mechanically generated metadata writes require an exact frozen
allowlist and generator/validator binding before implementation.

## Read-only design boundary

1. Ownership is independent of Ready or IPC health. Authenticate original PID,
   OS start identity, executable, invocation and project/instance/generation/
   owner epoch. PID reuse identifies a different process; unavailable or
   conflicting evidence means Unknown. Neither permits termination.
2. Preserve the request fence while settling writers and closing runtime
   start/restart admission. Settle an active configuration writer by commit or
   verified rollback at a safe point; timeout/caller loss is not kill authority.
3. Capture the owned roster before losing its parent. Attempt graceful drain,
   observe actual exits, and permit force only after identity revalidation of
   those exact owned executions. Never use a bare PID, name, tree or directory
   as authority. Missing original roster evidence is not proof of absence.
4. After runtime quiescence, acquire/reacquire the existing materializer lock,
   revalidate the request and selection, then perform existing deactivation.
   Do not await writer/runtime shutdown while holding a lock it needs.
5. Uninstalled requires authenticated runtime exit and committed inactive
   authority/selection, disabled project registration and desired state. A
   genuinely absent installation with no pending effects is NoActionNeeded;
   repeated terminal observation must not replay recovery or cleanup. Preserve
   user/shared/external content. Partial or Unknown results remain attributable.
6. Exercise a same-byte/different-Package-directory owner with newly created
   fixtures, not the live S30 owner. Follow only the authenticated captured
   locator and reviewed closure. Do not search historical directories or
   hot-enrol an old runtime. Unprovable old closure may remain Blocked/Unknown.
7. A2's bounds are design inputs: writer settlement 30s, graceful phase 120s,
   force/exit phase 10s, identity query at most 5s capped by phase remaining
   time. Preserve one monotonic deadline per phase and existing unrelated
   command limits. These are not authority to run a process experiment now.

### Read-only input binding — verified 2026-10-16

- Accepted base: `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`.
- Accepted Package witness:
  `.artifacts/s30-current-version-lifecycle-ed97c38/com.rice.ai-codedb.zip`,
  SHA256 `78cc1bea38e9a9ca5f057a916b5ea78c9a4427905d682c242dce52e430cdb08c`.
  Hash rechecked; no export or extraction was performed in this planning pass.
- Historical source locator: the existing S31 A2 implementation checkout,
  here called `<historical-s31-source>`. Its provenance is the A2 result and
  `.artifacts/tests/s31-project-uninstall-workflow/coder-a2/final-source-manifest.json`
  beneath that source. Manifest SHA256:
  `ed75b9542451747ce8e75860419122e6d4800a380dde8be2e9d925f1209e3224`.
  All 50 listed files currently match that manifest. The three historical
  documentation entries are evidence, not replacements for current workflow.
- All eight S31-A rebaseline hash entries match both the repo-local rebaseline
  and historical A2 bytes (16/16 comparisons). No merge between those eight
  inputs is presently needed; neither snapshot is accepted source.
- All 476 entries in A2 `protected-payload-sha256.txt` match both historical A2
  and the accepted Package review witness. This is byte identity only.
- The A2 generator `prepare-successor-generation.ps1` SHA256 is
  `7e89f7e8bbc69ad02b30db4c10783f789bfb0195b5d2da8ac7e5e06a729f6764`.
  It was read/hashed, not executed. Candidate metadata remains preview.6 /
  poc.44 WIP, derived from its canonical manifest rather than new literals.

Proposed preparation after implementation authorization: create the repo-local
S31-B checkout from the accepted base; copy only the attributed A2 production,
test and candidate metadata inputs needed for this chain, recording every
copied path/hash. Keep current policy documents separate. Verify frozen S31-A
inputs and protected predecessors again before any edit. This is a new WIP
composition, not promotion of A2 or S31-A. Do not execute from or write back to
the historical external checkout; execution/evidence must bind repo-local bytes.

### Frozen exact write allowlist — AUTHORIZED 2026-10-16

All paths below are beneath `com.rice.ai-codedb/` in the future S31-B checkout.
The current main tree and existing snapshots remain read-only.

- `Tools~/codedb-project-supervisor.mjs`
- `Tools~/invoke-codedb-manager-action.ps1`
- `Tools~/materialize-codedb-host-payload.ps1`
- `Tools~/codedb-instance-engine.ps1`
- `Editor/AICodedbProcessRunner.cs` (writer/checkpoint/terminal reading only)
- `Payload~/Generations/poc.44/coordinator/codedb-watch-coordinator.mjs`
- `Payload~/Generations/poc.44/scripts/manage-codedb-project-watch.ps1`
- `Payload~/Generations/poc.44/scripts/codedb-project-common.ps1`
- `Payload~/Generations/poc.44/shared/codedb-host-use-gate.mjs`
- `Payload~/Generations/poc.44/wrapper/codedb-project-instance-worker.mjs`
- Derived identity closure only: `package.json`,
  `Payload~/payload-manifest.json`, `Payload~/host-current.json`,
  `Payload~/Generations/poc.44/generation-manifest.json`. Keep the candidate
  identity route; no new generation/native build or manual hash replacement.
- `Tests~/test-codedb-host-payload-materializer.ps1`,
  `Tests~/test-codedb-project-supervisor.mjs`,
  `Tests~/test-codedb-package-boundary.ps1` (named S31-B cases only).
- Proposed dedicated managed reader tests:
  `Tests/Editor/AICodedbUninstallRuntimeTransactionTests.cs` and its `.meta`.
  No edits to frozen Manager/UI or lifecycle tests.
- Task-owned compile/native/transaction drivers and mechanical generator copy
  under the repository-local S31-B evidence root. These are ignored outputs,
  not new production executors or alternate contract authorities.

Copying an attributed frozen dependency is input preparation, not authority to
edit it. In particular, `AICodedbEditorLifecycle.cs`,
`AICodedbManagerActionJournal.cs`, Manager presentation and
`AICodedbSupervisorBridge.cs` remain outside the proposed write allowlist.
If closing an actual record consumer requires one of those changes, return the
specific dependency for alignment. Do not reopen UI/reconnect or silently relax
an existing reader to obtain PASS.

### Production record map — proposed contract closure

Names below were found in the bound A2 source. Existing schemas are inputs,
not claims of completed cross-language acceptance.

| Record / authoritative writer | Existing real readers | Required S31-B proof |
| --- | --- | --- |
| Project `uninstall_request`: C# Journal `RequestJson`/`ReplaceIndexRequest`, protocol/schema 1; project/request/confirmation/original owner and `WINDOWS_QPC_NS` timing | PS `Read-ProjectUninstallRequest`; Node `readCodedbUninstallRequest` via Supervisor and successor host-use gate; existing C# Journal reader | Use original C# emitted bytes; agree on phase/ownership and fail closed on conflicting/missing evidence. No rewrite of frozen request/UI behavior. |
| Cancellation: PS wrapper `Request-SafeCancellation`; checkpoint: materializer `Write-CooperativeCheckpoint`; admission/claim/terminal: existing ProcessRunner/Supervisor/wrapper | PS `Initialize-CooperativeStage`/`Assert-CooperativeSafeBoundary`; Node `readDurableMaterializerResult`; C# `ReadTerminalReceipt`/`RecoverManagerAction` | Action/stage/command/project/Package, original writer/child identity, QPC deadlines, settled phase and actual exit bind together; missing proof remains Pending/Unknown, never successful removal. |
| Coordinator schema 3 / `execution_evidence`: successor `captureExecution` -> `captureCodedbExecution`, `createDaemonState`/`sanitizeStatus` | Supervisor `validateOwnedExecution`/`runOwnedRuntimeStop`; PS `Assert-CoordinatorExecutionEnvelope`; C# `ReadCoordinatorState`/`ValidateCoordinatorExecutionEnvelope` | Four roles and each 13-field record bind classification, PID/start/executable/argv/hash to project/instance/generation/epoch. State decoders do not gain process-control authority; the stop owner performs OS identity and exit checks. |
| Runtime exit response: Supervisor `runOwnedRuntimeStop` emits `[OWNED_RUNTIME_EXITED]` with request id and original execution count | Engine `Invoke-ProjectUninstallOwnedRuntimeStop`, then `Invoke-InstanceUninstall` | Bind exactly one successful response to the executing request; duplicate, foreign or malformed markers cannot authorize deactivation. Keep result parsing separate from actual exit proof. |
| Deactivation journal/desired state and result: engine `Invoke-InstanceUninstall`, `Add-ProjectRemovalDeactivationEntries`, `Publish-InstanceOperation`; materializer command result and wrapper terminal | Existing engine recovery/postconditions and real C# receipt/result readers | Commit or verified rollback under original locks, revoke original authority/selection and managed registration, preserve external content, and repeat without effect replay. Native/transaction output must reach the real C# consumer. |

### Valid fixture route and historical failure disposition

Read-only inspection confirms the A2 transaction filter globalized AST-extracted
function bodies and initializers, overrode authority/stop/recovery, then invoked
the engine leaf. Its installed path failed with empty `RelativePath`; the
historical correction allowance is exhausted. Do not rerun or rename that
closure scenario as S31-B evidence, and do not call it a proved product failure.

Proposed replacement:

1. Reserve a unique owned root inside the repo-local S31-B evidence directory;
   give child processes their own receipt/local/temp roots. Reject any live
   project, machine configuration or unowned output target.
2. Invoke the original materializer script entry in its real script context;
   let it dot-source its original engine. No AST-global extraction, bypassed
   CLI guards, forged success markers or manually invented installed authority.
   Produce candidate/selection/activation state with original production
   writers, and use only explicitly declared fixture external prerequisites.
3. Respect existing CLI modes: `-PocFixture` and
   `-ConfirmedProjectMutation` are mutually exclusive. Fixture-mode roots must
   satisfy the original reviewed ownership-marker/layout checks. Native
   confirmed-request cases use only an owned simulated project with child-local
   environment. Do not remove those guards or operate the real S30 installation.
4. Prove the setup route can create/read authentic installed state before
   claiming transaction execution. If a full entry requires an unsupported
   machine Provider setup or new injection seam, report that precise boundary
   rather than install a machine dependency or substitute synthetic authority.
5. Run the original uninstall/writer -> Node stop -> transaction -> original
   receipt-reader chain. External process seams must be named; full successor
   spawning and native exit need their own actual task-process evidence.

This approach changes the invalid fixture boundary but is not yet executed or
proved feasible end to end. Approving the later evidence envelope must explicitly
admit this replacement; the original attempts/corrections remain historical.

## Execution Envelope

- Mode: CONTINUOUS_WITHIN_SCOPE.
- Approved stages: attributable input preparation, bounded implementation and
  focused isolated evidence, stable snapshot admission, read-only Verifier,
  consolidated findings. User `好的 同意` approves the concrete grant below.
- Implementation/delegation authorization: TASK_SPECIFIC Coder -> Verifier.
- Delivery authorization: NONE; no commit, push, export or reference switch
  for this new task. The earlier S31-A documentation commit is complete.
- Side-effect authorization: task-owned simulated projects and freshly created
  fixture processes only, as bounded below. No Unity/MCP/BatchMode, real
  Install/Uninstall, existing live process control or machine Provider setup.
- Budget: Coder DEEP_60M; Verifier 30M; output V2_DEFAULT; broad audit/full
  diff/full regression forbidden. At each ceiling consolidate and stop.
- Stop: input provenance cannot be bound; work needs UI/reconnect or historical
  recovery; required source/side effect exceeds the frozen scope.
- Historical A2 correction failures remain recorded. A new task name does not
  renew the exhausted transaction-fixture retry budget. Before any execution,
  specify how a valid original-path fixture replaces the invalid extracted
  closure and obtain the corresponding evidence/correction envelope.

### Active execution grant — user approved 2026-10-16

The user approved the pending concrete proposal with `好的 同意`. This grant
activates the previously proposed scope without authorizing delivery or Unity.

- Coder: one repo-local isolated implementation writer, up to DEEP_60M.
  Freeze original input hashes, generator binding and exact case/filter names
  before first execution; implement only the proposed write allowlist.
- Side effects: only owned simulated projects, child-local receipt/temp roots
  and freshly task-created native processes. Permit normal graceful stop and
  identity-revalidated force of those exact fixture processes; no census or
  control of existing real project/external processes. A fixture executable may
  be built under the evidence root; no production native rebuild or machine
  Provider installation is included.
- Evidence order: replacement-fixture setup/admission first; cooperative
  writer and reader closure; native owned-runtime stop/no-restart cases;
  complete installed uninstall/repeat/retention and nearest shared-writer
  regressions. Synthetic state/clock tests cannot replace the native gates.
- Budget per declared new scenario: initial semantic attempt plus at most two
  corrected semantic attempts, and at most two mechanical corrections; record
  each changed prerequisite. No unchanged rerun or retry of the exhausted A2
  closure. Stop and consolidate if setup cannot be attributed, new scope is
  needed, correction limits are reached or the time ceiling is reached.
- Verifier: separate read-only review, up to 30M, after Coder terminal and
  parent snapshot admission. Review the frozen outcome, safety chain and
  declared evidence; return findings together for User disposition. No broad
  audit or direct repair requests to Coder.
- Delegation: task-specific Coder -> Verifier reuse or dispatch,
  with inherited model settings; parent remains active through both terminal
  results and handles their questions. The current user grant activates this
  route only for S31-B; no recursive delegation or parallel source writers.
- No source acceptance, commit/push, package export/reference switch, Unity
  launch, real project Install/Uninstall or release operation is included.

### Authorized focused evidence

- Compile/parse original final source and validate canonical identity/protected
  predecessor byte closure. These are static checks, not runtime acceptance.
- Use production record writers and actual decoders across the chain. Prove
  graceful exit, authenticated force, PID-reuse refusal, Unknown refusal,
  missing-roster classification and suppression of successor restart.
- Use task-owned processes for native identity/exit evidence. Label synthetic
  OS, IPC, clocks or process roles separately; no substitution for native/full
  successor lifecycle evidence where required by the final scope.
- Use a valid installed fixture through the original transaction entry point
  for writer settlement, deactivation, postconditions, retained content and
  repeated no-op. Preserve the invalid A2 closure failure as historical evidence.
- Join emitted terminal records to the real C# reader. Run nearest affected
  Install/Remove/Repair writer regressions only under a new declared envelope;
  S31-A's stopped test batch remains unchanged and UNRUN cases stay UNRUN.

## Definition Of Done

Planning completion: one task card with a single outcome, safety boundaries,
protected state, input-binding requirements and proposed focused evidence.

Later implementation acceptance requires one attributable final snapshot,
complete declared original-path semantic evidence, a stable Coder terminal and
independent read-only Verifier findings returned together to User. Compilation,
hashes or selected component PASS alone cannot establish full acceptance.
Source accept, delivery and human lifecycle validation remain separate gates.

## Handoff

- Current task: S31-B owned-runtime stop and uninstall transaction.
- Current status: PARTIAL / NOT_ACCEPTED; R3 Coder and targeted Verifier terminal.
  Original F1 CLOSED WITH DECLARED EVIDENCE LIMITS.
- Next notification: User, via current parent Planner; return the selected
  instance's runtime-config preparation prerequisite and tool-freeze limit.
- Next action: align the original production preparation route and exact
  isolated side effects before any further runtime-stop/transaction attempt.
- Human decision required: that next route and bounded evidence envelope.
  No automatic preparation, config fabrication, request release, retry,
  product edits, cleanup, delivery or Unity operation follows from R3.

### Executed outcome — 2026-10-16

Original materializer fixture Install setup succeeded; original C# request
admission to that installed fixture remains unclosed. No S31-B production fix
was made. PS Uninstall, owned-runtime stop, transaction, repeat/retention and
terminal-reader closure remain UNRUN. Historical managed runner/DLL execution
and missing pre-execution scenario freezing were disclosed; those managed
observations are diagnostic only, not final-source evidence. The existing
instance manifest's 292-character locator is a static fact, not a proven cause.

Parent admitted the stopped Coder snapshot once: 47 source and 542 evidence
hashes matched. Verifier independently confirmed those matches and all 476
protected payload entries across the three bound copies, then returned one
P2 / EVIDENCE_GAP with no demonstrated product BLOCKER. No real machine receipt
write was established by the bounded evidence. All fixture state is preserved.

Terminal records: `RESULT.md` SHA256
`61b3e25705073ef5ec009f36d414ea91c8958e16f29d4b7154aab1139f87dabb`;
`VERIFICATION.md` SHA256
`bb5299c8a9573a719aaecc48d2a62d7aaad0b984ec4762b674fe7e4b174508b7`.
The earlier execution grant records the completed attempt, not automatic
authorization to repair or rerun after these independent findings.

### F1 bounded correction — user approved 2026-10-16

This subsequent grant approves the parent's proposed repository-local,
current-snapshot managed fixture and path-capability correction, then gated
continuation of the previously declared isolated uninstall chain. Reuse the
stopped Coder, followed by the stopped read-only Verifier. Coder ceiling remains
DEEP_60M for this bounded correction; Verifier ceiling remains 30M. No new
product objective or release authority is added. The first result, verification
and all 542 frozen evidence files remain historical evidence, not overwritten.
Coder appends one dated R2 section to RESULT; Verifier appends a targeted R2
section to VERIFICATION after Coder terminal and parent admission.

F1 correction writes are task-owned drivers/build outputs and RESULT only.
Original product/reader source remains read-only for this correction. If a
genuine product change is needed, report the exact finding and dependency;
do not change Journal, validation or generation metadata to obtain PASS.

One explicitly selected compact run owner is
`<repository-root>/.artifacts/tests/s31b-r2/`. Reserve it exclusively; reject
an existing root or any reparse escape. This is a deliberate preselected layout
inside the same repository, not a silent runtime fallback. It avoids adding
the full task identifier to every fixture consumer path. Source stays at the
existing S31-B checkout. Preserve the prior long fixture; do not move, rewrite
or delete it. All new compile, fixture, local/receipt/temp and log outputs are
children of the compact owner, mapped back to this task by a run manifest.

Freeze these case identifiers and entry filenames before first execution:

| Case | Entry under compact owner | Gate / criterion |
| --- | --- | --- |
| S31B.R2.ManagedCompile | `run-r2.ps1` / `build/` | Compile original current checkout Editor source and its actual dependencies; record source/RSP/reference/tool hashes. No historical CodeDB DLL/runner/reference assembly, source rewriting or substituted production APIs. Existing Unity compiler/framework binaries may be read as tools only; no Editor launch. |
| S31B.R2.PathCapability | `managed-fixture.cs` | Same target Mono/API process checks exact existing long instance-manifest read read-only, then create/read/delete probes at deepest proposed short fixture/receipt paths including publication suffixes before setup. Record paths, lengths and exceptions. No OS settings changes, system-temp fallback or retry under another root. |
| S31B.R2.OriginalInstallSetup | `run-r2.ps1` | Fresh uniquely owned compact fixture with reviewed marker/layout; original materializer Install -PocFixture writes installed authority. Preserve old fixture and respect original guards. This new setup differs in managed provenance and declared compact root. |
| S31B.R2.ManagedRequestAdmission | `managed-fixture.cs` | Rebuilt original Journal emits request for the fresh installed fixture, original Read agrees; existing test root seam supplies owned receipts. Include absent fixture and mismatched project/Package refusal as nearest reader checks. No handwritten request authority. |
| S31B.R2.UninstallTransaction | `run-r2.ps1` | Only after prior cases PASS, run original PS/Node path against this owned fixture; verify actual deactivation, retained-content postconditions and repeat no-op through original readers. Respect PocFixture/ConfirmedProjectMutation exclusion; unsupported authority setup means stop, not bypass. |
| S31B.R2.TerminalReaderJoin | `managed-fixture.cs` | Feed actual produced terminal evidence to rebuilt original C# reader. Missing proof remains Unknown/Blocked, not invented success. |

Native stop/restart/writer scenarios still need their own task-owned execution
evidence under the original safety envelope; these case labels do not substitute
for it. If further scenario execution is feasible in this window, the Coder
must freeze exact driver/case names and process ownership before launching it.
Keep already declared attempt counts; this correction does not renew the
exhausted historical A2 extracted-closure budget or reclassify previous failed
attempts as PASS. Record each materially changed prerequisite and correction.
The existing long-locator read is a diagnostic comparison: preserve its failure
if observed; it is not a promise to support arbitrary fixture path lengths.
At any failed selected compact-root path capability, provenance gap, unsupported original-entry
prerequisite, required scope expansion or active-time ceiling, stop that
dependent path, consolidate attributable evidence and return the stable result.

### R2 terminal outcome — 2026-10-16

Current-source compilation (30 Editor sources, 219 references) and selected
compact paths under actual bound Mono passed. The old 292-character locator
failed an exact read-only Mono read; keep this as that locator's runtime
observation, not a demonstrated normal product defect. No product bytes changed.

R2 setup used two recorded mechanical corrections: fixture-id length and
non-recursive cleanup of ten owned empty probe directories. On the final
permitted setup attempt, original Install returned PREFLIGHT/BLOCKED,
PROVIDER_MISSING, exit 4 and empty mutated_scopes. Its original Provider reader
derives its root from process LOCALAPPDATA; the receipt-isolation setting also
redirected that prerequisite lookup into a fresh task-local store. No machine
Provider absence, product uninstall failure or successful install is implied.
No Provider was copied/installed and no real local store fallback was used.
Installed admission, uninstall, native stop, transaction and terminal-reader
join remain UNRUN. The correction budget is not renewed by relabeling a driver.

Parent admitted the stopped snapshot with 47 source / 249 new evidence hashes
matching. Targeted Verifier independently confirmed those sets, all 30 compiled
sources, 219 references, three tools and the original 542 evidence files. The
missing pre-freeze and historical CodeDB binary execution deviations are resolved
for R2; prior evidence remains diagnostic. F1 is still P2 / EVIDENCE_GAP; no new
product BLOCKER was demonstrated. Both authorized children reached terminal
completion before returning this outcome to User.

R2 RESULT SHA256:
`6976dfc7faa1a66413055952a516fc9a4e15146925f2c10d06b034aba32fdc37`.
R2 manifest: `.artifacts/tests/s31b-r2/FINAL-MANIFEST-R2.json`, SHA256
`0cf37d729124c7194ce7a3b305e5d1e5b6d62c38ed514f2a5263b5ac26074980`.
Appended VERIFICATION SHA256:
`c9eec59e4f8eda8a37b7d2a6e56ab35b134e1b7ba88c30ad03f33b38d79eaf5e`.

### R3 isolated Provider prerequisite — user approved 2026-10-16

Grant source: after the parent proposed an exact-byte copy of the existing
Provider executable, manifest and notices into a repository-local isolated
store, retaining child-local LOCALAPPDATA and original validation, the user
replied `好的 我们继续`. This activates that specific prerequisite route and
its gated fixture continuation. It grants no machine installation, download,
environment fallback, product source change, delivery or Unity operation.
Reuse the stopped Coder -> stopped read-only Verifier; depth one, inherited
model settings, Coder ceiling DEEP_60M, targeted Verifier ceiling 30M.

Provider read/copy allowlist, derived from the current Package contract:

- Source: `<real-localappdata>/Rice/CodeDB/providers/<required-version>/`.
  Resolve the one required version from the bound contract, not a machine scan
  or newest-directory heuristic. Source files are read-only and not executed
  there. Read-only alignment found the required version and matching EXE hash.
- Exactly `codebase-mcp.exe`, `provider-manifest.json`,
  `THIRD-PARTY-NOTICES.txt`; reject missing, changed or reparse inputs before
  copying. Preserve original bytes, with source/destination hash comparison.
- Observed input SHA256, to be rechecked before the copy: executable
  `38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7`;
  manifest `82bdc9508e05f1fae0ad013a96d88fd4e5c336c48b96a13b00a6d43cc2cb57a4`;
  notices `5e69d07d422c858d299e1d51eac4aee820231ae4961151890e00ca278c9894ab`.
- One exclusively reserved compact owner:
  `<repository-root>/.artifacts/tests/s31b-r3/`.
  Copy target: `local/Rice/CodeDB/providers/<required-version>/` under it.
  All other R3 fixture, receipt, temp, build and log writes stay under this same
  owner. No links to the source store; no parent/global environment changes.
  Original production readers may validate/use only the owned copy for the
  task fixture; source Provider, real projects and real receipts remain read-only.
- Product source remains read-only. The attributable R2 Editor DLL may be copied
  into R3 build output after binding its hash to R2's final manifest and checking
  the 30 original source hashes have not drifted. It is the current-source R2
  build, not permission to reuse historical A2 binaries. Recompile only the new
  driver against that exact closure; no repeat unchanged compilation required.

Before first execution freeze `RUN-MANIFEST-R3.json`, `run-r3.ps1`,
`managed-fixture-r3.cs`, source/build/tool hashes, all paths and child env plus
these named scenarios:

1. `S31B.R3.ProviderPrerequisite`: source/copy hash checks and original Provider
   reader under child-local environment. No new manifest fields, fake Provider,
   changed protocol or forced CURRENT output. Treat Provider executable version
   and integrity as declared prerequisites, not runtime lifecycle evidence.
2. `S31B.R3.PathAndFreshSetup`: verify deepest actual consumer paths using R2's
   original helper/Mono API; remove only owned empty probe scaffolding before
   first Install, with recorded nonrecursive cleanup. Then original
   materializer Install -PocFixture against the declared fresh owned fixture.
3. `S31B.R3.ManagedRequestAdmission`: current-source Journal writer/reader on
   that actual installed fixture, with absent/foreign-owner nearest checks.
4. `S31B.R3.UninstallTransaction`: only after preceding gates pass, original
   materializer/wrapper/Node chain, honest terminal result and existing
   deactivation/postconditions; keep PocFixture/ConfirmedProjectMutation guards.
5. `S31B.R3.TerminalReaderAndRepeat`: actual terminal evidence into original C#
   reader; retained user content and repeat no-op without a second effect replay.
   Freeze the repeat entry and expected production state before running it.

Attempts remain cumulative. R2's two mechanical corrections and exhausted A2
closure are not reset. The user-approved added prerequisite permits ONE further
original Install setup attempt with the materially changed Provider input; do
not rerun it on failure or invent C3/C4 corrections. The new Provider-copy
preparation may have at most one construction correction before any product
semantic execution. New previously UNRUN downstream scenarios retain the
original bounded attempt rules, but no product source fix is included in R3.
Stop on any provenance/capability/prerequisite failure, original setup failure,
genuine product defect requiring edits, unavailable authority or time ceiling.
Never handwrite installed/uninstall authority or substitute success markers.

Native runtime/writer/restart gates remain separate and must not be reported
PASS from these fixture cases. No extra native scenario is added by this
prerequisite correction; unexecuted gates remain UNRUN. Preserve original,
R2 and R3 failures/logs. Append R3 results to RESULT and targeted review to
VERIFICATION only after stopped Coder admission. Source acceptance remains
pending the independently assessable declared evidence, not the prerequisite.

### R3 terminal outcome — 2026-10-16

Provider exact-byte copy and original validation, 13 selected-path probes,
ONE original fixture Install and actual installed Journal request writer/read
all passed. Original C# terminal reader also authenticated the actual failed
Uninstall result. Original F1 is CLOSED WITH DECLARED EVIDENCE LIMITS; later
unexecuted native/transaction gates are not added to that original finding.

The one Uninstall attempt returned PREFLIGHT/BLOCKED/MATERIALIZER_EXIT_1,
mutated_scopes empty. Its selected instance lacks config/codedb-mcp.toml at a
221-character locator. The original PocFixture branch skips runtime preparation;
the original Node stop entry first calls buildContext, which requires this
config. This is a demonstrated fixture/consumer prerequisite mismatch, not a
demonstrated normal real-install uninstall defect. Native stop/deactivation,
writer settlement, restart suppression, successful retention and repeat remain
UNRUN. No product source was edited or config fabricated; no retry was run.

One allowed Provider construction correction was used; prior/R2 failure budgets
and evidence remain preserved. R3's Node and Windows PowerShell hashes were
attributed only after execution, a disclosed pre-freeze deviation. No full
pre-frozen-tool or native/end-to-end acceptance is claimed. All child invocations
returned; no runtime successor was launched. The installed selection/desired
state, EXECUTING request and failed terminal remain preserved in the owned
fixture, without implicit cleanup or Journal release authority.

Parent admitted 47 source / 304 R3 evidence hashes with zero mismatches. Targeted
Verifier independently matched those sets, all 30 managed sources, 219 references,
three pre-frozen tools and historical/R2 evidence, then stopped. No new product
BLOCKER or broad audit finding was established. Both children completed before
returning the single remaining prerequisite to User.

R3 RESULT SHA256:
`bcd1e92492662bef35b06c149812051153042e5f6c0e2aa1cdc8b9bececf9bc4`.
R3 manifest: `.artifacts/tests/s31b-r3/FINAL-MANIFEST-R3.json`, SHA256
`553faf7e7554040f7b4cefbb60041f7452cc7d3bd8b2e9b6d931c3e45cae3b58`.
Appended VERIFICATION SHA256:
`3e3565948ee981c03b6d40ffbf323e3ff8e33ae0c97acc9abf3556560839d6d6`.

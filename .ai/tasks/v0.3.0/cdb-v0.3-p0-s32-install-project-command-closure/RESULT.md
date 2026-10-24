# S32 Coder result - 2026-10-17

Status: stable source snapshot, focused HARNESS PASS_WITH_LIMITS; ready for the
independent targeted Verifier. This is not source ACCEPT, full L1 lifecycle
acceptance, Unity acceptance, delivery or permission to retry the real project.

Baseline HEAD remains `97471f537749eba97171f6756a29112dd552a22b`.
Incoming active bytes are bound by `BASELINE-SHA256.md`; implementation uses
those bytes, not the old delivery extraction. Model/effort were inherited by
the task-scoped Coder; no tool exposes a reliable exact runtime model/effort
identifier here, so neither is invented. No children were created by Coder.

## Implemented boundary

- `RunInstallCodeDBAsync` enters the original materializer directly and retains
  its existing post-install reconcile policy. Initialization/prerequisites,
  candidate verification, activation and readiness code are unchanged.
- New Manager Install admission persists `project-install-v1` in its existing
  index and compact identity manifest. The session restores that recorded route.
  Index/manifest route mismatch refuses; exact release also checks route.
  Legacy unmarked records retain the original dual-route reader, without title
  reclassification, migration, recovery backfill or replay.
- Existing writer authenticates the Install command, then passes its admission
  locator only to its child. The new read-only admission runs under the existing
  project operation lock, before recovery/candidate creation. It authenticates
  current writer/child identity, observes relevant Windows processes, retained
  holders, current/alternate Supervisor authorities and bound terminal history.
  Missing selection/state is never the absence proof. No process is terminated.
- New direct Install normal/reopen reads existing real writer receipts offline.
  A same-action Supervisor map/canonical operation keeps the outcome unknown.
  Claimed/pending/malformed direct evidence remains unknown; proved pre-dispatch
  refusal and complete writer failure/success retain distinct semantics.

## Focused evidence

Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File
.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/run-focused.ps1
-Attempt frozen`.

Evidence root: `.artifacts/tests/s32-install/frozen/`.
Its `manifest.json` binds original Editor/test sources, existing tool/reference
hashes, child roles, repository-local output/temp/local-data roots and no network.
PowerShell execution uses original production writer and materializer bytes
copied into task-owned fixtures. No real project or Package extraction is edited.

- L0 PASS: all original Editor/test source compilation against the prebound
  compiler/references, and both touched PowerShell scripts parse. Three existing
  compiler warnings remain (`CS4014` twice and `CS0414` once).
- HARNESS PASS: original ProcessRunner admission -> original writer -> original
  materializer's genuine missing-payload failure -> original receipt reader ->
  offline Manager resolver, normal/reopened session and exact journal release.
  Both clean first-install and retained Supervisor-directory topologies reach
  that writer; no successful installation strings are fabricated.
- HARNESS PASS: repeated project admission refuses; missing terminal cannot
  release; a competing same-action Supervisor map cannot be adopted; reopen
  leaves the original terminal bytes unchanged. Missing writer produces a real
  pre-dispatch refusal, which remains separate from complete command failure.
- HARNESS PASS: original project lock + original new admission function accepts
  clean and completed bound-uninstall-history/maps topologies. Live/unknown
  retained holders, unknown writer, project-bound live Supervisor without owner
  files, inaccessible relevant metadata, current/alternate owner evidence,
  running history and original historical child all refuse. PID reuse is
  distinguished using the original process-absence identity helper; no kill.
- Existing focused reconcile policy cases PASS: complete trusted success with
  cleanup COMPLETE permits existing reconcile; failure, UNKNOWN, pending cleanup,
  unauthenticated success and missing/malformed command status do not.
- Targeted `git diff --check` PASS.

Earlier evidence is preserved: attempt `a` ran before the admission harness file
was present; `b` lacked the shared strict-JSON harness dependency. Those are two
mechanical harness corrections, not product failures. Attempts `c`, `final` and
`final-2` passed their then-current scenarios. `frozen` is the final source/test
binding, including the child-local test-entry guard and pre-dispatch refusal.

## Limits requiring honest downstream disposition

Evidence level is HARNESS, not complete production L1 or Editor compatibility.
The runtime chain begins at original ProcessRunner; the parameterless Actions
entry and original initialization chain are source-verified, not invoked through
a live Unity Manager. The engine safety harness invokes original guard/lock and
process-absence helper, with explicit process inventory and validated-retained-
closure inputs. It does not independently recreate the installed closure or run
the full convergence engine. The C# retained topology proves routing and result
handling; the engine fixture separately proves admission decisions. These are
not proof that normal real uninstall -> successful install -> Ready has passed.

Successful initialization, Provider startup, activation/readiness, human Unity,
real process-inventory visibility and real reinstall remain DEFERRED. The new
Editor test requires an explicitly supplied child-local fixture environment and
is otherwise ignored, so ordinary Test Runner cannot write external receipts.

Admission deliberately refuses unobservable relevant process metadata and any
live project-bound shell/Node execution. This can include a concurrent diagnostic
process; it grants no automatic retry. Older unbound/incomplete execution history
remains refused rather than migrated. No compatibility recovery is added.

The real S30 failed action `6b9678672d3744f0ab052e521ae42ad6`, its pending index,
all runtime/config, old archive/backups and delivered Packages were untouched.
No Unity, Supervisor/backend, real Install/Uninstall, process termination,
network, commit, export or reference switch was performed.

## Preserved incoming changes

ProcessRunner incoming durable-writer timeout/termination hunks remain intact;
S32 only changes manifest route serialization/validation there. Writer incoming
transaction timeout/drain/termination logic is untouched. Instance-engine incoming
repeated-Uninstall observational-idempotence hunk is untouched; S32 only adds the
Install execution guard and its lock-local invocation. Existing contract text is
preserved and the S32 contract is appended. HostPayloadMaterializer,
SupervisorBridge, ManagerUiTests and EditorLifecycleTests exactly retain their
incoming baseline hashes. Payload/manifests and unrelated dirty files are not
part of this change and were not staged/reset/cleaned/exported.

## Final changed-file SHA-256

Paths below are relative to `com.rice.ai-codedb/`.

| Path | SHA-256 |
| --- | --- |
| Editor/AICodedbActions.cs | 024f405b11a3c482d7d0cfd3f424e855a060469cd3653165116c9dc21bd14600 |
| Editor/AICodedbManagerActionJournal.cs | 0987f76cc98f5250e3018d77c88184775fb9a6cae1c91eb858e16a6f2e48bfed |
| Editor/AICodedbManagerWindow.cs | f62d589a32c32e31baab29c463a099a5ea002fc42859fbc716d48bf9aecf7dcc |
| Editor/AICodedbProcessRunner.cs | a3c9ae743c4634167f8cbbf20146be9b06132f8a54ef8f9e463f3a4bfc7380d1 |
| Editor/AICodedbInstallAdmission.cs | c6cc6823ba589a675f7072643f662d70b3823019dea57442b28ed583b07650c0 |
| Editor/AICodedbInstallAdmission.cs.meta | 05d0b3f0ed5c532c2fa2b6523f6ca06eb53dce60ac2ebb765fdc04f7ae67f62b |
| Tools~/codedb-instance-engine.ps1 | 537e5b871f7d9194935c866651c4954097e020981532877bfa0a8856903397c7 |
| Tools~/invoke-codedb-manager-action.ps1 | 44216a7061384c095b54b2183bc9dacb19f63428c3868f19ec9f1f4c8b11334c |
| Tests/Editor/AICodedbS32InstallTests.cs | 9726c9115d61447d6417ff5c96a03a00971ad172557a11040a6faefaefbfde59 |
| Tests/Editor/AICodedbS32InstallTests.cs.meta | 9ddb5c599dd4ffdcc8b7c2ef90acc8a1813bef025c41f6854aff268e4e6640f0 |
| Documentation~/v0.3.0-p0-host-action-execution.md | f3f345d217ad0acf616846afc455f9bf513424191ca71e4625a6bc359331bbc5 |

Task-local driver hashes:

- `run-focused.ps1`: `cdf970a69fa9a5c25ecc20a457918f28cecc86a398d28bd2883c191a46de9be5`
- `test-admission.ps1`: `e9f9c9b37d2ce099e5056ddd4ce0ee142e49f98020355d69633c649aa8fd205e`

Next: independent targeted read-only Verifier, then user ACCEPT/FIX/DEFER/STOP.
Coder stops at this stable snapshot.

## F1/F2 convergence repair - 2026-10-18

Status: stable repaired source; focused HARNESS PASS_WITH_LIMITS, awaiting
independent F1/F2-only repair review. This append supersedes the original
machine-wide inaccessible-process veto and exhaustive retained-generation
history validation described above. It does not change the original evidence
or VERIFICATION.md, and does not constitute source ACCEPT or real retry approval.

### Changes and supported boundary

Only product files changed during repair are the new Install admission portion
of `Tools~/codedb-instance-engine.ps1` and the necessary S32 contract clarification.
No route reader, writer producer, Supervisor producer, initialization or readiness
code was changed. The incoming repeated-Uninstall hunk remains outside repair.

- F1: inaccessible metadata on an unrelated same-name shell/Node row no longer
  blocks this project. Readable project-bound execution still refuses; an
  identifiable competing writer's admission is checked for this project.
  Authenticated writer/child ownership, retained holders, owner/start/takeover
  namespace evidence and referenced child identity remain independent vetoes.
  No process termination, global absence claim or global process collector is added.
- F2: project-local history receives bounded structural discovery, including
  schema/identity/terminal shape, timestamps, child evidence shape and complete
  result flags. Queued/running, malformed, missing-result, timeout, output-overflow
  or drain-incomplete records cannot become inert history simply because another
  canonical operation overwrote them. This discovery is necessary to locate
  unclosed/conflicting execution, not an audit/recovery of all historical effects.
- Deep retained-Package contract validation and recorded-child process observation
  follow the canonical operation, its same-action operations and any retained
  instance originating-operation id present in Supervisor history. They reuse
  `Assert-RemoveIntegrationTerminalOperation` and the existing PID-reuse helper.
  Its older exact result shape is projected only after the original complete
  result flags were validated; original records are not rewritten. Coherent
  inactive history need not keep an old retained generation available forever.
- All map operation ids must resolve to structurally complete matching-action
  history, rather than requiring exactly one operation forever. The producer's
  existing limit of 16 is retained. Missing canonical anchor with history remains
  explicit unknown evidence. No history deletion/backfill or alternate authority
  fallback was added. Removal-intent operation ids equal their removal state ids;
  they are not invented Supervisor references. Existing next-change admission
  independently owns local instance/activation transaction checks.

### Original producer-order prerequisite

Source-backed order checks run by `run-repair.ps1` and the bound original files:

- Direct writer authenticates admission/command, publishes its durable claim at
  `invoke-codedb-manager-action.ps1:266`, then starts its child at line 286.
  The admitted child carries the exact locator and the guard authenticates its
  writer parent under the existing project lock.
- Supervisor start obtains the attributable start claim before daemon spawn
  (`codedb-project-supervisor.mjs:894`); daemon acquires its owner lock before
  server/coordinator startup (`:1006`). Owner/start evidence remains a blocker.
- Maintenance admission persists queued operation before scheduling (`:1388`),
  and persists running operation before executing its callback (`:1353`).
  Materializer child preparation persists its phase before `runChild` (`:2022`).
  `persistOperation` writes canonical before history/map (`:2137`); discovery
  checks all local execution headers so an overwritten canonical cannot hide an
  unfinished operation.
- Actual child identity capture is post-spawn (`:2381`, `:2407` onward). It is
  not used as the pre-effect absence proof: already-published owner/operation
  evidence covers that interval, and missing/incomplete execution evidence
  refuses. Complete terminal plus recorded child absence is only consumed for
  the current/referenced authority after those independent gates.

These are source-order and controlled contract checks, not proof of all possible
unmanaged/foreign processes. An unrelated inaccessible row supplies no claim
about global process absence. No supported producer needed modification.

### Final evidence and attempt ledger

Final command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File
.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/run-repair.ps1
-Attempt repair-e`.

Final root: `.artifacts/tests/s32-install/repair-e/` (`manifest.json`,
`admission-test.log`, `route-result-regression.log`). Original source publication
order checks and PowerShell parsing passed before children. All 25 focused
admission scenarios passed, including unrelated inaccessible metadata versus
referenced unknown identity; retained complete uninstall and complete failure;
timeout/overflow/drain/missing result/flag/malformed timestamp; inert old
generation versus retained-origin reference; hidden queued/running/noncanonical
incomplete execution; missing canonical anchor; owner/alternate conflicts;
PID reuse versus original child live. The original frozen C# writer/result/
reopen/journal regression also passed against a fresh child-local fixture root.

No C# source changed during repair, so no recompilation/full suite was repeated.
The driver checks all frozen original C# sources/tool/reference hashes and binds
the reused frozen assemblies, current scripts/drivers and repository-local
output/temp/local-data roots. All final child sessions completed with exit 0.
Scoped `git diff --check` passed.

Attempts are preserved; no additional run is planned:

| Attempt | Reason and result |
| --- | --- |
| repair-a | Initial F1/F2 correction: focused guard and immediate original route/result regression passed. |
| repair-b | First semantic closure: added retained-origin/current-anchor discovery and 16-entry producer limit. Fixture failed because mocked Manifest used Hashtable, while original exact JSON helper requires PSCustomObject. Product failure was not inferred. |
| repair-c | Mechanical fixture correction 1: use actual JSON object shape. All then-current scenarios and immediate regression passed. Subsequent fixture inspection found the new origin refusal could be a missing shared-function failure, so that individual claim was not relied upon. |
| repair-d | Mechanical fixture correction 2: load existing shared origin contract, reject command-not-found as a valid refusal, require the expected origin-binding reason. All scenarios and regression passed. |
| repair-e | Second semantic closure: structurally validate every discovery record before granting inert status, including timestamps and child shape; current/referenced generation/process audit stays bounded. Final scenarios and immediate regression passed. |

Repair mechanical and semantic correction allowances are consumed; Coder stops
here for targeted independent review, without another broad test/rework loop.

Evidence remains HARNESS. Process inventory/identity and retained closure inputs
are explicit mocks around original guard/lock/functions. The original C# runtime
chain starts at ProcessRunner, not a live Unity Manager. Successful full Install,
Provider initialization, activation/Ready, Unity compatibility and real inventory
visibility remain deferred. No real S30 runtime, pending index, history/config,
external process, archive or delivered Package was changed. No commit, export,
reference switch, network, Unity or actual lifecycle operation was performed.

### Repaired snapshot hashes

The original 11-file snapshot table remains valid except these two overrides
(paths relative to `com.rice.ai-codedb/`):

| Path | SHA-256 |
| --- | --- |
| Tools~/codedb-instance-engine.ps1 | 2180bdf507cb18e1f0ad050734eaa995169df8250b8dfd9c7c0d474c27ab6444 |
| Documentation~/v0.3.0-p0-host-action-execution.md | 77e30fa9f65e6538c529354a22c76149340f4ae8bfa49587514d401e56beb3b7 |

Task-local repair drivers:

- `test-admission.ps1`: `0719e2fee8c3bd31a0094daf4ad1fdf4ecfa6680b9ba2920d4d4e0712144b1df`
- `run-repair.ps1`: `c47aee36e163f53bb334f1d79c30a46fa243ff423eac2506888312f5af34ed5e`
- `run-focused.ps1` is unchanged from the original snapshot.

Next: parent snapshot admission, then read-only `VERIFICATION-F1-F2.md` limited
to the original findings and their immediate regression. Coder is stopped.

## Approved execution-disposition refactor - 2026-10-18

Status: stable source, focused HARNESS PASS_WITH_LIMITS; Coder stopped for
`VERIFICATION-DISPOSITION.md`. This is the separately approved bounded
producer/consumer refactor after route reassessment. Original snapshots,
VERIFICATION.md, VERIFICATION-F1-F2.md and previous attempts remain immutable.
No source ACCEPT, delivery or real-state retry is implied.

### Field and consumer map

Exactly one optional serialized field is added to the existing durable operation
and its public projection: `execution_disposition`, enum `UNKNOWN`, `NO_CHILD`,
`CHILD_ADMITTED`. No extra bookkeeping fields, result store or executor was added.

| Boundary | Behavior |
| --- | --- |
| Supervisor maintenance operation admission | New operation explicitly initializes UNKNOWN; old missing fields remain absent, not backfilled. |
| Original ensureCoordinator ready/attach branch | Publishes NO_CHILD only if the operation still explicitly has UNKNOWN and child:null. A prior child admission is never downgraded. |
| prepareOperationChildEvidence | Publishes CHILD_ADMITTED before spawn. For a second admission, missing prior captured identity refuses; captured previous child must be observed absent or PID-reused before replacing its record. Live/unobservable prior execution refuses without spawning or erasing its evidence. |
| Watcher and recovery Verify | Join the existing pre-spawn admission/capture calls. No new command or process-control behavior; a legacy/uncertain operation cannot silently acquire another child. |
| recordChildEvidence | Requires the unique pending CHILD_ADMITTED slot before recording original captured identity. |
| finish/error/recovery | Existing terminal serialization retains disposition; none converts prior admission to NO_CHILD. Existing child/result/output checks remain independent. |
| publicOperation | Projects explicit disposition; missing legacy projects UNKNOWN without rewriting durable history. |
| validatePersistedOperation | Accepts only the enum when present, rejects NO_CHILD with child evidence, preserves missing legacy as unknown. |
| PowerShell shared strict operation readers | Accept the optional field and validate its enum. Proved NO_CHILD requires null child and complete explicit output flags, bypassing only nonexistent-child proof. Existing legacy removal's identified-child checks remain; no legacy null-child safety is inferred. |
| Install admission | Bounded terminal discovery selects current/same-action/retained-origin authority before detailed child validation. UNKNOWN/missing refuses, NO_CHILD requires null child, CHILD_ADMITTED requires captured child structure. Current/referenced child-bearing authority still validates retained Package contract and actual child absence. |
| C# protocol and exact Uninstall terminal reader | Existing readers accept extra operation fields. Their exact spawned Uninstall child/argv/result binding is unchanged; they do not consume NO_CHILD to release an action. No C# source edit/compilation was needed. |

Inert-history evidence is declared rather than inferred from missing owner files
or later uninstall: structurally complete terminal/output, explicit producer
disposition and (for CHILD_ADMITTED) captured child structure. Such inactive
history is not required to retain an old Package closure forever. Current and
referenced authority retains the separate instance/contract/process checks;
queued/running/conflicting/incomplete hidden records still refuse. The new field
does not prove old S30 null-child history safe and does not release its pending
action. Existing owner/claim and project lock checks are unchanged.

Multiple-child scope: the existing single last-child slot is sufficient because
the producer refuses to replace an unresolved slot and proves the captured prior
child absent/PID-reused before a new admission. Its safety boundary is original
process identity observation, not a new global inventory. A previously supported
multi-child route may now explicitly refuse if prior identity was never captured;
it cannot guess closure merely because a prior result succeeded. This is the
approved fail-unknown behavior, not a retry/termination mechanism.

### Evidence

Final command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File
.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/run-disposition.ps1
-Attempt disposition-b`.

Root `.artifacts/tests/s32-install/disposition-b/`: manifest binds original
scripts/test entry, driver/setup hashes, existing Node/tool/reference identities,
child-local temp/local-data/output roots and network=none. Logs: producer-syntax,
producer and reader. Both changed PowerShell files parse; Node original producer
syntax check passes. Node fixture itself runs its new focused entry only and
never enters the live named-pipe/Supervisor harness.

The fixture extracts the original ensureCoordinator ready/no-spawn branch,
original nested finishOperation, compactResult, publicOperation, actual child
admission/capture and original durable canonical/history serializer into a VM.
Coordinator status and process observations are explicit fixture inputs;
runChild is forbidden. The generated original operation bytes then pass through
the actual PowerShell Install guard under its original project lock, with
retained closure/process inputs explicitly mocked. This is HARNESS, not live
Supervisor/Coordinator/Provider or full lifecycle acceptance.

Producer assertions PASS: ready branch publishes NO_CHILD through original
terminal serializer/public projection; missing legacy stays absent/public UNKNOWN;
CHILD_ADMITTED is durably visible before any spawn; failed capture and later
attach/finish do not downgrade it; second admission with missing capture refuses;
known-live/unobservable prior child refuses while preserving its bytes; proved
prior exit admits the next child, whose missing capture remains CHILD_ADMITTED.

All 12 actual PowerShell reader cases PASS: original ready NO_CHILD current;
original identified spawned child; inert NO_CHILD without old generation;
legacy missing; first/second capture missing; NO_CHILD/child conflict; explicit
UNKNOWN; incomplete NO_CHILD output; hidden unfinished operation; referenced
child still live; referenced child identity unknown. NO_CHILD passes full
current instance/contract/terminal checks rather than bypassing them.

Attempt ledger: disposition-a stopped on one mechanical VM fixture omission,
`coordinatorStatus` required by original finishOperation. No product cause was
inferred. disposition-b adds that explicit mocked dependency and passes the
same original boundary end-to-end. No semantic correction/retry was needed.
No unchanged full batch, compilation or original lifecycle suite was rerun.
Scoped diff check passes. No test process/session remains running.

Limits: new-operation initial UNKNOWN construction is source-checked; fixture
operations supply original-boundary context explicitly. Process/Coordinator
status/retained identities are mocks, not machine-visibility evidence. This does
not establish successful full initialization, Provider startup, Ready, Unity,
real reinstall, external inventory or historical S30 recovery. No source outside
the approved producer/direct readers/fixtures/contract changed. Incoming timeout,
termination/idempotence/Payload and unrelated state were preserved; parent admits
protected hashes independently. No real project/runtime/index/history/config,
external process, delivered extraction, commit/export/reference or network action
occurred.

### Final snapshot overrides/additions

The original 11-file table remains applicable except engine/doc overrides below;
the other nine source/test/meta files are unchanged by this refactor. Newly
allowlisted producer/reader/test files are bound here, package-relative:

| Path | SHA-256 |
| --- | --- |
| Tools~/codedb-project-supervisor.mjs | 4842c3ed260b05bfe0adf65bce24c8acc7cdf0b68f8d2ffc852bf301f2de92be |
| Tools~/codedb-instance-engine.ps1 | 0e6f45d6f80751470c61f40d25d3c15d157512824d095b3d06bb6133bffb737d |
| Tools~/materialize-codedb-host-payload.ps1 | 44b1455513b32843b801d243e04ef2fb2267795f715181f8c904ffdd80cda73b |
| Tests~/test-codedb-project-supervisor.mjs | 2d434fbd1869472e6085ebb70e450d792c9580af543afcd1e8c6693092a7bb02 |
| Documentation~/v0.3.0-p0-host-action-execution.md | 2c06d535305f6c00b8a54fca81ef44dfa14667036bfc358304b5eee8f67b8df1 |

Task-local drivers:

- `test-admission.ps1`: `570ebe5cf80648cf19b724c75f6a45054d059125d295b19021832ff9597234db`
- `test-disposition.ps1`: `6cdb081ed7949d79f01ccbcfc6d3f9768556719bf4bf0d364a27b8028c698a0b`
- `run-disposition.ps1`: `f2ae9aa15cf0236a285354454be7be855829e44809e5f33fed0e1055d547cdca`

Original review reports, previous evidence and run-focused/run-repair drivers
were not modified. Parent admission -> one disposition/F2-nearby read-only
Verifier -> User disposition. Coder stops at this snapshot.

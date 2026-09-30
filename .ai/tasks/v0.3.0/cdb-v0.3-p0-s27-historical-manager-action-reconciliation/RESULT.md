# S27 Result

## Contract Freeze And Feasibility Admission - 2026-09-29

The Historical Unknown-Action Reconciliation Amendment was appended to the
Host Action Execution Contract. It keeps the old command outcome unknown,
preserves all original evidence, and permits no administrative closure without
both exact execution quiescence and independent project-state proof. S25
`TASK.md` now routes its blocked Gate C through this single continuous task.

The bounded source/evidence admission found a cross-boundary proof gap:

- The exact S25 stage still contains only `admitted.json` and `claim.json`.
  The claim records the writer PID/start identity, but not a child PID. The
  S25 writer publishes `claim.json` before runtime `Add-Type`; its child PID
  appears only in the missing terminal document. The reported `Add-Type`
  exception is consistent with pre-child failure, but is not a durable,
  action-bound start-failure record.
- A present-day writer PID check, process-name scan, elapsed timeout, or
  `INSTALLED / COMPLETE` project observation cannot alone exclude a surviving
  business descendant or retroactively prove the old child never started.
- `Invoke-RemoveIntegration` owns the materializer project lock, operation
  recovery, removal intent, authority checks, and mutation transaction. A
  separate Manager-journal-only marker cannot atomically establish this
  backend state under the current initial S27 allowlist. The
  `RemoveIntegration` entry also performs operation recovery, so it is not an
  interchangeable read-only proof probe.

Status: `ROUTE_REASSESSMENT_REQUIRED / CROSS_BOUNDARY_PROOF_GAP`. No production
or test file was edited, no synthetic or Unity test was run, and no old action
receipt, project runtime, process, or Package state was changed by this task.
No real Remove/Install, commit, push, or publication occurred. S25 Gate C
remains blocked; S26's prior accepted result is unchanged.

Planner/User must decide whether to authorize a materially wider, backend-
owned reconciliation design with a complete quiescence and project-state
proof, or retain the old action as unresolved. Do not weaken the contract to
create a success marker from age, screenshot text, or current status. Any
real process observation and project mutation remain separate human gates.

## Backend-Owned Source Feasibility - 2026-09-29

The user authorized the wider backend-owned design and bounded source-only
feasibility. The admitted S25 child command is `powershell.exe -File` with the
exact Package materializer, `-Action RemoveIntegration`, bound project root,
and confirmation switch; its timeout is 600000 ms. The S25 materializer SHA-256
matches the current source materializer byte-for-byte.

A PowerShell AST call-graph walk from `Invoke-RemoveIntegration` across the
materializer and instance engine reached 113 functions and found zero static
native-process launch calls. The sole dynamic command is
`Publish-InstanceOperation`'s supplied verification callbacks; the two
callbacks in `Invoke-RemoveIntegration` contain no process launch. The
unrelated legacy watcher Stop path does launch a native client, but is not
reachable from this Remove route. The old Remove's mutation-capable execution
is therefore bounded to the direct admitted business child in the reviewed
source, not an unbounded descendant tree.

This establishes a conditional source design path, not a live process result:
the backend can hold its materializer lock, require a complete exact-command
Windows process observation, validate the project state and operation/intent
closure without invoking mutation recovery, then atomically publish a
separate action-bound administrative disposition. Missing command-line
visibility, a live matching process, lock drift, or conflicting state still
blocks. The old command outcome remains unknown. No real OS process census,
Unity, product mutation, synthetic test, or production/test edit occurred.

The task allowlist now includes the directly coupled materializer route,
adapter/actions, and focused fixture tests. Current status:
`CONDITIONAL_SOURCE_FEASIBILITY_PASS / IMPLEMENTATION_PENDING`. Real process
observation and real reconciliation remain separate human-owned gates.

## Source Implementation And Focused Evidence - 2026-09-29

Status: `SOURCE_IMPLEMENTED / FOCUSED_L0_PASS / VERIFIER_PENDING`. The source
gate is not real S25 reconciliation or Unity acceptance.

The materializer now exposes an explicit `ReconcileHistoricalUnknown` action
bound to the exact S25 action/stage, reviewed old writer/materializer hashes,
complete command identity and timeout. It requires explicit confirmation,
holds the project materializer lock, rejects competing stage/terminal evidence,
checks the original writer identity and a complete visible PowerShell process
census, and independently checks `INSTALLED / COMPLETE`, the old `poc.34`
selection, removal-intent and operation absence, and backend removal authority.
Under the Manager index lock it repeats evidence, process and project checks
before append-only publication. The record retains `command_outcome=unknown`,
includes proof provenance/digests, and never invokes Remove or Install.

The Manager journal accepts only this fixed historical action/stage with a
matching schema-2 proof digest and byte-exact admission/claim bindings. A
later terminal, claim drift, wrong writer identity, orphan marker or malformed marker is a
conflict; ordinary pending actions and terminal/pre-effect dispositions keep
their existing behavior. No automatic second owner is admitted by the
reconciliation command itself.

Final source/test files changed, all within the S27 allowlist:

- `Editor/AICodedbManagerActionJournal.cs`
- `Tests/Editor/AICodedbManagerUiTests.cs`
- `Tests~/test-codedb-host-payload-materializer.ps1`
- `Tools~/materialize-codedb-host-payload.ps1`

Frozen HEAD: `1be11d911c05db4b7752122bf761e61fac47ef3c`.
Ordered four-path `git diff --binary --no-ext-diff | git hash-object --stdin`
identity: `4ecb40b44e091652bd57b04b8f67ecd521a2881e`.

Evidence on this source snapshot:

- Final `-HistoricalReconciliationOnly` fixture L0: PASS, exit 0. Synthetic
  cases covered exact envelope admission, conflicting terminal/stage, changed
  Package claim and script bytes, changed command arguments, live/unknown
  writer, live child, unavailable command line, incomplete shell census
  (including a missing coordinator PID),
  changed desired state/selection, competing intent/operation, state drift,
  successful unknown-only publication and repeated-publication refusal.
- PowerShell AST parse for materializer and focused fixture: PASS, 0 errors.
- Four-file scoped `git diff --check`: PASS, exit 0, no output.
- An earlier fixture run failed because the newly authored synthetic publisher
  mock omitted `WriterPid`; the mock was corrected and the final focused run
  passed. No product behavior was changed for that test-harness failure.

The Editor test was added but NOT RUN. C# compile, EditMode, Unity, Unity MCP,
real OS process observation, real S25 reconciliation, Remove, Install, full
regression, commit, push and publication are NOT RUN / DEFERRED. The source
gate did not read or modify the protected S25 receipts or project runtime;
the existing non-S27 dirty worktree was preserved. A real gate can still
fail closed on incomplete process visibility, retained operation directories,
holder ambiguity, missing old Package bytes or any state drift.

Next notification: UnityCodeDB v0.3 Planner/User. Next action: independent
targeted Verifier review of this frozen source snapshot and evidence, subject
to human authorization. Do not run the real reconciliation or a fresh
Remove/Install from this result.

## Planner/User Disposition - 2026-09-30

The independent GUARDED targeted review in
`verifications/VERIFICATION-01.md` passed on frozen HEAD
`1be11d911c05db4b7752122bf761e61fac47ef3c` and ordered four-file patch
identity `4ecb40b44e091652bd57b04b8f67ecd521a2881e`. Findings: none. It
reused the recorded focused L0, PowerShell parse and scoped diff-check without
rerunning tests. The user accepted this S27 source and focused-evidence gate.

This acceptance does not establish the historical command outcome. The old
S25 Remove remains unknown and S25 Gate C remains BLOCKED. The added Editor
test, C# compile, EditMode, Unity, and real S25 process/project proof remain
NOT RUN / DEFERRED. Commit, Package export, real reconciliation, fresh
Remove/Install, push and publication require separate authorization.

## Focused Editor Gate Setup - 2026-09-30

The human confirmed `UnityValidationProject` was closed. For the accepted
S27 source gate's directly affected C# / Editor check, Planner changed only
the `com.rice.ai-codedb` dependency in
`UnityValidationProject/Packages/manifest.json` from the inherited S25
commit-derived artifact to `file:../../com.rice.ai-codedb`. The pre-change
manifest SHA-256 was
`a3fce2719778387ab423a6c17ab18c1c07e27a6109c5a404bf8382a234f7d780`;
the pre-change `packages-lock.json` SHA-256 was
`b0eae1cd7fc1a54fb82b857998cb67fbb547cf7f21cd6e3c2e67129b9bf608c5`.
No other dependency, test, production source, old action evidence, project
runtime, or lockfile was changed by this setup. Unity and the focused Editor
test have not yet run. After the human-owned gate, restore the inherited
manifest binding and verify it against the pre-change hash while Unity is
closed; classify any Unity-produced lockfile change before editing it.

## Focused Editor Test Observation - 2026-09-30

The human reported that the S27-added EditMode test
`AICodedbProjectSettingsTests.ManagerActionJournal_HistoricalUnknownMarkerReleasesOnlyBoundPendingStage`
passed with the validation project source-bound for this gate. This is a
human-reported single-test PASS, not a full EditMode run or live S25 action
proof. The Unity Console's C# error count was not separately reported at this
checkpoint; compile status remains unconfirmed. Whether Unity is closed is
also unconfirmed, so the temporary Package binding has not yet been restored.
No real reconciliation, Remove, Install, old-action replay, commit, Package
export, push, or publication is authorized or claimed by this observation.

## Focused Editor Gate Closure - 2026-09-30

The human separately confirmed zero C# compile errors in that source-bound
Unity session and confirmed `UnityValidationProject` was closed. The single
S27-added EditMode test PASS above is therefore accompanied by a
human-reported zero-error compile observation. No full EditMode suite or real
S25 action test was run or inferred.

With Unity closed, Planner restored the temporary CodeDB Package binding.
`manifest.json` again matches its pre-gate SHA-256
`a3fce2719778387ab423a6c17ab18c1c07e27a6109c5a404bf8382a234f7d780`.
Unity had changed `packages-lock.json` during the source-bound import. Its
pre-gate value was independently identified by matching the recorded SHA-256
against the S26 commit-derived artifact path, then restored byte-for-byte:
`b0eae1cd7fc1a54fb82b857998cb67fbb547cf7f21cd6e3c2e67129b9bf608c5`.
The inherited pre-gate manifest/lockfile paths differ (S25/S26 respectively);
this task preserved that existing state rather than resolving it implicitly.
The ordered S27 four-file patch identity remained
`4ecb40b44e091652bd57b04b8f67ecd521a2881e` after restoration.

Status: `ACCEPTED_SOURCE / FOCUSED_CSHARP_EDITOR_GATE_PASS /
REAL_S25_GATE_BLOCKED`. Next step is a separately authorized scoped commit
and commit-derived Package closure before any human-owned real reconciliation
proof. The old Remove outcome remains unknown. No real reconciliation,
Remove/Install, push, or publication occurred.

## Scoped Commit And Package Authorization - 2026-09-30

The human authorized one S27-scoped commit and one commit-derived local
Package export/closure after the focused C# / Editor gate. The commit scope is
the four frozen S27 source/test paths, the Historical Unknown-Action
Reconciliation Amendment, the v0.3 roadmap checkpoint, and this S27 task
packet (`TASK.md`, `RESULT.md`, `verifications/VERIFICATION-01.md`). Inherited
S25 records, validation-project state, unrelated task/workflow changes, and
prior artifacts remain outside the commit. This authorization does not permit
push, tag, publication, real process/project proof, reconciliation, Remove,
or Install.

Before the scoped commit, Planner normalized only the Verifier report's
presentation: replaced the local absolute repository path with a portable
workspace label and removed Markdown hard-break trailing spaces. Its verdict,
findings, reviewed identity, evidence, and scope boundaries were unchanged.

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

## Scoped Commit And Commit-Derived Package Closure - 2026-09-30

The exact nine-path S27 commit is
`a0cd3d966fa8550930da5576d202f10030498f0a` (`S27 guard historical Manager
action reconciliation`). Before commit, the staged four-file patch identity
matched the Verifier-reviewed
`4ecb40b44e091652bd57b04b8f67ecd521a2881e`; the staged nine-path
`git diff --check` passed with no output. No S25 record, validation-project
file, unrelated task/workflow change, or prior artifact was included.

The canonical exporter produced a new local artifact from that exact commit:

- Root: `.artifacts/v0.3.0-preview.5-s27-reconciliation-a0cd3d9-final/`
- Package: `package/com.rice.ai-codedb` under that root
- ZIP: `com.rice.ai-codedb.zip` under that root
- ZIP SHA-256: `1ba866102e8a7bdc439731c081fb2e37c53284e60a559b5e8acc69ae4fd80b84`
- Commit-staged and exact-ZIP closure: PASS / PASS; `source_count=46`,
  `mismatch_count=0` each
- Export summary: `files=482`, `bytes=9919715`, `zip_entries=482`
- Cross-hashes: generation
  `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`,
  host-current
  `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`,
  runtime contract
  `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`

An independent file hash matched the reported ZIP SHA-256. The four S27
source/test files and Host Action contract in the exported Package each
matched their exact commit blob. Prior artifacts and the restored validation
project bindings were not changed. This artifact is not yet a real S25 Gate C
PASS: old Remove outcome remains unknown, and no real process/project proof,
reconciliation, fresh Remove/Install, Unity import of this artifact, push,
tag, or publication occurred.

Current status: `S27_COMMIT_AND_PACKAGE_CLOSURE_PASS /
S25_REAL_GATE_C_BLOCKED`. Next action requires a separately authorized,
human-owned real proof and validation-project integration plan; any failed
exact-action proof stops without replay or cleanup.

## Real S25 Proof Attempt 01 - 2026-09-30

The separately authorized one-shot real proof was invoked from the exact S27
commit-derived Package against `UnityValidationProject` and the exact
historical action `3049af7cfc9f4260928e3f89d18672c0`, with the required
administrative confirmation. It stopped before project-lock acquisition,
process observation, project-state proof, or marker publication with exit
`1`:

`Project mutation confirmation is valid only for Redeploy, Sync, Remove,
RemoveIntegration, Repair, Reinstall, Uninstall, or Install.`

This is a deterministic contract mismatch in the shipped route: the
`ReconcileHistoricalUnknown` implementation requires
`ConfirmedProjectMutation`, while the top-level argument guard rejects that
same combination. The command therefore could not reach any real proof logic;
no old receipt, runtime state, process, marker, Remove, Install, or project
bytes were changed by this attempt. Removing the confirmation switch would
not be a valid workaround because the reconciliation function rejects an
unconfirmed call. No retry was performed.

Status: `REAL_S25_PROOF_BLOCKED / RECONCILIATION_CONFIRMATION_GUARD_MISMATCH`.
Next action requires a separately authorized same-task FIX to align the
command admission guard and reconciliation confirmation contract, followed by
one new bounded proof attempt. The existing S27 commit and Package remain
immutable; do not replay the old Remove or start a fresh Remove/Install.

## FIX 01 - Reconciliation Confirmation Guard - 2026-09-30

The user authorized the same-task FIX after the pre-observation guard failure.
The top-level materializer admission now includes `ReconcileHistoricalUnknown`
in the actions that accept `-ConfirmedProjectMutation`, matching the explicit
confirmation required by `Invoke-ReconcileHistoricalUnknown`. The normal
mutation actions retain their existing confirmation behavior.

The focused `-HistoricalReconciliationOnly` L0 passed after the correction,
including the new source assertion that the reconciliation action is present
in the confirmation allowlist. Both the materializer and focused fixture
PowerShell AST parses passed, and their scoped `git diff --check` passed. No
real project proof was retried before producing the corrected commit-derived
Package.

Current status: `FIX_01_SOURCE_AND_FOCUSED_L0_PASS /
CORRECTED_PACKAGE_PENDING`. The prior commit and Package remain preserved;
the next real proof must use the corrected artifact once and stop on the first
failure.

## FIX 01 Corrected Package And Real Proof - 2026-09-30

The correction was committed as
`5cb4862ab41a30d7819e036c8da18b8f0bf30783` (`Fix S27 reconciliation
confirmation admission`). The corrected commit-derived Package was exported
and passed both staged and exact-ZIP closure: `source_count=46`,
`mismatch_count=0`, `files=482`, `bytes=9920306`, `zip_entries=482`.
The ZIP is
`.artifacts/v0.3.0-preview.5-s27-reconciliation-fix01-5cb4862-final/com.rice.ai-codedb.zip`
with SHA-256
`8afcf9cfc0879f92d43accd69123713700d17f73fd55be24c38b0842a0700ece`.

Using that exact Package, the single newly authorized real proof attempt for
the historical action `3049af7cfc9f4260928e3f89d18672c0` completed with exit
`0` and emitted:

`[HISTORICAL_ACTION] RECONCILED_UNKNOWN`

The published marker is under the project-key action index, has
`disposition=HistoricalUnknownReconciled`, `command_outcome=unknown`, and
SHA-256
`134fecaf0236a44de95aad99ce2aa33a6931117ee727f3e9e4c1cfe35d876adf`.
The original S25 stage still contains only `admitted.json` and `claim.json`;
no terminal or start-failure file was created. The proof observed the original
writer/command as quiescent and rechecked the project under the materializer
and Manager index locks. The project remains `INSTALLED / COMPLETE`, the
current selection remains `poc.34`, and operation/removal-intent paths remain
absent. No process was stopped and no Remove/Install or old-command replay was
performed.

Status: `REAL_S25_HISTORICAL_RECONCILIATION_PASS /
FRESH_REMOVE_PENDING`. This closes the old unknown-action block only. A fresh
Remove still requires a separate human confirmation and backend preflight;
fresh Install still requires authenticated `UNINSTALLED / PENDING` evidence.

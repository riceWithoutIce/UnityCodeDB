# S25 Result

Status: GATE_A_COMMIT_AUTHORIZED / PACKAGE_EXPORT_PENDING

## Gate A - Read-Only Attribution

Current HEAD remains `5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`.
The user-accepted S24 seven-path source/test identity is
`dd24b129403581169bcd3a286f78faa84f6f2868`. S24's own allowlist and
earlier RESULT checkpoint also include three currently modified, directly
coupled source/test paths omitted from that final identity:

- `com.rice.ai-codedb/Editor/AICodedbActions.cs`: the RemoveIntegration
  action bridge now requires the cached removal preflight and rechecks current
  migration/instance state. Without this diff, the Manager's newly admitted
  historical route can be rejected by the older action gate.
- `com.rice.ai-codedb/Editor/AICodedbControlContract.cs`: the partial-v1
  classifier validates the activation/journal against their own historical
  runtime hash, independently of the later Supervisor failure. This is part
  of the S24 predecessor path proved in focused PowerShell evidence.
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`: adjacent
  C# assertions cover the distinct historical and later runtime hashes and
  reject activation/journal mismatch; these assertions have not run in Unity.

The ordered ten-path tracked source/test diff (the accepted seven plus those
three paths) hashes to `57a6b80ecf77b9029e6da1de382ccd935c8ef2e8` with
`git diff --binary -- <ten exact paths> | git hash-object --stdin`. Ten-path
scoped `git diff --check` passed, exit 0, no output. This is a candidate
identity only, not a retroactive S24 acceptance or commit authorization.

The worktree has other dirty documentation, task, artifact and validation
project state. The validation project still references the prior S23 local
Package. No staging, commit, Package export, manifest edit, Unity/EditMode,
Unity MCP, real removal, fresh Install, Provider operation, process stop,
push, tag, publication, or test rerun occurred in this Gate A review.

## Initial Gate A Decision (Superseded By Reconciliation Below)

Keep this as one S25 outcome. First authorize a bounded reconciliation of
the three omitted direct paths into a single, attributable source closure,
including targeted review of their interaction with the accepted seven-path
S24 snapshot. Only then freeze the exact commit plan; commit, export, Unity,
and real project mutations remain later independent gates. If those three
paths cannot be admitted without unrelated bytes, stop for route
reassessment rather than packaging the dirty worktree.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: BLOCKED / SOURCE_CLOSURE_IDENTITY_REVIEW_REQUIRED
Next notification: UnityCodeDB v0.3 Planner/User
Next action: decide whether to reconcile and review the ten-path source/test
candidate before any commit or artifact operation.
At this checkpoint, human authorization was required for source closure
expansion and targeted review. That authorization and its result are recorded
below; exact commit, export, validation-project maintenance, Unity/EditMode,
real removal/Install, push and publication remain separate gates.

## Gate A - Authorized Ten-Path Reconciliation

The user authorized reconciliation of the three omitted direct paths within
the same S25 task. HEAD remains `5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`.
The ordered ten-path tracked source/test diff remains
`57a6b80ecf77b9029e6da1de382ccd935c8ef2e8`.

Targeted source review found only S24-coupled changes in the three added
paths. `AICodedbActions.cs` consumes the cached `RemovalPreflightPassed`
admission published by the worker and rechecks the current migration and
instance state before invoking the Package removal action. The Manager's
historical route already requires the corresponding cached preflight;
omitting the action-bridge diff would leave its older `RequiresReinstall` and
prerequisite gates in conflict with that route.
`AICodedbControlContract.cs` checks activation and journal against the same
historical activation runtime hash while separately authenticating the later
failed Supervisor operation. `AICodedbEditorLifecycleTests.cs` adds adjacent
assertions for distinct historical/later hashes and activation/journal
mismatch. The three diffs contain no unrelated hunks. No additional changed
S24 source/test path was identified outside these ten; the eleventh S24
allowlisted package-boundary test path is clean.

Ten-path scoped `git diff --check`: PASS, exit 0, no output. The S25 task
record and roadmap contain no machine-specific absolute paths; roadmap
scoped `git diff --check`: PASS, exit 0. This is a Planner source-attribution
review, not a rerun of L0, an independent Verifier acceptance of the expanded
identity, C# compile, EditMode, or real Unity integration evidence. The S24
seven-path GUARDED PASS remains scoped to its original frozen identity.

Source closure is reconciled for exact commit planning only. The existing
dirty worktree must not be staged wholesale. No production/test bytes,
validation-project files, artifacts, or runtime state were changed during
this review; no commit, Package export, Unity/Unity MCP, test, real removal,
fresh Install, push, tag, or publication occurred.

The proposed exact commit scope is 19 paths: the ten source/test paths in the
candidate identity; S24 `TASK.md`, `RESULT.md`, and both bounded verification
reports; S25 `TASK.md` and `RESULT.md`; and the project-integration reinstall
contract, historical control-contract migration note, and v0.3 roadmap under
`com.rice.ai-codedb/Documentation~/`. The latter three document this same
preview recovery route. This is a planning list, not authorization to stage
or commit. S18/S22/S23 records, `.ai/README.md`, `UnityValidationProject/**`,
and `.artifacts/**` are excluded and must retain their current state.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_A_SOURCE_CLOSURE_RECONCILED / COMMIT_SCOPE_PENDING
Next notification: UnityCodeDB v0.3 Planner/User
Next action: review and authorize an exact ten-path source/test plus task-record
commit scope before staging. Package export is a later separate gate.
Human decision or authorization required: exact commit scope, then local
Package export, validation-project maintenance, Unity/EditMode, real
removal/Install, Verifier routing, push, and publication.

## Gate A - Exact Commit Authorization

The user authorized the exact 19-path commit scope above. This authorization
does not authorize Package export, validation-project edits, Unity/EditMode,
real project removal/fresh Install, Verifier routing, push, tag, or
publication. The source/test identity remains the ten-path candidate, not
the previously accepted seven-path S24 identity.

Current status: GATE_A_COMMIT_AUTHORIZED / PACKAGE_EXPORT_PENDING
Next notification: UnityCodeDB v0.3 Planner/User
Next action: commit only the authorized 19 paths and report the resulting
commit identity; then request separate authorization for local Package export.

## Gate A - Commit Result

The exact 19-path scope was committed as
`6fb4566928e813b847dd2a4313306f49a17e6a41` on
`codex/v0.3.0-legacy-workflow`. Before commit, the staged path list contained
exactly the authorized 19 files, staged ten-path binary diff identity matched
`57a6b80ecf77b9029e6da1de382ccd935c8ef2e8`, and staged
`git diff --check` passed with exit 0 and no output. Post-commit `git show`
listed exactly those 19 paths. Inherited S18/S22/S23, validation-project,
and artifact changes remained outside the commit. This post-commit evidence
append itself is not included in the commit.

Current status: GATE_A_COMMITTED / PACKAGE_EXPORT_PENDING
Next notification: UnityCodeDB v0.3 Planner/User
Next action: decide whether to authorize one commit-derived local Package
export and its full Package Identity Authority/Release Closure checks.
Human decision or authorization required: Package export; later validation-
project maintenance, Unity/EditMode, real removal/fresh Install, Verifier
routing, push, tag, and publication.

## Gate A - Commit-Derived Package Closure

The user separately authorized one local Package export from commit
`6fb4566928e813b847dd2a4313306f49a17e6a41`. The canonical exporter
created a new artifact without replacing S23:

- Relative root: `.artifacts/v0.3.0-preview.5-s25-reinstall-6fb4566-final/`.
- Package directory: `package/com.rice.ai-codedb/` under that root.
- ZIP: `com.rice.ai-codedb.zip` under that root.
- ZIP SHA-256: `9f7c4e7867ca157d5f957f6d114d6396bb8b5f655bb7ca0ca2b3b07675e5cb47`;
  independent readback matched.
- Exactly one extracted `com.rice.ai-codedb` root, 480 files, 9,778,434 bytes,
  and 480 ZIP entries. Extracted `package.json` declares
  `com.rice.ai-codedb@0.3.0-preview.5` and Unity compatibility `2022.3`.
- Commit-staged and exact-ZIP Package closure: PASS, each `source_count=46`,
  `mismatch_count=0`. Shared generation manifest SHA-256:
  `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`;
  host-current SHA-256:
  `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`;
  runtime-contract SHA-256:
  `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`.
- Full-tree byte comparison between the exporter package directory and exact
  ZIP extraction: PASS, `git diff --no-index --quiet` exit 0.

The closure validator checked every declared payload source hash, generation
file/hash, host-current pointer and generation binding, runtime contract
identity, and exact payload source enumeration. No metadata repair flag,
version/generation rewrite, manual hash edit, or in-place artifact patch was
used. The S23 artifact and inherited dirty worktree were preserved. No
validation-project manifest edit, Unity/Unity MCP, C# compile/EditMode, real
removal/fresh Install, Provider/external process action, push, tag, or
publication occurred. This artifact's byte closure does not establish C#
semantic compilation or the human golden path.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_A_PACKAGE_CLOSURE_PASS / GATE_B_AUTHORIZATION_PENDING
Next notification: UnityCodeDB v0.3 Planner/User
Next action: separately authorize validation-project manifest maintenance and
human-owned Unity compile/focused EditMode against this exact artifact.
Human decision or authorization required: Gate B, then real project
removal/fresh Install, Verifier routing, push, tag, and publication.

## Gate B - Package Reference Prepared For Human Unity

The user authorized Gate B and confirmed `UnityValidationProject` was closed
before project maintenance. The existing CodeDB dependency pointed to the
S23 local Package. Only that value in
`UnityValidationProject/Packages/manifest.json` was switched to
`file:../../.artifacts/v0.3.0-preview.5-s25-reinstall-6fb4566-final/package/com.rice.ai-codedb`.
Other dependencies and `testables` were preserved; the previously dirty
`packages-lock.json` and ProjectSettings were not edited by this checkpoint.
The manifest parses as JSON, the relative target resolves to the extracted
single-root Package, and that target declares
`com.rice.ai-codedb@0.3.0-preview.5` / Unity `2022.3`. Manifest scoped
`git diff --check`: PASS, exit 0, no output. Artifact ZIP SHA-256 still
matches Gate A.

The bounded human Unity request is frozen before opening:

- Project: repository-relative `UnityValidationProject/`, resolved from the
  repository root by the human; declared Editor line: `2022.3.47f1`.
- Human opens the existing project visibly. Allow at most 600 seconds for
  Package import and C# compilation to settle. Require zero CodeDB C# errors;
  stop on the first product compile failure without attempting EditMode.
- If compile passes, use Unity Test Runner **EditMode** in that same visible
  session. Selection 1: the full
  `Rice.AI.Codedb.Editor.Tests.AICodedbLifecycleControlTests` class.
  Selection 2: the single
  `Rice.AI.Codedb.Editor.Tests.AICodedbEditorLifecycleTests.ControlContractMigration_PartialV1RequiresBoundCommittedEvidence`
  test. One run per selection, no automatic retry, maximum 300 seconds per
  selection. Stop at the first failure and preserve its exact text.
- The human owns normal Unity close/cleanup after recording results. Agents
  do not launch, hide, batch, or terminate Unity; Unity MCP is not a
  substitute. Gate C real removal/fresh Install remains separately confirmed
  after Gate B results, not part of these test clicks.

No Unity process or Test Runner was operated in this preparation checkpoint.
No C# compile or EditMode result is claimed yet. No real removal/Install,
Provider/external action, commit, push, tag, or publication occurred.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_B_PACKAGE_REFERENCE_PREPARED / HUMAN_COMPILE_PENDING
Next notification: human operator
Next action: visibly open `UnityValidationProject` and report CodeDB C#
compile result before any Manager or project mutation. If zero errors, run
the two frozen EditMode selections and report their individual results.
Human decision or authorization required: human Unity execution; later Gate C
removal/fresh Install, Verifier routing, push, tag, and publication.

## Gate B - First Unity Compile Blocker

The human opened the validation project with the S25 commit-derived Package.
Unity entered Safe Mode and the screenshot showed 7 CodeDB compile errors and
3 warnings. The first error is `CS0019` in
`Editor/AICodedbManagerWindow.cs:1326`: operator `!=` cannot compare
`AICodedbProductStatus` with `null`. Further errors in the same file occur
around lines 2094, 2105, 2112, 2114, and 2129, including `CS0173` and
`CS0037` from conditional/null returns. This is a product compile blocker;
the warning lines are not the gate failure.

Bounded read-only source inspection confirms `AICodedbProductStatus` is an
`internal readonly struct` in `Editor/AICodedbHostPayloadMaterializer.cs`.
The new Manager removal presentation and admission methods instead use
reference-type null checks and return paths. The offending Manager source
matches the exported Package file byte-for-byte, so this is a committed
source defect, not ZIP/extraction drift. Gate A Package byte closure remains
valid but did not prove C# semantic compilation.

Stop condition applied at compile. The two planned focused EditMode
selections were not run. Manager actions, project integration removal, fresh
Install, Unity MCP, Provider/external actions, process termination, source
correction, artifact modification, retry, commit, push, tag, and publication
were not performed in response. Preserve the failed S25 artifact and
validation-project state as evidence; do not patch the artifact in place.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: BLOCKED / GATE_B_CODEDB_CS_COMPILE
Next notification: UnityCodeDB v0.3 Planner/User
Next action: human closes the Unity project normally. Then decide whether to
authorize one bounded Manager value-type/nullability source correction,
focused source checks, a new exact commit-derived Package, and one human
compile retry. Do not enter EditMode or Gate C until compilation passes.
Human decision or authorization required: source fix/new commit/export and
human retry; later real removal/fresh Install, Verifier routing, push, tag,
and publication.

Human subsequently confirmed `UnityValidationProject` was closed normally.
No agent process termination or runtime probe was used. The failed Package,
validation-project reference, and source remain unchanged; the next gate is
the separate source-fix authorization described above.

## FIX 01 - Manager Value-Type Compile Correction

The user authorized one continuous correction, exact source/evidence commit,
new commit-derived Package export, manifest switch while Unity is closed,
and one later human compile retry. The original failed artifact is preserved.
The correction changes only `Editor/AICodedbManagerWindow.cs` and its
adjacent `Tests/Editor/AICodedbManagerUiTests.cs`:

- The Manager treats absent presentation status as
  `default(AICodedbProductStatus)`, matching the existing value-type
  convention, rather than comparing or returning the readonly struct as
  `null`.
- Removal predicates and cached/displayed selection no longer apply
  reference-type null checks to `AICodedbProductStatus`. A focused Editor
  test asserts the default status never offers project mutation.

Frozen base HEAD: `6fb4566928e813b847dd2a4313306f49a17e6a41`.
Two-file binary diff identity:
`e6f96097c8f512559392ee26bc3cb19e7e950b18`.
Two-file `git diff --check`: PASS, exit 0. Clean Roslyn syntax parse of both
files: PASS, 0 errors. An earlier command attempted to load an incompatible
SDK Roslyn DLL and printed a misleading PASS after non-terminating load
errors; that invocation is discarded and not evidence. The clean run used
the already available Roslyn type with terminating errors enabled.

No Unity C# semantic compilation, EditMode, Manager action, real removal,
fresh Install, or runtime probe was run after the correction. The old Package
was not edited. This source/static evidence does not close Gate B; only the
new Package's human Unity import can classify that result.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: FIX_01_SOURCE_READY / COMMIT_EXPORT_PENDING
Next notification: UnityCodeDB v0.3 Planner/User
Next action: exact four-path source/test plus S25-record commit, then one new
local Package export and closure check. Switch only the CodeDB dependency
after the new artifact passes and Unity remains closed.
Human decision or authorization required: human Unity compile/EditMode after
the new artifact; later Gate C real removal/fresh Install, Verifier routing,
push, tag, and publication.

## FIX 01 - New Package Prepared For One Human Retry

The exact four-path source/test plus S25-record commit is
`81d9f6bec26512d1b9cee19685a7e53fad8941b8`, parent
`6fb4566928e813b847dd2a4313306f49a17e6a41`. Staged source/test
identity matched `e6f96097c8f512559392ee26bc3cb19e7e950b18`; staged
`git diff --check` passed, and the commit contains only those four paths.

One new commit-derived artifact was exported at the repository-relative root
`.artifacts/v0.3.0-preview.5-s25-manager-valuetype-81d9f6b-final/`.
Its ZIP SHA-256 is
`cd8f72fe71a4854bc7ad84f15f951f7f3b5c35096c208fe7916c9ed95c40ed53`
and independent readback matched. Commit-staged and exact-ZIP closure both
passed with `source_count=46`, `mismatch_count=0`, one Package root, 480 files,
9,778,753 bytes and 480 ZIP entries. Generation, host-current and runtime
contract hashes remained the Gate A values. Full-tree package-versus-ZIP
byte comparison passed, as did a direct comparison of the corrected Manager
source with the extracted Package file. The original failed S25 artifact was
not changed or replaced.

While the human-confirmed Unity project remained closed, only the CodeDB
value in `UnityValidationProject/Packages/manifest.json` was switched to
`file:../../.artifacts/v0.3.0-preview.5-s25-manager-valuetype-81d9f6b-final/package/com.rice.ai-codedb`.
The manifest parses as JSON, that relative target resolves, its Package
identity is `com.rice.ai-codedb@0.3.0-preview.5`, and scoped
`git diff --check` passed. Other dependencies, `testables`, and inherited
dirty lockfile/ProjectSettings state were preserved.

The bounded human compile retry budget is 0/1 used. Unity, Unity MCP, C#
semantic compile, focused EditMode, Manager operation, real project
removal/fresh Install, Provider/external action, push, tag and publication
remain NOT RUN on this new artifact. The two EditMode selections and wait
ceilings frozen in the preceding Gate B record apply only after zero CodeDB
compile errors; stop at the first new failure.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: FIX_01_PACKAGE_READY / HUMAN_COMPILE_RETRY_PENDING
Next notification: human operator
Next action: visibly open `UnityValidationProject`, allow import/compilation,
report zero/nonzero CodeDB C# errors; if zero, run the two focused EditMode
selections once each and report individual results in the same session.
Human decision or authorization required: human Unity retry; later Gate C
real removal/fresh Install, Verifier routing, push, tag and publication.

## Gate B - Human Compile And Focused EditMode Retry

The human visibly reopened `UnityValidationProject` against the FIX 01 local
Package and reported that compilation completed with no errors. In the same
session, the human ran the frozen EditMode selections and reported both PASS:

- `AICodedbLifecycleControlTests` entire class: PASS, one run.
- `ControlContractMigration_PartialV1RequiresBoundCommittedEvidence` single
  test: PASS, one run.

The corrected Package reference in the project manifest and ZIP SHA-256 were
read back after this report and still match FIX 01. The human compile retry
budget is 1/1 used; each focused EditMode selection used one attempt, with no
reported retry. This is human-observed evidence, not an exported test report
or independent Verifier run. Warning count was not classified. No Manager
state, read-only removal preflight, real removal/fresh Install, Unity MCP,
Provider/external action, Play/Edit lifecycle, full regression, push, tag or
publication is inferred from this Gate B result.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_B_HUMAN_PASS / GATE_C_READ_ONLY_PREFLIGHT_PENDING
Next notification: human operator / UnityCodeDB v0.3 Planner
Next action: keep the same Unity session open; observe the settled CodeDB
Manager state and read-only removal admission without clicking a mutation
action. Stop on a blocked or ambiguous result. Seek separate explicit human
confirmation before any real project integration removal, and again before
fresh Install.
Human decision or authorization required: Gate C real removal/fresh Install,
Verifier routing, push, tag and publication.

## Gate C - Visible Read-Only Removal Admission

The human supplied a screenshot from the same Unity session after Manager
settled. Overview showed `UnityValidationProject - Needs attention` under
Package `v0.3.0-preview.5`, with the explicit
`Remove CodeDB Integration` action. Its banner stated:
`This integration cannot run under the current Package. Its removal authority is verified; uninstall the project integration, then install it fresh.`
Diagnostics showed the obsolete Owner Identity control state as
`Removal required`; Host payload/current instance and other runtime rows
were `Not evaluated` or inactive. No ongoing `Checking` was visible.

Targeted source review confirms this exact verified-removal banner is
conditional on `IsRemoveIntegrationMenuAvailable`, which requires
`RequiresReinstall` and cached `RemovalPreflightPassed`. The lifecycle worker
populates that flag from the read-only `RemoveIntegrationPreflight` action;
admission requires a successful result with exactly one
`[REMOVAL_PREFLIGHT] AVAILABLE` marker. Thus the screenshot proves visible
cached preflight admission at observation time, not a completed project
mutation or the locked authority recheck that occurs after a click.

Read-only Gate C observation: PASS. Real removal attempt budget remains 0/1;
fresh Install remains 0/1. No Manager mutation button or confirmation dialog
was clicked, and no process, runtime, MCP registration or project file was
intentionally changed by this observation. Keep the current Unity session
open. A separately confirmed human removal action may be attempted once;
allow at most 300 seconds for a terminal result, with no automatic retry.
The human owns normal Unity close/cleanup. Stop at the first blocked or
ambiguous result and preserve exact output; do not click Install until a
visible `Uninstalled` result and separate technical `UNINSTALLED / PENDING`
evidence are reviewed.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_C_VISIBLE_PREFLIGHT_PASS / REMOVAL_CONFIRMATION_PENDING
Next notification: human operator / UnityCodeDB v0.3 Planner
Next action: obtain explicit confirmation for one click of
`Remove CodeDB Integration` and its project-mutation confirmation dialog.
Human decision or authorization required: real removal; fresh Install only
after removal evidence; later Verifier routing, push, tag and publication.

## Gate C - One Real Removal Authorized

The human explicitly authorized one real `Remove CodeDB Integration` action
and its project-mutation confirmation in the currently open
`UnityValidationProject`. The human operates the visible Unity UI. This
authorization covers one attempt only, with a maximum 300-second wait for a
terminal result and no automatic retry. Stop at the first failure, timeout,
or ambiguous state and preserve the visible output. Do not click `Install
CodeDB`, manually delete runtime files, use Unity MCP or alternate probes, or
terminate Unity. The human owns normal Unity close/cleanup.

At this record point, the real removal action has not yet been reported as
clicked. Its attempt budget remains 0/1 used; visible `Uninstalled` and
independent `UNINSTALLED / PENDING` technical evidence remain unproved. Fresh
Install still requires separate authorization after those results are
reviewed. No release acceptance is inferred from this authorization.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_C_REAL_REMOVAL_AUTHORIZED / HUMAN_ACTION_PENDING
Next notification: human operator
Next action: perform the single visible removal and confirmation, then report
the terminal Manager state and exact error or output if it does not succeed.
Human decision or authorization required: fresh Install only after proven
removal; later Verifier routing, push, tag and publication.

## Gate C - Real Removal Outcome Unconfirmed

After the authorized removal attempt, the human supplied a 1606x945 Manager
screenshot (SHA-256
`23bf7c0fb92a399abe1e68593dc3f5082e0dda7ecef99829ba26a81261f30bd6`).
The visible toast states `Remove CodeDB Integration outcome is unconfirmed
after a Manager or Editor boundary.` The header says `CodeDB status
unconfirmed`; the activity area says `Outcome unconfirmed` and `The direct
command has admitted or claimed evidence but no matching terminal receipt;
no replay was attempted.` Host payload shows `Error / Check Failed`, current
instance `Needs Setup / Removal required`, host generation `Error / Invalid`,
and project MCP config `Needs Setup / Missing`. The screenshot does not show
`Uninstalled` or an independent `UNINSTALLED / PENDING` technical result.

Targeted source review of `AICodedbProcessRunner.RecoverManagerAction` confirms
that the displayed detail is the `Pending` outcome when a direct-command
stage exists without a matching terminal receipt. The Manager header is an
action-status override, not proof of final product state. The screenshot
therefore cannot distinguish a completed mutation with lost confirmation from
an unfinished or failed mutation. No replay or retry is authorized.

The single real removal attempt is 1/1 used, with terminal outcome
UNCONFIRMED. Fresh Install remains 0/1 and BLOCKED. This gate stops without
Unity MCP, runtime-file inspection, manual cleanup, process termination,
source changes, or another Manager action. Preserve the current visible state
and seek a separately scoped, read-only receipt/state diagnosis before any
retry, Install, or release claim. The human owns normal Unity close/cleanup.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: BLOCKED / GATE_C_REMOVAL_OUTCOME_UNCONFIRMED
Next notification: UnityCodeDB v0.3 Planner/User
Next action: decide whether to authorize a bounded read-only diagnosis of
the missing terminal receipt and post-attempt product state.
Human decision or authorization required: diagnosis scope; any further
removal or fresh Install; Verifier routing, push, tag and publication.

## FIX 02 - Durable Receipt Physical Path Correction

The bounded read-only diagnosis identified the single-cause failure: the
Manager action admission temporary file was attempted under a 335-character
physical Windows path, and the stage directory was created without
`admitted.json`. The writer therefore never started. The project control state
remained `INSTALLED / COMPLETE`; no removal intent or terminal uninstall
evidence existed.

The authorized correction changes only the physical receipt directory
components. `AICodedbPaths.GetManagerActionReceiptRoot` now uses the first 24
lower-hex characters of each full project and Package SHA-256 key for the
physical directories. `invoke-codedb-manager-action.ps1` applies the same
derived components when validating the admitted path. The full 64-character
project/package keys, roots, action id, and stage id remain in the admission,
claim, and terminal documents and continue to be validated; a path collision
therefore remains fail-closed rather than authorizing a different identity.
The stage id and action id remain full-length values.

The package-boundary fixture was updated to use the same physical layout. The
focused `ManagerActionWriterOnly` batch passed success, timeout, and
identity-rejected scenarios with exit 0. PowerShell AST parsing passed, and
scoped `git diff --check` passed for the three changed source/test paths. The
user-reported failing path recalculates from 335 to 255 characters under the
new layout.

Changed paths in this correction are limited to:

- `com.rice.ai-codedb/Editor/AICodedbPaths.cs`
- `com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`

No Unity project, runtime state, old receipt directory, or existing dirty
source was changed. Unity/C# compile, EditMode, Package export, fresh Package
import, real removal retry, fresh Install, Verifier review, commit, push, and
publication remain NOT RUN. The prior single real removal attempt remains
consumed and unconfirmed; no automatic replay was performed.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: FIX_02_SOURCE_COMPLETE / PACKAGE_REBUILD_PENDING
Next notification: UnityCodeDB v0.3 Planner/User
Next action: review this bounded correction and decide whether to authorize a
new attributable Package export and human compile/import gate. Do not retry
the old Package's removal action and do not click Install.
Human decision or authorization required: new Package export/import, any
future removal attempt, fresh Install, Verifier routing, commit, push, and
publication.

## FIX 02 - Attributable Package Export Ready

The user authorized completion of the pre-human-validation preparation. The
three-path correction and this S25 record were committed as
`6942c624f2469bce1a4d681e3396f7528f7f7f35`. No unrelated dirty path was
staged. The canonical exporter produced a new relative artifact without
replacing prior S25/S23 artifacts:

- Relative root: `.artifacts/v0.3.0-preview.5-s25-receipt-path-6942c62-final/`.
- Package directory: `package/com.rice.ai-codedb/` under that root.
- ZIP: `com.rice.ai-codedb.zip` under that root.
- ZIP SHA-256: `ff4aa561b247cb2b62bee5f71782afbb82b5d0e6e0256b6d21846c951117ecce`.
- Staged and exact-ZIP closure: PASS, each `source_count=46`,
  `mismatch_count=0`; 480 files and 480 ZIP entries; 9,780,408 bytes.
- Generation, host-current, and runtime-contract hashes match the accepted
  S25 Gate A values.

The new Package contains the bounded receipt-path correction and is ready for
the human validation-project import gate. `UnityValidationProject` has not
yet been switched to this artifact. Unity/C# compile, EditMode, real removal
retry, fresh Install, Verifier review, push, tag, and publication remain NOT
RUN. The old Package's unconfirmed removal attempt remains consumed; no replay
was performed.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: FIX_02_PACKAGE_READY / MANIFEST_SWITCH_PENDING
Next notification: human operator / UnityCodeDB v0.3 Planner
Next action: while Unity is visibly closed, switch only the CodeDB dependency
in `UnityValidationProject/Packages/manifest.json` to the new relative
Package path, preserve all other manifest/lockfile/project state, then have
the human open the project for compile and focused EditMode validation.
Human decision or authorization required: manifest switch while Unity is
closed; human compile/EditMode; later real removal, fresh Install, Verifier,
commit/publication gates.

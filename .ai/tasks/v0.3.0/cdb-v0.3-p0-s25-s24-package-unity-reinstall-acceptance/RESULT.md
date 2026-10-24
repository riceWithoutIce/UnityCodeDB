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

## FIX 02 - Validation Project Package Reference Prepared

The human confirmed `UnityValidationProject` was closed before maintenance.
Only the CodeDB dependency value in
`UnityValidationProject/Packages/manifest.json` was changed to
`file:../../.artifacts/v0.3.0-preview.5-s25-receipt-path-6942c62-final/package/com.rice.ai-codedb`.
The previous S25 artifact was preserved. Other dependencies, `testables`,
the inherited dirty lockfile, and ProjectSettings were not edited by this
checkpoint.
The manifest parsed as JSON; the relative Package target resolved and
declared `com.rice.ai-codedb@0.3.0-preview.5` with Unity `2022.3`.
The artifact ZIP hash independently matched the FIX 02 export record, and
scoped `git diff --check` passed with no output.

This prepares the human-owned Unity import and compile gate; it does not
establish C# compilation or a successful removal. The old Package's real
removal attempt remains unconfirmed and consumed. No Manager action, Unity
MCP, retry, or fresh Install was performed here.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: FIX_02_MANIFEST_READY / HUMAN_UNITY_GATE_PENDING
Next notification: human operator
Next action: visibly open `UnityValidationProject`, allow Package import and
compilation to settle, then report CodeDB C# errors before any Manager action.
Human decision or authorization required: later real removal retry and fresh
Install, Verifier, push, tag, and publication.

## FIX 02 - Human Import Observation: Unity Scheduler Error

After the validation project was opened against the new Package, the human
reported one Unity Console error: `On demand scheduler protocol error`.
Read-only inspection of the project `Editor.log` found that the Package
compiled successfully; the only compiler diagnostics were three existing C#
warnings (`CS4014` twice and `CS0414` once), with no CodeDB C# error. The log
contains CodeDB `scripts_reloaded`, `reconcile_completed`, and
`manager_closed` evidence; each reports `main_thread_violation_count=0` and
`manager_status_refresh_failed_count=0`.

The scheduler message occurs in Unity's own Asset Pipeline sequence around
`OnDemandSchedulerStart`, `TrimDiskCacheJob`, and `RefreshV2`. No repository
source contains this message or an OnDemand scheduler call, so this observation
does not identify a receipt-path or CodeDB Package failure. It is recorded as
an external Unity Editor/Asset Pipeline diagnostic, not as C# compile success
for the focused tests and not as a release PASS. No source, project settings,
runtime state, Manager action, or test selection was changed in response.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: FIX_02_HUMAN_IMPORT_EXTERNAL_SCHEDULER_DIAGNOSTIC /
FOCUSED_TEST_GATE_PAUSED
Next notification: human operator / UnityCodeDB v0.3 Planner
Next action: if the Console error repeats or blocks Test Runner, capture its
expanded Unity stack and stop; otherwise the human may run the two predeclared
focused EditMode selections once each. Do not click Remove or Install until
the focused test result and Manager state are separately recorded.
Human decision or authorization required: focused EditMode gate and later
real removal retry; fresh Install, Verifier, push, tag, and publication remain
separate.

## FIX 02 - Human Focused EditMode Result

In the same visible Unity session, after the new Package import, the human
reported both predeclared EditMode selections passed with no additional
error:

- `AICodedbLifecycleControlTests` entire class: PASS, one run.
- `ControlContractMigration_PartialV1RequiresBoundCommittedEvidence` single
  test: PASS, one run.

This is human-observed evidence for the exact local Package and is not an
independent Verifier run. The earlier Unity Asset Pipeline scheduler message
remains recorded as an external diagnostic; no new CodeDB C# error was
reported. No Manager mutation, removal retry, fresh Install, Unity MCP,
source change, or runtime cleanup was performed.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_B_HUMAN_PASS / GATE_C_READ_ONLY_PREFLIGHT_PENDING
Next notification: human operator / UnityCodeDB v0.3 Planner
Next action: observe the settled CodeDB Manager state and read-only removal
admission only. Stop on a blocked or ambiguous state; do not click Remove or
Install without separate authorization.
Human decision or authorization required: real removal retry, fresh Install,
Verifier routing, push, tag, and publication.

## Gate C - Read-Only Removal Admission Reconfirmed

The human supplied a 1585x966 screenshot from the same Unity session
(SHA-256
`4a187535732551ea6c1586cd5b2bc9a20bc903cdb8fb679862ca1de0113156a8`).
Manager Overview shows `CodeDB needs attention` and the verified
`Remove CodeDB Integration` action. Diagnostics show `Control contract
migration` as `Needs Setup / Removal required`; current instance and the
other runtime checks are `Inactive / Not evaluated`, with no active Checking
state or terminal uninstall result visible. This confirms only the cached,
read-only removal admission for the current Package. It does not prove that a
mutation was executed or that the project is `UNINSTALLED / PENDING`.

No button was clicked and no Manager action, runtime cleanup, Unity MCP, or
fresh Install was performed. The previous real-removal attempt remains
consumed and unconfirmed.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_C_READ_ONLY_PREFLIGHT_PASS / REAL_REMOVAL_RETRY_PENDING
Next notification: UnityCodeDB v0.3 Planner/User
Next action: decide separately whether to authorize one new real removal
attempt against this corrected Package; do not click Install before an
independent `UNINSTALLED / PENDING` result is proved.
Human decision or authorization required: real removal retry, fresh Install,
Verifier routing, push, tag, and publication.

## Gate C - Corrected Package Real Removal Authorized

The human separately authorized one new real `Remove CodeDB Integration`
attempt after the FIX 02 Package import, focused EditMode PASS, and visible
read-only removal admission. `UnityValidationProject/Packages/manifest.json`
still points to the relative
`.artifacts/v0.3.0-preview.5-s25-receipt-path-6942c62-final/package/com.rice.ai-codedb`
artifact. The earlier attempt against the previous Package remains consumed
and unconfirmed; it is not replayed.

The human operates the visible Unity Manager and confirms the project mutation
dialog once. This authorization permits one attempt only, with up to 300
seconds for a terminal result and no automatic retry. Stop on failure,
timeout, or ambiguity and retain the exact visible output. Do not click
`Install CodeDB`, run Unity MCP, manually edit project runtime state, or stop
holder/external processes. A visible `Uninstalled` result and independent
`UNINSTALLED / PENDING` technical state must be reviewed before any separate
fresh Install authorization.

At this record point, the corrected-Package removal attempt has not been
reported as executed (0/1); fresh Install remains 0/1. No release PASS is
inferred from this authorization.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: GATE_C_CORRECTED_REMOVAL_AUTHORIZED / HUMAN_ACTION_PENDING
Next notification: human operator
Next action: click `Remove CodeDB Integration` once, confirm once, and report
the terminal Manager state or exact error; do not proceed to Install.
Human decision or authorization required: fresh Install after proven removal,
Verifier routing, push, tag, and publication.

## Gate C - Corrected Package Removal Outcome Unconfirmed

The human supplied a 1597x969 Manager screenshot after the one authorized
corrected-Package removal attempt (SHA-256
`eb341b1ce92274b2d69ff2b0306942ce4e0df61da24cd3b6f55dc93ad4bc80bc`).
Manager reports `CodeDB status unconfirmed` and `Outcome unconfirmed`:
`The direct command has admitted or claimed evidence but no matching terminal
receipt; no replay was attempted.` The Host payload detail visibly contains
only a truncated, corrupted `Add-Type` error fragment.

Read-only inspection of the current project/Package receipt partition found
one action and one stage with `admitted.json` and `claim.json`, but no
`terminal.json`. The admission binds a confirmed project mutation to the
Package materializer; the writer claim was published. In the Package writer,
the `Add-Type` construction of the bounded child runner occurs after the claim
and before starting the child command or publishing a terminal receipt. This
places the observed failure within that handoff interval, but the exact
`Add-Type` cause is not established by the screenshot alone.

The project control state remains `INSTALLED / COMPLETE`, the previous current
selection remains present, and no removal-intent directory exists. Project
MCP config is absent, which alone is not evidence of logical uninstall. No
`UNINSTALLED / PENDING` result was proved. The corrected-Package attempt is
1/1 used and its outcome is UNCONFIRMED; fresh Install remains 0/1 and is
BLOCKED. No replay, new action, Unity MCP, runtime modification, or process
termination was performed by this inspection.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: BLOCKED / GATE_C_WRITER_CLAIM_WITHOUT_TERMINAL
Next notification: human operator / UnityCodeDB v0.3 Planner
Next action: obtain the complete Host payload `Copy` detail, preserving the
exception type and `Add-Type` diagnostics while redacting local path prefixes.
Then decide a bounded cause-specific fix; do not retry Remove or click Install.
Human decision or authorization required: any fix/new Package, removal retry,
fresh Install, Verifier routing, push, tag, and publication.

## Gate A - S26 Commit-Derived Package Closure

The user authorized the S25 route update and one commit-derived Package
closure after accepting S26. The canonical exporter ran against exact commit
`1be11d911c05db4b7752122bf761e61fac47ef3c` and created a new artifact without
replacing any prior S23/S25 artifact:

- Relative root:
  `.artifacts/v0.3.0-preview.5-s26-host-action-1be11d-final/`
- Package:
  `.artifacts/v0.3.0-preview.5-s26-host-action-1be11d-final/package/com.rice.ai-codedb`
- ZIP: `com.rice.ai-codedb.zip` under that root
- ZIP SHA-256:
  `1fb85dc9bcca8405d688c487e1def6d2ebfe75fd17979f06dfdebfb93d0884c5`
- Staged closure: PASS, `source_count=46`, `mismatch_count=0`
- Exact-ZIP closure: PASS, `source_count=46`, `mismatch_count=0`
- Export summary: `files=482`, `bytes=9864772`, `zip_entries=482`
- Cross-hashes: generation
  `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`,
  host-current
  `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`,
  runtime contract
  `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`.

The exporter and release-closure validator were run once for this artifact;
no repair mode, manual metadata edit, Package replacement, Unity launch,
manifest switch, project mutation, or real Remove/Install was performed.
The old S25 attempt remains consumed and unconfirmed.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: `GATE_A_PACKAGE_CLOSURE_PASS / GATE_B_AUTHORIZATION_PENDING`
Next notification: UnityCodeDB v0.3 Planner/User
Next action: separately authorize the human-owned Gate B dependency switch,
compile, and focused EditMode check against this exact artifact while Unity is
closed. Do not click Remove or Install at Gate B.
Human decision or authorization required: Gate B validation-project change and
human Unity acceptance; later real removal, fresh Install, Verifier, push, and
publication remain separate.

## Gate B - Human Unity Validation Result

The user opened `UnityValidationProject` against the exact S26 commit-derived
Package after the authorized manifest switch and reported:

- CodeDB C# compile errors: `0`;
- `AICodedbLifecycleControlTests`: full class PASS;
- `ControlContractMigration_PartialV1RequiresBoundCommittedEvidence`: single
  test PASS;
- no Remove or Install action was performed.

The user then closed Unity. Planner restored only the CodeDB dependency in
`UnityValidationProject/Packages/manifest.json` to the pre-Gate-B S25 value
`file:../../.artifacts/v0.3.0-preview.5-s25-receipt-path-6942c62-final/package/com.rice.ai-codedb`.
The restored manifest SHA-256 is
`a3fce2719778387ab423a6c17ab18c1c07e27a6109c5a404bf8382a234f7d780`, matching
the recorded pre-switch hash. No lockfile, ProjectSettings, other dependency,
source, runtime state, or artifact was changed by the restore.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: `GATE_B_HUMAN_PASS / GATE_C_READ_ONLY_PREFLIGHT_PENDING`
Next notification: UnityCodeDB v0.3 Planner/User
Next action: authorize one human-visible Gate C read-only removal preflight
against the exact accepted Package state. Do not click Remove until the
preflight is reviewed and separately authorized; do not click Install.
Human decision or authorization required: Gate C removal attempt, later fresh
Install, Verifier, push, and publication remain separate.

## Gate B - Human Unity Validation Authorization

The user confirmed that `UnityValidationProject` was closed and separately
authorized Gate B against the exact S26 commit-derived artifact. Before the
switch, the existing CodeDB dependency was recorded as
`file:../../.artifacts/v0.3.0-preview.5-s25-receipt-path-6942c62-final/package/com.rice.ai-codedb`;
the manifest SHA-256 was
`a3fce2719778387ab423a6c17ab18c1c07e27a6109c5a404bf8382a234f7d780`.

Planner changed only the `com.rice.ai-codedb` dependency in
`UnityValidationProject/Packages/manifest.json` to:

`file:../../.artifacts/v0.3.0-preview.5-s26-host-action-1be11d-final/package/com.rice.ai-codedb`

The JSON was parsed successfully and the target Package directory exists. No
lockfile, ProjectSettings, other dependency, source, or runtime state was
changed by this setup. Unity is still closed at this handoff.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: `GATE_B_AUTHORIZED / HUMAN_UNITY_OPEN_PENDING`
Next notification: human operator
Next action: open the existing `UnityValidationProject`, allow Package import
and compilation to settle, report CodeDB C# compile errors, then run exactly
the predeclared focused EditMode selections: `AICodedbLifecycleControlTests`
as a class and `ControlContractMigration_PartialV1RequiresBoundCommittedEvidence`
as a single test. Do not click Remove or Install in Gate B.
Human decision or authorization required: later Gate C removal and fresh
Install remain separate; stop at the first compile or focused-test failure.

## Gate B - Final Reconciliation - 2026-09-29

The human completed the authorized Gate B session against the S26
commit-derived Package and reported no C# compile errors. The full
`AICodedbLifecycleControlTests` class and the single
`ControlContractMigration_PartialV1RequiresBoundCommittedEvidence` test both
passed. No Remove or Install action was clicked.

Unity was then closed. Planner restored the CodeDB dependency in
`UnityValidationProject/Packages/manifest.json` to the pre-Gate-B S25 artifact
value. The restored manifest SHA-256 is
`a3fce2719778387ab423a6c17ab18c1c07e27a6109c5a404bf8382a234f7d780`, matching
the recorded pre-switch hash. No lockfile, ProjectSettings, other dependency,
source, runtime state, or artifact was changed during restoration.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: `GATE_B_HUMAN_PASS / GATE_C_READ_ONLY_PREFLIGHT_PENDING`
Next notification: UnityCodeDB v0.3 Planner/User
Next action: separately authorize one human-visible Gate C read-only removal
preflight. Do not click Remove until that preflight is reviewed and separately
authorized; do not click Install.
Human decision or authorization required: Gate C removal attempt, later fresh
Install, Verifier, push, and publication remain separate.

## Gate C - Read-Only Preflight Prepared - 2026-09-29

The user authorized only the Gate C read-only removal preflight. Unity remained
closed at setup. Planner changed the CodeDB dependency in
`UnityValidationProject/Packages/manifest.json` from the recorded S25 artifact
to the same S26 commit-derived Package that passed Gate B:

`file:../../.artifacts/v0.3.0-preview.5-s26-host-action-1be11d-final/package/com.rice.ai-codedb`

The manifest parsed successfully; its setup SHA-256 is
`e6360ddb341a018286e64ca433da917ddfe57ca6dc3d59372e427af1929d8ebc`.
The artifact ZIP SHA-256 still matched the Gate A value
`1fb85dc9bcca8405d688c487e1def6d2ebfe75fd17979f06dfdebfb93d0884c5`.
`packages-lock.json` was observed modified in the worktree during setup but was
not edited or restored by Planner. No real project runtime or receipt state was
read or changed; no Unity, test, Remove, or Install action was run by Planner.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: `GATE_C_READ_ONLY_PREFLIGHT_PREPARED / HUMAN_OBSERVATION_PENDING`
Next notification: human operator
Next action: open the existing `UnityValidationProject`, wait for import and
compilation to settle, then observe Manager Overview and Diagnostics for a
stable state and the read-only removal admission. Report exact visible state
and any error; do not click Remove, Install, or another maintenance action.
Human decision or authorization required: any real Remove attempt, later fresh
Install, Verifier, push, and publication remain separate.

## Gate C - Read-Only Preflight Blocked - 2026-09-29

The human opened `UnityValidationProject` against the S26 commit-derived
Package and supplied a CodeDB Manager screenshot. The visible Overview reports
`CodeDB status unconfirmed`: `The direct command has admitted or claimed
evidence but no matching terminal receipt; no replay was attempted.` Diagnostics
shows `Control contract migration: Removal required`, while Host payload and
Current instance are not evaluated. This does not establish the outcome of the
earlier action or admit a new removal attempt. The human was instructed not to
click Remove or Install; no new action result was supplied.

The human then confirmed Unity was closed. Planner restored only the CodeDB
dependency in `UnityValidationProject/Packages/manifest.json` to its recorded
pre-preflight S25 artifact value. No old action evidence, receipt, project
runtime state, lockfile, or ProjectSettings was changed by this reconciliation.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: `GATE_C_READ_ONLY_PREFLIGHT_BLOCKED / PRIOR_ACTION_UNCONFIRMED`
Next notification: UnityCodeDB v0.3 Planner/User
Next action: decide whether to authorize a separately bounded, read-only
diagnosis of the exact prior admitted/claimed action and missing terminal
receipt. Do not replay the old action or start a fresh Remove/Install from this
state.
Human decision or authorization required: prior-action evidence diagnosis,
real removal, fresh Install, Verifier, push, and publication remain separate.

## Gate C - Prior Action Read-Only Diagnosis - 2026-09-29

The user separately authorized a bounded read-only diagnosis after closing
Unity. The project-scoped Manager action partition contains exactly one
historical Package directory, action `3049af7cfc9f4260928e3f89d18672c0`,
and stage `b571e3a38c0f134306d1df4d412804de66048b32de371c95112d363e6b664b56`.
That stage has `admitted.json` and `claim.json`, but no `terminal.json` or
`start-failure.json`. Both records bind the same full project and Package keys,
action id, and stage id. The admission names the S25 receipt-path Package's
materializer, a confirmed project mutation, and a terminal-for-action command.
The admitted S25 writer still exists and its SHA-256 matches the admission's
`writer_sha256`.
The project action-index directory has no current or resolved action marker;
the current journal's legacy scan therefore encounters this pending receipt.

The S25 Package writer published `claim.json` before its `Add-Type` runner
construction. The human-reported `Add-Type` failure is consistent with that
claim-without-terminal interval. The S26 writer instead constructs the child
runner without that `Add-Type` step, but its recovery path does not convert a
historical pending claim into a terminal or pre-effect refusal. The exact
Windows temporary-source failure cause and a trustworthy terminal command
outcome cannot be reconstructed from these records alone.

The project desired-state record still says `INSTALLED / COMPLETE`, and the
previous `poc.34` current-instance selection remains. There is no proved
`UNINSTALLED / PENDING` transition. This read-only diagnosis does not claim
that an absent terminal receipt alone proves the child never started, and it
does not authorize fabricating a start-failure or resolved marker. The Gate C
preflight remains blocked by the earlier action, not by a newly attempted
Remove. No Unity, Unity MCP, process probe or termination, replay, runtime
mutation, receipt cleanup, source edit, test, commit, or push was performed.

Current task: `cdb-v0.3-p0-s25-s24-package-unity-reinstall-acceptance`
Current status: `BLOCKED / PRIOR_ACTION_CLAIM_WITHOUT_TERMINAL`
Next notification: UnityCodeDB v0.3 Planner/User
Next action: decide a separately scoped resolution contract for this exact
legacy pending action, with authenticated proof of pre-effect refusal or a
terminal outcome before any fresh removal admission. Do not click Remove or
Install, replay the old command, or manually clear its evidence.
Human decision or authorization required: resolution design/implementation,
later real removal, fresh Install, Verifier, push, and publication.

## Gate C - Historical Unknown Action Reconciled - 2026-09-30

S27 FIX 01 produced commit-derived Package
`.artifacts/v0.3.0-preview.5-s27-reconciliation-fix01-5cb4862-final/package/com.rice.ai-codedb`.
Using that Package, the separately authorized exact historical reconciliation
for action `3049af7cfc9f4260928e3f89d18672c0` completed with exit `0` and
published `HistoricalUnknownReconciled`.

The administrative marker retains `command_outcome=unknown`; it does not
claim the old Remove succeeded or failed. The original stage remains
byte-preserved with only `admitted.json` and `claim.json`; no terminal or
start-failure receipt was created. The proof rechecked the writer and exact
PowerShell command census, the project state under the materializer lock, and
the Manager index state before publication. The project remains
`INSTALLED / COMPLETE` with current selection `poc.34`; no operation journal,
operation directory, or removal intent remains. No process was stopped and no
old command was replayed.

Current status: `GATE_C_HISTORICAL_RECONCILED / FRESH_REMOVAL_PENDING`.
The historical unknown-action block is closed. A fresh Remove still requires
one separate human confirmation and backend preflight; fresh Install remains
blocked until authenticated `UNINSTALLED / PENDING` evidence exists.

## Gate C - Fresh Remove Ready - 2026-09-30

The corrected S27 Package preflight was run read-only against the validation
project and returned `[REMOVAL_PREFLIGHT] AVAILABLE`, exit `0`. The validation
project's manifest was then switched only for the CodeDB dependency to:

`file:../../.artifacts/v0.3.0-preview.5-s27-reconciliation-fix01-5cb4862-final/package/com.rice.ai-codedb`

Before the switch, `manifest.json` matched SHA-256
`a3fce2719778387ab423a6c17ab18c1c07e27a6109c5a404bf8382a234f7d780` and
`packages-lock.json` matched
`b0eae1cd7fc1a54fb82b857998cb67fbb547cf7f21cd6e3c2e67129b9bf608c5`.
The user-owned next step is one visible Manager `Remove CodeDB Integration`
click and one confirmation, with Unity open against this exact Package. Stop
on any error, ambiguity, or unexpected state; do not click Install or retry.

## Gate C - Fresh Remove Result And Package-Binding Restore - 2026-09-30

After the user performed the single visible `Remove CodeDB Integration`
action against the corrected S27 Package, Unity was closed before inspection.
The exact action `4d2e8ae90f5142eb9a107f5d6e513aca` has a terminal receipt with
`exit_code=0`, `state=terminal`, and the following authoritative result:

`[RESULT] UNINSTALLED`

`[CLEANUP_STATE] PENDING`

The receipt's structured command result is
`outcome=UNINSTALLED`, `phase=COMPLETE`,
`reason_code=INTEGRATION_REMOVAL_COMPLETE`, and
`next_action=Use Install CodeDB to create a fresh project integration.` The
project runtime independently contains `desired_state=UNINSTALLED` and
`cleanup_state=PENDING` with `state_id=4ba97765e6cd4f2597daa6b60db52e22`;
the retained removal intent binds the same state id, instance `7f02adc0f68f43c3888bf9375cc865ec`,
and generation `poc.34`. No historical Remove was replayed, no process was
stopped, and no Install was clicked.

With Unity closed, Planner restored the validation project's pre-Gate-C
Package bindings. `UnityValidationProject/Packages/manifest.json` now matches
the recorded S25 artifact value and SHA-256
`a3fce2719778387ab423a6c17ab18c1c07e27a6109c5a404bf8382a234f7d780`.
`packages-lock.json` was restored to its recorded inherited pre-gate S26
binding and SHA-256
`b0eae1cd7fc1a54fb82b857998cb67fbb547cf7f21cd6e3c2e67129b9bf608c5`.
Both files parse as JSON and their scoped `git diff --check` passed with no
output. Existing unrelated `ProjectSettings.asset` dirty state was preserved.

Current status: `GATE_C_FRESH_REMOVE_PASS / FRESH_INSTALL_PENDING`.
The real removal is now independently authenticated as `UNINSTALLED / PENDING`.
Fresh Install remains a separate human action and must not be performed until
the restored state and a new Install authorization are reviewed. Verifier,
commit, push, and publication remain separate gates.

## Gate C - Fresh Install Preparation - 2026-09-30

The user separately authorized the fresh Install after the authenticated
`UNINSTALLED / PENDING` result. With Unity still closed, Planner changed only
the CodeDB dependency in `UnityValidationProject/Packages/manifest.json` to
the closed S27 corrected Package:

`file:../../.artifacts/v0.3.0-preview.5-s27-reconciliation-fix01-5cb4862-final/package/com.rice.ai-codedb`

The manifest parses, the target Package directory exists, and the manifest
SHA-256 is
`c6b575e32016c8c0fb311df2ad7ba528716d4de44a30590a2e3e8a63db94e4f8`.
The inherited S26 `packages-lock.json` binding was preserved unchanged. The
runtime desired state remains `UNINSTALLED / PENDING` with state id
`4ba97765e6cd4f2597daa6b60db52e22`; no automatic Install or other mutation
was observed. Scoped `git diff --check` for the manifest passed with no output.

Current status: `GATE_C_INSTALL_READY / HUMAN_UNITY_INSTALL_PENDING`.
Next action is one human-visible Unity session against the exact project path:
wait for import/compile to settle, click `Install CodeDB` once, confirm once,
and stop on any error or ambiguous state. Do not click Remove, retry, or use
Unity MCP/BatchMode. Afterward, record the new instance, committed activation,
project MCP binding, Manager Ready state, and one bounded status/query check
before any Verifier routing.

## Gate C - Fresh Install Attempt Blocked Before Admission - 2026-09-30

The user opened `UnityValidationProject` against the prepared S27 corrected
Package and supplied a screenshot of the CodeDB Manager. No `Install CodeDB`
action was exposed. The visible Overview remained `Needs attention` with the
message `CodeDB could not finish setup for this project. Review diagnostics
before choosing a recovery action.` The diagnostic rows showed `Host payload:
Needs Setup`, `Current instance: Inactive`, `Coordinator startup: Inactive`,
and `Host generation: Inactive`; the technical details state that the current
Editor lease could not be established before coordinator admission. No
Install confirmation or mutation was performed.

This is not an Install failure and does not consume the authorized Install
mutation attempt: admission never produced the Install action. No retry,
Remove, Unity MCP, BatchMode, process probe, or runtime-file mutation was
performed. The screenshot is retained as human evidence of the blocked UI
state.

Current status: `GATE_C_INSTALL_BLOCKED / INSTALL_ACTION_NOT_EXPOSED`.
Next action requires a separately bounded diagnosis or corrected human-open
checkpoint for the missing Editor-lease/coordinator admission. Do not click
other recovery actions or infer a fresh instance from this screen. Verifier,
commit, push, and publication remain deferred.

## Gate C - Install Admission Lifecycle FIX 01 - 2026-09-30

After Unity was closed, the user authorized a targeted source and adjacent-test
fix. The read-only diagnosis found that an authenticated `UNINSTALLED / PENDING`
state intentionally skips Editor-lease publication, yet `RunReconcileWorker`
rejected the absent lease before reaching its existing uninstall cleanup and
`Uninstalled` status branches. That cached `NeedsAttention` and hid the
Manager's dedicated `Install CodeDB` view.

The source change moves the existing uninstall cleanup/status handling before
the no-lease rejection. It keeps automatic Supervisor reconnect disallowed,
deletes any Editor lease, preserves the pending-cleanup `Upgrade` route, and
publishes authoritative `Uninstalled` even when cleanup reports a warning.
The ordinary installed-state lease gate remains in place. Adjacent EditMode
tests now cover the current desired-state path with `UNINSTALLED / PENDING`,
no lease eligibility, Manager Install projection, and the lifecycle source
ordering that prevents this regression.

Focused source-order assertion: PASS. Two-path scoped `git diff --check`: PASS,
no output. The standalone package-boundary check stopped on the pre-existing
`C:/fixture/project` literal in unchanged
`Tests/Editor/AICodedbManagerUiTests.cs`; the same literal is present in HEAD,
so this is not evidence of a new lifecycle failure or a package-boundary PASS.
The added C# EditMode tests, Unity compilation, real Manager Install display,
and fresh Install remain NOT RUN. No exported Package, runtime evidence,
project binding, commit, push, or publication was changed by this FIX.

Current status: `FIX_01_SOURCE_READY / UNITY_AND_PACKAGE_GATE_DEFERRED`.
Next action is review of the two-file source/test diff and a separately
authorized validation/package handoff before resuming the human Install gate.

## Package Path Provenance Workflow Correction - 2026-09-30

The earlier package-boundary failure exposed a repeated process gap: the S18
test-root binding decision was task-local, while S24 introduced fixed-drive
fixture literals and did not run the path scan before snapshot freeze. The
two C# preflight argument tests now derive their supplied root from the test
runtime temporary area and assert exact argument forwarding. The directly
adjacent PowerShell historical-reconciliation fixture likewise derives its
synthetic Package root from its test run root. A batch helper's drive-root
usage example became a symbolic argument, and `.bat/.cmd` joined the Package
path scan. No production behavior changed.

Workflow revision 2.4 now requires a pre-freeze path-source declaration and
focused Package path-provenance check for Package text changes. The focused
check reuses the full package-boundary text selection and drive-root rule;
fixture-named hard paths have no exemption. Focused path gate: PASS, exit 0.
Both edited PowerShell scripts parsed: PASS. Scoped nine-path `git diff
--check`: PASS, exit 0. The full package-boundary gate, C# compile/EditMode,
Unity, fresh Install, and consumer validation remain NOT RUN; this correction
does not advance Gate C or claim a release Package PASS.

## Pre-Unity Candidate Gates - 2026-09-30

On HEAD `5cf474ad9f9a823fa29cbb8a4c7121a03c0fd1bc`, the focused path
provenance gate passed. The complete standalone Package-boundary initially
stopped on its older blanket `poc.34` runtime-source rule. S27's reviewed
historical-action proof intentionally binds the exact old `poc.34` selection;
the rule now excludes only that exact predicate inside
`Get-HistoricalUnknownProjectProof` and continues to reject the same literal
elsewhere in runtime policy source. No production source changed for this
gate correction.

After that bounded correction, the complete standalone Package-boundary
passed, exit 0. The directly affected `-HistoricalReconciliationOnly` L0
passed, exit 0, including unknown-outcome publication and fail-closed live,
incomplete, drifting, and repeated evidence. These checks do not prove C#
compilation, EditMode, a released artifact, or real Install. The validation
project still points at the older S27 export, so reopening Unity before a new
candidate is bound would test the wrong Package. Commit-derived export,
validation-project switch, human Unity gates, and real Install remain pending
separate authorization.

Pre-Unity handoff identity: HEAD
`5cf474ad9f9a823fa29cbb8a4c7121a03c0fd1bc`; ten-path source/workflow
stable patch identity `3bf457c7370bfe25cea078955261baec9f83be2f`.
Eleven-path scoped `git diff --check`, including this result record, passed
with exit 0 and no output. Current status:
`PRE_UNITY_SOURCE_GATES_PASS / COMMIT_DERIVED_CANDIDATE_PENDING`.

## Commit-Derived Candidate And Human Gate Handoff - 2026-09-30

The authorized ten-path source/workflow commit is
`a02a68c45362bb7ca60e846bacbd101c4498979f` on
`codex/v0.3.0-legacy-workflow`. Its staged patch identity matched the recorded
`3bf457c7370bfe25cea078955261baec9f83be2f`; staged `git diff --check`
passed. S25 task/result history, validation-project files, and unrelated
dirty/untracked state were not included in the commit.

The canonical exporter created a new, unmodified, commit-derived candidate at
`.artifacts/v0.3.0-preview.5-s25-install-admission-a02a68c-candidate`.
Commit-staged and exact-ZIP closure each passed with `source_count=46` and
`mismatch_count=0`; the ZIP has 482 entries, SHA-256
`7717eca61ce0c53f92621c766a8279de1ecbeceae4731931fe7cc1c41cba7bbd`.
The extracted candidate's full standalone Package-boundary passed.

No `UnityValidationProject` process was visible; the only observed Unity
process belonged to a separate `UnityResDB-clean` project and was untouched.
Only the CodeDB value in the validation project's Package manifest was
changed to the candidate's relative `file:` path. Its JSON parses, the target
exists and declares `com.rice.ai-codedb@0.3.0-preview.5`, manifest SHA-256
`35252105669b98d913f4d4e705a6491d97828e72526569e398ee323452c47a45`;
scoped manifest `git diff --check` passed. The inherited dirty lockfile and
ProjectSettings were preserved unchanged.

Status: `GATE_B_CANDIDATE_READY / HUMAN_UNITY_PENDING`. C# compilation,
EditMode, Manager Install visibility, actual Install, status/query, and RELEASE
Verifier are NOT RUN for this candidate. The user should perform the bounded
human Gate B/C observation in the current S25 task card; no Install click is
authorized by this preflight.

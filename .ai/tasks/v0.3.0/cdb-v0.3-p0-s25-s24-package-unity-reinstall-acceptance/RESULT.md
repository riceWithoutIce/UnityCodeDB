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

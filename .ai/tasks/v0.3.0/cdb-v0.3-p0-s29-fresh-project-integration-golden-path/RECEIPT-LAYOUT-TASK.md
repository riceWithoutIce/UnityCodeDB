# S29 compact Manager receipt layout - frozen implementation packet

Date: 2026-10-08. User approved the implementation boundary and said `同意 继续`.
IMPLEMENT authorized. FAST_SUBAGENT / GUARDED / STANDING_WORKFLOW, single writer,
depth one. Architecture decisions below are frozen by Planner; child implements
this bounded unit, not further redesign. Base branch codex/v0.3.0-legacy-workflow;
HEAD 332c7ffd510daebb6da6a386d66783d4aabf6bd6. Inherited dirty docs and real
projects are protected. Source/test baseline is clean; capture exact hashes before
edits. Canonical rules: Documentation~/manager-receipt-storage-layout.md and
Documentation~/test-workspace-contract.md. Read this packet first; historical
TASK sections do not authorize extra work. No live migration or Unity execution.

## Outcome and frozen wire decisions

Close C#, PowerShell writer, journal and test-consumer physical layout together.
New records use `<authorized receipt root>/<Action32>/<Stage16>.<kind>.json`.
Kinds: admitted, claim, terminal, start-failure. Stage16 is first16 lowercase hex
of full Stage64. Full project/Package roots and keys, Action, Stage and command
identities remain validated. No receipts-GUID wrapper in test fixtures.

Use field `storage_layout` with exact value `compact-v1` in new admission,
claim/terminal/start-failure and current/resolved journal records. Preserve
existing schema_version meanings: ordinary schema1; special historical resolved
schema2 stays legacy-only. Do not rename schema2 to mean compact storage.
Legacy field absence is admitted only with explicit old-path/old-record handling;
wrong/unknown layout is conflict. Missing layout at compact paths is conflict,
never fallback. New writer supports compact admission only; already dispatched
old writers continue independently against their original immutable Package.

Retain parameter name ReceiptPath in the new writer, but pass the exact compact
admitted FILE path; derive sibling names from validated Stage16 and Action32.
Reject directory/legacy arguments before launching a command. Preserve strict
machine-root confinement and reparse/identity checks, no arbitrary-root CLI seam.

## Allocation, journal and interrupted work

Existing project index/lock remains admission/lookup authority. Extend its model
with layout binding and propagate it through direct session/recovery callers.
Resolved entries retain original context and layout for direct compact lookup;
legacy-specific scans remain bounded at their existing project scope. Never scan
all machine actions or let missing/corrupt index authorize arbitrary execution.

Reserve compact action identity with `action.json` inside Action32, published
atomically/no-overwrite under existing admission before stage admission. It binds
storage_layout, managed_by, full Action and project/Package roots and keys. This
is an identity manifest, not another lifecycle state machine or mapping database.
Reuse only after exact full identity matches and existing journal owns the same
action. Foreign/full-identity mismatch is conflict. A matching stage admission
is existing evidence, never replay. Stage prefix collision is explicit conflict;
no alternate name retry, overwrite or mixed evidence. File publication and writer
claims must remain exclusive, not check-then-overwrite.

Before any child launch, validate all relevant complete paths, including action
manifest, journal/marker, longest evidence name and both atomic temp suffixes.
Failed or interrupted reservation/publication launches no child. Retain known
evidence; existing no-effect/PENDING semantics decide disposition. Missing receipt
after possible dispatch never implies no effects. Old pending operations are
observed via explicit legacy validator; no restarting, stopping, migration,
automatic deletion or rewriting old flags. Conflicting old/new locations for the
same action are conflict rather than selecting whichever validates.

## Test ownership and path evidence

Unity workspace: actual project Library/CodeDB/Tests/<12 lowercase hex>/, full
32hex ownership token retained in .codedb-test-owner. Use exclusive reservation
(CreateNew ownership/reservation under the test parent plus absent-directory
check), no adoption of an existing directory. One allocation attempt, clear
collision failure; mechanical command correction remains allowed. Cleanup only
proven owned paths, preserving primary and separate cleanup failures.

Use actual production layout helpers in fixtures. Entry capability probe must
exercise representative deepest record/temp paths using real System.IO; add
Editor coverage with at least S29 root length and longer-root failure handling.
Calculate all path overheads and report measured maxima. Do not introduce an
arbitrary 200/240-character product gate: if a platform limit is enforced,
document its actual API basis, include temporary names, and fail before effects
with exact offending path/length. No OS-temp fallback, drive alias, ACL/admin,
Windows setting or Unity patch-version requirement. C# API execution remains
human-owned and NOT RUN in this source phase.

PowerShell focused fixture owns .artifacts/tests/<short run>/ under repository.
Only its child ProcessStartInfo gets private LOCALAPPDATA/TEMP/TMP under that
run; parent/Unity/user environment unchanged. Copy Package writer into isolated
fixture Package; synthetic command children only. Require owned containment and
bounded cleanup. Never write a real machine journal or invoke real Host/Provider.

## Exact change allowlist (relative to com.rice.ai-codedb)

- Editor/AICodedbPaths.cs
- Editor/AICodedbProcessRunner.cs
- Editor/AICodedbManagerActionJournal.cs
- Editor/AICodedbManagerWindow.cs (layout propagation at recovery callers and
  layout binding inside its existing AICodedbManagerActionSession class only)
- Tools~/invoke-codedb-manager-action.ps1
- Tests/Editor/AICodedbTestWorkspace.cs
- Tests/Editor/AICodedbManagerUiTests.cs
- Tests/Editor/AICodedbEditorLifecycleTests.cs (direct changed context/fixture callers only)
- Tests~/test-codedb-package-boundary.ps1 (focused writer and directly stale path assertions only)

Keep layout authority in existing AICodedbPaths; language projection in standalone
writer must agree via focused contract evidence. No new helper module/dependency.
Coder owns RECEIPT-LAYOUT-RESULT.md and RECEIPT-LAYOUT-IDENTITY.json in this task
directory. Planner owns cards/contracts; Verifier owns only
RECEIPT-LAYOUT-VERIFICATION.md after stable handoff. Preserve inherited edits.

Read closure: above paths and their directly named APIs, approved plan/contracts,
prior TEST-WORKSPACE human evidence, current package/payload manifest bindings,
historical materializer reader and its directly coupled fixture. Tools writer is
outside immutable generation; verify direct manifest references before claiming
no generation transition. No edit of package version, payload/generation/pointer,
historical materializer, real project, exported package, .codex or machine state.
If a concrete dependency needs that scope, stop with one reassessment finding.

## Bounded evidence and completion

Non-Unity executable evidence: Windows PowerShell 5.1 parser checks for touched
scripts; PathProvenanceOnly; ManagerActionWriterOnly after fixture isolation;
scoped diff-check. Writer batch: existing seven synthetic outcomes plus at most
five directly coupled compact layout / replay / full-identity collision / wrong
layout / deepest-path cases (maximum12 scenarios per batch). Child lifecycle
cleanup only for proven fixture-owned processes; never kill external processes.
One initial plus at most two corrected attempts per scenario, justified by actual
edits or changed prerequisites; no unchanged reruns or broader full regression.

Author Editor tests for compact and legacy read, missing/wrong layout, prefix/full
identity conflict, duplicate admission, Package replacement, resolved history,
old pending evidence, path depth, ownership and existing receipt/session flows.
No asmdef/NUnit upgrade or unsupported attributes. Preserve original business
assertions. List exact methods/case counts for one later human compile/test cycle.
No C# compiler substitute, Unity/MCP/CUA/BatchMode, process probe, real Install,
Remove/replay, live cleanup, reference switch, commit/export/push or remote update.

Coder <=60 minutes; Verifier <=30 minutes. Per command <=200 lines/32KiB;
search/log <=50 matches/16KiB; Coder cumulative <=256KiB for this direct-consumer
closure, Verifier <=128KiB. Prefer <=60-line slices.
On truncated output narrow further reads; do not recapture whole files. RESULT
<=16KiB, exact baseline/final SHA256 for all allowed files plus HEAD/index and
changed paths. Stop at stable snapshot; source/PS PASS is not C# compile, Unity,
integration, S29 or release PASS. Parent admits snapshot, then independent review
of this contract and adjacent regressions only. Findings once to user, no direct
Verifier-to-Coder repair orders or recursive delegation.

Planner path correction before implementation: AICodedbManagerActionSession is
an existing class inside AICodedbManagerWindow.cs, not a standalone file. The same
approved layout-binding scope applies there; no class extraction or scope expansion.

Planner read-output adjustment during implementation: the existing nine-file
validation closure is large (roughly12k source lines). Permit up to256KiB of Coder
captured output while preserving narrow per-command slices, exact dependency
scope, 60-minute active-time and execution budgets. This is read-only inspection
capacity, not another test attempt or authority expansion. Record prior truncated
reads, never claim retroactive compliance and do not repeat unchanged dumps.

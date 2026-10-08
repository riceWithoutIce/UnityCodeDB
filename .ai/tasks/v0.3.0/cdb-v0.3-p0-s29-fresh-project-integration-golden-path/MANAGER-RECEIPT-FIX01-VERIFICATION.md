# S29 B-MR-01 scoped fix verification

Date: 2026-10-08. Disposition: B-MR-01 CLOSED AT SOURCE REVIEW / SCOPED PASS.
No remaining concrete finding in the original finding and its immediate
regressions. This does not mean C# compile, Editor test, Unity, runtime, live
recovery or release acceptance. Whole S29 remains PARTIAL.

## Snapshot admission

Independently verified HEAD `651f9b3b4a8af3108823036107f1d76bc450f760`, empty
staged index, and all nine source SHA256s in FIX01-RESULT: MATCH. Result SHA256:
`EC0F1D838C554E38074978786171698EC50B6C53FBAF74A3717D8C953423D149`.
Paths, lifecycle, journal and lifecycle-test files also match the previous
reviewed snapshot. Read FIX01-REVIEW/TASK/RESULT completely and revisited the
original B-MR-01 evidence. Coder was stopped; no source writes occurred here.

## Original blocker closure

`com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs:815` now tries the declared
Redeploy classifier before the generic single-terminal and historical INSTALL
paths. `:847-884` binds the four declared names to the existing
action/name/command-identity stage hash, rejects duplicates/undeclared stages,
supports the worker-only three-stage entry, and requires the predecessor chain.
There is no first/latest-record selection or arbitrary nonterminal skipping.

Actual producers match that contract: `AICodedbActions.cs:107-110` declares the
names, worker scopes at `:118`, `:152`, `:158` have false/false/true terminal flags,
and `AICodedbManagerWindow.cs:2445` uses the shared optional UI-preflight name
with false. Runtime config runs the existing project script with exactly `-Force`
(`AICodedbActions.cs:359-361`, `AICodedbPaths.cs:237`, `:410-412`). Materializer
argument construction supplies the matching DryRun and confirmed Redeploy shapes
(`AICodedbHostPayloadMaterializer.cs:235-259`). The real mutation producer emits
CONVERGED with COMPLETE cleanup for this route
(`Tools~/materialize-codedb-host-payload.ps1:9511-9516`), matching the new reader.

The classifier checks original effect/authority and command hashes, recognized
preflight status, strict matching REDEPLOY result, config path/arguments and stage
terminality (`ProcessRunner:885-930`, `:954-972`, `:1014-1068`). A completed chain
returns an authoritative action-terminal result containing mutation output plus
the final config outcome (`:944-951`). Redeploy is a direct-writer action, so the
existing resolver adopts that result (`ManagerWindow:2582-2600`, `:2682-2685`).
It now satisfies the existing release conditions (`:3561-3593`) instead of being
converted to Indeterminate. The original immediate-completion blocker is closed
in the reviewed control flow.

The journal still calls the same production aggregate reader and accepts a
CommandTerminal marker only for a Terminal aggregate
(`AICodedbManagerActionJournal.cs:350-379`). Accordingly, valid completed Redeploy
receipts no longer conflict with their resolved marker after Package replacement.
No marker/receipt rewrite or alternate durable owner was introduced.

## Immediate regressions

- Failed prefixes produce completed failure only when no successor exists
  (`ProcessRunner:933-938`). The original failed exit/output, mutation scopes and
  PENDING are preserved. Config failure retains the mutation output while using
  config's failed exit (`:897-908`, `:944-951`). Original stage flags remain intact.
- Missing final completion stays Pending; missing predecessor, wrong stage flags,
  unbound/malformed or undeclared extra records stay blocked. Failure with a
  successor conflicts. Timeout, overflow and incomplete drain do not release the
  action (`:878-895`, `:914-938`). Every completed record still passes the strict
  reader, and pending-plus-completed evidence is rejected before classification
  (`:793-820`).
- The historical failed INSTALL path still uses its bounded original classifier
  and returns the original INSTALL object (`:975-1011`). Its command binding
  keeps Redeploy disabled by default (`:1037-1068`). The special-case mutation
  allowance therefore does not generalize the historical INSTALL path.

## Test-source evidence and deferred gates

Reviewed the three new methods in `Tests/Editor/AICodedbManagerUiTests.cs`:

- `ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory`: 4 cases,
  lines 158-199. Real named three/four-stage shapes, production receipt/journal
  reads, session release/recovery, resolved markers, Package replacement, legacy
  and generation config paths, immutable receipt bytes and next-action admission.
- `ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects`: 7 cases,
  lines 201-237. UI/worker/mutation/config failures, failed exit, mutation output,
  PENDING retention, completed session and resolved journal.
- `ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain`: 11 cases,
  lines 239-287. Extra/unknown stage, wrong terminal flag, malformed/unbound
  evidence, wrong script, pending/missing predecessor or config, incomplete output,
  and failure followed by a successor; admission remains blocked.

The shared fixture retains the previous INSTALL defaults, uses production
argument construction and named stage-ID construction, and keeps test-owned
temporary journals/session isolation. The prior 19 cases retain NOT RUN status.
All 22 new + 19 prior = 41 Editor cases are authored but NOT RUN. No compilation,
Unity/MCP/CUA, process or real receipt probe, replay, removal, or previous
48/11/201 validation batch was performed. No source-only check is promoted to
behavioral PASS. F-IMC-01/P3 and human/runtime/release gates remain deferred.

## Procedure and stopping point

No additional audit, Coder contact, delegation, automatic fixes, source changes,
commit/export/publication or protected Unity/artifact changes. Only this report
was written. Review completed within the 30-minute active limit.

FIX01 Coder's interrupted static count script remains an exit-1 interruption;
the subsequent bounded unfinished-check completion is not a clean exit for that
original batch. Those source assertions were not rerun here. Prior Coder and
Verifier output deviations remain in their original immutable reports.

This review used byte-checked source slices of at most 40 lines/4 KiB, bounded
searches and commands, with no observed truncation or oversized source slice.
Output accounting retained 65,043 returned UTF-16 code units after an initial
15,000-byte allowance; cumulative transcript UTF-8 bytes were not independently
audited, so exact total-budget certification is not claimed. One initial targeted
search used a nonexistent Runtime~ directory, returned only the path error, and
was redirected using the declared materializer path; no live state was involved.

B-MR-01 is closed at the source-review gate. Stop this review here. Planner/User
owns acceptance and the separately authorized human test/runtime gates.

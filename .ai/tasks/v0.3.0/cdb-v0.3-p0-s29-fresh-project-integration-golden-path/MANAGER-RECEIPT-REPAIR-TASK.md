# S29 Manager action/stage semantic closure

Date: 2026-10-08. User disposition: FIX, authorized by `同意` after the
diagnosis and coherent repair proposal. This is the active source-repair packet
under the existing S29 task; historical task/evidence remains unchanged.

## Frozen outcome and authority

Recover the proven failed INSTALL + completed DryRun + pre-effect rejected
Upgrade historical shape without treating each stage's completion as a second
independent action result. Preserve original failed INSTALL and PENDING effects;
do not clear real runtime state. Isolate future lifecycle work from inherited
Manager action identity, terminal-stage flag, effect, authorization and dispatch
tracker. Correct original-Package presentation on journal conflict.

Base HEAD: 651f9b3b4a8af3108823036107f1d76bc450f760.
Branch: codex/v0.3.0-legacy-workflow. Mode: FAST_SUBAGENT source-only closure.
Delegation: TASK_SPECIFIC (user approved child Coder then independent Verifier),
also covered by existing STANDING_WORKFLOW. Runtime model/effort: inherit parent;
deep time envelope, 60 minutes Coder / 30 minutes Verifier. Depth one, single
writer. No child delegation or cross-session messages. Review: GUARDED.

User has accepted the architecture above; routine implementation choices inside
it do not require another approval. An unresolvable authority/design expansion
returns to Planner. This packet covers source work and review only, not Unity,
live recovery, commit/export/publication, or release acceptance.

## Change allowlist

Paths below are relative to com.rice.ai-codedb/:

- Editor/AICodedbPaths.cs
- Editor/AICodedbEditorLifecycle.cs
- Editor/AICodedbActions.cs
- Editor/AICodedbProcessRunner.cs
- Editor/AICodedbManagerActionJournal.cs
- Editor/AICodedbManagerWindow.cs
- Tests/Editor/AICodedbManagerUiTests.cs
- Tests/Editor/AICodedbEditorLifecycleTests.cs
- Documentation~/v0.3.0-p0-host-action-execution.md (append a bounded contract
  section only; inherited dirty contents must be preserved)

Coder owns MANAGER-RECEIPT-REPAIR-RESULT.md in this task directory. Planner owns
this packet and TASK.md. Verifier owns MANAGER-RECEIPT-REPAIR-VERIFICATION.md only.
No modifications to historical diagnosis, accepted prior repairs, or other docs.

## Contract and direct consumer closure

Authority: Host Action Execution Contract, extended here to distinguish stage
completion, action result, and unresolved effects. No new receipt schema/writer,
parallel admission owner, generic recovery platform, or historical rewrite.

| Boundary | Producer | Reader / consumer | Evidence |
| --- | --- | --- | --- |
| action attribution and stage terminality | Paths action/stage scopes; Lifecycle dispatch; Actions | ProcessRunner admission and existing Package writer | isolated scope/lifecycle regression |
| immutable stage receipts | existing admitted/claim/terminal production route | ProcessRunner.RecoverManagerAction | actual reader fixture, one stage and proven three-stage shape |
| resolved marker and original context | ManagerActionJournal | journal historical scan; ManagerActionSession.RestoreDurable; warning UI | changed Package + conflict context regression |
| original failed result and PENDING | original INSTALL COMMAND_RESULT | session admission and existing removal presentation | original failure/effects retained, no replay |

Read closure: allowlisted files, MANAGER-RECEIPT-CONFLICT-DIAGNOSIS.md, existing
Manager writer script and SupervisorProtocol/host-status/result decoder symbols
directly referenced by these paths, test asmdef, relevant contract sections and
existing focused fixture helpers. No repository-wide audit or live receipt reads
are required. Exact old receipt identities are diagnosis evidence, not constants
to hard-code. Test fixtures must use test-owned temporary contexts/journals only;
never C:/fixture/project or a real validation project/machine journal root.

## Required behavior / safety invariants

1. Validate every stage through existing strict readers before classification.
   Recognize the evidenced failed INSTALL, successful read-only status and
   rejected-before-effect follow-up by authenticated command/result semantics,
   not directory order, first/latest receipt, GUID/path, or permissive fallback.
2. Original INSTALL failure, mutations and PENDING remain authoritative for
   outstanding effects. A later COMPLETE with no effects never erases PENDING.
   Known completed failure is distinct from unknown execution. Removal remains
   a separately confirmed action with the existing live safety gate.
3. Pending, malformed, identity-mismatched, unclassified or additional mutating
   stages stay blocked. Preserve normal one-terminal behavior and existing
   safety evidence; do not silently ignore a stage merely because it is nonterminal.
4. Preserve all real historical bytes. No manual marker deletion, terminal-flag
   rewrite, selected candidate adoption or automatic replay. Prefer deriving the
   aggregate from original validated records on read; any inability to do this
   within existing journal authority must be reported rather than adding a
   second durable protocol.
5. Lifecycle observation/convergence must not inherit user confirmation or the
   user's action terminality. Preserve project/package capture and required
   lifecycle policy; do not turn automatic work into a new confirmed action.
6. Conflict UI displays authenticated original Package context or explicitly
   unavailable context. Current Package must never be mislabeled original.

## Evidence and execution bounds

One coherent static/source batch plus scoped git diff --check and final exact
SHA256 file manifest (include preexisting contract baseline hash and final hash).
Initial plus at most two causally justified corrected semantic attempts, two
pre-effect mechanical corrections. No repeated unchanged evidence. Normal output
<=200 lines/32 KiB; searches <=50 matches/16 KiB; prefer <=80 lines/4 KiB per
source read, cumulative <=128 KiB. Coder result <=16 KiB, no transcript dumps.

L0: use an existing applicable pure harness only if available in direct closure;
otherwise DEFERRED, do not invent an external Unity substitute/test platform.
Affected L1: add tests in the two existing Editor test files for production
reader aggregation, full journal->session->removal presentation, isolated async
action/stage scope, normal terminal, true conflict/unknown, changed Package, and
PENDING preservation. Reuse production serialization/read boundaries and existing
fixtures. These Unity/EditMode tests are NOT RUN in this envelope; list exact
human test names/case count for later delivery. Do not claim static PASS as compile.
Explicitly not run: Unity/MCP/CUA/BatchMode, external process probes, real
Install/Remove/replay, Provider/MCP changes, old 48/11 or 201-assertion batches,
full regression. F-IMC-01/P3 remains DEFERRED.

Unity is human-owned and currently open on a frozen extracted package. Do not
change project references, artifact bytes, payload/generations or live receipts.
Preserve all inherited dirty files. No commit, push, export, tag or publication.

## Stable handoff and review

Coder completes implementation within this envelope, records actual evidence,
new test names, exact changed-file identity, deferred gates and stops. Planner
admits snapshot then dispatches one independent read-only Verifier review of
the six invariants and immediate regressions, with no test rerun and no Coder
contact. Findings are returned together to user for ACCEPT/FIX/DEFER/STOP.
Whole S29 remains PARTIAL until human/runtime gates actually pass.

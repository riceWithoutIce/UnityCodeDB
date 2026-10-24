# S32 independent targeted verification - 2026-10-17

Disposition: **FIX recommended; two in-scope findings**. This is a read-only
GUARDED source review of the stable snapshot admitted by the parent. No repair
was requested from Coder and no product, test or evidence bytes were changed.
Only this report was written. User disposition remains ACCEPT/FIX/DEFER/STOP.

## Scope and evidence

Read TASK.md, RESULT.md, BASELINE-SHA256.md, changed product hunks/new files,
the new focused tests/driver, existing frozen logs, and direct ownership,
Supervisor operation producer and terminal-validation references. The parent
already admitted final hashes and preservation bindings; unchanged tests and
hash checks were not rerun. Incoming timeout/termination, repeated-Uninstall
and earlier documentation hunks were excluded from S32 review ownership.

Model/effort settings were inherited; no reliable exact runtime identifier is
available to this reviewer, so no model or effort value is asserted. No child
was created, no Unity/backend was launched, and no external process or runtime
configuration was modified.

The reported evidence is correctly limited to HARNESS: original C# compilation,
original ProcessRunner -> writer -> genuine missing-payload failure -> receipt
reader -> session/journal recovery, plus separately mocked process inventory and
validated-retained inputs for the original lock/guard. The Actions call itself
and the unchanged initialization chain were source-reviewed. Successful
initialization, Provider/full convergence, Unity, real process visibility and
real reinstall are not established and are not claimed here. These declared
limits are not additional review blockers.

## Findings

### F1 - P1 / BLOCKER: unrelated inaccessible shell metadata blocks normal Install

Location: `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1:4867` and
`:4876` (Assert-ProjectInstallExecutionAdmission).

The inventory selects every machine-wide PowerShell, pwsh, Node and MCP process
by executable name. Before establishing any project or CodeDB relationship,
the loop rejects a blank CommandLine. For example, an ordinary Unity user can
have an unrelated elevated PowerShell/Node process whose command line is not
visible to that user's CIM query. The project's first Install or reinstall is
then refused even though that process has no project ownership. This is a
normal lifecycle availability issue, not merely a hypothetical PID race.

The frozen clarification scopes observation to relevant project execution.
Executable name alone is not project relevance; the existing fixture calls a
synthetic unrelated Node row with null metadata "relevant" and therefore locks
in the overbroad refusal rather than proving that distinction. RESULT's
disclosed conservative behavior does not close that frozen requirement.

Requested bounded correction: establish the supported project/CodeDB relevance
boundary before making inaccessible metadata a project blocker. Preserve
fail-closed behavior for genuinely relevant live/unknown identities and do not
infer global process absence. Verify unrelated inaccessible execution versus
relevant inaccessible execution as distinct cases. If safe attribution cannot
be closed in this task, return that specific boundary for user disposition.

### F2 - P1 / BLOCKER: terminal labels are accepted without execution completeness

Location: `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1:4933` through
`:4942` (history admission).

The new history gate validates identity, terminal state/phase labels and the
recorded child's absence, but never validates the terminal result or its
execution/output completeness. A production Supervisor operation can finish
with state `failed`, phase `failed`, a dead recorded child, and
`result.timed_out=true` (or output incompleteness); those flags are preserved by
`compactResult` in `Tools~/codedb-project-supervisor.mjs:2060` and terminal labels
are assigned by `finishOperation` at `:1314`. Such history passes this new gate
as long as its retained instance binding matches. A record missing result/schema
and terminal timestamps also passes these checks. The admission fixture's
accepted "completed attributable uninstall" record omits those fields entirely.

That promotes an incomplete/unknown execution observation to the completed
history exception before a new Install mutation. A dead parent PID does not
establish complete dispatch/output observation or the absence of escaped
subordinate execution; the subsequent instance next-change check validates
resource bindings and does not validate these Supervisor result flags. The
existing direct terminal path deliberately retains timed-out/incomplete action
admission, and the existing removal terminal validator explicitly rejects a
timed-out result (`Tools~/materialize-codedb-host-payload.ps1:10225`).

Requested bounded correction: validate the complete supported terminal envelope
and execution-completeness flags before treating history as inactive completed
authority, preferably by reusing the compatible existing validation contract.
Missing/malformed/timed-out/output-incomplete history must remain unknown, while
well-formed complete failure may remain failure and need not be misclassified
as running. Add only the direct regression cases for this history exception;
no historical backfill, migration, cleanup or new recovery route is requested.

## Reviewed closure without additional findings

- New Install deliberately reaches the existing materializer; the original
  initialization and post-command reconcile policies remain unchanged.
- Route marker production closes through compact manifest, journal, session
  restore and exact release matching. Unmarked records retain legacy dual-route
  interpretation rather than receiving a title-derived route.
- The new route's normal/reopen reader requires direct receipt evidence and
  rejects a competing same-action Supervisor map/canonical operation. Missing
  claimed terminal remains unknown; complete failure and pre-effect refusal
  remain distinct. The existing S30 pending action is not auto-released.
- No process termination, history deletion, payload transition, delivery or
  real lifecycle replay is introduced by the S32-owned changes.

Review stops with these consolidated findings. No broad audit, unchanged test
rerun or further repair/review iteration is authorized by this report.

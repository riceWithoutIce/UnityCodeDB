# S29 test workspace ownership correction

Date: 2026-10-08. User said `好的 我们继续` after approving and freezing
Documentation~/test-workspace-contract.md. IMPLEMENT authorized under that
design. Same S29 outcome; child Coder then independent Verifier. FAST_SUBAGENT /
TASK_SPECIFIC plus STANDING_WORKFLOW / GUARDED, depth one, single writer.
Base HEAD: 932e3e7ff695019ebebac9d3e7ba2f4b9e205105. Index empty; source/test
paths clean. Current Unity project is human-owned, may remain open on frozen
export. No edit of that export, real project or system temporary files.

## Outcome and exact boundary

Make S29 receipt/session fixtures obtain one explicitly owned workspace from
the actual current Unity project's Library/CodeDB/Tests/<unique-run>/, captured
on main thread before action overrides. All simulated project/package/journal
paths must remain within it; lower-level fixtures receive paths/owner explicitly.
Use the canonical contract above, not OS temp, fixture constants, global environment
changes, ACL/admin workarounds or a production storage migration.
Probe required create/read/delete capabilities during setup. Revalidate owned
containment and reject reparse escape at cleanup. Restore session/context scopes
on failures; preserve primary test failure plus separate cleanup evidence. A
cleanup-only failure cannot PASS. Do not hide unknown original business failures:
human supplied one Dispose exception; other failures are not yet attributed.

## Allowlist (relative to com.rice.ai-codedb)

- Tests/Editor/AICodedbManagerUiTests.cs
- Tests/Editor/AICodedbEditorLifecycleTests.cs (only S29/context direct consumers)
- Tests/Editor/AICodedbTestWorkspace.cs (new shared test-only entry, if useful)
- Tests/Editor/AICodedbTestWorkspace.cs.meta (paired Unity metadata if new file)

No production C# or runtime/script edits. If a production API defect is proven,
report it rather than silently widening this fixture repair. No asmdef/NUnit
dependency change or unsupported attributes. Shared session fixture changes must
account for its existing direct callers without migrating unrelated test families.
The canonical workspace contract/workflow are already frozen and uncommitted;
read, do not rewrite them. Other inherited dirt remains protected.

Coder owns TEST-WORKSPACE-REPAIR-RESULT.md. Verifier owns
TEST-WORKSPACE-REPAIR-VERIFICATION.md only. Parent owns task/decision records.
Read closure: the contract, MANAGER-RECEIPT-HUMAN-RESULT.md, source fixtures and
direct production/test APIs they call (Paths/session/journal and test asmdef),
the prior 41-case manifest in MANAGER-RECEIPT-HUMAN-CHECKLIST.md, and focused
Package path validator. Use local symbols/slices; do not scan entire repo/history.

## Evidence

Keep prior 41 receipt/lifecycle assertions meaningful; migrate fixture lifecycle
without weakening result/effect/identity assertions. Add narrowly focused Editor
coverage for owned writable root, unavailable root with no fallback, cleanup
containment/ownership, scope restoration, and primary-failure preservation. Use
test-owned fault injection where required; no deliberately touching system temp,
ACLs or production project data. Verify API availability against existing Unity
test assembly conventions (no NonParallelizable/new NUnit assumptions).

L0: no existing pure harness for Editor C#; DEFERRED. Do not invent a compiler or
Unity substitute. Required one PathProvenanceOnly static batch and scoped
git diff --check, plus bounded source consistency review of changed consumers.
Human C# compile/EditMode NOT RUN; report exact changed/new methods and case
counts for next handoff. No previous 48/11/201 batch, full regression, fixture
execution, Unity/MCP/CUA/BatchMode, process probes, real Install/Remove/replay,
system-temp cleanup, reference changes, commit/export/push or remote updates.

One initial plus at most two justified corrected non-Unity attempts per scenario,
two mechanical corrections; never rerun unchanged checks. Coder <=60m; verifier
<=30m. Prefer <=40 lines/4KiB slices, command <=200 lines/32KiB, rg <=50 matches/
16KiB, cumulative <=128KiB. Avoid whole-file regex scans previously stalled.
One consolidated result <=16KiB with exact baseline/final SHA256 identity.

## Stop and handoff

Implement continuously inside this envelope, then stop at a stable snapshot.
If scope, authority or architecture must expand, return one clear blocker without
live workarounds. Parent checks identity then an independent verifier checks only
this workspace contract and direct fixture regressions. No simultaneous review
and development, no recursive delegation, no reviewer-to-Coder repair demands.
Findings once to user. No test/source review claim closes human validation or
S29 real install/removal. Prior source ACCEPT remains historical scope only.

# S29 Manager receipt repair - human validation blocked

Date: 2026-10-08. Status: HUMAN_TEST_FAILURE / FIXTURE_CLEANUP_ACCESS_DENIED /
CAUSE_BOUNDARY_IDENTIFIED / SOURCE_FIX_NOT_AUTHORIZED. S29 remains PARTIAL.
Source ACCEPT and delivery byte checks retain their own scope, not human PASS.

## Human evidence

Screenshot: codex-clipboard-b6ace506-ad6b-44be-b1ba-26c9790dc048.png.
SHA256: 0F5EC6EB93EBBB4BFACDB752B7ABCC606EDE967643AEEBC392118097B86C740C.
EditMode filter ManagerReceipt_. Visible aggregate counters: 12 green, 39 failed,
662 gray; counters are not independently established as the exact 41-case batch.
Most visible receipt cases failed, one unavailable-context case is green.
Screenshot initially had no selected-case exception detail.

Human supplied complete error for
ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory(False,False):
System.UnauthorizedAccessException: Access to path
C:\WINDOWS\TEMP\codedb-s29-receipts-a478a2b778224c88bcfd7a133f73835c is denied.
Stack: FileSystem.GetFindData -> RemoveDirectory -> Directory.Delete ->
ManagerReceiptFixture.Dispose (exported ManagerUiTests.cs:153) -> test at :199.
Exact artifact: .artifacts/0.3.0-preview.5-s29-manager-receipts-poc40/review/
com.rice.ai-codedb. No second-case stack has yet been supplied.

## Bounded source diagnosis

The delivered fixture initializes _root from Path.GetTempPath() plus a GUID
under codedb-s29-receipts-. Dispose calls Directory.Delete(_root, true), restoring
the async-local receipt-root scope in finally. The reported path proves Unity's
temp selection was C:\WINDOWS\TEMP in this run. The supplied exception is a
cleanup/access failure, not a Redeploy assertion message or real Install result.
Do not claim all business assertions passed: Dispose can replace an earlier
exception. Do not generalize this one stack to all failed cases or infer the
specific ACL/antivirus/lock cause without evidence.

The existing session fixture also derives captured test project/package paths
from Path.GetTempPath(). Receipt root override is test-only, async-local;
production defaults still use LOCALAPPDATA/Rice/CodeDB/manager-actions.
No evidence here establishes a real production registration path failure.

## Proposed same-scope correction, pending user FIX

Use an explicitly test-owned writable root captured from the actual current
Unity project's Library (or an established equivalent repository-approved test
root), with unique per-run directory and isolated project/package/receipt subroots.
No hard-coded fixture project, Windows temp dependency, user-global environment
rewrite, admin elevation or broad deletion. Validate ownership/containment and
probe required create/read/delete operations in fixture setup. Preserve primary
assertion failure when reporting cleanup failures; never swallow cleanup errors
and claim PASS. Cover the shared fixture boundary through the existing tests.
This is a proposal, not a source change or fixture rerun.

Read-only delivered-source inspection and task evidence recording only. No test
rerun, C# compile, Unity control, process/ACL probe, live receipt/candidate edit,
cleanup, source fix, export or commit performed. Keep Unity and failed test
evidence intact; do not click Install/Remove. Human FIX decision is next.

# S29 version-transition observation — prepared delivery proposal

Date: 2026-10-14, Asia/Shanghai.
Status: PREPARATION_COMPLETE / DELIVERY_GRANT_PENDING.

## Reviewed source and preflight

Source acceptance: VERSION-TRANSITION-OBSERVATION-ACCEPTANCE.md.
Base/current HEAD: c6c2f036aa3c5d08a2334118d9049eff9dd3b875.
All four accepted worktree hashes rechecked and match on this date; scoped
diff-check passed and staged index is empty. Preserve unrelated dirty/untracked
content, particularly dirty Payload and OwnerIdentityV2Status.

Commit allowlist, relative to repository:

- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1
- com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
- com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
- com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs

Proposed subject: `fix: authenticate retained predecessor observations independently`.
No task records or other files are included in this source commit.

Exporter and closure validator have no working-tree diff against HEAD.
HEAD's committed payload remains poc.43; export must use the new commit's
complete Package tree, never dirty working-tree Payload or the test overlay.

S29 manifest/lock still select:
file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-startup-auth-boundary-c6c2f03/review/com.rice.ai-codedb.
Their current hashes are respectively
99dd35fff5d95eea9a775986ccc5afca7e9af79517a6ab1b8f1ecb06a62903b7 and
b03cdcbbf3dcb636a263442de847d565e38444d2aa810c5456907e708cfe8d49.
Read-only inventory found no Unity process naming this project; recheck
immediately before reference changes and stop if it is open/unverifiable.

## Proposed grouped delivery grant

1. Revalidate accepted hashes and empty index, stage exactly the four allowlisted
   files, inspect staged file/hash equality, then make the proposed local commit.
   Stop if scope/hash/base has drifted; do not stage wholesale or push.
2. Run the existing exporter with `-Commit <new full SHA>` and unique
   `-OutputRoot .artifacts/s29-version-transition-observation-<short SHA>`.
   It archives that commit, validates the commit-stage Package, produces a
   deterministic ZIP and validates its exact extraction. Retain production
   payload admission, source byte closure and native VerifyOnly gates. Capture
   the command/log, ZIP hash, entry counts, exact four-file hashes and unchanged
   target runtime authority. This is a new accepted-source package, not a replay
   of the previous export. Do not regenerate generations or launch native runtime.
3. Only after exact-package gates pass and S29 Unity is closed, back up its
   manifest/lock under `.backups/s29-version-transition-observation-<short SHA>`
   and change only both CodeDB reference values to the new exact review Package.
   Reparse both JSON files, confirm matching references and package existence,
   and compare protected selected/desired/activation/operation hashes before/after.
4. Write DELIVERY-RESULT and a human Unity checklist, including explicit fixture
   and environment preparation for
   `ManagerVersionTransition_ProductionObservationKeepsIdentityAndSafetySeparate`.
   Bind existing final fixture `coder-a1/fixtures/r-c56cb129` and its production
   observation inputs to the accepted/delivered source hashes. The test requires
   `CODEDB_VERSION_OBSERVATION_FIXTURE` inherited by Unity; missing it means
   Ignore, not PASS. Prepare a reviewable human-invoked launch recipe if needed;
   do not launch Unity automatically or use MCP/BatchMode/CUA substitutes.

Any failed commit/package/reference prerequisite stops this delivery attempt
with evidence preserved; no automatic repair, second export attempt, cleanup or
real mutation is authorized by this proposal. Preserve old artifacts/backups.

## Human gate and unresolved items

Human controls opening Unity, compilation/import observation, the new focused
test with a valid fixture environment, Manager close/reopen/tab checks and Unity
close. Native consumer assertions must run to claim that consumption gate PASS;
source/compile/24 synthetic assertions do not substitute for it. Report actual
status and diagnostics without expecting target Ready while predecessor remains
installed. Do not click Install/Remove/Upgrade during this acceptance.

The old removal-preflight exit 4 remains a separate unresolved cause. No promise
of its resolution, real migration/removal, sustained Ready or S29/release closure
is made. CleanupMono continues deferred observation. This grant would not cover
true Install/Uninstall/Remove/Upgrade, index/history cleanup, process control,
system settings, push or publication.

## Authority

User `好的 我们继续` authorizes preparing this concrete proposal after source
acceptance. Under workflow lines 103-114 and this task's acceptance, it does not
by itself authorize the named delivery mutations. Obtain one bounded group
grant; after approval continue all approved prerequisite stages without repeated
per-command/per-stage permission requests.

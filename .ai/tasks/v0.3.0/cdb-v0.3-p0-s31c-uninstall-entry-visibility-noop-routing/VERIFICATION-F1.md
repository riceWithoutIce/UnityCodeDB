# Verification: S31-C F1-only repair

## Outcome

- Verdict: **PASS WITH LIMITS — original F1 closed at source/component level.**
- Workflow: `codedb-workflow-v2`, revision `2.6`; `GUARDED`, task-specific sequential `FAST_SUBAGENT` read-only re-review, inherited model/reasoning without override.
- Scope: original F1 and its adjacent regression only. Initial `VERIFICATION.md` remains preserved. F2 remains **FOLLOW-UP**, unchanged and not re-audited.
- This is a source-review recommendation for User/Planner acceptance, not Unity, backend lifecycle, delivery or release acceptance.

## Exact Snapshot

HEAD remains `279b442c657676d1adbda7d15151a3770682a674`; dirty bytes are identified by the latest F1 section of `SOURCE-SHA256.md`:

| Source | SHA-256 |
| --- | --- |
| `Editor/AICodedbActions.cs` | `9c2133d9790183b22d57415977a9dafa8518c7df9730271785bc5b2fffd4bee2` |
| `Tests/Editor/AICodedbManagerUiTests.cs` | `abf690e017b4343b0dfda8d26b7cd71a4744831cfd52ee5126b954dc7e745fd5` |
| `Editor/AICodedbManagerWindow.cs` (unchanged) | `d812bd9ee59a1a9518eebb4a5918b8877e6dc8ca834275fa2107433df936947e` |
| `Tests/Editor/AICodedbEditorLifecycleTests.cs` (unchanged) | `634100865e8e7410b6d35cfb4bb6ff526cc383c0d8cdbfbe70e9682f3354662e` |

Paths above are relative to `com.rice.ai-codedb/`. Current source hashes match the recorded snapshot. The F1 manifest hash is `fc29f42496bf02b026d0becd859c5e99daf9f42a0a5cedd3de0c149dc3b4c5f0`; the task driver hash is `b6c598fc6416ef84f8b3d33389cf8dd1556fc2736b6c4423353951f917f4a4b6`. Both match the record and manifest source entries.

## F1 Closure And Adjacent Regression

`ReadUninstallLocalDisposition` reads the existing canonical integration status
and invokes the same typed `GetUninstallLocalDisposition` exercised by the
focused tests. Only canonical `NotIntegrated` returns successful local
`NoActionNeeded`. `Uninstalled`, including COMPLETE and PENDING, returns null
instead of asserting absence. The existing async `local ?? await dispatch()`
therefore routes those requests to the original backend admission/consistency
checks. No new current-instance authority or fallback was introduced.

Consequently, a COMPLETE desired-state document can no longer locally mask a
conflicting selected/current instance. This directly closes F1 without claiming
that the real backend was executed. Five typed current-state cases verify that
COMPLETE always defers; the adjacent test retains fresh no-op and invalid-state
refusal with the exact local evidence flags. The canonical fixture assertions
now require both COMPLETE and PENDING to increment the dispatcher count; that
native-reader fixture remains unexecuted.

## Evidence And Limits

- Reused `.artifacts/tests/s31c-f1-20261017-a/`: original Editor and all Editor test source compilation PASS, same three existing-site warnings; focused component run PASS, reported exit 0, six method/case invocations.
- Inspected actual generated invocation driver, focused log, compiler logs and manifest; they match the narrow typed-component evidence claim. Typed values are explicit component inputs, not replacement canonical readers or simulated Unity-native APIs.
- Scoped source `git diff --check`: PASS. No tests rerun by Verifier.
- Original 22 passing invocations were not rerun. Canonical reader/native initialization, resolver/session completion, actual backend, real uninstall and Unity remain **NOT RUN**. Initial standalone native-path overall exit 1 remains frozen as `ENVIRONMENT_INCOMPLETE`.
- No product/test edits, Coder repair requests, new agents, Unity/Provider startup, process control, commit, export or reference switch were performed during re-review.
- No new in-scope findings. F2 remains FOLLOW-UP under the existing user disposition.

## Handoff

F1-only review is complete; stop this review. Return to Planner/User for source
ACCEPT or other disposition of this exact snapshot with the stated limits.
Delivery and human Unity/real-operation gates require their own authorization.

# S37 narrow repair verification — 2026-10-19

## Result

PASS_WITH_LIMITS for the frozen production-source review. No production BLOCKER
was found in the status-direct-read or asynchronous Windows identity change.
One adjacent fixture incompatibility is recorded below as FOLLOW-UP. This is
source/static evidence, not runtime latency, Windows process-authentication,
Unity or delivery acceptance.

Reviewed production snapshot:

- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- SHA-256: `63537CF98AD82C37077FC4C312C7521DBBBAA61CCBC02C69A477AF45D8FED1F1`
- Comparison: current working-tree diff against HEAD, limited to this file;
  unrelated dirty state was preserved.

## Confirmed source behavior

1. `dispatch` returns `publicStatus(state, coordinatorStatus)` directly for
   status (`:1519-1528`). It only queues a best-effort refresh and does not await
   that refresh or enter the query lane for its response. Request token
   authentication remains ahead of dispatch (`:3038-3058`). The public owner,
   project, instance and readiness projection was not changed.
2. Windows process inspection uses asynchronous `execFile`, awaited through
   `getProcessEvidence`, rather than synchronous PowerShell execution
   (`:52-68`, `:2623-2673`). Executable lookup also awaits asynchronous
   where/which (`:2529-2547`). Every production caller of changed identity and
   child-admission functions was checked for the corresponding await; none
   retained the removed `getProcessEvidenceSync` symbol.
3. Existing PID/start identity, executable, argv and command-line evidence
   fields and comparison branches remain. Unavailable evidence still rejects
   admission/recovery; no PID kill rule, unknown-to-success conversion or
   mutation authorization was added (`:2426-2476`, `:2613-2673`).
4. Query and maintenance queue functions and admission semantics are unchanged.
   The intentional exception is status bypassing that query queue. Constants
   remain IPC 1500 ms, process query 5000 ms, capture delay 50 ms, Coordinator
   offline retirement 5000 ms, query queue limit 16 and pending maintenance
   limit 1. Bridge timeout was not changed.

## Findings

### F1 — FOLLOW-UP / adjacent fixture must migrate to async contracts

`com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs:112` still injects
`getProcessEvidenceSync`, while the extracted production function now calls
`getProcessEvidence`. Lines 142-164 also call `prepareOperationChildEvidence`
and `recordChildEvidence` without awaiting them, and use `assert.throws` on
functions that now return rejected promises. The `--s32-disposition-fixture`
branch can no longer exercise the intended identity failure/live/unknown
admission cases correctly.

A read-only in-memory VM check of the original extracted `recordChildEvidence`
with the fixture's existing stub reproduced both `getProcessEvidence is not
defined` as a rejected promise and `Missing expected exception` from the
fixture's synchronous assertion style. No fixture files or runtime children
were created for this check.

This does not demonstrate a production user-path failure. It is a directly
adjacent test maintenance issue and limits regression evidence. If repaired,
limit the change to the renamed async stub, await calls and assert.rejects for
these existing scenarios; no new audit or historical recovery scope is needed.

## Checks and limits

- `node --check com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`: PASS.
- `git diff --check` for Supervisor and Bridge: PASS.
- Read-only source assertions for direct status snapshot, absent old sync
  identity symbol, async Windows lookup and awaited production admission:
  PASS.
- In-memory reproduction of F1 using extracted production code: CONFIRMED.
- The Coder's existing focused harness attempt stopped at the package fixture
  precondition (`Selected stable wrapper does not match the Package-declared
  runtime identity.`), before exercising this repair. That environment block
  was not repaired or retried in this review.
- No full harness, live status latency, slow Coordinator/PowerShell runtime,
  Unity, Install/Uninstall, package export, reference switch or commit was run.

The broader separation of periodic observation from reconcile/removal
preflight, Manager uncertainty copy, CleanupMono, logging and historical
recovery remain outside this narrow snapshot. No claim is made that the
reported 3-5 minute incident is fully reproduced or eliminated.

## F1 focused re-review — 2026-10-19

F1 CLOSED. Overall result remains PASS_WITH_LIMITS for the narrow S37 source
snapshot and producer-only evidence; no open finding remains from this review.

The test-file diff changes only the existing `--s32-disposition-fixture`
branch: the renamed `getProcessEvidence` stub and executable lookup stub are
async, all affected successful admission/evidence calls are awaited, and all
affected rejection assertions use awaited `assert.rejects`. Existing cases,
expected outcomes, extraction logic and fixture path policy are unchanged.
No production source was changed by this repair.

Rehashed current snapshot:

- Production SHA-256 (unchanged):
  `63537CF98AD82C37077FC4C312C7521DBBBAA61CCBC02C69A477AF45D8FED1F1`.
- Test SHA-256:
  `230754F6F4C7C16EC90B08869F66AD631698F93AAB4F17AF052F4C1200C22208`.
- Scoped test-file `git diff --check`: PASS.

The parent reports one successful producer-only run under
`node --unhandled-rejections=strict`, exit 0, recorded in RESULT.md. This
re-review did not rerun it. The existing generated evidence under
`.artifacts/tests/s32-install/s37-f1-efc7f69ee88a46eba6148f9acf0e8938/run/`
was read and its manifest/case operation IDs, project/runtime binding and
owned-directory containment were checked: PASS. The seven existing records
are ready-no-child, legacy-missing, capture-failed, identified-child,
second-capture-missing, no-child-conflict and hidden-running. Their recorded
dispositions/results match their existing fixture construction; conflict and
hidden-running remain intentional consumer inputs, not claimed successes.

The generated fixture does not capture a source hash or process exit code
itself; run attribution uses the parent's recorded command result, RESULT.md,
the current frozen hashes and the matching owned case manifest. No new PID
reuse, live Windows identity, latency or Unity result is inferred from these
mocked process-evidence scenarios. The earlier full-harness fixture identity
block and all previously stated runtime/delivery limits remain unchanged.

Review stopped after closure of F1 and its direct regression check. No source
repair, full-harness retry, Unity, real lifecycle or delivery operation was
performed during this re-review.

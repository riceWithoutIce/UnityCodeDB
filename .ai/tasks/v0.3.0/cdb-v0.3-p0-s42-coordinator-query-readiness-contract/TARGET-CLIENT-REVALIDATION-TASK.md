# S42 reopened target-client bounded revalidation

Status: FUNCTIONAL_PASS_REPORTED; see TARGET-CLIENT-REVALIDATION-RESULT.md.
This is a handoff for the human to the existing
CodedbTest_2 chat. Preparation does not dispatch a message or invoke CodeDB here.
Human forwarding this task with an execution instruction authorizes the following
single bounded attempt. Earlier S39/S40/S41 calls are not resumed or retried.

## Preconditions and binding

Execute in the actual external CodedbTest_2 Unity project root. Record actual cwd
and only a host-explicit current chat ID if provided; never scan/guess one.
Human has reported Unity open, no errors and Manager Ready after a timeout.

Read only target manifest/lock, project .codex/config.toml, selected pointer and
its instance manifest, and the existing original query probe. Confirm:

- Both CodeDB references: file:../../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb.
- Registration: codedb-codedbtest-2, command node, cwd equal to this project root
  (its generated absolute value is allowed), args
  ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."], timeout 120.
- project_identity: sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c.
- instance_id: a492a5e936c14e4da3ed7e4cc7c8c16c.
- pointer activation_epoch: 063aa347f49a4b9f955a5447f293a0ac.
- generation poc.44, Package 0.3.0-preview.5, instance state READY.
- pointer SHA-256: 1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a.
- instance manifest SHA-256: 61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced,
  matching the pointer's manifest hash.
- generation manifest SHA-256: f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb.
- Original Assets/CodeDBValidation/CodeDBQueryProbe.cs SHA-256:
  d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432.
  Line 5 contains public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";.

Require exact target namespace mcp__codedb_codedbtest_2__* in the current tool
catalog. No substitute namespace or manually started protocol client. Stop on
precondition mismatch or unavailable tools; report zero calls and the actual
blocker. Do not impose missing formal response identity as a new functional
precondition: record it separately, as in prior acceptance.

## Calls: maximum one each, no retry

1. Call mcp__codedb_codedbtest_2__codedb_status({}) exactly once. Preserve full
   original response. Require success, compatible ready status, expected Package,
   generation and generation manifest, with no explicit conflicting instance
   identity. STARTING, error, stale/degraded/offline or conflicting baseline ends
   the attempt; do not wait, refresh, reconnect or call another status.
2. Only if step 1 passes, call target codedb_text_search once:
   {"query":"CODEDB_S39_CWD_POC44_TEST2","path_glob":"Assets/CodeDBValidation/CodeDBQueryProbe.cs","regex":false,"limit":5}.
   Preserve full original response and require the expected path, line 5 and
   marker text. Errors and zero/wrong hits end the attempt without retry.

Finally reread pointer for byte stability even after a tool error. Report exact
call counts, arguments, original responses, functional result and identity
evidence separately. Formal project_identity / instance_id / activation_epoch
absent in responses are "not provided"; do not substitute path substrings or
disk identity as formal response identity.

No process/lease/log scan, snapshot RPC, Install/Uninstall/Repair/Restart, manual
component start/stop, configuration edit, probe edit/delete or S41 A-to-B action.
No wait for a preferred result. Keep retained S41 A untouched. Stop after the
allowed calls, even on success. This task does not close timeout, heartbeat,
freshness, performance, upgrade or public-release acceptance.

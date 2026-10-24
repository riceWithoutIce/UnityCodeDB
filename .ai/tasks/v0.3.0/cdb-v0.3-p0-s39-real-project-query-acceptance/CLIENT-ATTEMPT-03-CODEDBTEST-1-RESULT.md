# S39 returned Attempt 03 — correct project, initialize connection closed

Date: 2026-10-21. Status: TARGET_TOOL_STARTUP_FAILED / TARGET_CALLS_ZERO /
REAL_CLIENT_QUERY_NOT_EXECUTED / CHILD_CAUSE_UNRESOLVED.

## Report identity and numbering

Two distinct human-returned reports used the same Attempt 03 label. Preserve
both; do not overwrite or silently renumber either:

- Wrong-workspace report: chat `验收 UnityCodeDB S39 新工程`,
  id 01a15c2a-e7c2-75b0-bede-5b82298d77d5, CodedbTest_0.
  Recorded separately in CLIENT-ATTEMPT-03-RESULT.md.
- This correct-workspace report: chat `执行 S39 外部工程验收`,
  id 01a15c2e-25ee-7620-9cad-ade624685b4a, CodedbTest_1.
  App thread listing and read_thread independently corroborate its root,
  commands and final result. No message was sent to either chat.

The prepared Attempt 04 was not dispatched by this parent and is now on hold
pending diagnosis. Do not paste another query instruction merely to repeat
this failure. The numbering ambiguity is resolved by thread identity/root.

## Acceptance report

Target tools mcp__codedb_codedbtest_1__* were absent. Other CodeDB namespaces
were visible but not invoked. Status calls zero, search calls zero; no original
response/hit evidence exists. Query not verified, response identity insufficient.

The client checked project registration, original command/cwd/args/120-second
timeout, manifest/lock reference 237c72d, READY instance, project identity,
epoch, generation/version, pointer/instance/wrapper/sample hashes and activation
runtime contract against CLIENT-ATTEMPT-03-HANDOFF.md's baseline. All matched.
Final pointer SHA-256 remained
06a1afc91f9bea6a15b6d19130a166c5aa2c8926edd976ae36c61cbf7c37af1d.
The marker is locally present on line 5, not an MCP search result.

The client corrected one local package.json relative-base read; this was not
an MCP retry or a project mutation. Config sources beyond the project file
were not checked, and complete effective configuration remains unverified.
Disk authority facts do not substitute for a response identity.

Client diagnostic snapshot at 2026-10-21T01:59:56.8474490Z found only the
baseline bootstrap file (PID 60580, worker_created, Node 24.14.1, worker exit
0/requested wrapper code 0). The pre-existing watcher lease PID 64184 cannot
be attributed to this client. No new attributable MCP lease/bootstrap record
or actual external process exit was observed. No-record is not no-start proof.

## Existing host evidence inspected by development parent

Exact desktop log source:
`<codex-desktop-log-root>/2026/10/21/codex-desktop-66b9cf19-902e-4109-bed0-5f2f09202627-61080-t0-i1-000012-0.log`.

| Line | UTC time | Exact-thread target-server event |
| --- | --- | --- |
| 4948 | 01:58:10.813 | codedb-codedbtest-1 starting |
| 4958 | 01:58:10.987 | codedb-codedbtest-1 failed |
| 5011 | 01:58:12.493 | codedb-codedbtest-1 starting |
| 5012 | 01:58:12.578 | codedb-codedbtest-1 failed |

The two existing startup intervals are 174 ms and 85 ms. Both report the same
error below. The initiator of the second host startup is not independently
attributed; do not treat it as an agent tool-call retry. The returned chat
contains zero target calls and this parent did not request either startup.
Error:

```text
MCP client for `codedb-codedbtest-1` failed to start: MCP startup failed:
handshaking with MCP server failed: connection closed: initialize response:
connection closed: initialize response
```

Retained exact filtered records:
`.artifacts/tests/s39-attempt03-codedbtest1/existing-host-startup.json`.
Only this target server/thread was saved; no unrelated global config/log dump.

This establishes that the host reached target-server startup; the report's
uncertainty about registration loading is narrowed by these additional logs.
Successful initialize/tools listing is not established. The log does not
establish actual spawned Node executable, effective child cwd, stderr or exit
code. The host-startup event itself is not independent proof of successful
OS child creation or executing the wrapper's module body.

A bounded read-only query of the previously used sqlite/logs_2.sqlite found
no rows in this startup window; its latest id has an older timestamp. It adds
no relevant evidence and is not treated as proof that no runtime error exists.
No broad DB search was performed. Official OpenAI Docs MCP-page fetch returned
HTTP 403; no new product/config semantics are claimed from documentation.

Subsequent static analysis located the separate active `<codex-home>/logs_2.sqlite`.
Readonly bounded exact-thread records 98064591/98064593 corroborate initialize
failure and omission for lack of a ready client. The older database's empty
window is not absence of runtime evidence. See CLIENT-STARTUP-STATIC-ANALYSIS.md.

## Disposition and next boundary

Current evidence separates installation availability from actual-host startup:
normal Install generated a diagnostic record, but this failed connection did
not produce an attributable new one. It still cannot distinguish failure to
launch, failure before static imports/root validation, or inability to write
diagnostics. Those remain possibilities, not diagnosed causes.

Do not reinstall, change cwd registration/Node/PATH or relax validation based
on this symptom. Do not broaden logging or install a capture shim implicitly.
The next useful local work is bounded static mapping of the pre-record failure
paths against the missing actual-child evidence; any real startup capture
still needs a separately concrete authorized envelope. No further real-client
attempt is proposed until that evidence gap has a diagnostic plan.

This parent used only existing thread/log/DB evidence and updated task records.
It did not start Unity, Provider, wrapper/probe, real MCP, OS trace, another
chat or process inventory/control; no external project/config was changed.
The deferred Unconfirmed FOLLOW-UP remains independent and uninvestigated.

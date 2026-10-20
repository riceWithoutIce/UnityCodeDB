# S39 client attempt 01 and startup classification

Date: 2026-10-20.
Status: `STOPPED / REAL_CLIENT_QUERY_BLOCKED / INITIALIZE_CONNECTION_CLOSED`.

## Attributable client result

- Chat title: `验收 S39 MCP 查询`.
- Chat ID: `01a158b6-693a-7901-9da3-fda6d8a55490`.
- Turn ID: `01a158b6-7579-7f61-8d08-fb74dffe1bb1`.
- Target cwd: `<external-acceptance-root>/CodedbTest_0`.
- Evidence: human-forwarded terminal report, cross-checked against the completed
  client turn using read_thread. No cross-chat message was sent.
- Target registration `codedb-codedbtest-0` matched the prepared command, cwd,
  args and 120-second startup timeout.
- The exact target tools were absent. Other observable services were
  `codedb-balance` and `codedb-mcp`; neither was used as substitute evidence.
- Target `codedb_status`: 0 calls, no original response.
- Target `codedb_text_search`: 0 calls, no original response.
- Returned path/line/text: unavailable. This is not a query miss.
- Local sample was not read after stopping. The parent's prior sample check
  remains preparation evidence, not a client query.
- Current pointer and instance identity/hash matched the prepared binding;
  pointer text was unchanged during the client's manifest check.
- No response-side project/instance/epoch/generation/version identity was
  obtained. No attributable new MCP lease was established. Disk binding alone
  cannot establish which process would answer.
- Query functionality: unaccepted. Response identity attribution: insufficient.

The client stopped without retries, alternate queries or configuration/source
changes. The parent did not repeat status/query or launch a direct wrapper,
provider or CLI probe.

## Parent read-only classification

The current user config has a matching project entry with trust_level
`trusted`. Only that project entry and selected relevant config keys were
inspected; the full global configuration was not printed. This is a current
on-disk fact, not proof of every effective config layer at the earlier startup.

Official documentation fetched on 2026-10-20 states that trusted projects may
scope MCP registration through `.codex/config.toml`:
<https://developers.openai.com/codex/mcp>.
This supports the configuration contract; it does not prove this host loaded
every setting correctly or identify the server's exit cause.

The inspected original desktop log is
`<codex-desktop-log-root>/2026/10/20/codex-desktop-66b9cf19-902e-4109-bed0-5f2f09202627-61080-t0-i1-091619-0.log`.
It correlates the following startup events to the exact acceptance chat:

```text
line 3104, 2026-10-20T09:48:32.126Z:
server=codedb-codedbtest-0 status=starting
threadId=01a158b6-693a-7901-9da3-fda6d8a55490

line 3116, 2026-10-20T09:48:32.371Z:
server=codedb-codedbtest-0 status=failed
threadId=01a158b6-693a-7901-9da3-fda6d8a55490
error="MCP client for `codedb-codedbtest-0` failed to start: MCP startup failed: handshaking with MCP server failed: connection closed: initialize response: connection closed: initialize response"
```

The same chat has another starting/failed pair at `09:48:35.130Z` /
`09:48:35.301Z` (lines 3166/3173), with the same error. These are pre-existing
host startup records, not additional status/query calls or parent retries.
They do not change the bounded attempt's zero tool-call counts.

Classification: the target registration reached client startup, then the
initialize connection closed. The evidence does not establish a successful
initialize or tools/list, so post-handshake tool injection is not the diagnosed
failure layer. It also does not support treating the registration as entirely
undiscovered, assuming lack of Git caused the failure, or declaring Package
corruption. The desktop records alone do not establish the child executable,
effective startup cwd/environment, process exit code or stderr.

## Route boundary

Install/Ready PASS is retained. S39 real-client acceptance remains BLOCKED.
The external attempt is ended; CLIENT-HANDOFF.md is historical until a new
attempt is explicitly agreed. No new project, Install, registration/global
override, source repair, runtime write, process termination or client retry
is included in this evidence consolidation.

Next User/Planner decision: freeze a bounded startup/initialize diagnosis
envelope, prioritizing existing child stderr, actual startup cwd/Node and the
delivered wrapper's startup dependencies. Any reproduction or later external
retry needs its own named command, bounds and retained evidence. No production
repair is selected from the handshake symptom alone.

# S39 Attempt 02 stopped before target tool calls

Date: 2026-10-20. Status: ATTEMPT_02_STOPPED / REAL_CLIENT_QUERY_BLOCKED /
INITIALIZE_CONNECTION_CLOSED / CHILD_EXIT_CAUSE_UNRESOLVED.

Attributable client chat: `01a15985-a8e4-77b1-a999-6dd631bfff6b`, title
`验收 S39 独立工程查询`, rooted at external CodedbTest_0. The human returned
the stopped result; a read-only read_thread inspection corroborates it.

## Actual acceptance evidence

The client read project `.codex/config.toml` and found registration
codedb-codedbtest-0, command node, cwd '.', expected stable-wrapper args and
startup_timeout_sec 120. The target tools were not exposed. The observed other
CodeDB namespaces were codedb_balance and codedb_mcp; neither was substituted.
User/global configuration sources were not verified and were not dumped.

Target status calls: zero. Target text-search calls: zero. No raw response
exists for either. Query result is NOT_EXECUTED, not a no-hit query result.
No attributable new MCP lease or target response established response identity.

The client reports all disk bindings match the frozen attempt:

- selected instance `2414c73c2fbb47f4b664c1bdbcad5969`, activation epoch
  `4ad2120d1559487f8e54c015685496f6`, generation poc.43, preview.5, state READY;
- pointer SHA-256 b28c7e8c1268bd06b5c58b1f8a16c1470701b0d06602ed2685b1d5b74db8e00c
  unchanged through its final observation;
- instance SHA-256 dd1244b1660a26b102867035cb85525d7e124b0c72ae0c55e18868eeab8b423e;
- restored helper SHA-256 de2366310169830738ceef4cba4d24e2b54da72f6a8a11ec8c564b4dc298d07f;
- manifest/lock select file:../../Packages/c07bb59/com.rice.ai-codedb;
- local sample Assets/CodeDBAcceptance/S39QueryProbe.cs, marker line 5,
  SHA-256 76442fb3d5d7c950f8836f152bfd273c9b9a00c06d1d287eba036dc6e5d23842.

These are filesystem evidence, not target MCP response identity or query PASS.

## Existing host startup evidence

Desktop log:
`<codex-desktop-log-root>/2026/10/20/codex-desktop-66b9cf19-902e-4109-bed0-5f2f09202627-61080-t0-i1-091619-0.log`.
Exact target server/thread records:

- line 13743, 13:34:54.311Z: codedb-codedbtest-0 starting.
- line 13750, 13:34:54.413Z: failed, 102 ms after starting.
- line 13814, 13:34:56.518Z: another existing host startup record.
- line 13817, 13:34:56.673Z: failed, 155 ms later.

Both failures report:

```text
MCP client for `codedb-codedbtest-0` failed to start: MCP startup failed:
handshaking with MCP server failed: connection closed: initialize response:
connection closed: initialize response
```

These pre-existing host records do not add target tool-call attempts and were
not produced by a parent retry. The target registration reached startup; a
successful initialize/tools-list is not established. The observed barrier is
before exposure of a ready target tool client.

Read-only SELECTs of the existing Codex log databases, limited to this startup
time window, found an additional exact-thread runtime refresh failure in
`<codex-home>/sqlite/logs_2.sqlite`, logs.id 97785483, target codex_mcp::rmcp_client.
It repeats the initialize connection-closed error. No target child stderr,
exit code, actual effective cwd or executable was found in those bounded
records. The DB connections were opened readonly; no config/database mutation.

Current shell resolves two Node binaries, versions 24.14.1 and 24.19.0; that is
shell evidence and does not establish which executable the failed host used.
The registered cwd remains relative. No cause is inferred from that alone.
Official documentation retrieval was attempted but returned HTTP 403; this
diagnosis makes no new documentation-derived configuration claim.

## Next boundary

The previously diagnosed missing helper is restored and byte-authenticated.
This repeated handshake symptom alone does not prove that defect remains, a
new Package defect, wrong cwd, unsupported Node or a tools-catalog defect.
Do not change registration or reinstall speculatively.

The next concrete proposal is HOST-STARTUP-CAPTURE-PLAN.md: one explicitly
authorized actual-host startup capture, no tool calls, preserving actual cwd,
Node and original wrapper args; temporary registration and normal lease side
effects require approval. No capture shim was executed or installed, no new
chat was created/messaged, no MCP call or production command was run in this
diagnosis. Source and external project remain unchanged; only S39 records and
an inert repository-local diagnostic script were prepared.

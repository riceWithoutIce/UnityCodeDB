# S40 post-reinstall target-client result

Date: 2026-10-22 (user local date).
Status: TARGET TOOLS/STATUS PASS; REAL QUERY PASS; COMPLETE RESPONSE IDENTITY
UNESTABLISHED. The bounded functional gate stops here.

## Provenance and functional outcome

The user transferred the target CodedbTest_2 chat's complete report and original
response text. The development chat consumed and archived it; it did not make
these calls, inspect the target chat's logs or infer its unavailable session ID.

Reported cwd, project registration and both 186aacf Package references matched
CLIENT-POST-REINSTALL-TASK.md. Six exact `mcp__codedb_codedbtest_2__*` tools
were exposed: context, find, read, search, status and text_search. Calls:
status=1, text_search=1, other project tools=0. No retry, reconnect, component
start or file/configuration modification was reported. The target chat stopped.

The status isError=false response reported wrapper ready, lifecycle READY and
watch coordinator ready; Package, generation and generation manifest matched
the frozen baseline. No explicit old-instance response conflict was reported.

The exact marker/path_glob query (regex=false, limit=5) returned isError=false
and one Provider hit at `Assets/CodeDBValidation/CodeDBQueryProbe.cs:5`:

```csharp
    public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";
```

Path, line and text matched the local sample. Reported sample SHA-256 matched
`d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.
Reported pointer SHA-256 before/after was unchanged:
`1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.

This supports the observed normal reinstall -> new target-client startup ->
usable status -> actual C# retrieval flow for this delivered candidate.
Stored timings are single-call observations, not performance acceptance or
speedup evidence against S39 or another run.

## Identity and unclosed coverage

Reported disk bindings matched new instance
`a492a5e936c14e4da3ed7e4cc7c8c16c`, epoch
`063aa347f49a4b9f955a5447f293a0ac` and frozen project/manifest values. The
status wrapper suffix and Active provider config path associate the response
with the new instance. Neither response supplied formal project_identity,
instance_id or activation_epoch fields. Attributable host connection identity
was unavailable; the target chat did not inspect processes, leases or logs.

Full response/session identity remains unestablished. Do not fill missing
response fields with disk values. Under the frozen task this limitation does
not reverse functional PASS or require another status/query call.

The human Install terminal and new instance selection already passed with
cleanup PENDING (HUMAN-ACCEPTANCE.md). No pre-Install live-old-MCP snapshot was
captured, and post-action observations did not establish a matching live old
holder. This report does not close that regression in the real environment;
its isolated harness/review evidence remains a separate evidence class.

Physical cleanup after lease drain, second real lifecycle cycle, PS7
compatibility, Unconfirmed UX, upgrade, performance and public release are
outside this gate. Do not automatically start additional queries, audit,
lifecycle testing or identity protocol changes to fill those gaps.

## Canonical retained evidence

`<repository-root>/.artifacts/tests/s40-retained-mcp-install/client-post-reinstall-result-a/reported-responses.json`
preserves the user-transferred response blocks, arguments, call counts, disk
identity and missing-field classification. It is a report archive, not a new
development-chat tool receipt. Keep prior evidence unchanged.

# CodedbTest_2: bounded real C# text-hit query result

Date: 2026-10-21. Status: REAL_CSHARP_HIT_QUERY_PASS / BOUNDED_GATE_COMPLETE.

Evidence provenance: user-transferred target-chat report and complete raw MCP
response. The development chat did not execute or repeat this call. The report
explicitly confirms a single real hit matching the local sample path, line 5
and marker content. The response supplies all three match coordinates/content;
line display indentation is formatter output, not a byte-for-byte file payload.

Reported calls: text-search=1, additional status=0, other CodeDB=0. No retry;
the target stopped. isError=false and no host failure reported.
Provider route is coordinator with one Provider attempt. Timing is retained as
raw diagnostics, not a controlled performance or representative speed result.

Complete transferred response:

```json
{"content":[{"type":"text","text":"[OK] codedb_text_search found 1 unique hit(s) for: CODEDB_S39_CWD_POC44_TEST2\n[HIT] Assets/CodeDBValidation/CodeDBQueryProbe.cs:5 [provider]\n    public const string Marker = \"CODEDB_S39_CWD_POC44_TEST2\";\n[TIMING] {\"schema_version\":1,\"tool\":\"codedb_text_search\",\"total_ms\":265.9,\"queue_ms\":0.07,\"provider_process_ms\":1.99,\"provider_core_ms\":null,\"adapter_ms\":0,\"merge_ms\":0.21,\"read_ms\":0,\"provider_attempts\":1,\"provider_route\":\"coordinator\",\"provider_shared\":false,\"output_bytes\":203}"}],"isError":false}
```

Sample baseline: `Assets/CodeDBValidation/CodeDBQueryProbe.cs`, SHA-256
`d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.
Marker: `CODEDB_S39_CWD_POC44_TEST2`, local line 5. No alternate query or local
read is substituted for the actual returned Provider hit.

The response provides no independent project_identity, instance_id or
activation_epoch fields. Prior local baseline checks and matching hits do not
invent those fields or establish complete chat/lease attribution. This is a
functional hit-query PASS under the agreed task, separate from that limitation.

No further query, status, diagnostics sweep, index operation or sample cleanup
is part of this result. Keep the sample as acceptance evidence. Older failed
attempts remain closed; do not reinterpret them as passed or erase them.

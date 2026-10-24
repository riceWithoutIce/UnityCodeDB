# CodedbTest_2: client startup/status result

Date: 2026-10-21. Status: CLIENT_STARTUP_STATUS_PASS /
COMPLETE_RESPONSE_IDENTITY_NOT_PROVIDED / HIT_QUERY_NOT_EXECUTED.

Evidence provenance: the user transferred the target chat's report and complete
raw response into the development chat. This development chat did not observe
or repeat that MCP call. No system-provided chat ID was available in the report;
do not invent a chat identifier or attribute a disk lease to that chat.

The target reported the correct CodedbTest_2 cwd, matching project registration
and selected pointer baseline, with no identity conflict. The exact namespace
exposed all six expected tools: codedb_context, codedb_find, codedb_read,
codedb_search, codedb_status and codedb_text_search under
`mcp__codedb_codedbtest_2__`.

Reported calls: codedb_status({}) = 1, query = 0, other CodeDB = 0.
The single response has isError=false, no host-supplied failure, Package version
0.3.0-preview.5, selected generation poc.44, sequence 44, bootstrap 1 and matching
generation manifest
`f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`.
It reports coordinator ready, automatic refresh active, lifecycle READY, Provider
index present and zero Shader adapter files/lines. This is a status observation,
not a Provider text-hit result or controlled performance measurement.

The response does not independently provide project_identity, instance_id or
activation_epoch fields. A wrapper display name or instance string embedded in
a config path does not replace those fields. Full session/lease attribution
remains unestablished; missing response fields do not invalidate the narrower
startup/status gate agreed in the task.

Complete transferred response:

```json
{"content":[{"type":"text","text":"[OK] codedb-codedbtest-2-fe3b2578 wrapper ready.\nPackage version: 0.3.0-preview.5\nSelected generation: poc.44\nPayload sequence: 44\nBootstrap protocol: 1\nGeneration manifest: f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb\nLegacy sessions: 0\nUnity root: .\nProvider executable: present\nProvider config: present\nPolicy state: enabled\nManual runtime: none\nDesired state: enabled\nEditor demand: online\nAutomatic refresh: active\nLifecycle reason: READY\nWatch config: present\nWatch coordinator: ready\nWatcher generation: poc.44 (current)\nShader watcher: watching\nActive provider config: AIWork/.runtime/codedb/instances/fe3b257859f34023a9e290db3b2ad457/config/codedb-mcp.watch.toml\nProvider index: present\nShader adapter manifest: present\nTool profile: Discover Read only\nShader adapter files: 0\nShader adapter lines: 0\n[TIMING] {\"schema_version\":1,\"tool\":\"codedb_status\",\"total_ms\":24.12,\"queue_ms\":0,\"provider_process_ms\":0,\"provider_core_ms\":null,\"adapter_ms\":0,\"merge_ms\":0,\"read_ms\":0,\"provider_attempts\":0,\"provider_route\":\"none\",\"provider_shared\":false,\"output_bytes\":829}"}],"isError":false}
```

The target report states no config/source modification, install, repair, retry,
manual start or process stop, and it stopped after the agreed call. Earlier
failed attempts were not resumed. This report supports the project-derived
absolute-cwd fix in the normal new-project install/client flow; it does not
retrospectively prove the historical failed child's effective cwd or establish
universal compatibility, old-project migration or release acceptance.

Next gate: prepare a small project-owned C# marker sample and one bounded real
text-hit query through the exact target namespace. That sample/query step has
not executed. No additional status call is implied by recording this result.

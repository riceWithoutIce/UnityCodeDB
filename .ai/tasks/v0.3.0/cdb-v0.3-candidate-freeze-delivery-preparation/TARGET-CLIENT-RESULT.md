# 1105696 target client result — 2026-10-26

Outcome: `FUNCTIONAL_PASS / ON_DISK_BINDING_PASS / RESPONSE_IDENTITY_LIMITED`.
Evidence source: user-forwarded completion report from the existing external
CodedbTest_2 chat. Development session archives it without MCP reruns, chat
inspection or reconstructed tool envelopes. The original response text supplied
by the user appears below; isError=false was separately reported for each call.
Paths are relative to `<external-test-root>/CodedbTest_2` unless indicated.

## Result and preflight (reported)

- Actual cwd: the designated external CodedbTest_2 Unity project root; Assets,
  Packages and ProjectSettings present. Host chat ID: not provided.
- Exact target status/text_search tools visible in
  `mcp__codedb_codedbtest_2__*`; no substitute services used.
- Both manifest/lock references:
  `file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`,
  resolving to `<external-test-root>/Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
- Package 0.3.0-preview.5; Package LifecycleEvidence SHA-256
  `e939c8d8163ede9ca4a372a608fc5d7c66e24d83d230438e71db496048ea865e`.
- Registration namespace, node, cwd, args and startup timeout 120 matched.
- Pointer SHA-256
  `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.
- Instance SHA-256
  `61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced`;
  READY / poc.44. Pointer/instance identity checks passed the task baseline.
- Probe SHA-256
  `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`;
  exact marker at line 5.
- Target status=1, text_search=1, other MCP=0, retries=0.
- Final pointer remained 611 bytes and retained the initial SHA-256: PASS.

## Supplied status response

UTC: 2026-10-26T02:01:57.068Z → 2026-10-26T02:01:57.113Z.
Parameters: `{}`. Reported isError=false. Status functionality: PASS.

```text
[OK] codedb-codedbtest-2-a492a5e9 wrapper ready.
Package version: 0.3.0-preview.5
Selected generation: poc.44
Payload sequence: 44
Bootstrap protocol: 1
Generation manifest: f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb
Legacy sessions: 0
Unity root: .
Provider executable: present
Provider config: present
Policy state: enabled
Manual runtime: none
Desired state: enabled
Editor demand: online
Automatic refresh: active
Lifecycle reason: READY
Watch config: present
Watch coordinator: ready
Watcher generation: poc.44 (current)
Shader watcher: watching
Active provider config: AIWork/.runtime/codedb/instances/a492a5e936c14e4da3ed7e4cc7c8c16c/config/codedb-mcp.watch.toml
Provider index: present
Shader adapter manifest: present
Tool profile: Discover Read only
Shader adapter files: 0
Shader adapter lines: 0
[TIMING] {"schema_version":1,"tool":"codedb_status","total_ms":27.97,"queue_ms":0,"provider_process_ms":0,"provider_core_ms":null,"adapter_ms":0,"merge_ms":0,"read_ms":0,"provider_attempts":0,"provider_route":"none","provider_shared":false,"output_bytes":829}
```

## Supplied query response

UTC: 2026-10-26T02:02:01.423Z → 2026-10-26T02:02:01.455Z.
Reported isError=false. Query functionality: PASS; exactly one matching hit.

Parameters:

```json
{"query":"CODEDB_S39_CWD_POC44_TEST2","path_glob":"Assets/CodeDBValidation/CodeDBQueryProbe.cs","regex":false,"limit":5}
```

Original text:

```text
[OK] codedb_text_search found 1 unique hit(s) for: CODEDB_S39_CWD_POC44_TEST2
[HIT] Assets/CodeDBValidation/CodeDBQueryProbe.cs:5 [provider]
    public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";
[TIMING] {"schema_version":1,"tool":"codedb_text_search","total_ms":16.07,"queue_ms":0.25,"provider_process_ms":8.22,"provider_core_ms":null,"adapter_ms":0,"merge_ms":0.22,"read_ms":0,"provider_attempts":1,"provider_route":"coordinator","provider_shared":false,"output_bytes":203}
```

## Attribution and stopping boundary

| Formal response field | status | text_search |
| --- | --- | --- |
| project_identity | not provided | not provided |
| instance_id | not provided | not provided |
| activation_epoch | not provided | not provided |

Do not replace these fields with wrapper names, config paths or disk identity.
The observed functionality and on-disk candidate binding pass separately from
the LIMITED response attribution. Missing fields do not invalidate this bounded
functional result, nor do functional results supply those missing fields.

Attempt is complete and stopped. It does not establish a new connection,
loaded Editor code, default F01 log/sidecar suppression, long-term stability,
performance, complete candidate lifecycle, upgrade or release acceptance.
No further calls, scans, observer, installation, file modification or repair
is authorized by this completion report. No commit/push in receipt intake.

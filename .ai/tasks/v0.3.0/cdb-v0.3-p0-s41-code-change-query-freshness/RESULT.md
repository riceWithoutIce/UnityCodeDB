# S41 code-change query freshness: first observation result

Date: 2026-10-22. Status: PARTIAL / STOPPED.
Functional outcome: NOT_ESTABLISHED, because A baseline was not established.

## Evidence attribution and scope

Source: the human transferred the CodedbTest_2 session's complete bounded report
into the development chat. These are target-session reported observations;
the development session did not repeat the calls or independently observe the
target's runtime. Host-attributed session ID was not provided.

Reported cwd was `<test-projects>/CodedbTest_2`, the required Unity root.
Human confirmed Unity open, Manager Ready and no compilation errors. The exact
target text_search tool was visible. The target session created A once, did
not write B, called target text_search once, and made zero status or other
CodeDB calls. It stopped on the first tool error, without retries, refresh,
reconnect, repair, cleanup or substitute probes. L0, affected L1 and EditMode
were NOT_RUN.

Preflight matched the frozen TASK's Package reference, registration and selected
identity. The generated absolute registration cwd resolved to this project.
Package was 0.3.0-preview.5 / poc.44, instance READY on disk. Disk identity:

| Field | Reported value |
| --- | --- |
| project_identity | `sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c` |
| instance_id | `a492a5e936c14e4da3ed7e4cc7c8c16c` |
| activation_epoch, pointer | `063aa347f49a4b9f955a5447f293a0ac` |
| instance manifest SHA-256 | `61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced` |

## Sample and timeline

New file `Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs` was absent at
preflight, then created as UTF-8 without BOM, LF, 167 bytes:

```csharp
namespace CodeDBValidation
{
    internal static class CodeDBFreshnessProbeS41
    {
        internal const string Marker = "CODEDB_S41_FRESHNESS_A_20261022";
    }
}
```

All timestamps below are UTC, reported by the target session:

| Event | Time or interval |
| --- | --- |
| A save complete | `2026-10-22T03:10:11.2073833Z` |
| Sole wait start | `2026-10-22T03:10:11.2397475Z` |
| Sole wait end | `2026-10-22T03:10:26.2428923Z` |
| Actual wait | `15003.1448 ms` |
| Query start | `2026-10-22T03:10:35.896Z` |
| Save to query start including scheduling | approximately `24.689 s` |
| Query end | `2026-10-22T03:10:35.926Z` |
| Host call duration | `30 ms` |
| Final checks | `2026-10-22T03:10:51.3004350Z` |

## Sole call and original response

Target tool: `mcp__codedb_codedbtest_2__codedb_text_search`.

```json
{"query":"CODEDB_S41_FRESHNESS_A_20261022","path_glob":"Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs","regex":false,"limit":5}
```

Complete transferred original response:

```json
{
  "content": [
    {
      "type": "text",
      "text": "tool call error: tool call failed for `codedb-codedbtest-2/codedb_text_search`\n\nCaused by:\n    Mcp error: -32000: [STARTING] CodeDB is enabled and the Unity Editor is online, but the backend is not ready yet.\n    [TIMING] {\"schema_version\":1,\"tool\":\"codedb_text_search\",\"total_ms\":19.77,\"queue_ms\":0,\"provider_process_ms\":0,\"provider_core_ms\":null,\"adapter_ms\":0,\"merge_ms\":0,\"read_ms\":0,\"provider_attempts\":0,\"provider_route\":\"none\",\"provider_shared\":false,\"output_bytes\":94}"
    }
  ],
  "isError": true
}
```

## Outcome and preserved state

| Criterion | Result |
| --- | --- |
| A baseline | NOT_ESTABLISHED: `-32000 / [STARTING]` tool error |
| A-to-B edit | NOT_RUN |
| B hit / post-edit A absence | NOT_RUN / NOT_RUN |
| Pointer stability | PASS, reported starting/final hashes equal |
| Protected old sample stability | PASS, reported starting/final hashes equal |

Reported final SHA-256 values:

- A sample, equal to saved A:
  `2827d0f71db580099a13daad9c301407adeed331c8e4d0aa5413dfcebe2ce11c`.
- Selected pointer, unchanged:
  `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.
- Protected original sample, unchanged:
  `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.

The new sample remains A. It and any Unity-generated `.meta` were not removed
or restored. Retention is PROTECTED as the input of this unresolved observation;
review disposition after diagnosis/next-route alignment. Do not overwrite it
by replaying the TASK, whose absent-file precondition is now false.

## Interpretation and next-route boundary

The response reports no Provider attempt and no Provider route. This query
failed at the wrapper readiness/admission boundary before Provider execution;
it is not a NO HIT, explicit STALE, or old-content result. It cannot prove or
disprove source-edit indexing and cannot establish a freshness SLA violation.

Manager Ready was human-observed at the starting point, not captured as a
simultaneous authority snapshot at query time. The later STARTING response
shows this call was unavailable; it does not alone prove stale UI, identify a
failed readiness predicate, or connect the event causally to sample creation,
compilation/Domain Reload, the deferred identity/heartbeat issue, or earlier
reopen warnings. Pointer stability does not prove unchanged runtime readiness.

Formal MCP response project_identity / instance_id / activation_epoch were
not provided. Disk values do not fill those fields. No process/lease/native-log
diagnosis was performed. Prior S40 functional PASS is preserved at its original
scope; complete runtime, performance, freshness and release gates remain open.

Recommended next alignment: a narrow read-only readiness-admission diagnosis
using the already observed STARTING branch, then only the minimum existing safe
evidence needed to distinguish its failed conditions. Do not resume the broad
identity/heartbeat investigation or rerun S41 automatically. Any expanded read
closure, new runtime observation or repair must be aligned first. Never dump
whole runtime state containing credentials/tokens.

## Handoff

- Current task: cdb-v0.3-p0-s41-code-change-query-freshness.
- Current status: PARTIAL / STOPPED; A baseline NOT_ESTABLISHED.
- Next notification: human / current UnityCodeDB development session.
- Next action: align the narrow readiness diagnosis before another observation;
  retain the A sample and first-failure evidence.
- Human decision or authorization required: YES for expanded diagnosis, a fresh
  attempt, repair or cleanup. No further runtime action is active.

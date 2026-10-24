# S41 retained-A-to-B observation result

Status: STOPPED_EXECUTOR_SYNTAX_ERROR_BEFORE_WRITE.
Evidence source: human-forwarded target chat report, recorded 2026-10-22.
This development chat did not repeat calls or inspect the consumer in this step.
The original RESULT.md remains unchanged; this is the later fresh attempt.

Actual cwd reported: external CodedbTest_2 root. Target namespace reported:
mcp__codedb_codedbtest_2__*. Human starting-state provenance was the task's
Unity-open / no-error / Manager-Ready report, not an independent current check.

## A baseline PASS

Exactly one target text_search call with arguments:
{"query":"CODEDB_S41_FRESHNESS_A_20261022","path_glob":"Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs","regex":false,"limit":5}.

Forwarded original response text (no full MCP envelope supplied):

```text
[OK] codedb_text_search found 1 unique hit(s) for: CODEDB_S41_FRESHNESS_A_20261022
[HIT] Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs:5 [provider]
    internal const string Marker = "CODEDB_S41_FRESHNESS_A_20261022";
[TIMING] {"schema_version":1,"tool":"codedb_text_search","total_ms":9.27,"queue_ms":0.07,"provider_process_ms":1.43,"provider_core_ms":null,"adapter_ms":0,"merge_ms":0.14,"read_ms":0,"provider_attempts":1,"provider_route":"coordinator","provider_shared":false,"output_bytes":222}
```

## First anomaly and retained effects

The sole attempted modification command returned PowerShell parser error
"Missing ')' in method call". Reported to occur before writing. The exact failed
command was not forwarded; its quoting/construction cause has not been inspected.
No successful file write, wait, B query or post-edit A absence query occurred.
Retry count 0; no rollback. No B save time, B hash or save-to-call interval exists.

Reported terminal probe remains A, SHA-256:
2827d0f71db580099a13daad9c301407adeed331c8e4d0aa5413dfcebe2ce11c.
Pointer reported stable, SHA-256:
1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a.

The forwarded protected-original-probe hash is only 63 hex characters:
d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d343.
This is not a complete SHA-256 representation. Although stability was reported,
exact hash agreement is NOT_VERIFIED from this summary. Do not infer consumer
file mutation or silently append the missing character. Established expected
hash remains d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432;
a later authorized preflight should verify the actual file.

## Assessment

A baseline PASS; A-to-B update NOT_RUN; B hit / old-A absence NOT_RUN.
The observed interruption belongs to the executor command layer, before any
source update. It neither proves nor disproves CodeDB edit freshness and is not
a recurrence of the original STARTING response. The old failed attempt remains
preserved; current fixed-query and service-shape PASS results remain unchanged.

Recommended preparation before a new attempt: prepare a file-based edit helper
and syntax-check it without executing against the consumer, avoiding complex
inline shell quoting. Then freeze a fresh attempt starting from retained A,
including actual protected-probe hash verification and a new A baseline query.
No retry of this consumed grant, source edit, new query or recovery is authorized
merely by recording this result. Do not skip baseline or resume at the B write.

Subsequent separately authorized preparation verified current complete protected
probe hash matches baseline and checked a file-based helper offline. See
EDIT-HELPER-CHECK-RESULT.md. Earlier failure and its original report are preserved.

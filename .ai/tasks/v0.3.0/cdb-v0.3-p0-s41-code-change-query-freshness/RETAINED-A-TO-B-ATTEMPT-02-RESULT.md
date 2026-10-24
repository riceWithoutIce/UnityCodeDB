# S41 retained A-to-B attempt 02 result

Status: PASS_RECORDED_A_TO_B_OBSERVATION.
First anomaly: NONE. This bounded authorized attempt is complete and consumed.
Earlier stopped attempts and their evidence are unchanged.

## Authority and execution context

Executed under the human's explicit instruction forwarding RETAINED-A-TO-B-ATTEMPT-02-TASK.md.
The historical RETAINED-A-TO-B-TASK.md supplied only its field/call/stop contract.
No original absent-file/create-A sequence was run.

Actual cwd: `G:\RiceProgram\Test\CodedbTest\CodedbTest_2`.
Current chat ID: NOT_PROVIDED_BY_HOST; not inferred.
Unity starting-state provenance: the approved task records human-open Unity,
no errors and Manager Ready. No newer conflicting human feedback arrived.
No Unity/status/process inspection was used to independently verify that state.

Exact namespace: `mcp__codedb_codedbtest_2__codedb_text_search`.
No alternative namespace or manual CodeDB CLI was used.

## Preconditions

All required preconditions matched before the first query:

- Both target Package references: `file:../../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb`.
- Project registration: `codedb-codedbtest-2`, command `node`,
  cwd resolves to the actual project above, args
  `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]`,
  startup timeout 120 seconds.
- project_identity: `sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c`.
- instance_id: `a492a5e936c14e4da3ed7e4cc7c8c16c`.
- activation_epoch from selected pointer: `063aa347f49a4b9f955a5447f293a0ac`.
- generation `poc.44`, Package `0.3.0-preview.5`, instance `READY`.
- Selected pointer SHA-256:
  `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.
- Referenced instance manifest SHA-256:
  `61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced`, matching the pointer.
  No activation_epoch inside instance.json was required.
- Retained A SHA-256:
  `2827d0f71db580099a13daad9c301407adeed331c8e4d0aa5413dfcebe2ce11c`.
  Its unique A marker occupied line 5. Exact starting bytes were retained
  in memory, then reread and compared byte-for-byte before the helper.
- Protected original probe SHA-256:
  `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.
- Checked helper SHA-256, verified immediately before direct Node invocation:
  `2ef26660c75e10d5d0973cdbfeba393702c5cd6b5447272a58d0fafe33d0ac24`.

Retained A's original creation/save time was not supplied and is not invented.
Preflight capture UTC: `2026-10-22T07:11:04.4241234Z`.

## Counts and outcomes

| Item | Actual |
| --- | --- |
| Target text_search | 3, sequential |
| Status / other CodeDB | 0 / 0 |
| Helper --apply / source saves | 1 / 1 |
| Requested 15-second waits | 1 |
| Retries / recovery / .meta edits | 0 / 0 / 0 |
| A baseline | PASS, unique correct line-5 hit |
| B checkpoint | PASS, unique correct line-5 hit |
| Old A absence | PASS, successful zero hits; isError=false |
| Final exact B bytes | PASS |
| Selected pointer / protected probe stability | PASS / PASS |

No explicit STALE, STARTING, wrong hit, tool error or host error was returned.
The old-A NO HIT response is the expected successful absence result.

## Edit and timing

Invoked Node directly with the helper path and separate arguments:
`--apply Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs`.
No inline PowerShell replacement expression was used.

Full original helper stdout:

```json
{"mode":"--apply","before_sha256":"2827d0f71db580099a13daad9c301407adeed331c8e4d0aa5413dfcebe2ce11c","expected_b_sha256":"496ebae5e49d4970a938632b289701427e8d93d90572ea64be67650d747c47cc","bytes":167,"writes":1,"saved_at_utc":"2026-10-22T07:11:40.839Z","status":"B_SAVED"}
```

Helper exit code: 0. Actual B hash matched its expected hash:
`496ebae5e49d4970a938632b289701427e8d93d90572ea64be67650d747c47cc`.
The final 167-byte file equals the exact expected A-to-B replacement;
all other bytes and line positions were preserved.

| Event / interval | UTC / elapsed |
| --- | --- |
| A call start / end | 2026-10-22T07:11:14.095Z / 2026-10-22T07:11:14.150Z |
| B completed save, from helper | 2026-10-22T07:11:40.839Z |
| Wait start | 2026-10-22T07:11:52.6270518Z |
| Wait end | 2026-10-22T07:12:07.7626198Z |
| Requested wait / actual stopwatch duration | 15,000 ms / 15130.0241 ms |
| Save to wait start | 11788 ms |
| Wait end to B call start | 6511 ms |
| Save to B call start | 33434 ms |
| B call start / end | 2026-10-22T07:12:14.273Z / 2026-10-22T07:12:14.295Z |
| B response to old-A call start | 10481 ms |
| Old-A call start / end | 2026-10-22T07:12:24.776Z / 2026-10-22T07:12:24.794Z |
| Final capture | 2026-10-22T07:12:48.8409682Z |

UTC-derived intervals are recorded to millisecond precision and include
orchestration/scheduling delays. There was no second deliberate wait, polling
of CodeDB, extension or retry. The shell session completion was collected once
for the single Start-Sleep invocation.

## 1. A_baseline

Arguments, timestamps and full original response (including isError and timing):

```json
{
  "step": "A_baseline",
  "tool": "mcp__codedb_codedbtest_2__codedb_text_search",
  "args": {
    "query": "CODEDB_S41_FRESHNESS_A_20261022",
    "path_glob": "Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs",
    "regex": false,
    "limit": 5
  },
  "call_started_at_utc": "2026-10-22T07:11:14.095Z",
  "call_completed_at_utc": "2026-10-22T07:11:14.150Z",
  "elapsed_ms": 55,
  "raw": {
    "content": [
      {
        "type": "text",
        "text": "[OK] codedb_text_search found 1 unique hit(s) for: CODEDB_S41_FRESHNESS_A_20261022\n[HIT] Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs:5 [provider]\n    internal const string Marker = \"CODEDB_S41_FRESHNESS_A_20261022\";\n[TIMING] {\"schema_version\":1,\"tool\":\"codedb_text_search\",\"total_ms\":31.52,\"queue_ms\":0.11,\"provider_process_ms\":1.49,\"provider_core_ms\":null,\"adapter_ms\":0,\"merge_ms\":0.42,\"read_ms\":0,\"provider_attempts\":1,\"provider_route\":\"coordinator\",\"provider_shared\":false,\"output_bytes\":222}"
      }
    ],
    "isError": false
  }
}
```

## 2. B_checkpoint

Arguments, timestamps and full original response (including isError and timing):

```json
{
  "step": "B_checkpoint",
  "tool": "mcp__codedb_codedbtest_2__codedb_text_search",
  "args": {
    "query": "CODEDB_S41_FRESHNESS_B_20261022",
    "path_glob": "Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs",
    "regex": false,
    "limit": 5
  },
  "call_started_at_utc": "2026-10-22T07:12:14.273Z",
  "call_completed_at_utc": "2026-10-22T07:12:14.295Z",
  "elapsed_ms": 22,
  "raw": {
    "content": [
      {
        "type": "text",
        "text": "[OK] codedb_text_search found 1 unique hit(s) for: CODEDB_S41_FRESHNESS_B_20261022\n[HIT] Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs:5 [provider]\n    internal const string Marker = \"CODEDB_S41_FRESHNESS_B_20261022\";\n[TIMING] {\"schema_version\":1,\"tool\":\"codedb_text_search\",\"total_ms\":8.79,\"queue_ms\":0.04,\"provider_process_ms\":2.25,\"provider_core_ms\":null,\"adapter_ms\":0,\"merge_ms\":0.09,\"read_ms\":0,\"provider_attempts\":1,\"provider_route\":\"coordinator\",\"provider_shared\":false,\"output_bytes\":222}"
      }
    ],
    "isError": false
  }
}
```

## 3. old_A_absence

Arguments, timestamps and full original response (including isError and timing):

```json
{
  "step": "old_A_absence",
  "tool": "mcp__codedb_codedbtest_2__codedb_text_search",
  "args": {
    "query": "CODEDB_S41_FRESHNESS_A_20261022",
    "path_glob": "Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs",
    "regex": false,
    "limit": 5
  },
  "call_started_at_utc": "2026-10-22T07:12:24.776Z",
  "call_completed_at_utc": "2026-10-22T07:12:24.794Z",
  "elapsed_ms": 18,
  "raw": {
    "content": [
      {
        "type": "text",
        "text": "[NO HIT] codedb_text_search found no match for: CODEDB_S41_FRESHNESS_A_20261022\n[TIMING] {\"schema_version\":1,\"tool\":\"codedb_text_search\",\"total_ms\":4.52,\"queue_ms\":0.04,\"provider_process_ms\":0.82,\"provider_core_ms\":null,\"adapter_ms\":0,\"merge_ms\":0,\"read_ms\":0,\"provider_attempts\":1,\"provider_route\":\"coordinator\",\"provider_shared\":false,\"output_bytes\":79}"
      }
    ],
    "isError": false
  }
}
```

## Terminal sample and stability

Only the sample, selected pointer and protected original sample were reread
for finalization. Final sample remains B; no rollback, cleanup or .meta edit.

- Sample `Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs`:
  167 bytes, SHA-256 `496ebae5e49d4970a938632b289701427e8d93d90572ea64be67650d747c47cc`;
  exact expected B bytes and marker at line 5.
- Pointer `AIWork/.runtime/codedb/control/current-instance.json`:
  SHA-256 `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`, unchanged.
- Protected `Assets/CodeDBValidation/CodeDBQueryProbe.cs`:
  SHA-256 `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`, unchanged.

The receipt retains starting/final sample bytes as Base64, the instance
manifest, pointer contents, full query envelopes, helper output and shell
captures. Earlier evidence files were not overwritten.

## Evidence boundary

PASS proves this recorded scoped edit observation: A hit, B hit, old A absence,
correct final sample and stable disk binding/protected sample.
Formal query responses did not provide project_identity, instance_id or
activation_epoch. That identity-evidence gap remains separate from this
functional PASS; on-disk fields are not substituted for response identity.

The B/A queries were sequential, not atomic. This is not evidence of a
convergence instant, 15-second SLA, complete freshness signaling,
heartbeat/timeout repair, performance or release readiness.
No product suite, service command, refresh/reconnect/rebuild, Install/Repair/
Restart, log/process/lease scan, runtime/config change, automated Unity launch,
subagent, external chat message or browser action was performed.

Machine-readable full receipt: RETAINED-A-TO-B-ATTEMPT-02-RECEIPT.json.

## Development-session receipt reconciliation

The development session read this result and the complete receipt, without
rerunning consumer actions. Receipt SHA-256:
7d5a29c727c57fb12f5f8224deace1ab1b8d3849951e4be67b0ba4794e2bc7ed.
Static reconciliation PASS: three successful scoped query envelopes in A/B/A
order, expected line-5 hits and old-A absence, exact recorded A-to-B byte change,
sample hashes, recorded pointer-byte hash, protected-hash equality and 33,434ms
save-to-B-call arithmetic. This verifies consistency of supplied records, not an
independent live re-execution or target connection identity attestation.

Scoped functional acceptance is complete. Retain B and the earlier failure
receipts; no automatic cleanup, extension or new experiment follows this PASS.


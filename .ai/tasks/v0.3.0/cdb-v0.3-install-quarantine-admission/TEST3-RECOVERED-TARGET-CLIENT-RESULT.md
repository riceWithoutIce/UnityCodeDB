# Test3 recovered target-client result

Date: 2026-10-26. Outcome:
`STATUS_PASS / QUERY_PASS / RESPONSE_IDENTITY_LIMITED / PROCESS_DEVIATION`.
This is a bounded real target-client functional result after the first Install
handoff anomaly recovered to Ready. It does not close the handoff Bug or prove
long-term lifecycle stability.

## Execution boundary

Actual cwd was the designated external CodedbTest_3 project. The exact target
namespace was used. Calls were exactly one `codedb_status` and one
`codedb_text_search`; no other CodeDB call, retry, reconnect, process control,
Install/Uninstall action, configuration edit or product source edit occurred.

The target task allowed one new probe source. Human-side execution created
`Assets/CodeDBValidation/CodeDBQueryProbeTest3.cs`, 167 bytes, saved at
`2026-10-26T06:51:37.5356032Z`, SHA-256
`f9b707a53d005cd8e64d8086c5bf40f4b74148db3b0a25d89937fa76a37f34d3`.
The Unity-generated `.meta` was retained. Final selected-pointer SHA-256 was
`563fe18e496dbafb7d829e902f35c4d24d339f5329ed249083391cff3e5816f3`.

## Results

Status succeeded with wrapper ready, Package `0.3.0-preview.5`, generation
`poc.44`, lifecycle `READY`, coordinator `ready`, and the expected generation
manifest. Query succeeded with exactly one provider hit at
`Assets/CodeDBValidation/CodeDBQueryProbeTest3.cs:5`; the complete marker
matched. The reported save-to-query interval was approximately 79.356 seconds;
no freshness SLA claim is made.

Neither response provided formal `project_identity`, `instance_id` or
`activation_epoch`. Response identity is therefore LIMITED; disk binding is
separately PASS. This result demonstrates one usable recovered target-client
status/query path, not a new-connection guarantee or a clean Install handoff.

## Process deviation

The execution record reports a PowerShell argument-parsing prompt during a local
preflight check and a listing that included names under `leases/logs`, without
reading their contents and without process scanning/control. These are workflow
deviations to correct in the next task; they did not appear in either CodeDB
response and are not classified as product runtime failures. No MCP call was
repeated because of them.

## Acceptance boundaries

- Functional status/query: PASS.
- On-disk candidate binding and pointer stability: PASS.
- Formal response identity: LIMITED.
- First Install handoff Bug: OPEN.
- Cleanup scheduling Bug: OPEN / TRIAGE.
- Close/reopen, Uninstall, Fresh Install, second reopen and release gates: NOT
  RUN in this result.

The next lifecycle action requires a separately aligned human procedure. This
record does not authorize Uninstall, Fresh Install, process cleanup, source
repair, commit, push, board synchronization or release.

# S39 Attempt 03 — stopped at workspace preflight

Date: 2026-10-21. Source: human-returned acceptance-chat report.
Status: ATTEMPT_03_STOPPED / WRONG_WORKSPACE / TARGET_CALLS_ZERO.

Subsequent clarification: this report belongs to chat
01a15c2a-e7c2-75b0-bede-5b82298d77d5 (`验收 UnityCodeDB S39 新工程`). A separate
correct-root chat also used Attempt 03; see
CLIENT-ATTEMPT-03-CODEDBTEST-1-RESULT.md. Both reports are retained independently.

Reported actual cwd: `<external-test-root>/CodedbTest_0`.
Required cwd: `<external-test-root>/CodedbTest_1`.
The original returned report did not identify the chat id. The later app thread
listing corroborates this wrong-root chat separately from the correct-root one.

The acceptance chat stopped on this conflict before reading project config,
manifest/lock, selected pointer, instance manifest, wrapper or query sample.
It observed no `mcp__codedb_codedbtest_1__*`; other visible services were
`mcp__codedb_balance__*` and `mcp__codedb_mcp__*`, neither invoked.

| Operation | Calls | Raw response |
| --- | --- | --- |
| Target codedb_status | 0 | None; not invoked |
| Target codedb_text_search | 0 | None; not invoked |

Project identity/hashes/references, final pointer consistency, registration
sources, user/global config and attributable lease were not verified in that
chat. No diagnostic snapshot or hit path/line/text exists for this attempt.
It did not attribute the earlier bootstrap record to its own connection.
No edits, retries, substitute queries or process operations were reported.

Disposition: query not accepted; no response identity evidence. This is a
workspace-preflight failure, not an established CodedbTest_1 registration,
wrapper or MCP startup failure. It provides no new root-cause evidence for
the older target-tool startup issue. Earlier attempts remain stopped.

Next preparation: CLIENT-ATTEMPT-04-HANDOFF.md, requiring the human to select
the actual CodedbTest_1 workspace before creating its fresh acceptance chat.
Do not salvage this stopped chat by changing cwd and continuing the attempt.
No new chat or runtime was launched by this development session. The deferred
Ready/Unconfirmed FOLLOW-UP remains separate and uninvestigated.

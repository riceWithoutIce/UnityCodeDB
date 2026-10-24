# CodedbTest_2: one bounded real text-hit query

Authorization: user approved one sample and one text query. Execute in the SAME
target chat that completed the startup/status gate, only AFTER the human confirms
the new sample imported without compilation errors and Manager remains Ready.
Do not execute this task merely because the file is available. No new status
call, fresh client startup, reconnect or service launch is part of this phase.

## Read-only preflight

Record actual cwd; it must be `<test-projects>/CodedbTest_2`. Verify project config
and selected pointer against the baseline from the prior startup task. Same
registration `codedb-codedbtest-2`, actual absolute project cwd, node, unchanged
relative wrapper/root args and timeout 120. Same instance
`fe3b257859f34023a9e290db3b2ad457`, epoch `5bed173a875e461c981da8b7829a897b`,
project identity
`sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c`
and generation poc.44. Do not require undeclared instance-manifest fields.

Read the sample `Assets/CodeDBValidation/CodeDBQueryProbe.cs`; verify SHA-256
`d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`
and exact line 5:
`        public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";`.
If binding/file hash conflicts or the exact target tool is unavailable, stop
before any call and report the conflict. No broad environment or global-config
scan, standalone wrapper import or shell/SDK replacement query.

## Single call

Call ONLY `mcp__codedb_codedbtest_2__codedb_text_search`, once:

```json
{"query":"CODEDB_S39_CWD_POC44_TEST2","path_glob":"Assets/CodeDBValidation/CodeDBQueryProbe.cs","regex":false,"limit":5}
```

Use the actual exposed schema; if it does not support this agreed request,
stop and report the discrepancy instead of inventing a different search.
Additional status calls=0; other CodeDB calls=0; text-search calls=0 or 1.
Do not call codedb_read, codedb_find, an alternate server or another query.

Preserve the COMPLETE raw response, error flag and host failure if any. Success
requires an actual hit naming the sample path with line 5 and its exact marker
text. Compare coordinates/text to the local sample, normalizing ordinary path
separators only. An equivalent resolved project-contained path can be compared;
do not require a literal slash spelling. Record any absent coordinates/text
honestly; never fill missing response data with local file evidence.

After the one call, stop regardless of outcome. On failure/no hit, no retry,
wait-and-requery, forced refresh/rebuild, config edit, Install or reconnect.
No fixed delay is a guarantee of indexing. Preserve the original failure.

## Result

Report cwd and available attributable chat ID (or not provided), local binding
and sample hash/line match, exact tool called, all call counts, complete raw
response, actual hit path/line/text and pass/failure/not-executed reason.
Keep text-hit functionality separate from full session/response identity.
No additional project_identity/instance_id/activation_epoch protocol fields
are required if the current response does not provide them; mark them missing
instead of inventing values from paths or local records.

This gate covers one ordinary C# text query. Shader/HLSL, performance, historical
upgrades, Unconfirmed, full session attribution and release acceptance stay
outside it. This task never resumes an older failed acceptance attempt.

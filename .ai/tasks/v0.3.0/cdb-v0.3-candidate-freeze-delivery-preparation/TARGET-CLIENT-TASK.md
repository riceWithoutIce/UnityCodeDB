# 1105696 candidate — bounded CodedbTest_2 MCP check

Date: 2026-10-26. Status: COMPLETE / FUNCTIONAL_PASS / IDENTITY_ATTRIBUTION_LIMITED.
Result: user-forwarded target-chat receipt in TARGET-CLIENT-RESULT.md.
The following procedure is retained as executed scope, not a new run request.
The user forwarding this procedure to the existing target-project chat initiates
the named read-only check. No new chat, connection reset or manual server launch.
Execute only in the existing external CodedbTest_2 project chat; do not continue
an earlier failed attempt. Human starting report: "没有报错 ready了" after
opening the newly delivered candidate. Do not refresh/restart to alter the start.
Paths below are relative to that project's root unless marked Package-relative.

## Read-only preflight

Record actual cwd. It must be the intended external CodedbTest_2 Unity project
root (Assets, Packages, ProjectSettings); do not change cwd to compensate.
Record a host-supplied current chat ID only if available; otherwise not provided.

Read only these direct inputs, without running/importing the wrapper:

- `Packages/manifest.json`, `Packages/packages-lock.json`: CodeDB references both
  `file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
  Resolve relative to each JSON file's directory, not the project root.
- Referenced Package `package.json`: version `0.3.0-preview.5`.
- Package-relative `Editor/AICodedbLifecycleEvidence.cs`: SHA-256
  `e939c8d8163ede9ca4a372a608fc5d7c66e24d83d230438e71db496048ea865e`.
  This binds the on-disk F01 source; do not treat it as loaded-process proof.
- `.codex/config.toml`: `codedb-codedbtest-2`, command `node`, cwd resolving to
  this project root, args
  `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]`,
  startup timeout 120 seconds. Do not rewrite or inspect global registrations.
- `AIWork/.runtime/codedb/control/current-instance.json` and its referenced
  instance.json. Pointer expected fields:
  project_identity=`sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c`,
  instance_id=`a492a5e936c14e4da3ed7e4cc7c8c16c`,
  activation_epoch=`063aa347f49a4b9f955a5447f293a0ac`, generation=`poc.44`.
  Pointer SHA-256:
  `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.
  Instance SHA-256 matches pointer:
  `61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced`;
  instance state READY. Do not require activation_epoch in instance.json.
- `Assets/CodeDBValidation/CodeDBQueryProbe.cs`: SHA-256
  `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`;
  line 5 contains `public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";`.

Require visible exact target tools
`mcp__codedb_codedbtest_2__codedb_status` and
`mcp__codedb_codedbtest_2__codedb_text_search`. Missing tools or conflicting
preflight: stop with target calls 0. No substitute namespace or diagnostics scan.

## At most one status, then one query

1. Call target `codedb_status({})` once. Preserve start/end times and complete
   original response including isError/tool errors. Continue only on success,
   lifecycle READY, Package 0.3.0-preview.5, generation poc.44 and generation
   manifest `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`.
   An explicit identity conflict, STARTING, stale/offline, timeout or other error
   ends this attempt. Do not wait/retry or add another status.
2. Only if status passes, call target `codedb_text_search` once:

   ```json
   {"query":"CODEDB_S39_CWD_POC44_TEST2","path_glob":"Assets/CodeDBValidation/CodeDBQueryProbe.cs","regex":false,"limit":5}
   ```

   Require exactly one actual hit at the stated path, line 5, with the complete
   marker matching the local probe. A tool error is not a zero-hit result.
3. Finish by rereading the pointer once, reporting byte/hash stability, then stop.
   This final read is allowed after a tool error; it does not authorize another
   tool call or a diagnostic investigation.

## Report and limits

Return cwd, host chat ID if supplied, actual namespace visibility, preflight
results, exact call counts (status<=1, text_search<=1, other=0), parameters,
complete raw responses, start/end times, hit path/line/text and pointer stability.
Report status functionality, query functionality and response identity separately.

For each response, record project_identity, instance_id and activation_epoch as
provided or **not provided**. Missing fields limit attribution; they do not by
themselves fail the functional check. Disk identity, wrapper names or config
paths do not substitute for formal response fields. This check may demonstrate
functional compatibility plus on-disk candidate binding; unchanged payload/
generation alone does not prove a newly created connection or loaded Editor code.

No file writes, test output files, probe/meta edits, A-to-B experiment, extra RPC,
waiting/polling, reconnect, component start/stop, install/repair/restart/uninstall,
process/lease/log scan, global config, cleanup or automatic retry. First anomaly
stops the call sequence; success also stops after the two named calls.
No long-term stability, F01 log suppression, identity closure, lifecycle,
performance, upgrade or release conclusion from this bounded check.

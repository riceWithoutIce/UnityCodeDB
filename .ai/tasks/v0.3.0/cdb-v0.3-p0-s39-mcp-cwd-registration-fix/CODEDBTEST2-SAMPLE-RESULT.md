# CodedbTest_2: hit-query sample preparation

Date: 2026-10-21. Status: SAMPLE_PREPARED / HUMAN_IMPORT_PENDING /
QUERY_NOT_EXECUTED.

User authorization: "好的 同意" to the proposed single C# sample and one bounded
text query in the existing target chat. No further status call is authorized.

Verified config and selected pointer against the startup baseline before writing.
Created only `Assets/CodeDBValidation/CodeDBQueryProbe.cs` in the test project
(with its parent directory). The file did not exist; publication used CreateNew
to refuse overwrite. The plain static class has no Unity dependency or runtime
behavior. No config/runtime/Package file was changed.

- Bytes: 151, UTF-8 without BOM, LF newlines with trailing newline.
- SHA-256: `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.
- Marker line: 5.
- Exact line: `        public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";`.
- Publication time: 2026-10-21T08:20:15.4207902Z.

Evidence: `.artifacts/tests/s39-cwd-fix/codedbtest2-marker-preparation/`,
containing exact expected file bytes and receipt. Post-write read verified full
bytes and line 5. No implementation-mirroring test suite was added or run.

Allow the normal Unity import/compiler and active watcher to process the file.
No Unity API, forced refresh, manual index operation, process startup, reconnect
or CodeDB call was used. A local file/hash does not establish indexed content.
Wait for human confirmation of no compile errors and Manager Ready, then hand
CODEDBTEST2-HIT-QUERY-TASK.md to the same target chat that passed startup/status.
This is a human convergence gate, not another permission request for the already
approved one-call query. On a compile or state problem preserve it and diagnose
before that call; do not retry Install or manufacture readiness.

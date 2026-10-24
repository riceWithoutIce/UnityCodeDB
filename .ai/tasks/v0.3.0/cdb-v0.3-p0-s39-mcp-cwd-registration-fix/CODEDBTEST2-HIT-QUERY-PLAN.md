# CodedbTest_2: proposed bounded C# hit query

Date: 2026-10-21. Status: COMPLETE / REAL_CSHARP_HIT_QUERY_PASS.
The user approved the sample and bounded query scope with "好的 同意".
The transferred one-call result is in CODEDBTEST2-HIT-QUERY-RESULT.md;
ACCEPTANCE-CLOSURE.md closes this bounded gate. The plan below is retained as
the executed scope and does not authorize another call.

Startup/status is already PASS from the transferred client report. Do not
repeat it or add identity fields/protocol changes as new prerequisites.

Proposed preparation: create only
`Assets/CodeDBValidation/CodeDBQueryProbe.cs` in the test project, refusing an
existing file. Use a plain static class, no Unity dependency or runtime behavior:

```csharp
namespace CodeDBValidation
{
    public static class CodeDBQueryProbe
    {
        public const string Marker = "CODEDB_S39_CWD_POC44_TEST2";
    }
}
```

Record its exact bytes, SHA-256 and marker line 5 in the task evidence. Let the
normal Unity import/compilation and enabled watcher handle it. Do not manually
refresh/rebuild/reinstall or edit runtime configuration. The human should report
compilation/state convergence before the bounded query task is handed off; no
fixed wait or disk READY value can itself certify indexed content.

Use the same target chat that passed startup/status, avoiding a new startup
boundary for a separate question. Verify unchanged cwd, registration and selected
pointer baseline locally, then call ONLY the exact target codedb_text_search
once with query CODEDB_S39_CWD_POC44_TEST2, path_glob
Assets/CodeDBValidation/CodeDBQueryProbe.cs, regex=false and limit=5, subject to
the actually exposed tool schema. Status=0 additional calls; other CodeDB=0.
If the target tool/binding conflicts, stop before calling. On failure/no hit,
preserve the raw response and stop: no automatic retry, wait-and-requery,
alternate service or manual index operation.

Success requires an actual response hit attributable to the sample path, line 5
and exact local marker text. Report tool error state, complete raw response and
actual match coordinates; do not substitute a local read for a hit. Keep query
functionality and complete response/session identity as separate conclusions.
Package baseline remains 0.3.0-preview.5 / poc.44 and the identities from the
startup task; do not fabricate response fields absent from the implementation.

This proposal covers one C# text path. Shader/HLSL, performance, old-generation
migration, full-session identity and release acceptance remain outside it.

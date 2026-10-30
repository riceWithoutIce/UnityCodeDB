# Test3 recovered baseline: real target-client functional gate

Date: 2026-10-26. State: PREPARED / NOT_EXECUTED.
User elects to record the handoff bug and continue current acceptance. This
document prepares a separate bounded attempt after recovery. Neither the old
failed attempt nor the defect is converted to PASS. Execute from the actual
CodedbTest_3 project chat; the parent does not substitute another CodeDB server.
Human has reported Unity open, no compile errors, and Manager recovered Ready.

## Preflight (read only)

- cwd must equal the previously designated external CodedbTest_3 root, with
  Assets/Packages/ProjectSettings. Host-attributed current chat ID only if supplied;
  otherwise `not provided`. Do not scan session histories.
- Exact namespace `mcp__codedb_codedbtest_3__*`; require status and text_search.
  Record actual count/list. If missing, stop without another server or reconnect.
- Candidate `d84b5ca88b1adb57748b2988aa79cc9c7e6e8be9` delivered through both
  manifest and lock: `file:../../Packages/d84b5ca-v03-child-close/com.rice.ai-codedb`.
- Project config: registration `codedb-codedbtest-3`; command node; cwd resolves
  to this project; args `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]`;
  startup_timeout_sec 120. Do not import/execute the wrapper manually.
- Pointer `AIWork/.runtime/codedb/control/current-instance.json` SHA-256:
  `563fe18e496dbafb7d829e902f35c4d24d339f5329ed249083391cff3e5816f3`.
- Project identity
  `sha256:c2ad1085aca6ca5e8298cfe630b69c5b61242497f65c187eb08484f035ca6dd2`;
  instance `bd0f2f01601b4b3990704ad9659f9348`;
  activation epoch `60d2810430de421abefbce55567cf9ec`.
- Selected instance.json SHA-256
  `47a55412ee35f9f8b061e47c03b38dd6b248ab9b1ecff0920970d3a794b65b0e`;
  disk READY / preview.5 / poc.44. Generation manifest
  `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`.
- Stable wrapper SHA-256
  `a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e`.
- Any mismatch ends this attempt before sample creation/MCP. No process/lease/log
  scans or repeated status polling in this gate.

## Finite sample and calls

The project currently has no C# query sample. This task permits only one new
directory `Assets/CodeDBValidation` if absent and one new source file
`Assets/CodeDBValidation/CodeDBQueryProbeTest3.cs`. If the file already exists,
stop and report; never overwrite it. Save UTF-8 without BOM, LF, final newline:

```csharp
namespace CodeDBValidation
{
    internal static class CodeDBQueryProbeTest3
    {
        internal const string Marker = "CODEDB_V03_TEST3_D84B5CA_20261026";
    }
}
```

Record save UTC, exact bytes/hash. Unity owns automatic import and .meta creation;
do not create or alter .meta yourself. One 15-second wait, then:

1. Call exact target `codedb_status({})` once. Require successful response,
   wrapper Ready, lifecycle READY, coordinator ready, preview.5 / poc.44 and
   generation manifest as above. Stop immediately on error/conflict/unready.
2. Only if status passes, call exact target text_search once:

```json
{"query":"CODEDB_V03_TEST3_D84B5CA_20261026","path_glob":"Assets/CodeDBValidation/CodeDBQueryProbeTest3.cs","regex":false,"limit":5}
```

Require exactly one hit, exact path, line 5 and complete marker. Record start/end
UTC, actual save-to-query interval and full original responses. This is a
functional check; no 15-second freshness SLA claim. Maximum calls status=1,
text_search=1, all other CodeDB=0. First anomaly stops dependent work; no retry,
extra wait, refresh, repair, restart, reconnect or alternate query.

## End and report

One final pointer and sample reread/hash is permitted even after a failed call
to establish final state. Keep the sample and Unity-generated .meta; no rollback
or deletion. Record exactly which writes/calls occurred. No Install, Uninstall,
Package/config edits, manual backend startup, process control or Unity lifecycle
operation. Human retains ownership of Unity.

Report separately: status functionality, query functionality, on-disk binding,
pointer/sample stability, formal response identity. Missing project_identity,
instance_id or activation_epoch in responses = not provided / LIMITED; path and
wrapper names cannot replace formal fields. Do not infer a new MCP connection
or loaded Editor implementation from a newly created chat. No host connection
identity = not established. Source checks do not substitute runtime evidence.

Provide the result to the user. Durable records redact machine paths; original
tool responses may remain in the execution receipt. No commit, push, GitHub
update or further lifecycle action. Success does not close BUGS.md or establish
clean Install, Uninstall/Fresh Install, long-term stability or release readiness.

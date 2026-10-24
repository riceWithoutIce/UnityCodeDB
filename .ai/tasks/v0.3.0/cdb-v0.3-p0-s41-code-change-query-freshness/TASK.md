# Task: cdb-v0.3-p0-s41-code-change-query-freshness

## Metadata

- Product / Version: UnityCodeDB / v0.3.0 preview.
- Workflow: codedb-workflow-v2, revision 2.7.
- Status: Scoped A-to-B observation subsequently PASS in a separately authorized
  attempt; see RETAINED-A-TO-B-ATTEMPT-02-RESULT.md. The original attempt below
  remains STOPPED / A baseline NOT_ESTABLISHED, as preserved in RESULT.md.
- Current fixture state: B, retained. Do not execute the historical creation
  sequence below or treat this PASS as broader freshness/release acceptance.
- Planner: current UnityCodeDB development session.
- Coder / executor: human-selected CodedbTest_2 project session.
- Review mode: NORMAL; no independent Verifier activated.
- Execution mode: DURABLE_SESSION; Session policy: REUSE_ONLY.
- Execution profile: retain the target session's configured model and reasoning.
- Delegation authorization: NOT_AUTHORIZED for this task; no automatic dispatch.
- Requirement source: `com.rice.ai-codedb/Documentation~/v0.3.0-roadmap.md`,
  Runtime Release Gate 4 and Discover Read Release Gate 2.

## Objective and current evidence

Observe whether one ordinary C# source edit replaces the indexed query content
through the real project's existing MCP connection. This is a single-checkpoint
functional observation, not a product freshness SLA or release acceptance.

The user approved proceeding with the minimal observation plan after the
read-only mapping. This development session prepares the task; the human
transfers it to the target project session for execution. This file does not
create a session or authorize sending a message to another chat.

The human subsequently confirmed CodedbTest_2 Unity is open and Manager is
Ready. This confirms the requested starting state; compilation-error status
was not separately reported in that message. Real-client execution remains
NOT_STARTED here, pending manual transfer to the target project session.

Static mapping completed on 2026-10-22:

- The inspected poc.44 worker, coordinator, watch-config generator, freshness
  checker and materializer test file match the corresponding Git blobs in
  accepted delivery `186aacf0371ba64e47114306170b449dbca261c9`.
- C# queries scoped to a `.cs` path use the Provider lane. The coordinator
  calls the persistent Provider. Watch configuration enables native watch
  with a default one-second poll interval; that interval is not an update SLA.
- The separate freshness script reports OK/STALE/UNKNOWN. The inspected worker
  and coordinator query path do not call that script or establish an independent
  per-query index-freshness check. This does not prove that the Provider cannot
  update or that a real query has returned stale content.
- Materializer tests cover watch configuration, routing and conditional refresh
  using a fixture Provider. They do not establish real Provider edit freshness.
- S40's real-client fixed-marker PASS remains valid. Its sample is protected.
- A concrete supported freshness window was not established by this bounded
  mapping. The following 15-second checkpoints are diagnostic budgets only.

## Scope and execution envelope

- Approved stages: task preparation, then one human-transferred target-client
  observation under the limits below. No product implementation or repair.
- Delivery authorization: NONE; no commit, export, reference switch or release.
- Change allowlist in `<test-projects>/CodedbTest_2`:
  `Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs` only, created once as A
  and modified once to B. Never overwrite a pre-existing file at this path.
- Unity may generate its normal `.meta`/import/compiler/runtime outputs;
  the agent must not edit them or suppress normal Unity processing.
- Read closure: target manifest/lock, project `.codex/config.toml`, selected
  pointer and referenced instance manifest, the new sample and protected old
  sample; actual tools exposed to this target session and their responses.
- Protected: original `CodeDBQueryProbe.cs`, Package source, configuration,
  all pre-existing project source, runtime files and connections. Do not write
  runtime state, reconstruct identity, or manually trigger refresh/rebuild.
- Human owns Unity launch/close and confirms it is open, without compilation
  errors, with Manager Ready before the attempt. If absent, report the missing
  prerequisite and wait for the human; do not launch Unity automatically.
- Existing target connection may be used. Do not require a new chat, disconnect,
  reconnect, reload MCP, or close another client for this scenario.
- L0 / affected L1 / EditMode: NOT_RUN; no product code changes, and isolated
  tests cannot supply the real-client evidence sought here.
- MCP budget: text_search at most 3, status 0, other CodeDB calls 0.
- Observation budget: one 15-second wait after creation and one after the edit;
  no polling or extension to obtain a passing result. Record actual elapsed
  times, including scheduling delays, rather than asserting exact timing.
- A host/tool failure, baseline failure or unexpected result ends the attempt.
  No second operational attempt, repair or semantic retry is authorized here:
  a repeat would change the observation history and can obscure first-failure
  evidence. A command-construction error before any sample mutation or MCP
  invocation may be corrected mechanically, at most twice.
- No new broad search, full regression, log/process/lease scan, subagent,
  alternative service, automation or process manipulation.
- Active preparation/analysis budget: 30 minutes; no product-cause repair.

## Target-project execution instructions

Run only when the human has transferred this task and confirmed the Unity
prerequisite. Do not ask again for the listed file edits and three conditional
calls once the human has instructed this task's execution.

### 1. Bounded preflight before any write

Report actual cwd; it must be the CodedbTest_2 Unity root. Record a session ID
only if the host explicitly provides one attributable to this chat.

Require visible `mcp__codedb_codedbtest_2__codedb_text_search`. If absent, stop
with all call and mutation counts zero. Never substitute codedb_balance,
codedb_mcp, direct wrapper/CLI or another project's service.

Confirm manifest and lock still reference:
`file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb`.
Project registration is `codedb-codedbtest-2`, command `node`, cwd resolves to
this Unity root, args are
`["AIWork/codedb/wrapper/codedb-project-wrapper.mjs","--root","."]`, timeout 120.
Do not require the literal cwd value to be `.`; the generated absolute cwd is
valid when it resolves to this project. Do not inspect user/global config.

Read `AIWork/.runtime/codedb/control/current-instance.json`, retain its starting
SHA-256, and check its referenced instance manifest/hash against this baseline:

| Field | Expected |
| --- | --- |
| project_identity | `sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c` |
| instance_id | `a492a5e936c14e4da3ed7e4cc7c8c16c` |
| activation_epoch (pointer) | `063aa347f49a4b9f955a5447f293a0ac` |
| generation / Package / instance state | `poc.44` / `0.3.0-preview.5` / `READY` |
| instance manifest SHA-256 | `61d2de93a0d19f9ae1ef68cc2b7d9f71645b81145c501fafb9ebb41aa344dced` |

Do not demand activation_epoch inside instance.json; pointer is its source.
These are disk bindings, not formal MCP response identity.

Verify the new sample does not exist and its parent directory already exists.
Retain the starting hash of protected
`Assets/CodeDBValidation/CodeDBQueryProbe.cs`; expected SHA-256 is
`d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.
Any conflicting binding or occupied sample path stops before writing.

### 2. Create A and obtain one baseline hit

Create the new file as UTF-8 with this content (Marker is line 5):

```csharp
namespace CodeDBValidation
{
    internal static class CodeDBFreshnessProbeS41
    {
        internal const string Marker = "CODEDB_S41_FRESHNESS_A_20261022";
    }
}
```

Record the completed-save UTC time and sample SHA-256. Allow Unity's normal
processing; do not click Refresh, Install or other recovery actions. Wait once
for 15 seconds, then issue the first and only baseline query:

```json
{"query":"CODEDB_S41_FRESHNESS_A_20261022","path_glob":"Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs","regex":false,"limit":5}
```

Use only target `codedb_text_search`. Retain full raw response, isError, timing,
call start UTC and elapsed time since save. Require exactly the expected Provider
hit at line 5 with the A text. Missing hit, wrong text/location, STALE or a tool/
host error ends this attempt without modifying A to B. Label it baseline not
established; it is not a failed A-to-B update experiment.

### 3. Make the one A-to-B edit and query at the checkpoint

Only after baseline success, confirm the sample still equals the A bytes this
attempt created. Replace only `CODEDB_S41_FRESHNESS_A_20261022` with
`CODEDB_S41_FRESHNESS_B_20261022`; preserve all other bytes and line positions.
If somebody changed the file meanwhile, stop without overwriting their edits.

Record completed-save UTC and B SHA-256. Wait once for 15 seconds. Query B once:

```json
{"query":"CODEDB_S41_FRESHNESS_B_20261022","path_glob":"Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs","regex":false,"limit":5}
```

Require exactly the expected Provider hit, new B text and line 5. If missing,
stale, erroneous or inconsistent, preserve the response and stop; no A query
or compensating refresh follows. A returned STALE is explicit freshness
signaling, not a silent miss, but it does not establish the replacement PASS.

Only after B success, immediately query A once using the baseline arguments.
Expected: successful response with no hit in this file. Old A hit, STALE or
error means replacement was not fully established. Do not issue any more calls.

The B and A calls are sequential observations, not an atomic consistency proof.

### 4. Final evidence and retained sample

On completion or failure after writing, read only the final sample/hash, selected
pointer hash and protected old-sample hash. Report whether pointer and old
sample remained unchanged. Do not restore A or delete the sample/.meta: that
would introduce another unobserved source mutation. Leave the sample in its
observed terminal state, identify it in the report, and let the human decide
its later removal. If a final check cannot be read, retain the original failure
and mark that check unverified; do not repair.

Reply in the target chat with:

- cwd, optional host-attributed session ID, namespace availability, human Unity
  starting-state confirmation, completed writes and exact call counts;
- saved A/B content, hashes, save/call UTC times and actual elapsed intervals;
- complete raw MCP responses in order, including isError and timing;
- baseline, B hit, A absence and pointer/old-sample stability separately;
- formal response identity fields if actually provided, otherwise “未提供”;
  missing identity alone does not invalidate the scoped functional observation;
- final sample state, first failure if any, and the boundary below.

## Definition of done and evidence limits

Functional checkpoint PASS requires the baseline A hit, post-edit B hit and
post-edit A absence, with matching file/line/text and stable project binding.
It proves this sample reflected the edit at the recorded query times. It does
not measure the actual convergence instant or establish a 15-second SLA,
freshness signaling completeness, atomicity, performance or release readiness.

If post-edit freshness is not established, report NOT_ESTABLISHED / observed
result rather than inventing an SLA violation. Preserve any explicit STALE
separately from silent NO HIT or stale old-content hit. Existing S40 PASS is
not revoked by this different scenario. Changed binding or protected sample
means attribution is inconclusive, not permission to rebaseline automatically.

Create/rename/delete matrices, Shader freshness, navigation tools, runtime
identity/heartbeat follow-ups, physical cleanup, repairs and publication remain
outside this task. The fixture remains ACTIVE until this task is concluded;
later cleanup needs the human's scoped disposition.

## Handoff

- Current task: cdb-v0.3-p0-s41-code-change-query-freshness.
- Current status: PARTIAL / STOPPED; the sole baseline query returned STARTING.
- Next notification: human / current UnityCodeDB development session.
- Next action: align whether a narrow read-only readiness-admission diagnosis
  should precede any separately authorized fresh observation. No retry active.
- Human decision or authorization required: YES for another operational attempt,
  expanded diagnosis, repair or sample cleanup. See RESULT.md for evidence.

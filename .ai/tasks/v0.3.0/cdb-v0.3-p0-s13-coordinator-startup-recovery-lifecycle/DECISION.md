# Decision: cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle

Status: ACCEPT

## Disposition

- Human decision on 2026-09-10: `ACCEPT` the current stable uncommitted S13
  snapshot, including FIX 06 and the bounded human lifecycle evidence.
- Accepted branch: `codex/v0.3.0-legacy-workflow`.
- Accepted committed base HEAD:
  `9aada838e26879810a4f79760273ca66340ebf12`.
- The accepted S13 implementation remains uncommitted. This decision does not
  authorize commit or push.
- Acceptance closes the reviewed S13 repair scope and accepts the explicitly
  recorded evidence limits. It does not convert deferred or unproved runtime
  outcomes into passing evidence.

## Accepted Snapshot

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `TASK.md` | `12747` | `a69f5f5561ec238198de730ccfd3265f77eddd39f3459671d00c17fb55e13da6` |
| `RESULT.md` | `105055` | `0e8b70a6da2b60787f2786f581864bd982e931a17008a76f86f6c61aa611e955` |
| `verifications/VERIFICATION-01.md` | `11104` | `99074f612fbe481db70e193b1ebb03c7030ebc1f85d6321850b77e962399da51` |
| `verifications/VERIFICATION-02.md` | `5607` | `f8a474d35b21f84e470a3ea93c72c12e79cc779c7299663fed7f6e5226e875d2` |
| `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` | `128166` | `d7567cda79add3a1717c861f542d9516e18cb483fe44220da1b704931c7dd176` |
| `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs` | `70576` | `a51ee74454dcb5336564d718abcf26718506430a3f547b4b3cd5e30e6c362514` |
| `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs` | `122925` | `750f63b5485d1ba8901ced4f9a220973ccb178483eb23e03285438a4cbbf8877` |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `156286` | `ee1630b8119b79fd226791f6bb4852fe0b9c626f6b316ba653f79cdf305991cb` |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | `48210` | `a716e15a67cc3cc92e0a67ea492a92d7b2b6369ab2b84ae8fbf1c14a6aa8f9db` |
| `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs` | `126612` | `88fdca68be19e9ba82cf8361f253f7baaa189bb77e89116076801df26cceec8a` |
| `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs` | `49434` | `bd64acea729c27b5dceba20c534d2e49ab3e6ba2f181b333923a0d9e8ab72904` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `210166` | `67d2f64269e97dac18d594f314dd626c0824885c4eb98d42aee2ac0c55b5efc3` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `162653` | `c413b9e720bea021b618de7d87feff36b9f02f505f1e18ff6d7de83b46eafd54` |

## Accepted Outcome

- The S13 lifecycle changes addressing Editor lease ordering, prerequisite
  attribution, migration gating, terminal Manager presentation, stale async
  publication, shutdown evidence, and the recorded-child-absent Supervisor
  fixture are accepted within the reviewed scope.
- The human-observed validation project compile reached `0 warnings / 0
  errors` before FIX 06.
- The Manager no longer remained permanently at `Checking` in the accepted
  human scenario.
- Play to Edit completed without a reported stall or error. With the Manager
  open, Unity exited normally in less than 30 seconds without forced
  termination, and the bounded post-exit target-project Unity process count
  was zero.
- FIX 06 constrains `shutdown_disposition` to
  `NOT_EVALUATED`, `NO_RESPONSE`, `SUCCEEDED`, `FAILED`, or
  `SUPERVISOR_ERROR`; arbitrary Supervisor error codes are not persisted as
  dispositions.

## Verifier Disposition

- `VERIFICATION-01.md` returned `FAIL` with one P1 concerning the unbounded
  `shutdown_disposition` vocabulary; all other reviewed areas passed within
  their stated evidence limits.
- FIX 06 addressed that exact P1 and its adjacent regression coverage.
- `VERIFICATION-02.md` returned `PASS`; one-time findings are `none`.
- The Verifier performed a targeted read-only source review and did not rerun
  Unity, EditMode, compilation, lifecycle execution, or other tests.

## Explicit Runtime Gap

- The original S13 Definition of Done required Fresh Cold Start to reach
  stable `Ready` with an operational selected Coordinator.
- That outcome was not established. The retained runtime observations instead
  included terminal `NeedsAttention`, `Selected instance coordinator is not
  operational.`, or persisted-child-absent/unauthenticated state.
- The user accepts the current repairs and evidence with this gap explicit.
  This decision must not be interpreted as proof that stable `Ready`, selected
  Coordinator operational admission, the complete S13 lifecycle envelope, or
  the Runtime Release Gate has passed.
- Closing that runtime gap requires a separately aligned successor scope or a
  later unified runtime gate; it is not an implicit continuation of this
  accepted decision.

## Deferred Boundaries

- FIX 06 C# compilation and EditMode execution are `DEFERRED` to the later
  unified Unity gate. The Coder's attempted FIX 06 static/source assertion
  command ended in a PowerShell parser error and did not form PASS evidence.
- Full Cold Start, authenticated Supervisor/selected-instance continuity,
  operational Coordinator admission, complete Domain Reload machine trace,
  internal shutdown-marker ordering, consumer, third-party, publication,
  deployment, and release acceptance remain `DEFERRED` or `NOT RUN` as
  recorded by RESULT and the Verifier reports.
- This decision authorizes no Unity or Unity MCP action, additional test,
  process control, commit, push, publication, or release operation.

## Handoff

Current task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`  
Current status: `ACCEPTED / EXPLICIT_RUNTIME_GAP_DEFERRED`  
Next notification: `UnityCodeDB v0.3 Planner / Human`  
Next action: decide separately whether to commit the accepted S13 snapshot or
first align a successor task for operational Coordinator admission and stable
`Ready`  
Human decision or authorization required: commit, push, successor task,
Unity/runtime validation, Runtime Release Gate, and every later roadmap or
release action remain separately gated

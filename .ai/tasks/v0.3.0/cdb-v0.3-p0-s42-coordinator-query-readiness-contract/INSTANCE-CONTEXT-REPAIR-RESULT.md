# Watch-manager selected instance context repair result

Status: SOURCE_REPAIR_PASS / NOT_COMMITTED_OR_DELIVERED.
Date: 2026-10-22. Human authorized the aligned minimal repair and focused tests.
Base: 267b921dee0385962885e8e3142b4e4903ab711b.

## Change

In the repository-local S42 worktree, runWatchManager now supplies
RICE_CODEDB_UNITY_ROOT=context.root and
RICE_CODEDB_INSTANCE_ROOT=context.selectedInstance.instanceRoot to its existing
runChild invocation. The existing environment merge overrides inherited values
for this child without changing process.env or the generic runChild default.
The values are derived from the already validated context; no machine paths or
additional runtime guard were introduced.

Only two product paths changed relative to the base:

| Path under com.rice.ai-codedb | SHA-256 |
| --- | --- |
| Tools~/codedb-project-supervisor.mjs | 50260e1a355907a163e7841dc7a076e1917c0cec1e4b0d3f4f6f4a7186e59aca |
| Tests~/test-codedb-project-supervisor.mjs | dcfb3008eac55880b0ba5eae26f7acb962dcb345b3d92cab467d279b02b41e06 |

Production diff is one call-site argument (six changed lines). The test harness
adds its own --watch-manager-context-fixture branch. Immutable generation files,
manifests, Editor code and prior S42 export remain unchanged. Isolated index empty;
no primary source/index operations or consumer changes were performed.

## Verification

L0 PASS: both final JS syntax checks, git diff --check, exact two-path allowlist,
empty isolated index. No unstaged paths outside the declared product allowlist.

Affected L1 PASS, one initial invocation, no failed run or retry:

`node com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs --watch-manager-context-fixture .artifacts/tests/s42-instance-context/repair-a`

Canonical result:
`<repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract/.artifacts/tests/s42-instance-context/repair-a/result.json`
SHA-256: `2a7d910f6472668a1204dc5e9e26e4e21f8e33117f7ed4c9ceb4df6a885eb123`.

Original runWatchManager/runChild executed with product spawn intercepted.
Captured child environment fed original PowerShell context and session-reader
functions; source AST extraction, synthetic process-start evidence and owned
fixture dependencies were used. No script entry point was imported or executed.

| Inherited condition | Selected instance and lease root | Sessions |
| --- | --- | --- |
| Instance variable absent | Correct | 1 |
| Matching instance | Correct | 1 |
| Foreign instance | Correct | 1 |
| Incorrect Unity root and foreign instance | Correct | 1 |
| No valid lease (malformed lease only) | Correct | 0 |

All cases also assert unchanged parent environment, preserved unrelated variable,
expected lifecycle forwarding, project cwd, hidden window and one original
admission/capture callback. One bounded fixture-only PowerShell process ran;
actual product child starts=0, live process probes=0, IPC requests=0.

The negative control uses the selected derived lease directory with the fixture's
valid lease removed and a malformed lease present. No valid session was invented.
The product's original session guard and lifecycle/ownership checks are unchanged.

## Limits and handoff

This is source and offline boundary acceptance, not real Editor/session liveness
or Stop success. Historical child environment remains unobserved. Existing S42
readiness evidence is retained; its unchanged scenarios were not rerun because
this repair only changes watch-manager child environment.

No broad harness, Unity/EditMode, Provider, MCP, freshness, performance, release,
live Stop/Start or process-control gate ran. No commit, export or consumer
reference switch occurred. The running old Supervisor cannot adopt these edits.

Source task complete. Next alignment: exact updated delivery artifact and a
bounded old-owner retirement plan accounting for the failed old watch-manager
route; do not replay that Stop against the unchanged owner. Heartbeat continuity,
Unconfirmed/Needs attention and formal response identity remain separate items.

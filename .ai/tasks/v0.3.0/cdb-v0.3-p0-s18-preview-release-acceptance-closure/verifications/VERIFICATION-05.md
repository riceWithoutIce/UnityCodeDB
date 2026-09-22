# S18 Host Runtime Bootstrap FIX 02 - GUARDED Verification

## Outcome

- Verdict: `PASS / HOST_RUNTIME_REQUIRED_FOR_MCP_CLOSED`
- Mode: `GUARDED`, targeted and read-only except for this report.
- Scope: original `HOST_RUNTIME_REQUIRED_FOR_MCP` finding and directly
  adjacent bootstrap regression only.
- Findings: `none` within the authorized scope.

## Frozen Admission

- Branch: `codex/v0.3.0-legacy-workflow`.
- Expected and observed HEAD:
  `e4ac545e3d1261340c5b757cfa328a0c3296ac1e`.
- Exact uncommitted changed paths:
  - `com.rice.ai-codedb/Editor/AICodedbActions.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Observed SHA-256 values matched the frozen handoff:
  - Actions:
    `212DB33DACBAFBA873FA220606D47F2AAFA087D79E7A9924D2C2A4F5DE604489`
  - Manager UI tests:
    `DDBCE34F7A4CC341FB6443AC211EFC15E9FFB8C5B7F215E493D7B749ED98971D`

Identity admission: `PASS`.

## Authorized Review

### Supervisor-first Probe and fallback: `PASS`

`RunHostAdmissionAfterProviderAsync` invokes the supplied Supervisor
`materialize/Probe` first. A successful Supervisor Probe is returned directly;
the existing current-instance path therefore performs no bootstrap fallback
and no duplicate installation.

When the Supervisor Probe fails, the helper checks the Bridge-owned
`OneShotFallbackAuthorized` bit through
`IsSupervisorOneShotFallbackAllowed`. Unauthorized failures remain fail-closed.
Only an authorized response permits exactly one Package-owned read-only
`RunProbeAsync` fallback.

### Explicit runtime-required transition: `PASS`

The read-only bootstrap Probe result is examined for the exact marker:

```text
MCP availability requires the current Package-owned Host runtime.
```

Only a successful Probe fallback containing that marker starts the next
transition. The helper then issues a second Supervisor-first
`materialize/Install` request with explicit project-mutation confirmation.
That Install fallback is independently gated by the second command's own
`OneShotFallbackAuthorized` bit. A failed or unauthorized second command does
not invoke direct Install and remains fail-closed.

This closes the original external state in which the Provider was installed
but the first Package-owned Host runtime was absent, without treating every
Probe result as permission to install.

### Provider and adjacent regressions: `PASS`

- Null or failed Provider result returns immediately; neither Probe nor
  Install is invoked.
- Supervisor Probe success does not invoke Probe fallback or Install.
- Unauthorized Probe failure does not invoke Probe fallback or Install.
- Authorized Probe fallback without the exact runtime-required marker returns
  its result and does not Install.
- Authorized runtime-required Probe fallback performs one Supervisor Install
  attempt and permits direct Install fallback only when that second response is
  independently authorized.
- The Manager still calls the Actions API, requests reconcile/cache refresh,
  and does not access the materializer directly.

The adjacent source tests encode these branches, including the independent
second authorization gate.

## Reused Coder Evidence

- Static/source contract batch: `PASS`.
- Two-path scoped `git diff --check`: `PASS`, exit `0`.
- No test or diff command was rerun by Verifier.

## NOT RUN / DEFERRED

- C# compile, EditMode, Unity, Unity MCP/CUA/BatchMode, external Package
  rerun, Provider rerun, runtime/process probes, Node/Package-boundary tests,
  broad diff, repository-wide search, and unrelated tests: `NOT RUN`.
- Commit, artifact export, tag, push, publication, and promotion: `DEFERRED`.

## Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `PASS / HOST_RUNTIME_REQUIRED_FOR_MCP_CLOSED`

The FIX 02 targeted re-review is complete. The next actor is
`UnityCodeDB v0.3 Planner / User`, who must decide `ACCEPT / FIX / DEFER /
STOP`. This review does not contact Coder, route another role, or authorize
Unity, Git, artifact, or release operations.

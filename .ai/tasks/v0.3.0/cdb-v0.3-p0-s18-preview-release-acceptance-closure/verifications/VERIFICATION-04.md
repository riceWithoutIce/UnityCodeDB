# S18 External Host Admission Fix - GUARDED Verification

## Outcome

- Verdict: `FAIL / BOOTSTRAP_PROBE_FALLBACK_NOT_CONSUMED`
- Mode: `GUARDED`, targeted and read-only except for this report.
- Scope: original external Host-admission finding and its directly adjacent
  Provider-success regression only.
- Findings: one in-scope `P1`.

## Frozen Admission

- Branch: `codex/v0.3.0-legacy-workflow`.
- Expected and observed HEAD:
  `babec1fcf97e424fbf6c8c9ba28e5339407b13da`.
- Expected changed source/test paths:
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- The scoped source/test review found exactly those two paths modified relative
  to HEAD. Unrelated dirty workflow/task/project files were preserved and were
  outside this review.
- Observed worktree SHA-256 values:
  - Manager window:
    `F8A0B91543A818336734B30B4ADC27A1D93398D212B1EAC7F3B89290F40004C4`
  - Manager UI tests:
    `03FFEABC7EED0BDB3630F161A943BBD0FA588CC0D9254081A7B96F9F351DE5E3`

Identity admission: `PASS`.

## Authorized Review

### Provider-success transition: `PASS`

The Setup/provider-guidance Configure entry point
`GetConfigureDependenciesAction` and the Overview primary action
`RunPrimaryAction` both pass the same `RecheckHostPayloadAfterProviderAsync`
continuation to `RunUserActionAsync`. The continuation therefore covers both
user-visible Configure Dependencies entry points without duplicating Manager
admission logic.

### Authenticated Host admission route: `FAIL`

The continuation returns the original Provider result when it is null or not
successful. For a successful Provider result it calls:

```text
AICodedbEditorLifecycle.RunSupervisorCommandAsync(
    "materialize",
    "Probe",
    false)
```

For an existing current instance, that lifecycle/bridge path reads the project
Supervisor identity and uses its authenticated pipe request. The Manager does
not construct a materializer request or bypass the Supervisor.

However, the externally observed state has no current instance yet. In that
bootstrap state `RunSupervisorCommandAsync` returns
`CURRENT_INSTANCE_UNAVAILABLE` and marks the response's existing
`OneShotFallbackAuthorized` evidence when the runtime control directory is
proved empty. The new continuation returns this failed result directly. It
does not consume the one-shot authorization through the existing
Supervisor-first fallback pattern, so no read-only materializer Probe occurs
and Host payload admission remains unevaluated.

### P1-01: Bootstrap Probe fallback is not consumed

The fix only handles the path where a Supervisor can already be reached. It
does not close the reported first-install path (`Host payload: Needs Setup`,
`Current instance: Inactive / Not evaluated`):

1. `AICodedbSupervisorBridge.SendCommandWorker` detects the missing current
   instance before launching a Supervisor.
2. For an exact `materialize/Probe`, it returns the fail-closed result together
   with `OneShotFallbackAuthorized` only when the missing-instance and empty
   runtime-control proof succeeds.
3. `RecheckHostPayloadAfterProviderAsync` does not inspect that authorization
   and returns the failed Supervisor result.

The codebase already has the required safe pattern in
`AICodedbActions.RunSupervisorCommandWithFallbackAsync`: it invokes fallback
only when the Supervisor result failed and
`IsSupervisorOneShotFallbackAllowed` is true. The new Configure continuation
does not use an equivalent path. As a result, the original external user flow
can remain at `Not evaluated` after Provider success.

Priority: `P1`, because the normal first-install acceptance path remains
unavailable. This is not a request to weaken Supervisor authentication or to
allow unconditional direct materializer access.

### Failure and ownership boundaries: `PASS`

- Failed Provider installation does not invoke the Probe continuation.
- The Manager source contains no direct
  `AICodedbHostPayloadMaterializer` call.
- For non-bootstrap states, Host admission remains owned by the existing
  Supervisor/lifecycle route and Manager consumes the resulting observation
  through its normal refresh/cache path.
- The existing `RunUserActionAsync` progress, completion, reconcile, and
  refresh sequencing remains in use. It does not compensate for the missing
  authorized bootstrap fallback.

### Test contract: `PASS`

The added source regression assertion checks for the shared continuation,
Supervisor `materialize/Probe` route, and reconcile request, and rejects one
specific direct materializer spelling. It does not assert the reported
missing-current-instance bootstrap outcome or consumption of
`OneShotFallbackAuthorized`, so its PASS does not close P1-01. Existing
Manager source assertions continue to cover cache-only status observation and
absence of direct materializer access in status-refresh paths.

## Reused Coder Evidence

- Static/source check: `PASS`.
- Focused Manager source regression assertion:
  `ConfigureDependenciesSource_RechecksHostAdmissionAfterProviderSuccess`,
  `PASS`.
- Two-path scoped `git diff --check`: `PASS`, exit `0`.
- No production/test bytes were changed by this verification.

## NOT RUN / DEFERRED

- C# compile, EditMode, Unity, Unity MCP/CUA/BatchMode, external Package
  rerun, Provider rerun, runtime/process probes, Node/Package-boundary tests,
  broad diff, repository-wide search, and unrelated tests: `NOT RUN` by
  Verifier.
- Commit, artifact export, tag, push, publication, and promotion: `DEFERRED`.

## Handoff

Current task:
`cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `FAIL / BOOTSTRAP_PROBE_FALLBACK_NOT_CONSUMED`

The targeted Verifier review is complete. The next actor is
`UnityCodeDB v0.3 Planner / User`, who must decide `ACCEPT / FIX / DEFER /
STOP`. This review does not route another role, contact Coder, or authorize a
commit, artifact rebuild, Unity validation, tag, push, or publication.

---

## FIX 01 Targeted Re-review - 2026-09-22

### Outcome

- Verdict: `PASS / P1_01_CLOSED`.
- Mode: `GUARDED`, targeted and read-only except for this appended section.
- Scope: original `P1-01 / BOOTSTRAP_PROBE_FALLBACK_NOT_CONSUMED` and its
  directly adjacent success/failure routing only.
- Findings: `none` within the authorized re-review scope.
- The original FAIL above remains preserved as the finding against the prior
  two-path identity.

### Frozen Admission

- Expected and observed HEAD:
  `babec1fcf97e424fbf6c8c9ba28e5339407b13da`.
- Exact changed source/test paths relative to HEAD:
  - `com.rice.ai-codedb/Editor/AICodedbActions.cs`
  - `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- Observed worktree SHA-256 values matched RESULT exactly:
  - Actions:
    `B850ED0D788CA0D9850BD9E9A419F2BBD38EED3C8962868103D608A8927912B6`
  - Manager:
    `62A19AF361188A4459165277EB916C0F1EF533CF5233410EF589F47E7C7DE0D7`
  - Manager UI tests:
    `57E5B173F2E32516ECD674AE008EACC0F5D764ADFFA436AD7CF9DFF31D624C92`

Identity admission: `PASS`.

### P1-01 Closure

`AICodedbActions.RunHostAdmissionAfterProviderAsync` now owns the narrow
post-Provider transition. It short-circuits a null or failed Provider result.
For Provider success it invokes the Supervisor `materialize/Probe` first via
the existing `RunSupervisorCommandWithFallbackAsync` gate.

That gate returns a Supervisor success directly. A normal failed Supervisor
result remains fail-closed. It calls the supplied Package-owned
`RunProbeAsync` exactly once only when
`AICodedbEditorLifecycle.IsSupervisorOneShotFallbackAllowed` confirms the
Bridge-owned authorization bit. This consumes the existing missing-current-
instance plus empty-runtime bootstrap proof without broadening it or creating
a second authorization authority.

The Manager continuation calls this Actions API, requests the normal lifecycle
reconcile, and then continues through the existing cache refresh/completion
path. It has no direct materializer access. Both Overview and Setup Configure
entry points retain the shared continuation.

Original P1-01: `CLOSED`.

### Adjacent Regression Review

- Authorized missing-current-instance result: one Supervisor call and one
  read-only bootstrap Probe fallback.
- Failed Supervisor result without authorization: no fallback and original
  failure preserved.
- Successful current-instance Supervisor Probe: no duplicate fallback.
- Failed Provider result: neither Supervisor nor bootstrap Probe invoked; the
  original Provider result is preserved.
- Existing Install/Uninstall callers retain the same shared fallback
  semantics through the original action/confirmation overload.

The directly adjacent tests encode all four post-Provider branches above and
the source ownership assertions. Focused EditMode execution remains deferred,
so this PASS is limited to the reviewed source/test contract and reused Coder
evidence.

### Reused Coder Evidence

- Static/source contract batch: `PASS`.
- Three-path scoped `git diff --check`: `PASS`, exit `0`.
- No evidence command was rerun by Verifier.

### NOT RUN / DEFERRED

- C# compile, EditMode, Unity, Unity MCP/CUA/BatchMode, external Package
  rerun, Provider rerun, runtime/process probes, Node/Package-boundary tests,
  broad diff, repository-wide search, and unrelated tests: `NOT RUN`.
- Commit, artifact rebuild/export, tag, push, publication, and promotion:
  `DEFERRED`.

### FIX 01 Handoff

Current status: `PASS / P1_01_CLOSED`

The FIX 01 targeted re-review is complete. The next actor is
`UnityCodeDB v0.3 Planner / User`, who must decide `ACCEPT / FIX / DEFER /
STOP`. Verifier does not contact Coder, route another role, or authorize Git,
Unity, artifact, or release operations.

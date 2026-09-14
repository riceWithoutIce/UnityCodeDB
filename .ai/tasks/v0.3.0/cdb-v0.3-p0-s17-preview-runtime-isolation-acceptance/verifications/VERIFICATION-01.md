# Verification: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance

## Verification Request

- Workflow: `codedb-workflow-v2`
- Review mode: `GUARDED`
- Requested profile: `v0.3.verifier.deep`
- Status: `READY / DISPATCH_AUTHORIZED`
- Decision owner: user
- Verification scope: S17 terminal-failure authority refactor, its two
  original P1 findings, the adjacent compile closure, and the named affected
  EditMode evidence only
- Input records: `../TASK.md`, `../ROUTE-REASSESSMENT.md`, and `../RESULT.md`
- Report target: this file; preserve this request and append the completed
  Outcome, Evidence, Findings And Limits, and Handoff sections below it

## Frozen Admission

- Branch: `codex/v0.3.0-legacy-workflow`
- HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63`
- Ordered six-path identity:
  `970b95b826a5aefa7130a17a813a5fc3240337cb7d616f0fc2459ec517095a04`
- Identity algorithm: in the listed order, concatenate UTF-8
  `relative-path + NUL + decimal-byte-length + NUL + lowercase-file-sha256 + LF`,
  then SHA-256 the concatenated bytes.

| Ordered path | Bytes | SHA-256 |
| --- | ---: | --- |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | 201595 | `76ae4ad9bc40b473a69533aced9e5b577fd4e121c4567e6fe3d0371f574bb46d` |
| `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs` | 56607 | `4519b2f8d4600947ecb2cfe89d0f49f5eb6f14584cf74ea604ce82adda765129` |
| `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs` | 121526 | `60ba5ef11d7d776810a6132880fe0efdef6a1a7dc58f328f14c586add14e51b1` |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | 48210 | `a716e15a67cc3cc92e0a67ea492a92d7b2b6369ab2b84ae8fbf1c14a6aa8f9db` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | 252455 | `223b11e1893b7bfd5aded9bf6753850fc882b6eca50b537891e312116f62873c` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | 173901 | `980ac9b10c40a2f823766979ad6b655e86966f3aa4cb88dfa29985cdb49f85bb` |

At admission, verify only HEAD and these six exact file records/aggregate.
Do not use repository-wide status, diff, history, or identity discovery. If any
value differs, stop as `BLOCKED / FROZEN_IDENTITY_DRIFT`; do not review or fix.

## Claim-Bounded Review

Review only the following claims and their immediately adjacent regression
surface:

1. Lifecycle owns one validated terminal convergence failure envelope;
   Snapshot and Manager only project/consume the lifecycle cache and introduce
   no second readiness, ordering, persistence, filesystem, hash, or runtime
   authority.
2. Failure replacement and authenticated Ready clearing are authority-aware:
   identical `SupervisorId` plus `OwnerEpoch` requires a strictly newer local
   revision, while a different already-authenticated authority may restart at
   a lower revision. `ObservationId` is not treated as the authority epoch.
   Transient, missing, malformed, unauthenticated, same-authority stale, and
   Package-fingerprint-mismatched evidence remain fail-closed.
3. Authoritative Uninstalled completion publishes one coherent cache tuple
   under the lifecycle lock: product status present and Uninstalled, null
   materializer result, null terminal failure, null Supervisor snapshot, and
   exactly one newer cache revision. It clears the persisted envelope before
   persisting Uninstalled state. The unchanged cache-only Manager can consume
   this revision immediately and retain the Install/Uninstalled presentation.
4. The added three-argument `TryGetPersistedProductState` overload only forwards
   through lifecycle-published project root/identity to the existing
   five-argument display helper. It adds no identity derivation, I/O, cache, or
   authority and closes the human-observed `CS1501` compiler error.
5. Direct tests cover serialized layer/binding retention, same/new authority
   ordering, authenticated Ready clearing, Uninstalled envelope resolution,
   coherent cache publication, cached NeedsAttention retention, and cached
   Uninstalled/Install presentation.

One-time findings only. Only an unclosed original P1, the compile blocker, or
an immediately adjacent regression may block. The accepted `CS0414` unused
retry-counter warning is a non-blocking code-freeze follow-up, not an S17
repair request. Do not open a broader lifecycle, Supervisor, Manager, Package,
or release audit.

## Reused Evidence

- Human Unity compile: zero visible compiler errors; prior `CS1501` closed.
- Human affected EditMode fallback: the seven exact tests frozen in
  `ROUTE-REASSESSMENT.md` were reported `7/7 PASS`, failed `0`, skipped `0`.
  This is explicitly human attestation; screenshot, durations, and independent
  UI observation are unavailable and must not be inferred.
- Coder formatting evidence: final relevant scoped `git diff --check` records
  are exit `0` with empty output.
- The preceding CUA kernel-assets error occurred before any test launched. It
  is retained as tooling history and is not a product or EditMode failure.

Reuse these records. Do not rerun EditMode, compile, L0, or any other test.

## Execution Boundaries

- Production/test/TASK/RESULT/route records are strictly read-only. Only this
  report file may be updated.
- Read only the named task records, the six frozen files, and exact direct
  symbols/tests needed for the five claims. Use exact-symbol searches with at
  most 20 matches and line-ranged excerpts; no whole-file dump.
- Active review time: 30 minutes maximum. Findings are reported once.
- Do not run Unity, Unity MCP, CUA, BatchMode, CLI tests, compile, process/log/
  runtime/Provider inspection, network access, full regression, or consumer /
  publication checks.
- Do not run Git diff/status/history. Admission permits only one HEAD read and
  one six-file identity calculation using the algorithm above.
- Do not modify code/tests, contact Coder, dispatch a repair, commit, tag,
  push, publish, or route another role.

## Required Report

Append:

- Verdict: `PASS`, `FAIL`, or `BLOCKED`
- Frozen identity admission result
- Criterion-by-criterion result for the five claims
- One-time findings, explicitly `none` when empty
- Reused evidence and tests rerun (`none`)
- `NOT RUN / DEFERRED` boundaries, including Phase B runtime convergence,
  full EditMode/PlayMode, consumer/release, Unity MCP, and publication
- Current task/status, next notification `UnityCodeDB v0.3 Planner`, and next
  action: Planner/User decides `ACCEPT / FIX / DEFER / STOP`

Do not automatically notify or dispatch any next role.

## Outcome - Targeted S17 Review

- Review date: `2026-09-14`.
- Verdict: `PASS` for the frozen, claim-bounded S17 terminal-evidence review.
  This is not a promotion of the deferred runtime, consumer, or publication
  gates.
- Scope stayed within the two original P1 findings, the adjacent cache/compile
  closure, and the seven named affected EditMode tests.

### Frozen Identity Admission

- Branch: `codex/v0.3.0-legacy-workflow`.
- HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63` (`PASS`, matches the frozen
  request).
- Ordered six-path identity: `970b95b826a5aefa7130a17a813a5fc3240337cb7d616f0fc2459ec517095a04`
  (`PASS`, matches the frozen request).
- The recorded per-path byte counts and SHA-256 values in the admission table
  matched. No identity drift was observed and no replacement identity was
  calculated.

### Criterion Results

1. **Lifecycle-only terminal envelope: `PASS`.**
   `AICodedbEditorLifecycle.RememberLifecycleProductStatus` and
   `PublishLifecycleStatusCache` keep terminal evidence, product status,
   Supervisor observation, and revision in one lifecycle-owned cache tuple.
   `AICodedbStatusSnapshot` projects a valid retained envelope as
   `NeedsAttention` and suppresses `Checking`/`Ready`; Manager consumes the
   lifecycle cache and does not add a readiness, ordering, persistence, hash,
   filesystem, or runtime authority. The direct Manager cache path is visible
   at `AICodedbManagerWindow.cs:553-595`.

2. **Authority-aware replacement and Ready clearing: `PASS`.**
   `BindProductStatusToSupervisorObservation` validates the exact observation
   marker and binds revision, Supervisor id, owner epoch, process identity, and
   observation id before terminal use (`AICodedbEditorLifecycle.cs:2582-2693`).
   `ShouldReplaceTerminalConvergenceFailure` and
   `ShouldClearTerminalConvergenceFailure` require a higher revision for the
   same Supervisor/owner epoch, while an authenticated different authority may
   start at a lower local revision (`:2765-2830`). Transient, missing, invalid,
   unauthenticated, and fingerprint-mismatched evidence remains rejected.
   The direct tests cover round-trip retention, stale/equal rejection, newer
   replacement, and cross-authority low-revision acceptance.

3. **Authoritative Uninstalled cache/persistence closure: `PASS`.**
   `PublishAuthoritativeUninstalledCache` publishes `hasProductStatus=true`,
   `Uninstalled`, null result, null terminal failure, null Supervisor snapshot,
   and one newer revision (`AICodedbEditorLifecycle.cs:2482-2521`). Reconcile
   completion publishes that tuple, clears the persisted terminal envelope,
   then persists Uninstalled state (`:643-666`). The direct regression
   `AuthoritativeUninstalledCompletion_PublishesCoherentCacheRevision`
   verifies the complete tuple and exactly-one revision increment
   (`AICodedbEditorLifecycleTests.cs:1257-1360`).

4. **Three-argument persisted-state overload / compile closure: `PASS`.**
   The overload at `AICodedbEditorLifecycle.cs:2396-2407` forwards only through
   lifecycle-published `_projectRoot` and `_projectIdentity` to the existing
   five-argument display helper. It performs no identity derivation, hashing,
   filesystem read, new cache publication, or authority decision. The recorded
   human compile evidence reports zero visible errors and closes `CS1501`.

5. **Direct regression coverage: `PASS` (evidence-qualified).**
   The five lifecycle tests cover serialized authenticated layer/binding
   retention, same/new authority ordering, authenticated Ready clearing,
   Uninstalled envelope resolution, and coherent cache publication. The two
   Manager/UI tests cover cached Uninstalled/Install presentation and retained
   terminal `NeedsAttention` without `Checking` (`AICodedbManagerUiTests.cs:801-854`).
   The human-reported exact affected EditMode set is `7/7 PASS`, `0` failed,
   `0` skipped; this remains attestation without independent UI screenshots or
   timing data.

### Findings

None. No original P1 or immediately adjacent regression remains open in this
bounded review. The accepted `CS0414` retry-counter warning is retained as a
non-blocking `FOLLOW-UP`, not a release finding.

### Reused Evidence / Tests Rerun

- Reused: recorded human compile (`0` visible errors), human exact EditMode
  attestation (`7/7`), and final scoped `git diff --check` (`exit 0`, empty
  output).
- Tests rerun by Verifier: `none`.
- Git diff/status/history, identity rediscovery, Unity, Unity MCP, CUA,
  BatchMode, CLI, process/log/runtime inspection, and external Provider checks:
  `not run`.

### NOT RUN / DEFERRED And Residual Risk

Phase B runtime convergence, full EditMode and all PlayMode coverage, real
Provider/third-party Package-only installation, consumer and release checks,
Unity MCP, publication/promotion, and commit/tag/push remain
`NOT RUN / DEFERRED`. The human test result is not independently observable;
runtime behavior outside the named tests and the previously accepted
`CS0414` warning remain residual risk.

### Handoff

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current status: `PASS / TARGETED_VERIFIER_REVIEW_COMPLETE`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner/User disposition: `ACCEPT / FIX / DEFER / STOP`.

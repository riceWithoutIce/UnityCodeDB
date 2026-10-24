# S29 control authentication recovery: v3 independent verification PASS

2026-10-10. Verifier `/root/control_auth_verifier`, explicitly approved by User.
Base HEAD `9a2ca41e19baf125cae594eb10ceef6b28cfef9b`. Scope: the seven files in
CONTROL-AUTH-RECOVERY-SOURCE-SHA256.txt and immediate regressions of the frozen
POST-P1-READINESS-DIAGNOSIS-2026-10-10.md. Result: **PASS; B01 closed; no BLOCKER
or FOLLOW-UP.** Findings returned together to User; Verifier remained read-only.

User disposition, 2026-10-10: "同意 accept". The reviewed v3 seven-file source
snapshot is SOURCE_ACCEPTED; the scoped review is closed. This is source
acceptance only; the runtime and release limits below remain in effect.

## Admission and evidence

v1 freeze was invalidated by parent edits after dispatch. Verifier reported the
two mismatches. Parent stopped editing, published v2, and Verifier independently
admitted v2: all 7 hashes MATCH, including end-of-review verification. Parent's
final hash check also matches all 7. Scoped git diff --check PASS; staged index
empty. Unrelated dirty source outside scope, payload, docs and consumers preserved.

Independent command:
`dotnet run --project .artifacts/tests/s29-control-auth-recovery/Semantic.csproj -- run`
reports semantic 0 errors and 14 distinct methods / 30 cases PASS. The preceding
34-case count included six duplicate freshness cases; corrected evidence is used.

## B01: recovered authentication can strand Ready project in Starting (BLOCKER closed in v3)

Normal trigger: Installed, current instance, cleanup not Pending, existing Editor
lease, previousProductState Ready, scheduled force=false reconcile. Initial live
authentication times out; retry then authenticates successfully.

In the v2 snapshot, EditorLifecycle.cs:955 disabled lease prerequisite/start admission and published
Starting through RetryControlContractAuthentication. With an existing lease the
independent prerequisite branch is skipped. EditorLifecycle.cs:1247 still uses
the old previousProductState=Ready to decide backend work is unnecessary and
returns null. It skips the subsequent Probe, authenticated Ready publication and
lease prerequisite restoration. Cache remains Starting while last product state
remains Ready; reconnect refreshes Supervisor snapshot but not product status.
QueueLeaseRefresh checks prerequisite=false, so heartbeat stops. Later scheduled
reconciles can keep taking the same early-return path.

This contradicted the frozen successful-authentication recovery requirement and
could interrupt lease liveness on a normal user path. The user authorized a
narrow v3 fix: successful transient recovery now bypasses the old Ready/backend
no-op early return. A production-worker harness covers Probe, Ready publication
and lease restoration; independent v3 re-review is PASS and B01 is closed.
Runtime reproduction was NOT_RUN.

User authorized narrowly repairing B01 and adding the full recovery-path
regression evidence, then reviewing only B01 and its adjacent regressions. No queue
redesign, timeout extension, package/reference switching or Unity automation.

## Other scoped checks

- Transport versus invalid/foreign authority distinction, validation gates and
  multi-authority rejection: PASS at source/isolated level.
- Three total attempts, Starting/exhaustion NeedsAttention, cancellation and
  invalid evidence stopping retry: PASS at source/isolated level.
- No new transient/TimedOut terminal convergence failure; existing retention and
  newer authenticated Ready clearing rules: PASS at source/isolated level.
- Bridge timed_out parse/conversion, timeout refusal of authoritative terminal
  evidence, dispatched Manager outcome-unconfirmed: PASS at source level with
  conversion cases PASS.
- Manager source unchanged; 30-second freshness, reopen revision reset and
  display-only cache boundary preserved. Actual GUI reopen NOT_RUN.

No independent FOLLOW-UP finding. B01 is closed after v3 re-review.

## v3 re-review evidence

All 7/7 SHA256 values match the v3 frozen manifest; scoped `git diff --check`
PASS. `recoveredControlAuthentication` is set only after successful transient
authentication recovery, bypassing the old non-force Ready/backend early return
and continuing through the existing Probe, Ready publication and lease route.

Independent standalone validation: semantic compilation 0 errors;
14 distinct methods / 30 cases PASS; full worker regressions 5/5 PASS:

- Success: reads=2, probes=1, product=Ready, lease prerequisite=1.
- Missing proof: product=NeedsAttention, lease prerequisite=1.
- Probe timeout: product=NeedsAttention, lease prerequisite=0.
- Retry exhaustion: reads=3, probes=0, product=NeedsAttention, lease prerequisite=0.
- No timeout: Ready unchanged, lease prerequisite=1.

`run reproduce-b01` fails as expected with the old early-return condition,
demonstrating the former B01 path. No adjacent regression was found. Lease values
above describe prerequisite state in the harness, not real lease-file publication.

## Limits and terminal state

Verifier completed and stopped. No source edits, commits, export, reference
switch, service/process control, Unity/MCP/CUA/BatchMode or external messages.
Standalone uses explicit lifecycle initializer, SessionState/native path/time
and assertion adapters; no Unity import/EditMode, actual IPC timing, JsonUtility
round-trip, native GUI or release acceptance. S29/release remain PARTIAL.

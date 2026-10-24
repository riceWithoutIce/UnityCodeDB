# S42 delivery and single-retirement-entry preparation

Date: 2026-10-22. Status: PREPARATION_PASS / NOT_COMMITTED / NOT_DELIVERED.
No live consumer observation or control occurred in this preparation stage.

## Exact candidate

Two frozen Package sources still have RESULT.md hashes. Base remains
`186aacf0371ba64e47114306170b449dbca261c9`; branch remains
`codex/coordinator-query-readiness`. The isolated checkout has only these two
modified paths, no staged changes, and scoped git diff --check passes.

Prepared complete tree: `cf162955d6f3e89daa0bf32b3db8110219f161f6`.
An artifact-owned Git index/object directory projected the exact raw source
bytes onto the accepted base. Real Git index unchanged. No commit, branch update,
formal release ZIP or consumer Package copy was created.

Evidence root: `<repository-root>/.artifacts/tests/s42prep-a/`.

| Evidence | Result |
| --- | --- |
| Projected complete Package | 666 files; two source hashes match; inventory.json retained |
| Production materializer read-only payload admission | PASS, 62 declared files |
| Byte/hash/identity closure and native source/build/binary binding | PASS, zero mismatches |
| S42 focused fixture from actual projected Package | PASS, 7 scenario groups |
| S32 disposition fixture from actual projected Package | PASS, original child attribution/refusal checks |
| projection.json SHA-256 | `bdccf5f2b7f401fce7e84f0e13dcb370de3749d075afbfac31bee9780dd7d6fe` |

The projection is a preparation artifact, not a substitute for exact future
commit-stage and exact-ZIP closure. Package identity remains preview.5/poc.44;
source commit and artifact hash will identify this host-only repair.

## Concrete old-service retirement entry

Task-owned `retire-once.mjs` contains the actual bounded client flow;
`retire-live-adapter.mjs` binds it to the installed accepted Supervisor's original
owner/process validators and IPC transport, loaded without its executable entry.
Neither script is added to the Package or changes production runtime behavior.

Before live use the development session must record a new explicit human grant
and a short-lived approval JSON bound to both script hashes, project/pointer/
instance/activation, accepted old Package reference, Supervisor owner epoch and
lifecycle, coordinator PID/start identity/lifecycle. Historical observations are
only expected baselines; they are freshly validated and any drift stops the run.
The approval file itself does not grant authority. It must not be fabricated or
populated with human_authorized=true before the user actually authorizes this run.

The entry is invoked only as:
`node <task-directory>/retire-live-adapter.mjs --execute-approved <approved-receipt>`.
It has no default execution path. The normal Manager Restart is not substituted.

Client behavior:

1. Revalidate installed accepted source, selected binding and original authenticated
   Supervisor owner; inspect coordinator process identity and authenticated status.
   Stop on drift or unavailable evidence. No ensure/start/reconnect fallback.
2. Send **one** authenticated watcher:Stop with the expected coordinator lifecycle
   and a unique action correlation ID. Original maintenance queue may serialize
   behind a running Probe. Existing full-queue/owner/child-admission guards remain.
3. Observe only the returned operation ID, at most 90 reads at two-second spacing,
   within 180 seconds plus individual bounded IPC/probe overhead. This is terminal
   result observation, not a retry of Stop. Validate same owner, action, name and
   operation throughout. Rejection, missing response, owner/selection drift,
   malformed/failed terminal result or budget exhaustion ends with NO_REPLAY.
4. After successful terminal result, one recorded-coordinator process probe plus
   state-file absence/manual-stopped checks determine whether stop is confirmed.
   An ACK alone is insufficient. Do not kill a process or repair records if the
   postcondition is not established. No Supervisor shutdown or automatic restart.

It journals a safe dispatch trace before sending requests so lost-response runs
cannot be mistaken for unattempted Stop. Tokens/pipe/argv/raw runtime state are
not emitted. Original server-side observation/operation writes are expected once
a later mutation is authorized; the client's VM cannot write product files or
directly spawn services. Old Supervisor remains until its normal human-close
retirement boundary; later Start must account for manual-stopped state.

## Offline evidence and limits

`test-retirement-client.mjs s42retfixture-c`: **PASS**, 10 groups; live RPC=0,
real child starts=0. Tests execute actual client control logic with seams, plus
original Supervisor admitMaintenance and runWatchManager functions. Original
admission queues Stop behind an active Probe, preserves Probe and refuses a second
different queued request. The actual forwarder preserves ExpectedLifecycleId.

Client cases cover queue-to-terminal success, explicit lifecycle/correlation,
full-queue rejection, lost reply, owner/operation/selection drift, failed terminal,
180-second/90-read budget, postcondition failure, and no Stop replay.
Two earlier fixture runs lacked extracted publicOperation/coordinatorStatus
dependencies. These were the two mechanical corrections; their artifact roots
remain. No production defect or live failure was involved. Final run passed.

Artifact: `<repository-root>/.artifacts/tests/s42retfixture-c/result.json`.
SHA-256 `cbe1f36e062acd59c725693ffdc8f21054ef101febf7a588eb6c8147271e9d7e`.

| Script | SHA-256 |
| --- | --- |
| retire-once.mjs | `e2e8912f8e401688c361c481d1c6a956f9f4fd05fd83eaa0a3c1643fba55ce7f` |
| retire-live-adapter.mjs | `18c31428040d295f997cb0540ec76cddfb0ea960cfbbd65f2fe158a3b1ef733b` |
| test-retirement-client.mjs | `1623967c0a9e22e0456158f1cad06667b9066695e5d98eadfea9debb65da4cda` |

Both client modules pass Node syntax checks. Real Windows transport/queue timing,
actual expected-lifecycle stop and process exit are NOT_RUN. Live adapter owner
validation reuses the preflight approach, but the live adapter as a whole has not
been executed against the consumer; offline client flow is not live recovery PASS.
No independent reviewer or broad regression was invoked. No C# compile/runtime
claim, formal response-identity claim, freshness/performance or release claim.

## Next gate

Exact next grant is COMMIT-EXPORT-PROPOSAL.md: two-file isolated commit, exact
commit export/ZIP closure and two focused extracted-artifact checks only. No live
retirement, reference switch, Unity action or real MCP call is bundled into that
grant. Current Unity open confirmation is historical; this task did not rescan it.

Current status: PREPARATION_PASS.
Next notification: user.
Next action: approve exact source commit/export; later authorize single owned Stop
and human-close consumer delivery at their concrete risk boundaries.

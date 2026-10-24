# S29 version-transition observation — human Unity result

Date: 2026-10-14, Asia/Shanghai.
Status: HUMAN_FOCUSED_CONSUMER_TEST_PASS / MANAGER_INTERACTION_PASS /
SHUTDOWN_BLOCK_OBSERVED / REAL_RECOVERY_PENDING.

## Human evidence

User reported: `testrun 通过`, `关闭出现卡住`, `其余都正常`.
Test Runner screenshot shows
ManagerVersionTransition_ProductionObservationKeepsIdentityAndSafetySeparate
green, 1 passed / 0 failed, duration 1.091s. This is actual human Unity execution
of the authored isolated production-observation consumer test, replacing its
earlier Ignore and supplying the missing blocked Journal/session/UI assertion
execution. It is not a full-suite or live recovery/removal PASS. The remaining
requested Manager interactions are human-confirmed normal.

Manager screenshot still shows dependencies not configured / prerequisite
required and `Retained effects safety check is blocked: activation record does
not match its trusted contract or project context.` Historical d8c/f14 records
and the unrelated older orphan warning remain. The new truthful blocked-reason
wording is visible; real installation recovery or Ready is not established.
Do not infer fresh removal-preflight exit 4 execution from this screenshot.

Shutdown screenshot shows `Application.Shutdown.CleanupMono`, busy for 19s,
waiting for Unity code. This is another shutdown-block sample. Under the prior
user disposition, preserve it for observation without attributing it to this
repair or starting a shutdown fix. At the read-only process check S29 Unity
PID 26468 was still present. Eventual self-exit versus manual termination has
not been reported. No process was stopped by the agent.

User screenshots:

- C:/Users/admin/AppData/Local/Temp/codex-clipboard-a7f8eea3-e824-4175-9c4b-f5c68f5f706c.png
- C:/Users/admin/AppData/Local/Temp/codex-clipboard-869f88e6-d58b-4eba-b066-b461ec1e62c2.png
- C:/Users/admin/AppData/Local/Temp/codex-clipboard-a8ef7845-e39c-40a6-b50d-d4e473e2f6d1.png

## Post-human read-only checks

HEAD remains 14444cf1ad179fe29e067e8dcfdc7b0b5496e230; staged index empty.
Manifest/lock both select the exact delivered Package:
file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb.

Protected control hashes remain unchanged from delivery:

| File relative to control | SHA256 |
| --- | --- |
| desired-state.json | 0abe47370544c18fe074f34a1230109da5ebe3a5de4951cc40a08c5680933f3b |
| current-instance.json | e270b40b20409f484a395f522ac9e2afa451499a1bdb0b1bc3bbe28c583274c1 |
| contracts/v0.3-control/v2/activation.json | afdce4014bd4ef18998f56933ea0b3bd4ad7189feda9d0022875cc278ef390e3 |
| contracts/v0.3-control/v2/operation.json | 0995b8929e763a2defdfe219fb42375ffc236322b89af5eb730e94c17f0a0ad2 |

Default local Unity Editor.log identifies S29. A snapshot is preserved under
.artifacts/delivery/s29-version-transition-observation-14444cf/human-20261014/Editor-observed.log.
No causal or finished-shutdown claim is inferred from its tail.

No tests were rerun; no live product reader/Probe, Install/Remove/Upgrade,
history/index cleanup, process control, source repair, commit/export/reference
switch or Unity automation was performed during these post-human checks.

## Disposition

Focused human Unity consumer assertions PASS; Manager interactions are
human-confirmed. Earlier standalone runtime-log limitations remain historical
and are not retroactively labeled PASS. The retained-current-index message
branch still has static review only.

Real Manager prerequisite/context refusal remains unresolved. Original removal
preflight exit 4 remains a separate prior unresolved item. Unity close is not a
PASS in this sample. The user explicitly deferred CleanupMono shutdown handling
and excluded it from the current version-transition task; retain this sample
for later observation only. S29/release remain PARTIAL. Do not repeat
installation/packaging or implement a new repair from this sample without a
concrete approved scope.

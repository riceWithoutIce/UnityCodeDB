# Install quarantine admission — static closure and bounded repair plan

Date: 2026-10-26. Original status: STATIC_CLOSURE_COMPLETE / REPAIR_NOT_STARTED.
Follow-through: user "ok 继续" authorized implementation; TASK.md and RESULT.md
record the completed narrow source repair and focused harness evidence.
User agreed the narrow direction and asked to continue. This slice completes
the promised static reuse check and records the concrete repair/evidence plan.
It does not modify product source, execute tests or touch the consumer project.

## Problem and source boundary

Candidate baseline: `11056964da1143955ed69a067361622799e3d6f2`.
Failed action: `1a02434fd5424d379508b338318c1b65`.
Original evidence is preserved in the candidate-lifecycle-acceptance task's
FRESH-INSTALL-ATTEMPT-01-RESULT.md and named sanitized artifact. No new consumer
reads were needed for this static closure.

The Supervisor produces paired state/lock `.stale.<timestamp>.<id>` quarantine
records. Install's namespace allowlist rejects that shape before its existing
operation-history execution checks. The repair must distinguish verified inert
quarantine from current/unknown authority without deleting or activating it.

## Reuse decision

| Existing code | Decision |
| --- | --- |
| `Read-BoundedJsonDocument`, required typed property readers | Reuse; bounded strict parsing |
| `Assert-NoReparsePoint`, root/namespace path comparison | Reuse; no redirected or foreign input |
| Control-contract hash and expected pipe-name derivation | Reuse applicable pure identity producers |
| `Assert-RemoveIntegrationV2ProcessAbsent` | Reuse its read-only original-process-absence assertion: dead PID or valid changed start identity; live same identity and unknown remain blocked |
| `Assert-RemoveIntegrationOwnerRecord` | Do not call wholesale: depends on selected instance/generation/activation and trusted Package history |
| `Get-RemoveIntegrationV2NamespaceProof` | Do not call wholesale: removal-specific namespace inventory, fingerprint, selection and removal semantics |
| Install canonical/history/disposition/retained-holder checks | Retain unchanged; accepting quarantine must not skip later execution checks |

The existing absence assertion uses Windows UTC start ticks rounded to producer
microsecond precision. Do not substitute lease Unix-millisecond identity or
compare bare PID. PID reuse grants no right to act on the replacement process.
Its existing removal-oriented error text is not a reason to refactor shared
process infrastructure in this repair.

## Proposed minimum implementation

Primary file: `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`.
Add an Install-specific quarantine-pair reader/validator near its admission
helpers; collect exact recognized pairs in the existing runtime scan, then
validate before returning admission. History processing remains in the same
production path. Existing writer ownership, project lock, retained holder and
execution checks remain authoritative.

1. Recognize only regular files with the producer's exact state/lock stale
   pattern, grouped by common suffix. Keep unknown names, directories, current
   owner records and takeover claims blocked. Require complete pairs; enforce
   the existing removal-side bounds of at most 32 pairs and 256 KiB per record.
2. Check typed identity fields actually used by admission: managed role/schema,
   target project/root/runtime/control namespace and control identity, coherent
   owner identity, PID/start evidence, and matching pair identity fields. Reuse
   pure derivation helpers rather than embedding machine paths or pipe names.
3. Keep historical instance/generation/activation fields internally coherent
   and structurally valid. They must not be compared with a new selection or
   used to nominate an old Package as a trust root. No need to reopen every old
   instance, index, generation or Package. Dynamic readiness, heartbeat, auth
   token, UI and timestamps unrelated to process identity are not new admission
   requirements. Additional irrelevant producer metadata is not a new authority.
4. Apply the existing process-absence assertion to each coherent original owner.
   Live same-start identity, invalid/unavailable identity or conflicting pair
   blocks. Proved PID reuse does not block solely because the replacement PID
   exists, and does not authorize stopping it.
5. Preserve every quarantine file. Admit only continuation to the existing
   remaining Install checks; no activation/deletion/cleanup permission is minted.

No Supervisor producer change, generation payload edit, Manager/heartbeat change,
global fallback, history pruning or broad shared-validator extraction is needed.
If implementation cannot meet this scope without a new historical dependency,
return that concrete design conflict rather than expanding silently.

## Focused evidence proposal

Test file: `com.rice.ai-codedb/Tests~/test-codedb-install-quarantine-admission.ps1`
(new focused fixture). Run original production admission/helper functions using
existing AST harness conventions. Synthetic OS/retained prerequisites must be
declared; the validator under test must not be stubbed. Assert preserved input
bytes and no consumer mutation. Classification: HARNESS, not live acceptance.

Cover only this finding and its adjacent regressions:

- Complete coherent historical pair, differing from current selection and old
  owner proved absent: admission reaches/passes remaining valid gates.
- PID reuse with valid changed start identity: original owner absent; replacement
  process never stopped. Live original and unknown identity: reject.
- Missing counterpart, mismatched owner/project/namespace, malformed identity,
  redirected/oversized record, unknown/current/takeover entry: reject.
- No quarantine pair: existing baseline unchanged. Accepted pair cannot mask
  pending/incomplete/unknown operation history or a live child.
- Production entry still requires its existing writer/project-lock context;
  this helper is not another Install entry or deletion authority.

Use repository-owned unique roots under `.artifacts/tests/`, child-local temp and
LOCALAPPDATA, no network, real Provider, Unity or external process control.
Parse changed PowerShell and run this focused test plus directly affected
`test-codedb-retained-mcp-install.ps1 -L0Only`. Do not automatically launch the
broader convergence scenarios or all historical tests. Preserve first failures;
same-cause fixture/mechanical corrections do not become real Install retries.

## Workspace and stage boundaries

Implementation should use a new repository-local checkout
`.worktrees/cdb-v03-install-quarantine-admission`, based on the fixed candidate,
with branch `codex/install-quarantine-admission`. Preserve the primary checkout's
dirty acceptance records and existing dirty worktrees. No C-drive worktree or
reuse/reset of the older heartbeat checkout. No agent delegation is required.

This turn did not create that checkout, change product code, run tests, query
live processes/leases, execute Install or alter CodedbTest_2. The existing scene
and quarantine are retained for later real regression.

Source repair/focused evidence, candidate commit/export, delivery/reference
switch and human real-environment acceptance are distinct stages. No source
acceptance can stand in for Fresh Install PASS. After source evidence, agree the
delivery separately; human closes Unity before any Package switch. Then one
normal human Install against the preserved project, with original failure kept,
no manual quarantine deletion or forced holder drain. No unchanged retry now.

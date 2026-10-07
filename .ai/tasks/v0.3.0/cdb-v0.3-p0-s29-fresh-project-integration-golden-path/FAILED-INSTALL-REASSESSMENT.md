# S29 Failed Install - Bounded Recovery Reassessment

Date: 2026-10-07. Status: PREPARATION_COMPLETE / SOURCE_REPAIR_DECISION_REQUIRED.
Base: 13bf5fd16c15c42e1379ce35a06e49c20753195f.
This document completes the next read-only preparation under the standing
pre-human-validation instruction. It proposes a coherent product change; it
does not authorize or perform runtime cleanup, source repair or another Install.

## Outcome And Observed State

The accepted poc.40 parser repair and exported Package remain valid. The next
blocker is failed-install finalization and retry admission, not another Package
hash or parsing failure. Preserve the existing artifact and acceptance.

Project: UnityFreshInstallValidationProjectS29.
Candidate: AIWork/.runtime/codedb/instances/330b7a972a7649259409fbce4de8ca56.
The prior scoped inventory found control absent and that single PROVISIONING
poc.39 instance. The continued bounded inventory now finds exactly:

- instance.json, 1234 bytes, SHA256
  13cb910b889aa671024ad97a70e69601289be8892b4613b8494cdedcd526aeec.
- watch/lifecycle/editor-leases/f9ed754a9c1f483cb3762478db5a2a7d.json,
  506 bytes, SHA256
  fb6e97c254ef2df932434a0afd45cb779d9c823c04a3b97141b3c633ce94a9e3.
- Nine directories: adapter, config, index, leases, logs, tmp, watch,
  watch/lifecycle, watch/lifecycle/editor-leases. All except the lease's ancestor
  directories are empty; no index, adapter, config, log or worker lease file.

Inventory was bounded to 128 entries and checked ancestors/entries against
reparse traversal. No writes or process queries occurred. The editor lease's
project identity, session ID, recorded PID 200188 and process-start ticks
639269524078002697 match the admitted Install arguments. Last heartbeat is
2026-10-07T07:06:02.8808420Z. Human has reported normal Editor closure.
Neither heartbeat age nor matching PID values independently proves holder exit;
no automated live-holder assertion was made.

Manager action d8c736504562495dbafdd673c6851efb and candidate origin
73c9d6a0a8ba4df0898721265ec515d6 are different identifiers. Lease/session and
timing now give additional correlation, but do not rewrite either identity or
create a missing durable Manager-to-candidate link.

## Confirmed Source Gaps

Paths below are relative to com.rice.ai-codedb.

| Gap | Evidence | Consequence |
| --- | --- | --- |
| Direct Manager materializer invocation omits origin IDs | Editor/AICodedbHostPayloadMaterializer.cs BuildRuntimeScriptArguments forwards Editor lease identity, but no origin action/operation. Actual admitted Install arguments confirm the omission. Tools~/codedb-instance-engine.ps1:4395 generates fallback IDs. Supervisor route already forwards these IDs at Tools~/codedb-project-supervisor.mjs:2022. | Two existing invocation routes produce different attribution quality. |
| Failure still requests lifecycle reconciliation | Editor/AICodedbActions.cs RunInstallCodeDB/Async unconditionally calls RequestReconcile after a result. ManagerWindow's CanRequestPostCommandReconcile already requires success, so this action-layer request bypasses that gate. | Recorded failed Install is followed by DryRun and a refused Upgrade. The failed result must remain primary; a later attempt's COMPLETE cannot resolve its PENDING effects. |
| Normal uninstall requires successful activation | Tools~/codedb-instance-engine.ps1 Get-CurrentProjectRemovalAuthority requires selected and COMMITTED activation evidence. Invoke-InstanceUninstall calls next-change admission before recovery. With no control binding, the retained instance fails admission. | Failed preparation is neither authenticated Installed nor empty first-install state; ordinary Uninstall/Install cannot close it. |
| Existing recursive retirement helper is not sufficient authority | Remove-ValidatedRetiredInstance publishes retirement controls and recursively deletes the instance after holder checks. The accepted project-integration contract explicitly protects unattributed mutable content. | Do not call that helper against this observed candidate merely to force admission, or change PENDING to COMPLETE by removing evidence. |

poc.39 prepare enters shared context validation before runtime/config work.
The candidate builder runs prepare before adapter/watcher startup. The recorded
parse failure is consistent with the mostly empty candidate. This source order
is evidence for a narrow recovery classifier, not blanket proof that every
failed candidate has no effects. Existing watch Stop also loads that old context,
explaining why normal catch cleanup failed. Old generation bytes stay immutable.

## Proposed One Continuous Same-S29 Repair

Purpose: after a failed first Install, show the original failure and provide one
authenticated project-integration removal/finalization route; only its terminal
result may admit a new Install. Keep the agreed uninstall/reinstall user flow.

1. Unify invocation attribution at the existing command admission boundary.
   Carry the real Manager action and stable per-operation identity into direct
   materializer calls just as Supervisor does. Bind them before command hashing
   and record publication; preserve identity across any existing fallback.
   A standalone invocation may generate its own identity once, but must not
   claim it is the Manager ID. No hard-coded observed action/session IDs.
2. Make failed Install completion observational. Reuse the existing successful-
   result gate at action and lifecycle entry points. A failed/pending/unknown
   candidate must not implicitly trigger another Upgrade or Install. Cached
   status refresh is allowed and must retain the original failure and effects.
3. Extend the existing confirmed project-uninstall authority with a distinct
   failed-preparation case. Installed activation admission and removability are
   separate decisions. Validate exact project/path/manifest/generation ownership,
   absence of conflicting active selection/activation, known effect boundary,
   and holder state before publishing a recovery/removal intent.
4. Preserve durable intent before effects, use the existing project lock and
   exact byte/path rechecks, and publish authenticated Uninstalled only after
   integration authority/registration is proved absent or deactivated. Physical
   cleanup remains a separate COMPLETE/PENDING fact. Retain unknown mutable
   content and live holders; never infer ownership from attribution alone.
5. Include the current pre-fix record shape as an explicit bounded fixture:
   PROVISIONING instance plus matching editor lease, no control, absent direct
   Manager/backend ID link. Recovery binds the actual observed manifest and its
   project ownership without fabricating a historical operation link. If required
   ownership/effect facts remain unavailable, return a concrete fail-closed
   review result; do not introduce machine-wide historical recovery.

The design must resolve the existing host/bootstrap residue as part of the same
authenticated removal result; deleting only the candidate cannot justify empty
first-install admission while host/runtime materialization remains.

## Implementation Boundary To Freeze Before Coder

Candidate owning paths (modify only the necessary subset):

- Editor/AICodedbHostPayloadMaterializer.cs
- Editor/AICodedbActions.cs
- Editor/AICodedbProcessRunner.cs (only action/operation binding before receipt)
- Editor/AICodedbManagerWindow.cs (existing post-result gate / removal presentation)
- Editor/AICodedbEditorLifecycle.cs (only directly coupled automatic convergence)
- Tools~/codedb-instance-engine.ps1
- Tools~/materialize-codedb-host-payload.ps1
- Tests/Editor/AICodedbManagerUiTests.cs
- Tests/Editor/AICodedbEditorLifecycleTests.cs
- Tests~/test-codedb-host-payload-materializer.ps1

Before implementation, map any changed recovery record through actual C#/PS/
Node readers and freeze the precise schema/record locations and coupled test
paths. Reuse existing operation/removal machinery and counters; do not add a
second recovery executor, generic migration platform, or competing uninstall
button. If the shared contract requires another concrete consumer file, admit
it in one consolidated map before edits, not a trail of speculative allowlists.

The existing Manager UI action attribution and recovery readers may require
additional narrowly named paths after this map. This proposed list is not a
claim that those dependencies are already closed. No generation change is
presumed: prefer Package-owned control fixes. If a generation-owned reader must
change, use a reviewed successor and canonical generator; never edit poc.39 or
the delivered poc.40 in place.

## Focused Evidence And Acceptance

- Actual direct invocation carries Manager/operation identity into the actual
  serializer and receipt; cover the Supervisor/direct fallback boundary.
- Failed Install and cleanup PENDING do not schedule Upgrade; successful Install
  keeps its normal status reconciliation. Test the action-layer entry, not only
  the already-passing ManagerWindow helper.
- Production failed-candidate fixture: empty owned candidate plus editor lease,
  no control records, pre-prepare parse failure, retained host/bootstrap content.
- Confirmed removal produces a durable, attributable terminal state; then one
  fresh Install is admitted with a new instance identity.
- Conflicting project/manifest/hash/path, selected/active candidate, live or
  ambiguous holder and unexpected mutable content preserve bytes and refuse
  unsafe deletion. Include interrupted finalization and one replay using the
  existing focused harness, without full unrelated regression.
- Fixtures use runtime-derived owned temporary roots and real writer/reader
  boundaries. No real candidate, Provider, Unity or process mutation in source
  tests. C# authored checks are not executed Unity evidence.
- Stable child Coder result -> targeted independent child Verifier; findings
  once to User, no concurrent review edits or automatic follow-up repair.

New exact-artifact delivery and one human golden-path session follow source
acceptance. The existing 48-case human PASS is retained rather than replayed as
preparation. Actual recovery of this project requires a concrete reviewed
mutation scope at that later boundary; the current diagnostic grants none.

## Decision Boundary

Read-only diagnosis and preparation are complete. No tests, product source,
candidate/lease/control bytes or exported artifacts were changed this turn.
The next implementation adds/changes product recovery behavior and associated
record authority; it is beyond the already accepted parser repair and the
standing preparation grant. Request one coherent source-repair decision, then
freeze the consumer/schema map and run the approved child pipeline. Do not seek
per-command permission or invite another human Install before this is ready.

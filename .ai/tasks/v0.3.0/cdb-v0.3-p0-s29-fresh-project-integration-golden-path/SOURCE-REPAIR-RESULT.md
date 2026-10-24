# S29 Source Repair checkpoint — 2026-10-05

Status: CHECKPOINT / INCOMPLETE. This is an immutable source-work checkpoint, not SOURCE_REPAIR_COMPLETE, full static semantic acceptance, or SCOPED_NON_UNITY_EVIDENCE_PASS.

## Window and frozen input

Original start: 2026-10-05 07:29:21 UTC. Final evidence ended 08:29:13 UTC: 59m52s conservative elapsed window. Active versus paused time cannot be reconstructed precisely: unavailable; no pause discount or budget reset was assumed. Stop implementation at the original DEEP_60M boundary; record finalization only follows. The notification-only interruption did not renew the window. Same session/profile preserved; actual model/reasoning identifiers unavailable; no subagent/new session.

Branch admission reused: codex/v0.3.0-legacy-workflow. Final HEAD: b15292f8978272244e605805a9ec064049141ee2. Four read-only contract hashes matched the supplied grant earlier in this same window; not repeated. All inherited dirty state, Stage A RESULT.md/HUMAN-CHECKLIST.md, TASK, metadata, Payload, consumed artifacts and validation projects were left unchanged by Coder.

## Actual source/test changes (nine)

- com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs
- com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs
- com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
- com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs
- com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs
- com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs
- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1
- com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
- com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1

- Engine: add target-bound first-Install evidence checks distinct from UNINSTALLED; revalidate first-Install evidence under the project lock. Existing strict next-change admission and verified-before-activation checks were not relaxed.
- Supervisor remains the operation/action owner: forward its persisted operation_id and, when present, manager_action_id to the materializer invocation. No new queue, owner or persistence service.
- Materializer accepts those identifiers. Engine creates an originating_action object, retains it in the candidate manifest, writes PROVISIONING manifest before candidate child directories, and supplies a by-reference candidateAttempt to the outer catch before candidate creation. Existing selection/control writers remain unchanged.
- Native incomplete-observation errors retain observed exit/stdout/stderr text and the native result in Exception.Data. Incomplete observation or a retained attempt path maps cleanup to PENDING even before the candidate return. Explicit exit handling occurs after outcome mapping; automatic replay promise removed.
- Integration/status: additive NotIntegrated classification and cache projection, separate from authenticated Uninstalled/StateId. Absence of desired state alone is not sufficient; check reviewed resource anchors and bounded project-local MCP registration text on the worker reader, not Manager observation.
- Lifecycle: NotIntegrated returns a cache projection without Supervisor/coordinator admission; Manager uses the cached state to offer Install through the existing confirmed action, including Setup. No instrumentation counters changed.
- C# regression authored: no-integration first Install without removal history, no Editor lease, and existing resource anchors preventing a false first-Install classification. These tests are NOT RUN.

AICodedbActions.cs, AICodedbManagerActionJournal.cs, AICodedbControlContract.cs, AICodedbManagerUiTests.cs and both behavioral harness files remain byte-unchanged in this checkpoint.

## Remaining closure / risks (same S29, not new microtasks)

1. Source implementation is an unaccepted draft. Full semantic/structural review and isolated production-function fixtures have NOT been completed. No existing-project recovery or Ready claim is made.
2. FirstInstallAttributionOnly selector/family is not yet authored. It must cover fresh versus authenticated reinstall, pre-return retained and unknown effects, verification before activation, and unbound/foreign/drift refusal. Existing NextChangeAdmissionIntegrationOnly has not been run after these edits.
3. Check the complete first-Install execution/preflight/result consumers, additive manifest-origin consumer compatibility, and crash-before-manifest behavior. The root directory is necessarily created before its instance.json; no new direct-command durable receipt was added. Do not claim the entire durable-before-effects requirement is proven. Standalone materializer correlation currently derives per-command identifiers; Supervisor already has a durable originating operation.
4. C# reader conservatively treats an existing control directory as integration evidence, whereas backend first-Install classification can admit a validated Supervisor-only namespace. Reconcile their intended transition/cache behavior in the same allowlisted continuation; no behavioral proof currently exists.
5. Other Manager title/state routing, restored-cache projection, migration precedence and direct action-result paths need focused completion review and closest tests. No compile/EditMode evidence exists.
6. Existing strict next-change admission still refuses retained unbound/unverified candidates; this checkpoint does not retrofit attribution, adopt or clean the real S29 candidate.
7. Mandatory PathProvenanceOnly and conditional manager-action-correlation Node gate remain NOT RUN. Production Supervisor changed, so its focused evidence is required, not NOT_APPLICABLE.

## Commands and actual evidence

### one bounded partial static/source batch

Command:
```powershell
$s29parse=@('com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1','com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1'); foreach($s29p in $s29parse){$s29tok=$null;$s29err=$null; $null=[Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) $s29p),[ref]$s29tok,[ref]$s29err); if(@($s29err).Count){$s29err | ForEach-Object {$_.Message};exit 1}; Write-Output ('AST PASS '+$s29p)}; node --check com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; $s29engine=[IO.File]::ReadAllText((Join-Path (Get-Location) 'com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1')); $s29life=[IO.File]::ReadAllText((Join-Path (Get-Location) 'com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs')); $s29cache=[IO.File]::ReadAllText((Join-Path (Get-Location) 'com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs')); if(-not $s29engine.Contains('-CandidateAttempt ([ref]$candidateAttempt)') -or -not $s29engine.Contains('InstanceNativeResult') -or -not $s29life.Contains('if (integrationStatus.IsNotIntegrated)') -or -not $s29cache.Contains('cachedNotIntegrated')){throw 'Direct partial-source routing assertion failed.'}; Write-Output 'PASS: changed PS AST, Node parse, direct attempt/cache/lifecycle source markers. This is partial source evidence, not complete semantic acceptance.'
```
Exit: 0; wall time: 0.474 s.
Output: PowerShell AST PASS (engine/materializer), Node parse exit 0; limited direct attempt/cache/lifecycle marker checks PASS, explicitly not complete semantic closure.

### final fifteen-path scoped diff check

Command:
```powershell
git diff --check -- 'com.rice.ai-codedb/Editor/AICodedbActions.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs' 'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs' 'com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs' 'com.rice.ai-codedb/Editor/AICodedbControlContract.cs' 'com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs' 'com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs' 'com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1' 'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1' 'com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs' 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs' 'com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs' 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1' 'com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs'
```
Exit: 0; wall time: 0.268 s.
Output: Empty output; whitespace check PASS.

### unique final fifteen-path actual-byte identity and changed subset

Command:
```powershell
$s29paths=@('com.rice.ai-codedb/Editor/AICodedbActions.cs','com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs','com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs','com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs','com.rice.ai-codedb/Editor/AICodedbControlContract.cs','com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs','com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs','com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs','com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1','com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1','com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs','com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs','com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1','com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs'); [Array]::Sort($s29paths,[StringComparer]::Ordinal); $s29rows=@($s29paths | ForEach-Object { $_+[char]9+(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant() }); $s29text=($s29rows -join [char]10)+[char]10; $s29bytes=[Text.UTF8Encoding]::new($false).GetBytes($s29text); $s29sha=[Security.Cryptography.SHA256]::Create(); try { $s29digest=([BitConverter]::ToString($s29sha.ComputeHash($s29bytes))).Replace('-','').ToLowerInvariant() } finally { $s29sha.Dispose() }; Write-Output ('IDENTITY '+$s29digest); Write-Output ('HEAD '+(git rev-parse HEAD)); $s29rows; git diff --name-only -- 'com.rice.ai-codedb/Editor/AICodedbActions.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs' 'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs' 'com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs' 'com.rice.ai-codedb/Editor/AICodedbControlContract.cs' 'com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs' 'com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs' 'com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1' 'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1' 'com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs' 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs' 'com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs' 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1' 'com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs'
```
Exit: 0; wall time: 0.473 s.
Output: HEAD matched the original frozen HEAD; fifteen rows and nine changed source/test paths; digest 85886aebf9a8e7f268925594a1522f09cca48166fa00f66206eadc4572496519.

## Budget ledger

- Bounded static/source: 1 initial batch executed, exit 0; only AST/Node parse and limited direct source assertions closed. Full semantic scope remains INCOMPLETE. Corrected evidence attempts: 0.
- Mechanical edit correction: one apply_patch expected-context failure; corrected without running tests. Additional small pre-evidence parameter-name cleanup was performed; no runtime evidence was inferred. No semantic test retry consumed.
- FirstInstallAttributionOnly L0: 0 executed, NOT RUN (fixture not authored).
- NextChangeAdmissionIntegrationOnly affected non-Unity L1: 0 executed, NOT RUN.
- manager-action-correlation Node focused gate: 0 executed, NOT RUN, required because Supervisor changed.
- PathProvenanceOnly: 0 executed, NOT RUN.
- Final exact fifteen-path diff-check: 1, PASS.
- Final source identity calculation: 1, fifteen actual-byte rows; no whole-repository identity/diff.
- Captured command output in retained repair ledger: 255951 UTF-8 bytes. The output guard was exceeded during bounded reads; acknowledged in commentary and subsequent reads reduced to essential symbol slices. This does not retroactively establish output-budget compliance. Notification-only tool output is separate, not included in the source-evidence ledger.
- Context compactions: at least 1 supplied checkpoint; exact total unavailable. Active/paused breakdown unavailable. No active-window restart, automatic retry or extra scenario was performed.

## Final identity

SHA-256: 85886aebf9a8e7f268925594a1522f09cca48166fa00f66206eadc4572496519

SOURCE-REPAIR-IDENTITY.txt contains only the ordinal-sorted forward-slash path, TAB, lowercase SHA-256 of each file's actual bytes, with LF lines and final LF, UTF-8 without BOM. Stable checkpoint means no further source writes after this digest; it is not an accepted repair or Stage A artifact identity.

## NOT RUN / DEFERRED

C# compile/L1/EditMode, Unity/MCP/CUA/BatchMode, real Provider/operations/process probing, original preparation-error classification, real candidate recovery/cleanup/adoption, actual Install/Remove/Reinstall, artifact export/Package switch, operational MCP/client exposure, full regression, release acceptance and Verifier: NOT RUN / NOT AUTHORIZED. No commit/push/tag/publication or protected project/runtime reads.

## Consolidated same-S29 reassessment and completion route

The original conservative time window is exhausted. Continue only after Planner/User grants a new bounded same-S29 window on this exact draft identity, with the remaining source/fixture closure and unrun gates above. Do not automatically refresh budgets or dispatch Verifier; do not consume the draft Package in a real project.

Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: CHECKPOINT / INCOMPLETE (original window exhausted; partial source evidence only)
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner review this frozen draft checkpoint and decide same-S29 continuation authorization
Human decision or authorization required: further active time/evidence; later runtime recovery, Unity/C# acceptance, export, Verifier routing, commit and release


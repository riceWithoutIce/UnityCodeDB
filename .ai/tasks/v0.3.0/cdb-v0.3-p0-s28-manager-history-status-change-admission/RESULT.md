# RESULT: cdb-v0.3-p0-s28-manager-history-status-change-admission

## Disposition

- Status: ROUTE_REASSESSMENT_REQUIRED; new-change safety proof BLOCKED.
- This is the consolidated stopped Coder result, not implementation completion,
  a passing admission, or S25 acceptance.
- Trigger: TASK's explicit "inability to bind relevant process evidence" source
  preflight stop condition. No identity drift or concurrent source modification
  was observed in the scoped final snapshot.
- Source/test edits: none. The only Coder-written file is this RESULT.md.
- No old action disposition, receipt, stage, index, or warning was changed.
- The same S28 task remains the route; no micro-task or sub-agent was created.

## Execution attribution and time

- Profile/session: v0.3.coder.deep; DURABLE_SESSION / REUSE_ONLY.
- Actual model: unavailable from the current execution interface. The inherited
  continuation summary reports GPT-6, but this run did not independently verify
  a model setting. The profile name is not evidence of the actual model.
- Actual reasoning effort: unavailable; not inferred from profile-map defaults.
- Original start: 2026-10-01 09:50:03 UTC; the initial preflight/read work was inherited.
- Source work stopped and final source identity captured: 2026-10-01 10:14:26 UTC.
- Start-to-source-stop wall time: 24 minutes 23 seconds, including intervening
  notification/idle time; the DEEP_60M allowance was NOT reset on continuation.
- Exact active/paused split: unavailable. No per-phase timer was retained, so
  these values are not invented.
- Compaction count: at least one supplied handoff summary; exact total unavailable.
- Cumulative captured output: unavailable, including inherited/truncated reads.
  Tool original_token_count values are not misrepresented as captured byte counts.
- No sleep/poll loop, process inventory, or runtime scenario was performed.

## Frozen and stopped snapshot

- Branch: codex/v0.3.0-legacy-workflow.
- Preflight HEAD and final HEAD:
  aaea58a0262c99a7901b39a8309e94b126111b00.
- Preflight and final ordered eleven-path SHA-256:
  e4167a4693acedae9bd0c511941fdfc73f24be2ac32040a8c35522cc25c0a7bb.
- Same TASK algorithm: ordered relative-path/space/lowercase-file-SHA256 rows,
  LF joined without a trailing LF; SHA-256 of UTF-8 bytes.
- Final scoped git status returned no source/test modifications.
- All eleven source/test files, including AICodedbActions.cs, remain byte-identical
  to the admitted input. Task-card continuation edits remain Planner-owned.

```text
HEAD=aaea58a0262c99a7901b39a8309e94b126111b00
BRANCH=codex/v0.3.0-legacy-workflow
FINAL_ORDERED_11_PATH_SHA256=e4167a4693acedae9bd0c511941fdfc73f24be2ac32040a8c35522cc25c0a7bb
com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs bb92b0bcda4115855cb4a77ee2700337636b948c9968a7b01f49169c36e4e395
com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs d50de776ef8ac6d98d254f9abbfc8f3d49a81f7cb7156a94b015878e10252414
com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs ebc7118a9f3ca7c51f2e2889431e1bdd14d5abbebc027d9c241e24f08f27b6c5
com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs a0c15e7d77650264e9d294893f57d4be68173e8653059765d618006348b17464
com.rice.ai-codedb/Editor/AICodedbActions.cs 2a25e7798e38c19fda2849619072a0ce94cbaa372be0eb70566281a6ff69b1ec
com.rice.ai-codedb/Editor/AICodedbPaths.cs eb571172bac6afd7dd34ec85f3088d8a0f6a6fb71505a8ff67336efbbf858b28
com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 031e0bc5025ecbf91c69783379a580f00fb4d554ff62c02d15514b8b7453fa23
com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1 f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4
com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs 50b1d108c80e64e705d121b7c620768e8108025a54704673e5e3e8edeb874ae4
com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 0a4ad7f786a5ad929b3db907e0af94f779a2ab2b544b819af0958be209bea059
com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 dcd21d38e12ea9cb1e90067c2c19ea7dfd9b8e647f8803d639c7297b4d4c8bd1
```

## Concrete proof gap

The problem is the completeness/binding of the relevant execution set, not
whether an old command succeeded. No live-project claim is made here.

1. S25's frozen ROUTE-REASSESSMENT.md, lines 29-36, records that the historical
   Install stage contains only admitted.json and claim.json; the original
   writer is no longer visible. The record itself explicitly says that these
   facts do not establish the original command outcome. It contains no
   authenticated original materializer-child identity or complete transient
   business-child closure to use for this admission.
2. Tools~/invoke-codedb-manager-action.ps1, lines 228-239, durably publishes
   claim.json with the writer PID/start identity only, before child.Start().
   Lines 275 and 338-362 keep the child PID locally and finally put child_pid
   in terminal.json. A crash/exit without that terminal therefore leaves the
   frozen admission/claim shape without durable child identity. This is NOT
   reclassified as pre-effect refusal.
3. Tools~/codedb-instance-engine.ps1, Invoke-InstancePowerShellScript,
   lines 2161-2190, starts business PowerShell scripts through the existing
   materializer helper, passing project and instance context in environment
   variables. New-VerifiedInstanceCandidate, lines 2350-2379, invokes runtime
   preparation, adapter construction, watcher management, and candidate
   verification. Transient preparation/adapter children are not just the
   persistent authenticated query owner.
4. Tools~/materialize-codedb-host-payload.ps1,
   Invoke-BoundedNativeProcess (350-417) and
   Invoke-BoundedNativeProcessWithFileOutput (419-539), retain process handles
   during the parent invocation but publish no durable Manager-action-to-child
   PID/start binding. Their returned exit/output values are not durable
   descendant evidence if their parent exits first.
5. Enter-MaterializerLock (2771 onward) uses FileShare.None. Availability of
   this parent-held lock, or valid desired/activation/current-instance files,
   cannot by itself prove that an already launched child has stopped.
   No parallel lock/status authority was added.
6. The read-only Supervisor path was also considered. Its existing operation
   contains manager_action_id and it can record an exact immediate child in
   recordChildEvidence (2358 onward); however runMaterializer (2014 onward)
   does not carry an action-bound descendant proof through the instance
   scripts. prepareOperationChildEvidence first persists child=null and
   queueChildEvidenceCapture is asynchronous. These records are not evidence
   for an unrelated historical direct-writer Install, and no historical
   Supervisor operation was presumed to exist.

A current exact project-script command line can identify a *visible* relevant
process. It is not, without a complete bound process set, proof that no
unobservable/orphaned relevant process remains. Conversely, rejecting every
unrelated or inaccessible PowerShell process would violate S28's project-scoped
proof requirement. The inspected durable history does not supply the missing
binding needed to distinguish these cases safely.

Changing allowed writer/materializer source now can improve future evidence,
but cannot backfill authentic child identities into the frozen old records.
An authenticated selected Coordinator proves that Coordinator's ownership;
it does not retroactively prove all transient Install children stopped.
Current Ready, PID absence, elapsed age, generation change, an idle lock, or
a synthetic mock is not substituted for that proof.

This is why implementation stopped before introducing a nominal permit that
would either remain unusable for the causal history or weaken its safety claim.
It is not a claim that all possible alternative proof designs are impossible;
the frozen proof source/contract is insufficient for a safe passing branch.

## Evidence commands and outcomes

### Inherited bounded preflight

Executed once before this continuation, not repeated:

- exit: 0; wall: 0.3634147 seconds.
- Confirmed branch/HEAD, ordered eleven-path identity and clean scoped source.
- The untracked S28 task directory and inherited unrelated state were retained.

### One bounded source-closure diagnostic

This command only parsed two existing PowerShell files and inspected their
named AST assignments/functions. It did not dot-source or execute either
script, run a fixture, read runtime documents, or enumerate processes.
Exit 0 means the diagnosis matched the inspected source; NOT product PASS.

Exact shell command:

```powershell
$s28WriterPath = 'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1'; $s28WriterTokens = $null; $s28WriterErrors = $null; $s28WriterAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) $s28WriterPath), [ref]$s28WriterTokens, [ref]$s28WriterErrors); if (@($s28WriterErrors).Count -ne 0) { throw 'Writer AST parse failed.' }; $s28Assignments = @($s28WriterAst.FindAll({ param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] }, $true)); $s28Claim = @($s28Assignments | Where-Object { $_.Left.Extent.Text -eq '$claim' }); $s28Terminal = @($s28Assignments | Where-Object { $_.Left.Extent.Text -eq '$terminal' }); if ($s28Claim.Count -ne 1 -or $s28Terminal.Count -ne 1) { throw 'Exact claim/terminal assignment cardinality changed.' }; if ($s28Claim[0].Extent.Text -notmatch 'writer_pid\s*=' -or $s28Claim[0].Extent.Text -notmatch 'writer_start_utc_ticks\s*=') { throw 'Writer claim binding differs from inspected source.' }; if ($s28Claim[0].Extent.Text -match 'child_(pid|start|identity)\s*=') { throw 'Claim unexpectedly contains child binding; reassess the diagnosis.' }; if ($s28Terminal[0].Extent.Text -notmatch 'child_pid\s*=\s*\$childPid') { throw 'Terminal child PID binding differs from inspected source.' }; Write-Output ('WRITER_CLAIM_LINES=' + $s28Claim[0].Extent.StartLineNumber + '-' + $s28Claim[0].Extent.EndLineNumber); Write-Output 'CLAIM_BINDS_WRITER_ONLY=true'; Write-Output ('TERMINAL_LINES=' + $s28Terminal[0].Extent.StartLineNumber + '-' + $s28Terminal[0].Extent.EndLineNumber); Write-Output 'CHILD_PID_DURABLE_IN_TERMINAL_ONLY=true'; $s28MaterializerPath = 'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1'; $s28MaterializerTokens = $null; $s28MaterializerErrors = $null; $s28MaterializerAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) $s28MaterializerPath), [ref]$s28MaterializerTokens, [ref]$s28MaterializerErrors); if (@($s28MaterializerErrors).Count -ne 0) { throw 'Materializer AST parse failed.' }; foreach ($s28Symbol in @('Invoke-BoundedNativeProcess','Invoke-BoundedNativeProcessWithFileOutput')) { $s28Function = @($s28MaterializerAst.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $s28Symbol }, $true)); if ($s28Function.Count -ne 1) { throw ('Function cardinality changed: ' + $s28Symbol) }; Write-Output ($s28Symbol + '_LINES=' + $s28Function[0].Extent.StartLineNumber + '-' + $s28Function[0].Extent.EndLineNumber); Write-Output ($s28Symbol + '_DURABLE_ACTION_CHILD_BINDING=' + [bool]($s28Function[0].Extent.Text -match 'manager_action_id|ReceiptPath|writer_start_utc_ticks|child_pid\s*=')) }; Write-Output 'CONCLUSION=SOURCE_PROCESS_BINDING_GAP; no runtime or synthetic test was executed.'
```

- exit: 0.
- wall: 0.8762728 seconds.
- output:

```text
WRITER_CLAIM_LINES=228-239
CLAIM_BINDS_WRITER_ONLY=true
TERMINAL_LINES=338-362
CHILD_PID_DURABLE_IN_TERMINAL_ONLY=true
Invoke-BoundedNativeProcess_LINES=350-417
Invoke-BoundedNativeProcess_DURABLE_ACTION_CHILD_BINDING=False
Invoke-BoundedNativeProcessWithFileOutput_LINES=419-539
Invoke-BoundedNativeProcessWithFileOutput_DURABLE_ACTION_CHILD_BINDING=False
CONCLUSION=SOURCE_PROCESS_BINDING_GAP; no runtime or synthetic test was executed.
```

Adjacent reads were limited to named direct references and frozen documents:
Manager journal/session/result recovery, materializer process helpers/lock,
instance candidate child call sites, Supervisor operation child persistence,
S25 route evidence, current payload-manifest source mappings and the directly
referenced preparation/adapter/watcher/probe sources. Reading Package-owned
immutable sources did not modify them or inspect the validation project's
runtime.

Read-command non-successes are retained explicitly: an inherited S27 directory
lookup used the wrong name; two continuation lookups used guessed
HostPayload~/manifest.json and test-codedb-mcp-availability.mjs names and returned
exit 1. The actual names were then taken from existing source references
(Payload~/payload-manifest.json and probe-codedb-mcp-availability.mjs).
Other rg exit 1 results meant no pattern matches. These were read/lookup
errors, not production failures or test attempts; no failed test was rerun.

### Final scoped whitespace check

```powershell
git diff --check -- 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs' 'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs' 'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs' 'com.rice.ai-codedb/Editor/AICodedbActions.cs' 'com.rice.ai-codedb/Editor/AICodedbPaths.cs' 'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1' 'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1' 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs' 'com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1' 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'
```

- exit: 0.
- wall: 0.2083149 seconds.
- output: empty.
- Count: 1. Only the fixed eleven source/test paths were checked.
- An unchanged-source whitespace PASS does not close any new behavior claim.

### Final ordered source identity

Calculated once after stopping source work; no full-repository diff/identity:

```powershell
$s28FinalPaths = @('com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs','com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs','com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs','com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs','com.rice.ai-codedb/Editor/AICodedbActions.cs','com.rice.ai-codedb/Editor/AICodedbPaths.cs','com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1','com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1','com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs','com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $s28FinalRows = foreach ($s28FinalPath in $s28FinalPaths) { $s28FinalPath + ' ' + (Get-FileHash -LiteralPath $s28FinalPath -Algorithm SHA256).Hash.ToLowerInvariant() }; $s28FinalHasher = [Security.Cryptography.SHA256]::Create(); try { $s28FinalIdentity = ([BitConverter]::ToString($s28FinalHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($s28FinalRows -join [char]10))))).Replace('-','').ToLowerInvariant() } finally { $s28FinalHasher.Dispose() }; $s28FinalHead = (& git rev-parse HEAD); Write-Output ('HEAD=' + $s28FinalHead); Write-Output ('BRANCH=' + (& git branch --show-current)); Write-Output ('FINAL_ORDERED_11_PATH_SHA256=' + $s28FinalIdentity); $s28FinalRows | Write-Output; git status --short -- $s28FinalPaths; if ($s28FinalHead -cne 'aaea58a0262c99a7901b39a8309e94b126111b00' -or $s28FinalIdentity -cne 'e4167a4693acedae9bd0c511941fdfc73f24be2ac32040a8c35522cc25c0a7bb') { throw 'Final stopped snapshot drifted from untouched source baseline.' }
```

- exit: 0.
- wall: 0.3501 seconds.
- output: the stopped-snapshot block above.
- Final HEAD and all eleven bytes matched the preflight. No drift repair.

## Five behavior claims

| Claim | Stopped result |
| --- | --- |
| 1. Attributable unknown history and warnings persist | Original evidence/source retained unchanged; proposed multi-history presentation not implemented or newly accepted. |
| 2. Independent authenticated cache-only status | Existing source was read; new independent history/status behavior not implemented or tested. |
| 3. Rechecked new mutation admission | BLOCKED at source proof closure; no passing permit, admission, or mutation was produced. Missing process binding was not guessed. |
| 4. Current-project proof, unrelated evidence and changed generation | Not closed. A global shell veto or generation special case was deliberately not introduced; complete relevant process binding is unresolved. |
| 5. Accepted S27 and existing result provenance | Byte-identical baseline retained; no new marker/receipt/provenance interpretation. New admission evidence is not implemented. |

No Affected L1 test names were added; AICodedbManagerUiTests.cs is unchanged.
No marker-driven test branches or fixed-drive fixtures were introduced.

## Budget and evidence ledger

- Bounded preflight: 1, inherited; no repeat.
- Bounded source-closure diagnostic: 1, exit 0, diagnostic only.
- Planned complete C# nearest-test/source acceptance batch: NOT RUN following
  the structural stop. The closure diagnostic is not presented as that batch.
- NextChangeAdmissionOnly focused L0: 0; selector/scenarios NOT IMPLEMENTED.
- PathProvenanceOnly focused L0: 0; NOT RUN following the structural stop.
- ManagerActionWriterOnly: 0 new executions. REUSED accepted S26 baseline
  evidence only, with unchanged writer SHA-256
  f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4.
  See S26 verifications/VERIFICATION-01.md; reuse does not establish S28
  admission or descendant completeness.
- S27: unchanged accepted source/interpretation only; no reconciliation rerun.
- Scoped diff-check: 1, exit 0.
- Final eleven-path identity: 1, exit 0; exact match.
- Test initial attempts: 0; semantic corrected attempts/retries: 0.
- Mechanical test corrections: 0. Named read-lookup corrections are disclosed
  above, separately from local scenario attempts.
- Redesign repairs: 0/2; structural proof cause: 1 identified;
  diagnostic-only checkpoints: 1/3. Stop occurred at the immediate binding
  trigger, not because time or semantic-attempt allowances were exhausted.

## NOT RUN / DEFERRED / preservation

NOT RUN: Unity/Unity MCP/BatchMode, CUA, real process inventory or command lines,
protected runtime reads, real Remove/Install/reconciliation, process stop,
MCP/query probes, other L0/L1, full regression, Provider installation,
Package export/switch, commit/tag/push/publication.

C# compile and focused EditMode are DEFERRED. S25 real-project Ready, retained
warning, process visibility, fresh Remove/Install admission and release gates
remain separate and unproven by this source diagnosis.

Inherited dirty/untracked files, immutable generation/artifact bytes, original
Install records, existing S27 marker, validation project configuration/runtime,
human-owned Editor session, Provider and external processes were not modified.

## Required same-task route decision

Planner/User must freeze a sufficient legacy-Install process-proof strategy
before asking this snapshot to admit a new effect. Do not merely grant another
unchanged test attempt or reinterpret the old outcome.

1. Decide whether an independently authenticated, bounded *current-project
   capability inventory* may supply the missing legacy descendant proof.
   If so, define its complete mutation-capable process set, source/instance
   bindings, visibility/UNKNOWN rules, point-of-effect revalidation and current
   lock/control relationship. Healthy persistent query ownership must remain
   separate. Any real evidence collection belongs to separately authorized
   S25; none is authorized or attempted here.
2. For future actions, freeze durable non-terminal child/descendant admission
   evidence without changing old command receipts. Review the exact writer
   claim/start window, both materializer native-process helpers,
   Invoke-InstancePowerShellScript/candidate call sites, and Supervisor
   runMaterializer/child capture before deciding whether the existing
   eleven-path envelope suffices or named additional ownership/correlation
   paths are needed. This report does not grant that expansion.
3. A new evidence producer cannot retroactively prove an unrecorded historical
   child's exit. If a complete current proof cannot be established, retain
   UNKNOWN and refuse new mutation. Independently displaying current status
   with the warning could proceed only under an explicitly revised same-task
   disposition; it must not be advertised as full S28 admission completion.

No new task card, generation transition, second mutation/lock authority,
historical receipt synthesis, automatic replay or process termination is
proposed as a workaround.

## Completion routing

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: ROUTE_REASSESSMENT_REQUIRED
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner/User review of the stopped exact snapshot and legacy process-proof contract; freeze a sufficient same-task route before implementation continues
Human decision or authorization required: process-proof contract or any named allowlist/authority expansion; later Verifier routing, Unity/real-project evidence, commit/export/switch/push/publication remain separate

Delivered in the current Coder conversation only. This continuation did not
authorize messaging another conversation, and no cross-thread notification
or Verifier dispatch was sent.

## Authorized Phase A continuation - 2026-10-01

### Current disposition and authorization

- Overall S28: PARTIAL.
- Phase A: PHASE_A_SOURCE_EVIDENCE_PASS.
- Phase B passing legacy mutation proof: DEFERRED / NOT AUTHORIZED.
- Executed the updated Authorized Same-Task Ordering and Phase A Execution
  Envelope, not the superseded all-at-once implementation order.
- The earlier stopped diagnostic above remains intact. Its process-binding gap
  is now the expected retained mutation refusal, not a blocker to this
  independent history/status implementation.
- No claim of C# execution, fresh real Manager Ready, complete S28, S25 PASS,
  safe new admission, release/export, or publication.

### Session/model/time attribution

- Same v0.3.coder.deep; DURABLE_SESSION / REUSE_ONLY; no new task or agent.
- Actual model and reasoning setting remain unavailable from the execution
  interface; the earlier unverified model-summary attribution is not upgraded
  into verified fact. No model/profile switch was made.
- Phase A entry: 2026-10-01 12:29:32 UTC.
- Phase A stopped source snapshot: 2026-10-01 12:51:40 UTC.
- Source-stage wall window: 22 minutes 08 seconds.
- Original task start remains 2026-10-01 09:50:03 UTC.
- The previous RESULT file last-write was observed before this append as
  2026-10-01 10:17:14 UTC, length 21506 bytes.
- Carry the complete prior start-to-result window conservatively:
  27 minutes 11 seconds; the time allowance was not reset.
- Between that prior result and Phase A entry: 2 hours 12 minutes 18 seconds
  of inter-stage wall time, principally the stopped Planner/User decision
  interval. That stopped interval is not a new source execution budget.
- Working-window subtotal through the new source stop: 49 minutes 19 seconds.
  Documentation through the 12:53:55 UTC clock read makes the conservative
  working-window estimate 51 minutes 34 seconds. Exact active reasoning versus
  command/wait/admin time remains unavailable; these are explicitly wall-window
  estimates, not an invented precise CPU or active-time timer.
- Compactions: at least the existing supplied handoff summary; exact total
  unavailable. Counters/consumed attempts were carried forward.
- Core Phase A gate stdout captured: 2531 characters/ASCII bytes across
  the entry, source batch, provenance, diff-check and final identity commands.
  Exact cumulative output for all inherited/scoped source reads remains
  unavailable; original_token_count is not treated as captured-byte telemetry.

### Actual modified paths

Only these three original allowlist paths changed:

1. com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
2. com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
3. com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs

This RESULT.md is append-only. TASK, ROUTE-REASSESSMENT, contracts, runtime
documents and inherited dirty content were not Coder-edited.

Tests~/test-codedb-package-boundary.ps1 did not need a source change and remains
byte-identical. All seven Phase A read-only paths were individually checked
against the original preflight hashes. AICodedbActions.cs, ProcessRunner,
HostPayloadMaterializer, Paths, both production PowerShell scripts and the
materializer test harness remain unchanged. No new file/selector/permit was
introduced.

### Implementation and authority boundaries

- Header/Overview product projection no longer uses Recovery to overwrite
  current product state with the old command's unconfirmed state.
  ShouldOverrideProductStatus preserves existing running, completed-warning
  and failed-without-fresh-status presentation.
- DrawBodyLayout independently displays a Warning HelpBox for unresolved
  history. The warning includes the original action ID/title/Package context,
  explicitly separates current product state, and says new project changes
  remain blocked until execution safety is proved. Its height is included
  in the body layout.
- Unknown recovery still has no command Result, still retains IsRecovering,
  and still blocks the session and durable second-owner gates. No original
  receipt/index is rewritten, cleared, replayed, or classified as terminal
  merely because product status becomes Ready.
- Journal reads expose display-only HistoricalWarning separately from index
  state. A valid accepted S27 unknown marker retains its original Empty/index
  interpretation but now also retains the explicitly unknown history warning.
  The original marker/admission/claim identity/hash validation remains in use.
  This display property does not grant mutation or alter marker semantics.
- Durable history and the current Package observation boundary are captured
  on Task.Run. Window generation and captured project/Package context reject
  late/foreign restoration. No new filesystem/hash/process work was put in
  OnGUI/open/tab/cache observation callbacks.
- Existing Lifecycle/Bridge product classification and authentication remain
  authoritative. AICodedbManagerStatusBoundary is only a display rejection
  boundary, not a classifier, lock owner, process proof, or mutation permit.
  Its expected runtime path, target generation and runtime-contract hash are
  obtained from the existing Package contract reader on the worker.
- A Ready cache needs the existing classified product result AND a connected
  operational observation bound to that Package/runtime/generation, with a
  non-future observation age within the existing 30-second Ready cache window.
  Supervisor core_ready alone is not enough. Invalid/stale/foreign Ready
  observations fall back to Starting; non-Ready status remains independently
  consumable and is not rewritten to command success.
- The static Ready cache now also binds Package root, retains the original
  observation timestamp, and rejects wrong project/Package, stale and future
  timestamps. Restoring a cached window or a Play display handoff does not
  renew its timestamp. An ordinary persisted Ready hint without a fresh
  in-domain observation starts as Starting until the current cache arrives.
  The existing authorized Play handoff semantics remain display-only.
- Async status workers explicitly retain/check their captured context as
  well as existing window/Play/cancellation generation boundaries.
- Header status refresh still uses the existing lifecycle observation intent
  and cache path, without new action admission or Manager-owned backend
  dispatch. Recovery does not disable that current-status observation path.
- No result-authority, writer launch/receipt, Supervisor scheduling,
  mutation confirmation, Install UNINSTALLED/PENDING precondition, shutdown,
  or process-stop behavior changed. No counter was hidden/reset/fabricated.

### Directly affected Editor tests

Added (source assertions inspected; NUnit execution DEFERRED):

- ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation
  (Ready, NeedsAttention, Uninstalled and MissingPrerequisite cases).
- ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence
  (current valid proof, foreign project/Package/runtime, changed generation/hash,
  old/future timestamp, incomplete observation and non-Ready).
- ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal.
- ManagerStatusOverride_PreservesRunningAndTerminalPresentation.

Extended adjacent existing tests:

- ManagerActionJournal_RestoresOriginalIdAfterFullExitAndPackageReplacement:
  warning retains the original action/Package and Recovery does not override
  product presentation; existing blocked/release behavior stays asserted.
- ManagerActionJournal_HistoricalUnknownMarkerReleasesOnlyBoundPendingStage:
  unknown warning survives valid S27 history, original admission bytes/claim
  text are unchanged, and ordinary tamper/orphan conflict assertions remain.

The source batch also checked the existing
ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission
assertions for wrong-action/unconfirmed rejection and matching final recovery.
These names are not reported as executed/passing NUnit tests.

### Executed commands and evidence

#### Phase A unchanged stopped-baseline admission

Run once because the updated envelope explicitly requires it before edits.
It is not another historical-child audit or a budget reset.

```powershell
$s28PhaseAPaths = @('com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs','com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs','com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs','com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs','com.rice.ai-codedb/Editor/AICodedbActions.cs','com.rice.ai-codedb/Editor/AICodedbPaths.cs','com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1','com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1','com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs','com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $s28PhaseARows = foreach ($s28PhaseAPath in $s28PhaseAPaths) { $s28PhaseAPath + ' ' + (Get-FileHash -LiteralPath $s28PhaseAPath -Algorithm SHA256).Hash.ToLowerInvariant() }; $s28PhaseAHasher = [Security.Cryptography.SHA256]::Create(); try { $s28PhaseAIdentity = ([BitConverter]::ToString($s28PhaseAHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($s28PhaseARows -join [char]10))))).Replace('-','').ToLowerInvariant() } finally { $s28PhaseAHasher.Dispose() }; $s28PhaseAHead = & git rev-parse HEAD; $s28PhaseABranch = & git branch --show-current; Write-Output ('HEAD=' + $s28PhaseAHead); Write-Output ('BRANCH=' + $s28PhaseABranch); Write-Output ('PHASE_A_ENTRY_IDENTITY=' + $s28PhaseAIdentity); if ($s28PhaseAIdentity -cne 'e4167a4693acedae9bd0c511941fdfc73f24be2ac32040a8c35522cc25c0a7bb' -or $s28PhaseAHead -cne 'aaea58a0262c99a7901b39a8309e94b126111b00' -or $s28PhaseABranch -cne 'codex/v0.3.0-legacy-workflow') { throw 'Phase A stopped baseline admission failed.' }
```

- Exit 0; wall 0.3066202 seconds.
- Output:

```text
HEAD=aaea58a0262c99a7901b39a8309e94b126111b00
BRANCH=codex/v0.3.0-legacy-workflow
PHASE_A_ENTRY_IDENTITY=e4167a4693acedae9bd0c511941fdfc73f24be2ac32040a8c35522cc25c0a7bb
```

#### One bounded C# source/nearest-assertion batch

The stdin program reads only the three changed C# files, masks comments and
literals before lexical/member parsing, locates named production members,
checks production rejection/presentation call sites, and checks the nearest
test assertion bodies. It does not compile C#, invoke NUnit, execute production
Manager code, or run a Supervisor Node L0. No marker-driven production branch
was added.

```powershell
@'
const fs = require("fs");
const assert = require("assert/strict");
const root = "com.rice.ai-codedb/";
const names = ["Editor/AICodedbManagerWindow.cs","Editor/AICodedbManagerActionJournal.cs","Tests/Editor/AICodedbManagerUiTests.cs"];
const sources = names.map(name => fs.readFileSync(root+name,"utf8"));
function mask(source) {
  let out="", i=0;
  while (i<source.length) {
    if (source.startsWith("//",i)) { const e=source.indexOf("\n",i); const end=e<0?source.length:e; out+=" ".repeat(end-i); i=end; continue; }
    if (source.startsWith("/*",i)) { const e=source.indexOf("*/",i+2); assert(e>=0,"unterminated block comment"); const end=e+2; out+=source.slice(i,end).replace(/[^\r\n]/g," "); i=end; continue; }
    const c=source[i];
    if (c==='"' || c==="'") {
      const start=i, verb=c==='"'&&i>0&&source[i-1]==="@"; i++;
      let closed=false;
      while(i<source.length) {
        if (!verb && source[i]==="\\") { i+=2; continue; }
        if(source[i]===c) { if(verb&&source[i+1]==='"') { i+=2; continue; } i++; closed=true; break; }
        i++;
      }
      assert(closed,"unterminated literal");
      out+=source.slice(start,i).replace(/[^\r\n]/g," "); continue;
    }
    out+=c; i++;
  }
  return out;
}
const masks=sources.map(mask);
for(let i=0;i<masks.length;i++) {
  const stack=[], pairs={"}":"{",")":"(","]":"["};
  for(const c of masks[i]) {
    if("{([".includes(c))stack.push(c);
    else if("})]".includes(c)) assert.equal(stack.pop(),pairs[c],names[i]+" lexical delimiter mismatch");
  }
  assert.equal(stack.length,0,names[i]+" unclosed lexical delimiter");
}
function member(index,name) {
  const re=new RegExp("^ {8}(?:private|internal|public) [^\\r\\n]*\\b"+name+"\\(","gm");
  const hits=[...masks[index].matchAll(re)];
  assert.equal(hits.length,1,"declaration cardinality: "+name);
  const start=hits[0].index, open=masks[index].indexOf("{",start); assert(open>=0);
  let depth=1, end=open+1;
  while(end<masks[index].length&&depth) { if(masks[index][end]==="{")depth++; if(masks[index][end]==="}")depth--; end++; }
  assert.equal(depth,0,"member closure "+name);
  return sources[index].slice(start,end);
}
function has(body,values,label) { for(const value of values)assert(body.includes(value),label+": missing "+value); }
const projection=member(0,"ShouldOverrideProductStatus");
has(projection,["phase != AICodedbUserActionPhase.Recovery","presentation.IsRunning","AICodedbUserActionPhase.Completed","AICodedbUserActionPhase.Failed"],"independent status projection");
for(const name of ["GetHeaderTitle","GetHeaderDescription","GetOverviewStatusTitle","GetOverviewStatusDescription","GetDisplayedProductState"]) has(member(0,name),["TryGetActionStatusOverride"],name);
has(member(0,"TryGetActionStatusOverride"),["ShouldOverrideProductStatus"],"production projection call");
has(member(0,"DrawBodyLayout"),["GetHistoricalActionWarning()","EditorGUILayout.HelpBox(historicalWarning, MessageType.Warning)","historicalWarningHeight"],"separate visible warning");
has(member(0,"BuildHistoricalActionWarning"),["session.IsRecovering","session.ActionId","session.Context.PackageRoot","unknown command outcome","New project changes remain blocked"],"correlated unknown warning");
has(member(0,"AttachCurrentActionSession"),["session.IsRunning || session.IsRecovering"],"mutation UI refusal");
has(member(0,"TryStart"),["_current.IsRunning || _current.IsRecovering","return false"],"session refusal");
has(member(1,"TryAdmit"),["existing.State != AICodedbManagerActionIndexState.Empty","return false"],"durable refusal");
has(member(0,"RestoreDurableActionAsync"),["await Task.Run","AICodedbManagerActionJournal.Read(context)","AICodedbManagerStatusBoundary.Capture(context)","generation != _windowStatusGeneration","IsSameStatusContext(_executionContext, context)","read.HistoricalWarning"],"worker restoration/boundary");
const legacy=member(1,"ReadLegacyPending");
has(legacy,["marker.HistoricalUnknown","matchedHistorical.Add(actionId)","retainedUnknown.Add(","MatchesHistoricalClaim","AdmissionSha256","ClaimSha256","historicalWarning: historicalWarning"],"S27 retained warning and validation");
for(const name of ["Read","ReadLegacyPending"])assert(!/\b(?:File\.(?:Delete|WriteAll)|FileStream\s*\([^)]*Create)/.test(member(1,name)),name+" must remain read-only");
const cached=member(0,"TryApplyCachedLifecycleStatus");
has(cached,["TryGetCachedLifecycleStatus","revision <= _cachedLifecycleStatusRevision","_statusBoundary.CanDisplay","_readyObservationAtUtc","CreateStarting","cachedSupervisorSnapshot?.ObservedAtUtc"],"cache consumer rejection");
has(member(0,"CanDisplay"),["IsSameStatusContext","hasProductStatus && observation.IsCoreReady","observation.HasOperationalReadinessObservation","CanDisplayReadyEvidence"],"existing authority conjunction");
has(member(0,"CanDisplayReadyEvidence"),["IsSameStatusContext","hasAuthenticatedProductReady","SamePath(_runtimePath, runtimePath)","_generationId, generationId","_contractSha256, contractSha256","observedAt <= now","TimeSpan.FromSeconds(30d)"],"fresh bound Ready");
has(member(0,"CanUseCachedReadyObservation"),["packageRoot, observedPackageRoot","projectRoot, observedProjectRoot","observedAt <= now","ReadySnapshotCacheSeconds"],"cached project/Package/time");
has(member(0,"CacheReadySnapshot"),["_lastKnownReadyAtUtc = observedAt","_lastKnownReadyPackageRoot = context.PackageRoot"],"no timestamp renewal");
assert(!member(0,"RefreshStatus").includes("CacheReadySnapshot("),"restore must not renew Ready");
assert(!member(0,"RestoreReadySnapshotForPlayMode").includes("CacheReadySnapshot("),"Play handoff must not renew Ready");
for(const name of ["RefreshStatusAsync","ApplyCachedLifecycleStatusAsync"])has(member(0,name),["var context = _executionContext","IsSameStatusContext(_executionContext, context)","ShouldApplyStatusRefreshResult"],"late/foreign worker rejection "+name);
for(const name of ["OnGUI","SelectTab","DrawBodyLayout","GetHistoricalActionWarning","TryApplyCachedLifecycleStatus","TryGetCachedReadySnapshot"]) {
  assert(!/\b(?:File|Directory)\.\w+|Process\.|SHA256|GetFileHash|RunPowerShell|ReadObject/.test(member(0,name)),name+" direct prohibited I/O");
}
const newTests=[
"ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation",
"ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence",
"ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal",
"ManagerStatusOverride_PreservesRunningAndTerminalPresentation"];
for(const name of newTests)assert((member(2,name).match(/Assert\.That\(/g)||[]).length>=3,"nearest assertions: "+name);
has(member(2,newTests[0]),["session.Result, Is.Null","session.IsRecovering, Is.True","TryStart(","TryReleaseDurableIndex(","unknown command outcome"],"Ready/non-Ready leaves history and admission unresolved");
has(sources[2],["[TestCase(AICodedbProductState.Ready)]","[TestCase(AICodedbProductState.NeedsAttention)]"],"projection cases");
has(member(2,newTests[1]),["otherProject","foreign","now.AddSeconds(-31d)","now.AddSeconds(1d)","hash, false","runtime + \"-foreign\"","\"other-generation\"","true, null, now), Is.False"],"stale/foreign/incomplete nearest cases");
has(member(2,"ManagerActionJournal_RestoresOriginalIdAfterFullExitAndPackageReplacement"),["BuildHistoricalActionWarning","original.PackageRoot","TryAdmit(second","TryCompleteRecovery"],"durable restore nearest regression");
has(member(2,"ManagerActionJournal_HistoricalUnknownMarkerReleasesOnlyBoundPendingStage"),["history.HistoricalWarning","Is.EqualTo(originalAdmissionBytes)","Is.EqualTo(claim)","Is.EqualTo(AICodedbManagerActionIndexState.Conflict)"],"S27 immutable/provenance nearest regression");
has(member(2,"ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission"),["wrongAction","unconfirmed","TryCompleteRecovery","TryStart"],"unchanged result-authority assertions");
console.log("[PASS] C# lexical/member source checks (3 files); independent history/status, contextual freshness, cache-only callbacks, worker restore, preserved mutation refusal and S27/result authority.");
console.log("[PASS] Nearest source assertions: "+newTests.join(", "));
console.log("[DEFERRED] C# compilation and NUnit/EditMode execution; no Unity or runtime was read or started.");
'@ | node
```

- Exit 0; wall 0.3710015 seconds.
- Initial attempts 1; corrected mechanical/semantic attempts 0.
- Output:

```text
[PASS] C# lexical/member source checks (3 files); independent history/status, contextual freshness, cache-only callbacks, worker restore, preserved mutation refusal and S27/result authority.
[PASS] Nearest source assertions: ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation, ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence, ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal, ManagerStatusOverride_PreservesRunningAndTerminalPresentation
[DEFERRED] C# compilation and NUnit/EditMode execution; no Unity or runtime was read or started.
```

Read/preparation corrections before that sole evidence execution are not hidden:
named-class lookup initially used standalone UserActionStatus,
SupervisorProtocol and StatusService filenames which were absent; the first
two definitions were located in the existing ActivityPanel and SupervisorBridge,
and status work used the actual StatusSnapshot dependency. The context type
was confirmed to be a readonly struct, and two in-progress construction
references were corrected before running the batch. No failed test command
or unchanged source-evidence rerun occurred.

#### Required focused Package path provenance

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1 -PathProvenanceOnly
```

- Exit 0; wall 2.296334 seconds.
- L0 batches 1; corrected attempts/retries 0.
- Output:

```text
[PASS] Package path provenance.
```

Only -PathProvenanceOnly executed; its existing early-return boundary prevents
the full Package/materializer suite. The harness source is unchanged.

#### Final original-eleven-path scoped whitespace check

```powershell
git diff --check -- 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs' 'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs' 'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs' 'com.rice.ai-codedb/Editor/AICodedbActions.cs' 'com.rice.ai-codedb/Editor/AICodedbPaths.cs' 'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1' 'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1' 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs' 'com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1' 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'
```

- Exit 0; wall 0.2467173 seconds; empty output.
- Phase A executions 1. Overall task total 2, including the separately recorded
  unchanged-source check in the original stopped diagnosis; not a repeated
  Phase A check.

#### Final original-eleven-path identity and read-only attribution

```powershell
$s28PhaseAFinalPaths = @('com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs','com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs','com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs','com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs','com.rice.ai-codedb/Editor/AICodedbActions.cs','com.rice.ai-codedb/Editor/AICodedbPaths.cs','com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1','com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1','com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs','com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $s28PhaseAReadonly = @{'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs'='ebc7118a9f3ca7c51f2e2889431e1bdd14d5abbebc027d9c241e24f08f27b6c5';'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs'='a0c15e7d77650264e9d294893f57d4be68173e8653059765d618006348b17464';'com.rice.ai-codedb/Editor/AICodedbActions.cs'='2a25e7798e38c19fda2849619072a0ce94cbaa372be0eb70566281a6ff69b1ec';'com.rice.ai-codedb/Editor/AICodedbPaths.cs'='eb571172bac6afd7dd34ec85f3088d8a0f6a6fb71505a8ff67336efbbf858b28';'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1'='031e0bc5025ecbf91c69783379a580f00fb4d554ff62c02d15514b8b7453fa23';'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1'='f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4';'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'='dcd21d38e12ea9cb1e90067c2c19ea7dfd9b8e647f8803d639c7297b4d4c8bd1'}; $s28PhaseAFinalRows = foreach ($s28PhaseAFinalPath in $s28PhaseAFinalPaths) { $s28PhaseAFileHash = (Get-FileHash -LiteralPath $s28PhaseAFinalPath -Algorithm SHA256).Hash.ToLowerInvariant(); if ($s28PhaseAReadonly.ContainsKey($s28PhaseAFinalPath) -and $s28PhaseAReadonly[$s28PhaseAFinalPath] -cne $s28PhaseAFileHash) { throw ('Read-only source drift: ' + $s28PhaseAFinalPath) }; $s28PhaseAFinalPath + ' ' + $s28PhaseAFileHash }; $s28PhaseAFinalHasher = [Security.Cryptography.SHA256]::Create(); try { $s28PhaseAFinalIdentity = ([BitConverter]::ToString($s28PhaseAFinalHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($s28PhaseAFinalRows -join [char]10))))).Replace('-','').ToLowerInvariant() } finally { $s28PhaseAFinalHasher.Dispose() }; $s28PhaseAFinalHead = & git rev-parse HEAD; $s28PhaseAFinalBranch = & git branch --show-current; Write-Output ('HEAD=' + $s28PhaseAFinalHead); Write-Output ('BRANCH=' + $s28PhaseAFinalBranch); Write-Output ('PHASE_A_FINAL_ORDERED_11_PATH_SHA256=' + $s28PhaseAFinalIdentity); $s28PhaseAFinalRows | Write-Output; git status --short -- $s28PhaseAFinalPaths; if ($s28PhaseAFinalHead -cne 'aaea58a0262c99a7901b39a8309e94b126111b00' -or $s28PhaseAFinalBranch -cne 'codex/v0.3.0-legacy-workflow') { throw 'Final Phase A HEAD/branch drift.' }; Write-Output 'READONLY_SEVEN_HASHES_MATCH=true'
```

- Exit 0; wall 0.406985 seconds.
- Final identity calculated once for this Phase A stopped snapshot.
- Output:

```text
HEAD=aaea58a0262c99a7901b39a8309e94b126111b00
BRANCH=codex/v0.3.0-legacy-workflow
PHASE_A_FINAL_ORDERED_11_PATH_SHA256=9549a12925935127059132ca549f9e5ed0599c1191004a0ccd36ea2feb0fc899
com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs 750f7f8be3f99bee89db72d6e98cd36c64beb0d6783dc80ee3abc568d591a4b1
com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs e03ad95304e32c82b861ebafb6391502ca65f217105478114c75c3c55ef026cf
com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs ebc7118a9f3ca7c51f2e2889431e1bdd14d5abbebc027d9c241e24f08f27b6c5
com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs a0c15e7d77650264e9d294893f57d4be68173e8653059765d618006348b17464
com.rice.ai-codedb/Editor/AICodedbActions.cs 2a25e7798e38c19fda2849619072a0ce94cbaa372be0eb70566281a6ff69b1ec
com.rice.ai-codedb/Editor/AICodedbPaths.cs eb571172bac6afd7dd34ec85f3088d8a0f6a6fb71505a8ff67336efbbf858b28
com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 031e0bc5025ecbf91c69783379a580f00fb4d554ff62c02d15514b8b7453fa23
com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1 f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4
com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs 20bb785e34db0392cd28274a4137989cc76f2cad9e98db87a9edda994ba8c5f5
com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 0a4ad7f786a5ad929b3db907e0af94f779a2ab2b544b819af0958be209bea059
com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 dcd21d38e12ea9cb1e90067c2c19ea7dfd9b8e647f8803d639c7297b4d4c8bd1
 M com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
 M com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
 M com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
READONLY_SEVEN_HASHES_MATCH=true
```

Final SHA-256:
9549a12925935127059132ca549f9e5ed0599c1191004a0ccd36ea2feb0fc899.

Same HEAD/branch and same ordered eleven-path UTF-8/LF/file-SHA256 algorithm;
not a replacement four-path/three-path identity. The only dirty source paths
in this scoped snapshot are the three implementation/test paths listed above.

### Five behavior claims at this partial boundary

| Claim | Phase A source outcome |
| --- | --- |
| 1. Unknown history remains attributable | Implemented separate warning and retained correlation; source/nearest assertions passed. Durable receipts and recovery gates are not cleared or synthesized. Actual close/reload/full-exit/Package runtime observation is DEFERRED. |
| 2. Independent current status/cache-only observation | Implemented separate projection and contextual/freshness rejection. Source/nearest assertions passed for Ready/non-Ready, old/future/foreign/incomplete evidence and worker/cache call sites. No real Manager Ready claim. |
| 3. Safe fresh mutation admission | PARTIAL: existing refusal with unresolved execution proof is retained and asserted. No passing legacy permit or backend proof was implemented. |
| 4. Current-project execution proof scope | DEFERRED: no new global process veto or generation/action exception was added; the previously diagnosed proof-completeness gap remains. |
| 5. Accepted S27 and command-result provenance | Existing S27 interpretation is retained with a separate unknown warning; nearest tamper/original-byte/result-authority assertions remain covered at source level. Writer/direct/Supervisor producer bytes unchanged. |

### Cumulative budget, reused evidence and remaining gates

- Original preflight 1; old source-closure diagnostic 1; Phase A required
  stopped-baseline admission 1.
- Phase A complete source/nearest-assertion batch 1/1; retries/corrected
  semantic attempts 0; no unchanged rerun.
- Phase A PathProvenanceOnly focused L0 1/1; retries 0.
- ManagerActionWriterOnly: 0 new executions, REUSED accepted S26 evidence with
  unchanged writer hash
  f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4
  and unchanged ProcessRunner attribution from the final identity.
- PowerShell source changes/parse attempts: 0; production/harness scripts
  remained frozen. The existing Package script was executed only for the
  authorized path-provenance selector.
- NextChangeAdmissionOnly: DEFERRED for Phase B; no nominal selector or permit.
- C# compilation/Editor test execution/EditMode: DEFERRED.
- Redesign repairs 0/2; inherited structural proof causes 1; inherited
  diagnostic-only checkpoints 1/3. This phase produced actual implementation,
  not another diagnosis of the same missing legacy binding.
- Source work used only the authorized three of four write-subset paths.
  AICodedbActions.cs and all other Phase A read-only files are unchanged.
- NOT RUN: Unity/Unity MCP/BatchMode, CUA, real runtime/protected document reads,
  real process inspection or stopping, real Remove/Install/reconciliation,
  live MCP/query, other L0/L1/full regression, Provider installation, Package
  export/switch, commit/tag/push/publish.
- No Verifier/sub-agent dispatch and no cross-thread message were sent.

Remaining risks are evidence-class limits, not assertions of new defects:
C# semantics and IMGUI layout, actual observation refresh cadence/30-second
freshness behavior, main-thread counters and full lifecycle/history reattachment
need the later separately authorized source-attributable Unity/S25 gate.
Phase B must still freeze a sufficient legacy execution quiescence/recovery
contract and any required ownership/correlation expansion before a passing
mutation branch may be implemented.

### Phase A completion routing

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: PARTIAL / PHASE_A_SOURCE_EVIDENCE_PASS
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner/User review the stable Phase A snapshot and decide the remaining same-task Phase B proof contract and later role/evidence routing
Human decision or authorization required: Phase B passing legacy proof/any named expansion, Verifier routing, Unity/S25/real-project evidence, commit/export/switch/push/publication

Delivered in this Coder conversation only. No cross-thread sending authorization
was inferred from the continuation.

### Final closure timing check

- The appended Phase A result was verified present: 52272 bytes before this
  timing-only append, last-write 2026-10-01 12:57:31 UTC.
- Last clock observation: 2026-10-01 12:59:25 UTC. Phase A wall window to that
  observation is 29 minutes 53 seconds; adding the retained 27 minutes 11
  seconds gives a conservative working-window estimate of 57 minutes 04
  seconds, below DEEP_60M. Exact active/paused accounting remains unavailable;
  the already reported stopped inter-stage interval is excluded, not reset.
- No source, test, identity or diff-check was rerun for this bookkeeping.

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: PARTIAL / PHASE_A_SOURCE_EVIDENCE_PASS
Next notification: UnityCodeDB v0.3 Planner
Next action: review the stable Phase A source snapshot; decide the same-task Phase B proof contract
Human decision or authorization required: Phase B proof/expansion, Verifier and real-project/Unity gates, commit/export/switch/push/publication

## Phase A P1-01 FIX — 2026-10-02

### Stopped result and precise delta

- Overall S28 remains **PARTIAL**. This authorized correction has
  **PHASE_A_P1_01_SOURCE_EVIDENCE_PASS**, pending Planner disposition and a new
  P1-01-only GUARDED review. It is not C# execution, real Ready or S25 PASS.
- Admitted the stopped `9549a129...fc899` snapshot, not the early
  `e4167a...` baseline. Branch/HEAD matched; a single app-thread inventory
  showed this Coder active, Planner idle and Verifier notLoaded, with no
  competing source owner indicated. No process/runtime inventory was performed.
- Actual FIX edits: `Editor/AICodedbManagerWindow.cs` and
  `Tests/Editor/AICodedbManagerUiTests.cs` only. This RESULT is append-only.
  All nine other original scoped source/test files, including
  ManagerActionJournal and AICodedbActions, match the admitted file bytes.
- ManagerWindow: removed the separate 120-second Ready cache authority.
  `AICodedbManagerStatusBoundary.IsReadyObservationFresh` now owns the single
  30-second rule (non-future and age <= 30s). Display admission, cache
  consumption/restoration and displayed-Ready expiry delegate to that rule.
  `ShouldExpireDisplayedReady` is a pure state/time decision; its Starting
  application remains before the unchanged-lifecycle-revision return.
- Retained original observation timestamps, project/Package/runtime/generation/
  contract rejection, async lifetime/context checks, cache-only callbacks and
  worker I/O ownership. No scheduling, history/journal/receipt/S27 interpretation,
  mutation refusal, result authority, identity/version or generation changes.
- Added nearest Editor tests:
  `ManagerReadyFreshness_SharedAcrossDisplayCacheAndExpiry` and
  `ManagerReadyExpiry_PrecedesUnchangedLifecycleRevisionGate`.
  Extended `ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal`
  without weakening its existing 31-second rejection. The existing
  `ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence`
  remained unchanged and was source-checked. All four test executions are
  **NOT RUN / DEFERRED**.

### Executed evidence

| Command / boundary | Exit | Tool wall seconds | Result |
| --- | --- | --- | --- |
| One bounded branch/HEAD + original-order eleven-file admission | 0 | 0.3123199 | Exact stopped identity matched |
| One changed-source/time-bound Node stdin assertion batch | 0 | 0.4142031 | Actual shared return expression derived and evaluated command-side |
| `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1 -PathProvenanceOnly` | 0 | 5.414003 | `[PASS] Package path provenance.` |
| One final original-eleven-file `git diff --check` | 0 | 0.2905622 | Empty output |
| One final original-eleven-file identity/read-only attribution | 0 | 0.4295985 | HEAD/branch unchanged; nine read-only file hashes matched |

Source batch output (not C# compile/NUnit, production Manager or Supervisor Node L0):

```text
[PASS] Derived production shared rule: observedAt <= now && now - observedAt <= TimeSpan.FromSeconds(ReadyObservationFreshnessSeconds); seconds=30
[PASS] Display/cache/expiry: fresh and 30s accept; 30.001s/31s/120s/future reject; non-Ready unchanged.
[PASS] Direct context/authentication, original timestamp/no renewal, unchanged-revision expiry, async context and cache-only closure.
[PASS] Nearest Editor source assertions: ManagerReadyFreshness_SharedAcrossDisplayCacheAndExpiry; ManagerReadyExpiry_PrecedesUnchangedLifecycleRevisionGate; ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal; ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence.
[DEFERRED] C# semantic compile/NUnit/EditMode; command-side adaptation of pure source expressions, not production C# or Unity execution.
```

The batch lexically locates the named changed members, adapts their actual pure
boolean return expressions into bounded command-side checks and derives the
shared lifetime from the single production constant. It evaluates fresh/30s,
30.001s/31s/120s, future time, directly affected context/authentication, cache
restoration/no renewal and expiry-before-same-revision wiring. It does not
repeat the original full Phase A source/history/authority audit. DateTimeOffset,
Editor/NUnit and IMGUI runtime semantics are not claimed as executed evidence.

<details>
<summary>Exact executed commands (source stdin body and scoped identity runners)</summary>

Admission, once:

```powershell
$ErrorActionPreference = 'Stop'; $s28FixPaths = @('com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs','com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs','com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs','com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs','com.rice.ai-codedb/Editor/AICodedbActions.cs','com.rice.ai-codedb/Editor/AICodedbPaths.cs','com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1','com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1','com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs','com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $s28FixHead = & git rev-parse HEAD; if ($LASTEXITCODE -ne 0) { throw 'HEAD read failed' }; $s28FixBranch = & git branch --show-current; if ($LASTEXITCODE -ne 0) { throw 'Branch read failed' }; $s28FixRows = foreach ($s28FixPath in $s28FixPaths) { $s28FixPath + ' ' + (Get-FileHash -LiteralPath $s28FixPath -Algorithm SHA256).Hash.ToLowerInvariant() }; $s28FixHasher = [Security.Cryptography.SHA256]::Create(); try { $s28FixIdentity = ([BitConverter]::ToString($s28FixHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($s28FixRows -join [char]10))))).Replace('-','').ToLowerInvariant() } finally { $s28FixHasher.Dispose() }; Write-Output ('HEAD=' + $s28FixHead); Write-Output ('BRANCH=' + $s28FixBranch); Write-Output ('FIX_INPUT_ORDERED_11_PATH_SHA256=' + $s28FixIdentity); $s28FixRows | Write-Output; git status --short -- $s28FixPaths; if ($LASTEXITCODE -ne 0) { throw 'Scoped status failed' }; if ($s28FixHead -cne 'aaea58a0262c99a7901b39a8309e94b126111b00' -or $s28FixBranch -cne 'codex/v0.3.0-legacy-workflow' -or $s28FixIdentity -cne '9549a12925935127059132ca549f9e5ed0599c1191004a0ccd36ea2feb0fc899') { throw 'BLOCKED: stopped-input identity drift; no repair admitted' }
```

Changed-source/time-bound batch, once:

```powershell
@'
const fs = require("fs");
const assert = require("assert/strict");
const paths = ["com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs", "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs"];
const sources = paths.map(path => fs.readFileSync(path, "utf8"));
function mask(source) {
  let out = "", i = 0;
  while (i < source.length) {
    if (source.startsWith("//", i)) { const e = source.indexOf("\n", i); const end = e < 0 ? source.length : e; out += source.slice(i, end).replace(/[^\r\n]/g, " "); i = end; continue; }
    if (source.startsWith("/*", i)) { const e = source.indexOf("*/", i + 2); assert(e >= 0, "unterminated comment"); const end = e + 2; out += source.slice(i, end).replace(/[^\r\n]/g, " "); i = end; continue; }
    const c = source[i];
    if (c === '"' || c === "'") {
      const start = i, verbatim = c === '"' && i > 0 && source[i - 1] === "@"; i++;
      let closed = false;
      while (i < source.length) {
        if (!verbatim && source[i] === "\\") { i += 2; continue; }
        if (source[i] === c) { if (verbatim && source[i + 1] === '"') { i += 2; continue; } i++; closed = true; break; }
        i++;
      }
      assert(closed, "unterminated literal"); out += source.slice(start, i).replace(/[^\r\n]/g, " "); continue;
    }
    out += c; i++;
  }
  return out;
}
const masked = sources.map(mask);
function member(file, name) {
  const re = new RegExp("^\\s*(?:public|private|internal|protected)\\s+(?:(?:static|async|override|virtual)\\s+)*[\\w<>?,.\\[\\]]+\\s+" + name + "\\s*\\([^{};]*\\)\\s*\\{", "gm");
  const matches = [...masked[file].matchAll(re)];
  assert.equal(matches.length, 1, "member cardinality: " + name);
  const start = matches[0].index, open = masked[file].indexOf("{", start); let depth = 1, end = open + 1;
  while (end < masked[file].length && depth > 0) { if (masked[file][end] === "{") depth++; if (masked[file][end] === "}") depth--; end++; }
  assert.equal(depth, 0, "member scope: " + name);
  return { start, raw: sources[file].slice(start, end), body: sources[file].slice(open + 1, end - 1) };
}
function expression(name) {
  const m = member(0, name), returns = [...m.body.matchAll(/\breturn\s+([^;]+);/g)];
  assert.equal(returns.length, 1, "single pure return: " + name); return returns[0][1].trim();
}
function has(text, fragments, label) { for (const fragment of fragments) assert(text.includes(fragment), label + ": " + fragment); }
const constants = [...masked[0].matchAll(/\bprivate\s+const\s+double\s+ReadyObservationFreshnessSeconds\s*=\s*([0-9.]+)d\s*;/g)];
assert.equal(constants.length, 1, "one freshness scalar authority");
const seconds = Number(constants[0][1]); assert.equal(seconds, 30, "accepted boundary");
assert(!sources[0].includes("ReadySnapshotCacheSeconds"), "old cache authority removed");
const freshExpression = expression("IsReadyObservationFresh");
has(freshExpression, ["observedAt <= now", "now - observedAt <= TimeSpan.FromSeconds(ReadyObservationFreshnessSeconds)"], "actual shared rule");
assert.equal((sources[0].match(/TimeSpan\.FromSeconds\(ReadyObservationFreshnessSeconds\)/g) || []).length, 1, "one time comparison authority");
assert(!/TimeSpan\.FromSeconds\((?:30|120)d\)/.test(sources[0]), "no independent Ready time literal");
function translate(text) {
  return text
    .replace(/AICodedbManagerWindow\.IsSameStatusContext/g, "sameContext")
    .replace(/AICodedbManagerStatusBoundary\.IsReadyObservationFresh/g, "fresh")
    .replace(/\bIsReadyObservationFresh/g, "fresh")
    .replace(/\bSamePath/g, "samePath")
    .replace(/string\.IsNullOrWhiteSpace/g, "blank")
    .replace(/string\.IsNullOrEmpty/g, "empty")
    .replace(/string\.Equals\(([\w.]+),\s*([\w.]+),\s*StringComparison\.OrdinalIgnoreCase\)/g, "equalIgnoreCase($1, $2)")
    .replace(/string\.Equals\(([\w.]+),\s*([\w.]+),\s*StringComparison\.Ordinal\)/g, "equalOrdinal($1, $2)")
    .replace(/AICodedbProductState\.Ready/g, "readyState")
    .replace(/TimeSpan\.FromSeconds\(ReadyObservationFreshnessSeconds\)/g, "(" + seconds + " * 1000)");
}
const functions = {
  blank: value => value == null || /^\s*$/.test(value),
  empty: value => value == null || value === "",
  equalIgnoreCase: (a, b) => a == null || b == null ? a === b : a.toLowerCase() === b.toLowerCase(),
  equalOrdinal: (a, b) => a === b,
  readyState: "Ready"
};
function derive(text, argumentsList) {
  const translated = translate(text);
  assert(/^[\w\s.(),<>=!&+*\/-]+$/.test(translated), "bounded boolean expression syntax");
  const allowed = new Set([...argumentsList, ...Object.keys(functions), "ProjectRoot", "PackageRoot"]);
  for (const identifier of translated.match(/\b[A-Za-z_]\w*\b/g) || []) assert(allowed.has(identifier), "unexpected expression identifier: " + identifier);
  return new Function(...Object.keys(functions), ...argumentsList, "return (" + translated + ");").bind(null, ...Object.values(functions));
}
functions.fresh = derive(freshExpression, ["observedAt", "now"]);
functions.sameContext = derive(expression("IsSameStatusContext"), ["expected", "observed"]);
const samePathRaw = expression("SamePath");
has(samePathRaw, ["!string.IsNullOrWhiteSpace(expected)", "!string.IsNullOrWhiteSpace(observed)", "StringComparison.OrdinalIgnoreCase"], "unchanged runtime context");
const normalizeExpected = "expected.Replace('\\\\', '/').TrimEnd('/')";
const normalizeObserved = "observed.Replace('\\\\', '/').TrimEnd('/')";
has(samePathRaw, [normalizeExpected, normalizeObserved], "runtime path normalization");
functions.normalizePath = value => value.replace(/\\/g, "/").replace(/\/+$/, "");
const pathExpression = samePathRaw.replace(normalizeExpected, "normalizedExpected").replace(normalizeObserved, "normalizedObserved");
const derivedPath = derive(pathExpression, ["expected", "observed", "normalizedExpected", "normalizedObserved"]);
functions.samePath = (expected, observed) => derivedPath(expected, observed, expected == null ? expected : functions.normalizePath(expected), observed == null ? observed : functions.normalizePath(observed));
const display = derive(expression("CanDisplayReadyEvidence"), ["_context", "context", "_runtimePath", "runtimePath", "_generationId", "generationId", "_contractSha256", "contractSha256", "hasAuthenticatedProductReady", "observedAt", "now"]);
const cache = derive(expression("CanUseCachedReadyObservation"), ["projectRoot", "packageRoot", "observedProjectRoot", "observedPackageRoot", "observedAt", "now"]);
const expire = derive(expression("ShouldExpireDisplayedReady"), ["state", "observedAt", "now"]);
for (const name of ["CanDisplayReadyEvidence", "CanUseCachedReadyObservation", "ShouldExpireDisplayedReady"]) {
  const text = expression(name);
  assert.equal((text.match(/IsReadyObservationFresh\(/g) || []).length, 1, "shared consumer call: " + name);
  assert(!/TimeSpan|FromSeconds|observedAt\s*<=|now\s*-\s*observedAt/.test(text), "no independent consumer time rule: " + name);
}
const context = { ProjectRoot: "fixture/project", PackageRoot: "fixture/package" };
const runtime = "fixture/runtime", generation = "fixture-generation", hash = "a".repeat(64), now = 1000000;
function displayAt(observedAt, overrides = {}) {
  return display(context, overrides.context || context, runtime, overrides.runtime || runtime, generation, overrides.generation || generation, hash, overrides.hash || hash, overrides.authenticated !== undefined ? overrides.authenticated : true, observedAt, now);
}
const cases = [[0, true], [30, true], [30.001, false], [31, false], [120, false], [-1, false]];
for (const [age, expected] of cases) {
  const observedAt = now - age * 1000;
  assert.equal(functions.fresh(observedAt, now), expected, "shared rule age " + age);
  assert.equal(displayAt(observedAt), expected, "display age " + age);
  assert.equal(cache(context.ProjectRoot, context.PackageRoot, context.ProjectRoot, context.PackageRoot, observedAt, now), expected, "cache age " + age);
  assert.equal(expire("Ready", observedAt, now), !expected, "expiry age " + age);
  assert.equal(expire("NeedsAttention", observedAt, now), false, "non-Ready unchanged age " + age);
}
for (const changed of [{ context: { ...context, ProjectRoot: "foreign/project" } }, { context: { ...context, PackageRoot: "replacement/package" } }, { runtime: "foreign/runtime" }, { generation: "foreign-generation" }, { hash: "b".repeat(64) }, { authenticated: false }])
  assert.equal(displayAt(now, changed), false, "context/authentication rejection");
assert.equal(cache(context.ProjectRoot, context.PackageRoot, "foreign/project", context.PackageRoot, now, now), false);
assert.equal(cache(context.ProjectRoot, context.PackageRoot, context.ProjectRoot, "replacement/package", now, now), false);
assert.equal(cache("", context.PackageRoot, "", context.PackageRoot, now, now), false);
const consume = member(0, "TryApplyCachedLifecycleStatus").raw;
const expiryIndex = consume.indexOf("ShouldExpireDisplayedReady("), revisionIndex = consume.indexOf("revision <= _cachedLifecycleStatusRevision");
assert(expiryIndex >= 0 && revisionIndex > expiryIndex, "expiry before unchanged revision gate");
has(consume.slice(expiryIndex, revisionIndex), ["_statusSnapshot.ProductStatus.State, _readyObservationAtUtc, DateTimeOffset.UtcNow", "ApplyStatusSnapshot(AICodedbStatusSnapshot.CreateStarting("], "actual expiry decision wiring");
for (const [age, expected] of cases) {
  let state = "Ready"; const observedAt = now - age * 1000;
  if (expire(state, observedAt, now)) state = "Starting";
  const revision = 7, cachedRevision = 7;
  assert(revision <= cachedRevision, "same revision fixture");
  assert.equal(state, expected ? "Ready" : "Starting", "derived same-revision expiry age " + age);
}
has(member(0, "TryGetCachedReadySnapshot").raw, ["CanUseCachedReadyObservation(", "_lastKnownReadyAtUtc, DateTime.UtcNow"], "restoration delegates to cache rule");
has(member(0, "CacheReadySnapshot").raw, ["_lastKnownReadyAtUtc = observedAt;"], "original observation retained");
for (const name of ["RefreshStatus", "RestoreReadySnapshotForPlayMode", "TryGetCachedReadySnapshot"]) {
  const text = member(0, name).raw;
  assert(!text.includes("CacheReadySnapshot("), "no renewal during restoration: " + name);
  assert(!/_lastKnownReadyAtUtc\s*=/.test(text), "no observation publication during restoration: " + name);
  assert(!/_readyObservationAtUtc\s*=\s*(?:DateTimeOffset|DateTime)\.UtcNow/.test(text), "no clock renewal: " + name);
}
has(member(0, "RefreshStatus").raw, ["DateTime.SpecifyKind(_lastKnownReadyAtUtc, DateTimeKind.Utc)"], "restored original timestamp");
has(consume, ["cachedSupervisorSnapshot?.ObservedAtUtc"], "lifecycle original timestamp");
for (const name of ["RefreshStatusAsync", "ApplyCachedLifecycleStatusAsync"])
  has(member(0, name).raw, ["var context = _executionContext", "IsSameStatusContext(_executionContext, context)", "ShouldApplyStatusRefreshResult("], "preserved async context: " + name);
for (const name of ["IsReadyObservationFresh", "ShouldExpireDisplayedReady", "CanUseCachedReadyObservation", "TryApplyCachedLifecycleStatus", "TryGetCachedReadySnapshot"])
  assert(!/\b(?:File|Directory)\.\w+|Process\.|SHA256|RunPowerShell|ReadObject/.test(member(0, name).raw), "cache-only changed closure: " + name);
const timeTest = member(1, "ManagerReadyFreshness_SharedAcrossDisplayCacheAndExpiry");
const attributes = sources[1].slice(sources[1].lastIndexOf("[TestCase(0d, true)]", timeTest.start), timeTest.start);
const testCases = [...attributes.matchAll(/\[TestCase\((-?[0-9.]+)d,\s*(true|false)\)\]/g)].map(match => [Number(match[1]), match[2] === "true"]);
assert.deepEqual(testCases, cases, "Editor boundary matrix retained");
has(timeTest.raw, ["IsReadyObservationFresh(observedAt, now)", "boundary.CanDisplayReadyEvidence(", "CanUseCachedReadyObservation(", "ShouldExpireDisplayedReady(AICodedbProductState.Ready", "Is.EqualTo(!expectedFresh)", "AICodedbProductState.NeedsAttention"], "four directly coupled Editor decisions");
const nearestContextTest = member(1, "ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence").raw;
has(nearestContextTest, ["foreign", "otherProject", "now.AddSeconds(-31d)", "now.AddSeconds(1d)", "hash, false", 'runtime + "-foreign"', '"other-generation"'], "retained nearest context rejection assertions");
const noRenewalTest = member(1, "ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal").raw;
has(noRenewalTest, ["now.AddSeconds(-31d), now), Is.False", "observedAt, observedAt.AddSeconds(30d)), Is.True", "observedAt, observedAt.AddSeconds(31d)), Is.False"], "31-second assertion and no renewal retained");
has(member(1, "ManagerReadyExpiry_PrecedesUnchangedLifecycleRevisionGate").raw, ["revision <= _cachedLifecycleStatusRevision", "Is.GreaterThan(expiry)", "ApplyStatusSnapshot(AICodedbStatusSnapshot.CreateStarting("], "nearest same-revision wiring test");
console.log("[PASS] Derived production shared rule: " + freshExpression.replace(/\s+/g, " ") + "; seconds=" + seconds);
console.log("[PASS] Display/cache/expiry: fresh and 30s accept; 30.001s/31s/120s/future reject; non-Ready unchanged.");
console.log("[PASS] Direct context/authentication, original timestamp/no renewal, unchanged-revision expiry, async context and cache-only closure.");
console.log("[PASS] Nearest Editor source assertions: ManagerReadyFreshness_SharedAcrossDisplayCacheAndExpiry; ManagerReadyExpiry_PrecedesUnchangedLifecycleRevisionGate; ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal; ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence.");
console.log("[DEFERRED] C# semantic compile/NUnit/EditMode; command-side adaptation of pure source expressions, not production C# or Unity execution.");
'@ | node
```

Path provenance, once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1 -PathProvenanceOnly
```

Final fixed-eleven-file diff-check, once:

```powershell
git diff --check -- 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs' 'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs' 'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs' 'com.rice.ai-codedb/Editor/AICodedbActions.cs' 'com.rice.ai-codedb/Editor/AICodedbPaths.cs' 'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1' 'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1' 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs' 'com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1' 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'
```

Final identity/read-only attribution, once:

```powershell
$ErrorActionPreference = 'Stop'; $s28FixPaths = @('com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs','com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs','com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs','com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs','com.rice.ai-codedb/Editor/AICodedbActions.cs','com.rice.ai-codedb/Editor/AICodedbPaths.cs','com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1','com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1','com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs','com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1','com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'); $s28FixReadonly = @{'com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs'='e03ad95304e32c82b861ebafb6391502ca65f217105478114c75c3c55ef026cf';'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs'='ebc7118a9f3ca7c51f2e2889431e1bdd14d5abbebc027d9c241e24f08f27b6c5';'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs'='a0c15e7d77650264e9d294893f57d4be68173e8653059765d618006348b17464';'com.rice.ai-codedb/Editor/AICodedbActions.cs'='2a25e7798e38c19fda2849619072a0ce94cbaa372be0eb70566281a6ff69b1ec';'com.rice.ai-codedb/Editor/AICodedbPaths.cs'='eb571172bac6afd7dd34ec85f3088d8a0f6a6fb71505a8ff67336efbbf858b28';'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1'='031e0bc5025ecbf91c69783379a580f00fb4d554ff62c02d15514b8b7453fa23';'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1'='f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4';'com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1'='0a4ad7f786a5ad929b3db907e0af94f779a2ab2b544b819af0958be209bea059';'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1'='dcd21d38e12ea9cb1e90067c2c19ea7dfd9b8e647f8803d639c7297b4d4c8bd1'}; $s28FixHead = & git rev-parse HEAD; if ($LASTEXITCODE -ne 0) { throw 'HEAD read failed' }; $s28FixBranch = & git branch --show-current; if ($LASTEXITCODE -ne 0) { throw 'Branch read failed' }; if ($s28FixHead -cne 'aaea58a0262c99a7901b39a8309e94b126111b00' -or $s28FixBranch -cne 'codex/v0.3.0-legacy-workflow') { throw 'BLOCKED: final HEAD/branch drift' }; $s28FixRows = foreach ($s28FixPath in $s28FixPaths) { $s28FixHash = (Get-FileHash -LiteralPath $s28FixPath -Algorithm SHA256).Hash.ToLowerInvariant(); if ($s28FixReadonly.ContainsKey($s28FixPath) -and $s28FixHash -cne $s28FixReadonly[$s28FixPath]) { throw ('BLOCKED: read-only source drift: ' + $s28FixPath) }; $s28FixPath + ' ' + $s28FixHash }; $s28FixHasher = [Security.Cryptography.SHA256]::Create(); try { $s28FixIdentity = ([BitConverter]::ToString($s28FixHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($s28FixRows -join [char]10))))).Replace('-','').ToLowerInvariant() } finally { $s28FixHasher.Dispose() }; Write-Output ('HEAD=' + $s28FixHead); Write-Output ('BRANCH=' + $s28FixBranch); Write-Output ('FIX_FINAL_ORDERED_11_PATH_SHA256=' + $s28FixIdentity); $s28FixRows | Write-Output; Write-Output 'READONLY_NINE_BYTES_MATCH=true'; git status --short -- $s28FixPaths; if ($LASTEXITCODE -ne 0) { throw 'Scoped status failed' }; rg -n 'ShouldExpireDisplayedReady|ReadyObservationFreshnessSeconds|IsReadyObservationFresh|ManagerReadyFreshness_Shared|ManagerReadyExpiry_Precedes|ManagerReadyCache_IsProjectPackage' 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs' 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs'; if ($LASTEXITCODE -ne 0) { throw 'Changed-member attribution lookup failed' }
```

</details>

### Frozen input / final identity and unchanged attribution

- Branch: `codex/v0.3.0-legacy-workflow`.
- Pre/post HEAD: `aaea58a0262c99a7901b39a8309e94b126111b00`.
- FIX input ordered eleven-file SHA-256:
  `9549a12925935127059132ca549f9e5ed0599c1191004a0ccd36ea2feb0fc899`.
- FIX final ordered eleven-file SHA-256:
  `6f70f3b4f044b4eeb7db74e87c85bc38e6c3f50269bd666264b2bdd57d466573`.
- Algorithm unchanged: TASK's original eleven paths in order, file-byte SHA-256
  in lowercase, `relative-path + space + hash` rows, UTF-8/LF with no final LF.
  No smaller substitute identity or repository-wide diff/identity was used.

```text
com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs 327f23f5eaa63bb1be77224703b18a9c7371c1d8d19689e43b5a437ef11d76a5
com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs e03ad95304e32c82b861ebafb6391502ca65f217105478114c75c3c55ef026cf
com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs ebc7118a9f3ca7c51f2e2889431e1bdd14d5abbebc027d9c241e24f08f27b6c5
com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs a0c15e7d77650264e9d294893f57d4be68173e8653059765d618006348b17464
com.rice.ai-codedb/Editor/AICodedbActions.cs 2a25e7798e38c19fda2849619072a0ce94cbaa372be0eb70566281a6ff69b1ec
com.rice.ai-codedb/Editor/AICodedbPaths.cs eb571172bac6afd7dd34ec85f3088d8a0f6a6fb71505a8ff67336efbbf858b28
com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 031e0bc5025ecbf91c69783379a580f00fb4d554ff62c02d15514b8b7453fa23
com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1 f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4
com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs 2cfa7275367aa04432034615b6388501e26aafcb4173e8b78eac6f1e30001fe6
com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 0a4ad7f786a5ad929b3db907e0af94f779a2ab2b544b819af0958be209bea059
com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 dcd21d38e12ea9cb1e90067c2c19ea7dfd9b8e647f8803d639c7297b4d4c8bd1
READONLY_NINE_BYTES_MATCH=true
```

The final scoped dirty paths remain the inherited ManagerActionJournal plus
ManagerWindow and ManagerUiTests. Only the latter two changed in this FIX;
ManagerActionJournal's admitted Phase A bytes remain intact. Writer L0 stays
**REUSED**, zero new executions, with unchanged writer SHA-256
`f0273b341d2656cf71668a5e55ccd6e10e46d2517550e633d69162b96d463ec4`.
Planner TASK/ROUTE/VERIFICATION, immutable artifacts and inherited/protected
Unity state were not written or inspected.

### Carried budget and execution attribution

- Same `v0.3.coder.deep`, DURABLE_SESSION / REUSE_ONLY. Actual model identifier
  and reasoning-effort setting are unavailable from this execution interface;
  neither is inferred from the profile or an older summary. No session,
  profile/model override, child agent or Verifier was created/contacted.
- FIX entry: 2026-10-02 10:53:42 UTC+08:00 (02:53:42 UTC).
  Final source/identity stop: 11:01:58 UTC+08:00 (03:01:58 UTC).
  Result timing observation: 11:03:19 UTC+08:00 (03:03:19 UTC).
- FIX source/evidence wall window: 8m16s; including documentation to the timing
  observation: **9m37s**, a conservative active-time upper-bound estimate, below
  the authorized 30 additional active minutes. Exact active/paused split is
  unavailable. The stopped inter-stage interval is not counted as active work.
- Original DEEP_60M working-window estimate **57m04s** is retained, not reset.
  Added FIX estimate makes **66m41s** to this record-time observation against
  the explicitly extended envelope; this is not a precise active-time timer.
- Prior original source diagnosis: 1; prior full Phase A source batch: 1.
  This FIX changed-source/time-bound initial batch: **1/1**, corrected
  mechanical/semantic attempts **0/2, 0/2**, retries **0**. No unchanged rerun.
- PathProvenanceOnly: prior Phase A 1 + FIX 1 = **2 total**; current allowance
  **1/1**, retry 0. Final scoped diff-check: diagnostic 1 + Phase A 1 + FIX 1 =
  **3 total**; current allowance **1/1**.
- FIX admission 1 and FIX final identity 1; no additional identity/diff run.
  Writer REUSED; no new writer, materializer, C# or other L0/L1 batch.
- Retain inherited redesign-repair ledger `0/2` and diagnostic-only checkpoint
  `1/3`; this record adds the explicitly authorized P1-01 correction, not a
  new redesign route or reset. Independent structural causes carried: legacy
  process-proof gap plus this freshness-authority split = **2**. No third
  independent cause, widening or corrected semantic iteration was encountered.
- Captured stdout from the five core FIX command results:
  **6504 characters / ASCII bytes**. Full cumulative inherited/
  read/tool output is unavailable; token estimates are not byte counts.
  Compaction total remains unavailable (at least the supplied prior handoff);
  no exact total is invented. Earlier read errors, evidence and ledgers above
  remain preserved.

### NOT RUN / DEFERRED and completion routing

C# semantic compile, NUnit/Editor/EditMode, Unity/MCP/BatchMode, CUA, protected
runtime/log/process reads, real Manager/Remove/Install/reconciliation, MCP/query,
Phase B passing proof, other L0/L1/full regression, Package export/switch,
commit/tag/push/publication: **NOT RUN / DEFERRED**, as applicable. The original
command remains unknown; source correction does not establish real Ready, a
safe passing new-mutation branch, complete S28 or S25 Gate C PASS. Remaining
risk is separately gated C# and runtime evidence, not a claim that those gates
passed.

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: PARTIAL / PHASE_A_P1_01_SOURCE_EVIDENCE_PASS
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews the stable correction result and decides P1-01-only GUARDED re-review
Human decision or authorization required: targeted Verifier routing/disposition, Phase B proof/expansion, Unity/S25/real-project evidence, commit/export/switch/push/publication

Stopped result is delivered in this Coder conversation. No cross-thread return
authorization was inferred from the Planner delegation, and no next-role
dispatch was performed.


## Phase B Source And Focused Evidence Closure - 2026-10-02

Status: **PARTIAL / PHASE_B_SOURCE_AND_FOCUSED_EVIDENCE_PASS / LEGACY_UNLOCK_DEFERRED**.
This is the single authorized S28 Phase B source/synthetic continuation, not
legacy unlock, complete S28 acceptance or S25 Gate C PASS. Planner's input
admission was reused; no broad admission or Phase A rerun was performed.
Profile remains `v0.3.coder.deep`, DURABLE_SESSION / REUSE_ONLY. Actual model
identifier and reasoning effort are unavailable and were not inferred.

### Implementation and attribution

Eight of the twelve admitted source/test paths changed in this continuation:

- `Editor/AICodedbManagerWindow.cs`: retain authenticated exit/output/elapsed
  even when durable-index release fails; display an authenticated reported
  result separately from unresolved admission; command progress ends before a
  separately labelled, cancellation/lifetime-guarded 5000 ms status observation.
  Retained admission still refuses overlap; unknown/failure/timeout cannot
  automatically request post-command business reconciliation. Close/reattach
  use retained results without replay.
- `Editor/AICodedbProcessRunner.cs`: consume the already-existing receipt
  `output_overflow` / `output_drain_incomplete` fields into typed results.
  Preserve actual child exit and expose incomplete collection; no new schema.
- `Tools~/invoke-codedb-manager-action.ps1`: one monotonic shared 5000 ms
  post-child/deadline budget, one termination request, no unbounded
  `WaitForExit()`. Publish observed actual exit (including failure 7); an
  unobserved exit does not produce a fabricated terminal receipt.
- `Tools~/materialize-codedb-host-payload.ps1`: bound file-output and directly
  coupled pipe helper observation/cleanup with remaining shared budget; expose
  timeout, incomplete collection and unconfirmed direct-child termination.
  Exact Remove retains its existing ownership fingerprint and now rechecks
  next-change admission under the same lock and before mutation.
- `Tools~/codedb-instance-engine.ps1`: read-only next-change admission inside
  the existing project-lock owner; refuse unbound/unfinished/drifted candidates,
  bind current/LKG/retirement/removal and recoverable activation evidence using
  existing readers, and recheck desired/selection fingerprint at the effect
  boundary. A verified in-pass candidate carries only an in-memory execution
  observation flag, not a new durable authority. Incomplete native observation
  retains the candidate without speculative cleanup. Existing Install,
  activation/recovery, removal, holder preservation and directly-owned-child
  termination policy remain the owners of their ordinary preconditions.
- `Tests/Editor/AICodedbManagerUiTests.cs`: nearest real-failure/actual-output,
  incomplete-success/admission and no-replay/display decisions. Source checked;
  these NUnit/C# tests were **not executed**.
- `Tests~/test-codedb-package-boundary.ps1`: parse materialized writer fixtures,
  assert truthful timeout/overflow bits rather than invented exit 4, and record
  exact fixture holder PID/start-time identity for bounded owned cleanup.
- `Tests~/test-codedb-host-payload-materializer.ps1`: early
  `-NextChangeAdmissionOnly` route, isolated runtime-derived fixture root,
  typed authority-reader seams plus real desired-state/path/hash/native checks.
  No canonical/full fixture setup, Provider install or production receipts.

`AICodedbManagerActionJournal.cs`, `AICodedbHostPayloadMaterializer.cs`,
`AICodedbActions.cs` and `AICodedbPaths.cs` are byte-identical to the admitted
input. Inherited Phase A journal bytes are preserved. No Planner-owned records,
lifecycle/Supervisor scheduling, Provider contract, metadata, immutable
generation/artifact or protected validation-project state was written.
Generation transition: NONE. No source/test edits occurred after final identity.

### Commands, outcomes and bounded corrections

All commands used repository cwd `G:\RiceProgram\UnityCodeDB`.
Wall columns are tool-reported seconds; ongoing-session waits are not silently
represented as complete process wall time. Full inline command inputs remain
in this Coder execution record; chunk IDs below identify the actual invocations.

| Evidence / invocation | Chunk | Exit | Wall s | Concise outcome |
| --- | --- | ---: | ---: | --- |
| Initial inline changed-source batch: five PowerShell `Parser.ParseFile`, named function ASTs, C# member-signature slicing and 16 assertions | 062063 | 1 | 1.361456 | Five AST parses and first 15 assertions PASS; stale freshness marker failed |
| Mechanical freshness marker correction 1 | 2e8c85 | 1 | 0.244101 | Incorrectly sought the boundary in Journal |
| Mechanical correction 2: actual `AICodedbManagerStatusBoundary` member in ManagerWindow, shared `30d` | edb9d0 | 0 | 0.225103 | Final assertion PASS; preceding unchanged assertions reused |
| Writer L0 initial same process session 90181 | e3a40b | ongoing | 10.010656 | Command yielded; never relaunched |
| `write_stdin(session_id=90181)` | e8c94c | 0 | 0.000011 | Seven writer receipt scenarios PASS |
| Admission/native L0 initial | 866075 | 1 | 7.320346 | Read-only admission scenarios passed; fixture closure could not resolve `Assert-NoReparsePoint` |
| Fixture loading mechanical correction 1 | 1b7300 | 0 | 3.409916 | Admission/native family PASS |
| Fixture semantic coverage closure 1 | b48e03 | 0 | 3.161154 | Added actual locked-resource refusal, ordinary Install/Upgrade refusal and actual native-result-to-admission linkage; PASS |
| PathProvenanceOnly | 072665 | 0 | 4.517581 | Package path provenance PASS |
| Final fixed twelve-path diff-check | 3b3c8a | 0 | 0.310679 | PASS, no whitespace errors |
| Final twelve-path bytes/HEAD/branch/scoped-status attribution | 7791e0 | 0 | 0.413019 | Frozen HEAD/branch match; eight changed, four unchanged input paths |

Exact focused L0 commands (admission command executed for the three separately
recorded initial/mechanical/semantic attempts, not an unchanged blind rerun):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1 -ManagerActionWriterOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -NextChangeAdmissionOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1 -PathProvenanceOnly
```

Final diff invocation: `git diff --check --` followed by exactly the twelve
repository-relative paths in the identity block below, in that order. Final
identity command uses `git branch --show-current`, `git rev-parse --verify HEAD`,
twelve `Get-FileHash -Algorithm SHA256` calls and
`git --no-optional-locks status --porcelain=v1 -- <same twelve paths>`.
No full diff, repository-wide status/identity or extra diff-check was run.

Source claims covered: selected route/captured context and competing-publisher
refusal; actual results versus retained admission; bounded command/status/exit/
drain/cleanup observation; close/reattach and late lifetime rejection; no failure/
timeout/unknown replay; existing-lock/effect rechecks; ordinary Install and exact
S27 ownership checks; unknown candidate preservation; typed receipt fields and
nearest declared C# tests; accepted shared 30-second freshness.

Final native fixture evidence: success exit 0 / 298 ms; failure exit 7 / 221 ms;
timeout observed exit -1 / timed_out=true / 195 ms. These are fixture-owned
direct-child observations, not proof of project-effect quiescence. Actual
failure/timeout remain refused as candidate change authority. Six labelled
live/unobservable/missing/legacy/failure/timeout cases exercise the common
unbound-root refusal; they are not six production process probes. Full current/
LKG/retirement/contract readers are typed seams in this focused fixture;
real production reader/state/activation integration is not claimed as executed.
Writer total process wall time is unavailable after yielding; recorded tool
waits and final exit above are retained without guessing a complete duration.

### Frozen input and final twelve-path identity

Branch/HEAD unchanged: `codex/v0.3.0-legacy-workflow` /
`aaea58a0262c99a7901b39a8309e94b126111b00`.
Input twelve-path digest:
`0f8a6f4dfc7ad43384459c8333e416dc8b57ffe27dc9cd8d6053e0c81d514a0d`.
Final twelve-path digest:
`3d0b40e229c030a556c988012de940afa8b995acbf33c62af8082a66b3b5726e`.
Algorithm: frozen original eleven paths plus engine twelfth; lowercase file-byte
SHA-256; `relative path + space + hash` rows, UTF-8/LF, no final LF.

```text
com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs 3a73be0ad836af6ef9739676d5d1ae0488e32c92d44bc71ab93ff04e26d956cf
com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs e03ad95304e32c82b861ebafb6391502ca65f217105478114c75c3c55ef026cf
com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs 96d0213cc8dffe5d83df757117d5a89b62a2ffbaf0196524e1d338089ff84265
com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs a0c15e7d77650264e9d294893f57d4be68173e8653059765d618006348b17464
com.rice.ai-codedb/Editor/AICodedbActions.cs 2a25e7798e38c19fda2849619072a0ce94cbaa372be0eb70566281a6ff69b1ec
com.rice.ai-codedb/Editor/AICodedbPaths.cs eb571172bac6afd7dd34ec85f3088d8a0f6a6fb71505a8ff67336efbbf858b28
com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 2ac6dd6c59c3eddb8feaf6bea21fc599785bebc1782c86e0e4092e72cd6223de
com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1 585cdedfdec34d8eefea7be0201b94563c19e6e8d61a671448d63ba8cbcdefae
com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs b06c435cddedbcb9dde2f9e3fc727a0132a245b15ddf485a65011a3dcf49dd9a
com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 2a994a943dc163c0fff7e66c2975708dacb40d58bfc5106dfb6cbae531e1b2ef
com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 81f5487c69cf4a9a369fa3643bd9cf2c662715612560c9271feaf337cea4fa28
com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1 a380e77ff073e7830d7e131b32be1b2c8f7264361801b9b80630864eae700327
```

### Preserved and additional budget ledger

- Prior estimate **66m41s**, inherited attempts/diagnostics and two previously
  recorded causes are retained, not reset. Planned Phase B fault-closure work
  is not silently classified as an additional out-of-scope redesign.
- Phase B start: **09:42:32 UTC / 17:42:32 UTC+08**. Final source/identity
  observation: **10:26:44 UTC / 18:26:44 UTC+08**, wall window **44m12s**.
  Documentation timing observation: **10:29:15 UTC**, wall window **46m43s**;
  conservative combined estimate then **113m24s**. Exact active/paused split
  unavailable; this window includes reads, compaction and waits. Additional
  cap is 60 active minutes, not a reset of the prior ledger.
- Source batch: initial **1/1**, mechanical corrections **2/2**, semantic **0/2**.
  Writer L0: **1/1**, corrections **0/2, 0/2**, restart/retry **0**.
  Admission/native family: initial **1/1**, mechanical **1/2**, semantic **1/2**.
  The semantic fixture change closed declared coverage gaps; no new test family.
  PathProvenanceOnly **1/1**, correction/retry **0**. Final diff-check **1/1**;
  final canonical identity **1/1**. No further evidence attempts planned.
- Three bounded source-navigation commands also exited 1 from accidental
  nonnumeric `Select-Object -First thirty/eighty/seventy` arguments
  (0.444980 / 0.577527 / 0.363269 s). These are retained read/construction
  errors, not hidden passing tests or additional test families.
- Captured output of the eleven core evidence chunks above: **8301 UTF-8
  bytes**. Cumulative inherited/source-read/tool output bytes unavailable;
  token counts are not substituted. Compaction total unavailable; at least
  the inherited handoff and this supplied continuation summary are known.
  No child agent, replacement chat, profile/model override or Verifier contact.
- User explicitly requested Planner notification in this chat; one progress
  notification was accepted by the exact existing Planner thread. This was
  not inferred from delegation and was not next-role dispatch or review PASS.

### NOT RUN / DEFERRED, residual boundaries and stopped routing

Legacy Install remains unknown and unsafe mutation remains refused: no backfill,
receipt/index deletion, forced unlock or renewed legacy process diagnosis.
C# compile/NUnit/EditMode; Unity/MCP/BatchMode/CUA; production runtime/log/receipt/
process reads; real Ready/query/Install/Remove/reconciliation; full activation/
retirement or other L0/L1/full regression; S25 Gate C; export/switch; commit/tag/
push/publish; remote GitProject mutation: **NOT RUN / DEFERRED**.
Remaining acceptance risk is C# semantics and separately authorized real reader/
runtime integration; synthetic PASS is not production process/effect proof.

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: PARTIAL / PHASE_B_SOURCE_AND_FOCUSED_EVIDENCE_PASS / LEGACY_UNLOCK_DEFERRED
Final documentation timing observation: 2026-10-02 10:31:35 UTC; Phase B wall-window estimate 49m03s, carried combined estimate 115m44s; exact active/paused split unavailable. No further source edits or evidence runs after the recorded final identity.
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews this stable twelve-path Phase B snapshot and evidence, then decides the targeted GUARDED route; do not reopen accepted Phase A broadly
Human decision or authorization required: Verifier routing/disposition, C#/Unity/real-project/S25 acceptance, legacy unlock, commit/export/switch/push/publication


## Phase C Real-Reader Fixture And Stopped Evidence - 2026-10-02

### Disposition and authority

**PARTIAL / PHASE_C_FOCUSED_EVIDENCE_PASS /
ROUTE_REASSESSMENT_REQUIRED_OUTPUT_GUARD / LEGACY_UNLOCK_DEFERRED.**

The granted Phase C test/evidence segment is stopped. All declared final local
checks below passed on the final two-test snapshot; this is not full Phase C,
C#/Unity, deployed reader/effect-quiescence, legacy unlock or release acceptance.
A source-navigation output-guard exception is explicitly retained below and
requires Planner/User disposition before treating the preparation gate as closed.

Entry: Frozen Phase C Integration Evidence Scope, preparation/closed-project
admission and Phase C Progress And Continuation. Reused Planner's accepted
input and compatible existing binding; no repeated input Git/hash admission.
DURABLE_SESSION / REUSE_ONLY / v0.3.coder.deep; no child agent, replacement
session or model/profile override. Actual configured model/reasoning metadata
is unavailable to this execution interface; no value is invented.

### Exact test-only deltas

- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`:
  mutually exclusive `-NextChangeAdmissionIntegrationOnly` early return;
  one isolated runtime-GUID fixture family and tightly coupled assertions.
  AST imports retain exact production function bodies and pre-function
  constants/allowlists; production main entry is never invoked. Actual
  `Read-PayloadManifest` validates canonical Package sources/hashes, then only
  the declared immutable-generation/stable-wrapper closure is copied into
  owned temporary projects. The observed canonical generation was `poc.39`,
  read from the Package, not a new generation or copied version authority.
  Missing operation backup lives outside the contract namespace. Generic
  PREPARED journal is factory-authored/read/recovered under the actual lock.
  Effect callbacks use synchronous harness scope/local context, avoiding
  GetNewClosure's module-local script namespace. Selection drift swaps
  current/LKG so every instance remains bound and the rejection is the
  captured fingerprint, not an accidental unbound-root refusal.
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`:
  only fourteen `[Category("S28PhaseC")]` attributes on the exact frozen
  methods in `Rice.AI.Codedb.Editor.Tests.AICodedbProjectSettingsTests`.
  Normalized per-method body/signature/existing-attribute fingerprints match
  the pre-tag source. Existing parameterized attribute sets remain 4 / 4 / 6;
  actual NUnit case counts are NOT RUN, not inferred from those counts.
- This RESULT append is the only administrative write. All ten other admitted
  Phase B paths retain their exact bytes (full final attribution below).
  Production, metadata, generation, project, Planner/Verifier and protected
  runtime files were not edited. Generation transition: **NONE**.
  The earlier typed-seam `-NextChangeAdmissionOnly` family is preserved with
  its original limitations and was not rerun.

### Actual fixture coverage and limits

Final family reported **45 assertions/refusals**, including eight exact-body
comparisons, using no returning reader seams and **native_children=0**:

- Actual `Get-ValidatedCurrentInstance`: canonical current and distinct LKG,
  complete declared generation/wrapper closure; AllowMissing null versus
  required missing refusal; foreign project, manifest hash conflict, LKG path
  escape, corrupt selection JSON and stable-wrapper byte drift.
- Actual `Get-ValidatedInstanceRetirementControls`: valid retirement binding,
  foreign-project rejection and admission's actual retired-manifest hash recheck.
- Actual `Get-InstanceActivationContractState`: COMMITTED activation/operation
  pair; runtime-contract conflict; missing operation; authenticated PREPARED
  classification; missing candidate verification and extra operation directory.
- Actual `Read-InstanceOperationJournal` with
  `New-InstanceTransactionEntry` / `Write-InstanceOperationJournal`: full
  PREPARED entry/id/hash readback, foreign project, backup path escape, corrupt
  JSON; actual `Invoke-InstanceOperationRecovery` removes this fixture-owned
  unpublished PREPARED attempt without changing desired/selection evidence.
- Actual `Enter-MaterializerLock`: same-fixture contention with a 100 ms
  bounded second acquisition. Actual `Publish-InstanceOperation` invokes
  `Assert-InstanceNextChangeAdmission` at its existing pre-mutation callback;
  desired-state and selection drift both return the required
  `changed after preflight` refusal, preserving effect target bytes.
- Actual admission/desired/removal readers: installed admission, empty ordinary
  UNINSTALLED/COMPLETE, intent-bound inert UNINSTALLED/PENDING, retained manifest
  mismatch and unproved in-pass candidate refusal. Ordinary Upgrade-on-
  Uninstalled and Install-on-Installed reject before prerequisite/dispatch.
  No business Install/Remove, Provider/Supervisor operation or process probe ran.

This does not execute ACTIVATING rollback or every generic COMMITTED recovery
branch; it proves the exact listed reader/lock/effect integrations in synthetic
records, not deployed backend liveness, descendant quiescence or the old
Install's missing observation. Each negative checks a specific causal fragment,
not arbitrary exceptions or several labels on the same unbound-root refusal.

### Commands, exit, elapsed evidence and corrections

All commands ran in `G:\RiceProgram\UnityCodeDB`.

| Local family / physical invocation | Exit | Tool elapsed seconds / bounded output |
| --- | --- | --- |
| Initial inline changed-test parse/source batch | 1 | 0.4883548; mutual-exclusion message-marker localization mismatch |
| Same-cause AST-condition correction | 0 | 0.5245817; early route/exact-body calls and fourteen unchanged method/case selections PASS |
| Final changed-test source closure after harness corrections | 0 | 0.5588044; same assertions plus synchronous effect scope, bound selection swap and ordinary Uninstalled markers PASS |
| Integration initial | 1 | 7.0797912; unsafe-path refusal was correct; expected fragment `relative` was wrong |
| Integration mechanical correction 1 | 1 | 7.5825743; contract mismatch correctly refused; expected fragment `identity` was wrong |
| Integration correction 2 (mechanical 2 + semantic 1) | 1 | total process wall unavailable after yield; waits 10.0099171 + 0.0000098; reached real journal/recovery, then module-local RelativePath binding failure |
| Integration semantic correction 2, final | 0 | total process wall unavailable after yield; waits 10.0056571 + 2.6775893; fixture Stopwatch **19665 ms**, UTC start/end **13:42:14 / 13:42:34**; 45 checks PASS |
| Package PathProvenanceOnly | 0 | 1.4726586; `[PASS] Package path provenance.` |
| Final exact twelve-path diff-check | 0 | 0.2428050; empty output |
| Final branch/HEAD/ordered file-byte identity and ten-path attribution | 0 | 0.3794843; unchanged branch/HEAD, non-write paths=10, drift=0 |

Exact focused invocations (integration command used for each changed attempt;
ongoing sessions 89510 and 99338 were waited to final exit, never restarted):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 -NextChangeAdmissionIntegrationOnly
powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly
git diff --check -- 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs' 'com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs' 'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs' 'com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs' 'com.rice.ai-codedb/Editor/AICodedbActions.cs' 'com.rice.ai-codedb/Editor/AICodedbPaths.cs' 'com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1' 'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1' 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs' 'com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1' 'com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1' 'com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1'
```

Changed-test batch was inline PowerShell, not a new runner: exact harness
`[Management.Automation.Language.Parser]::ParseFile` -> one integration
FunctionDefinitionAst -> one early IfStatementAst/two statements/final return
before the old family -> existing mutual-exclusion IfStatementAst -> eight real
reader call sites and absence of reader definitions/seams/native/fixed-root
operations. Required fixture/capture/journal/lock/effect markers were checked.
For the C# selection it used
`(?ms)(?<attributes>(?:^        \[[^\r\n]+\]\r?\n)+)        public void (?<name>\w+)\((?<signature>.*?)\r?\n        \{(?<body>.*?)^        \}`,
exactly fourteen category names, and UTF-8 SHA-256 of each LF-normalized method
with only its category line removed, compared to pre-tag method/attribute
fingerprints. This is source selection, not C# compilation or execution.
The initial localized-error correction replaced message-text selection with
`^if \(@\(\$RepairOnly,`; final source closure covered the changed harness
rather than replaying an unchanged passing source snapshot.

Final identity invocation used `git branch --show-current`,
`git rev-parse --verify HEAD`, and one
`Get-FileHash -LiteralPath <each ordered path below> -Algorithm SHA256`
per file. Lowercase `relative path + space + hash` rows were joined with LF,
without a trailing LF; UTF-8 SHA-256 produced the digest below. Ten non-write
hashes were compared to the already admitted Phase B attribution; no repository-
wide status, full diff, patch identity or repeated final identity ran.

### Final attributable twelve-file identity

Branch: `codex/v0.3.0-legacy-workflow`.
HEAD unchanged: `aaea58a0262c99a7901b39a8309e94b126111b00`.
Accepted input digest:
`3d0b40e229c030a556c988012de940afa8b995acbf33c62af8082a66b3b5726e`.
**Final Phase C twelve-file digest:**
`26a71e42e6bbe16880555c46198541a5f0c294110bd1d14356ec26ad08d7c1dc`.

```text
com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs 3a73be0ad836af6ef9739676d5d1ae0488e32c92d44bc71ab93ff04e26d956cf
com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs e03ad95304e32c82b861ebafb6391502ca65f217105478114c75c3c55ef026cf
com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs 96d0213cc8dffe5d83df757117d5a89b62a2ffbaf0196524e1d338089ff84265
com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs a0c15e7d77650264e9d294893f57d4be68173e8653059765d618006348b17464
com.rice.ai-codedb/Editor/AICodedbActions.cs 2a25e7798e38c19fda2849619072a0ce94cbaa372be0eb70566281a6ff69b1ec
com.rice.ai-codedb/Editor/AICodedbPaths.cs eb571172bac6afd7dd34ec85f3088d8a0f6a6fb71505a8ff67336efbbf858b28
com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 2ac6dd6c59c3eddb8feaf6bea21fc599785bebc1782c86e0e4092e72cd6223de
com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1 585cdedfdec34d8eefea7be0201b94563c19e6e8d61a671448d63ba8cbcdefae
com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs a0f3cb22ecef7a10e9743dbf4e78927077a4249a619eb1e239fe5f71b217c0ea
com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 2a994a943dc163c0fff7e66c2975708dacb40d58bfc5106dfb6cbae531e1b2ef
com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1 39cdf720aed35422652786bc3503b02b007a829e21a9a866f6fe00eb70e74674
com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1 a380e77ff073e7830d7e131b32be1b2c8f7264361801b9b80630864eae700327
```

Only the two test rows differ from input. The other ten rows all matched
admitted Phase B bytes; zero unexplained source/identity drift.

### Preserved budget, output incident and stop

- Retained prior **66m41s**, Phase B **49m03s**, carried **115m44s** estimates,
  failures/attempts and accepted evidence. This continuation did not renew a cap.
- Phase C start **2026-10-02 13:09:42 UTC**; latest continuation began
  **13:31:50 UTC**; final identity **13:44:28 UTC**; documentation observation
  **13:47:33 UTC**. Conservatively charged Phase C wall window **37m51s**,
  within the original additional 60-minute envelope, including reads/waits and
  the progress stop. Combined carried estimate then **153m35s**. Exact active/
  paused split and cumulative compaction count are **unavailable**; supplied
  continuation checkpoint/compaction history is retained, not reset.
- Source family: initial 1/1, mechanical 1/2, semantic final closure 1/2,
  three physical invocations. Integration: initial 1/1, mechanical **2/2**,
  semantic **2/2**, four physical invocations / three changed reruns
  (one combined mechanical+semantic correction). No remaining integration
  correction authority. Path gate 1/1, retry 0; final diff 1/1; identity 1/1.
  No old writer/native/admission family or other test was rerun.
- The twelve recorded core-evidence chunks captured **14171 UTF-8 bytes**.
  Cumulative inherited/navigation/tool output total remains unavailable.
  One source-navigation command,
  `Get-Content -LiteralPath 'com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs' -Raw`,
  exited 0 in **0.22783 s** but returned a **truncated**
  5011-line original read: captured **104106 characters / 104110 UTF-8 bytes**.
  It was stored in orchestration rather than displayed or used as the category
  baseline, but exceeded the normal command output bound. The separate bounded
  fourteen-method fingerprint read supplied the actual baseline.
  This output-limit exception was recognized during final consolidation,
  after the recorded checks; it should have been stopped earlier. It is not
  hidden, retroactively relabelled as compliant, or a production defect.
  No further source edit/check/test followed recognition; this RESULT is the
  permitted stopped append. **ROUTE_REASSESSMENT_REQUIRED** for Planner/User
  disposition of that procedural exception. No automatic rerun or renewed budget.
- Before the initial source family, a bounded navigation regex initially
  selected only the last parameterized attribute. Its grouping was corrected
  before tags/evidence, yielding the true 4/4/6 attribute sets; it was not used
  as a passing case-preservation claim. Earlier ledger records remain untouched.

### NOT RUN / DEFERRED and completion routing

C# compilation/NUnit/EditMode; Unity/MCP/CUA/BatchMode or human Manager scene;
commit/export/ZIP/extracted closure/project dependency switch; immutable
generation/metadata transition; real Install/Remove/Provider/Supervisor/shared
dependency activity; protected runtime/log/process/receipt reads; legacy safe
unlock; real Ready/query/third-party/full lifecycle/full regression; S25 Gate C;
Verifier contact/routing; tag/push/publish/remote GitProject: **NOT RUN / DEFERRED**.

No cross-thread notification was sent for this continuation. Return this single
stopped handoff in the existing Coder chat. Planner/User first disposes the output
guard exception and limited evidence; no artifact/project/Unity/Verifier permit
is inferred from the fixture PASS. Subject to that disposition, Planner owns
the previously conditional limited source/test commit and commit-derived
source/ZIP/extracted closure/dependency preparation. Human Unity and final
Verifier routing remain separately unauthorized. Overall S28 remains PARTIAL;
the old Install is unknown, unsafe mutation is refused, legacy safe unlock is
DEFERRED and S25 Gate C is blocked.

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: PARTIAL / PHASE_C_FOCUSED_EVIDENCE_PASS / ROUTE_REASSESSMENT_REQUIRED_OUTPUT_GUARD / LEGACY_UNLOCK_DEFERRED
Next notification: UnityCodeDB v0.3 Planner via this stopped in-chat handoff only
Next action: Planner/User disposition of output-guard exception and review of the final two-test evidence/ten-path attribution; then decide conditional candidate preparation without an unchanged rerun or broader Phase A/B audit
Human decision or authorization required: output-guard exception disposition now; human C#/EditMode/Unity acceptance and final Verifier routing remain separately gated; no Coder commit/export/project/push/publication authority

## Phase C Human L1 Test-Isolation FIX - stopped, 2026-10-03

**PARTIAL / TEST_ISOLATION_FIX_SOURCE_EVIDENCE_PASS / HUMAN_L1_RETEST_DEFERRED.**
Latest TASK FIX only; v0.3.coder.deep / DURABLE_SESSION / REUSE_ONLY.
Human closure reused. 
### Cause and change

Human evidence retained: 24 PASS / 1 FAIL / 606 unrun; MissingCommandResultCannotReleaseAdmission failed at old line 905 initial TryStart (0.014s, Expected True / But False), before Complete(null). Manager NOT RUN; Editor version/explicit zero-error report UNREPORTED. Source confirms shared _current/pending-state refusal and missing test isolation. Actual blocker origin NOT OBSERVED; no protected probe.

Only source write: `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`.
Eight directly coupled selected session methods use ManagerActionSessionFixture
before session/key access, with NonParallelizable. Synchronous Editor-main-thread
and nonblocking test/actual production Gate ownership reject concurrent/nested
entry. Reflected Gate/_current shape is validated; original object reference is
retained and detached only under Gate. A GUID-derived fixture context claims an
absent pending key. Dispose restores the original object in finally before Gate
release, including exception exit, and erases only its owned key. Owner-thread,
active-scope and idempotent-disposal checks remain. No async/yield, saved-session
field mutation, real-key read/clear or forced recovery completion.
The original failed method adds nested refusal and normal/exception restoration/
key-removal assertions. No added case, Ignore/order escape, production hook or weaker TryStart. All fourteen members, 4/4/6 parameterized
sets, **100 original Assert.That statements** and nonaffected bodies are retained.
SOURCE checks do not prove compilation/NUnit/live isolation; original human FAIL
remains unclosed pending authorized new-candidate retest.

### New local evidence and identity

Workspace `G:\RiceProgram\UnityCodeDB`.

| Command/evidence | Exit | Tool wall seconds | Result |
| --- | --- | --- | --- |
| Once-only input admission | 0 | 0.8439848 | frozen identity; twelve source paths clean |
| Bounded pre-edit method/attribute/assertion baseline | 0 | 0.4705672 | fourteen metadata rows |
| Inline changed-test/source-selection batch, initial | 0 | 0.4280274 | membership/cases/100 assertions, eight scopes, nonaffected bodies and ownership/finally statements PASS |
| PathProvenanceOnly, initial | 0 | 4.9466823 | path provenance PASS |
| Final twelve-path diff-check | 0 | 0.2273264 | empty output |
| Final digest/eleven-path attribution | 0 | 0.3791581 | unchanged branch/HEAD; eleven matches, drift=0 |

Exact path command:
`powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`.
Diff: `git diff --check --` plus exactly the prior Phase C twelve paths/order.
Admission/final identity: `git branch --show-current`,
`git rev-parse --verify HEAD`, one
`Get-FileHash -LiteralPath <each ordered path> -Algorithm SHA256` per file.
Canonical digest uses lowercase path/space/hash rows, UTF-8/LF without final LF. Inline source batch compares membership/assertion/body fingerprints and ownership/finally guards; it does not run C#.

Branch `codex/v0.3.0-legacy-workflow`; input/final HEAD
`ac6bfb99014ae5bcbe8f54a7641984a74023f326`.
Input twelve-path SHA-256:
`26a71e42e6bbe16880555c46198541a5f0c294110bd1d14356ec26ad08d7c1dc`.
Final twelve-path SHA-256:
`8302fc38978ab53ff350ea9ee8e373bf69c5743dbde0edd32cd0690cab41aada`.
Final test SHA-256: `e178d63e38ff46483799fe0521d537852ccf4f4618bb21cb25fd101207f369dd`.
Eleven read-only paths (original ordered set minus this test) all match input hashes; drift=0. Full final rows are retained in command output.
No production, PowerShell, identity/metadata/generation, old candidate ZIP/
extraction/reference, project or Planner/Verifier edit. Generation transition
NONE; only this source file and this append changed.

### Budget, limits and routing

Prior 66m41s / Phase B 49m03s / Phase C 37m51s / carried **153m35s** wall
estimates, failures, exhausted integration corrections and acknowledged output
violation remain; no old test replay or renewal.
New DEEP_30M start **03:34:11 UTC / 11:34:11 UTC+08**; documentation observation
**2026-10-03 04:02:02 UTC**; conservative wall charge **27m51s**, carried
combined estimate **181m26s**. Exact active/paused/compaction totals and
configured model/reasoning unavailable; no override.
Source initial 1/1, semantic 0/2; pre-assertion mechanical construction 2/2: expired orchestration state
TypeError before any Git execution, and atomic Path.combine patch-context typo
(no write). Neither reran input/evidence. Path initial 1/1, retry/correction 0;
final diff 1/1, identity 1/1. Six retained chunks captured **15667 UTF-8 bytes**;
cumulative inherited/navigation output unavailable. Selected excerpts/metadata
only, no whole-file dump. Five draft sizes were checked before any write.

C# compile/NUnit/EditMode, corrected human Unity/Manager, Unity/MCP/CUA/BatchMode,
runtime/process/receipt probes, real operations, other L0/L1, commit/export/
reference switch, Verifier, tag/push/publish: **NOT RUN / DEFERRED**.
Compiler/API and real restoration remain L1 DEFERRED. Prior source/closure PASS and Phase A/B
ACCEPT stand; legacy safe unlock DEFERRED, S28 PARTIAL / S25 Gate C blocked.

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: PARTIAL / TEST_ISOLATION_FIX_SOURCE_EVIDENCE_PASS / HUMAN_L1_RETEST_DEFERRED / LEGACY_UNLOCK_DEFERRED
Next notification: Planner via this stopped in-chat handoff only
Next action: Planner/User decides new-candidate preparation and corrected human L1; no Verifier dispatch
Human decision or authorization required: new commit/export/reference preparation and corrected Unity gate; final Verifier routing later; no Coder commit/push/publication authority


## Phase C Test API Compatibility FIX - stopped, 2026-10-03

**PARTIAL / TEST_API_FIX_SOURCE_EVIDENCE_PASS / COMPILE_AND_HUMAN_L1_DEFERRED / LEGACY_UNLOCK_DEFERRED**.

### Admission and repair

Latest TASK grant only. Human confirmed Unity closed; no process check.
Branch codex/v0.3.0-legacy-workflow; input/final HEAD
`edef71393357711ecec22c922ebf553dde8fe13a` (recorded Planner commit lineage).
Input twelve-path SHA-256:
`8302fc38978ab53ff350ea9ee8e373bf69c5743dbde0edd32cd0690cab41aada`;
input test SHA-256:
`e178d63e38ff46483799fe0521d537852ccf4f4618bb21cb25fd101207f369dd`.
Once-only admission matched; zero overlapping dirty/staged source.

Only source write: com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs.
Removed all eight unresolved NonParallelizable attributes, not just line 255.
No replacement NUnit/order/Ignore workaround. Replaced internal
CurrentThreadIsMainThread() with public BCL SynchronizationContext.Current,
GetType().FullName and ordinal Unity Editor context-name comparison. Null/unknown
contexts refuse before isolation; no internal Unity compile-time API reference.
Both Monitor.TryEnter calls now use public (object,int), timeout 0.
Those latter APIs were reviewed, not claimed to have produced observed errors.

Production Gate exclusion, nested/concurrent refusal, GUID-derived absent owned
key, original _current reference restoration under Gate on success/exception,
owner-thread checks and owned-key-only erasure preserved. No real pending
cleanup, forced admission/Ready/recovery, session discard/replay or production hook.
Every test method body remains identical to input: 14 S28PhaseC methods / 25
cases, 4/4/6 parameterized sets, eight fixture-first users, all 105 input
Assert.That statements, categories/parameters and nonselected behavior retained.
Editor/TestAssemblies binding and framework 1.1.33 / ext.nunit 1.0.6 unchanged.

Public BCL signature rationale is source evidence only. Actual Unity Test Runner
context, compilation/API compatibility, NUnit and restoration remain DEFERRED.
Candidate CS0246 exhausted corrected visible session 1/1 before S28PhaseC or
Manager started. Original 24 PASS / 1 FAIL / 606 unrun and F-C01 OPEN preserved;
neither failure is closed by this source/path result.

### Commands, exit and tool wall seconds

All commands exit 0. Exact inline scripts and argument arrays remain in tool
record; twelve-path order is TASK lines 1024-1035, path + space + lowercase
file-byte SHA-256 rows, UTF-8 LF joined without final LF.
- Authorization read 0.2609204; skill/registry read 0.2696552; scoped discovery
  0.2575622; direct fixture/session/binding reads 0.3235394/0.4132265/0.3093612.
- Input inline: git branch --show-current; git rev-parse HEAD;
  git status --porcelain=v1 --untracked-files=all -- <ordered twelve paths>;
  file hashes/ordered digest. 0.4277017; exact match.
- One changed-test/source-selection inline batch: 0.4254515; eight PASS summaries.
  Baseline: git show HEAD:com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs.
  Exact permitted delta, selection/cases/assertions, API shape, Gate/key ordering,
  success/exception assertions, unchanged production hash and bindings checked.
- `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`:
  1.4890117; child exit 0; "[PASS] Package path provenance."
- One `git diff --check -- <ordered twelve paths>`: 0.2317363; no diagnostics.
- One final ordered digest/eleven-path attribution/scoped status: 0.3872939;
  eleven unchanged, drift=0, only test unstaged.
- Existing RESULT tail read: 0.2389701; prior records untouched.

Final twelve-path SHA-256: `b137e30f2e153f052b5d87017363e4180c4d9e85acb270aab0113d1fb3eaa590`.
Final test SHA-256: `e290e5eff14e87d1e4a4a342b07e269ca2e0f072cdb4f350381e023e82e8ddad`.
All eleven read-only identity paths unchanged. No production/PowerShell,
assembly/package contract, artifact/project/reference, generation or
Planner/Verifier write. Package 0.3.0-preview.5 / poc.39; transition NONE.

### Ledger and stopped return

New DEEP_30M clock anchor 2026-10-03 06:17:28 UTC; documentation 2026-10-03 06:33:01 UTC;
anchored wall estimate 15m33s; initial TASK read precedes anchor. Exact
active/paused totals, cumulative compactions and model/reasoning unavailable;
no profile/model override. Source initial 1/1 and semantic 0/2; path initial 1/1
and semantic 0/2; input/final diff/final identity each 1/1. Mechanical size
corrections 2/2: RESULT drafts 7938 and 6782 bytes rejected before any write,
then compressed; no source/evidence retry. Final append guarded <=6 KiB.
Seven retained command chunks: 16,722 UTF-8 bytes; full cumulative read/tool
output unavailable. Bounded excerpts only; no whole-file/log dump or wait timeout.

Prior 27m51s / combined 181m26s estimates, output violation, failures and
exhausted attempts retained; anchored combined estimate 196m59s.
Unanchored preparation/exact historical active time unavailable.
No unchanged Phase A/B/integration or other suite replayed.

Compile/NUnit/EditMode, human Unity/Manager, Unity/MCP/CUA/BatchMode,
protected Library/DLL/runtime/process/SessionState probes, business actions,
other L0/L1, commit/export/package patch/reference switch, Verifier/remote
update/tag/push/publication: NOT RUN / NOT AUTHORIZED.
Phase A/B source ACCEPT retained; S28 PARTIAL / legacy unlock DEFERRED /
S25 Gate C blocked. Coder stopped; source and append remain uncommitted.

Current task: cdb-v0.3-p0-s28-manager-history-status-change-admission
Current status: PARTIAL / TEST_API_FIX_SOURCE_EVIDENCE_PASS / COMPILE_AND_HUMAN_L1_DEFERRED / LEGACY_UNLOCK_DEFERRED
Next notification: Planner via terminal in-chat handoff only
Next action: Planner reviews snapshot and decides candidate preparation plus human compilation/focused L1 authorization
Human decision or authorization required: candidate preparation, human Unity gate, later Verifier routing; no automatic cross-thread dispatch/publication


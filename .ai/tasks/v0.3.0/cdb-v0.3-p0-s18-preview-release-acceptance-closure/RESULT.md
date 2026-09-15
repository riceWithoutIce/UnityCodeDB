# S18 Closed-Project Preflight Result

Execution date: 2026-09-14. This was the authorized closed-project admission
and candidate preflight only. `UnityValidationProject` was treated as human-
confirmed closed. No Unity, Unity Hub, Unity MCP, CUA, BatchMode, process,
log, protected runtime, external probe, test, compile, publication, or source
operation was performed. No inherited S14/S14r or validation-project state was
read, cleaned, staged, or included in identity claims.

## Admission

The single branch/HEAD admission command was:

`$branch = git symbolic-ref --short HEAD; $head = git rev-parse --verify HEAD; ...`

Exit: `0`. Branch: `codex/v0.3.0-legacy-workflow`. HEAD:
`eb21a7a5d28548e0369db35ee0cac1c0d626183c`. Both exactly match the frozen
task card. Command wall time was unavailable from the bounded orchestration
record; no retry was used.

## Candidate Identity

The exact candidate metadata files were parsed structurally and their SHA-256
values recorded:

- Package `com.rice.ai-codedb/package.json`: version `0.3.0-preview.1`, Unity
  compatibility `2022.3`, SHA-256
  `ec906ade8622e7d4c5e9be4888fb6dd071510e8b4fe7645f55a7d1ead202b4e3`.
- Payload manifest `com.rice.ai-codedb/Payload~/payload-manifest.json`:
  package `0.3.0-preview.1`, generation/payload `poc.35`, sequence `35`,
  control contract `v0.3-control` version/schema `1/1`, control SHA-256
  `7c85ebc534091fcb53d40eedd9eadf869c09caf77fb56a35aeb22e0e8aea09a1`,
  manifest SHA-256
  `c13b837bd95e644311b20bef59ca9e2de1f1df8399a7d56d494980195123ce48`.
- Tracked pointer `com.rice.ai-codedb/Payload~/host-current.json`: target
  `poc.35`, sequence `35`, generation path
  `AIWork/.runtime/codedb/host/generations/poc.35`, generation manifest
  SHA-256 `481b7f20ad804797f0617e159c74d189246f923f955f306b39bcbb3c16d2e006`,
  pointer SHA-256
  `549143203ee3853e0feec16432bc0a344450c248c20768ede17936d30cff5205`.
- `poc.35/generation-manifest.json`: 22 files, package/generation/sequence
  `0.3.0-preview.1` / `poc.35` / `35`, SHA-256
  `481b7f20ad804797f0617e159c74d189246f923f955f306b39bcbb3c16d2e006`.
  All 22 declared file hashes matched the checked package files (`22/22`,
  mismatch count `0`).
- Provider distribution: schema `2`, `killop/codedb-mcp`, version
  `0.5.0-28e3912-c2`, commit
  `28e3912d5cd67ff3499734984f3e3d626a204796`, protocol `codedb-cli-v1`,
  capability `codedb-search-tools-v1`, executable/archive SHA-256
  `38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7`.
  Distribution file SHA-256:
  `25b2a7f2d750dd3e308a589c493484cd5615bc130c3d0662f967f23e29871919`;
  recorded distribution metadata also has `license_status=PENDING` and was
  not changed or interpreted as a publication decision.

The five candidate metadata files were clean against the frozen HEAD. Pointer,
payload, and generation manifest hashes cross-matched; all structured checks
returned `true`. The bounded structured inspection command exited `0` with
wall time `0.4647498s`; no retry was used. Accepted S17 identities carried from the task card remain
`af645f364fb41202ef3b56d7113b5d29aa6aef32` and
`970b95b826a5aefa7130a17a813a5fc3240337cb7d616f0fc2459ec517095a04`; they
were not recomputed.

## Human Phase A Checklist

After separate Planner/user authorization, the human may open
`UnityValidationProject` and perform exactly one continuous local scenario:

1. Compile with zero current C# errors; record warnings without promoting the
   already dispositioned non-blocking warning.
2. Reach stable supported cold state without deleting runtime data, editing
   configuration, stopping a process, repeated refresh, or normal-path
   Reinstall.
3. Enter Play before Manager, return to Edit Mode, and observe one ordinary
   Domain Reload/reconnect without duplicate Supervisor, Coordinator, Provider,
   adapter, or maintenance work.
4. Open Manager, allow ordinary repaint/cache/tab activity, close it, and
   capture terminal evidence showing all prohibited main-thread work counts and
   violation count zero with no refresh in flight.
5. Confirm query-first ordering and stale/missing-index behavior using the
   accepted evidence boundary; do not manufacture another maintenance action.
6. Close Unity normally and confirm bounded, non-blocking shutdown with no
   unresolved authenticated Package-owned runtime.

Coder does not perform those transitions or substitute CUA/MCP/BatchMode or
protected runtime reads. Phase B publication, Phase C external Package-only
and Codex validation, and Phase D Verifier review remain unauthorized/deferred.

## Human Phase A Checkpoint - Local Handoff Blocked

Evidence date: `2026-09-14`. After the Play-to-Edit transition, the human
opened Manager and observed the candidate in `Needs attention`; Host payload
was `Needs Setup / Not evaluated`, Current instance and most dependent layers
were `Inactive / Not evaluated`, and the visible diagnostic said the
availability probe required handoff from the trusted previous generation.
This is a setup/handoff blocker before stable readiness, not a successful
runtime gate. No recovery action was clicked.

With Manager still open, the human then closed Unity normally and reported a
quick bounded exit. Exact elapsed time and independent process observation
were not measured. The shutdown sub-check therefore passes by human
attestation, while the overall Phase A result remains `BLOCKED /
LOCAL_HANDOFF_NOT_READY`.

No source, test, Package, runtime, or configuration change was made. The
next action is one same-task, bounded Coder diagnosis of the trusted-generation
handoff within the existing conditional allowlist; no new micro-task or
Verifier routing is warranted before that diagnosis.

## Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`
Current status: `BLOCKED / LOCAL_HANDOFF_NOT_READY`
Next notification: `UnityCodeDB v0.3 Planner / User`
Next action: decide whether to authorize one bounded same-task Coder diagnosis
and in-allowlist repair of the trusted-generation handoff. Do not route
Verifier or enter publication/third-party phases while this gate is blocked.
Human decision required: same-task diagnosis authorization, then renewed Phase
A evidence, publication authorization, third-party/Codex acceptance, Verifier
routing, and final release disposition.

## Planner Continuation - Owner-Free Legacy Pointer Repair

Evidence date: `2026-09-14`. The trusted-previous marker repair was confirmed
as a distinct local correction, but its single focused `UpgradeOnly` scenario
stopped on a second independent product cause before the new marker assertion:
owner-free retirement left an existing legacy `current.json` pointer at
`poc.27` instead of switching host/current to the candidate `poc.35`.

This is still the same S18 acceptance outcome and remains inside the declared
conditional allowlist, with repair/cause budgets at the second and final
iteration. The existing source comment and `Get-InstanceActivationEntries`
branch show that legacy pointer retention is currently unconditional whenever
the pointer exists; the required repair must distinguish an owner-free,
validated legacy closure from a live or ambiguous owner/lease window. It must
preserve live/invalid/ambiguous evidence and never stop an external process.

Planner authorizes the Coder to continue once, in the same task, to diagnose
and repair this exact owner-free retirement path and run one directly adjacent
focused `UpgradeOnly` evidence attempt. No third repair, new independent cause,
immutable-generation change, Provider/Package change, expanded allowlist, or
external side effect is authorized. Unity remains closed and Verifier routing
is deferred until a stable result exists.

## S18 Coder Continuation - Trusted-Previous Marker Repair (BLOCKED)

Execution date: 2026-09-14. Planner authorized the same-task bounded repair
envelope while `UnityValidationProject` remained closed. The frozen branch and
HEAD were rechecked before editing and remained:

- Branch: `codex/v0.3.0-legacy-workflow`
- HEAD: `eb21a7a5d28548e0369db35ee0cac1c0d626183c`

No Unity, Unity MCP, CUA, BatchMode, protected runtime access, publication,
commit, push, or Verifier action was performed. The inherited S14/S14r and
validation-project dirty state was not changed.

### Diagnosis and bounded repair

The direct call-chain diagnosis confirmed that the trusted-previous product
status is emitted by `Write-InstanceProductStatus` in
`com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`. The minimal repair was:

1. In the trusted-previous branch, emit
   `[PRODUCT_LAYER PREREQUISITE] CURRENT - <detail>` only when the current
   invocation has not already published prerequisite status. This preserves
   the top-level materializer's single-marker/cardinality rule while covering
   the direct trusted-previous status path.
2. In `Invoke-PriorGenerationUpgradeScenarios`, add the requested pre-Upgrade
   `DryRun` assertions for `CURRENT`, `INSTANCE=TRUSTED_PREVIOUS`, and
   `PRODUCT_STATE=NEEDS_ATTENTION`.

Only these two allowlisted files were modified:

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

`poc.35`, Package metadata, Provider contract, global configuration, and all
other paths remained unchanged. The repair is uncommitted.

### Evidence and budget ledger

Static/source batch, once:

`$sw = [Diagnostics.Stopwatch]::StartNew(); $paths = @('com.rice.ai-codedb\\Tools~\\codedb-instance-engine.ps1', 'com.rice.ai-codedb\\Tests~\\test-codedb-host-payload-materializer.ps1'); ... [System.Management.Automation.Language.Parser]::ParseFile(...) ...`

Exit: `0`; measured wall time: `376 ms`.
Output: both PowerShell files reported `AST PASS`.

Focused L0 batch, exactly once and with no retry:

`powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\\Tests~\\test-codedb-host-payload-materializer.ps1 -UpgradeOnly`

Exit: `1`. A process-start stopwatch was not embedded in the authorized
command; exact process wall time is therefore unavailable. The observed
session wait was approximately `20.1 s` and is recorded as an observation, not
an exact process duration. The first independent failure was:

`Owner-free retirement did not switch host/current to poc.35. Expected 'poc.35', got 'poc.27'.`

The failure occurred in the pre-existing owner-free retirement portion of
`Invoke-PriorGenerationUpgradeScenarios`, before the newly added
trusted-previous assertions were reached. Static inspection shows that
`Get-InstanceActivationEntries` intentionally retains an existing legacy
`current.json` pointer until its legacy owner/lease window drains; changing
that authority would be a separate legacy-pointer/retirement repair, not a
continuation of the marker finding. No second repair or L0 rerun was attempted.

Scoped diff check, once:

`git diff --check -- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1 com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

Exit: `0`; measured wall time: `181 ms`.

Budget: static/source `1/1`; focused L0 `1/1`; corrected retry `0/0`; scoped
diff check `1/1`. No C# L1, EditMode, Unity, Unity MCP, external release
scenario, full regression, or unrelated test was run. The trusted-previous
marker repair therefore has no passing focused-L0 evidence and must not be
represented as Unity readiness.

### Completion routing

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `BLOCKED / FOCUSED_L0_OWNER_FREE_RETIREMENT_FAILURE`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: Planner reviews the independent legacy-pointer failure and decides
whether to authorize a second bounded in-allowlist repair or route
reassessment. Do not route Phase A retry or Verifier on this snapshot as if the
repair had passed.

Human decision or authorization required: any legacy pointer/retirement repair,
additional focused evidence, renewed Phase A Unity scenario, publication,
third-party acceptance, Verifier routing, commit, or push.

## S18 Coder Final Bounded Repair - Owner-Free Legacy Retirement (BLOCKED)

Execution date: `2026-09-14`. Planner authorized the second and final
same-task repair iteration for the owner-free legacy-pointer retirement
finding. The frozen branch and HEAD remained:

- Branch: `codex/v0.3.0-legacy-workflow`
- HEAD: `eb21a7a5d28548e0369db35ee0cac1c0d626183c`

`UnityValidationProject` remained closed. No Unity, Unity MCP, CUA, BatchMode,
protected runtime/process/log access, publication, commit, push, or Verifier
action was performed. Inherited S14/S14r and validation-project dirty state
was not changed.

### Bounded change

Only `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` was changed in
this repair. The successful candidate activation path now invokes the
existing `Get-CombinedInstanceCleanupState` authority with the held
materializer lock and `-PerformCleanup`, then persists the returned cleanup
state through `Update-InstanceDesiredCleanupState` when it differs from the
post-activation state. This restores the existing owner-free legacy closure
retirement path while preserving the existing lease/owner validators and their
fail-closed `PENDING` behavior. No external process is stopped. The earlier
trusted-previous `CURRENT` marker correction remains present in the two
allowlisted files; the harness was not modified in this repair.

### Evidence and budget ledger

Bounded AST/source check, exactly once:

`$sw = [Diagnostics.Stopwatch]::StartNew(); $paths = @('com.rice.ai-codedb\\Tools~\\codedb-instance-engine.ps1','com.rice.ai-codedb\\Tests~\\test-codedb-host-payload-materializer.ps1'); ... Parser::ParseFile(...) ...`

Exit: `0`; measured wall time: `430 ms`.
Output: both allowlisted PowerShell files reported `AST PASS`; the static
owner-free cleanup call and existing-authority binding assertions passed.

Focused L0, exactly once and with no retry:

`powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\\Tests~\\test-codedb-host-payload-materializer.ps1 -UpgradeOnly`

The command ran to final exit in the same process session. Exit: `1`.
Exact child-process wall time was not embedded in the authorized command; the
observed orchestration wait was approximately `10.1 s` and is recorded as an
observation, not an exact process duration. The first failure after this
repair was:

`v0.2.4 owner-free instance Upgrade command-result cleanup state mismatch. Expected 'COMPLETE', got 'PENDING'.`

The run stopped at that assertion. No investigation, corrected retry, third
repair, or additional test was attempted.

Final scoped diff check, exactly once:

`git diff --check -- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1 com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

Exit: `0`; measured wall time: `179 ms`.

Budget: AST/source `1/1`; focused UpgradeOnly L0 `1/1`; corrected retry `0/0`;
scoped diff check `1/1`; local repair iteration `2/2`; independent product
cause budget `2/2`. The final bounded repair did not produce a passing focused
L0 result and cannot be represented as Phase A readiness.

Not run / deferred: C# L1, EditMode, Unity, Unity MCP, CUA, BatchMode, real
business processes, publication, Package-only third-party validation, real
Codex acceptance, full regression, unrelated tests, immutable-generation or
Provider/Package changes, commit, push, and Verifier review.

### Completion routing

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `ROUTE_REASSESSMENT_REQUIRED / BLOCKED / FOCUSED_L0_CLEANUP_STATE_FAILURE`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: Planner reviews the failed final bounded repair and decides the
route reassessment. Do not route Phase A retry or Verifier on this snapshot.

Human decision or authorization required: any further owner-free retirement
repair or evidence, renewed Phase A Unity scenario, publication,
third-party/Codex acceptance, Verifier routing, commit, or push.

## Planner Route Reassessment - Cleanup Contract Separation

On `2026-09-15`, the two local repair iterations and two independent causes
were exhausted. The final `PENDING` result is now classified as a contract
boundary conflict, not permission for a third pointer/cleanup patch: product
documentation allows asynchronous retired cleanup to remain `PENDING` without
gating new-instance usability, while the focused fixture required immediate
`COMPLETE`.

The same S18 outcome is retained and a structural continuation is authorized
in `ROUTE-REASSESSMENT.md`. Activation must own candidate selection and may
return successful `UPGRADED` with either legal cleanup state; cleanup remains
the separate holder-aware authority and later maintenance pass. No Unity,
publication, Verifier, commit, or push is authorized by this route.

## S18 Route-Authorized Cleanup Contract Separation Continuation (BLOCKED)

Execution date: `2026-09-15`. The Planner confirmed the existing S18 route
authorization. `UnityValidationProject` remained closed. The continuation
stayed within the route allowlist and did not modify immutable `poc.35`,
historical generations, Provider/Package metadata, validation-project state,
or inherited S14/S14r records.

### Frozen identity and bounded changes

- Branch remained `codex/v0.3.0-legacy-workflow`.
- HEAD remained `eb21a7a5d28548e0369db35ee0cac1c0d626183c` before and after the
  continuation.
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` was changed to
  validate existing legacy current/LKG generation pointers and include both
  pointers in the same activation transaction journal; isolate post-COMMITTED
  cleanup exceptions so `UPGRADED` remains successful with legal
  `CLEANUP_STATE=PENDING|COMPLETE`; publish holder-aware retry guidance; and
  remove only the exact, revalidated retired-instance control after its
  corresponding instance is deleted.
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` was
  changed only in the direct `UpgradeOnly` fixture: immediate candidate
  current/LKG selection is asserted, PENDING retains the old marker/generation
  and flat closure, later convergence requires COMPLETE, active/unknown owner
  safety remains asserted, and the activation-failure fixture rejects an
  unbound retired control. The one corrected assertion accepts the existing
  worker-owned availability transition markers `UNAVAILABLE|PENDING` while
  retaining CONFIGURED and NEEDS_ATTENTION requirements.
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` remained
  byte-unchanged from HEAD.

Scoped worktree hashes after the continuation:

- `codedb-instance-engine.ps1`: `725902bdfdbeaaa5198b1268b7339b1823eea404`
- `materialize-codedb-host-payload.ps1`: `89410db933769ccfe1f000d01da2b77288c30ecf`
- `test-codedb-host-payload-materializer.ps1`: `2f8ef435aa1d68b011ef75e38b8708641bed617d`

### Evidence and budget ledger

Bounded static/source batch, exactly once:

`Parser::ParseFile` plus direct function-source ownership assertions for the
engine, materializer, and UpgradeOnly harness; the batch also checked that the
materializer was byte-unchanged from HEAD.

Exit: `0`; wall time: `1435 ms`. Result: `PASS` for all bounded structural
assertions, including joint current/LKG journaling, post-commit cleanup
isolation, exact control removal, legal cleanup states, retained-closure
semantics, holder-aware next action, and trusted-previous markers.

Consolidated focused L0 initial attempt, exactly once:

`powershell -NoProfile -ExecutionPolicy Bypass -File com.rice-ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UpgradeOnly`

Exit: `1`; wall time: `54834 ms`. First failure:
`Transient availability failure was not isolated to MCP availability.` The
initial run had reached the direct activation/retirement assertions; no
investigation or automatic retry followed this failure.

Same-cause corrected semantic attempt, exactly once:

The only correction changed the direct transient-availability assertion to
accept `MCP_AVAILABLE UNAVAILABLE` or the existing worker-owned transitional
`MCP_AVAILABLE PENDING`, while retaining `CONFIGURED CURRENT` and
`PRODUCT_STATE NEEDS_ATTENTION` requirements. The same command was then run
once more:

`powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UpgradeOnly`

Exit: `1`; wall time: `47502 ms`. First real failure after the correction:
`Transient availability failure was incorrectly reported as Ready.` The
attempt stopped immediately. No production availability repair, further
investigation, or third attempt was performed.

Final scoped diff check, exactly once:

`git diff --check -- com.rice.ai-codedb\Tools~\codedb-instance-engine.ps1 com.rice.ai-codedb\Tools~\materialize-codedb-host-payload.ps1 com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1`

Exit: `0`; wall time: `215 ms`.

Budget: static/source `1/1`; focused UpgradeOnly L0 initial `1/1`; same-cause
corrected semantic attempt `1/1`; automatic retry `0`; final scoped diff check
`1/1`. No Unity, Unity MCP, CUA, BatchMode, process/runtime probe, full
regression, unrelated test, C# L1, EditMode, publication, commit, push, or
Verifier action was run. The materializer was not modified.

The focused evidence does not prove the route-reassessed contract because the
corrected run exposes a real transient-availability state failure. The current
snapshot must not be represented as Phase A retry-ready, publication-ready, or
Verifier-ready.

### Completion routing

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `ROUTE_REASSESSMENT_REQUIRED / BLOCKED / FOCUSED_L0_TRANSIENT_AVAILABILITY_FAILURE`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: Planner reviews the bounded structural changes and the first real
corrected L0 failure, then decides whether a new in-allowlist availability
repair route or broader reassessment is warranted. Do not route Phase A or
Verifier on this snapshot.

Human decision or authorization required: any further production or fixture
repair, additional focused evidence, renewed Phase A Unity scenario,
publication, Verifier routing, commit, or push.

## S18 Availability Authority Fixture Continuation (BLOCKED)

Execution date: `2026-09-15`. Planner authorized the same-snapshot
`FIXTURE_CONTRACT_CORRECTION / SUPERVISOR_AUTHORITY_PRESERVATION`
continuation. `UnityValidationProject` remained closed. No production file,
immutable generation, Package/Provider metadata, validation-project state, or
inherited S14/S14r record was changed by this continuation.

### Identity and fixture correction

- Branch remained `codex/v0.3.0-legacy-workflow`.
- HEAD remained `eb21a7a5d28548e0369db35ee0cac1c0d626183c`.
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` remained byte-exact at
  worktree hash `725902bdfdbeaaa5198b1268b7339b1823eea404`.
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` remained
  byte-exact at worktree hash `89410db933769ccfe1f000d01da2b77288c30ecf`.
- Only `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
  changed. Its final worktree hash is
  `9d8808c1d87cd4badb0da9e1d14bb8e5e35c4a6b`.

The direct `UpgradeOnly` fixture now constructs a fresh `core_ready`
Supervisor observation bound to the exact project identity, selected candidate
instance/generation, target generation, control-contract Supervisor runtime,
and raw runtime-contract hash. Each current-instance convergence call installs
that value only in process scope and restores the exact prior value in
`finally`. The transient availability scenario corrupts only the lower-level
instance document and requires `CONFIGURED=CURRENT`, `MCP_AVAILABLE=CURRENT`,
`PRODUCT_STATE=READY`, plus forwarding of the exact observation identity. It
then republishes the previously verified lower-level bytes, runs `Probe`, and
checks the same immutable selection and valid lower-level candidate evidence.
The existing absent, malformed, stale, mismatched, and degraded Supervisor
coverage was not changed.

The single authorized mechanical correction changed the fixture lease-holder
`ProcessStartInfo.WorkingDirectory` from the repeatedly rebuilt Host root to
the generated holder script's parent directory. This correction did not alter
production behavior, lease identity, or process lifetime semantics, but the
same process-start failure remained.

### Evidence and budget ledger

Bounded static/source batch, exactly once:

`Parser::ParseFile` for the engine, materializer, and harness, plus direct AST
function assertions for observation identity binding, environment restoration,
corrupt/restore/Probe ordering, authoritative result markers, lower-level
evidence identity, scoped convergence calls, frozen production hashes, and
byte-semantic equality of the existing Supervisor fail-closed coverage against
HEAD.

Exit: `0`; wall time: `2012 ms`. Result: `PASS`.

Consolidated focused L0, initial attempt:

`powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UpgradeOnly`

Exit: `1`; wall time: `50406 ms`. The authority-correction scenario and the
owner-free current-instance convergence completed far enough to enter the
existing active-holder fixture. The first failure was:

`Start-LegacyHostUseLeaseProcess : Exception calling "Start" with "0" argument(s): "The system cannot find the file specified"`

The failure occurred at the fixture-owned lease-holder process start, before
the active-holder assertions.

Single same-cause mechanical fixture correction and corrected L0 attempt:

After the one WorkingDirectory correction described above, the exact same
`-UpgradeOnly` command was run once more. Exit: `1`; wall time: `50731 ms`.
The first failure was the same `Start-LegacyHostUseLeaseProcess` Win32
file-not-found error at process start. The attempt stopped immediately; no
second correction, semantic repair, production change, or further test was
performed.

Final three-path scoped diff check, exactly once:

`git diff --check -- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1 com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

Exit: `0`; wall time: `197 ms`.

Budget: static/source `1/1`; consolidated focused L0 initial `1/1`; same-cause
mechanical fixture correction `1/1`; corrected L0 attempt `1/1`; semantic
correction `0`; final scoped diff check `1/1`. No extra suite, full regression,
Unity, Unity MCP, CUA, BatchMode, runtime/process probe, C# L1, EditMode,
publication, commit, push, or Verifier action was run.

The bounded runtime reached the corrected availability-authority portion, but
the consolidated `UpgradeOnly` L0 did not pass because the existing
fixture-owned lease-holder could not start. This snapshot is not
`HUMAN_PHASE_A_RETRY_READY` and must not be routed to Unity or Verifier as
passing evidence.

### Completion routing

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `BLOCKED / FOCUSED_L0_LEASE_HOLDER_START_FAILURE`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: Planner reviews the unchanged production identities, corrected
availability-authority fixture, and exhausted same-cause mechanical attempt,
then decides whether to authorize a new bounded lease-holder harness
investigation/evidence attempt. Do not route Phase A or Verifier on this
snapshot.

Human decision or authorization required: any further fixture investigation or
correction, additional focused evidence, renewed Phase A Unity scenario,
publication, Verifier routing, commit, or push.

## S18 Lease-holder Harness Evidence Unblock (COMPLETE)

Execution date: `2026-09-15`. This bounded continuation preserved the prior
fixture `WorkingDirectory` correction and changed only
`com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`. The
production engine and materializer remained frozen.

### Harness correction and final identity

The lease-holder fixture now resolves Node with:

`$nodeSelection = @(Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1)`

It requires exactly one selected command, materializes `.Source` as a scalar
string, and verifies that path with `File.Exists` before process start. No
machine-specific path was added or logged. Existing holder lease, lifetime,
shutdown, and availability-authority semantics remained unchanged.

- Branch: `codex/v0.3.0-legacy-workflow`.
- HEAD: `eb21a7a5d28548e0369db35ee0cac1c0d626183c`.
- Engine blob identity:
  `725902bdfdbeaaa5198b1268b7339b1823eea404` (frozen match).
- Materializer blob identity:
  `89410db933769ccfe1f000d01da2b77288c30ecf` (frozen match).
- Harness blob identity:
  `2ec87f16acf21a6c8bbe12abfd3fd7cd828acc03`.

### Evidence and budget ledger

The single bounded static/source batch had already completed before the
runtime attempt. Exit: `0`; wall time: `1232 ms`. Harness AST parsing, scalar
Node selection and file validation, holder lifetime/shutdown markers,
availability-authority assertions, and both frozen production identities all
passed. Static/source budget: `1/1` (exhausted).

Consolidated focused L0, exactly once with no retry:

`powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -UpgradeOnly`

Exit: `0`; tool-observed cumulative same-session wall time: approximately
`91017 ms` (`31.0 s + 30.0128531 s + 30.0036651 s + 0.0000018 s`). Concise
output:

- `[OK] Real v0.2.4 flat/runtime state converged through an isolated poc.35 instance; candidate and activation failures retained the old selection, live/unknown owners were never stopped, and retirement completed idempotently after drain.`
- `[OK] Exact Package-declared immutable instances hand off automatically, retain live owners, drain idempotently, and reject undeclared identities before activation.`
- `[OK] Focused prior-generation Upgrade scenarios passed.`

Final three-path scoped diff check, exactly once:

`git diff --check -- com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1 com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

Exit: `0`; wall time: `308 ms`; output: none.

The bounded final identity observation reported the branch and HEAD above.
`Get-FileHash -Algorithm SHA1` over only the same three paths exited `0` in
`422 ms`; raw file SHA-1 values were `65feff6e98ef7bf23765b8a03cb05d5919e70077`,
`1534b5a1e04f784fccef7756644514fdb1c2411c`, and
`a3b2f088b78af54aecd5fb7dfca03aa2bb2f74ca`, respectively. The subsequent
three-path `git hash-object` observation exited `0` in `274 ms` and produced
the blob identities recorded above. No broad identity or diff scan was run.

Budget: static/source `1/1`; focused `UpgradeOnly` L0 `1/1`; retry `0/0`;
final scoped diff check `1/1`. No other suite, full regression, Unity, Unity
MCP, CUA, BatchMode, C# L1, EditMode, protected runtime/process probe,
production edit, publication, commit, push, or Verifier action was performed.

The focused L0 now passes on the frozen production snapshot. This bounded
route is complete and the snapshot is ready for Planner review before any
human Phase A retry.

### Completion routing

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `COMPLETE / HUMAN_PHASE_A_RETRY_READY`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: Planner reviews the frozen production identities, bounded harness
correction, passing focused L0, and final scoped diff evidence, then decides
whether to authorize the human Phase A retry.

Human decision or authorization required: renewed Phase A Unity scenario,
Verifier routing, publication, commit, or push.

## S18 Phase A Human Evidence And Identity Diagnostic (FAIL / INSUFFICIENT)

Execution date: `2026-09-15`. This entry records the one continuous
human-operated Phase A scenario authorized after the focused `UpgradeOnly`
closure. The Coder did not launch, connect to, inspect, or terminate Unity or
any process. No protected validation-project runtime was read. Production and
test files remained unchanged by this continuation.

### Human evidence

- The human opened `UnityValidationProject`, compilation completed with zero
  current C# errors, and no abnormal condition was observed.
- With Manager closed, entering Play and returning to Edit Mode were both
  prompt and showed no error.
- In Edit Mode, the human opened CodeDB Manager. `Checking` stopped and the
  window reached a stable terminal state.
- The terminal state was not `Ready`: the header showed
  `UnityValidationProject - Needs attention`; the summary said CodeDB could
  not safely identify its control state; and `Control contract migration`
  showed `Error / Review required` with the visible diagnostic
  `Supervisor PID is live, but its start or executable identity does not match.`
- Host payload, Current instance, Coordinator startup, Host generation,
  Provider executable, Project MCP config, and MCP availability remained
  `Not evaluated` or `Inactive` behind that admission failure.
- Switching Manager tabs did not trigger another `Checking` transition.
- The human closed Manager and then closed Unity normally. Manager did not
  reproduce the prior shutdown obstruction. Shutdown duration was not measured
  precisely and is deliberately not represented as `<30s`.

Screenshot evidence is referenced only by sanitized metadata:
`codex-clipboard-56f0c468-4cf8-4bd3-ad84-a3d77843f59e.png`, `1466x871`,
`127676 bytes`, SHA-256
`4c4ca9fb5f0b5ad42bdf3069518532f338f005b424f3a53192aa8b01eb6d7105`.
No temporary absolute path is recorded.

Phase A result: `FAIL / CONTROL_CONTRACT_IDENTITY_ADMISSION`. The passing
human observations for compile, Play/Edit, Manager cache/tab interaction, and
normal shutdown do not override this control-state gate failure.

### Targeted source classification

The visible diagnostic is emitted by
`AICodedbControlContractMigrationStore.ValidateProcessIdentity` in
`com.rice.ai-codedb/Editor/AICodedbControlContract.cs`. It is reached only
after the current namespace has both state and lock evidence, those documents
identify the same owner, current Package/selection evidence validates, the
recorded PID resolves to a process that has not exited, and its StartTime and
MainModule path are readable. The throw at lines 883-889 means at least one of
these comparisons failed:

- persisted `process_start_identity` versus
  `Process.StartTime.ToUniversalTime().Ticks`, canonicalized to 10-tick
  (microsecond) granularity; or
- persisted `executable_path` versus `Process.MainModule.FileName` under the
  existing path comparator.

The diagnostic intentionally combines those two comparisons and contains no
field-level result. It therefore does not prove whether the live PID is a
reused/stale owner, the same owner represented inconsistently, or a different
live owner.

There is a concrete source-backed capture/normalization defect candidate in
`com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`:

- the preferred WMIC branch reads DMTF `CreationDate` and
  `normalizeStartIdentity` merely removes non-digits (lines 2354-2394);
- the CIM fallback publishes UTC `.Ticks` (lines 2306-2315); and
- the C# classifier requires the UTC-ticks representation (lines 879-889).

Consequently, when the persisted owner evidence came from the WMIC branch,
its start identity is not the same representation required by C#. This is a
strong explanation for the observed failure, but the supplied screenshot does
not reveal whether WMIC or CIM produced the persisted value, whether the start
comparison or executable comparison failed, or whether the PID was reused.

The nearest tests do not close that distinction. The Node Supervisor fixture
covers proven-dead takeover and live PID-reuse fail-closed behavior, but it
compares evidence through the Node implementation itself. The C# migration
classifier fixture uses a synthetic non-existent PID for current evidence and
therefore exercises the compatible-stale path rather than a live
Node-published WMIC-to-C# identity comparison. No direct test found in the
bounded closure proves the cross-language Windows start-identity format.

Root-cause classification:
`DIAGNOSTIC_EVIDENCE_INSUFFICIENT`. The current evidence cannot safely select
exactly one of `STALE/PID_REUSE_EVIDENCE`,
`START_OR_EXECUTABLE_IDENTITY_CAPTURE_NORMALIZATION_DEFECT`, or
`REAL_OWNER_CONFLICT/AMBIGUOUS_EVIDENCE`. No repair is authorized or justified
from this combined diagnostic alone.

### Minimal impact and proposed next route

If one sanitized discriminator confirms a WMIC-format persisted start identity
with executable equality, the coherent repair fits the existing conditional
allowlist:

- production: `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`;
- direct Node regression: `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`;
- direct C# cross-contract regression, if needed:
  `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`.

That route would make every Windows capture branch publish the same
microsecond-granularity UTC-ticks string already required by C#, without
weakening PID reuse, owner conflict, state/lock equality, executable identity,
or authenticated-pipe gates. These three paths are inside S18's conditional
allowlist. No source edit was made in this diagnostic pass.

The minimum separate evidence authorization is one evidence-only, read-only,
single-snapshot discriminator after the human has closed Unity. It should read
only the current Supervisor state/lock owner identity fields already consumed
by the product and the corresponding OS process StartTime/MainModule identity,
then emit only sanitized facts:

- state/lock owner fingerprint equality;
- recorded PID exists and is live;
- persisted start-identity kind (`DOTNET_TICKS`, `DMTF_DIGITS`, or `OTHER`);
- `start_identity_match` boolean using the exact C# 10-tick rule; and
- `executable_path_match` boolean using the existing path comparator.

It must not emit PID, raw paths, command line, argv, tokens, or runtime
documents; it must not mutate files or stop/start a process. This is sufficient
to choose the next route without another Unity scenario. If such a bounded
discriminator is not authorized, the gate remains blocked and no repair should
be guessed.

### Evidence boundary and completion routing

No Phase A retry, L0/L1/EditMode test, static batch, diff check, identity
command, Unity/Unity MCP/CUA action, protected runtime read, process probe,
cleanup, source/test modification, commit, push, publication, or Verifier
contact was performed in this continuation. Only direct source/test reads and
this append-only result update were performed.

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`

Current status: `BLOCKED / PHASE_A_FAIL / CONTROL_CONTRACT_IDENTITY_ADMISSION / DIAGNOSTIC_EVIDENCE_INSUFFICIENT`

Next notification: `UnityCodeDB v0.3 Planner`

Next action: Planner reviews the Phase A gate failure and source-backed format
candidate, then decides whether to authorize the one-shot sanitized identity
discriminator described above. Do not route Phase A, publication, or Verifier
from this snapshot.

Human decision or authorization required: the evidence-only discriminator;
any subsequent bounded repair and focused evidence; a renewed Phase A Unity
scenario; Verifier routing; publication; commit; or push.

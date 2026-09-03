# Result: cdb-v0.3-p0-s03-migration-state-routing

## Status

- Result: COMPLETE
- Requested execution profile: `v0.3.coder.deep`
- Actual agent identity exposed to this session: GPT-5-based Codex coding agent
- Actual reasoning: deep task execution; no separate runtime effort identifier was exposed
- Snapshot HEAD: `cd1ec021179b3c36312774d282dae17652c4d832`
- Commit/push: not performed

## Bounded preflight

- Working directory: `G:\RiceProgram\UnityCodeDB`
- `HEAD` exactly matched the frozen snapshot.
- Tracked working tree was clean before implementation.
- The only pre-existing untracked file was this task's `TASK.md`.
- `AICodedbControlContract.cs` and project runtime state remained read-only.

## Changed files

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`

No file outside the task allowlist was modified.

## Implementation

- The background reconcile worker reads
  `AICodedbControlContractMigrationStore.Read(...)` at
  `AICodedbEditorLifecycle.cs:560` and resolves migration admission at line
  564. The first start/mutation-capable Supervisor command in that worker is
  the existing automatic uninstall-cleanup command at line 595, after the
  admission gate.
- Automatic Supervisor reconnect starts fail-closed. Each reconcile epoch
  resets admission before worker dispatch, and `QueueSupervisorReconnect`
  checks the cached admission at line 1158. Only `Missing`, `Current`, and
  `CompatibleStale` enable it.
- `ObsoleteReinstallRequired` and `InvalidOrAmbiguous` return before any
  Supervisor command. Both map to a cached product status; the former carries
  `ControlContractReinstallRequired`, while the latter carries
  `ControlContractInvalidOrAmbiguous`.
- A previously cached `MissingPrerequisite` remains the product/UI state for
  either blocked migration classification. The migration reason and diagnostic
  remain cached, but `RequiresReinstall` stays false while prerequisite
  presentation has precedence.
- `AICodedbProductStatus` now carries the stable attention reason plus the
  classifier's `Detail` and `DiagnosticDetail`. No legacy evidence parsing or
  contract validation was duplicated.
- Manager consumes the lifecycle product-status cache through
  `TryGetCachedLifecycleStatus` and `CreateCachedStatus`. The Manager and
  status snapshot contain no classifier invocation. Generic or ambiguous
  `NeedsAttention` no longer displays or invokes Reinstall; only the explicit
  obsolete reason enables `Reinstall CodeDB`.
- Cached migration detail is shown in the Overview diagnostics row. All open,
  repaint, and draw paths remain cache-only.

## Focused evidence

- Source tests cover all five classifier states, both blocked-state reasons,
  missing-prerequisite precedence, cached diagnostic presentation, and the
  Reinstall action decision.
- The PowerShell source boundary asserts classifier-read/admission ordering
  before the first worker Supervisor command, automatic reconnect admission,
  and the absence of classifier calls from Manager.
- `git diff --check`: PASS.
- Protected classifier diff check:
  `AICodedbControlContract.cs: unchanged`.
- One read-only evidence-location command initially failed because PowerShell
  interpreted the unescaped regex alternation as a command. Original error:
  `The term 'Probe' is not recognized as a name of a cmdlet, function, script
  file, or executable program.` One corrected read-only `rg` invocation
  succeeded. This was not a test batch and did not modify the workspace.

## Test batches and limits

- L0 batch count: 1 of 1 allowed.
- L0 command:

      powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1

- L0 result: PASS.

      [OK] Standalone CodeDB package boundary passed.

- L0 retries: 0.
- Affected L1 batch count: 0. The lifecycle and Manager Editor fixtures were
  updated as required source coverage; execution remains DEFERRED because
  Unity EditMode authorization is `NOT_REQUESTED`.
- Unchanged Supervisor Node L0 was not run.
- Unity, Unity MCP, EditMode, full Editor/full repository regression,
  cold-start/Play, real Codex, consumer/third-party Package, and release
  acceptance were not run.

## Deferred risks and boundaries

- C# compilation and runtime behavior remain DEFERRED until a separately
  authorized Unity EditMode run.
- No runtime acceptance exists yet for domain reload, cold start, or a real
  obsolete/ambiguous project state.
- Missing-prerequisite precedence relies on the lifecycle's previously cached
  product state; machine prerequisite transition behavior remains part of the
  deferred Editor runtime verification.
- Reinstall execution, candidate provisioning, activation, rollback,
  retirement, cleanup, deletion, quarantine, process stopping, Node/PowerShell
  policy, and immutable-generation behavior were not changed or tested.
- No commit or push was performed, and Verifier was not directly dispatched.

## Completion Routing

Current task: cdb-v0.3-p0-s03-migration-state-routing
Current status: COMPLETE
Next notification: UnityCodeDB v0.3 Planner
Next action: review this RESULT.md and route the frozen uncommitted snapshot to Verifier for targeted read-only verification
Human decision or authorization required: Planner review and routing; Unity/EditMode, commit, push, and release acceptance remain separately gated

## Bounded FIX 01 - Planner Finding

### Status

- Repair result: BLOCKED
- Finding disposition: CONFIRMED
- Existing snapshot preserved: all 7 allowlist code/test changes remain
  uncommitted and unchanged by this repair attempt.
- Actual repair change: this appended `RESULT.md` record only. No production
  or test source was modified.

### Blocker evidence

- `AICodedbProjectIntegrationStateStore.Read(...)` provides current read-only
  integration evidence, so the `Uninstalled` precedence can be identified
  without starting a Supervisor.
- No allowlist API provides an authoritative current prerequisite
  `Missing`/`Current` classification without starting an external process.
- `AICodedbHostPayloadMaterializer.ReadStatus/Probe` reaches
  `AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScript(...)`
  or its async equivalent at
  `AICodedbHostPayloadMaterializer.cs:45,330,337,381`.
- The lifecycle-only alternative,
  `CaptureMachinePrerequisiteEvidenceFingerprint(...)` at
  `AICodedbEditorLifecycle.cs:2257`, hashes PATH strings and Provider file
  evidence. It detects change but does not validate Node version, Provider
  manifest identity, executable hash, or produce a current prerequisite
  state.
- `_leasePrerequisiteCurrent` and `previousProductState` are presentation or
  prior-observation caches. Treating their cold-start `false`/`Starting` values
  as current missing evidence would guess; treating them as current would miss
  the required cold-start precedence.
- Implementing a second C# prerequisite validator would duplicate the existing
  Node/Provider/PowerShell policy and expand this task into a new authority.
  Calling the materializer would start an external PowerShell process. Both
  violate the frozen FIX conditions.

Consequently, the two required installed combinations cannot both be mapped
correctly from current evidence inside the present boundary:

- current prerequisite missing + obsolete/ambiguous must remain
  `MissingPrerequisite`;
- current prerequisite satisfied + obsolete/ambiguous must become the blocked
  migration `NeedsAttention` result.

The existing helper still uses
`previousProductState == MissingPrerequisite` at
`AICodedbEditorLifecycle.cs:713`; changing only the integration ordering would
fix `Uninstalled` but leave the cold-start prerequisite defect unresolved, so
no partial code change was made.

### Verification boundary

- One related static source check was performed. It confirmed the current
  integration read, external-process materializer route, fingerprint-only
  helper, and cache-based precedence branch.
- One targeted `git diff --check` was performed against the 7 existing
  allowlist changes: PASS.
- FIX L0 batch count: 0. The original task already consumed its 1 allowed L0
  batch; it was not rerun.
- Affected L1 batch count remains 0, DEFERRED. Unity EditMode authorization is
  still `NOT_REQUESTED`.
- Unity, Unity MCP, Supervisor/Package L0, Node tests, external prerequisite
  probes, full regression, commit, and push were not run.
- `AICodedbControlContract.cs`, runtime evidence, editor leases, external
  processes, and global configuration were not modified.

### Remaining risk

- The confirmed cold-start defect remains in the current uncommitted snapshot:
  missing prerequisites can be hidden by blocked migration and incorrectly
  expose Reinstall.
- Blocked migration can still hide current `Uninstalled` presentation because
  classifier admission currently precedes the integration-state read.
- Verifier should not receive this snapshot as a completed repair until Planner
  resolves the missing prerequisite-evidence authority.

## FIX Completion Routing

Current task: cdb-v0.3-p0-s03-migration-state-routing
Current status: BLOCKED
Next notification: UnityCodeDB v0.3 Planner
Next action: decide whether to provide or authorize an authoritative no-process current prerequisite status inside the frozen boundary, or revise the task boundary before another bounded repair
Human decision or authorization required: prerequisite evidence authority/boundary decision; Unity/EditMode, external-process probing, commit, push, and Verifier routing remain separately gated

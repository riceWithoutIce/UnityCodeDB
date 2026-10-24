# S29 historical handoff capability — delivery preparation

Date: 2026-10-13.
Owner: Planner. Status: SOURCE_ACCEPTED_WITH_LIMITS / DELIVERY_PREPARATION.

## Frozen state

User source ACCEPT remains recorded and attributable. This preparation does
not rewrite the Coder result or independent Verifier report. All five live
source hashes match HISTORICAL-HANDOFF-CAPABILITY-SOURCE-SHA256.txt; HEAD is
9eac17cfdb741f89d33a4b7c2ddf6261abcb9566 and the ordinary index is empty.
The scoped diff remains five files, 50 insertions / 35 deletions.
S29 still references s29-upgrade-callsite-fix-34b3a65. No new commit, export,
reference switch, Unity run, live command or actual removal was performed.

## BLOCKER HH-01: removal-only branch follows prerequisite admission returns

This is a deterministic source call-chain finding in the changed normal route,
not a claimed Unity reproduction or a new whole-product audit.

Counterexample: valid Installed integration, authenticated TrustedPrevious
selection, usable control migration, current prerequisite evidence, no published
Editor lease, no cancellation, and an active worker context.

1. RunReconcileWorker reads that selection at
   Editor/AICodedbEditorLifecycle.cs:974. At :1002, absence of a published lease
   selects the independent prerequisite path.
2. TryRefreshEditorLeaseForAdmission (:3974) calls
   ClassifyEditorLeasePublication (:4018). The accepted
   AICodedbProjectIntegrationState.cs:281 change makes CanPublishEditorLease
   false for TrustedPrevious. Classification returns CurrentInstanceIneligible
   at lifecycle :4045; the helper deletes any tracked lease and returns it.
3. ShouldAttemptCoordinatorAdmission (:3737) consequently returns false.
   ShouldContinueInstanceBootstrapWithoutCoordinator (:3746) also returns false
   because only CurrentInstanceMissing is admitted. A usable control migration
   does not intercept the route (TryResolveControlContractMigrationBlock :1719).
4. The :1211 guard therefore returns at :1242 with NeedsAttention,
   AttentionReason.None, and the default RemovalPreflightPassed=false.
   It never invokes WithRemovalPreflight for this selection.
5. The newly accepted TrustedPrevious branch and its authenticated removal
   preflight begin only at :1332. They cannot handle this ordinary cold-start
   case. Repeated reconciliation without a lease follows the same return.

There is a second adjacent ordering gap: with an existing tracked lease and
force=false / recoveredControlAuthentication=false, BackendNeedsReconcile
returns false for TrustedPrevious (:2184), so :1249 returns before :1332.
The automatic-start flag is set to 1 at :1248 on that path. This is source
ordering evidence; no actual Coordinator start is asserted.

Impact: automatic Upgrade refusal is present, but the approved controlled
removal/reinstall presentation is not reachable on the above normal path.
The late branch also cannot establish the promised before-admission boundary
for all initial/repeated/existing-lease cases. This blocks this slice's stated
delivery outcome, independently of the deferred RequireReady wording FOLLOW-UP.

## Evidence limits

The Coder records PowerShell parser PASS and Roslyn semantic errors=0.
Both declared L1 attempts are explicitly NOT PASS: the standalone runner hit
RetainedDispositionOnly and GenerationAlignmentOnly hit fixture binding.
The result does not identify exact raw compile/test commands or log paths.
The named task artifact root currently contains only an empty fixture directory;
this does not prove that evidence is absent elsewhere. PathProvenanceOnly has
no recorded result. No unchanged test was rerun during this preparation.
Neither helper assertions nor snapshot-hash PASS demonstrate worker ordering.
Initial combined instruction/status reads were truncated and narrowed to the
required task records and direct symbols; no output-budget compliance is claimed.

## Concrete bounded FIX — authorized

User replied `同意 fix` to this proposal. The task's HH-01 amendment records
the approved repair/evidence scope and reuse of stopped Coder then Verifier.
Delivery remains on hold while that correction and targeted review run.

Outcome remains A: authenticated previous-v2 is historical/removal-only.
Keep the accepted five-file snapshot as the baseline and preserve all existing
strict backend authorization, current/missing routes and protected bytes.

- Repair the ordering in Editor/AICodedbEditorLifecycle.cs so the previous-v2
  removal-only disposition is reached before operational lease admission,
  automatic-start enablement, Supervisor Probe/start and no-reconcile returns.
  Preserve valid integration, migration/authentication, prerequisite and
  cancellation handling; missing/untrusted evidence must not fabricate removal
  permission or Ready. Do not make ineligible instances bootstrap-eligible.
- Add only direct regression coverage in
  Tests/Editor/AICodedbEditorLifecycleTests.cs for cold start/repeated reconcile,
  existing lease, and authenticated removal preflight PASS/refusal. Prove the
  actual routing entry or a directly consumed production routing seam, rather
  than only independent classifier values.
- Use the already allowlisted Tests~/test-codedb-host-payload-materializer.ps1
  only if a fixture-binding correction is required to execute the existing
  changed Probe producer/real C# reader scenario. No production writer/schema
  or generic Upgrade/removal authorization changes are permitted.
- Close the original declared focused L0/affected L1 evidence, including
  PathProvenanceOnly, with commands, log locations, snapshot bindings and
  explicit seams. Use a new test-owned overlay of the immutable accepted
  Package; do not consume dirty worktree Payload or alter frozen artifacts.
  Initial plus at most two causally corrected semantic attempts per declared
  scenario; record previously consumed attempts before starting. No full suite.
- Reuse the stopped task Coder, then the stopped read-only Verifier, only after
  user FIX disposition. Parent stays active through terminal completion and
  returns findings together. Review HH-01 and its nearest regressions only.
  Source ACCEPT is requested again if bytes change.

No actual Remove/Install/Upgrade, Unity/MCP/BatchMode/CUA, process control,
cleanup, commit, export, reference switch, push or publication is included.
RequireReady wording, selected-v2 automatic Upgrade capability, CleanupMono
and unrelated historical cleanup remain deferred.

## Handoff

Current status: all authorized source/evidence corrections and review complete.
Next notification: User, concrete named delivery proposal.
Next action: prepare commit/export/reference-switch proposal; do not execute.
Human decision required: grouped authorization for named delivery actions.
After a stable accepted correction, prepare commit -> exact export -> S29
reference switch as a separate concrete grouped delivery proposal.
S29/release remain PARTIAL.

## HH-01 terminal update and next concrete proposal

Coder and Verifier have both stopped. The designated
HISTORICAL-HANDOFF-CAPABILITY-VERIFICATION.md closes HH-01 at source level,
but reports BLOCKED / REQUIRED_EVIDENCE_UNMET. Original acceptance remains
historical; no new source ACCEPT is claimed. Terminal five-file hashes match
SOURCE-SHA256. Parent compared S29 manifest/lock and desired/current/activation/
operation (six exact files) to this FIX's entry baseline: all match.

E-01: full original-byte Unity csc/Bee compilation and permitted exact-AST
focused execution were not run. Old NativeBoundaryRewrite runs are invalid
for this envelope; original plus two corrected C# executions exhausted budget.
The first raw log was overwritten and historical generated harness outputs
changed. The old Runner text was restored, but this does not recover those
outputs or justify blanket historical-artifact preservation. See RESULT for
the exact command/error record. This is our execution deviation, not a
production defect or a Unity failure.

E-02: the owned PowerShell fixture omitted the upstream prerequisite marker
after setting MachinePrerequisiteStatus. The production writer correctly
avoids duplicate emission; the real reader consequently receives Unknown.
The focused producer-to-reader check is NOT PASS; no parser change is justified.

E-03: the frozen baseline test
Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs:43 contains
a machine-bound G:/fixture/project literal. PathProvenanceOnly failed and was
not bypassed. The file is outside the existing correction allowlist.

Recommended pending authorization: one bounded evidence-completion envelope,
without further production changes or delivery actions:

1. Correct only the HistoricalProbeOnly fixture in
   Tests~/test-codedb-host-payload-materializer.ps1 so its emitted input carries
   the existing upstream prerequisite output as well as the unchanged real
   production writer output. Do not fabricate reader state or change assertions.
2. Extend the test allowlist by only
   Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs. Replace
   its fixed fixture path with a path supplied by the existing test workspace
   owner at runtime; preserve its missing-handoff refusal assertion. Cover only
   this existing test and the focused path-provenance gate, not a full suite.
3. Create a new exclusive immutable-Package overlay and new per-attempt log
   paths; leave old/frozen artifacts intact. Compile original complete Editor
   and directly affected test bytes with existing Unity csc/Bee tooling, without
   launching Unity. Run the already authored HH-01 focused batch through the
   permitted same-body exact-AST seam adaptation, with original methods and
   assertions preserved and explicit Unity/native/Provider exclusions. If that
   boundary cannot execute, report the concrete prerequisite without substitution.
4. Renew each directly coupled focused evidence scenario to one initial attempt
   plus at most two causally corrected attempts. Preserve the exhausted previous
   ledger; this is a requested extension, not a retroactive budget reset. Include
   syntax, complete original-byte compile, HH-01 seam and producer-to-real-reader,
   changed preflight-argument test and PathProvenanceOnly only. Freeze exact inputs,
   methods/commands and binding before execution. No unchanged failing replay.
5. Reuse stopped Coder then read-only Verifier for E-01/E-02/E-03 and their
   immediate regressions only. Parent monitors terminal completion. Return the
   consolidated result for source ACCEPT; do not automatically enter delivery.

This proposal was AUTHORIZED by the user's `同意` reply and is now complete.
It renewed only the
declared evidence budget and adds the named preflight test file to the temporary
evidence allowlist. No production source change is authorized by this grant.
No Unity,
MCP/CUA/BatchMode, real actions/process control/cleanup, commit/export/reference
switch, push or publication is included. HH-01 production correction remains
frozen; RequireReady wording and CleanupMono remain deferred.

## Terminal review disposition — 2026-10-13

Both child roles completed. HH-01 source is CLOSED; E-01/E-02 are CLOSED WITH
LIMITS: original-byte compilation, exact text binding, 22 seam cases, and real
reader consumption passed. E-03 remains BLOCKED at the correct overlay's
unchanged Tests/Editor/AICodedbManagerUiTests.cs:1845 G:/RiceProject/Retained
literal and adjacent fixed literals. The newly workspace-bound preflight test
compiled but was not run because Unity main-thread execution remains human-owned.
Overall PACKAGE_PATH_GATE_NOT_PASS. No new source ACCEPT is claimed.

Recommended next disposition: authorize only the method
RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot in
Tests/Editor/AICodedbManagerUiTests.cs. Derive its base path and comparison
variants from runtime test-owned context, retaining same-root/case/separator
acceptance and relative/different-root/malformed rejection. Do not weaken the
production comparator or path gate. Evidence scope: this pure comparator test,
PathProvenanceOnly, and affected original-byte test compilation only; no full
suite or replay of the unchanged HH-01 22 cases. Use a new immutable overlay,
initial plus at most two causally corrected attempts and distinct logs; reuse
Coder then targeted read-only Verifier with parent terminal monitoring. The
preflight owner's actual Unity execution remains in the later human checklist.
This recommendation was AUTHORIZED by the user's `同意批准` reply. It adds
only Tests/Editor/AICodedbManagerUiTests.cs to the temporary evidence/source
allowlist for this pure comparator-path repair. Production code and all HH-01
accepted bytes remain frozen; commit/export/reference switch remain separate.

## Current terminal outcome — 2026-10-13

E-04 was separately authorized by the user's `同意` reply and completed by
Coder then targeted read-only Verifier. Only the two fixed invalid-input
samples in Tests~/test-codedb-retained-entry-routing.ps1 were changed to use
the owned fixtureContainer. Rejection assertions and the production comparator
remain unchanged. Correct immutable-overlay PathProvenanceOnly exit 0/PASS;
affected complete original-byte Tests compile exit 0/errors 0. HH-01 was not
rerun and no production logic was changed during E-04. Designated Verifier
closes E-03/E-04 and returns no new finding. Eight current source hashes match
the latest SOURCE-SHA256 record; HEAD/index remain unchanged.

Current evidence disposition: PACKAGE_PATH_GATE_PASS / HUMAN_UNITY_PENDING.
User replied `同意 accept`; source is now accepted with these limits. The
workspace-owned comparator/preflight methods still require real human Unity
execution; pure-seam results are not native lifecycle/lease/Provider proof.
RequireReady wording, CleanupMono and historical failed-run integrity limits
remain explicit. Do not replay tests or begin commit/export/reference switching
until the appropriate grouped delivery authorization. No delivery action occurred.

## Proposed delivery group — pending authorization

The accepted source snapshot consists of these eight Package paths:

- `Editor/AICodedbProjectIntegrationState.cs`
- `Editor/AICodedbEditorLifecycle.cs`
- `Tools~/codedb-instance-engine.ps1`
- `Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `Tests~/test-codedb-host-payload-materializer.ps1`
- `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs`
- `Tests/Editor/AICodedbManagerUiTests.cs`
- `Tests~/test-codedb-retained-entry-routing.ps1`

The proposed bounded group is:

1. Recheck the eight hashes, scoped diff/whitespace, empty staged index, no
   matching S29 Unity process, and recorded protected S29 reference/runtime
   files. Create one local source commit containing exactly these eight Package
   paths. No task-document bulk staging, Payload regeneration, push or publish.
2. Run `Tests~/export-codedb-package.ps1` once from that exact commit into a
   new repository-local root `.artifacts/s29-historical-handoff-<shortsha>`.
   Require commit-stage and exact-extraction byte closure, production payload
   admission, native VerifyOnly and Package PathProvenance PASS. Preserve prior
   artifacts; do not export from the dirty worktree.
3. Compare the new extraction against the prior 617-file Package baseline:
   only the eight accepted source/test paths may differ; Payload/generation
   identity and all other entries must remain byte-identical. Record ZIP hash,
   inventory, byte counts and source-to-artifact hashes.
4. After a fresh no-S29-process and reference-preimage check, back up only
   `UnityFreshInstallValidationProjectS29/Packages/manifest.json` and
   `packages-lock.json` under a new `.backups/s29-historical-handoff-<shortsha>`
   root. Switch both references to the new exact extraction, then verify JSON
   parsing, one replacement per file, backup equivalence and unchanged protected
   runtime state. This is the only project mutation in the group.
5. Prepare the exact-package human checklist for compilation, focused Editor
   tests, Manager close/reopen and tab switching, historical removal-only
   display/preflight behavior, and normal Unity close. Human Unity owns the run;
   no automated Unity substitute.

Approval applies only to this named commit/export/reference-switch group. It
does not authorize real Remove/Install/Upgrade/Uninstall, process termination,
history cleanup, Unity automation, push, publication or release acceptance.
The human Unity gate remains separate after the reference switch.

## Delivery completion — 2026-10-13

The approved commit -> exact export -> reference-switch group is complete.
Source commit is `04e9a6bd49ae46f5c10989f6e4c6efddc479ad24`; exact ZIP SHA256 is
`d76c5a2cec01323c6bd220564a78dee2a75d67e0da6dccd2aa74d8015d4ea681` with
617 entries. Package closure and production admission passed, and the two S29
Package references now point to the new extraction after verified backups and
JSON checks. No Unity process was started. See the delivery result and human
checklist in this task directory.

Status: REFERENCE_SWITCH_COMPLETE / HUMAN_UNITY_PENDING. S29/release remain
PARTIAL until the human reports the exact-package Unity gate.

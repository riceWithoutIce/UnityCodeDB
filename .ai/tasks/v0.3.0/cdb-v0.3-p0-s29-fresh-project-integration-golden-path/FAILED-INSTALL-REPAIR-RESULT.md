# S29 Failed Install Repair - Partial Coder Result

Status: PARTIAL / OUTPUT_BUDGET_EXCEEDED / NO_PRODUCT_MUTATION.
Date: 2026-10-07.
Base and final HEAD: 13bf5fd16c15c42e1379ce35a06e49c20753195f.

The coherent source repair is NOT IMPLEMENTED. No product/test file was edited,
no focused family was run, and no C# tests were authored. This is a terminal
partial handoff, not a source PASS or a stable implementation for Verifier.

## Reason for stop

Source discovery exceeded the packet's cumulative 128 KiB output budget through
oversized source slices and an inefficient raw baseline capture. The baseline
tool returned 63,939 bytes, even though it was stored rather than printed in the
outer tool output. Exact cumulative byte accounting was not collected, so no
claim of budget compliance is made. One source read was truncated and was not
accepted as complete evidence. A later metadata-check command hit Windows
command-length rejection before process creation; it was replaced with a compact
read-only hash comparison. No unchanged test rerun occurred.

The Coder reported this process failure and stopped exploration before any
product mutation. Planner requested this terminal partial handoff; any bounded
continuation is a separate parent-owned disposition under the user's standing
authorization. There is no demonstrated structural contradiction to the frozen
consumer map.

## Useful bounded source observations

- Direct BuildRuntimeScriptArguments currently forwards editor lease identity
  without originating action/operation IDs.
- Both Install action entry points currently request lifecycle reconciliation
  after any returned result. Existing Manager action session policy requires
  authoritative success and no retained admission.
- Assert-InstanceNextChangeAdmission currently binds a retained removal intent
  only for UNINSTALLED/PENDING. A failed-preparation intent must remain admitted
  after fresh Install and through later ordinary cleanup.
- Get-InstanceCleanupState already retains every instance bound by a removal
  intent. This does not by itself make PROVISIONING acceptable to admission.
- Get-ValidatedRetiredInstance has an AllowProvisioning switch and uses the
  existing origin and generation closure readers. A dedicated bounded effect
  classifier is still required before invoking it on failed preparation.
- Get-CurrentProjectRemovalAuthority currently requires selected and COMMITTED
  activation evidence. Get-InstanceRemovalIntent currently accepts schema v1
  only. Neither was changed.

The parent clarified the identity interpretation within the existing packet:
preserve the real Manager action across pre-admission Supervisor fallback.
When the Supervisor never admitted an operation, mint the direct operation
exactly once before direct receipt hashing; do not fabricate or reuse an
unadmitted server operation. This requires no new protocol field.

## Evidence and preservation

The 10 allowlisted product/test files were initially clean and are still raw
byte-identical. All 358 tracked generation files in the recorded generation
scope are byte-identical. HEAD and the index SHA256 are unchanged. The product
binary patch is empty. Exact hashes and generation digest are in
FAILED-INSTALL-REPAIR-IDENTITY.txt.

This Coder wrote only this result and its identity record. Unrelated dirty
content was not written; protected real project/candidate/receipt bytes were
not inspected or hashed. The parent-owned contract amendment is excluded from
the unrelated-byte preservation assertion. No Unity, MCP, service, external
process observation, real Install, cleanup, commit, push, export or generation
execution was performed.

Syntax/static/diff batch: NOT RUN.
Focused FailedPreparationRecoveryOnly family: NOT IMPLEMENTED / NOT RUN.
Causal test corrections used: 0.
Unity compile/EditMode/runtime/consumer/device/release acceptance: NOT RUN.
F-IMC-01 / P3 remains DEFERRED.

## Handoff

Next implementation remains exactly the approved packet: direct identity,
authoritative-success reconcile gate, FAILED_PREPARATION classifier and schema
v2, all actual removal-intent consumers, transaction/removal/fresh-Install
integration, retained PENDING closure after subsequent operations, and focused
production-boundary tests. Do not treat these observations as completed repairs.

## Continuation 01 - Stable partial implementation

Status: PARTIAL / FRESH_INSTALL_NOT_PROVEN / TEST_CORRECTION_BUDGET_EXHAUSTED.
Stable snapshot UTC: 2026-10-07T13:49:23.8961607Z.
Base/final HEAD: 13bf5fd16c15c42e1379ce35a06e49c20753195f.
This section supersedes the earlier NO_PRODUCT_MUTATION status for current
source only. Earlier inspection failure evidence remains preserved above.

Nine approved product/test files now contain partial implementation: direct
origin IDs before receipt admission, Actions/Manager Install-result gates,
observational lifecycle blocking for unselected retained instances, bounded
FAILED_PREPARATION classification, v2 intent writer/strict readers, existing
RemoveIntegration/Uninstall transaction wiring with intent-first/desired-last
publication, persistent intent admission/PENDING retention, and focused tests.
AICodedbProcessRunner.cs itself is unchanged.

Planner Correction 01 admitted a failed-preparation-only route through
Get-ValidatedRetiredInstance / Assert-InstanceGenerationClosure /
Get-InstanceGenerationPackageIdentity. It requires original INSTALL,
PROVISIONING, empty verified_at_utc, exact unique Package transition, safe
Package-preserved manifest/worker and declared generation file hashes.
Default installed/retired RetiredTargetMap admission remains unchanged.
Production v2 intent consumers now supply Package manifest authority.

### Evidence and failures

1. Initial scoped syntax/static/diff batch passed: three PS files parsed,
   origin argument construction precedes ProcessRunner invocation, and
   git diff --check passed. C# compilation is NOT established.
2. Initial focused run failed at the real old-generation reader:
   "Package payload does not retain the declared previous generation identity."
   Actual metadata contains the poc.39 transition and preserved Package files,
   but zero poc.39 file targets and zero poc.39 retired targets.
3. Causal correction 1 added the narrowly approved old-generation route.
   The next run passed observed-shape/default-route/transition, project/hash/
   path/conflict/holder/mutable-byte cases with refusal-byte preservation, then
   failed: "failed preparation effect must be a JSON object."
4. Causal correction 2 consumed Get-RequiredJsonArray directly, removing the
   extra array around its -NoEnumerate result, and used the existing strict
   JSON parser for the emitted in-memory intent.
5. The final allowed family reached 41 successful assertions: actual production
   RemoveIntegration -> Uninstall -> UNINSTALLED/PENDING, emitted v2 record and
   collection readers, effect/path tamper refusal with unchanged bytes, and
   production COMMITTED journal finalization replay. It then failed:
   "Instance Install failed without selecting an unverified candidate. Stable
   instance wrapper target contains unowned or drifted bytes."

No fourth family, unchanged rerun or further correction occurred. All runs
finished within 300 seconds. All three PS files parsed before the final family;
final diff check passed. C# tests were authored/source-reviewed only.
Unity compile/EditMode/runtime/release acceptance: NOT RUN.

The recovery fixture materializes a real production journal/transaction entry
after actual removal and invokes production recovery. It simulates the
post-COMMITTED interruption boundary; it is not an OS crash or real-project
recovery test. External prerequisite/process behavior uses explicit fixture
seams. No generation code was executed.

Fresh candidate verification/new LKG, later admission/cleanup after fresh
Install, final status projection and v1 reader assertions are authored but were
NOT REACHED in the final family. They are not passing evidence.

### Exact remaining wrapper boundary

Verified anchors in Tools~/codedb-instance-engine.ps1:

- Get-FailedPreparationEffects:1829 inventories exact retained bytes.
  Line 1872 accepts flat bytes matching current TargetMap; line 1877 also
  accepts the old generation stable-wrapper hash.
- New-FailedPreparationRemovalIntentDocument:2005 emits
  retained_wrapper_sha256 from evidence.Generation.StableWrapperSha256:2018,
  regardless of which authenticated wrapper the effects inventory contains.
- Assert-FailedPreparationEffects:1928 binds retained_effects bytes.
- Assert-InstancePreflight:3233 reads the intent's retained_wrapper_sha256:3254
  and rejects differing actual wrapper bytes:3263.
- Fresh activation loads current Package wrapper bytes:3302 and schedules
  their publication:3362.

The producer can therefore authenticate a current Package wrapper in its exact
effect snapshot while recording the old generation hash in the scalar field
fresh Install consumes. The final fixture exposes that mismatch.

Under the frozen packet, recorded shared bootstrap effects must remain exact
and inert as part of the retained closure. No silent hash rewrite, ignored
drift or invented COMMITTED evidence is authorized. The existing Install writer
can replace the wrapper; that is consistent with exact retention only when its
intended bytes match retained bytes, or a separately frozen handoff explicitly
binds replacement. Broader shared-bootstrap replacement is not authorized by
this implementation. Parent requested reassessment of this exact boundary
before any continuation. Verifier has not started.

### Stable identity and preservation

Changed product/test paths: 9, all allowlisted.
Binary product patch: 87914 raw bytes.
Binary patch SHA256: fc7fa2a594201bc76b3be433333ea032dbaa48cf82588a6f21bc021c79d5044c.
All ten current raw file hashes are appended to FAILED-INSTALL-REPAIR-IDENTITY.txt.

HEAD/index and all 358 tracked generation files match the initial baseline.
Unrelated dirty content was not written by this Coder; parent-owned packet/
contract edits are excluded. Protected project/candidate/receipt bytes were
not inspected or hashed. No Unity/MCP/service startup, external process probe,
real Install/removal, commit/push/export or generation mutation occurred.
Each failed run cleaned only its exact harness-owned temporary fixture root.

Implementation is incomplete. Do not claim source PASS or proceed to human
runtime acceptance on this snapshot. Third family failure exhausted both causal
corrections; no additional repair was made. F-IMC-01 / P3 remains DEFERRED.

## Continuation 02 - Shared wrapper implemented; fixture completion pending

Status: PARTIAL / FOCUSED_FAMILY_INCOMPLETE / FIXTURE_LOCK_DIGEST_FAILURE.
Stable UTC: 2026-10-07T14:23:16.2951256Z. HEAD remains 13bf5fd16c15c42e1379ce35a06e49c20753195f.
The earlier partial attempts remain historical; the fresh-Install wrapper
producer/consumer mismatch is now repaired within the frozen amendment.

The v2 immutable snapshot excludes only the shared stable-wrapper FILE entry.
Its original authenticated raw hash, or explicit absence, is preserved in
retained_wrapper_sha256. Candidate, old generation and other recorded bootstrap
bytes remain exact. Assert-FailedPreparationWrapper (engine:1931) accepts the
original observation, an exactly bound ACTIVATING INSTALL journal, or a
different READY selection matching COMMITTED activation and its authenticated
generation wrapper hash. It never calls removal/admission/cleanup recursively.
Unknown wrapper bytes remain refused. The existing publication transaction and
recovery execute the change; no new executor, generation edit or schema family.

Focused fixture now covers CURRENT, ABSENT and OLD wrapper states, plus a
separate OLD publication-interruption scenario. Historical OLD bytes are an
embedded gzip fixture from source blob 1cb6ba624df89a7ce862398a409c0f2c8364f492;
decoded size 14,213 bytes and SHA256
01d9012c649df61056e469ad4382d004dccb89773997a9eb4ce8821ec01ae0ac
match the declared poc.39 wrapper. Git was used only during preparation;
the test has no runtime Git dependency and executes no generation code.

### Continuation 02 evidence

- Initial family: exit 1, 204,761 ms, 192 successful assertions. All three full
  wrapper-state paths passed, including actual removal, new verified candidate/
  LKG, preserved PENDING, later admission/cleanup, production status and v1
  reader. The separate interruption fixture passed lock.Root as candidate
  staging authority; production correctly requires a strict child.
- One causal correction created the owned staging child. Source cross-check
  also corrected the handoff consumer to the actual serialized lowercase
  mutation value, write. Both changes preceded the final run.
- Final family: exit 1, 207,045 ms, 193 successful assertions. The three complete
  wrapper-state scenarios again passed (150 assertions), plus interruption
  setup and actual INSTALL-journal authorization of wrapper publication.
- The interruption negative-case helper then failed while hashing the
  exclusively held materialize.lock. No complete-family PASS occurred.
  No further product/test correction or rerun was made after this failure.

All three PS files parsed and git diff --check passed before the final run.
Each family remained below 300 s. C# tests remain authored/source-reviewed;
Unity compile/EditMode/runtime/release acceptance remains NOT RUN.
Temporary fixture roots were removed by their bounded existing finally block.

### Exact remaining fixture-only gap

Tests~/test-codedb-host-payload-materializer.ps1:617 defines
Get-FailedFixtureDigest; line 619 hashes every file recursively, including the
harness-owned AIWork/.runtime/codedb/payload-materializer/materialize.lock.
Assert-FailedRefusal:621 invokes it while the production transaction owns that
exclusive lock. The resulting file-open failure occurs before the intended
wrong-journal-binding assertion, so the final rejection message does not match
the fixture's requested interruption.

Next bounded correction is to exclude only that exact held lock path from the
fixture digest, retaining all journal, intent, desired-state, selection,
candidate, generation and bootstrap bytes. Review the remaining interruption
assertions together before any next run. Non-INSTALL/wrong-preimage rejection,
the requested pre-commit interruption, explicit activation recovery and final
rollback assertions remain NOT PROVEN by the family. The actual journal's
positive INSTALL publication authorization did pass.

### Stable identity

Nine allowlisted product/test paths differ from base; ProcessRunner is unchanged.
Product binary patch: 104036 bytes.
Product binary patch SHA256: 369fd10eb27648527392eb7bc300f6d328fea20eadaecab395f7417791605f81.
Current ten-file raw hashes are appended to FAILED-INSTALL-REPAIR-IDENTITY.txt.
HEAD/index and all 358 tracked generation files match the initial baseline.
No Coder writes touched unrelated dirty files; parent-owned packet/contract
changes remain excluded. No real project/candidate/receipt access, Unity/MCP/
service startup, external process observation, commit/push/export or real
Install/removal occurred. Verifier has not started. F-IMC-01 / P3 remains DEFERRED.

## Continuation 03 - interruption fixture completed

Stable source UTC: 2026-10-07T14:35:53.9900893Z.
Status: SCOPED_FIXTURE_PASS / READY_FOR_INDEPENDENT_VERIFIER.
This continuation changes only the PowerShell test harness and appends the
Coder RESULT/IDENTITY evidence. Production code and C# tests remain frozen.

### Fixture correction and selector

Get-FailedFixtureDigest now excludes only an explicitly supplied held lock's
exact full Path after checking containment in this fixture root and that the
open stream names that same file. It does not exclude other lock-like files.
Without HeldLock it excludes nothing. Both fault-injection refusal calls in
the interruption callback pass the real Enter-MaterializerLock result.
The fault records still restore their exact original bytes in finally.
The journal action/mutations/pre_image_sha256 structure and publication's
rollback/recovery mechanism were inspected before the focused execution.
No production predicate or rejection expectation was weakened.

New mutually exclusive -FailedPreparationInterruptionOnly selects the existing
shared-module, unchanged-production-definition import and OLD wrapper
-InterruptBeforeCommit case. The existing full family selector still executes
CURRENT, ABSENT, OLD complete scenarios followed by interruption.
The interruption case now explicitly asserts schema_version 2 after recovery.

### New execution evidence

Invocation: Windows PowerShell 5.1 -NoProfile -ExecutionPolicy Bypass -File
com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
-FailedPreparationInterruptionOnly.

Attempt 1 was a launcher failure before fixture execution: the hosting shell's
PSHOME belongs to bundled PowerShell, so PSHOME/powershell.exe was absent.
No child or fixture was started; tool wall time was 0.404 seconds. The outer
command's zero exit code is not test success. This failed attempt is preserved.
The launcher was corrected to the explicit Windows PowerShell executable and
ErrorActionPreference Stop. No harness change was needed for this correction.

Attempt 2 / first actual fixture run:
- Start UTC: 2026-10-07T14:34:37.6735405Z.
- End UTC: 2026-10-07T14:35:21.1965181Z.
- Wall elapsed: 43514 ms; family elapsed: 42270 ms.
- Deadline: 300 seconds; TimedOut false; exit 0.
- 51 assertions; native_children 0; stdout 3671 bytes; stderr 0 bytes.
- PASS real-INSTALL-journal-authorizes-wrapper-publication.
- PASS non-INSTALL-publication-refused and its bytes-preserved assertion.
- PASS wrong-wrapper-preimage-refused and its bytes-preserved assertion.
- PASS actual-publication-interrupted-before-commit.
- Production recovery found ACTIVATING, then rolled back before new selection.
- PASS explicit-activation-recovery-after-publication-interruption.
- PASS wrapper-and-removal-authority-restored.
- PASS recovered-retained-v2-intent-readable.

Two launcher attempts, one actual fixture run; no third attempt. The actual
execution window was under one minute and within the 15-minute allowance.
The injected interruption is the existing pre-commit exception through real
publication/rollback/recovery functions, not a killed OS process experiment.

### Reused evidence and acceptance boundary

The complete CURRENT/ABSENT/OLD recovery -> fresh Install -> PENDING retention
cases, v1 reader and later admission/cleanup from Continuation 02 are reused
under unchanged production hashes. They were not rerun by this selector.
The historical 193-assertion run remains partial with its lock-digest failure;
it is not relabeled as a full-family pass. Its missing interruption evidence
is now supplied by the focused 51-assertion pass above.

Final harness parse and scoped git diff --check PASS. Nine non-harness hashes,
HEAD and index match Continuation 02 exactly; ordered raw hashes are appended
to IDENTITY. No generation file writes or broader generation re-audit occurred.
Only fixture-owned temporary project data was exercised. Unity/EditMode, live
runtime, real consumer/project/candidate/receipt, Provider/service, device,
performance and release acceptance remain NOT RUN in this continuation.
No commit/index write/export, real Install/removal, subagent or Verifier contact.
F-IMC-01 / P3 remains DEFERRED. Coder stops at this stable snapshot for Verifier.

# S29 historical wrapper handoff Coder result

Date: 2026-10-14. Status: STABLE_CODER_SOURCE_AND_PS_SYNTHETIC_PASS_WITH_LIMITS.
Base/head: 14444cf1ad179fe29e067e8dcfdc7b0b5496e230.
Branch: codex/v0.3.0-legacy-workflow. Staged index empty; no delivery performed.
Only two allowlisted source files changed. ManagerUiTests, Journal, materializer,
Lifecycle, prerequisite and dirty Payload remain unchanged.

## Change and authority

Get-InstanceRetainedEffectsObservation now validates selected/current and LKG
Package identity before reading failed-preparation intents. Only independently
validated TRUSTED_PREVIOUS selection opts into the HistoricalObservation switch.
The switch passes through Get-InstanceRemovalIntents, Get-InstanceRemovalIntent
and Assert-FailedPreparationWrapper. Its changed-wrapper branch uses existing
Get-ValidatedRemoveIntegrationSelection and Get-RemoveIntegrationActivationState,
requires predecessor disposition and committed exact cross-bound activation,
then revalidates the selected READY instance and actual Package wrapper bytes.
Historical committed documents retain their original CURRENT-relative evidence;
the exact selected instance/hash is compared without rewriting any records.

The repeated intent read inside Assert-InstanceNextChangeAdmission receives this
scope only from the observation caller. It requires HistoricalRemoval plus a
validated predecessor before reading intents. Existing real HistoricalRemoval
callers do not set the new switch; their shared intent/default behavior stays
strict. Ordinary CURRENT, Ready, Install, ACTIVATING handoff, real removal,
holder/config/handoff and mutation gates are unchanged. There is no broad catch
fallback, new serialization field, new reader/service or inferred mutation permit.

## Exact inputs and evidence

Exclusive overlay:
.artifacts/tests/s29-version-transition-wrapper-handoff/coder-a1/com.rice.ai-codedb.
It was copied from exact delivered
.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb,
with only the two changed files overlaid. Original predecessor input:
.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb. Dirty working-tree
Payload was never copied/regenerated. Historical runtime remains
538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d;
target runtime remains
69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.

- L0: final engine/test PowerShell AST syntax and scoped git diff-check PASS.
  Exact overlay PathProvenanceOnly PASS, with helper projections=3,
  PS decoding/admission bindings=2 and Node bindings=2. C# not changed, so no
  redundant C# compilation/execution was required or performed.
- Missing chronology: before-install-a2.log PASS 32 Check assertions, fixture
  .artifacts/tests/s29-version-transition-observation/wrapper-handoff-a2/r-25c90177.
  Real serializers created PROVISIONING failed candidate + schema2 retained
  intent while the wrapper was absent; original hash is empty. Existing
  PocFixture production Install42 then commits a distinct READY instance.
  Current42 wrapper reader returns COMMITTED; target43 default intent refuses;
  explicit historical intent and repeated admission both authenticate COMMITTED.
  Target43 production observation is SAFE with InstallEligible=false. Its
  emitted single-line SAFE/BLOCKED output uses the exact materializer statement.
- ORIGINAL chronology: original-a1.log PASS 27 assertions, fixture
  .artifacts/tests/s29-version-transition-observation/wrapper-handoff-a2/r-29ff7bce.
  Existing install-before-failure scenario still returns ORIGINAL. Both scenarios
  keep ordinary next-change target-strict and Current same-version SAFE controls.
- Both scenarios reject wrong/missing/undeclared predecessor runtime, foreign
  selected project, wrong generation/epoch, mismatched operation/runtime,
  paired ACTIVATING historical records, immutable worker drift, arbitrary wrapper
  bytes, live/unknown holder and independent unbound relevant candidate. Refusals
  return BLOCKED, empty ids and InstallEligible=false; actual safety reason stays.
- Both fixture byte digests remain unchanged by observation/refusal reads and
  fault restoration. Original failed intent remains byte-identical through
  synthetic Install42 and all observations. No index or original result is
  created/manufactured. This fixture has no original Manager receipt attribution.

Initial before-install-a1.log failed before scenario execution because a cast
within New-Module ArgumentList became a string. One mechanical correction
parenthesized the bool cast; before-install-a2 then passed. No semantic/product
test failure or additional independent product cause occurred. Attempt logs are
separate and preserved. Existing synthetic prerequisite/process-identity and
PocFixture candidate verification are the declared seams; native children=0.
Synthetic setup logs READY describe original42 fixture setup, not target43 Ready.
The existing synthetic cleanup warning is preserved; no external process observed
or stopped, and no actual cleanup success is claimed.

## Preservation, limits and handoff

protected-before.txt and protected-after.txt under the exclusive evidence root
are identical across 2844 bounded entries: real S29 references/runtime, receipts,
installed generations, exact original/target Packages, dirty Payload and
OwnerIdentityV2Status. Source/overlay SHA256 equality verified for two changed
files plus unchanged consumer test. Hashes are in the task-local dedicated file.

NOT RUN: Unity/EditMode/MCP/CUA/BatchMode, consumer Journal/session/UI execution,
live product reader/Probe/IPC, real Install/Remove/Upgrade/Ensure, process control,
cleanup, commit/export/reference switch/push/release. Existing ManagerUi NUnit
method can consume either fixture's identical output contract under separately
authorized Unity testing; this task does not rerun it or claim consumer PASS.
MissingPrerequisite, real removal-preflight exit4, CleanupMono and release/real
recovery remain independent deferred evidence boundaries.

Coder stops at this stable source snapshot. Parent owns read-only Verifier
admission and consolidated user disposition; source accept/delivery remain later.

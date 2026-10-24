# S29 version-transition wrapper handoff — read-only diagnosis

Date: 2026-10-14, Asia/Shanghai.
Status: CONFIRMED_STATIC_CAUSE / REPAIR_PROPOSED_NOT_AUTHORIZED.

## Baseline and authority

User approved continued analysis after the focused human Unity test passed and
Manager interaction was reported normal. The actual Manager still showed a
retained-effects activation-context refusal and MissingPrerequisite.
CleanupMono shutdown handling is explicitly deferred and excluded.

HEAD remains 14444cf1ad179fe29e067e8dcfdc7b0b5496e230. The four accepted source
files have no working-tree diff; staged index is empty. Existing unrelated
dirty documentation, Payload, project and task records remain untouched.
Production reads below use the exact delivered Package:

`.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb`.

This is static source analysis plus bounded JSON/hash and existing-log reads.
No product reader, Node probe, fixture execution, live IPC, Unity automation,
process control, source repair, commit, export, reference switch, Install,
Remove, Upgrade, or historical cleanup was performed. No child was dispatched.

## Confirmed earlier blocker

The accepted change fixed the outer observation's predecessor authority, but
the following earlier dependency still uses the target runtime authority:

1. `Get-InstanceRetainedEffectsObservation`, engine line 3377, reads all removal
   intents before its TrustedPrevious branch at line 3396.
2. `Get-InstanceRemovalIntents`, line 2296, calls `Get-InstanceRemovalIntent`.
3. The schema-2 failed-preparation branch calls
   `Assert-FailedPreparationWrapper -AllowActivationHandoff` at line 2227.
4. Wrapper validation compares the current hash to the intent's original hash
   at lines 2014-2015. If they differ, line 2017 calls
   `Get-InstanceActivationContractState -Manifest $Manifest`, using target43.
5. The actual committed activation belongs to selected42. Its runtime hash is
   538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d;
   target43 requires
   69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.
   The control-contract tuple is unchanged. The target-runtime reader therefore
   refuses this historical activation before the new outer branch is reached.

The screenshot's explicit activation-contract/project-context refusal agrees
with this deterministic source/record mismatch. This turn did not execute the
live reader and does not claim that every later gate would pass after repair.

The same inner intent read appears in `Assert-InstanceNextChangeAdmission` at
line 3305, before that function's HistoricalRemoval authority branch at 3325.
A repair restricted to only the first observation read would leave the same
cause on the subsequent admission path. Other callers include production
mutation paths: do not globally relax the shared reader.

## Actual wrapper history versus passing fixture

Actual intent records relative to S29 control/removal-intents:

| Intent | Retained instance / generation | retained_wrapper_sha256 |
| --- | --- | --- |
| 13852a6e3cd84136985bd25f7e61a563 | 5a6ff71560234b558e1a42148b680a77 / poc.40 | empty |
| 35db5b76947741278dceeef1d98990c7 | 330b7a972a7649259409fbce4de8ca56 / poc.39 | empty |

Their SHA256 values in this read:

- 13852…: 7db4cd86d4e58f227f63e6f02291ce98b6914a40ff666a86d3c36e540f537e45
- 35db…: aa6dfb83231fadfc8fc6d1d1ecc963c4053414ede28bacb8bcfb3d810c7c8039

The real wrapper exists at AIWork/codedb/wrapper/codedb-project-wrapper.mjs,
SHA256 7f209316005ffd02bccd01c78ae1773d695694a77817d99f1753041b6aef4399.
Both records therefore bypass ORIGINAL and require handoff authentication.
An empty historical hash is evidence of absence at that time; it is not a
reason to rewrite the old record or authorize an arbitrary current wrapper.

The authored PS fixture instead installs42 first (test line 1127), then creates
a failed predecessor and intent. Line 1147 records the already-existing wrapper
hash into WrapperSha256; line 1149 uses the production intent serializer. Its
observation thus passes through ORIGINAL at engine line 2015 and never exercises
the predecessor committed-handoff reader at 2017. The 24 isolated checks and
human Unity consumer PASS are valid for that scenario, but do not cover the real
failure-before-install chronology. The Unity test consumes these recorded
observation outputs; it does not add backend coverage of the missing chronology.

## Separate prerequisite uncertainty

The screenshot also shows MissingPrerequisite. Its diagnostics expose a
truncated provider-install guidance suffix. Bounded prior reads found the real
machine provider manifest/executable present with matching hash. Presence in the
agent environment does not establish what Unity's child process resolved.

Production DryRun evaluates Node then provider and emits MISSING on refusal
(materializer lines 12147-12151; machine-provider contract lines 343-378).
Lifecycle `TryRouteHistoricalRemoval`, lines 1563-1577, returns an observed
trustworthy MissingPrerequisite before calling removal preflight. Thus this
status and the retained-effects refusal are distinct gates; fixing wrapper
authentication does not prove prerequisites or real removal are ready.

The existing Editor-observed.log reports MissingPrerequisite at its first
reconcile completion, before Manager opens. It lacks the complete prerequisite
ReasonCode/detail and test-start ordering needed to attribute the cause.
The Unity consumer test temporarily changes process LOCALAPPDATA and restores
it in finally. Concurrent lifecycle inheritance is a candidate explanation,
not a confirmed cause. No test-isolation or prerequisite source change is
authorized by this diagnosis. Preserve the uncertainty; do not ask for blind
dependency reinstall or declare the provider absent.

## Proposed bounded repair and evidence

Proposed source allowlist, subject to user approval:

- Tools~/codedb-instance-engine.ps1: explicitly carry validated historical
  observation authority through the intent/wrapper dependency chain and its
  repeated admission read. Authenticate a committed predecessor handoff using
  existing Package-bound historical readers and preserve the selected instance,
  epoch, operation, generation, immutable hash and actual wrapper bindings.
- Tests~/test-codedb-host-payload-materializer.ps1: add production-serializer
  coverage of failures before wrapper publication, successful install42 handoff,
  then target43 observation; preserve the existing ORIGINAL scenario.
- Tests/Editor/AICodedbManagerUiTests.cs: only directly coupled consumer fixture
  assertions if needed to consume both observation scenarios. No UI/lifecycle
  behavior redesign is proposed.

The default CURRENT reader, Ready, ordinary next-change, Install eligibility,
ACTIVATING handoff, and real removal execution must retain their existing strict
authority and safety checks. A failed historical identity must remain BLOCKED;
do not fall back from an arbitrary target-reader failure to historical trust.

Evidence must cover the missing chronology and both reads, unchanged ordinary
target-strict refusal, and adjacent negative cases: undeclared/wrong predecessor
authority, foreign project or selected identity, mismatched committed
operation/epoch, arbitrary wrapper hash, and pending activation. Production
observation -> Journal/session/UI remains explicit, with InstallEligible false
for an installed predecessor. Isolated test state must remain unchanged by
observation. Preserve original histories and real protected bytes.

The proposal addresses the confirmed context-routing gap. It makes no promise
that all real Manager gates clear or that existing removal-preflight exit 4 is
resolved. Real prerequisite detail and confirmed removal remain separate evidence
boundaries. No new packaging, project switch, or human Unity run is included in
the repair proposal. Source acceptance and delivery retain their own gates.

Workflow revision 2.6 lines 103-104 requires a user decision for the next
independent deliverable or expanded frozen evidence scenario. The prior accepted
source envelope has finished; continued diagnosis does not authorize this new
repair. A child execution route, if selected, also needs task-specific approval
under the user's AGENTS instructions.

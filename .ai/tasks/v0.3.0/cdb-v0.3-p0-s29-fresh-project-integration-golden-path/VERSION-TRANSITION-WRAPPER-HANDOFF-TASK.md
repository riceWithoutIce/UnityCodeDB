# S29 historical wrapper handoff narrow repair

Date: 2026-10-14. Base HEAD: 14444cf1ad179fe29e067e8dcfdc7b0b5496e230.
Status: AUTHORIZED / CODER_ACTIVE. Parent confirmed explicit user approval to
reuse Coder then read-only Verifier. No recursive delegation or delivery grant.

Frozen source scope: com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1 and
Tests~/test-codedb-host-payload-materializer.ps1; directly necessary consumer
assertions only in Tests/Editor/AICodedbManagerUiTests.cs. Task-local records and
new isolated artifacts are evidence outputs. No prerequisite/lifecycle/shutdown,
UI production, serializer fields, authority service or wider orphan redesign.

Cause and acceptance: schema2 intent wrapper handoff currently authenticates
selected42 committed activation under target43 context before outer historical
observation/admission is reached. Carry explicit historical-observation scope
through both intent reads into wrapper authentication, using existing strict
Package-bound selected-v2 and committed activation readers. Default callers,
CURRENT/Ready, ordinary Install/admission, ACTIVATING and real removal gates
remain strict. No fallback from arbitrary current failure to historical trust.

Freeze authority chain before edits: observation validates selected/current
Package identity first; only TRUSTED_PREVIOUS opts into historical observation.
Get-InstanceRemovalIntents -> Get-InstanceRemovalIntent ->
Assert-FailedPreparationWrapper carry that explicit scope. Wrapper's changed
historical branch revalidates exact selected READY instance, Package predecessor
closure, committed paired records, epoch/operation/hash and actual wrapper hash;
it grants only a read-only COMMITTED disposition. Observation's subsequent
Assert-InstanceNextChangeAdmission opts into the same scope and repeated intent
read; its ordinary default and existing real HistoricalRemoval callers do not.

Inputs: exact delivered target Package
.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb;
exact original predecessor Package
.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb. Never use dirty
working-tree Payload. Protected: real projects/references/runtime/receipts/index,
original histories/artifacts, immutable generations, dirty Payload and unrelated
source/docs. Snapshot bounded protected hashes before/after, no product reader.

Evidence envelope: L0 PS syntax, diff/hash/path provenance; compile only if C#
changes. L1 existing VersionTransitionObservationOnly ORIGINAL fixture plus
failure-before-wrapper -> production synthetic Install42 committed -> target43
observation, both intent/admission reads and strict ordinary refusal. Adjacent
negative runtime/undeclared/project/identity/epoch/operation/wrapper/pending,
holder/relevant effects guards remain active. Consumer emitted output remains
seven-field SAFE with InstallEligible=false; compile authored test as needed,
Unity execution stays NOT RUN. Synthetic setup uses existing PocFixture/native
identity seam only and zero native children.

Budget: DEEP_60M; initial plus two causally corrected semantic attempts per
scenario, two mechanical corrections; at most two product causes. Preserve
attempt logs and stop on a new out-of-scope cause. Stable Coder result/hash and
questions return to parent before Verifier. No commit/export/reference switch,
Unity/MCP/CUA/BatchMode, real Probe/Ensure/Install/Remove/Upgrade/IPC/process control
or cleanup. Prerequisite status and real removal exit4 remain separate gaps.

# S29 startup readiness / historical routing — read-only diagnosis

Date: 2026-10-13, Asia/Shanghai. Snapshot observed at approximately 11:42.
Status: DIAGNOSIS_COMPLETE / NEXT_SCOPE_ALIGNMENT_PENDING.
Authority: user continuation of the read-only Provider/Coordinator diagnosis.
No implementation or operational authority is inferred from this record.

## Current identities

- HEAD: 9eac17cfdb741f89d33a4b7c2ddf6261abcb9566.
- Both S29 Package references select the exact upgrade-callsite-fix-34b3a65
  extraction. Manifest and lock hashes still match its delivery result:
  9adea12c24219aea55d06364dbb38346b418079746e59c05c37fcb7efd8fbc09 and
  507a4db713e10748a63d7a694729649f5550b2e2e42cd449d86a74636d9982d6.
- Package target is poc.43, sequence 43; generation manifest SHA256:
  55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5.
- Package runtime authority (raw payload-manifest.json SHA256):
  69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.
- Selected installed instance remains d620abbab0334a2d9c49e59888c1ef55,
  poc.42, desired INSTALLED / cleanup PENDING. Its manifest matches selection:
  664d0a7d99ce67c32f4537fecae076c3efcd0ac4e2aee8260957d4269302df62.
- Original installed42 and Package-retained42 generation manifests both hash to
  2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026.
  All 29 installed declared files match their own manifest. This is file-hash
  closure, not live holder authentication or a no-extra-files assertion.
- Existing activation is COMMITTED and its runtime hash remains
  538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d;
  the committed operation binds that same old runtime hash.
- Installed coordinator hash is 5a61242e336fac40ac5ce94729d71c676272f65510993481c80a0ee71651ed00;
  successor43 coordinator hash is 928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09.

## Latest operational evidence

Read only the selected instance's coordinator log, recent Supervisor events and
eight latest operation-history records. No Probe/Ensure command was executed.

- At 03:08:18.612Z coordinator start was followed by provider_ready at
  03:08:19.088Z. At 03:10:40.663Z another start was followed by provider_ready
  at 03:10:40.711Z. These are old42 Provider observations, not successor43
  sustained or authenticated Ready acceptance.
- Four recent materialize:Probe results exited 5. They report TRUSTED_PREVIOUS,
  product NEEDS_ATTENTION and a required handoff. They do not report a Provider
  initialize/tools-list timeout.
- Three materialize:Upgrade records (cb60d76287524845974b6539cc23e741,
  90c17e9c48b843c2a5c37ae4ddfdec53, 1a43cdf055cd43d389388598b2cf93ae)
  exited 6: INSTANCE_CONVERGENCE_FAILED, PREFLIGHT, BLOCKED, timed_out=false,
  mutated_scopes=[], with activation contract/project-context mismatch.
  These are existing application actions, not actions invoked by this diagnosis.
- A later Supervisor start at 03:10:59.961Z records coordinator_start_failed /
  NONZERO_EXIT at 03:11:00.051Z. Current disk state remains degraded with that
  category and no coordinator status. That event/state does not retain enough
  child output to identify its exact cause; do not label it STARTUP_TIMEOUT or
  attribute it to Provider initialize/tools-list.
- Read-only process inventory found Supervisor PID 12632 using this exact
  Package's supervisor source. No matching S29 Unity or the observed previous
  coordinator/provider PIDs appeared in that inventory. A running process and
  disk status are not an authenticated IPC availability test. No process stop
  or cleanup is authorized by this observation.

Historical operation 5bb81f9b95074bb5848d8bca01e265ea from 2026-10-10 really
did contain a 30000ms coordinator-readiness timeout. Keep that old sample
separate from today's preflight refusals. Successor43 contains the accepted
initialize/tools-list phase and STARTUP_TIMEOUT classification repair; it has
not been installed or live-validated here.

## Confirmed source routing gap

The accepted historical-removal contract explicitly says that
source_runtime_contract_sha256 does not grant CURRENT, Upgrade, Install or
cleanup permission. Nevertheless, the existing production lifecycle conflates
trusted historical identity with automatic deployment eligibility:

1. AICodedbProjectIntegrationState.cs:680 validates exact Package-declared
   predecessor identity/closure and returns TrustedPrevious. This establishes
   historical identity, not cross-runtime activation migration.
2. AICodedbEditorLifecycle.cs:2216-2218 unconditionally maps TrustedPrevious
   to Deploy; its Deploy branch at 1405-1415 runs materialize Upgrade.
3. codedb-instance-engine.ps1:5420-5431 describes a non-current selection as
   ready for automatic handoff. That output promises more than today's existing
   strict Upgrade route can perform.
4. Invoke-InstanceConvergence at 4862 enters generic next-change admission.
   The activation context derives its runtime authority from the current
   Manifest (476-505), and the validator at 621-628 rejects the old activation
   hash. The three actual refusals match this deterministic authority mismatch.

The backend refusal protects the selected predecessor. Do not repair this by
letting the historical removal hash authorize general Upgrade or by rewriting
activation hashes. The confirmed gap is route/capability separation, not a
reason to relax authentication or extend Provider startup timeouts.

The exact Package also already distinguishes post-identity IPC transport
failure from malformed/foreign authority in AICodedbControlContract.cs:1678-1684.
The old blanket transport-to-invalid diagnosis must not be replayed as an
unfixed source finding without new evidence.

## Recommended next bounded objective — proposal only

Align the lifecycle/Probe capability contract before another real Unity or
removal run: a Package-declared predecessor that only has historical-removal
authority must not enter automatic Upgrade. Preserve genuine existing
automatic-handoff cases only where their authority is separately proven.
Present the controlled removal/reinstall route using its authenticated
preflight, without forcing Install visibility or claiming current Ready.

Before implementation, freeze the minimum producer/consumer map, compatible
handoff cases and focused evidence for: old selected-v2 + different current
runtime hash; same-contract supported handoff; malformed/foreign predecessor;
unchanged first Install/current readiness; reopen/reconcile without repeated
Upgrade; removal-preflight presentation without a manufactured permit.
Return any needed serialized capability or additional reader change for scope
approval. This diagnosis selects no schema, source allowlist or execution route.
An implementation task and Coder/Verifier routing require their own grant.

Actual Remove -> Uninstalled -> fresh43 Install -> authenticated/sustained Ready
remains a later separately authorized gate. CleanupMono remains user-deferred
observation. The unexplained latest NONZERO_EXIT remains an observation with
insufficient attribution, not an automatic new repair target.

## Limits and preservation

Only this diagnostic document was added. No source/Package/runtime edit,
test run, Unity/MCP/BatchMode/CUA launch, real Probe/Ensure, Install/Upgrade/
Remove/Uninstall, generation production, export, reference switch, commit,
push, process control, receipt/index release or historical cleanup was executed.
Existing dirty state is preserved; scoped Editor/Tools/Tests source diff and
staged index were empty. The live Supervisor continues to update its own state,
so its timestamps/revisions are point-in-time observations, not frozen bytes.

Some initial search/read outputs were truncated and some guessed filenames
were absent; decisive identity, source routing and recent operation evidence
were read in bounded follow-ups. No blanket output-budget compliance or
independent Verifier result is claimed. S29/release remain PARTIAL.

A final whitespace check was inadvertently repository-wide and reported
inherited UnityValidationProject/ProjectSettings.asset whitespace; its output
was truncated. No cleanup was performed and no repository-wide clean-check
claim follows from it. Final scoped status still showed no Editor/Tools/Tests
source changes and an empty staged index.

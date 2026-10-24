# S29 retained execution — bounded feasibility result

Date: 2026-10-15. Status: READ_ONLY_ANALYSIS_COMPLETE / ISOLATION_PROOF_NOT_ESTABLISHED.
Approved scope: RETAINED-EXECUTION-ISOLATION-ALIGNMENT-PLAN.md; user `ok 同意`.
Baseline HEAD/source: `5b52c017e8415bb061f33a8380b3dcec2916411a`.

## Decision

The bounded analysis does not establish a safe existing-mechanism exception
for missing-child histories. Keep their fail-closed refusal. Do not begin a
patch that merely drops these histories from admission or treats preservation
as execution isolation. This is a concrete proof gap, not a demonstrated live
orphan process, a new source finding against the accepted slice, or authority
to build a general isolation subsystem.

The two records belong to the current selected instance and retain null child:
45e02ba862654c81af4d592dc56e49d3 (Probe, completed/exit0) and
69d2e7c44f774e3687e352d5faf9eb97 (Upgrade, failed/exit1).
Both runtime-contract hashes are
538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d.
Completion/failure is not child/descendant termination proof.

## Source authority and limits

The preserved `.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb`
Package has that exact payload-manifest hash. Analysis used its frozen
Supervisor, materializer, instance engine and relevant generation42 launch/lease
consumers; current removal was read from the delivered5b52c01 Package. Dirty
Payload was not used, and no arbitrary older versions were searched.

Matching runtime-contract bytes authenticates a runtime authority reference;
it does not attest which historical Tools bytes executed. The manifest lists
60 payload entries and no Tools entries. Null-child records cannot provide
their missing executable/argv identity. Thus this analysis maps the preserved
matching-authority implementation, not an exact reconstructed historical process
execution. That limitation precludes using the source map as a new universal
retrospective termination/isolation permit.

## Execution map

In the preserved Supervisor, materialize Probe and Upgrade first call
ensureCoordinatorWithAttribution, then runMaterializer (lines1600-1608).
ensureCoordinator may launch Node Coordinator startup (lines1914-1948), while
runMaterializer starts PowerShell with root/payload/action and originating IDs
(lines2014-2038). prepareOperationChildEvidence clears child before each phase
(lines2388-2395). Therefore one null child does not identify a single executable
or establish that no earlier component was started.

recordChildEvidence is deferred and can miss short-lived children; finishOperation
overwrites phase with completed/failed (lines1314-1322,2397-2435). Recovery of a
running record without a child finishes with an interruption failure (2274-2280).
These explain possible evidence shapes, not the exact cause for either record.

runChild uses ordinary spawn, later identity capture and direct-child close/error
observation (3005-3050). This path contains no durable process-tree containment
proof that can be recovered from these two historical records. Its timeout
handling is not evidence that any unknown historical descendant was stopped.

## Resource-to-proof table

| Resource/effect | Existing relevant mechanism | Sufficiency for missing/unknown historical execution |
| --- | --- | --- |
| Old instance/generation bytes and dynamic index/runtime | Immutable closure validation, explicit retention, retirement controls | Can bind preserved bytes; does not prove that an untracked actor cannot keep writing mutable content |
| Project selection, desired state, activation and registration | Materializer lock, convergence admission, transactional hashes and verification | Serializes compliant mutation and checks state; does not authenticate an absent historical actor or provide an established permanent revocation of all its future effects |
| Coordinator, Provider, adapter children and runtime status | Coordinator lifecycle demand, leases and known component identities | Useful for represented components; not an inventory/containment proof for an unrecorded execution tree |
| Current/stale Supervisor namespace and history | Paired owner identity, strict terminal history, canonical equality, preserved fingerprint | Current removal explicitly requires missing-child refusal; removing that check would remove proof, not add isolation |
| MCP, Editor, Coordinator holders | Get-InstanceRetirementHolderEvidence | Covers these registered consumers only; Clear cannot substitute for unknown-child proof |
| Retired instance fence | Retirement control and retiring marker publication | Protects participating retirement/lease paths; not demonstrated as an OS access boundary or a revocation check consumed by every possible historical writer |

Supporting preserved-source locations:
materializer Enter-MaterializerLock2617; Probe12083; instance engine
Invoke-InstanceConvergence4759, Add-ProjectRemovalDeactivationEntries3219,
Get-InstanceRetirementHolderEvidence4141, Publish-IntentBoundRetirementFence4161;
Coordinator assertLifecycleDemand423 and child launches1375/1441;
generation host-use gate acquireCodedbHostUseLease82 and active-marker check185.
OriginatingOperationId is attribution; the convergence path validates its format
and records origin, not a universal per-effect revocable permission for old actors.
The existence of some epoch/lease checks must not be generalized to all writers.

## Time and recovery boundaries

The current delivered Invoke-RemoveIntegration (materializer11759 onward)
validates authority/handoff at entry and after acquiring the project lock,
rechecks before mutation, validates terminal state before commit and after it,
and retains durable intent/transaction evidence. Preserved history is part of
its authentication fingerprint and terminal validation.

Those checks guard a transaction using the accepted admission rules. Ignoring
null child/unknown process would not prove the absent premise. In particular,
release of the project lock and later fresh installation are future periods;
a scan performed under a lock is not permanent execution revocation. Existing
UNINSTALLED and selection checks are real safeguards, but this analysis does
not establish that they cover every unrecorded earlier phase/descendant or
remain a closed barrier after a later installation. No actual late-write
reproduction, exploitation, or claim that such a process currently exists is made.

Changing only current code also cannot retroactively make an unrecorded old
process consume a newly introduced fence. Any broader solution requires its
own explicit authority, resource and backwards-boundary design; it is not a
mechanical three-file exception.

## Evidence fingerprints

Paths below are relative to preserved Package root for the first three:

```text
d70d49a2a664aef3ac6cea759ac77873868be7941df82e66f305088e95ad6220  Tools~/codedb-project-supervisor.mjs
7bdce9d731e02a7f0bc4711128c3b1ece9cf26cf99f269bd7735ef74502216af  Tools~/codedb-instance-engine.ps1
740d5fc9a9f51817fb7446ecfc6e90674316f09356287237747e3e40ffa3b826  Tools~/materialize-codedb-host-payload.ps1
5cff0f5ee12181ae95a49c3bf2af515d8d473972f3ecb38cdcb6ca2fad29bfc3  operation-history/45e02ba862654c81af4d592dc56e49d3.json
263eabd0a54b4a40191ecaa8b0ecbaa4c829c61805f9d1e3bd0579a10d3f16fb  operation-history/69d2e7c44f774e3687e352d5faf9eb97.json
```

History paths refer to the real S29 v2 Supervisor namespace named in the
diagnosis. Hashes identify read evidence, not an execution attestation.

## Next disposition

Stop this bounded analysis at the concrete isolation-proof gap. Keep this
integration blocked and preserve original history. The twelve known-PID
observation failures remain a separate issue; enhancing their observation would
not close missing-child admission. Do not combine this result with an automatic
CIM fallback repair or repeat delivery/human smoke.

For development-route progress, propose a separately authorized clean fixture
with explicit paths and exact accepted Package to exercise install/remove/fresh
reinstall without changing this project. Old-project recovery remains an open
item and cannot be reported solved by clean-fixture success. If recovery of this
exact project is instead prioritized, freeze that larger resource/isolation
design separately before any implementation. No choice is presumed here.

## Actions and verification limits

Read-only file/source/hash analysis only; no new tests, real preflight/Probe/IPC,
process queries/control, Unity operation, runtime/history/config modification,
clean fixture creation, commit, export, reference switch or remote write.
Parent used no subagents. Only alignment/result documents were edited.
The root AGENTS.md file was absent; the user-provided AGENTS instructions apply.
Some source listings were truncated; conclusions use the targeted visible
functions/branches, not a claim of a whole-file or all-writer audit. Plan-status
patches with mismatched context failed before a corrected patch succeeded.
Final bounded checks: HEAD remains5b52c01; accepted three-file source diff and
staged index are empty. Both null-child record hashes match the evidence above.
S29 manifest/lock hashes remain respectively
f5c97a3380b59db8b9dab4e206f7e464894ab335b1ae5c2d87efe76cb136cda3 and
3a5c6b00dd9d20604086eb178bf3f0a8dfa82be2014a2198dadee78f80b0c452.
No global protected-state equality claim is made. S29/release remain PARTIAL;
CleanupMono and post-stability physical cleanup stay deferred.

# S29 Instance Manifest Contract Closure - Coder Result

Date: 2026-10-07
Status: COMPLETE - bounded source and isolated non-Unity evidence only.
Role: task-scoped Coder; all product/tool/test writes are now stopped.
Base HEAD: 70f33f7e9f7b39b63aaf9c1d4eedba122f67799a (unchanged).
Authority: INSTANCE-MANIFEST-CLOSURE-PLAN.md and the named 2026-10-07 contract/workflow sections.
Snapshot: Package 0.3.0-preview.5; poc.40; payload sequence 40; bootstrap protocol 1.

## Result and contract projections

Closed both PS edges (strict decoding and the obsolete exact 17-field admission)
and both affected Node instance edges. originating_action remains absent/null or
exactly action/action_id/operation_id, with INSTALL/UPGRADE/REINSTALL and two
lowercase 32-hex string IDs. Attribution conveys no selection, readiness,
ownership or change permit.

The existing four recursive strict-JSON PS functions were extracted unchanged
to Payload~/AIWork/codedb/shared/codedb-strict-json.ps1. Static comparison to the
frozen HEAD confirmed all four function bodies match, normalizing line endings.
The pure PS instance projection uses that reader, exact required/optional field
admission and typed accessors. The writer's existing origin validator now binds
the same pure origin projection; its document and atomic serializer remain
production definitions. The pure Node instance projection retains bounded,
strict JSON parsing and explicit field/origin checks. Provider flat parsers and
Provider compatibility remain unchanged.

All paths in the following map are relative to com.rice.ai-codedb.

| Consumer boundary | Actual binding and evidence |
| --- | --- |
| Writer | Tools~/codedb-instance-engine.ps1:2057, :2080, :2119; shared origin validator, New-InstanceManifestDocument and Write-InstanceManifest. L0 asserts exact production function bodies, emits actual atomic serializer bytes before decoding. |
| Generation PS decoding | Payload~/Generations/poc.40/scripts/codedb-project-common.ps1:207 -> ConvertFrom-CodedbInstanceManifestJson. Actual generation script is dot-sourced from its exact fixture copy; no reader/parser seam. |
| Generation PS field admission/context | Same file :247 -> Assert-CodedbInstanceManifestFields, instance typed accessors; old fixed-count list removed. Identity/state/path/no-reparse/generation-hash/worker-hash checks remain. Actual context succeeds for valid bytes and rejects RETIRED and wrong generation hash. |
| PS action callers | 14 generation scripts call Get-ProjectCodedbContext and Assert-CodedbUnityProject -Context $context. The latter (:317) binds Assert-CodedbInstanceContext when an instance root exists. Enumerated caller list below. |
| Stable Node front door | Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs:116 unconditionally calls imported parseCodedbInstanceManifest after existing selection/path/hash binding. Control selection remains on its original flat parser. |
| Generation Node worker | Payload~/Generations/poc.40/wrapper/codedb-project-instance-worker.mjs:258 unconditionally calls that same imported decoder before unchanged identity/state/worker checks. Provider manifest remains on its original flat parser. |
| Other PS direct readers | Current/LKG, retired closure and retained removal-intent reads use Read-BoundedJsonDocument -> the extracted strict reader. Current/retired routes retain Assert-InstanceManifestOrigin. Removal-intent reads retain hash/identity/path binding and do not interpret origin. No additional flat instance decoder found. |
| Existing C# projections | Editor/AICodedbProjectIntegrationState.cs:330/:467; control/v1 route Editor/AICodedbControlContract.cs:623/:624 already calls ValidateOriginatingAction. Host generation/settings routes delegate or reference selection paths. All C# source and accepted origin test bodies unchanged; no C# compilation performed. |
| Existing Supervisor reader | Tools~/codedb-project-supervisor.mjs:3208 -> readRequiredJson -> parseStrictJson(:3524). Existing recursive decoder supports object/null (:3570/:3573), checks duplicates/depth and does not interpret origin. Inventoried/source checked only; no Supervisor execution or new validation scope. |

PS caller inventory (all under poc.40/scripts):
build-codedb-project-text-adapter.ps1; check-codedb-project-freshness.ps1;
clear-codedb-project-index.ps1; emit-codedb-mcp-registration-draft.ps1;
manage-codedb-project-watch.ps1 (including failure/cleanup); prepare-codedb-project-runtime.ps1;
prepare-codedb-project-watch-config.ps1; probe-codedb-project-index.ps1;
probe-codedb-project-text-adapter.ps1; refresh-codedb-project-if-stale.ps1;
refresh-codedb-project.ps1; show-codedb-project-provider-guidance.ps1;
validate-codedb-mcp-project-config.ps1; verify-codedb-project.ps1.

## Canonical successor route

Extended the existing Tests~/test-codedb-package-release-closure.ps1 route
(:105 consumer projection; :135 successor generation) with one admitted
-SuccessorGenerationId input. The actual invocation was:
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File
com.rice.ai-codedb/Tests~/test-codedb-package-release-closure.ps1
-PackageRoot com.rice.ai-codedb -RepairCanonicalMetadata -SuccessorGenerationId poc.40

The route rejected an existing target, derived sequence 40 from the admitted
identity and prior sequence, generated common/worker projections from immutable
prior templates, copied all three shared helpers byte-for-byte, enumerated all
new files and regenerated coupled metadata/hashes and OwnerIdentityV2Status.json.
No independent hashes were hand-edited. Added the three helper targets to the
materializer's flat and generation production allowlists. Boundary assertions
now include helper-copy/caller bindings and the directly coupled identity/counts.
No new runtime generation literal was added.

Eight historical transition records retain exactly their frozen values and
order. One predecessor record for protected poc.39 was added from prior payload
identity/hashes and existing production marker compatibility constants.

## Executed evidence

Every test root was created from the runtime temporary directory and a fresh
GUID. Existing guarded fixture cleanup removed only those exact owned roots.
No real project/runtime/config, failed candidate, Provider, worker, watcher,
Supervisor or Unity service was read, started, changed, reconciled or cleaned.

| Declared evidence | Terminal result |
| --- | --- |
| Static/source batch | PASS: 10 changed/new PS sources parsed; 5 changed/new Node sources passed node --check; exact four PS reader bodies retained; 14 PS caller bindings; C# unchanged; Provider helper identical in canonical/poc.39/poc.40 copies. |
| InstanceManifestContractOnly | PASS: ps_cases=45; service_children=0; node_fixture_children=1; elapsed_ms=3903. Node fixture PASS: cases=26, helper_decodes=52, production_callers=2, service_children=0. |
| FirstInstallAttributionOnly | First attempt PASS: cases=26; native_children=0; elapsed_ms=17167. External prerequisite/process collector remain existing fixture seams; attribution, production readers/writers and pre-effect association remain real definitions. |
| NextChangeAdmissionIntegrationOnly | First attempt PASS: cases=45; native_children=0; elapsed_ms=21721; canonical generation=poc.40. |
| test-codedb-package-boundary.ps1 -PathProvenanceOnly | First attempt PASS; helper projections=3, PS decoding/admission bindings=2, Node caller bindings=2. |
| Canonical generation plus source-candidate release-closure validator | Creation/repair route PASS, then final read-only validator PASS; source_count=52, mismatch_count=0. Source-candidate evidence only. |
| Final scoped diff/protection | PASS: tracked owned diff --check; inspected old/new common projection diff preserves path/hash/state guards; protected generations count/hash unchanged. git diff --no-index returns expected 1 for differing generation projections, not a failed diff check. |

The 26 Node byte cases are the same PS production/serializer cases:
six action x PROVISIONING/READY cases; absent/null; eight directly coupled
invalid-origin cases; duplicate/case-ambiguous/top-level origin, unknown/missing
required field, integer type, trailing-content, size, BOM and invalid UTF-8
rejection boundaries. Both canonical and generated Node modules process every
case. Both real caller imports and unconditional call statements are checked.
The selector returns before the old full-harness stubs; no stub replaces the
actual generation reader/context or shared decoder.

L0 attempt accounting, with every failed start retained:
1. Initial semantic start failed in Read-PayloadManifest: newly added helper
   target absent from the audited flat/generation allowlists. Added those exact
   targets in the authorized materializer; this is the one semantic correction.
2. Mechanical fixture path construction stopped before the first production
   writer/Host assertion: instance tmp directory absent. Created it and
   shortened the owned fixture subdirectory to imc for Windows path headroom.
3. Mechanical native-command loading stopped before any Node child/decoder:
   Get-Command node yielded two Application Source paths; an array could not
   name one executable. Selected the first actual Application path explicitly.
   The actual PS boundary had already passed 44 assertions at this start.
4. Corrected run PASS, including the Node decoder and final count assertion.
Thus four physical starts, one corrected semantic attempt and two separately
declared v2 mechanical corrections. No unchanged rerun, failed assertion
suppression, service launch or extra test family occurred. All batches <300s.

Output guard deviation: the early broad source-symbol rg exceeded 50 matches /
16 KiB and reported 25,857 original tokens before truncation. Some initial
combined/slice outputs also truncated. These are TRUNCATED / OUTPUT_GUARD_EXCEEDED,
not retrospectively compliant results. The 128-KiB cumulative inspection guard
was conservatively exceeded; thereafter inspection was restricted to the narrow
source slices, named caller inventory and aggregates already required by this
packet. No whole TASK/session/log dump, broader audit or test replay followed.

## Frozen identity and protected bytes

INSTANCE-MANIFEST-CLOSURE-IDENTITY.txt contains 39 ordinally sorted,
repository-relative path + TAB + lowercase file SHA256 rows, UTF-8 without BOM,
LF separators and final LF. It covers all 13 affected canonical product/tool/test
files and all 26 newly generated poc.40 files. The two handoff records
are excluded from their own recursive identity calculation.

Identity rows aggregate SHA256:
c4a1cfe61877dfce0bd81759840f4b64fd08d1c987b5e9bb76ea1b13be4dba0d
Generation manifest SHA256:
d427ffa383c7de5203637ca16cee5a1480e470c812d30fa523f332d7385d92d3
host-current.json SHA256:
ece8bdb9ca1e265544d9ff749f4aaeff33a5ab112df39a4a06f4f88d7f2604a3
payload-manifest.json / runtime contract SHA256:
709c6225fa2c52ffa0a7c880e26ee6e2769a9fe8a12743dbea5e4e91fa399979

Protected pre-existing generation proof, initial and final (excluding poc.40):
332 regular files; aggregate
502bf6d2e3bbc697ed1d5927deb16274cbbb6ecb76c729b6838af71217c32dc9.
Algorithm is the packet's sorted generation-relative path/TAB/lowercase file
SHA256 rows joined by LF with final LF. No old generation bytes were changed.

Unchanged C# projection SHA256:
34ea23e11d5b0704c57cd4048a1bd9450fd5134780c9b8d504c5ea792b77dcac.
Unchanged Provider helper SHA256, all three copies:
ebcaf8792a5f759ed9639c7250d1d411362ec4a90a32dcbf506020b10fd872be.

## Handoff and acceptance limits

The prior human 18-group / 48-case PASS and first Install exit 6 / 4.95s,
action d8c736504562495dbafdd673c6851efb, cleanup PENDING remain preserved packet
evidence. The actual candidate was never inspected or touched. Human closure
of UnityFreshInstallValidationProjectS29 was reported; no editor/process probe
or control was performed.

This COMPLETE snapshot closes only the authorized source/isolated evidence
outcome. New artifact extraction/byte and consumer closure, human Install /
Ready / Uninstall / Reinstall / shutdown, release acceptance and whole S29 are
unresolved. No Unity/MCP/CUA/BatchMode, machine installation, global/client config,
candidate adoption/cleanup, commit, export, push or publication occurred.

Return this stable snapshot to the parent. A later read-only Verifier may reuse
the attributable evidence and assess the frozen contract/map once. No further
Coder edits or tests are pending; no code or durable-thread messages were sent
to another development task.

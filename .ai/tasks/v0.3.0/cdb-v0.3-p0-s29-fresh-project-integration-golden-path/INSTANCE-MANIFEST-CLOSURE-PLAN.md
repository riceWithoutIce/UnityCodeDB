# S29 Instance Manifest Consumer Closure - Authorized Repair Envelope

Date: 2026-10-07. Status: AUTHORIZED / SOURCE_WINDOW_ACTIVE.
Direct human agreement authorizes the scoped child Coder -> child Verifier
source/evidence/generation sequence below. The human subsequently confirmed
UnityFreshInstallValidationProjectS29 has normally closed. This is not an
external-operation, candidate-cleanup, commit, export or publication grant.
Task remains cdb-v0.3-p0-s29-fresh-project-integration-golden-path.

## Outcome And Frozen Input

Close the same originating_action contract across the existing instance writer,
PowerShell Host context and Node wrapper/worker decoding routes. Prove that
production-emitted manifests cross those real boundaries before any new human
Install. Do not redesign the executor, transport, recovery platform or product.

- Base HEAD: 70f33f7e9f7b39b63aaf9c1d4eedba122f67799a.
- Protected existing generations: 332 regular files; SHA-256 of sorted ordinal
  generation-relative path + TAB + lowercase file SHA-256 rows, joined by LF
  with final LF: 502bf6d2e3bbc697ed1d5927deb16274cbbb6ecb76c729b6838af71217c32dc9.
  Recheck excluding newly created poc.40; never print the whole rows as a log.
- Existing product/tool/test source is clean; unrelated dirty documentation,
  local Unity projects, runtime and prior artifacts remain protected.
- Preserve the human 18-group / 48-case PASS and first Install exit 6 / 4.95s,
  action d8c736504562495dbafdd673c6851efb, cleanup PENDING. No Install retry.
- Current Package is 0.3.0-preview.5, generation poc.39. Proposed successor is
  poc.40 / sequence 40, with Package version and Provider compatibility unchanged.
  poc.40 is absent at preparation; recheck before creating it. An existing or
  changed target requires handoff, not overwrite or an invented alternate ID.

## One Contract And Actual Consumer Map

Use the 2026-10-07 Instance Manifest Contract And Consumer Closure section in
Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md and the
Record Contract Consumer Closure Gate in development-workflow.md.

originating_action is absent/null or an object with exactly action/action_id/
operation_id. Preserve INSTALL/UPGRADE/REINSTALL and lowercase 32-hex IDs.
Attribution is not ownership, selection, readiness or a change permit.

| Boundary | Observed binding / required closure |
| --- | --- |
| Production writer | Tools~/codedb-instance-engine.ps1: New-InstanceManifestDocument and Write-InstanceManifest publish origin before effects. |
| C# projection | Editor/AICodedbProjectIntegrationState.cs: ValidateOriginatingAction already accepts the agreed object. Keep C# source unchanged; preserve its accepted tests. |
| PS Host | Generation scripts/codedb-project-common.ps1: Read-CodedbInstanceManifest currently borrows the flat Provider parser; Assert-CodedbInstanceContext also requires exactly the old 17 fields. Both decoding and field admission must close together. |
| PS callers | prepare, adapter, watch/cleanup, verify and other scripts entering the shared context. Group one shared reader with demonstrated caller bindings; do not individually rewrite every action. |
| Node instance worker | Generation wrapper/codedb-project-instance-worker.mjs: instance.json goes through parseStrictFlatJson before identity/worker checks. |
| Stable Node front door | Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs: selected instance.json also goes through parseStrictFlatJson after selection/hash binding. |
| Other direct readers | Inventory directly referenced reads during implementation; an in-scope shared route may be grouped. An uncovered out-of-scope production decoder returns one consolidated scope request, not silent omission. |

Use explicit instance-contract projections and shared production helpers. Reuse
the existing strict recursive JSON behavior where appropriate; do not replace
it with permissive ConvertFrom-Json/JSON.parse alone. Keep the Provider parser
and manifest contract unchanged. Preserve duplicate/type/size/path/hash/state
checks; support the optional origin rather than dropping or stringifying it.
No dynamic C# compilation/Add-Type source generation is part of the repair.

## Exact Authorized Write Scope

Paths below are relative to com.rice.ai-codedb. Modify only the necessary subset:

- Tools~/materialize-codedb-host-payload.ps1
- Tools~/codedb-instance-engine.ps1
- Payload~/AIWork/codedb/shared/codedb-strict-json.ps1 (new shared pure helper)
- Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1 (new PS projection)
- Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.mjs (new Node projection)
- Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs
- Tests~/test-codedb-host-payload-materializer.ps1
- Tests~/test-codedb-instance-manifest-contract.mjs (new focused Node runner)
- Tests~/test-codedb-package-boundary.ps1 (direct helper/contract assertions only)
- Tests~/test-codedb-package-release-closure.ps1 (existing generator/closure route only)
- Tests/Editor/OwnerIdentityV2Status.json (identity projection via canonical generator)
- Payload~/payload-manifest.json
- Payload~/host-current.json
- Payload~/Generations/poc.40/** (new regular files only)

Use the existing canonical metadata/materialization route. Extend that route
only where necessary to generate the new generation, helper projections and
coupled hashes from one admitted identity input. Generated helper copies must
equal their canonical source; they are projections, not separate authorities.
Do not manually repair independent hashes or introduce runtime generation
literals. Preserve every old generation byte and historical transition record.
The old flat PS common and reviewed Provider contract are not write-allowlisted.

Coder writes only INSTANCE-MANIFEST-CLOSURE-RESULT.md (<=16 KiB) and
INSTANCE-MANIFEST-CLOSURE-IDENTITY.txt here. TASK, plan, workflow, contracts,
roadmap, index, prior results/checklists/reviews remain Planner-owned/read-only.

## One Continuous Non-Unity Evidence Window

Mode: FAST_SUBAGENT / TASK_SPECIFIC, explicitly confirmed by the human.
Parent has fixed the contract, consumer map and successor route; the child
implements this outcome only. No human/runtime/release handoff occurs inside
the source window. Unresolved architecture or required scope expansion stops
the child with one consolidated report; do not spawn grandchildren.

- Coder active budget: 60 minutes. V2_DEFAULT output guards apply; no whole
  112-KiB TASK/session/log dumps. Read this packet plus named contract sections,
  relevant source definitions/callers and fixture/generator helpers.
- Static/source batch: parse changed PS/Node sources and demonstrate the map,
  unchanged C# projection, optional-field handling and all shared caller bindings.
- L0: add one -InstanceManifestContractOnly selector to the existing materializer
  harness. Send real producer/serializer bytes to the new generation's actual
  PS reader/context and shared Node decoder used by wrapper/worker. Include
  valid origin actions, absent/null and directly coupled invalid-origin cases,
  preserving existing rejection boundaries. Test outputs/counts must be exact.
- A Node fixture runner may be a test-owned child of that one focused batch.
  It must not run the worker service, watcher, Provider, Unity or a live wrapper
  against a real project. Show that real callers unconditionally use the tested
  decoder. Test roots are newly created runtime-derived temporary directories.
- Nearest non-Unity regressions: -FirstInstallAttributionOnly and
  -NextChangeAdmissionIntegrationOnly, justified by helper/bootstrap and existing
  writer/cleanup attribution changes. No Supervisor/queue/full-suite replay.
- Focused Package text check: test-codedb-package-boundary.ps1 -PathProvenanceOnly.
- Candidate metadata: one canonical generation/materialization route followed
  by the existing package release-closure validator on the source candidate.
  This is not an export, extracted-artifact closure or release PASS.
- Non-Unity scenarios: initial + at most two causally corrected attempts each;
  mechanical corrections follow existing v2 rules. Batch <=300s; no ownership-
  based process termination inferred from timeout. No blind unchanged reruns.
- Final scoped diff-check and one stable identity handoff. Freeze sorted ordinal
  path + TAB + lowercase SHA256 rows (LF, final LF), including all generated
  successor files and affected helpers. Record unchanged old-generation proof.

## Protected State And Stop Point

No Unity/MCP/CUA/BatchMode, editor/process launch/probe/termination, machine
Provider/Node installation, global/client config, real project/runtime reads,
candidate adoption/deletion/cleanup, existing artifact rewrite, commit, push,
export or publication. Human project closure is not assumed until reported.

Stop on identity drift, existing successor root, required out-of-scope files,
unresolved architecture, unsafe fixture behavior or exhausted attempts/time.
Report COMPLETE only for the bounded source/isolated evidence outcome; real
Install/Ready/Uninstall/Reinstall/shutdown and whole S29 remain unresolved.

After a stable Coder snapshot, the later read-only Verifier checks this map,
original failure and nearest regressions once. It reuses attributable evidence,
returns findings to the user and does not contact/interrupt Coder or rerun tests.
Review PASS does not authorize commit/export or reconcile the PENDING candidate.
Those later stages, exact-artifact closure and one human retry retain their
explicit authorization before any real project change.

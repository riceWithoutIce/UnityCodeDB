# S29 retained candidate recovery - Coder source window

2026-10-09. CODER_STOPPED / READ_BUDGET_BREACH / NO_SOURCE_PASS.
Base: `4ba4ccb6cfc437343c8e4cdc7c45816e4510882e`. No production or test
retained implementation edits, real project/receipt access, processes, Unity, services,
commits, exports or remote writes. Unrelated dirty state preserved.

## Pre-write generated-effect map

Paths below are relative to the exactly attributed candidate instance root.
They are an observed topology supplied by Parent, not current holder/ownership
proof. Actual candidate scripts are under `Payload~/Generations/poc.40/`;
historical generation scripts must be authenticated through the existing
generation reader before using their declarations. Initial mapping examined the
legacy `Payload~/AIWork/codedb/` counterparts before the first classifier draft.
This missed actual generation providerName/runtime-token binding; later direct
generation reads corrected the draft. That is a pre-write mapping deficiency,
not retroactively claimed as full compliance with the frozen sequence.

| Effects | Existing owning producer/declaration | Required classifier proof |
| --- | --- | --- |
| `instance.json` | `Tools~/codedb-instance-engine.ps1` Write-InstanceManifest / New-InstanceCandidate preparation | Existing strict instance/project/generation/origin reader; PROVISIONING, unverified original INSTALL |
| `adapter/text-index/{files.jsonl,index.jsonl,manifest.json}` | scripts/build-codedb-project-text-adapter.ps1 manifest construction and Publish-TextAdapterArtifact; scripts/codedb-project-common.ps1 Get-ProjectCodedbContext fixed paths | Exact three names; schemaVersion=1, adapter=shader-hlsl-text-index, providerName=codedb-<projectSlug>-<instance8> and project-relative output bound to candidate. Manifest has no invented project/instance identity fields. Actual file records/aggregate preserved as effects |
| `config/codedb-mcp.toml` | scripts/prepare-codedb-project-runtime.ps1 -> Sync-ProjectCodedbRuntimeConfig in codedb-project-common.ps1 | Existing runtime template substitutes token instances/<id>; Assert-ProjectCodedbRuntimeConfig validates project-relative storage path. Do not invent generation fields absent from TOML |
| `config/codedb-mcp.watch.toml` | scripts/prepare-codedb-project-watch-config.ps1 Set-TomlSectionValues and final Write-Utf8NoBom | Existing formal config transformed to watch enabled, fixed candidate index path and logs/codedb-watch.log |
| `index/manifest.json`; `index/{deps,fingerprints,index,outlines_index,outlines}.1791454689784.51364.0.bin` | Native Provider 0.5.0-28e3912-c2, pinned src/cache.rs CacheManifest / CacheWriteTransaction::new / manifest_generation_files | Exact six manifest declarations: payload_file,outlines_file,outlines_index_file,fingerprints_file,bm25_postings_file,deps_file. Writer generates index/outlines/outlines_index/fingerprints/deps.<unix-ms>.<pid>.<counter>.bin and bm25.<same>.postings. Require bounded safe exact names from manifest and writer family; no invented candidate/project fields |
| `logs/codedb-watch.log` | Fixed [logging].file declaration in prepare-codedb-project-watch-config.ps1; external Provider owns emitted log bytes | Capture effect only; exact declared candidate path, no successful-execution inference |
| `tmp/native-<32lowerhex>.{stderr,stdout}.log` | Tools~/materialize-codedb-host-payload.ps1 Invoke-BoundedNativeProcessWithFileOutput; engine Invoke-InstancePowerShellScript routes candidate tmp output | Bounded exact token/suffix family, path/no-redirect and deterministic hashes; capture effect only |
| `watch/management.lock` | scripts/manage-codedb-project-watch.ps1 Enter-WatchManagementLock | Exact name; existing ownership/lock safety required before classification |
| `watch/coordinator/coordinator.log` | coordinator/codedb-watch-coordinator.mjs LOG_FILE, context.logPath and appendLog | Exact name; bytes retained, no lifecycle-success inference |
| `watch/lifecycle/desired-state.json` | scripts/manage-codedb-project-watch.ps1 Write-DesiredState | schema_version=1, managed_by, enabled/disabled, actual project_root/project_identity; no fabricated instance identity |
| Prior early lease effects | Engine New/Update-InstanceCandidateEditorLease; existing fixed watch/lifecycle/editor-leases/<32lowerhex>.json route | Existing holder reader, exact bounded bytes; preserve early v2 behavior |

External Provider provenance: `https://github.com/killop/codedb-mcp`, exact commit
`28e3912d5cd67ff3499734984f3e3d626a204796`, `src/cache.rs` lines50-73,
229-255, 803-820. Parent confirmed this direct producer-reference read is in
scope. Two read-only `gh api repos/killop/codedb-mcp/contents/src/cache.rs?ref=...`
calls plus one config-signature reference call decoded returned base64 in
memory and emitted bounded matching lines;
no clone/download/build or upstream writes. Generation token uses now_ms,
process id and atomic counter, not a Unity instance identity.

## Proposed narrow schema2 field projection (not emitted evidence)

Keep the existing resolved-action/index publication route. A new named
`FailedCandidateEffectsRetained` disposition would require common fields
schema_version=2, managed_by, state=resolved, action_id, project_key,
package_key, project_root, package_root, and original receipt storage_layout.
Validate compact-v1 16hex stage and legacy 64hex stage independently using the
original actual receipt route; retain S27 historical rules without broadening.

Bind stage_id, admission_sha256, claim_sha256, terminal_sha256,
command_identity_sha256 and originating INSTALL operation/candidate to the
actual original action/receipt. Bind retained_instance_id,
retained_generation_id, removal_state_id, removal_intent relative path and its
actual SHA256, current desired-state SHA256 and current UNINSTALLED state.
Bind two validated process/holder observations and no-active-authority proof
using existing backend safety and project lock. Preserve command_outcome as
failed/unknown and original output_drain_incomplete; never project a terminal,
PreEffectRefusal, invented EOF or original command success.

The producer must emit only after actual committed confirmed Uninstall and
revalidation under existing index lock. Actual journal/history/session restore
must decode original receipt, referenced real v2 intent/state and exact effect
hashes; marker presence alone is insufficient. Partial publication stays
blocked; explicit same-proof completion revalidates without replaying Install.
The existing cached worker preflight and confirmed Uninstall UI dispatch scope
must release only the matching original action gate after valid disposition.

## Baseline and evidence limits

Source baseline for all 11 frozen allowlisted files captured by SHA256; fresh
`.artifacts/tests/rc41-retained-candidate-recovery/source-baseline.sha256` holds
the exact values. Protected Payload~: 417 files; FullName Sort-Object ordered
relative-name=SHA256 UTF8 LF digest
`d395508812c306439d4c392ab26d492bd2346e579f64c0d563f67a697c7bb84a`.

Read-limit breach: initial complete TASK read was greater than 6KiB; several
later outputs were token-truncated. Original-output token metadata summed to
approximately 51,521 tokens (includes output later capped). No exact <=120KiB
total byte accounting was established, and the run cannot claim that bounded
read envelope. Those partial reads were not complete-source verification.
No retroactive compliance claim. Parent instructed prompt freeze rather than
further implementation; original same-S29 authorization remains for Parent's
separately bounded continuation decision.

Only an unverified 83-line engine classifier draft and one local static
correction were attempted. Both were completely removed using apply_patch.
Final source verification: all 11 allowlisted SHA256 values equal the recorded
baseline (11 files, zero mismatches); git diff --numstat for engine is empty.
Protected Payload~ rehash: 417 files, same digest shown above. The baseline
artifact is therefore also the stable stopped source snapshot, not evidence
of the proposed feature. No tests, compilation, exact Package extraction,
human Unity, runtime, real recovery or S29 acceptance were run/claimed.

## Exact continuation routing and unimplemented consumers

- Engine Get-FailedPreparationEffects line1829, file policy line1868 and nested
  directory policy line1887: own generated-effect names through authenticated
  historical generation declarations; validate actual adapter providerName/output,
  config runtime token, index manifest six filenames and lifecycle project fields.
  Preserve existing 512-entry/128KiB shape and fingerprint; no fake index identity.
- Engine Get-FailedPreparationRemovalAuthority line1999: use actual
  Get-InstanceRemovalIntents line2194 readers to exclude authenticated old closures
  before exactly-one additional candidate selection. Check generation ownership
  against the retained plus new set, not project-wide singularity. Reject every
  additional unknown candidate/authority; preserve original intents byte for byte.
- Engine Get-CurrentProjectRemovalAuthority line5019 and Invoke-InstanceUninstall
  line5048: existing INSTALLED-only selection and null authority for UNINSTALLED
  currently block the diagnosed sequence. Explicit confirmed removal must bind
  the new candidate; automatic cleanup must retain its refusal. The existing
  UNINSTALLED cleanup early return must not consume the new confirmed retention
  transaction. No physical cleanup in this source task.
- Engine Assert-InstanceNextChangeAdmission line3197 and actual
  Get-InstanceRemovalIntent line2065/Assert-FailedPreparationEffects line1968:
  retain shared intent reader/hash inventory at admission, recovery and fresh
  distinct Install handoff; preserve original removal state and failure evidence.
- Materializer Invoke-BoundedNativeProcessWithFileOutput line455 owns capture
  names; Get-HistoricalUnknownActionEvidence line10960 and its process proof
  line11068 are S27-specific and must remain specific. New scoped original
  INSTALL receipt proof is still unimplemented, including writer/child/holder
  absence and two locked observations. Manager terminal producer
  Tools~/invoke-codedb-manager-action.ps1 line381 records writer_pid, child_pid,
  exit_code and output_drain_incomplete; it must remain unchanged.
- Journal ReadResolvedMarker line195 currently recognizes CommandTerminal,
  PreEffectRefusal and S27 HistoricalUnknownReconciled. Its schema decision
  line213, origin receipt validation line375 and failed-install history branch
  line405 need the separate effects disposition projection. Real intent/state
  validation, original result preservation and incomplete-publication behavior
  remain unimplemented; a reader-only synthetic marker is not acceptance.
- ManagerWindow InspectActionRecoveryAsync line509 and existing Uninstall/menu
  route, Actions.RunUninstallCodeDBAsync line186, HostPayloadMaterializer
  ReadUninstallPreflight line171 and EditorLifecycle cached preflight dispatch
  line1498 must carry narrowly matching recovery context and cache availability.
  Explicit recovered-current-effects gate/session result kind remains unimplemented.
- PS tests existing Invoke-FailedPreparationRecoveryCases line652 provides the
  actual engine/transaction extraction seam; native process identities may be
  synthetic, real classification/record decoder bodies may not. Add one focused
  family for two retained closures + advanced outputs/refusals and interrupted
  marker completion, then exact extracted Package execution. Existing C# Manager
  tests contain HistoricalUnknown journal test line1409; add actual emitted-PS
  schema2 record consumption/session/UI tests and directly coupled lifecycle
  cache tests, not fabricated reader-only records. C# source compile evidence
  and human Unity acceptance must stay separate.

The stopped artifacts are the map, proposed field projection and unchanged
source/protected snapshot only. Further implementation and focused acceptance
are entirely outstanding; no independent Verifier source PASS is requested.

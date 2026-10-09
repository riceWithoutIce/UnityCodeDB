# S29 payload admission Coder result

2026-10-09. `SOURCE_FIX_AND_FOCUSED_EVIDENCE_PASS / SOURCE_SNAPSHOT_FROZEN`.
Scope: PAYLOAD-ADMISSION-TASK.md only. Base HEAD:
`8b2061d45504da551b626714a877176051a43fe1`. No new commit was created.
This is a stable working-tree source handoff, not committed delivery or S29
human/runtime acceptance. S29 remains PARTIAL.

## Change

- Materializer: add exactly three flat target strings and three generation
  relative target strings: `native/win-x64/build-manifest.json`,
  `native/win-x64/codedb-daemon-launch.exe`, `shared/codedb-daemon-launch.mjs`.
  No new wildcard or permission derived from manifest declarations.
- `-Action ValidatePayload` uses the existing initialization and actual
  `Read-PayloadManifest -> Assert-TargetRelativePath`, including strict JSON,
  source SHA256, source/target safety and generation-contract validation.
  It exits before Unity/project marker checks, project integration state,
  machine prerequisites, locks, runtime actions, registration or mutation.
  The required ProjectRoot is a caller-owned logical target projection.
- Standard release closure invokes this production subprocess reader before
  metadata projection checks. It emits attributable production-admission and
  byte-closure results, then overall closure PASS only after both succeed.
- The existing export helper requires both attributable PASS markers. The
  unchanged normal export sequence applies it to its commit-stage Package and
  exact emitted ZIP extraction. A validator without the admission marker is
  insufficient for export PASS.
- New focused regression harness retains stage/ZIP/negative fixtures and raw
  subprocess stdout, stderr, exit codes, commands and pre/post snapshots.

## Commands and evidence

All commands below ran from `G:\RiceProgram\UnityCodeDB`, with Windows
PowerShell `5.1.19041.6456`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .artifacts/tests/pa41-baseline/capture.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 -Action ValidatePayload -ProjectRoot G:/RiceProgram/UnityCodeDB/.artifacts/tests/pa41-positive/logical-project
powershell.exe -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-payload-admission.ps1 -EvidenceRoot G:/RiceProgram/UnityCodeDB/.artifacts/tests/pa41-admission-01
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .artifacts/tests/pa41-final/capture.ps1
git diff --check -- com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 com.rice.ai-codedb/Tests~/test-codedb-package-release-closure.ps1 com.rice.ai-codedb/Tests~/export-codedb-package.ps1
```

The baseline capture ran the original real materializer with `-Action DryRun`,
canonical PayloadRoot, and a test-owned logical project containing only Unity
marker fixtures. It stopped on the known admission failure, exit **2**:
`AIWork/codedb/native/win-x64/build-manifest.json` was outside the audited
production allowlist. Baseline payload and logical-project bytes were unchanged.
See `.artifacts/tests/pa41-baseline/{stdout,stderr,exit-code}.txt` and its saved
payload/project/dirty fingerprints.

Focused evidence is `.artifacts/tests/pa41-admission-01/`:

| Entry | Outcome | Saved evidence |
| --- | --- | --- |
| canonical-source | Real reader exit 0; 58 files, all six added targets present | canonical-source.*; six-targets.txt |
| source-snapshot-stage | Export helper -> standard closure -> real reader PASS; byte closure PASS | source-snapshot-stage.* |
| exact-zip | Exact extracted ZIP equals staged snapshot; export helper admission and byte closure PASS | exact-zip.* |
| unknown-flat-reader | Only copied flat target renamed to unaudited adjacent native JSON; exit 2 | unknown-flat-reader.* |
| unknown-generation-reader | Only copied generation target renamed to same unaudited relative JSON; exit 2 | unknown-generation-reader.* |
| unknown-flat-export-gate | Same invalid Package refused by actual export helper/standard closure; exit 1, no export/closure PASS | unknown-flat-export-gate.* |
| unknown-generation-export-gate | Same invalid generation Package refused; exit 1, no export/closure PASS | unknown-generation-export-gate.* |

Every copied negative manifest retains all original source declarations and
hashes; the harness verifies every declared source SHA256 before invoking the
reader and gate. Only its selected target string changed. Negative evidence
records this separately in `unknown-{flat,generation}.source-hashes.txt`.
The production allowlist error is required in each negative result; a later
runtime-identity fixture mismatch cannot falsely satisfy these assertions.

Each reader/gate's exact Windows PowerShell subprocess command is preserved in
its `.command.txt`. Export evidence invokes the existing
`Invoke-PackageClosureValidator` entry loaded via the existing exporter
`-LoadFunctionsOnly` route. It does not run an actual committed delivery export.
The stage fixture is the base commit's `git archive`, overlaid with precisely
the four allowed repair scripts. The ZIP uses the real existing
`New-DeterministicPackageZip` function; its exact extracted file/directory
fingerprints equal the stage fixture. This proves the source-stage and ZIP
gate binding while leaving later commit/delivery to Parent.

Runtime contract SHA256 remains
`c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba`.
Source-snapshot ZIP SHA256:
`9cd3d76dfdccab0bcaa5af0646da75500520ecd963aa603237b6fa180e1eea92`.
Both positive closure logs retain the existing two native `-VerifyOnly` byte
binding checks. No build, launch, daemon execution or duplicated full suite ran.

## Frozen source identity

Paths below are relative to `com.rice.ai-codedb/`. Stable final SHA256:

| Path | SHA256 |
| --- | --- |
| Tools~/materialize-codedb-host-payload.ps1 | 1708bf8df295953c40a3698f6781f7e488076de4516b8b303a529aaaf918e65d |
| Tests~/test-codedb-package-release-closure.ps1 | d5100c392056174746bd63f02766f68d9eac284173173adb30213153650b57f2 |
| Tests~/export-codedb-package.ps1 | c0e4da862e6b3f4e6276dc9ce017d7223ce0ea8cd2a68ce8b8aa90b44c91668f |
| Tests~/test-codedb-payload-admission.ps1 | f142a2bda5bd7f3e83887053ed18ec72c75b2fed374c867c173706a5b5bee2e5 |

Final Windows PowerShell parser checks passed for all four. `git diff --check`
passed for tracked repairs. Proof: `.artifacts/tests/pa41-final/proof.txt`;
harness identity: `pa41-admission-01/source-script-hashes.txt`.

## Preservation, limits and stop

Complete protected source Payload fingerprints, including all flat bytes,
generations/manifests, host-current and transition content, equal the pre-fix
baseline. Whole source Package pre/post validation snapshots are identical.
Every reader/gate's retained fixture Package pre/post file and directory
snapshots are identical; no nonexistent logical projection root was created.
All pre-existing tracked dirty file hashes remain unchanged, including consumer
manifests/settings, except the Parent-owned development-workflow.md deliberately
excluded from child attribution. No child command addressed historical consumer
receipts or failure evidence; existing historical poc.40 evidence remains intact.

Child writes: four allowlisted scripts, this RESULT, and fresh `.artifacts/tests/pa41*`
fixture/evidence files only. No Payload source repair, identity regeneration,
other docs, Editor C#, native launcher/build/caller edits, actual consumer
operations, Unity/MCP, C# compile, Provider, runtime/daemon launch, process kill,
commit, push or tag. No nested agent and no concurrent Verifier.

Process deviations: initial combined read outputs exceeded the 8 KiB bound
and/or were truncated; this breach is acknowledged and not retroactively cured.
The initial baseline collector encountered Windows PowerShell native-stderr
error/wrapping behavior; the final baseline uses raw subprocess streams and
retains the original known rejection. The first focused-harness invocation
failed before fixture creation because Windows PowerShell did not supply
PSScriptRoot to the parameter default; moving default resolution into the script
body fixed that test entry. No production semantic correction cycle was needed.

Coder is stopped at this frozen snapshot. Fresh read-only Verifier may reuse
the saved evidence for the original admission finding and adjacent gate/rejection
regressions. Human Install/Unity/runtime and committed delivery remain separate
unrun gates owned by User/Parent.

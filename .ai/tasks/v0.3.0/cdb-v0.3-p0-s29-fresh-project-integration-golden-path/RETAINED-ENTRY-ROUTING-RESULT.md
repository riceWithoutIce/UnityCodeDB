# S29 retained recovery entry result

2026-10-09. Coder stable snapshot; independent review pending. Base and current
HEAD: `a06944c1cb7e29ff0b2b209eebe6ca4fe502de85`. S29 remains PARTIAL.

## Change and boundary

Added one read-only `UninstallPreflight` case to the UNINSTALLED early switch in
`Tools~/materialize-codedb-host-payload.ps1`. It continues to the existing main
action switch and dedicated candidate/action/process validator. No direct backend
call, altered validator, new schema, generation edit or replay was introduced.
The adjacent confirmed Uninstall still uses its existing early entry and engine
retained-disposition flow. Other actions retain the default no-reinstall refusal.

Added `Tests~/test-codedb-retained-entry-routing.ps1`. The existing retained
fixture builder gained an optional `BuildFixtureOnly` return before any backend
recovery call; its normal existing test path is unchanged. The narrow harness
imports exact production definitions only to prepare fixtures/read results, then
starts Windows PowerShell 5.1 children that invoke the original on-disk production
script with actual CLI parameters. No copied production body is edited or used
as an entry replacement.

## Focused evidence

Command, from repository root:

```powershell
& "$env:SystemRoot/System32/WindowsPowerShell/v1.0/powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File 'com.rice.ai-codedb/Tests~/test-codedb-retained-entry-routing.ps1'
```

Initial harness attempt exited 1 after its first CLI exited 2 because fixture
`Packages/manifest.json` and `ProjectSettings/ProjectVersion.txt` were absent.
Preserved CLI evidence: `.artifacts/tests/s29-entry/r-dd8031a3/`.
One causal correction added those owned Unity marker fixtures. The second
harness attempt exited 0 under PowerShell **5.1.19041.6456**: **22 assertions,
8 actual CLI invocations**. Evidence:
`.artifacts/tests/s29-entry/r-c61f2fc8/` (per-command stdout/stderr and summary).
No second correction or blind retry was used.

| Scenario | CLI exit | Evidence |
| --- | ---: | --- |
| UNINSTALLED/PENDING, matching retained candidate/action | 0 | Dedicated `[REMOVAL_PREFLIGHT] AVAILABLE`; synthetic inventory call observed |
| Unknown retained action id | 4 | Dedicated intent-bound candidate refusal |
| Matching candidate id, receipt action id tampered | 4 | Dedicated BLOCKED; original receipts disagree |
| Relevant process with unobservable command | 4 | Dedicated BLOCKED; live/ambiguous execution refusal retained |
| Uninstall without confirmation | 4 | Existing second-level mutation confirmation refusal |
| Reinstall without confirmation | 4 | Existing second-level mutation confirmation refusal |
| Explicitly confirmed Reinstall | 4 | Existing UNINSTALLED no-reinstall policy refusal |
| Explicitly confirmed retained Uninstall | 0 | `FAILED_CANDIDATE_EFFECTS_RETAINED`, original action disposition |

All seven read-only/refused cases compare complete fixture project and local
receipt file digests before/after and assert byte identity. Confirmed Uninstall
asserts unchanged retained instance effects, prior removal-intent bytes and all
original admission/claim/terminal receipt bytes. Its emitted marker binds the
original action, retained instance, removal state and terminal/intent/desired
hashes. The original terminal remains exit 6, incomplete drain, original failure
stdout/stderr; no successful terminal or EOF is manufactured. Existing production
intent/admission readers accept the resulting links; no pending marker remains.

Native seam is explicit and limited: each CLI runner defines `Get-CimInstance`
for `Win32_Process` only, returning an unrelated synthetic row for clear cases or
a relevant-name row with an empty command line for the ambiguous case. No native
process inventory is read or printed. Real production PID lookups verify the
synthetic dead writer/child identities (424242/424243); no process identity
validator, action/receipt decoder, top-level dispatch, or holder reader is replaced.
All fixture paths are dynamically generated below repo-local
`.artifacts/tests/s29-entry/`; LOCALAPPDATA is temporarily scoped to their owned
manager-local directory and restored. No real project runtime/receipt access,
external process termination, services, Unity, MCP, CUA or BatchMode occurred.

## Snapshot and checks

`git diff --check --` the three changed product/test paths: exit 0. The harness
executes under Windows PowerShell 5.1 and parses its materialized runner and
imported production/helper files there; additional final parser checks passed.
`git diff --exit-code HEAD --` the protected three Payload identities: exit 0.
Fresh SHA256 snapshot (changed product/test paths and protected Payload identities):
`.artifacts/tests/s29-entry/source.sha256`.

The protected identities remain:

```text
c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba  Payload~/payload-manifest.json
ac35dd035c259c65064cc684101b51c3a435ca5cbb55f914d2e6b0d41d274089  Payload~/host-current.json
c9114d7de03ea26520a07d32915c9e62a1a976028ec282051c9a1142a700f7ec  Payload~/Generations/poc.41/generation-manifest.json
```

Existing shared dirty state was preserved. No commit/export, Planner-owned file
edit, engine/UI change, child agent or Verifier messaging occurred. Old PS39/41
and C#32 suites were not rerun. Source/CLI synthetic evidence is not real-project
recovery, Unity compile/EditMode, runtime, consumer/device/performance or release
acceptance. Reference switch/launch and real recovery remain outside child scope.

## Procedure deviations

One bounded source read accidentally included the existing historical-wrapper
base64 fixture line and exceeded the 6 KiB/source-read target. The required full
task-file read was 6153 bytes, also 9 bytes over that target. Neither is treated
as retroactively compliant. Searches stayed at or below 50 matches and total
returned output stayed below 128 KiB. A final `git diff --check` was initially
unscoped and emitted inherited ProjectSettings whitespace diagnostics; it made
no changes, and its exit was not separately captured before the subsequent diff
command. The scoped changed-path check above independently exited 0. No inherited
whitespace or unrelated file was repaired. The Coder work completed within its
30-minute window; no test crossed the 120-second warning or 300-second stop.

Implementation and test edits are stopped for sequential independent review.

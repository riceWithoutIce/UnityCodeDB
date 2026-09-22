# S18 Host Runtime Bootstrap FIX 03 - GUARDED Verification

## Outcome

- Verdict: `FAIL / ADJACENT_EMPTY_RUNTIME_REGRESSION`
- Mode: `GUARDED`, targeted and read-only except for this report.
- Scope: the original FIX 03 bootstrap-proof finding and its directly adjacent
  bootstrap regression only.
- One-time findings: one `P1`; no additional findings were opened.

## Frozen Admission

- Branch: `codex/v0.3.0-legacy-workflow`.
- Expected and observed HEAD:
  `e4ac545e3d1261340c5b757cfa328a0c3296ac1e`.
- The two FIX 03 paths matched the recorded SHA-256 values:
  - `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs`:
    `BB135900D71ADFF24B76D5B285F79FE563140C72F936E884079AB43175C5187C`
  - `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`:
    `0A2737BE7292F04F165D239005091C40E3DBE67CFFDBFE3685BCB5990C0DD08F`

Identity admission: `PASS`. No source, test, or task-record drift was observed
during this review.

## Authorized Review

### FIX 03 existing-runtime proof: `PASS` by source inspection

`IsProvenBootstrapFallback` now rejects an existing runtime containing a
directory, unknown file, operation/claim artifact, or an incomplete state/lock
pair. With both records present it delegates to the strict Package-owned
runtime-contract reader with missing `selected_instance_id` permitted only for
null or a valid instance id, then binds the lock's managed-by/root/runtime/
owner-epoch/PID fields to the authenticated state. The command gate preserves
`materialize/Probe` and `materialize/Upgrade` with
`confirmedProjectMutation=false`, and `Install`/`Reinstall`/`Uninstall` only
with `confirmedProjectMutation=true`. Existing current selection, malformed
selection, or any failed proof therefore remains fail-closed.

### Finding P1 - empty runtime regression

The adjacent test
`SupervisorBridge_BootstrapFallbackRequiresReviewedMaterializerCommandAndEmptyRuntime`
creates the Package-owned Supervisor runtime directory with no entries and
asserts that a subsequent `materialize/Probe` response has
`OneShotFallbackAuthorized == true` (the test's lines 2293-2299). The current
production proof enters the `Directory.Exists(runtime)` branch, finds no
entries, then requires both `supervisor-state.json` and `supervisor.lock` before
returning true (`AICodedbSupervisorBridge.cs` lines 2074-2095). It therefore
returns `false` for that previously accepted empty-directory bootstrap case.

This is a directly adjacent regression, not a theoretical hardening request:
the named EditMode test will fail (and the bridge can proceed into Supervisor
launch instead of returning the authorized fallback) whenever the runtime
directory exists but is empty. The implementation and test contract must be
reconciled while retaining rejection of non-empty incomplete/unknown runtime
evidence.

## Reused Coder Evidence

- FIX 03 static/source assertion batch: `PASS` (reused; not rerun).
- FIX 03 two-path scoped `git diff --check`: `PASS`, exit `0` (reused; not
  rerun).
- Recorded FIX 03 Bridge/Test identities matched exactly as shown above.

## NOT RUN / DEFERRED

- C# compile, EditMode, Unity, Unity MCP/CUA/BatchMode, external runtime,
  Provider, Package-boundary, Node, broad tests/searches, and process probes:
  `NOT RUN`.
- No source/test change was made by Verifier. No command was rerun.
- Commit, tag, push, publication, and promotion: `DEFERRED`.

## Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`.

The FIX 03 targeted review is complete with one adjacent P1 finding. The next
actor is `UnityCodeDB v0.3 Planner / User`, who must decide `FIX / DEFER / STOP`
for this finding before any further routing. Verifier does not contact Coder,
authorize Unity, or perform Git publication.

---

## P1 Repair Re-review - 2026-09-22

### Outcome

- Verdict: `PASS / ORIGINAL_P1_CLOSED`
- Mode: targeted, read-only re-review of the sole finding above and its
  directly adjacent regression only.
- One-time findings: `none` in the authorized re-review scope. No new audit was
  opened.

### Frozen Admission

- Expected and observed HEAD:
  `e4ac545e3d1261340c5b757cfa328a0c3296ac1e`.
- Production Bridge remained byte-identical:
  `BB135900D71ADFF24B76D5B285F79FE563140C72F936E884079AB43175C5187C`.
- Repaired Editor lifecycle test SHA-256 matched the handoff:
  `BAC51945AB50A150CF815412A9AE7AE0FC742A8A92C114384536666B77E317B7`.

Identity admission: `PASS`.

### Original P1 Closure

The repaired adjacent test invokes `IsProvenBootstrapFallback` directly via a
private static reflection helper. The tested path therefore cannot call
`SendCommand`, enter `EnsureStartedAsync`, or otherwise launch a Supervisor.

The test contract now matches production semantics:

- a nonexistent Supervisor runtime remains an admissible bootstrap;
- an already-created but empty runtime directory has no authenticated owner
  evidence and is explicitly asserted `false`;
- `Probe` uses `confirmedProjectMutation=false`, while `Install` is rejected
  without confirmation and admitted with `confirmedProjectMutation=true`;
- a current Package-owned state/lock pair with null selected instance and no
  project current-selection file remains admitted;
- malformed selected-instance evidence, a non-owned lock, an added claim
  artifact, or an existing project current-selection file remains rejected.

The unchanged production reader also preserves the adjacent identity
semantics: bootstrap mode accepts only null or a syntactically valid
`selected_instance_id`; malformed non-null values fail closed. State identity
continues to bind the current Package control/runtime contract, root, project,
generation, namespace, canonical pipe, owner identity/epoch and process
evidence. Lock identity remains bound to managed-by, root, runtime, owner epoch
and Supervisor PID. The exact allowed runtime entry set rejects directories,
unknown entries, operation/claim artifacts and incomplete state/lock evidence.
An existing current-instance selection prevents the bootstrap proof before
those records can authorize fallback.

### Reused Evidence

- Corrected evidence-only static/source contract: `PASS`, 14/14 assertions,
  exit `0` (reused; not rerun).
- Original scoped diff-check: `PASS`, exit `0` (reused; not rerun).
- No test, Unity, process, or external command was run by Verifier.

### NOT RUN / DEFERRED

- C# compile, EditMode, Unity, Unity MCP/CUA/BatchMode, Supervisor/Provider or
  other external process, Package-boundary/Node/broad tests, runtime probes and
  full regression: `NOT RUN / DEFERRED`.
- Commit, export, tag, push, publication and promotion: `DEFERRED`.
- Verifier changed no production or test source and did not contact Coder.

### Handoff

The original `VERIFICATION-06` P1 and its adjacent regression are closed. The
next actor is `UnityCodeDB v0.3 Planner / User`, who decides
`ACCEPT / FIX / DEFER / STOP`. This PASS does not authorize Unity, Git, artifact
or release operations.

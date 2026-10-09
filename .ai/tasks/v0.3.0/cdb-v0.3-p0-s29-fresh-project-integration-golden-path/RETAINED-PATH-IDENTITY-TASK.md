# S29 retained recovery project-root identity correction

2026-10-09. FROZEN / SOURCE_IMPLEMENTATION_AUTHORIZED.
User approved the proposed five-part correction with `同意`.
FAST_SUBAGENT / STANDING_WORKFLOW ACTIVE; sequential depth-one Coder -> fresh
independent read-only Verifier -> Planner/User. Base HEAD:
915a21b8c09aa126bdf757711baa80632c537137. Preserve inherited dirty state.

## Proven trigger and required behavior

Human actual emitted-proof test failed at AICodedbManagerUiTests.cs:1429:
Expected Empty, actual Conflict / Failed candidate intent identity is invalid.
Read-only comparison of the supplied proof showed all intent identity predicates
true except raw project_root comparison: producer uses backslashes and Editor
context forward slashes. Original intent SHA256 matched the marker. Affected
journal, Paths and engine source bytes matched the delivered Package. Desired
state has the same native-path representation. This is a cross-language consumer
gap; previous PS41assertions and source review remain historical evidence, not
successful C# recovery execution.

Repair path identity comparison only for this retained recovery chain. On Windows
accept fully qualified same-project absolute paths with slash-direction, case or
trailing-separator differences. Reject relative, drive-relative, current-drive
rooted, malformed and different-project inputs without deriving identity from
current directory or environment expansion. Reuse AICodedbPaths.NormalizePath
through one comparison entry with explicit absolute-path admission. Platform
semantics must not silently make non-Windows roots case-insensitive.

Normalize for comparison only. Do not rewrite evidence or persisted records.
Keep exact original hashes/fingerprints and full identity/state bindings, owned
path containment/reparse checks and original failed/incomplete result. No new
schema, identity authority, broad path audit, product action or generation bump.

## Frozen producer/consumer map

| Field/record | Production writer | Affected consumer | Evidence |
| --- | --- | --- | --- |
| removal-intent project_root | Tools~/codedb-instance-engine.ps1 New-FailedPreparationRemovalIntentDocument | Journal ReadRetainedEffectsMarker intent identity | actual emitted proof, same-root representations and refusals |
| desired-state project_root | engine existing committed removal/state transaction | Journal ValidateRetainedCurrentState | same committed intent/current-state linkage preserved |
| later activation/operation project_root | engine existing fresh Install transaction | same Journal current-state handoff branch | focused comparison regression without fabricating committed authority |
| disposition marker project_root and project_key | existing materializer retained-effects disposition publication | same Journal ReadRetainedEffectsMarker | real emitted marker, keys and receipt hashes unchanged |
| normalized execution root | Editor AICodedbEditorExecutionContext / AICodedbPaths | above journal checks and session restore | one shared semantic comparison route |

## Ownership and allowlist

Coder may edit only necessary members:
- com.rice.ai-codedb/Editor/AICodedbPaths.cs (shared path comparison entry).
- com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs (retained chain only).
- com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs (focused recovery cases).
- RETAINED-PATH-IDENTITY-RESULT.md in this task folder.
- Fresh ignored .artifacts/tests/s29-retained-path-identity/ evidence/identity files.

Planner owns this task, diagnosis/status/decision, contract/workflow/roadmap and
later delivery records. Verifier owns only RETAINED-PATH-IDENTITY-VERIFICATION.md.
Other source/task/consumer edits and existing exported artifacts remain untouched.
If another consumer/write is necessary, stop and report a scope conflict.

## Focused evidence and stable handoff

1. Same absolute Windows root: native/forward/mixed separators, case and trailing
   separator differences compare equal. Different project, relative/drive-relative
   and current-drive-rooted/malformed input must not compare equal. Keep useful
   tests focused rather than combinatorial parsing/security checks.
2. Use actual production PS-emitted intent/desired/marker bytes with the real
   C# journal/session consumer. Retain the original failure exit6, incomplete
   output and released session; false admission/terminal/intent hashes refuse.
   No test that only implements a second normalization algorithm proves closure.
3. Reuse the existing focused retained-recovery PS harness where necessary;
   synthetic identities/services remain seams, actual writers/readers unchanged.
   Test roots are fresh repository-local directories. Prior delivered short
   proof is read-only while human Unity may still be open; do not mutate it.
4. Prefer an already available isolated C# toolchain for non-Unity focused
   execution. No dependency installation/download or auto Unity/MCP/CUA/BatchMode.
   If unavailable, declare authored/not-run C# tests honestly; human gate remains.
5. Record exact changed-file SHA256 snapshot, base HEAD, commands/evidence classes,
   preserved Payload identity hashes and unrun boundaries. Stop Coder before
   independent review; review only original defect and tightly coupled regressions.

Profile standard: Coder30min; Verifier15min. Existing workflow output limits:
32KiB/200lines command, 16KiB/50matches search/log, 128KiB cumulative window,
RESULT16KiB. Use bounded reads and compact output; preserve any deviation.
Initial evidence attempt plus at most2 causally corrected non-Unity attempts;
no rerun of unchanged passing evidence. Follow existing 120s/300s waits and
report timeouts without terminating outside processes. No nested agents,
commit/export/push, real project receipts/runtime access, process control,
Install/Uninstall/Configure, project reference switch or Unity operations by
children. Original candidates/history stay protected. S29 remains PARTIAL.

## Delivery after source review

Existing pre-human prerequisite authorization covers Planner's scoped accepted
commit, exact new immutable artifact export/byte and focused consumer checks,
input preparation and checklist. Do not overwrite the previously tested Package.
Switch S29 Package references only after its normal-close confirmation. The
previous close confirmation was followed by this human test and is not proof
the project is closed now. No real recovery action or release promotion granted.

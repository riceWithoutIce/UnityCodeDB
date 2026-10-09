# S29 payload admission repair and export gate

2026-10-09. FROZEN / SOURCE_FIX_AUTHORIZED. User approved the bounded plan and
said `好的 请你开始`. Execution: FAST_SUBAGENT, STANDING_WORKFLOW / ACTIVE.
One Coder, then a fresh read-only Verifier. Parent owns workflow/task records.

## Problem and outcome

Commit 8b2061d45504da551b626714a877176051a43fe1 exports poc.41 with valid
source/hash closure but the production materializer rejects the new native
build-manifest target. The launcher harness exercises its production output
collector, not Read-PayloadManifest -> Assert-TargetRelativePath. Current human
gate is blocked at payload admission; prior launch evidence remains valid for
its declared claims. The displayed f14c0524af324b7a802335a393483fa0 result is a
historical poc.40 failure, not evidence of a fresh repaired Install attempt.

Close this one gap: the unchanged canonical payload must be accepted by the
actual production reader; invalid target paths must still be rejected. Every
standard export must run this same read-only gate on the commit-stage package
and its exact ZIP extraction, separately from byte/hash closure.

## Scope and authoritative route

Only add these three audited relative paths to both flat and generation layouts:
native/win-x64/build-manifest.json, native/win-x64/codedb-daemon-launch.exe,
shared/codedb-daemon-launch.mjs. Six target paths total. Keep exact allowlists;
do not derive permission from manifest declarations or add directory wildcards.

Expose a minimal non-mutating validation route in the existing materializer
that invokes Read-PayloadManifest and therefore Assert-TargetRelativePath.
Reuse its real initialization, strict reader, source/hash and target checks.
Stop before project-state reads, machine prerequisites, locks, runtime actions,
MCP registration, or writes. A project path needed for target projection is a
test-owned logical root, never an actual consumer project. No second parser,
copied target policy, generic validation platform, or new contract schema.

Integrate this route with the existing export/closure chain so existing callers
cannot receive export PASS when production payload admission fails. Avoid
duplicate unchanged whole-Package or daemon tests. Emit separately attributable
byte-closure and production-admission outcomes.

## Coder write allowlist

Paths relative to com.rice.ai-codedb/:
- Tools~/materialize-codedb-host-payload.ps1.
- Tests~/test-codedb-package-release-closure.ps1.
- Tests~/export-codedb-package.ps1, only if needed for the gate/result binding.
- Tests~/test-codedb-payload-admission.ps1 (new focused regression harness).

Coder also owns PAYLOAD-ADMISSION-RESULT.md in this task directory and fresh
repository-local .artifacts/tests/pa41*/ fixture/evidence files. No other writes.
Parent owns PAYLOAD-ADMISSION-TASK.md, review/decision records and the small
development-workflow.md amendment. Direct dependencies may be read, not changed.

Protected: all Payload~/ bytes including flat assets, all generations/manifests,
host-current and transitions; native launcher/build/caller; Editor C# and tests;
all consumer project state, manager receipts, historical failures; unrelated
dirty documentation and files. This repair changes Package-side admission only;
no successor or identity/hash regeneration is needed unless actual evidence
proves the protected scope must change, in which case stop for reassessment.

## Evidence and convergence

Use Windows PowerShell 5.1, production subprocess entry points and a test-owned
root under .artifacts/tests. First preserve a compact baseline: current payload
rejected for the known native target with exit 2. Then prove:
1. Actual canonical payload accepted, with all six additions represented.
2. Unknown target rejection in flat and generation layouts, no wildcard bypass.
3. The standard release closure gate refuses the same invalid target, although
   source bytes/hashes remain valid. Only narrowly mutate copied fixture manifests.
4. Validation writes no consumer state; retained fixture/package snapshots prove
   this. Protect source payload/generations and preserve historical evidence.
5. PowerShell parse checks for touched scripts and attributable stable source
   snapshot. No real Install/Uninstall/Configure, Provider, Unity, native daemon,
   C# compile, full suites, old-package compatibility, process kill or broad audit.

Record source and exact-extracted-package checks separately. Coder stops at stable
source/evidence; Parent handles later authorized delivery. Verifier reviews only
this finding and adjacent gate/rejection regressions, reuses saved evidence, and
owns PAYLOAD-ADMISSION-VERIFICATION.md. No concurrent Coder/Verifier, further child,
direct fixer messages, commit/push/tag, or consumer reference edit by children.

One continuous bounded source window, target 30 minutes. At most two same-scope
semantic correction cycles; stop for architecture/scope/protected-state conflict.
Keep reads targeted, output <=8 KiB per call, summarize arrays rather than dump
large files. Result <=12 KiB with exact changed-file hashes and evidence paths.
Completion: original admission blocker and adjacent focused checks pass; no
new broad audit. S29 remains PARTIAL until separate human/runtime acceptance.

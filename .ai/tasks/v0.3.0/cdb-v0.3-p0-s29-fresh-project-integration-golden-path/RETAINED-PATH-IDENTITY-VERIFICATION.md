# S29 retained path identity scoped verification

2026-10-09. Fresh independent depth-one Verifier. Coder stopped before review.
Verdict: **PASS — scoped source review and existing focused evidence review**.
Original raw-root representation blocker is closed at this source/evidence
scope. Human journal/session execution remains DEFERRED; S29 remains PARTIAL.
No actionable finding on the original defect or its directly coupled regressions.

## Stable snapshot admission

- HEAD: `915a21b8c09aa126bdf757711baa80632c537137`, matching frozen TASK/RESULT.
- `.artifacts/tests/s29-retained-path-identity/source.sha256` has six rows;
  SHA256 `ce279752444a8708257694da183bd156b8738ce03693866d3e1059b75e80eb2e`.
- All six actual file hashes match, checked at admission and again before this
  report. Three changed source/test files match RESULT; three protected Payload
  identities match RESULT and have no diff against HEAD.
- Scoped diff: Paths +45 lines; journal four comparison substitutions;
  ManagerUiTests +74/-2 lines. No source/test/fixture mutations by Verifier.

## Original defect and coupled behavior

`AreSameAbsoluteProjectRoot` admits the absolute path before `NormalizePath`,
so Windows relative, drive-relative, current-drive-rooted and the focused
malformed examples cannot gain identity from current directory. Same absolute
roots accept separator direction, case and trailing separators; non-Windows
comparison remains ordinal. Normalization occurs only in memory.

All four affected comparison sites use that shared entry: disposition marker,
removal intent, desired state, and the activation/operation loop. The four-line
journal diff preserves project/package keys, original record hashes,
fingerprints, containment/reparse checks and instance/generation/ownership
bindings. Fresh handoff still requires a different selected instance,
READY/INSTALL origin, committed activation/operation, matching epochs,
candidate hashes and wrapper handoff evidence. This branch was source-reviewed,
not executed or granted fabricated selection authority.

Authored human tests are meaningful: the original actual PS proof test still
asserts outer journal Empty, retained historical failure, exit 6, incomplete
drain, non-authoritative terminal, original stderr, and released recovery via
`RestoreDurable`. Added equivalent-context tests leave authenticated records
untouched. Marker/intent/desired wrong-root tests rebind the affected hashes,
isolating root refusal from hash refusal; original admission/terminal/intent
hash tampering cases remain. A finally block restores fixture bytes and checks
terminal preservation. Helper tests cover mixed separators, symmetry,
case/trailing forms, different roots and relative/drive-relative/rooted/malformed
inputs, plus non-Windows case sensitivity. These NUnit methods were NOT RUN.

## Evidence classification

Reviewed existing writer wrapper, extracted C# harness and logs without reruns.
Windows PowerShell writer log reports PASS39, native children 0, and actual
emitted retained proof; wrapper stops before subsequent fresh Install. Initial
pwsh writer failure remains recorded. `run-csharp.ps1` extracts current method
bodies with Roslyn and includes the actual strict JSON, context/result,
receipt-key helpers, retained reader and validation helpers. Its service/Unity
seams are explicit; current-instance Read throws for the unrun INSTALLED branch.
`ReaderChecks.cs` calls `ReadRetainedEffectsMarker`, checks preserved failure,
normal equivalent roots, independent root refusals and three hash refusals;
`csharp.log` reports PASS32 and explicitly marks Unity/session/INSTALLED NOT RUN.
This supports the original consumer comparison repair, not full Editor build
or full journal/session/product acceptance. RESULT states these limits honestly.

DEFERRED / NOT RUN: full C# package/Unity compile, authored NUnit execution,
outer journal Read, session RestoreDurable, fresh committed INSTALL authority,
non-Windows runtime execution, real S29 recovery/integration and release.
No tests, Unity/MCP/CUA, real receipts, process control, commits or exports were
performed by Verifier. Findings return to Planner/User once; no Coder contact.

## Review deviations and stop

RESULT's disclosed Coder mechanical attempts/output breaches are retained;
review PASS does not retroactively certify those budgets. Verifier's initial
parallel memory/task reads exceeded the 6 KiB combined packet aim and a memory
search was truncated; a later three-log combined packet also exceeded 6 KiB.
Subsequent source packets were narrowed. Cumulative returned output was not
byte-metered and likely exceeded the aimed <=48 KiB total; no cumulative
budget-compliance claim is made. Initial hash-row
lookup omitted the package-relative prefix, produced missing-file diagnostics,
then was corrected with explicit `com.rice.ai-codedb/` resolution; all six
hashes matched. This was a read-only admission correction, not a test retry.

Original blocker assessed; stop this scoped review. Planner/User owns the
separate immutable delivery and human compile/test gate under frozen TASK.

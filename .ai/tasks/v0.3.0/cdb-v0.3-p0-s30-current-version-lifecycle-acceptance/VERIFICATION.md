# S30 current-version lifecycle — independent source repair verification

Date: 2026-10-15 (Asia/Shanghai)  
Base: `5b52c017e8415bb061f33a8380b3dcec2916411a`  
Disposition: **SOURCE_AND_ISOLATED_PASS**  
Findings: **0 BLOCKER, 0 FOLLOW-UP** within this guarded source-repair scope.

## Admission and boundary

The S30 TASK, authorized source-repair packet, complete Coder RESULT repair
section, direct producer/consumer source, and nearest recovery/UI contracts were
read after the Coder stopped at a stable handoff. This review is read-only. No
source, TASK, RESULT, accepted ZIP, S30 project or prior evidence was edited;
no test, Unity, real preflight, uninstall, reinstall, probe, process, cleanup,
export or commit was run. The only write is this report.

The six allowlisted files independently match the frozen Coder hashes:

| Path relative to `com.rice.ai-codedb` | SHA-256 |
| --- | --- |
| `Editor/AICodedbEditorLifecycle.cs` | `86dc783bd612c35d6c973007e665688785b9465d479186398a268ca3865f71bf` |
| `Editor/AICodedbHostPayloadMaterializer.cs` | `8c42c3f094b443245189487229f8f6effc7a461c93bea02b5d4068d09b93d1f5` |
| `Editor/AICodedbManagerWindow.cs` | `a0e63aeb58b9960780a14d54c9226f311757f713e6c05c68db7e5b6d8a2e678c` |
| `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs` | `49612f1e4a4bcb80bce559c6ac86e612891307ad45726fe2206015497d8847d7` |
| `Tests/Editor/AICodedbManagerUiTests.cs` | `a95bea3e96c2d2931ae7da947b4df48b40ab7afc0ee7fc1032b0050e5577d13e` |
| `Tests/Editor/AICodedbEditorLifecycleTests.cs` | `be61964b76445d442d5956e5f89d54c53bbaaf046e5088038cfc87a8db1395af` |

Evidence root: `.artifacts/tests/s30-uninstall-admission/coder-a1`. Its 47-entry
evidence manifest independently hashes cleanly. `protected-comparison.log`
reports 1,649 protected entries unchanged; the before/after snapshot files also
match. HEAD and index remain the admitted base and empty respectively.

## Contract and source review

`HasUninstallPreflight` now validates the normal producer contract directly:
successful, complete, non-overflow output containing exactly one exact
`[REMOVAL_PREFLIGHT] AVAILABLE` classification. Blocked, duplicate, malformed,
empty, timeout/overflow and incomplete output are refused. The action-aware
lifecycle projection calls this classifier for `UninstallPreflight`; the
existing authenticated handoff parser remains required for
`RemoveIntegrationPreflight`. The producer's exact shipped branches and the
explicit retained-candidate process-proof path remain unchanged.

Manager presentation now separates visibility from admission. Ready, known
current installed and explicit reinstall-required states keep their applicable
removal entry while preflight is pending/refused or an action is active; the
entry is disabled and gives a bounded cached reason, with a header help row for
the same state. Missing/not-integrated evidence does not fabricate an installed
state. Ready remains Ready when a new removal preflight refuses. No filesystem,
PowerShell or Node work was added to menu/header construction.

True action execution and recovery inspection remain disabled while running.
An attributable retained recovery session is projected separately from a live
action, so the existing confirmed failed-candidate Uninstall proof path can
proceed only after its normal preflight admits it. Confirmation and execution
time backend locking, ownership, handoff and transaction checks remain intact.

## Focused evidence inspected

| Gate | Result |
| --- | --- |
| L0 syntax/scoped diff/Package path provenance | PASS — `l0-a1.log`, `l0-a2.log`, `path-final617.log`, `source-overlay-check.log` |
| Original-byte Editor and complete Editor.Tests compile | PASS, exit 0 — compile logs and response inputs; only existing Manager warnings |
| Actual shipped producer branches | PASS — `producer-a1.log`, `producer-a2/*.stdout`/`*.stderr`; seven normal/recovery modes, `native_children=0` |
| C# parser/cache/menu/confirmation seam | PASS — `seam-run-a1.log`, exact 34-member binding; native GUI/backend authority not run |
| Protected state and exact six-file/617-path overlay | PASS — `protected-comparison.log`, `source-overlay-check.log`, independent hashes |

The producer fixture executes the exact source AST clauses for normal
`UninstallPreflight` and recovery `RemoveIntegrationPreflight`; it does not
hand-build an AVAILABLE line. Synthetic authority dependencies are explicit,
and the evidence does not claim backend ownership. The seam covers normal
success/refusal/malformed/duplicate/incomplete output, action-route separation,
pending/refused/busy visibility, bounded reason text, Ready preservation,
no-integration non-actionability, confirmation cancellation and one confirmed
dispatch. Recovery missing/invalid/valid handoff checks and nearest existing
redaction/cache assertions remain exercised.

## Attempt and acceptance limits

The first producer helper selected an earlier same-name switch; its empty
outputs are preserved. One AST-selection-only correction selected the unique
actual AVAILABLE emitter; no product source correction followed. The initial
test compiler helper stopped at S30's absent test response input; a separate
explicit rebinding helper compiled the full Editor.Tests assembly. The same
known helper boundary appeared once during the final Editor-only recompilation;
it is not a product compile failure or hidden test result.

The human-opened canonical extraction contained one generated test `.cs.meta`
file absent from the frozen 617-file ZIP. Its actual S30 GUID/hash was recorded;
the canonical tree stayed untouched and the final owned overlay contains the
exact 617 ZIP paths. Final source correction compile/seam ran on that final 617
tree; no semantic or runtime claim is based on the earlier 618-file tree.

The first Install/Ready checkpoint remains the prior human-owned S30 evidence.
Normal uninstall and reinstall are still paused and unrun. Unity/EditMode,
native GUI, real backend authority, actual lifecycle mutation, availability
after reinstall, process/device/performance and release acceptance remain
separate downstream gates. These limits are explicitly retained and are not
findings or waived gates.

No further in-scope review work remains. Findings are returned once and review
stops; source acceptance, delivery and resumption of the real lifecycle remain
with the parent/User gates.

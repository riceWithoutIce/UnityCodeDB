# S29 short-command launch selection and bounded POC

2026-10-08. User approved the responsibility-first repair plan including isolated
implementation comparison before production scope freeze. State: POC_COMPLETE /
REJECT_DIRECT_HELPER_SWAP. The original limited approval below is retained as scope
history; it does not authorize another run. See INSTALL-OUTPUT-LAUNCH-SELECTION-RESULT.md.
FAST_SUBAGENT / STANDING_WORKFLOW, single diagnostic child, no further delegation.
No production implementation is authorized by this selection packet.

## Baseline and candidate screening

Problem: exact delivered Start-Process file-output launcher plus actual Manager
writer fails to complete output while a normal detached Node daemon survives.
Baseline proof: INSTALL-OUTPUT-REPRO-RESULT.md, sandbox995de5da. No baseline rerun.
Source inspected: shipped Invoke-BoundedNativeProcessWithFileOutput and existing
Invoke-BoundedNativeProcess, one-shot writer, Node daemon startup, reproduction
scripts. Runtime evidence: Windows PowerShell5.1 and installed Node24.14.1.

| Candidate | Purpose/support/distribution | Storage/isolation | Benefit and risk | Decision |
| --- | --- | --- | --- | --- |
| Existing Start-Process file redirection | Shipped WinPS5.1 implementation, no new dependency | Existing bounded sandbox | Known failing detached topology; no change cannot resolve it | Baseline only |
| Existing ProcessStartInfo pipe launcher | Existing Package/.NET implementation, same WinPS runtime, no compiler/download | Same sandbox and fixture-owned processes; process-local environment | Removes intermediate redirected-file writer; both-layer isolation remains unproved until POC | Limited POC |
| Native explicit handle-list launcher | Potential low-level handle control | Would require reviewed build/distribution/interop route | Higher complexity; no supported route screened for this task | DEFER, no POC |

No new broker/service, Node runtime download or generic executor platform is selected.
The small credible candidate set follows the no-new-component constraint.

## Early gates for existing ProcessStartInfo POC

| Gate | Result and evidence |
| --- | --- |
| Target support | PASS: already implemented in delivered PowerShell/.NET source |
| Distribution/build | PASS: exact Package AST function import, no new build/dependency |
| Generated-data boundary | PASS: fresh exclusive .artifacts/diagnostics/io/<short-id> |
| Ignore/isolation | PASS: git check-ignore confirms diagnostics evidence excluded |
| Side effects | PASS within scope: test-owned processes only, no network/credentials/live runtime |
| Repeatability/removal | PASS: prior sandbox harness/receipts and cooperative-stop/self-expiry reused |
| Integration boundary | PASS: only fixture control launcher selected; unchanged Manager/daemon |
| Baseline advantage | PASS as hypothesis: avoid intermediate file redirect resource lifetime; actual correctness pending |

## POC execution

Create a fresh exclusive sandbox; preserve995de5da exactly. Use its actual-writer
fixture recipe and unchanged leaf/Node bodies. In the new fixture control import
the delivered Invoke-BoundedNativeProcess and required actual helper bodies.
Never execute materializer top level. This compares an existing implementation,
not a hand-written successful substitute. Preserve source hashes/AST extents.

Initial two scenarios: baseline leaf and normal detached daemon. Keep normal daemon
alive through native return and actual Manager terminal/EOF; check its exact owned
PID/start/token at that checkpoint before cooperative stop. If normal case succeeds,
run intentional inherited-output retention to verify failure remains bounded.
At most one causally justified diagnostic follow-up, no generic matrix or repeated
unchanged PASS. Outer bound60s/run, daemon self-expiry35s, total window20minutes.
No daemon early exit as a success workaround. No silent widening of function limits.

All TEMP/TMP/LOCALAPPDATA overrides child-local under sandbox; do not repurpose HOME
or CODEX_HOME. Hidden windows, exact PID/start/token/path ownership, cooperative
stop before any exact-owned fallback. Do not kill by name or scan unrelated process
trees. No runtime C# compilation/Add-Type source, handle scanner, downloads, Unity,
MCP, Provider, S29 files/receipts, actual install/uninstall, production edits, commit
or Package export. Retain evidence and report any remaining process without lying
about cleanup. Use apply_patch for fixture script edits.

## Handoff and decision

Child owns INSTALL-OUTPUT-LAUNCH-SELECTION-RESULT.md plus fresh sandbox only.
Report exact source/function hashes, bounded timelines, daemon-alive-at-completion
proof, native/Manager exit/incomplete/EOF and final PID audit. Existing pipe helper
may have separate limitations (e.g. size/encoding); a normal-case pass only supports
integration planning and does not automatically approve all its behavior as-is.
If candidate fails, stop with comparison evidence; do not escalate to native/extra
components without a new reviewed choice. Parent alone updates task/contract.

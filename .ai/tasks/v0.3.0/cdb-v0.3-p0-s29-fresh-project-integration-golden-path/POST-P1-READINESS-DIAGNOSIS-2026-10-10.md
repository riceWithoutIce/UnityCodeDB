# S29 readiness after P1 repair: read-only diagnosis

2026-10-10, Asia/Shanghai. Source baseline `9a2ca41e19baf125cae594eb10ceef6b28cfef9b`.
Result: a concrete transport-to-invalid-contract classification path is identified;
the latency source of the photographed IPC timeout is not uniquely established.
No source repair, commit, export or runtime operation was performed in this slice.
S29/release remain PARTIAL. The separate one-attempt human normal-close PASS is
retained in UNITY-CRASH-P1-HUMAN-RESULT.md.

## Attribution and inspection limits

- Manifest and lock select `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-unity-crash-p1-9a2ca41/review/com.rice.ai-codedb`.
- ZIP SHA256 was re-read: `153816dd39868a104937f193147b1322d51f1645461684f22bfcf754a1f3b597`.
- ControlContract, SupervisorBridge, EditorLifecycle, ManagerWindow and the
  Supervisor tool each match the selected extracted package byte-for-byte.
  Editor/Tests diff and staged index are empty; unrelated dirty state is retained.
- The supplied Manager screenshot was inspected directly. It shows an IPC timeout,
  control-contract review required, and retained terminal convergence failure with
  `COORDINATOR_OPERATIONAL`, observation `070d3698a9c745b2aac8c13790823658`, revision
  84, owner epoch `b6e25d65d954454e9a904b3ef9787f46`.
- The currently retained shared Editor-prev.log points to the earlier
  `s29-optional-flat-compile-poc42` package. Current Editor.log no longer supplies
  the earlier S29 checkpoints. Neither file establishes a new per-reconcile
  sequence for the repaired package. Prior attributed Editor findings remain
  prior recorded evidence, not a fresh re-verification here.
- Earlier broad log reads produced truncated output, and one structured extraction
  had a PowerShell parse error. They are not used as repaired-session evidence.
  Conclusions below use the exact four operation documents, bounded event and
  coordinator tails, the screenshot and attributable package/source inspection.
- Existing `handoff_audit` agent is completed; its read-only handoff result was
  consumed. No new child was dispatched. No MemPalace server is available; local
  memory was used only for workflow boundaries, verified against current handoff.

## Repaired-session durable sequence

Evidence root: `UnityFreshInstallValidationProjectS29/AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor`.
Times below are UTC. Each listed operation has lane maintenance, state completed,
exit 0, `result.timed_out=false`, empty stderr and stdout PRODUCT_STATE READY.

| Operation id | Command | Started | Completed | Operational observation |
| --- | --- | --- | --- | --- |
| d1fab6283a594f868e66d5793d915706 | Probe | 05:53:58.500 | 05:54:04.760 | core_ready, revision 6 |
| c01adf2a56b94aba92346cb2138ab73d | Upgrade | 05:54:09.978 | 05:54:25.152 | no observation marker in retained stdout |
| 977ea51c970849669e09fdbf5206a7b7 | Probe | 05:54:26.711 | 05:54:32.578 | core_ready, revision 43 |
| f1fc21ae529b494e96efd708041ccf28 | Probe | 05:55:00.727 | 05:55:09.587 | core_ready, revision 84, screenshot observation id |

Upgrade reports CONVERGED / INSTANCE_CURRENT, no mutated scopes and cleanup
PENDING. The three Probes report all four product layers CURRENT. Revision 84
was observed at 05:55:00.741; completion time is not its observation timestamp.
These records establish backend results, not receipt of every IPC response by
Unity and not continuous availability after completion.

Coordinator log records lease reclamation at 05:56:36.585 and
`coordinator_stop reason=last_editor_lease_gone exit_code=0` at 05:56:36.707.
Supervisor event 10 records `supervisor_retiring / coordinator_offline` at
05:56:42.499; event 11 records queued-query epoch invalidation at 05:56:42.502.
This supports lease-loss retirement as the cause of those final two events.
Without the original precise Unity quit timestamp it does not independently
prove whether lease loss began during shutdown or before it. It cannot explain
the earlier screenshot merely by occurring later.

## Concrete classification mechanism

1. `AICodedbControlContractMigrationStore.Read` calls InspectNamespace. Once
   stored selection/owner evidence and process identity pass, ValidateCurrentNamespace
   requires a fresh authenticated pipe status as a second factor (ControlContract.cs
   1330, 1612, 1633). This is real IPC, not a disk-only read.
2. SendPipeRequest limits the write/read exchange to 1500 ms. TimeoutException
   contains the exact photographed diagnostic (SupervisorBridge.cs 2438, 2540,
   2556). InspectNamespace catches every Exception and classifies it Invalid
   (ControlContract.cs 1269); Read then returns invalid/ambiguous control status.
   Thus transport failure can become structural-invalid status without evidence
   that the stored contract itself is malformed.
3. TryResolveControlContractMigrationBlock can subsequently run a Probe. Even
   when prerequisite evidence is current, it retains the earlier migration
   failure and blocks product layers (EditorLifecycle.cs 1614). A successful
   Probe is not used to re-authenticate the failed migration check.
4. RememberLifecycleProductStatus binds that product failure to the successful
   Probe's operational marker. TryCreateTerminalConvergenceFailure rejects
   `result.TimedOut`, but does not reject successful Probe + CoreReady observation
   when the product status is NeedsAttention (EditorLifecycle.cs 3214, 3410).
   The resulting retained failure can use reason COORDINATOR_OPERATIONAL and
   require a newer authenticated success to clear (3503).
5. This path explains the photographed combination: timeout in migration
   diagnostic, successful operational observation revision 84, yet retained
   terminal failure. The original timed-out request is not identified in durable
   operation documents, so this remains a source-established path matching the
   evidence, not a trace of every executed branch.

Independent semantic gap: Supervisor result JSON includes `timed_out`, but Bridge
does not parse it; ToCommandResult always sets TimedOut false (412). Generic IPC
exceptions also lose their timeout classification. Fixing this alone would not
fix migration Read, which catches the exception through a separate route.

## Freshness, reopen and latency hypotheses

- Manager Ready expires after 30 seconds and falls back to Starting. This
  display expiry does not itself request reconnect (ManagerWindow.cs 702, 3381).
- Scheduled reconcile has its own 30-second cadence. Reconcile completion queues
  a non-forced reconnect (EditorLifecycle.cs 614, 722). Reopen resets the window
  cache revision and reconstructs its display from persisted/cached evidence;
  it does not establish a fresh authenticated Ready result by opening the window.
- Reconnect cancellation applies to a local connection worker; it is not evidence
  that an external Supervisor was stopped. No claim that reconnect caused the
  observed retirement is justified here.
- Supervisor serializes refresh/status/operation queries via queryRunning.
  Internal coordinator status can spend the same 1500-ms budget as the outer
  Bridge request (Supervisor tool 33, 1159, 1514, 1522, 2474). A query queued
  behind a slow internal refresh therefore has no guaranteed budget margin.
  This is a concrete timeout mechanism, but the exact slow request is untraced.
- ReadBoundedUtf8Line performs one asynchronous read per byte under that shared
  deadline. Its actual cost was not measured; do not claim it caused this report.

## Proposed next source slice, pending User disposition

Primary target: distinguish temporary failure of live contract authentication
from proven malformed/foreign/ambiguous contract evidence. Temporary uncertainty
must refuse new mutation/start admission, use bounded retry/Starting semantics,
and become explicit NeedsAttention if the observation window is exhausted.
Successful same-context authentication must clear the transient observation;
old Ready must never be renewed or pinned to mask failure.

Candidate files are AICodedbControlContract.cs, AICodedbEditorLifecycle.cs and
their directly affected Editor tests. Include SupervisorBridge.cs only for the
adjacent explicit timeout-provenance gap if frozen into the accepted slice.
Do not add query-queue redesign, timeout extensions, payload/generation changes,
cleanup policy changes or broader Manager refactoring to this fix.

Focused verification should cover transport timeout versus malformed/foreign
authority, timeout followed by authenticated success, bounded exhaustion,
successful CoreReady proof not being mislabelled as a transport-caused terminal
convergence failure, existing terminal-failure retention, unchanged freshness,
and Manager cache reconstruction on reopen. Test the actual classification and
publication path, not only unused presentation predicates.

No new tests were executed in this diagnostic slice. After User authorizes the
frozen repair, follow Coder -> stable snapshot -> independent read-only Verifier
-> User disposition. Commit/export/reference switching and human Unity acceptance
remain separate later stages; no new package is prepared by this proposal.

No Unity launch/control, MCP/CUA/BatchMode, Install/Uninstall, manual index release,
receipt rewrite, runtime cleanup, process stop or source modification occurred.
The only workspace edit in this slice is this diagnostic record.

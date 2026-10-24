# S40 bounded independent verification

Review date: 2026-10-21. Mode: GUARDED, read-only source/evidence review.
Verdict: FINDINGS; one P1 / BLOCKER normal-user-path admission defect.
The declared single-cycle HARNESS result is supported; this is not a real
lifecycle, delivery, release or physical-cleanup acceptance.

## Admitted source identity

- Source checkout: `<repository-root>/.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission`.
- Base and HEAD: `c848049d90fbdf618905be25225580642d98d987`.
- Branch: `codex/retained-mcp-install-admission`.
- Stable uncommitted snapshot: the four files in SOURCE-SHA256.json, all matched
  by independent SHA-256 reads before semantic review.

| Repository-relative source | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `227e64df16cbb13484d8b29744002193fdc76efed0b2c0b8d0a189cb972d4583` |
| `com.rice.ai-codedb/Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md` | `3b09c957860533b3fd82141f564a32f9147123637843755aa748f824fba93b7e` |
| `com.rice.ai-codedb/Tests~/test-codedb-retained-mcp-install.ps1` | `b5f661f4b2c03ebf63ebc510a4f28fa3a4a384d2b2f17d3e8dd1160673a1a50f` |
| `com.rice.ai-codedb/Tests~/test-codedb-retained-mcp-install.mjs` | `6dfae913d97e220b3bad0309e64a6b647d3dbb6648e4f5a9fd60f41e9b296df2` |

The final harness manifest's six production dependency hashes also match the
reviewed checkout. The unchanged poc.44 worker hash matches worker-result.json:
`5578c9baec9968402296351c86dbecd14691871488aa73539a99e98735a94ea1`.
SOURCE-SHA256-01.json records the same worker harness source hash as the final
snapshot. The tracked diff and two new tests were read, with direct helpers
only; no broad audit was performed.

## Finding returned once

### F1 - P1 / BLOCKER: an older retained reader blocks the next fresh Install

Location: `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1:4953-4956`;
caller: the all-retained-instances loop at lines 5026-5041.

Trigger: install instance A, keep its positively identified MCP reader connected,
logically uninstall A, and successfully fresh-install same-Package instance B.
Then logically uninstall B while A's reader is still connected and separately
confirm another same-Package Install. No unknown process, failed preparation,
foreign generation, current/LKG selection or runtime writer is needed.

The new helper always loads the removal intent using the *latest desired-state*
StateId (line 4953), then requires that intent's InstanceId to equal whichever
retained instance the caller is currently checking (line 4954). The first fresh
activation creates a new StateId while retaining A's original intent
(lines 3594-3598). Uninstalling B publishes B's normal intent under that new
StateId (lines 5705 and 5712-5729). A's intent and live lease remain retained:
Get-InstanceCleanupState marks removal-intent instances pending
(lines 4459-4477), and Uninstall returns before downstream cleanup while that
instance accounting is pending (lines 4521-4526).

The next admission enumerates both authenticated removal closures. When it
reaches A, whose holder is still live, Get-InstanceRetainedMcpInstallHolders
loads B's intent and deterministically throws the normal-uninstall-closure
mismatch. Thus the fresh Install path becomes unavailable solely because a
known, same-Package, isolated old MCP reader remains. The user must drain that
external connection before installing again, contrary to the frozen contract's
statement that a live lease may delay cleanup indefinitely without forcing the
user to wait before fresh installation (contract lines 150-164, 193-207).

This is a source-derived finding in the changed admission helper and its direct
lifecycle consumers. It was not reproduced by running a new test or a real
client. The existing harness stops after the first successful fresh activation
(PowerShell test lines 117-128), so its 29-check PASS does not exercise this
trigger. BLOCKER is used because this is a normal repeated user lifecycle that
cannot complete, not a speculative race or a demand for additional test breadth.

## Supported claims and inspected evidence

Raw records are beneath
`<repository-root>/.artifacts/tests/s40-retained-mcp-install/`.

- `cleanup-accounting-ps51-a/result.json`, `run.log`, `manifest.json`, and
  `cleanup-observation.json`: the recorded full PowerShell 5.1 harness passes
  29 checks. It covers one known-reader uninstall/fresh-install cycle, distinct
  instance/epoch, failed candidate preserving UNINSTALLED/no selection, exact
  old file hashes/removal intent, and retained deletion-holder refusal.
- The observation records versioned cleanup COMPLETE, instance/command/desired
  cleanup PENDING, and both old intent and old lease present. The first activation
  reports command and desired cleanup COMPLETE. The extra accounting call at
  engine lines 4598-4605 is after existing versioned retirement and does not
  supply PerformCleanup; deletion implementations and holder-clear authority
  are unchanged.
- Admission rejects unknown start/invocation, foreign lease/wrapper, conflicting
  or absent intent, selected predecessor, live Editor/coordinator, other
  generation, failed preparation and competing project execution in the named
  receipt. The source requires exact process-start matching before adding an
  exempt PID; invalid/live writer evidence throws. The returned PIDs only skip
  the competing-execution inventory check. No process-stop function was added.
- `s32-regression-a/run.log`: prior 25-check safety receipt, including incomplete
  histories, unattributable writers and conflicting Supervisor authority. The
  underlying history validation remains present after the changed holder loop.
  This prior receipt is not a rerun against the final accounting amendment.
- `l1-ps51-b/worker-result.json` and `worker-run-c.log`: six prior original-worker
  function checks. The worker's createContext binds config/index/lifecycle and
  coordinator paths to the supplied instance root; request generation uses that
  instance's manifest, not a newly selected pointer. The VM harness exercises
  requests across removal/new selection, distinct old/new paths, and refusal of
  the old unavailable runtime query without IPC. It does not run a real MCP
  transport or establish query availability.
- `l0-ps7-a/run.log`: PowerShell 7.6.5 terminates before admission assertions with
  `payload manifest must contain one JSON object.` No PS7 PASS is admitted; the
  separate compatibility repair is outside this review.

No other actionable in-scope findings were identified.

## Evidence and action limits

Evidence class remains HARNESS / CONTRACT_ISOLATED: production functions and
serialized records with synthetic process inventory/start/command observations,
synthetic prerequisites and PocFixture candidate verification. Worker checks use
production functions in a VM and synthetic machine-provider lookup. These
receipts do not establish real client concurrency, Provider execution, target
namespace/query acceptance, Unity behavior, lease-drain physical cleanup,
repeated real lifecycle acceptance or release readiness.

Only this VERIFICATION.md was written. No source/fixture edits, test reruns,
Unity/MCP/Provider launches, process control, cleanup, commits, export, delivery,
agents or messages to the Coder/other chats were performed. Review stops here;
findings are returned for the user's disposition, with no repair dispatched.

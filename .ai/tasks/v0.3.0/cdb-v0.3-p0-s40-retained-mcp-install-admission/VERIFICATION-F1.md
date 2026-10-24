# S40 F1 targeted repair verification

Review date: 2026-10-21. Mode: GUARDED, original finding and nearest regression
only. Verdict: **F1 CLOSED / TARGETED SOURCE REVIEW PASS**.
No remaining actionable risk from original F1 or its immediate repair was found.
The original VERIFICATION.md is preserved as the historical finding record.

## Source admission and repair delta

Checkout: `<repository-root>/.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission`.
Base/HEAD remains `c848049d90fbdf618905be25225580642d98d987`; branch remains
`codex/retained-mcp-install-admission`. All four current source hashes were
independently read and matched SOURCE-SHA256.json:

| Repository-relative source | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `b8931439f2f77fbebc65f81a3614cedf94b0c5b62f1ddac0e62ae402bf8b045f` |
| `com.rice.ai-codedb/Tests~/test-codedb-retained-mcp-install.ps1` | `35512d17a087fe23955b4aae444a7d5afc83225726f2d0947e4da227d3f3411c` |
| `com.rice.ai-codedb/Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md` | `3b09c957860533b3fd82141f564a32f9147123637843755aa748f824fba93b7e` |
| `com.rice.ai-codedb/Tests~/test-codedb-retained-mcp-install.mjs` | `6dfae913d97e220b3bad0309e64a6b647d3dbb6648e4f5a9fd60f41e9b296df2` |

The prior snapshot in SOURCE-SHA256-02.json is the originally reviewed snapshot.
The F1-only engine delta is the helper's RemovalStateId parameter and independent
current/retained intent lookup, plus the caller's instance-to-state association.
The PowerShell test delta is the two-cycle block at lines 127-147. Removing only
these deltas in memory reproduces the exact prior engine and test SHA-256 values
(`227e64df...72d4583` and `b5f661f4...73a1a50f`); no files were rewritten for this
comparison. Documentation and Node harness hashes are unchanged. This confirms
the cleanup accounting, worker, process-control and deletion code did not change
for F1.

## Why F1 is closed

In `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1:5034-5038`, the caller
associates each validated removal intent's state_id with its validated instance.
Line 5047 passes that association to the helper for the same evidence instance.
The helper at lines 4956-4963 still validates the latest desired-state removal
intent, but separately loads the retained instance's own intent. It no longer
uses B's latest intent as A's authority merely because B was uninstalled later.

The own-intent lookup preserves normal schema, exact instance, manifest hash and
current Package wrapper checks. An absent association produces no intent and
fails closed. A valid intent for another instance fails the exact InstanceId
comparison. A tampered older intent fails the existing full intent validation.
Current UNINSTALLED/PENDING, READY/same generation, absent current/LKG selections
and registration deactivation checks remain; registration is checked using the
latest desired-state StateId. Lease identity, unknown process invocation,
Editor/coordinator and competing-writer checks are unchanged.

## Inspected receipts and nearest regression

Raw root: `<repository-root>/.artifacts/tests/s40-retained-mcp-install/`.

- `f1-two-cycle-before-a/manifest.json` identifies the originally reviewed
  engine hash. Its run.log reaches B's second logical uninstall, passes the
  wrong-instance and tampered-old-intent negatives, then terminates at the
  expected original normal-uninstall-closure mismatch when admitting A's reader.
- `f1-two-cycle-after-a/manifest.json` identifies the repaired engine hash; all
  six recorded production dependency hashes independently match current source.
  Its run.log and result.json record **46 checks PASS** in PowerShell 5.1.
- The repaired test block at lines 127-146 holds A's synthetic MCP reader live
  through uninstall A -> Install B -> uninstall B -> Install C. It checks
  distinct removal-state identities, admits A through its own intent, exercises
  original production convergence, and requires C's instance and epoch to differ
  from both predecessors. The corresponding two-cycle-observation.json records
  distinct A/B/C, distinct old/second intent states, command and desired cleanup
  PENDING, and A's lease still present.
- The wrong-instance valid intent and tampered older intent remain rejected
  (test lines 135-136 and both raw logs). Both normal intents and all enumerated
  A/B file hashes remain unchanged after C activation. A's live holder still
  refuses physical deletion (lines 143-145 and corrected receipt).
- The same corrected receipt retains the original single-cycle controls:
  no-retention COMPLETE; retained-reader PENDING; failed-candidate
  UNINSTALLED/no-selection preservation; unknown start/invocation, foreign
  lease/wrapper, missing/conflicting intent, selected predecessor, live
  Editor/coordinator, foreign generation, failed preparation and competing
  execution rejection. No unchanged S32 or worker scenario was rerun here.

RESULT-F1.md declares the PowerShell test unchanged between reproduction and
corrected runs. The per-run manifests hash production inputs rather than the
test file itself; the current test is admitted by SOURCE-SHA256.json, and its
assertions correspond to both serialized logs. This targeted review did not
independently execute the test or reconstruct an unrecorded historical test hash.

## Limits and stop

Closure is source plus inspected HARNESS / CONTRACT_ISOLATED evidence. Process
inventory/start/command observations and prerequisites are synthetic; candidate
verification uses PocFixture. No real client concurrency, Provider query, Unity,
target namespace, repeated real lifecycle or eventual physical cleanup after
lease drain is accepted. The separate PS7 compatibility follow-up remains open;
no PS7 PASS, delivery or release acceptance is implied.

Only VERIFICATION-F1.md was written. No source/fixture changes, test reruns,
services, process control, cleanup, agents, developer messages, repair dispatch,
commit, export or delivery occurred. Original F1 is closed and the targeted
review stops here without a new comprehensive audit.

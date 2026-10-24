# S29 removal-preflight namespace — read-only route reassessment

Date: 2026-10-14, Asia/Shanghai.
Status: READ_ONLY_CAUSE_CONFIRMED / ROUTE_REASSESSMENT_REQUIRED.
Source: exact delivered d88a101f15d21f916cbee9578ab887aa1ea862cd Package,
.artifacts/s29-version-transition-wrapper-handoff-d88a10/review/com.rice.ai-codedb.
User requested continued diagnosis and progress assessment. No new source
repair, delegation or real operation is authorized by that request.

## Progress and blocked acceptance path

The wrapper historical observation repair has advanced the actual Manager path:
human tests/interactions/normal exit passed, the screenshot now reports retained
effects safe with Install ineligible, and the previous activation-context refusal
has cleared. Current selection remains authenticated predecessor42 under target43.
Actual historical removal preflight still reports exit4; real removal, migration,
target Ready and overall S29/release remain unaccepted.

This diagnosis used bounded source excerpts, file metadata/selected JSON fields,
and the already preserved human log. No live product reader/preflight/Probe/IPC,
Unity launch, process control, cleanup, test rerun, source edit, commit or export.
No child was dispatched. Source files remain clean and staged index empty.

## Concrete namespace mismatch

Get-RemoveIntegrationAuthority selects the existing VERSIONED_V2 Supervisor
namespace (materializer :10654-10687). It calls
Get-RemoveIntegrationNamespaceInventory (:10755) before owner parsing, process
identity checks and historical activation authentication.

The inventory (:10115-10153) only permits supervisor-state.json, supervisor.lock,
supervisor-events.jsonl and supervisor-error.json. It rejects all directories
(:10131-10132), considers any operation.json in-flight (:10134-10135), rejects
all other filenames (:10137-10138), and requires a current state/lock pair
(:10149-10151).

Actual v2/supervisor namespace has:

- operation-history/ (directory)
- operation.json (3455 bytes)
- supervisor-events.jsonl (270299 bytes)
- two supervisor-state.json.stale.* and two supervisor.lock.stale.* files
- no canonical supervisor-state.json or supervisor.lock

Its first lexically sorted entry, operation-history/, deterministically fails
the inventory with:
`Supervisor control namespace contains an unexpected directory: operation-history`.
RemoveIntegrationPreflight wraps authority/config failures at :12291-12293 into
exit4. This establishes a concrete present-state refusal from static code and
real inventory. The exact earlier child stderr was not persisted in the inspected
human log; do not present this static refusal as a captured runtime traceback.

These are additional dependent barriers, not permission to incrementally ignore
each entry:

- Canonical operation.json is operation 1a43cdf055cd43d389388598b2cf93ae,
  name materialize:Upgrade, phase failed, started 2026-10-13T03:10:48.181Z,
  completed 2026-10-13T03:10:55.514Z. It is byte-identical to its matching
  operation-history entry (SHA256
  2b3f8b024e7f7ab48f6ef1c0b6285016705aedae56fc2deb7591f83478a7ed62).
  The reader's filename-only rule does not distinguish terminal from active.
  Terminal metadata is not itself sufficient to prove all children/effects safe.
- The stale records bind prior Supervisor epochs to selected42 and its committed
  activation epoch. Their names alone are not a removal authority or proof that
  every recorded owner/child is dead.
- Even after inventory concerns, the v2 path unconditionally reads canonical
  state and lock at :10767-10770. Current records are absent. A legitimate retired
  v2 state therefore needs an explicit authenticated disposition, not fabricated
  current owner records or a relabeling as v1.

## Producer behavior explains these files

Exact codedb-project-supervisor.mjs persistOperation (:2133-2141) writes both
canonical operation.json and operation-history/<operation_id>.json. Therefore
operation-history is product-owned output, not an unknown user directory.
The stale-takeover path (:689-704) requires STALE_PROVED, rechecks its claim and
renames state/lock with .stale.<time>.<id>. It deliberately retains operation.json
for authenticated child recovery. Normal retirement removes only its own current
state/lock via removeOwnedRuntimeEvidence (:1640-1641, :1692-1693).

The retained namespace thus contains expected producer outputs that the removal
reader lacks a matching lifecycle/terminal/history contract for. This is a local
cross-component contract inconsistency. It does not demonstrate that the overall
version/ownership/explicit-removal architecture is wrong, nor that runtime safety
gates should be weakened.

## Why screenshot diagnostics lost the cause

Lifecycle WithRemovalPreflight :1643-1647 caches only
result.GetSummary() on failure and appends it to diagnostic at :1653. GetSummary
in AICodedbProcessRunner :98-99 returns only `Command failed with exit code 4`.
The backend exception detail in stdout/stderr is not conveyed through this path.
Existing Editor log has package/S12 attribution but no complete preflight error.
This explains why repeated screenshots do not expose the actual failing gate.

## Structural escalation and route recommendation

Workflow development-workflow.md :713-720 requires route reassessment for
cross-component semantic conflicts and concrete causes collapsed into a generic
error. Both signals apply here. Source review/repair count for this newly scoped
namespace cause is 0; earlier independent source envelopes are not relabeled as
this cause's iterations. Historical overall iteration counts are not reconstructed
or reset by this note. No new local patch, verifier cycle or screenshot loop starts.

Recommend REFACTOR as one bounded vertical contract task: align Supervisor-owned
namespace production, authenticated terminal/active/history classification,
retired-v2 removal authority and precise Manager refusal projection. Keep the
existing committed selection/activation/Package authority as the identity source;
operational readiness remains a separate decision. Define a single ownership and
effects contract before implementation.

Acceptance scenarios should include committed predecessor42/target43 after
normal retirement, product-owned operation history and stale quarantine, terminal
failed/succeeded versus active or ambiguous operation, missing current state/lock,
foreign/malformed evidence, live/ambiguous owner or child, unsafe configuration,
and unchanged lock-time/commit-time removal revalidation. Historical state may
cease to block only after its ownership and current effect safety are established.
Preserve historical records and original outcomes; no manual deletion or broad
filename exemption. Precise refusal detail must survive to Manager.

Allowed source/evidence closure and budgets still need freezing against this
contract proposal. User route disposition is required before implementing it.
No actual Remove/Install/Upgrade, generation migration, cleanup, process stop,
delivery or Unity execution is included in a future source-task grant unless
explicitly authorized. CleanupMono remains deferred. MissingPrerequisite was
not visible in the latest sample; its earlier cause remains unattributed.

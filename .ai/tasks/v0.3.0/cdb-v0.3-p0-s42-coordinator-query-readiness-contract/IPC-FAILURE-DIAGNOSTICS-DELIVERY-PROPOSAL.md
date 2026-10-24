# IPC diagnostics exact commit/export proposal

Date: 2026-10-22. Status: PREPARED / AWAITING_EXACT_HANDOFF_AUTHORIZATION.
Implementation and NORMAL self-review complete; see
IPC-FAILURE-DIAGNOSTICS-RESULT.md and IPC-FAILURE-DIAGNOSTICS-REVIEW.md.
This is an internal repository-only artifact gate, not consumer delivery or
public release. No source change or exact-artifact operation has been executed
by preparing this proposal.

## Frozen candidate

Checkout: <repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract.
Branch: codex/coordinator-query-readiness.
Parent HEAD: 4589249564c7affb541634d61656c0cc895ca9d4.
Only these two paths under com.rice.ai-codedb may enter the commit:

| Path | SHA-256 | Raw Git blob ID |
| --- | --- | --- |
| Editor/AICodedbSupervisorBridge.cs | 8b021ead8de1716b6b9d36d631ca4c4a0aa3f543ff5dfc1d7be07d121e09e83e | d7bd21169a91459d85a7a216aa0cab00efff0321 |
| Tests~/test-codedb-supervisor-ipc-diagnostics.ps1 | fe5c6c8a043ecade5bd38abbb841805a1ad85871f24fe5e9625333f014badc87 | 75190542ef7d84e35ebc13c37aa228408be66d00 |

The existing isolated index is empty. Raw IDs were calculated without writing
objects. Preserve tested byte identity when staging; validate indexed/extracted
SHA-256 rather than assuming text conversion is harmless. Package version and
generation remain 0.3.0-preview.5 / poc.44. No payload/manifest changes.

## Proposed single authorized sequence

If the human explicitly approves this proposal, perform all steps below without
another approval between them:

1. Recheck parent/branch, two-path diff, empty isolated index, frozen hashes and
   retained receipt binding. Fingerprint the primary index without changing it.
   Stage only exact raw blobs for the two paths, verify indexed paths and bytes,
   then create one isolated-branch commit titled
   `Add bounded Supervisor IPC timeout diagnostics`. No primary merge, source
   synchronization, cherry-pick, push, unrelated staging or history rewrite.
2. Export that exact new commit with the existing isolated exporter:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/export-codedb-package.ps1 -Commit <new-commit> -OutputRoot <repository-root>/.artifacts/exports/s42-ipc-diagnostics-<sha7>`.
   The output directory must be new. The exporter requires production payload
   admission and Package byte closure both at committed staging and exact ZIP
   extraction. No RepairCanonicalMetadata, payload regeneration or identity edit.
3. Verify the complete committed-stage and extracted ZIP inventories match, and
   both changed source hashes match the frozen tested candidate. Record exact
   ZIP SHA-256, commit/parent/tree and inventory. Do not repeat the unchanged
   79-assertion transport batch merely for confirmation: exact source-byte and
   full artifact closure bind that existing evidence to this artifact. This
   does not promote offline evidence to Unity/runtime acceptance.
4. Verify isolated checkout clean and primary index unchanged; retain logs,
   inventory and result beneath
   `<repository-root>/.artifacts/tests/s42-ipc-commit-export/<unique-run>/`.
   Record the result in this task's canonical records and stop.

Use exporter/validator from the isolated candidate, not mutable primary source.
No new dependencies, full regression, Unity/EditMode or service execution.
Closure failures stop export acceptance; preserve any already-created commit or
artifact, with no automatic retry, cleanup, amend or consumer fallback.

## Later consumer gate, excluded here

No external project reads, process probes, RPC, Stop/Start, Unity operation,
Package copy, manifest/lock reference change, Install/Uninstall, MCP call or
live log scan is included. The current external CodedbTest_2 environment and
S41 B are preserved without resampling. Unity need not close for this
repository-only commit/export gate, consistent with the prior S42 delivery
split. Human closing, fresh bounded retirement evidence and exact Package
reference switching must be aligned before any later consumer mutation.

Only after delivery and human compilation may a separate real observation
capture command-vs-poll and I/O-stage evidence from a naturally occurring
timeout. A successful opening without timeout is NOT_REPRODUCED, not root-cause
closure. No repeated refresh, timing change or forced failure is proposed here.

## Authorization boundary

The approved implementation task explicitly excludes commit/export. The current
workflow's HANDOFF stage also requires human initiation and explicit approval
of the exact operation. Approval of this prepared proposal covers steps 1-4
only, not consumer delivery, real reproduction or release.

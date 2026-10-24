# S40 primary-source integration result

Date: 2026-10-22. Status: PRIMARY SOURCE INTEGRATION PASS.

## Approval and exact effects

The user replied `好的 同意` to SOURCE-INTEGRATION-PLAN.md. Executed only the
four prepared primary Package writes, with their exact preimages preserved:

| Path under `com.rice.ai-codedb/` | Effect |
| --- | --- |
| `Tools~/codedb-instance-engine.ps1` | Replaced exact parent engine with reviewed 186aacf engine bytes. |
| `Tests~/test-codedb-retained-mcp-install.ps1` | Added exact accepted focused PowerShell test bytes. |
| `Tests~/test-codedb-retained-mcp-install.mjs` | Added exact accepted focused Node test bytes. |
| `Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md` | Inserted only the accepted same-Package retained-reader paragraph; all original local bytes preserved. |

Primary HEAD remains `237c72d9980114b99887fb8e805658447dd8d4fd` on
`codex/v0.3.0-legacy-workflow`. No new commit, staging, merge, cherry-pick,
stash/reset, push, export or consumer reference switch occurred.

## Verification and preservation

- Preparation manifest and all four primary preimages/absence matched before
  writes. Proposed file hashes matched the approved plan.
- Engine and both tests equal the raw blobs from accepted commit
  `186aacf0371ba64e47114306170b449dbca261c9` byte-for-byte after integration.
- Removing only the inserted contract paragraph restores the complete exact
  primary preimage, including original local clarifications and EOL/BOM.
  Integrated contract SHA-256:
  `be1bfa25f380ff75e954b1236d594cb5ba24a8aa612bd693d4982abf1838f8f5`.
- Primary index SHA-256 before/after matches:
  `74aaa666f53eb641db7452e149c0f1cc2823f3da725962a00193ab910f87fef2`.
- The explicitly protected unaccepted writer-lifetime deltas remained unchanged:
  AICodedbProcessRunner.cs
  `a3c9ae743c4634167f8cbbf20146be9b06132f8a54ef8f9e463f3a4bfc7380d1`;
  invoke-codedb-manager-action.ps1
  `44216a7061384c095b54b2183bc9dacb19f63428c3868f19ec9f1f4c8b11334c`.
- The write procedure touched only the four allowed Package paths. Other local
  source/runtime/configuration and immutable generations were not written.
- Existing exact-byte source parse/harness/review evidence is reused for the
  unchanged engine/tests. No tests were rerun; no combined-primary-tree or new
  runtime acceptance is inferred from this mechanical integration.

Consumer CodedbTest_2, the delivered exact Package and the deferred identity/
heartbeat investigation received no operations. Runtime calls, MCP calls,
consumer writes and process-control operations were zero.

## Evidence and handoff

Canonical integration evidence:
`<repository-root>/.artifacts/maintenance/s40-primary-source-integration-execution-a/`:
result.json, sequential journal.json and exact two existing-file preimages.
The preparation proposal and absent-file declarations remain in sibling
`s40-primary-source-integration-preparation-a/`.

This closes the approved source synchronization. The primary combined dirty
tree still includes other local work and is not the exact exported 186aacf
candidate; do not transfer that artifact's acceptance to a whole-primary export.
PREVIEW-EVIDENCE-SUMMARY.md separates basic-flow evidence from broader roadmap
and release decisions. No additional operation is started by this result.

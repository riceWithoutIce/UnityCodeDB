# S29 accepted compact receipt layout - delivery preparation

2026-10-08. User explicitly ACCEPTED FIX01 source review. Standing pre-human
preparation authorization covers scoped commit/export/checklist and closed-project
reference switching. Human confirmed UnityFreshInstallValidationProjectS29 is
normally closed and reference switching is allowed. No Unity operation authorized.

Accepted base HEAD332c7ffd510daebb6da6a386d66783d4aabf6bd6. Exact reviewed snapshot:
RECEIPT-LAYOUT-FIX01-IDENTITY.json; verifier report SHA256
F57C8A4567588F0828D027B955C9BEA46F85BD88B6655D78E342B3EDD4CCA6E3.
Source ACCEPT only;34methods/80cases, Unity and real integration remain pending.

## Scoped commit

Eight changed source/test files from original layout allowlist at FIX01 hashes;
Documentation~/manager-receipt-storage-layout.md and test-workspace-contract.md;
only compact-layout additions from development-workflow.md and
v0.3.0-p0-host-action-execution.md (not inherited unrelated edits).
Twelve task records: RECEIPT-LAYOUT-{TASK,IMPLEMENTATION-PLAN,IDENTITY,RESULT,
REVIEW-PACKET,VERIFICATION,FIX01-TASK,FIX01-IDENTITY,FIX01-RESULT,FIX01-VERIFICATION,
DELIVERY-PLAN} plus TEST-WORKSPACE-PATH-REASSESSMENT.md. Total24 paths.
Use raw reviewed source bytes; scoped doc index blobs derived from HEAD plus
specific sections, preserving worktree bytes. Empty initial index, exact path and
hash checks, staged diff-check before commit. Message:
`fix(editor): compact Manager receipt storage and preserve recovery identity`.
No blanket staging, reset/clean, amend, push/tag/publication or remote edits.

## Artifact and consumer evidence

Use unchanged committed Tests~/export-codedb-package.ps1 from exact new commit
into fresh .artifacts/s29-receipt-layout-poc40. Short artifact label limits fixture
path overhead. Version0.3.0-preview.5/poc.40 unchanged. Run exporter once, both
commit-staged and exact-ZIP extraction closure gates. Verify all nine reviewed
source/test hashes and committed document bytes against extracted Package.

Then execute the extracted Tests~/test-codedb-package-boundary.ps1
-ManagerActionWriterOnly once using Windows PowerShell5.1. This is new artifact
consumer evidence, not an unchanged source rerun. Fixture scratch is confined
below extracted review parent .artifacts/tests; child environment remains private.
Maximum12 synthetic scenarios, no live Host/Provider/Unity. Stop on failure and
retain artifact/evidence; no source repair or repeated export under this plan.

After closure/hash/consumer PASS switch only CodeDB reference in S29 manifest
and packages-lock, prove other text unchanged and JSON valid. Preserve old
artifacts and real failed candidates/journals. Prepare one compile+34methods/80cases
and Manager observation checklist; no mutation buttons or automatic retry.
Delivery result/checklist/TASK changes stay uncommitted, no amend. Whole S29 PARTIAL.

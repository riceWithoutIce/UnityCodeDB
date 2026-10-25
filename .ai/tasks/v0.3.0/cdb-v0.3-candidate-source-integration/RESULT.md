# v0.3 primary candidate source integration result

Date: 2026-10-25. Outcome: `SOURCE_INTEGRATION_OFFLINE_PASS`.
All paths relative to repository root. Same-session implementation and scoped
source review; no independent verifier or new development environment.

## Candidate composition

The primary checkout now contains the accepted fe08d6e implementation/tests,
the F01 default-off diagnostic publication repair, and five retained newer
primary documents. The prior F02 writer-lifetime exclusion remains unchanged.

- Baseline commit: `fe08d6e0961189cedd467487675062564c470644`.
- Applied exactly thirteen allowlisted files: twelve immutable Git blobs plus
  the hash-verified F01 LifecycleEvidence file. Three are additions, including
  the original transition helper GUID metadata. Existing formal tests retained.
- No branch merge, isolation dirty-file copy or primary-only WIP inclusion.
- Five retained docs: responsibility contract, host action execution,
  project integration reinstall contract, roadmap and safe-execution module.
- Full inventory: **669 files**. Compared with baseline, content differences
  are exactly F01 and those five newer docs. One additional byte difference
  is the pre-existing CRLF-only package.json; its original bytes are preserved.
- Package remains `0.3.0-preview.5`; generation remains `poc.44`.
- Current payload and historical-generation files were not rewritten. Four
  historical paths surfaced by Git/EOL normalization already had baseline raw
  bytes; no generation change or canonical metadata repair was needed.

Primary HEAD remains `f7634d29664e6557308938068814d5d2d1c0fd5c`;
this is an uncommitted working-source candidate, not an immutable release.

## Identity and evidence

Generated run:
`.artifacts/tests/cdb-v0.3-candidate-source-integration/207d4249-ded8-4f96-8744-4b03992e31dc/`.

The source manifest uses SHA-256 of ordered UTF-8 records
`<repository-relative-path>\t<file-sha256>\n`, in baseline Git tree order.
It identifies this working snapshot; Git/export EOL normalization may produce
different raw bytes and must be checked when a committed artifact is prepared.

| Object | SHA-256 |
| --- | --- |
| Full working-source manifest | `221a9854704c48fb71e9c0f5659638825894cdebeccdfd32707b34f83de06989` |
| Payload manifest | `ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5` |
| poc.44 generation manifest | `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb` |
| Stable wrapper | `a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e` |
| F01 LifecycleEvidence | `e939c8d8163ede9ca4a372a608fc5d7c66e24d83d230438e71db496048ea865e` |

Retained generated records: plan with preimage hashes, original bytes under
preimages/, write journal, candidate-source-manifest.json, integration-receipt,
verification-receipt and final-protection-check. Concise authority is this task
record plus immutable source commits; generated copies are not release inputs.

## Verification

`verify.ps1`: **113 focused offline checks PASS**:

- C# syntax for eight integrated C# files; two PowerShell parsers; two Node
  syntax checks without executing modules; one Unity GUID metadata check.
- Every declared payload/current-generation file byte hash and selected
  generation manifest hash matches its existing contract.
- Integrated F01 and helper bytes equal the previous passing executable
  extracted-body/BCL fixture. That evidence is reused for those exact bytes;
  the unchanged diagnostic harness was not repeated.
- Both F02 writer file hashes still equal the restored accepted bytes.
- All 669 candidate source hashes remain stable after checks; scoped diff
  whitespace checks pass. No consumer or global environment writes.

Pre-write admission initially stopped on package.json CRLF-only bytes, before
any product mutation. The comparator was corrected to distinguish EOL-only
differences from content differences while retaining raw hashes and preserving
all protected bytes. One patch context mismatch also occurred before applying
that harness correction. Neither caused a product/external acceptance retry.

Protection closure PASS: primary HEAD/index unchanged; seven pre-existing
isolation dirty files (including F01) retain their hashes; every non-allowlisted
primary Package file, including the five newer docs and F02 files, is unchanged.

## Scoped review and remaining boundary

Post-write review verified only the frozen composition, direct source identity,
default-off F01 gate, F02 exclusion and protection closure. It adds no findings
and does not reopen the completed residual/legacy audit.

Unity compilation, NUnit/EditMode, consumer Manager behavior, real MCP,
lifecycle, performance and release acceptance: **NOT_RUN**. The full production
package release-closure runner was not executed; this task performed declared
byte-hash checks only and does not claim its production-admission PASS.
Historical runtime PASS stays attributable to its original delivered package.

No export, delivery/reference switch, installation, process start/control,
commit, push, board mutation, tag or release. Stop this integration task here.
Next: authorize a candidate commit/snapshot, then prepare a concrete consumer
delivery and its human Unity/focused acceptance steps before golden-path tests.

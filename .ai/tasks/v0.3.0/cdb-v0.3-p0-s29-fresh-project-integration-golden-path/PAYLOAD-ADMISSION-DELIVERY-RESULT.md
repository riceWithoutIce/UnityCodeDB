# S29 payload admission committed delivery - focused harness blocked

2026-10-09. SCOPED_SOURCE_REVIEW_PASS / COMMIT_EXPORT_PASS /
EXTRACTED_CANONICAL_ADMISSION_PASS / EXTRACTED_HARNESS_ENTRY_BLOCKED.
S29 remains PARTIAL. No Package reference switch or real runtime operation.

## Source and scoped commit

Independent PAYLOAD-ADMISSION-VERIFICATION.md reports scoped PASS with no
actionable source/saved-evidence finding. Parent verified four stable source
hashes and accepted this bounded source-stage result under the authorized fix.
Commit 97c46f577c17639af32579c41dbb832eacb9346b:
fix(package): gate exports on production payload admission.
Exactly 11 paths: four scripts, five task records, and scoped additions to
workflow/roadmap projected over HEAD. Other dirty document and consumer bytes
remain uncommitted; index is empty. Raw-blob staging retained reviewed bytes.
No push, tag, release or remote Project synchronization.

Staging helper initially refused a missing insertion anchor before any index
write: the worktree contains an earlier uncommitted consumer-closure bullet
absent from HEAD. The helper was corrected to use the existing HEAD preserve
anchor while extracting only this repair's paragraphs. Second staging PASS
verified exact 11-path set and scoped whitespace. This tooling correction did
not change reviewed product bytes or include the unrelated earlier amendment.
Recipe and staged hashes: .artifacts/delivery/s29-pa41/.

## Exact committed artifact

Standard exporter ran once with the exact commit and fresh output root
.artifacts/s29-payload-admission-poc41. Exit 0. Both Commit-staged Package and
Exact ZIP reported PRODUCTION_PAYLOAD_ADMISSION PASS file_count=58 and
PACKAGE_BYTE_CLOSURE PASS source_count=58 mismatch_count=0, then EXPORT_GATE PASS.
All four extracted script hashes equal reviewed source. Native VerifyOnly
provenance checks passed; no rebuild or daemon execution occurred.

- Review Package: review/com.rice.ai-codedb.
- ZIP: com.rice.ai-codedb.zip, 2713051 bytes, 554 entries.
- ZIP SHA256: 465f5035a2932a61c4586ea68171591d28cf960636ea2b5423080dcac037c8c6.
- Generation remains poc.41; all Payload bytes were unchanged.
- Generation-manifest SHA256: c9114d7de03ea26520a07d32915c9e62a1a976028ec282051c9a1142a700f7ec.
- Host-current SHA256: ac35dd035c259c65064cc684101b51c3a435ca5cbb55f914d2e6b0d41d274089.
- Runtime contract SHA256: c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba.

## F-PA01: extracted focused harness entry

Invoked exact extracted Tests~/test-codedb-payload-admission.ps1 once, with fresh
EvidenceRoot review/.artifacts/tests/pa41-delivery. Its canonical-source reader
returned exit 0 with 58 files, all six targets present, byte-identical before/after
Package fingerprints. The run then stopped before stage/ZIP/negative assertions:
`fatal: pathspec 'com.rice.ai-codedb' did not match any files` /
`Fixture git archive failed`, overall exit 1.

Cause: harness line 12 treats PSScriptRoot/../.. (the extracted review directory)
as the repository root. git rev-parse HEAD finds the ancestor checkout, but
line 110's `git -C $repo archive ... -- com.rice.ai-codedb` interprets the pathspec
relative to the review subdirectory, which has no such tracked Package path.
This is a directly observed test-entry portability gap, not another production
allowlist rejection or actual Install failure. Source-stage two-layout negative
evidence remains valid, but final extracted harness has not completed those gates.

Retained incomplete evidence: .artifacts/s29-payload-admission-poc41/review/
.artifacts/tests/pa41-delivery. It includes canonical reader command/stdout/
stderr/exit, six targets, source and package fingerprints, base commit and empty
tar. Do not overwrite/retry this root or alter the exported artifact in place.

Minimal proposed continuation: same-S29 harness-only source correction to separate
test-local evidence root from actual Git source-root discovery; ensure all changed
script overlays still come from the package under test. Review only this finding
and adjacent exact-extracted harness binding, then new scoped commit/fresh export.
No production, payload, identity, full-suite or runtime scope expansion is needed.

## Stop and consumer boundary

User confirmed UnityFreshInstallValidationProjectS29 normally closed and reference
switching permitted. References remain at s29-native-launch-poc41 because the
agreed final focused gate did not complete. No Unity launch, real Install,
Remove/Configure, candidate cleanup, receipt deletion or process operation.
Per delivery plan's first-failure rule this attempt stopped; route disposition
belongs to User/Planner before correction/review/new delivery. Prior blocked
artifacts and historical poc.40 receipts remain intact.

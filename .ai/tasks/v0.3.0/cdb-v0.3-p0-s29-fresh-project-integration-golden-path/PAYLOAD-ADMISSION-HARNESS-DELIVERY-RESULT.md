# S29 F-PA01 corrected committed delivery

2026-10-09. F-PA01_SCOPED_REVIEW_PASS / COMMIT_EXPORT_PASS /
EXACT_EXTRACTED_FOCUSED_GATE_PASS / PROJECT_REFERENCE_SWITCH_PASS.
Human compile/Manager observation pending; S29 remains PARTIAL.

User `同意修复` reopened the precise harness correction route. Fresh independent
Verifier reports no scoped findings and closes F-PA01. Prior delivery failure
is preserved in PAYLOAD-ADMISSION-DELIVERY-RESULT.md and its evidence directory.

Commit 4ba4ccb6cfc437343c8e4cdc7c45816e4510882e:
fix(tests): resolve payload admission archive root for extracted packages.
Exactly five paths: one reviewed harness and four task/result/review records.
Stage verified raw script SHA256 0041b6458a77bc321d0fd2425b170400e4c9c14decdd598866d0bd7c711a21df,
path set and whitespace; index empty after commit. Other dirty state preserved.
Staging recipe/identity: .artifacts/delivery/s29-pa41hf/. No push/tag/publication.

## Exact final package

Standard exporter ran once at this commit into fresh
.artifacts/s29-payload-admission-hf-poc41. Exit 0; commit-stage and exact ZIP
each emitted production admission PASS file_count=58 and byte closure PASS
source_count=58/mismatch_count=0, then export gate PASS. Four extracted repair
script hashes equal reviewed source. Native VerifyOnly checks passed without
compilation or launch. Package0.3.0-preview.5 / unchanged generationpoc.41.

- ZIP com.rice.ai-codedb.zip: 2713526 bytes, 554 entries.
- ZIP SHA256 f902beb0827b6ecf321c319b60eb6ad07b9ec2b92b11e29cc6576344828f97df.
- Generation hash c9114d7de03ea26520a07d32915c9e62a1a976028ec282051c9a1142a700f7ec.
- Host-current hash ac35dd035c259c65064cc684101b51c3a435ca5cbb55f914d2e6b0d41d274089.
- Runtime contract hash c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba.

Directly ran the exact extracted Tests~/test-codedb-payload-admission.ps1 once
with EvidenceRoot review/.artifacts/tests/pa41-delivery, exit 0. Saved summary
proves all six canonical targets, stage/exact-ZIP byte and admission checks,
flat/generation unknown reader exit 2 and export refusal, unchanged Package
snapshots and no logical project creation. roots.txt and overlays bind archive
Git root separately from the tested extracted Package. This final run supersedes
only F-PA01's incomplete final-harness gate, never its preserved failed evidence.

## Closed-project reference switch

User's explicit normal-close/reference-switch confirmation remains applicable.
Changed only CodeDB local reference in S29 Packages/manifest.json and
packages-lock.json to file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-payload-admission-hf-poc41/review/com.rice.ai-codedb.
Both parse/resolve to the actual package.json. SHA256 of each full text after
replacing its single CodeDB reference with <CODEDB_REFERENCE> is equal before/after:

- manifest 6f4e99c88116e62ea9d20d88504a65a605677432a6d899648a743bcfe8cc8614.
- lock 230b6328bdec81b4248f45029ffbfa7f8a1ccebca8d5ca4e324647d5c1608a2a.

No Library clearing, consumer runtime/history mutation, cleanup, Unity launch,
real Install/Remove/Configure or process operation. Consumer references and
post-delivery task checkpoints remain uncommitted. No real S29 acceptance.
Human next step is PAYLOAD-ADMISSION-HUMAN-CHECKLIST.md, one observation session.

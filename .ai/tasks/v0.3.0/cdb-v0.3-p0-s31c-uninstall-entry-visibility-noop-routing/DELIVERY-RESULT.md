# S31-C accepted source delivery — 2026-10-17

Status: SOURCE ACCEPTED WITH LIMITS / DELIVERY PASS / HUMAN S31-C ACCEPTANCE PASS.
User `同意 accept` authorized source acceptance plus DELIVERY-PLAN.md steps
1–4 together. This record is outside the four-file source commit.

## Exact Inputs And Commit

- Base: `279b442c657676d1adbda7d15151a3770682a674`.
- Commit: `cc49c95e84945308385f64640963716d93d070ea`.
- Message: `fix: keep uninstall entry reachable and classify local no-op safely`.
- Exactly four accepted source/test files committed, with final F1 hashes in
  SOURCE-SHA256.md. Index was empty before staging and after commit. Staged
  Git blobs matched the compiled candidate. Unrelated dirty state preserved.
- Candidate: `.artifacts/tests/s31c-delivery-20261017-a/candidate/com.rice.ai-codedb`.
  Archived base plus exactly four accepted overlays. All other files match base.
- Original candidate Editor and all Editor test source compiled: PASS, exit 0,
  three existing warnings (CS4014 twice, CS0414 once). No native or runtime test
  execution. Existing local tools/references authenticated against F1 manifest.
- Evidence root: `.artifacts/tests/s31c-delivery-20261017-a/`.
  Manifest SHA-256: `d194d65147f8648a272dab7a4ce9715193e07c14eeaf48ba8434f8acd642b652`.

## Exact Package Gates

- Export root: `.artifacts/s31c-uninstall-entry-cc49c95/`.
- Exact ZIP: `com.rice.ai-codedb.zip`; single root; 617 files, 13,247,653
  extracted bytes, 617 ZIP entries.
- ZIP SHA-256: `ffd2fe86f9a69fe6136a8404919fd2c48ecdffb1e22b26871ba422894610e696`.
- Existing exporter against the new commit: PASS, exit 0. Commit-stage and
  exact-ZIP extraction independently passed complete byte closure, production
  materializer read-only payload admission and native source/build/binary binding.
- Payload sources: 60; mismatches: 0.
- Runtime contract SHA-256: `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- Generation manifest SHA-256: `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`.
- host-current SHA-256: `ef73f381ffc3f5a611b1712edaf91958cacb6dc304eec4e9d3d96495403619e1`.
- All 617 exact-extraction files matched the compiled candidate hashes.
- Extracted `Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`:
  PASS, exit 0; helper projections and PS/Node bindings also PASS.
- Package identity remains `0.3.0-preview.5 / poc.43`. No generation migration,
  dirty Payload export or package repair occurred. Previous artifacts preserved.

## S30 Reference Switch

- Target: `<repository-root>/UnityFreshLifecycleValidationProjectS30`.
- UnityLockfile absent. One live Unity process was positively attributable
  to a different project; S30 was closed. No process was stopped or started.
- Initial conservative guard stopped before any backup/reference mutation on
  seeing that editor. Bounded ownership inspection established it was unrelated;
  relevant-project guard then passed. This was no product/test retry.
- Backups: `.backups/s31c-uninstall-entry-cc49c95/manifest.json` and
  `packages-lock.json`, original hashes verified:
  `a0f8fcd0069d232f0e02e3bf0f26d5e341e38d92202a18cb4d0e549c1358b1ca`;
  `fd46bbe94d5a338b58d3bff5da38d6a292f330e95fb252a0015071db2c601660`.
- Only CodeDB references changed from
  `.artifacts/s30-current-version-lifecycle-ed97c38/review/com.rice.ai-codedb`
  to `.artifacts/s31c-uninstall-entry-cc49c95/review/com.rice.ai-codedb`.
  Manifest and lock parse and agree. Full text matches the backed-up files
  with only that exact reference replacement.
- New manifest SHA-256:
  `ed054ad5489f6aa007cf311b426040c5d828eeeeedd06c51f90ea45537ee42a5`.
- New lock SHA-256:
  `67fe15f44147943c741b6598207f5345a71d8569bf3821d130fb047a3093296d`.

## Remaining Gates

Human Unity compile/tests/UI acceptance subsequently passed; see HUMAN-RESULT.md
and HUMAN-CHECKLIST.md. This is human-reported evidence for the agreed S31-C
boundary, not an independent case-count audit or real-backend uninstall result.
Earlier native reader/session limitation remains frozen, not retried in the
non-Unity environment. F2 remains FOLLOW-UP. S31-B, Provider readiness,
owned-runtime stop, actual uninstall, reconnect and historical recovery remain
deferred. No actual Install/Uninstall, Unity launch, push or release publication.

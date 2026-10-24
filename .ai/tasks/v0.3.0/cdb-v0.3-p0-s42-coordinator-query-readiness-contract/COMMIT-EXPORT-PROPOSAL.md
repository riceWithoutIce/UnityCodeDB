# S42 exact commit/export grant proposal

Status: COMPLETE. User explicitly approved this proposal; see COMMIT-EXPORT-RESULT.md.
This proposal stops before any consumer or running-service operation.

Candidate checkout:
`<repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract`;
branch `codex/coordinator-query-readiness`, parent/base
`186aacf0371ba64e47114306170b449dbca261c9`.

Exactly two committed paths, raw SHA-256:

- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`:
  `ac341b039f0840735801dc991e42a9ba7e313df0c82cca895d00dfc08a104fba`.
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`:
  `7bf20ca426419905b34bb3297af2f164be2946d50a3e95a9850de09fb77f468e`.

Complete prepared tree: `cf162955d6f3e89daa0bf32b3db8110219f161f6`.
Preparation and preserved evidence: PREPARATION-RESULT.md.

If explicitly approved, execute this closed sequence without repeated approval:

1. Verify branch/base, exact changed paths/hashes and empty isolated index; retain
   primary index fingerprint without changing it. Stage exact two raw blobs
   (no content filters), verify indexed hashes and resulting complete tree against
   prepared tree. Create one commit on the isolated branch, title
   `Fix Supervisor watch service startup and readiness contract`.
   No unrelated files, primary merge/sync, push or history rewrite.
2. Run existing `Tests~/export-codedb-package.ps1` against that exact new commit,
   output `<repository-root>/.artifacts/exports/s42-query-readiness-<sha7>/`;
   refuse existing destination. Require commit-stage and exact-ZIP extracted
   byte closure plus production materializer payload admission. No identity/
   generation regeneration or manual manifest repair.
3. Compare exported two source hashes to this frozen candidate. Run only S42
   query-readiness and S32 disposition fixtures from the exact ZIP extraction,
   fresh repository-owned artifact roots under its synthetic checkout. No full
   regression, real Provider or runtime. Record semantic PASS separately from
   file/manifest/admission PASS.
4. Record parent/commit/tree, source hashes, ZIP hash, complete inventory and
   commands/results. Preserve old artifacts and all prior failures. Verify the
   isolated checkout is clean and primary index unchanged; stop here.

Stop affected sequence once on base/source/index/tree drift, unexpected commit
scope, export/admission/closure/fixture failure or output conflict. Record exact
effects (including any already-created commit); no consumer fallback or automatic
repair/retry. Mechanical construction errors can be corrected within the normal
two-correction budget before intended side effects/assertions.

Not authorized by this grant: reading/probing live consumer state, sending Stop,
operation polling, Supervisor retirement, opening/closing Unity, copying Package
to external test Packages, manifest/lock switching, Install/Uninstall, Start,
CodeDB/MCP query, push/publication or cleanup. Package output remains an internal
exact candidate; it is not a public release or accepted real-project recovery.

The preparation TASK and original S42 TASK explicitly reserve actual commit/
formal export and live effects for separate human grants. This proposal is the
concrete result of the current preparation, not a repeat implementation gate.

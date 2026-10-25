# v0.3 candidate commit and delivery preparation

Date: 2026-10-25. Status: COMPLETE / CANDIDATE_COMMITTED_DELIVERY_PREPARED.
Grant: user "ok 继续" following the explicit next step of fixing the candidate
commit and preparing CodedbTest_2 delivery/acceptance. Current session only;
workflow codedb-workflow-v2 revision 2.7. No new agents or worktrees.

## Scope

Commit the stable candidate source from cdb-v0.3-candidate-source-integration,
the F01/F02 repair and their task records. Candidate parent is
`f7634d29664e6557308938068814d5d2d1c0fd5c`; package version remains
0.3.0-preview.5, generation poc.44. Protect working bytes and isolation state.

Product commit allowlist: the thirteen integration files in that task plus
the two restored F02 writer files. Also preserve four historical payload files'
accepted raw bytes in the Git index (no worktree rewrite):

- `Payload~/Generations/poc.42/generation-manifest.json`
- `Payload~/Generations/poc.42/scripts/codedb-project-common.ps1`
- `Payload~/Generations/poc.43/scripts/codedb-project-common.ps1`
- `Payload~/Generations/poc.44/scripts/codedb-project-common.ps1`

All four paths are under `com.rice.ai-codedb/`. Read-only admission confirmed
their worktree bytes equal fe08d6e while existing index bytes were normalized
to LF. Stage their exact immutable fe08d6e blobs so the commit preserves the
already-verified candidate and declared hashes; no metadata regeneration,
generation transition or new runtime policy. Other Package files stay unchanged.

Records/scripts allowlist: the residual-review, source-integration and this task
directory only. First commit fixes the candidate and pre-existing records;
a receipt/repository-metadata commit may record the resulting candidate hash.
No generated copies in Git. Intended candidate message:
`fix(codedb): freeze reviewed v0.3 candidate source`.

## Checks and boundary

- Verify all 669 working files still match the integration hash manifest.
- Verify staged set, complete staged Package byte manifest, exact F01/F02 and
  historical blobs, payload/current-generation declaration hashes and unchanged
  isolation dirty files. Retain raw and canonical snapshot identities separately.
- One bounded scoped syntax/byte/source check; reuse unchanged 113-check result
  only with matching bytes. Same-session focused composition review.
- One read-helper syntax correction occurred before any index/product change;
  corrected once and continued. No product failure or external test attempt.
- Local receipts under `.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/`.
- STANDARD_30M; two mechanical corrections per scenario. Stop on source drift.
- Read consumer manifest/lock to prepare exact proposed delivery only. No
  export/reference switch, Unity/MCP/process operations, install/uninstall,
  remote push, board changes, tag or release in this grant.

Prepare DELIVERY-PLAN.md with source/destination/rollback and acceptance steps;
leave consumer writes for the separately named delivery grant and human-confirmed
closed Unity prerequisite. No current Unity state is inferred from old reports.

## Adjacent Git metadata correction

After the exact-byte candidate commit, Git still reported the four canonical
historical payload paths as modified: the root LF text rule cleans their CRLF
bytes even when raw bytes equal HEAD. Close this directly caused freeze issue
with four exact-path `-text` exceptions in the Package `.gitattributes`; do not change the
default or any other path. This extends the repository metadata allowlist only,
without changing payload bytes, generation or runtime behavior. The Package
tree changes only for its Git metadata. Prior root
attributes SHA-256: `931ea98fe553b945d3032a322cf0932f35581d7eea127c8a3385d8e727381a8e`.
One patch context error occurred before this correction was applied.

Check exact text attributes, normal filtered hashes versus canonical HEAD blobs,
payload byte preservation, unchanged Package tree and final main-checkout status.
Include this same-cause correction with the result/plan receipt commit.
The root rule was overridden by the existing nested Package rule; the first
root-only attempt had no effect and was restored byte-for-byte. The final
four exceptions belong in `com.rice.ai-codedb/.gitattributes`. This is the one
adjacent Git-filter repair, not a general normalization or fallback policy.

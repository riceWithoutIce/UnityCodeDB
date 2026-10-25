# Candidate commit and delivery preparation result

Date: 2026-10-25. Outcome: `CANDIDATE_COMMITTED / DELIVERY_PREPARED_ONLY`.
Paths relative to repository root; no export, consumer switch or remote push.

## Frozen source identity

- Implementation commit: `cd7dd01b94d3e24f825347827297f6518dc74920`.
- Final candidate: the commit that first adds this RESULT.md, including the
  adjacent Package Git-filter correction below. Resolve its exact hash with
  `git log --diff-filter=A -1 --format=%H -- <this-result-path>`.
- Final Package Git tree: `0690f9fee09541da2d75df6878f53c0114869ce9`.
- Final committed-source manifest SHA-256:
  `e1f7ff9eb53b0ad10362e3b3ae1a37e5c2658370950683e6501ef97769365229`.
- Inventory: 669 Package files. Manifest convention: ordered UTF-8
  `<repository-relative-path>\t<file-sha256>\n` in baseline Git tree order.
- Package remains 0.3.0-preview.5; generation poc.44. Generation manifest SHA-256
  `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`;
  stable wrapper SHA-256
  `a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e`.

The implementation commit contains the thirteen integrated files, two restored
F02 files, four exact historical blobs and the scoped task records. It excludes
isolated validation/payload dirty state and keeps five newer documents. F01
diagnostics stay explicitly off by default; the writer WIP remains excluded.

## Adjacent canonical-byte correction

Pre-commit checks found four working payload files already matched fe08d6e
but the old index had LF-normalized bytes. Their accepted immutable Git blobs
were restored in the candidate commit, with no working-file or identity rewrite.

After that commit, the existing text rules still marked identical working/HEAD
bytes as modified and could normalize them again on a normal future `git add`.
The final candidate adds only four exact-path `-text` exceptions in
`com.rice.ai-codedb/.gitattributes`. The Package tree changes for that metadata
alone; payload, generation and product code bytes do not change.

The initial root-only exception was overridden by the existing Package rules;
it was removed and the root attributes restored to its exact original hash.
No default rule, other generation, global configuration or unrelated file was
changed. No assume-unchanged/skip-worktree workaround was used.

## Evidence

Run:
`.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/bc756ebd-ad4f-4e97-9e9b-c75f7ac3eeb4/`.

- `stage-receipt.json`: implementation staged tree PASS; exact 30-path set and
  complete 669-file staged manifest checked. Actual implementation commit tree
  matched the staged tree exactly. Only existing package.json CRLF-to-LF differs
  between committed and working bytes; its content is unchanged and both source
  identities remain explicit.
- Declared payload/current-generation hashes checked against staged Git blobs,
  before commit; these match the same authority as prior working-byte checks.
- `attributes-receipt.json`: PASS. All four accepted blob bytes, working bytes,
  checkout-filter bytes and ordinary clean-filter hashes agree. Effective text
  attributes are unset for exactly the intended paths; false dirty flags clear.
- `final-source-manifest.json`: full final committed Package file identities;
  only the Package Git metadata differs from the verified implementation tree.
- All other Package working bytes retain the prior 669-file source-manifest
  hashes. Seven isolated dirty files retain their recorded bytes. Root attributes
  unchanged. Prior 113 offline checks are reused for their exact code/payload
  bytes, not rerun or generalized to new Unity evidence.

Read-helper syntax and patch-context errors occurred before their respective
mutations; corrected locally, with no product/runtime experiment retry.

## Delivery and acceptance boundary

DELIVERY-PLAN.md is ready: commit-derived export and both exact-package closure
gates; a new candidate-specific directory under the existing external test root;
two CodeDB reference changes only after human confirmation that Unity is closed;
backups, preimage checks and explicit rollback; later human Unity and bounded
target-project MCP acceptance. Old source remains available.

The current consumer manifest/lock still reference
`file:../../Packages/fe08d6e-c-scheme-observation/com.rice.ai-codedb`.
No consumer files or registration/runtime/probes changed. Current Unity state
was not inferred from earlier reports.

Exporter/full production release closure, Unity compilation, EditMode, consumer
Manager behavior, real MCP, lifecycle/performance and release: **NOT_RUN** in
this stage. No watcher/provider/Supervisor start, installation, remote push,
board update, tag or release. Source commit is not release acceptance.

Next named action: authorize export of the final candidate via the existing
exporter and retain its closure/ZIP-hash receipt. A reference switch then needs
the current closed-Editor confirmation and the bounded delivery grant.

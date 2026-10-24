# Verification 02: S18 Post-Publication FIX 01

## Outcome

- Verdict: `BLOCKED / FROZEN_IDENTITY_DRIFT`.
- Review mode: `GUARDED`, targeted, read-only except for this report.
- Review date: `2026-09-18`.
- Scope: admission for the authorized `0.3.0-preview.3 / poc.37`
  Post-Publication FIX 01 snapshot.
- Semantic review: `NOT STARTED`. The frozen identity gate failed and the
  authorization requires an immediate stop.

## Frozen Identity Admission

- Expected HEAD: `983e091bbf5973fbb799a6e044dec028ef5b9720`.
- Observed HEAD: `983e091bbf5973fbb799a6e044dec028ef5b9720`.
- HEAD result: `PASS`.
- Expected 29-path identity:
  `4b57740477e611c2b37e048d74919e98cad3da27`.
- Observed 29-path identity:
  `b4af83cc4df0b5297064e85bc91f6c37dc5283af`.
- Path count: `29` (`6` explicit successor paths plus `23` files beneath
  `com.rice.ai-codedb/Payload~/Generations/poc.37/`).
- Identity method: current Git blob ID for each authorized path; ordinal sort
  by repository-relative path; concatenate `path<TAB>blob<LF>` with one
  terminal LF; encode as UTF-8 without BOM; run `git hash-object --stdin` once.
- Identity result: `FAIL / DRIFT`. No second calculation, replacement freeze,
  semantic inference, or repair was attempted.

## Findings

1. `P1 / FROZEN_IDENTITY_DRIFT`: the exact successor snapshot presented for
   review does not match the authorized 29-path identity. The verifier cannot
   bind Coder's recorded evidence or any source-level conclusion to the
   current bytes. This blocks the requested review admission; it is not a
   finding that the installer implementation or successor metadata is
   semantically incorrect.

No additional finding was opened because review stopped at admission.

## Reused Evidence And Boundaries

- Recorded but not promoted to current-snapshot PASS: Coder static/source
  closure PASS, focused Provider-installer fixture exit `0` (approximately
  `10.5 s`), scoped diff-check PASS, and generation-manifest SHA-256
  `cb0d06c32c6065a67ecb8a0d612e5fc148a80f516ac459ccdf1aa7176ada4fab`.
  Identity drift prevents binding those records to the admitted snapshot.
- Tests/static batches/diff-checks rerun by Verifier: `none`.
- Installer Package-version semantics, caller behavior, Provider
  artifact/hash/protocol/capability preservation, focused fixture coverage,
  successor metadata/hash/pointer closure, and predecessor/tag immutability:
  `NOT REVIEWED` after the admission stop.
- Unity, Unity MCP, CUA, BatchMode, real Provider installation, external
  project/runtime inspection, process probing or termination, full diff,
  repository-wide search, commit, tag, push, publication, and release
  promotion: `NOT RUN / DEFERRED`.
- `VERIFICATION-01.md`, production, tests, TASK, RESULT, ROUTE, and all other
  task records were preserved.

## Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`  
Current status: `BLOCKED / FROZEN_IDENTITY_DRIFT`  
Next notification: `UnityCodeDB v0.3 Planner`  
Next action: Planner reconciles the frozen snapshot/evidence boundary and
returns the disposition to the user. The Verifier does not repair, recompute,
or select a replacement identity.  
Human decision or authorization required: `ACCEPT / FIX / DEFER / STOP`.

当前 S18 Post-Publication FIX 01 定向验收已完成；下一步需要通知 Planner
汇总，并由用户决定 `ACCEPT / FIX / DEFER / STOP`。本报告不授权任何后续
发布动作。

## FIX 02 Identity Reconciled - Reopened GUARDED Review

- Review date: `2026-09-18`.
- Verdict for this reopened, original-scope review: `PASS`.
- The preceding `BLOCKED / FROZEN_IDENTITY_DRIFT` report is preserved as the
  historical admission result under the former freeze. RESULT's FIX 02 and
  ROUTE's explicit reopen authorization establish that `4b577...` resulted
  from PowerShell default string sorting, not changed bytes. This section does
  not overwrite or silently reinterpret that prior stop.

### Reopened Admission

- HEAD observed once: `983e091bbf5973fbb799a6e044dec028ef5b9720`, matching
  the frozen HEAD.
- Exactly 29 unique paths: six authorized explicit files and 23 files in
  `com.rice.ai-codedb/Payload~/Generations/poc.37/`.
- One current-blob identity calculation used ordinal path sorting,
  `path<TAB>blob<LF>`, terminal LF, and UTF-8 without BOM. Observed
  `b4af83cc4df0b5297064e85bc91f6c37dc5283af`, matching the sole
  reconciled canonical identity. Admission: `PASS`. No new freeze was
  invented or substituted.

### Original Finding And Adjacent Regressions

1. **Installer Package-version mismatch: `PASS`.** The installer parameter
   default and internal runtime contract are both `0.3.0-preview.3`
   (`Tools~/install-codedb-provider.ps1:5,26`); the ordinal mismatch gate
   rejects a different caller value before installation (`:700-704`). The
   `package.json`, payload manifest, generation manifest, and pointer all
   declare `.3`. The real synchronous and asynchronous Editor callers pass
   the current Package runtime contract's `Target.PackageVersion`
   (`Editor/AICodedbActions.cs:332-389`), not the old `.1` workaround.

2. **Fixed Provider identity and isolation: `PASS` within source/fixture
   evidence.** The Package-owned direct Provider contract retains version
   `0.5.0-28e3912-c2`, commit `28e3912d5cd67ff3499734984f3e3d626a204796`,
   executable hash `38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7`,
   `codedb-cli-v1`, and `codedb-search-tools-v1`; installer validation checks
   distribution and installed manifest identity and executable hash. Test mode
   remains restricted to an isolated temporary script and requires isolated
   LocalAppData/artifact paths (`install-codedb-provider.ps1:685-736`). Real
   Provider installation and optional real-artifact fixture branch were not
   exercised by this review.

3. **Focused fixture and negatives: `PASS` on reused L0.** Its three valid
   invocation helpers pass `.3` (`test-codedb-provider-installer.ps1:136-193`);
   `.1` remains only the intentional schema-2 package-coupling negative case.
   The fixture retains production TestMode rejection, timeout/non-mutation,
   development and signed-release paths, distribution identity/schema/hash/
   protocol/capability rejection, tamper/idempotence/rollback/recovery, and
   historical Provider sentinel assertions (`:206-409`). The recorded single
   focused run exited `0` in approximately `10.5 s` and ended with
   `[OK] Provider installer focused regression passed.`

4. **Successor and predecessor closure: `PASS` on direct metadata plus reused
   bounded hash/immutability evidence.** `package.json`, payload manifest,
   `host-current.json`, and the 22-entry generation manifest align on
   `0.3.0-preview.3 / poc.37 / 37`. The pointer and payload entry bind the
   successor generation-manifest SHA-256
   `cb0d06c32c6065a67ecb8a0d612e5fc148a80f516ac459ccdf1aa7176ada4fab`.
   The manifest contains 46 current file targets, six bootstrap transitions,
   and 304 retired targets; its one `poc.36` transition binds the published
   `v0.3.0-preview.2 / poc.36 / 36` predecessor. The adjacent Package-boundary
   assertions specify 23 successor generation files, direct hash/pointer
   closure, 23 predecessor files, and exact retired-target closure
   (`test-codedb-package-boundary.ps1:413-424,426-566,624-641`). The Coder
   static/source PASS records all successor hashes and that the 23 `poc.36`
   tracked files match HEAD. Planner separately recorded that the published
   `.2` tag still resolves to this frozen HEAD. Neither predecessor bytes nor
   remote tag was independently rechecked in this review.

### Findings And Evidence Boundaries

- One-time findings for the reopened original scope: **none**. The old
  identity-admission P1 is resolved by the explicitly authorized FIX 02
  serialization reconciliation; it is not a product-code finding.
- Reused: Coder final static/source `PASS` (exit `0`, `643 ms`); focused
  installer fixture exit `0` (approximately `10.5 s`, retry `0`); scoped
  `git diff --check` exit `0` (CRLF warnings only, no whitespace errors);
  FIX 02 path/order/byte reconciliation; generation-manifest SHA-256 above;
  Planner's bounded predecessor/tag admission.
- Tests, static/source batches, diff-checks, Package-boundary execution, and
  full/hash regression rerun by Verifier: `none`.
- `NOT RUN / DEFERRED`: Unity, Unity MCP/CUA/BatchMode, actual Provider
  installation and optional real-artifact fixture path, external Package-only
  project/real Codex acceptance, process/runtime inspection, Node/C#/EditMode,
  broad regression, independent remote tag inspection, commit, tag, push,
  publication, and release promotion. The current `.3` successor is
  uncommitted and unpublished; this verdict does not accept the external
  consumer/release path.

### Reopened Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`  
Current status: `PASS / POST_PUBLICATION_FIX_01_TARGETED_REVIEW_COMPLETE`  
Next notification: `UnityCodeDB v0.3 Planner`  
Next action: Planner summarizes this bounded result; Planner/User decides
`ACCEPT / FIX / DEFER / STOP`. No subsequent publication is authorized by this
review.

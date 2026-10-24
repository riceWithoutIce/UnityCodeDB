# Verification 03: S18 preview.4 / poc.38 successor

## Outcome

- Verdict: `FAIL`.
- Review date: `2026-09-19`.
- Mode: `GUARDED`, targeted and read-only except for this report.
- Scope: the frozen `0.3.0-preview.4 / poc.38` Package successor, original
  external hash blocker, retired-`poc.37` FIX 01, portable Owner Identity v2
  fixture, predecessor immutability, and directly adjacent Package-boundary
  assertions only.
- One in-scope P1 remains open in the frozen 32-path snapshot. No repair was
  requested or attempted.

## Frozen Admission

- Branch: `codex/v0.3.0-legacy-workflow`.
- Expected and observed HEAD:
  `645f5effbe9f386600c216abaa3e7a9f3a0c233b`.
- Exact path count: `32` unique paths: seven Package/installer/test paths,
  23 files beneath `Payload~/Generations/poc.38/`, and the Owner Identity v2
  fixture JSON plus `.meta`.
- Canonical identity method: current Git blob for each path; repository-relative
  paths sorted with `StringComparer.Ordinal`; serialize `path<TAB>blob<LF>`
  with terminal LF; encode UTF-8 without BOM; compute SHA-256.
- Expected and observed canonical identity:
  `d028ea1551f3ff212a7098e7aa7c2432769a584c43b29f879b63a260ad9baadb`.
- Admission result: `PASS`; no byte or path-set drift.
- Mechanical note: the first command-construction attempt incorrectly sent
  the canonical byte stream to Git's default SHA-1 `hash-object`, yielding a
  non-canonical 40-hex value. One corrected SHA-256 calculation produced the
  frozen 64-hex identity above. This was not treated as drift and no further
  identity calculation was performed.

## Finding

### P1-01: Portable Owner Identity fixture is stale against the final runtime contract

The final Package runtime contract is the current
`Payload~/payload-manifest.json`; its actual SHA-256 is
`46faed01a92cf0579bb08cccedf51a840f281a718232c15bbae49f7cc4f7d842`.
The frozen `Tests/Editor/OwnerIdentityV2Status.json` still stores
`053e93d3c1b53d16448722740226ecd7b114d6e6f00b7da3360c0052a4d87b23`
in both `status.runtime_contract_sha256` and
`status.operational_readiness.runtime_contract_sha256`.

RESULT records that `053e93...` was the current manifest hash when the focused
Node fixture passed and the sample was synchronized. FIX 01 subsequently
changed `payload-manifest.json` to repair 23 retired `poc.37` targets, changing
the Package runtime-contract identity, but the admitted sample was not
regenerated. The Node harness does derive `TARGET` and `CONTROL_CONTRACT` from
the current manifest and preserves runtime-contract fields during
normalization (`test-codedb-project-supervisor.mjs:25-70,2164-2179`), so a
fresh run would be expected to produce the current identity; rerunning it is
explicitly forbidden here. The existing Package-boundary assertions check the
fixture for machine-local paths and general production contract fields, but do
not bind this stored sample's two runtime-contract hashes to the current
manifest.

Impact: the recorded focused Node PASS and stored cross-language sample cannot
be attributed to the final FIX 01 32-path snapshot. This does not demonstrate
a production runtime failure, but it leaves authorized criterion 4 and its
direct adjacent regression evidence unclosed. Therefore the targeted review
cannot return PASS.

No additional finding was identified within the authorized scope.

## Criterion Results

1. **preview.4 / poc.38 Package closure: `PASS` for directly read metadata and
   reused hash evidence.** `package.json`, installer default/internal Package
   version, payload manifest, pointer, and generation manifest agree on
   `0.3.0-preview.4 / poc.38 / 38`. The generation manifest contains 22
   payload entries and its directory contains those exact 22 payload files
   plus the manifest. Provider identity remains `0.5.0-28e3912-c2`, protocol
   `codedb-cli-v1`, and capability `codedb-search-tools-v1`. The Editor caller
   supplies `Target.PackageVersion` from the resolved Package manifest.

2. **Original external `host-current.json` blocker: `PASS`.** The payload
   manifest binds `host-current.json` to
   `88128cb74863360147abc789a7bad0899b1f2360aa02bdd9b8405791cbdc5040`,
   which equals the actual successor source SHA-256. The pointer and payload
   manifest also bind the actual `poc.38` generation-manifest hash
   `4b2cfced7397b9c1616274ca35ce170c8c497124c9206982f9d34acd16903c2a`.
   The published preview.3 source-hash mismatch is not repeated in this
   snapshot.

3. **FIX 01 retired `poc.37` closure: `PASS`.** Exactly 23 retired targets use
   `AIWork/.runtime/codedb/host/generations/poc.37/<suffix>`; zero contain the
   malformed `poc.37/ayload~/Generations/poc.37` segment, and their sorted set
   exactly matches all 23 files in the immutable `poc.37` generation.

4. **Portable Owner Identity v2 fixture: `FAIL`.** The stored sample uses
   portable `fixture://` values, contains no drive-qualified environment path
   and no secret-bearing key, and carries `poc.38` plus current control-contract
   identity. Its runtime-contract hashes are nevertheless stale as described
   in P1-01.

5. **Predecessor immutability: `PASS` on reused evidence.** Coder's bounded
   source closure reports no worktree drift in published `poc.36` or `poc.37`.
   Package-boundary evidence also passed its predecessor and retired-generation
   closure. Verifier did not rerun a Git diff or independently inspect remote
   tags.

6. **Direct adjacent Package-boundary regression: `PARTIAL / FAIL`.** The
   assertions cover candidate version/generation, source hashes, pointer and
   generation-manifest binding, exact current and retired generation closure,
   `poc.37` transition identity, predecessor hard-code exclusions, installer
   `.4` coupling, and Package-wide machine-local-path rejection. They do not
   assert that `OwnerIdentityV2Status.json` is bound to the current
   payload-manifest hash, which allowed P1-01 to coexist with the recorded
   Package-boundary PASS.

## Reused Evidence

- Owner Identity focused Node fixture: `PASS`, exit `0`, `5402 ms`, retry `0`
  against the pre-FIX-01 manifest identity; not promoted to final-snapshot
  contract PASS because of P1-01.
- Bounded fixture/source check: recorded `PASS`; portable path and secret
  claims remain supported, but its runtime-contract check preceded FIX 01.
- Corrected Package-boundary L0: `PASS`, exit `0`, `4167 ms`, retry `0`.
- Exact 32-path scoped `git diff --check`: `PASS`, exit `0`, `124 ms`.
- Coder canonical successor identity and predecessor immutability evidence were
  reused; identity admission was independently confirmed as stated above.

## NOT RUN / DEFERRED

- Tests, Node, static/source batch, Package-boundary L0, diff-check, C# compile,
  EditMode, Unity, Unity MCP, CUA, BatchMode, real Provider installation,
  external consumer/real Codex acceptance, process/runtime inspection, full or
  broad diff, repository-wide search, and unrelated audit: `NOT RUN`.
- Independent remote tag inspection, commit, tag, push, Package publication,
  artifact export, stable promotion, and release acceptance: `DEFERRED`.
- The targeted source SHA checks above were read-only admission/claim checks,
  not a rerun of the Coder static or Package-boundary batches.

## Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`  
Current status: `FAIL / PORTABLE_FIXTURE_RUNTIME_CONTRACT_STALE`  
Next actor: `UnityCodeDB v0.3 Planner / User`  
Next action: decide `ACCEPT / FIX / DEFER / STOP`. The Verifier does not
contact Coder, dispatch a repair, or route another role.  

当前 S18 定向验收已完成；下一步由 Planner 汇总，并由用户决定
`ACCEPT / FIX / DEFER / STOP`。本报告不授权任何提交、发布或推广动作。

---

## FIX 02 Targeted Re-review - 2026-09-19

### Outcome

- Verdict: `PASS`.
- Mode: `GUARDED`, targeted, read-only FIX re-review.
- Scope: only original finding
  `P1-01 / PORTABLE_FIXTURE_RUNTIME_CONTRACT_STALE` and its directly adjacent
  Package/successor regression.
- Historical record: the original `FAIL` above is preserved as the decision for
  canonical identity
  `d028ea1551f3ff212a7098e7aa7c2432769a584c43b29f879b63a260ad9baadb`.
  This appended result reviews the repaired identity below and closes P1-01.

### Frozen Admission

- Branch: `codex/v0.3.0-legacy-workflow`.
- Expected and observed HEAD:
  `645f5effbe9f386600c216abaa3e7a9f3a0c233b`.
- Exact admitted set: `32` unique paths: seven successor/installer/test paths,
  23 files beneath `Payload~/Generations/poc.38/`, and the portable fixture
  JSON plus `.meta`.
- Canonical method: current blob per path; ordinal repository-relative path
  ordering; `path<TAB>blob<LF>` serialization with terminal LF; UTF-8 without
  BOM; SHA-256.
- Expected and observed canonical identity:
  `29552e61ee7b234518dd58574bb78181b14bea38cf6346a17c01c8683222a21c`.
- Admission result: `PASS`; the single authorized identity calculation found no
  HEAD, path-set, or byte drift.

### Finding Disposition

No finding remains within the authorized FIX 02 scope.

`P1-01` is closed. The actual SHA-256 of
`Payload~/payload-manifest.json` is
`46faed01a92cf0579bb08cccedf51a840f281a718232c15bbae49f7cc4f7d842`.
Both `status.runtime_contract_sha256` and
`status.operational_readiness.runtime_contract_sha256` in
`Tests/Editor/OwnerIdentityV2Status.json` equal that exact value.

### Criterion Results

1. **Fixture/runtime-contract binding: `PASS`.** Direct read of the final
   fixture confirms both stored runtime-contract fields equal the actual
   current manifest SHA-256. The fixture blob is
   `94e66191fe5f75de86ac7f762e9b6a229847cf63`, matching RESULT's final record.

2. **Portable current successor sample: `PASS`.** The fixture retains
   `fixture://` project, runtime, executable, and Coordinator values; fixed
   deterministic identities and timestamps; no machine-local absolute path or
   secret value. Its generation, target generation, selected generation, and
   operational-readiness generation all remain `poc.38`, with
   `owner_identity_version = 2`.

3. **Independent adjacent assertion: `PASS`.** The Package-boundary test loads
   the stored fixture, independently computes the actual
   `payload-manifest.json` SHA-256 with `Get-FileHash`, and separately compares
   both stored runtime-contract fields to that value
   (`test-codedb-package-boundary.ps1:303-314`). Its final blob is
   `8f24f576fbda9d2d2a9d81993c80bc463c4584a0`, matching RESULT.

4. **Adjacent FIX 01 and successor closure: `PASS`.** Minimal direct metadata
   reads still agree on `0.3.0-preview.4 / poc.38` across `package.json`, the
   current pointer, payload manifest, and generation manifest. The manifest
   still contains exactly 23 retired `poc.37` targets and zero malformed
   `poc.37/ayload~/Generations/poc.37` targets. The manifest blob remains
   `b9af2e75e91ca9bbf8b7a528a0dafa53345ecb51`, and the unchanged Node generator
   blob remains `e4977584be9fcaad338df0c22996935a2ef9b5b6`, both matching RESULT.

5. **Published predecessor immutability: `PASS` on reused evidence.** Coder's
   FIX 02 ledger records no modification to published `.2/poc.36` or
   `.3/poc.37` bytes, and the post-fix Package-boundary PASS retained the
   predecessor and retired-generation assertions. Verifier did not reopen or
   independently diff those published predecessor trees.

### Reused Evidence

- Focused Node Owner Identity fixture generation: `PASS`, exit `0`,
  `3746 ms`, retry `0`; generated `poc.38` portable fields and both final
  runtime-contract hashes.
- Package-boundary L0 after fixture/assertion synchronization: `PASS`, exit
  `0`, `6541 ms`, retry `0`; output
  `[OK] Standalone CodeDB package boundary passed.`
- Exact 32-path scoped `git diff --check`: `PASS`, exit `0`, `101 ms`, retry
  `0`; only recorded existing CRLF normalization warnings.
- Coder canonical identity:
  `29552e61ee7b234518dd58574bb78181b14bea38cf6346a17c01c8683222a21c`,
  independently admitted once above.

### NOT RUN / DEFERRED

- Node, Package-boundary, static/source batches, diff-check, C# compile,
  EditMode, Unity, Unity MCP, CUA, BatchMode, external consumer, real Provider
  installation, external/runtime process inspection, broad diff,
  repository-wide search, unrelated audit, and any other test: `NOT RUN`.
- Commit, artifact export, tag, push, publication, promotion, remote release
  inspection, and release acceptance: `DEFERRED`; this review grants none of
  those authorizations.

### FIX 02 Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`  
Current status: `PASS / FIX_02_P1_01_CLOSED`  
Next actor: `UnityCodeDB v0.3 Planner / User`  
Next action: decide `ACCEPT / FIX / DEFER / STOP`. The Verifier does not route
another role, contact Coder, or dispatch repair work.  

FIX 02 targeted re-review is complete. Planner/User must decide
`ACCEPT / FIX / DEFER / STOP`.

---

## Release-byte Normalization Closure Review - 2026-09-19

### Outcome

- Verdict: `PASS / RELEASE_BYTE_NORMALIZATION_CLOSED`.
- Mode: `GUARDED`, targeted and read-only except for this appended report.
- Scope: release-byte normalization closure and its immediate generation,
  pointer, payload-manifest, and portable-fixture hash chain only.
- Findings: `none` within the authorized scope.
- All earlier VERIFICATION-03 decisions above remain preserved as historical
  records for their respective frozen identities.

### Frozen Prospective Admission

- Branch: `codex/v0.3.0-legacy-workflow`.
- Expected and observed HEAD:
  `645f5effbe9f386600c216abaa3e7a9f3a0c233b`.
- Exact admitted set: `32` unique paths: nine Package/Provider/test/fixture
  paths and exactly 23 files beneath `Payload~/Generations/poc.38/`.
- An isolated temporary `GIT_INDEX_FILE` was initialized from HEAD and only
  these 32 paths were added. The prospective stage-0 blobs were ordered by
  ordinal repository-relative path and serialized as
  `path<TAB>blob<LF>` with terminal LF and UTF-8 without BOM, then SHA-256
  hashed.
- Expected and observed canonical prospective commit identity:
  `c67d6ebe4721fa5eb6bfa70f8d153a139ec4827e56cff60ed458704281cce723`.
- Admission result: `PASS`; path count, path uniqueness, HEAD, and identity all
  matched the frozen candidate.
- Real Git index guard: SHA-256
  `051d186b053a4ed7c70d92601d5ed66c107e5301a65361e91bef77c12ec5fba4`
  before, immediately after, and at final confirmation; length remained
  `91342` bytes. The real index was not selected or mutated.

### Release-byte Results

1. **LF and prospective-byte stability: `PASS`.** Root `.gitattributes`
   requires `* text=auto eol=lf` and explicit LF for JSON, MJS, PowerShell,
   TOML, metadata, and related text; the Package `.gitattributes` reinforces
   LF for Payload, Tools, and test scripts. `git check-attr` reports
   `text: set` and `eol: lf` for the hash-chain JSON and fixture paths. Direct
   byte inspection of the 23 `poc.38` generation files, `host-current.json`,
   `payload-manifest.json`, the portable fixture, and `package.json` found zero
   CRLF and zero UTF-8 BOM files. All 26 hash-authoritative successor files had
   worktree raw blobs identical to their isolated prospective blobs; Package
   metadata was also byte-identical (`1/1`). No normalization drift remains.

2. **Generation closure: `PASS`.** The generation manifest contains 22 payload
   entries and all `22/22` actual payload SHA-256 values match. The final
   generation-manifest SHA-256 is
   `b176c13aeb19d183e388290c6617567e19b61ade9b467dca7160310d00424638`.

3. **Pointer and payload-manifest chain: `PASS`.** The pointer's
   `generation_manifest_sha256` and the unique payload-manifest generation
   entry both equal the final generation-manifest SHA-256. The final
   `host-current.json` SHA-256 is
   `29bc2bb14e06885253146594472060cc3847e062978c1301f1505379b133cea3`,
   and the unique payload-manifest `host-current.json` entry equals it. The
   final payload-manifest SHA-256 is
   `ce84b9ac6e009024eb757ef815215c848042dbc3714883a2a3cd9fb7338e366a`.

4. **Portable fixture binding: `PASS`.** Both
   `status.runtime_contract_sha256` and
   `status.operational_readiness.runtime_contract_sha256` equal the final
   payload-manifest SHA-256. Generation, target generation, selected
   generation, and readiness generation remain `poc.38`; owner identity is
   version 2. Parsed string inspection found no drive-qualified, Unix
   machine-local, or non-pipe UNC value and no secret-bearing key. Project,
   runtime, executable, and Coordinator paths remain `fixture://` values; the
   single Windows path is the expected deterministic `\\.\pipe\...` name.

5. **Adjacent Package closure: `PASS`.** Prospective Package metadata is
   stable and remains `0.3.0-preview.4 / poc.38 / 38` across `package.json`,
   current pointer, payload manifest, and generation manifest. FIX 01 remains
   closed: all 23 `poc.37` retired targets use the canonical
   `AIWork/.runtime/codedb/host/generations/poc.37/<suffix>` prefix and none
   contains the former malformed segment.

6. **Published predecessor immutability: `PASS` on reused evidence.** Coder's
   isolated prospective-byte closure records no drift in published
   `poc.36` or `poc.37`; no historical generation payload was modified by the
   normalization correction. Verifier did not independently diff or reopen
   those predecessor trees.

### Reused Coder Evidence

- Corrected focused Node fixture generation: `PASS`, exit `0`, `3607 ms`.
- Corrected Package-boundary L0: `PASS`, exit `0`, `3170 ms`; output
  `[OK] Standalone CodeDB package boundary passed.`
- Exact 32-path scoped `git diff --check`: `PASS`, exit `0`, `38 ms`, no
  output.
- Isolated prospective-byte closure: `PASS`, exit `0`, `349 ms`; `22/22`
  generation hashes, pointer/manifest entries, fixture `2/2`, authoritative
  byte matches `26/26`, Package bytes, and predecessor no-drift.
- Coder prospective identity:
  `c67d6ebe4721fa5eb6bfa70f8d153a139ec4827e56cff60ed458704281cce723`,
  independently admitted above.
- Removal L0 was omitted as not directly coupled to normalization.

### Verifier Mechanical Notes

- The first admission command was rejected before process creation because its
  cleanup text used a disallowed temporary-file removal form. It created no
  temporary index, ran no Git operation, and consumed no candidate evidence.
  The corrected command validated the system temporary root and used
  non-recursive cleanup, producing the single effective admission above.
- One read-only hash-chain helper initially assigned the PowerShell reserved
  `$Host` variable, so that helper could not populate the pointer object and
  printed one invalid local comparison. Renaming it to `$pointer` confirmed
  the declared and actual generation-manifest hashes are identical. Neither
  incident was a candidate/product assertion failure or a test rerun.

### NOT RUN / DEFERRED

- Node, Package-boundary, removal, static/source, diff-check, C# compile,
  EditMode, Unity, Unity MCP, CUA, BatchMode, external consumer, Provider
  installation, external/runtime process inspection, broad diff,
  repository-wide search, unrelated audit, and any other test: `NOT RUN` by
  Verifier.
- Commit, final artifact export, tag, push, publication, promotion, and release
  action: `DEFERRED`; this review authorizes none of them.

### Release-byte Handoff

Current task: `cdb-v0.3-p0-s18-preview-release-acceptance-closure`  
Current status: `PASS / RELEASE_BYTE_NORMALIZATION_CLOSED`  
Next actor: `UnityCodeDB v0.3 Planner / User`  
Next action: decide `ACCEPT / FIX / DEFER / STOP`. The Verifier does not route
another role, contact Coder, or dispatch repair work.  

The S18 release-byte closure review is complete. Planner/User must decide
`ACCEPT / FIX / DEFER / STOP`.

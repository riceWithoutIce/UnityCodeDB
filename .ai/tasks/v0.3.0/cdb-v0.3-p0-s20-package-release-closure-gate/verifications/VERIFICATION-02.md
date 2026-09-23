# Verification: cdb-v0.3-p0-s20-package-release-closure-gate FIX 02

## Verdict

- Review mode: RELEASE / FAST_SUBAGENT targeted FIX re-review
- Status: PASS
- Original findings: P1-01 CLOSED; P1-02 CLOSED
- One-time findings: none (BLOCKER 0, P1 0, P2 0, FOLLOW-UP 0)
- Scope: original P1-01/P1-02 and directly adjacent regression only

## Finding Closure

### P1-01 - CLOSED

`export-codedb-package.ps1` now:

- resolves the validator from the requested commit-staged Package;
- validates those commit-staged bytes before export;
- creates entries in ordinal path order with the fixed legal ZIP timestamp
  `1980-01-01T00:00:00+00:00`;
- loads `System.IO.Compression.FileSystem` for Windows PowerShell 5.1;
- extracts the exact emitted ZIP into a distinct review root;
- requires exactly one `com.rice.ai-codedb` root; and
- invokes the validator contained in that extracted Package in validation-only
  mode before calculating and reporting the successful artifact result.

The export route no longer rewrites canonical metadata or resolves a validator
from the current worktree. Read-only inventory of the final ZIP found 477 file
entries, one root, zero duplicate paths, and one timestamp shared by all 477
entries. The validator and exporter bytes inside the ZIP match the corresponding
files at frozen HEAD exactly.

### P1-02 - CLOSED

`test-codedb-package-release-closure.ps1` now reads `package.json` and validates
the complete Package/payload/host-current/generation tuple: owner, package
version, payload version and sequence, generation id and relative path,
bootstrap protocol, generation/host cross-hashes, canonical control-contract
identity, and both runtime-contract identity consumers.

No preview version or `poc.*` identity is hard-coded in the validator. Normal
execution remains validation-only; all metadata writes remain behind the
explicit `-RepairCanonicalMetadata` switch.

## Frozen Identity

- HEAD/final source commit:
  `399e81412820999889c7273e0f5489071e99218e` - PASS
- FIX 02 commit:
  `03fe35e732b381b21652c571d52a1976755d3db3` - PASS; exact two-tool path set
- ZIP compatibility commit:
  `399e81412820999889c7273e0f5489071e99218e` - PASS; exporter-only one-line
  assembly-load change
- Commit ancestry: `a2b2223` -> `03fe35e` -> `399e814` - PASS
- Final artifact:
  `.artifacts/v0.3.0-preview.5-s20-zipfix-399e814-final/com.rice.ai-codedb.zip`
- ZIP SHA-256:
  `a947ae36f24c1ab870567613abe9ca3df986f8ac5dd8a93903a02f8492a1c2a9`
  - PASS
- ZIP inventory: 477 entries/files, one `com.rice.ai-codedb` root,
  zero duplicate paths, 9,472,805 uncompressed bytes, one fixed timestamp - PASS
- Current two tool files match frozen HEAD and their exact ZIP entries - PASS
- Preserved S19 failure artifact and incomplete FIX 02 artifact remain present
  and non-authoritative - PASS

## Reused Evidence

- Final exporter attempt: PASS, 1/1, no retry.
- Commit-staged Package validator: PASS, 46/46 sources, 0 mismatches.
- Exact emitted ZIP internal validator: PASS, 46/46 sources, 0 mismatches.
- Generation-manifest SHA-256:
  `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`.
- Host-current SHA-256:
  `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`.
- Runtime-contract SHA-256:
  `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`.
- PowerShell AST and scoped `git diff --check`: PASS.
- Previously recorded Package-boundary L0: PASS; not rerun for this re-review.

Verifier did not rerun the exporter, closure validator, Package-boundary L0,
or any other test. Review activity was limited to frozen identity admission,
the two original finding areas, exact commit path sets, and read-only archive
inventory.

## NOT RUN / DEFERRED

- Unity, Unity MCP, EditMode: NOT RUN / DEFERRED
- External Configure Dependencies and consumer acceptance: NOT RUN / DEFERRED
- Provider/runtime process probes and full regression: NOT RUN
- Commit, push, tag, publication, artifact replacement/deletion, and Coder
  contact: NOT PERFORMED

## Handoff

- Current task: `cdb-v0.3-p0-s20-package-release-closure-gate`
- Current status: PASS
- Next notification: UnityCodeDB v0.3 Planner / User
- Next action: decide ACCEPT / FIX / DEFER / STOP.
- Human authorization remains required for any downstream Unity/external gate,
  commit of task evidence, push, tag, or publication.

S20 RELEASE 定向 FIX 复审已完成，下一步由 Planner/User 决定 ACCEPT /
FIX / DEFER / STOP。不要自行派发下一角色。

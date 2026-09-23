# Verification: cdb-v0.3-p0-s20-package-release-closure-gate

## Verdict

- Review mode: RELEASE / FAST_SUBAGENT
- Status: FAIL / RELEASE_CLOSURE_IMPLEMENTATION_INCOMPLETE
- One-time findings: BLOCKER 0, P1 2, P2 0, FOLLOW-UP 0
- Scope: frozen S20 release-closure claims and directly adjacent regression only

## Findings

### P1-01 - The exporter does not enforce closure on the exact ZIP it emits

`com.rice.ai-codedb/Tests~/export-codedb-package.ps1` exports the requested
commit, extracts the Git archive, invokes the validator on that staging tree,
and then creates the ZIP (lines 30-44). It never extracts the emitted ZIP and
never invokes the read-only validator on those consumed bytes. The validator
path at line 21 is also resolved from the current worktree rather than from the
requested commit, so a dirty or different worktree validator can participate
in an otherwise commit-addressed export.

The current artifact remains reviewable because Coder separately recorded an
independent extracted-ZIP validation and the current validator bytes match the
frozen commit. That one-run evidence does not make the exporter enforce the
v2.3 rule that every future success must validate the exact emitted archive.

The helper also rewrites the three metadata files before compression. Archive
inventory shows 474 file entries at the commit timestamp and those three
entries at a later export timestamp. Consequently, repeated exports can have a
different ZIP identity despite identical content, so the claimed deterministic
artifact identity is not currently enforced.

### P1-02 - The canonical validator does not close the full identity tuple

`com.rice.ai-codedb/Tests~/test-codedb-package-release-closure.ps1` validates
all declared source hashes and checks generation hash, host-current hash, and
three generation-to-payload fields (lines 95-142). It does not read
`package.json`; does not compare host-current package version, payload version,
payload sequence, or generation id with the payload/generation authorities;
does not compare generation payload version; and does not enforce the declared
runtime-contract identity. Those fields can therefore drift while this
canonical validator still reports PASS.

The exact frozen snapshot currently has matching values for package version
`0.3.0-preview.5`, payload/generation `poc.39`, and sequence `39`, and the reused
Package-boundary L0 covers the current fixture. The finding is that the new
release gate does not itself enforce the identity closure required by TASK.md
and workflow v2.3.

## Claim Review

- Workflow v2.3 rule: PASS. The normative workflow and templates require one
  authority, complete source enumeration, cross-hash closure, frozen-commit
  export, exact extracted-artifact validation, and downstream Unity gating.
- Canonical validator behavior: PARTIAL. Default validation-only execution has
  no write path, repair is explicit, full 46-source enumeration is implemented,
  and the preserved S19 rejection evidence is reusable. P1-02 remains open.
- Export helper: FAIL. Commit path isolation and one Package root are present,
  but exact-ZIP revalidation, commit-bound validator selection, and stable ZIP
  identity are not enforced. P1-01 remains open.
- Current metadata/artifact closure: PASS for the frozen snapshot based on
  targeted reads plus reused Coder evidence; this does not close the two tool
  contract findings.

## Frozen Identity

- HEAD/source commit: `a2b22237c32fc6b31f4e6a1d4cb9bde6eb2ab855` - PASS
- Exact committed path set: 12 paths recorded in RESULT.md - PASS
- Final artifact:
  `.artifacts/v0.3.0-preview.5-s20-a2b2223-final/com.rice.ai-codedb.zip`
- ZIP SHA-256:
  `e2899caa341f031a9ffd884d913b75ece7520fce8439efbe776c6ff1676f529c`
  - PASS
- ZIP inventory: 479 entries, 477 file entries, one
  `com.rice.ai-codedb` root, 0 duplicate entry paths, 9,464,951 uncompressed
  bytes - PASS
- Current scoped source/test files match the source commit - PASS

## Reused Evidence

- Package-boundary L0: PASS, exit 0, no retry.
- Final commit-derived extracted ZIP closure: PASS, 46/46 sources,
  0 mismatches.
- PowerShell AST and scoped diff check: PASS.
- Final export: 1/1 attempt, no retry.
- Preserved invalid S19 artifact: canonical validator rejected it at generation
  manifest cross-hash admission; no repair was applied to that artifact.

Verifier did not rerun Package-boundary L0, the closure validator, exporter, or
any other test. The verifier performed only frozen identity admission,
targeted source/metadata reads, SHA-256 admission, and read-only ZIP inventory.

## NOT RUN / DEFERRED

- Unity, Unity MCP, EditMode: NOT RUN / DEFERRED
- External Configure Dependencies and consumer acceptance: NOT RUN / DEFERRED
- Provider/runtime process probes and full regression: NOT RUN
- Commit, push, tag, publication, and Coder contact: NOT PERFORMED

## Handoff

- Current task: `cdb-v0.3-p0-s20-package-release-closure-gate`
- Current status: FAIL / RELEASE_CLOSURE_IMPLEMENTATION_INCOMPLETE
- Next notification: UnityCodeDB v0.3 Planner / User
- Next action: decide ACCEPT / FIX / DEFER / STOP for P1-01 and P1-02.
- Human authorization required: any implementation fix, evidence rerun,
  artifact replacement, commit, or downstream Unity/external gate.

S20 RELEASE 定向验收已完成，下一步由 Planner/User 决定 ACCEPT / FIX /
DEFER / STOP。不要自行派发下一角色。

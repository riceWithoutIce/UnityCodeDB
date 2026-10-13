# S29 generation alignment FIX2 — delivery preparation

Date: 2026-10-13.
Status: SOURCE_ACCEPTED / DELIVERY_AUTHORIZED / EXECUTION_ACTIVE.

User explicitly replied `批准` on 2026-10-13 to the exact grouped
commit -> exact export checks -> S29 reference switch -> human Unity checklist
proposal in this document. Execute these five steps without repeated approval,
subject to all listed preconditions and stop rules. Real Remove/Install, Unity
automation, process control, cleanup and remote publication remain outside it.

The FIX2 source/synthetic stage was accepted by the user's `同意授权` after
the independent `PASS_WITH_LIMITS` review. The accepted snapshot is:

- Candidate: `.artifacts/tests/s29-generation-alignment/fix2-a4/com.rice.ai-codedb`.
- Focused evidence: `focused-a4.log`, `GENERATION_ALIGNMENT PASS cases=35`.
- Final repair scope: five files listed in
  `INSTALLED-GENERATION-ALIGNMENT-PREFLIGHT-HANDOFF-FIX2-SOURCE-SHA256.txt`.
  Full generation-alignment delivery also includes the two unchanged approved
  implementation files and the isolated generation/fixture projection below.
- Independent review:
  `INSTALLED-GENERATION-ALIGNMENT-PREFLIGHT-HANDOFF-FIX2-IMPLEMENTATION-VERIFICATION.md`.
- Protected limitation: the pre-existing `OwnerIdentityV2Status.json` drift
  remains outside this task and was not attributed or changed.

The source stage proves the bounded historical handoff contract and synthetic
production paths. It does not prove C# compilation, Unity/EditMode, live
readiness, real Remove/Install, package export, project reference switching or
release acceptance.

No commit, export, reference switch, Unity launch, real project mutation,
cleanup, process control or remote publication was performed during this
preparation. The earlier retained-disposition delivery grant covered a prior
accepted snapshot and does not silently cover these newer FIX2 source hashes.
Those operations require a fresh exact grant naming the commit/export/switch/
human-Unity sequence and its stop conditions.

## Current read-only checks

- HEAD: `61408bc7e43a63edf2f717d299ee5da868a62894`.
- Branch: `codex/v0.3.0-legacy-workflow`.
- All five final FIX2 working source hashes match the reviewed snapshot.
- The remaining instance-engine and canonical generator hashes match the
  original implementation record and the final candidate.
- The candidate's 63-file generated projection has inventory SHA256
  `81242f1d8e0ee5ba73add1d7615a9c0797b833fd04811750846a88ae89c3f753`.
  Definition: sort relative paths case-sensitively; hash UTF-8 without BOM of
  one `relative-path raw-sha256` line per file with LF and a trailing LF.
- Raw unfiltered comparison to HEAD during delivery corrected the original
  filtered-OID count: the projection has 5 modified files and 30 added poc.43
  files. poc.42/scripts/codedb-project-common.ps1 is also raw-byte identical
  to HEAD (Git blob 5fc3a7f197a7f832d717a0930efaa78e4636c510). Its accepted
  projection SHA256 remains unchanged; no source/projection scope expanded.
- S29 references remain the previous retained-disposition extraction.
- S29 manifest preimage SHA256:
  `c723ee546d1166dd8cec9274a804d57817dc0f544db3c7bd2560abb708db6046`.
- S29 packages-lock preimage SHA256:
  `7defc8f775e20094fd9555711a68c78b224dd967b04a2c2cb289246df242b570`.
- Protected working OwnerIdentity fixture SHA256 remains
  `3cdf6ac436264ff391acafd77999b8aa62966f5295b7481cb0c004ee3afcf6a7`.
  The candidate fixture below is a distinct, approved generated projection;
  delivery must not overwrite or stage the protected working bytes.

## Exact proposed product commit scope

Seven source/test files (paths relative to com.rice.ai-codedb):

| Path | SHA256 |
| --- | --- |
| Tools~/codedb-instance-engine.ps1 | 7ee8ab147cd593028f68f0efe384308379a830d469831bd88b1bcaccc926e159 |
| Tests~/test-codedb-package-release-closure.ps1 | 162d4a4c1c9fa0aaa144d74c12f877a8952e1fc26657a08a41ab32adb1d3ca38 |
| Tools~/materialize-codedb-host-payload.ps1 | 70ce751c2a0044855f28132611d01dc84ec59c0aec0835833eff524a4a550758 |
| Tests~/test-codedb-host-payload-materializer.ps1 | 111c92202b586de960ffa392710e0f9b2e24dedfdf37f683778a394082b41cf4 |
| Editor/AICodedbHostPayloadMaterializer.cs | c229d9778f07154d8dbb74ddf5e431ecf5fe82c29d8e5f7d0e4efea3dab70b3f |
| Editor/AICodedbActions.cs | 9afd83bf12e6e2cdde38cc1630686fc9beb020bf745b6322544a4ec5fc2371e0 |
| Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs | a072bf1564b3189b766e6cacb9a23c88d79b27363d37b814c09dfa1a749013b7 |

Six existing files bound to the isolated candidate, plus all 30 new poc.43
files (35 changed projected files; 42 total product changes; the common
script in the table is byte-identical to HEAD):

| Existing projected path | Raw SHA256 |
| --- | --- |
| Payload~/payload-manifest.json | 69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a |
| Payload~/host-current.json | ef73f381ffc3f5a611b1712edaf91958cacb6dc304eec4e9d3d96495403619e1 |
| Tests/Editor/OwnerIdentityV2Status.json | 48ac99296e9aaf8676c7a9dbe21d2dede2935f55b69ad2b8b34e399fb1a58594 |
| Payload~/Generations/poc.42/generation-manifest.json | 2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026 |
| Payload~/Generations/poc.42/coordinator/codedb-watch-coordinator.mjs | 5a61242e336fac40ac5ce94729d71c676272f65510993481c80a0ee71651ed00 |
| Payload~/Generations/poc.42/scripts/codedb-project-common.ps1 | 21208a16e7f65007200995f3fc81e6b8a8695199e72eaa6fa06d1b77ba71e311 |

The exact new poc.43 inventory is its candidate generation-manifest.json
(raw SHA256 `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`)
and the 29 paths declared in that manifest. It contains no additional files;
the combined projection inventory above binds that manifest and every byte.
Original installed poc.42 project bytes and all historical artifacts stay
untouched; the Package projects the exact frozen predecessor and distinct
successor already reviewed in the source stage.

Raw Git staging preserves accepted mixed CRLF/LF bytes; use `cr-at-eol` for
whitespace diagnostics. Full staged whitespace review has one inherited
formatting FOLLOW-UP: poc.43/shared/codedb-strict-json.ps1:225 has a final empty
line. Its raw blob `1869a9e18c18a9bbed7f30d3121a31c7d2e3e97b` is identical
to the frozen predecessor script. Do not alter this immutable byte closure to
remove that warning. Source/evidence whitespace checks must be clean; report
the full staged check as PASS_WITH_INHERITED_FORMAT_LIMIT, not a blanket PASS.

Bounded evidence commit scope is the 21 currently prepared files with prefix
`INSTALLED-GENERATION-ALIGNMENT-` in this task directory: TASK; DIAGNOSIS;
RESULT; SOURCE-SHA256; CONTRACT-PROPOSAL; GAP-VERIFICATION;
IMPLEMENTATION-RESULT; IMPLEMENTATION-SOURCE-SHA256;
IMPLEMENTATION-VERIFICATION; PROJECTION-MANIFEST; PROTECTED-BASELINE;
PREFLIGHT-HANDOFF-FIX-RESULT; PREFLIGHT-HANDOFF-FIX-IMPLEMENTATION-RESULT;
PREFLIGHT-HANDOFF-FIX-IMPLEMENTATION-VERIFICATION;
PREFLIGHT-HANDOFF-FIX-PROJECTION-MANIFEST; PREFLIGHT-HANDOFF-FIX-SOURCE-SHA256;
PREFLIGHT-HANDOFF-FIX2-RESULT; PREFLIGHT-HANDOFF-FIX2-SOURCE-SHA256;
PREFLIGHT-HANDOFF-FIX2-PROJECTION-MANIFEST;
PREFLIGHT-HANDOFF-FIX2-IMPLEMENTATION-VERIFICATION; this
FIX2-DELIVERY-PREPARATION. Extensions and full names are the existing files.
No unrelated workflow/roadmap/other task or project changes enter the commit.

## Authorized bounded delivery sequence

1. Local source/evidence commit with message
   `Align immutable generations and enforce removal preflight handoff`.
   Build an isolated Git index from HEAD, add only the seven accepted source
   files, the 35 candidate projection changes, and the named bounded records.
   Compare raw staged bytes to the accepted hashes, exact path scope and
   staged diff check. Preserve the real working Payload/fixture and unrelated
   index/worktree state; no broad staging or reset.
2. Run existing Tests~/export-codedb-package.ps1 on that exact new commit into
   a new `.artifacts/s29-generation-alignment-<source-short-sha>` directory.
   No payload regeneration: use the accepted projection bytes. Require the
   existing commit-stage and exact-extraction full byte closure, production
   ValidatePayload and native VerifyOnly gates. Match accepted seven source
   hashes, 63-file projection, complete stage/extraction hashes and ZIP hash.
   PathProvenanceOnly's known inherited ManagerUi issue remains explicitly
   limited; this grant would not authorize its repair or a silent gate bypass.
3. After fresh no-S29-Unity-process and exact reference-preimage checks, back
   up and change only UnityFreshInstallValidationProjectS29/Packages/
   manifest.json and packages-lock.json to the new exact extraction. Preserve
   runtime/history/receipts, installed generations and other processes.
4. Prepare a human checklist for C# compilation, the dedicated handoff
   Editor tests, Manager open/close/tabs and normal Unity close. Human owns
   launch and execution. Parent then performs bounded read-only attribution.
   This is Package/UI acceptance only; real Remove/Install remains separate.
5. Record delivery/checklist in a local bounded evidence commit. No push,
   publication or runtime/release claim.

Stop the dependent sequence on changed accepted bytes/HEAD, unexpected stage
scope, protected-state drift since the new preflight, closure/admission/export
failure, active S29 Unity, or mismatched reference preimages. Preserve failure
evidence. No forced process termination, retry loop, historical cleanup, real
Remove/Install or generation migration is included.

# S32 authorized delivery result - 2026-10-18

Status: PRECISE COMMIT / EXACT ARTIFACT GATES / S30 REFERENCE SWITCH COMPLETE.
Human focused results are now recorded in HUMAN-RESULT.md as
HUMAN_REPORTED_PASS_WITH_LIMITS. Delivery-time observations below remain intact.
Real lifecycle acceptance is DEFERRED; no real Install/Uninstall or historical
recovery was performed.

## Grant and precise commit

User `授权` approved DELIVERY-PLAN.md's concrete 14-file candidate/projections
and complete delivery group. No repeated stage approval was requested.

- Parent: `97471f537749eba97171f6756a29112dd552a22b`.
- Commit: `b0462ed07b6a14be64bddf848e67609d9143fa71`.
- Message: `fix: route project installs directly and distinguish supervisor child execution`.
- Exactly 14 candidate files committed; four task-only projections are exactly
  those authorized in DELIVERY-PLAN.md. Staging used candidate blobs without
  overwriting working source. No task-record sweep or unrelated staging.
- Candidate manifest SHA-256:
  `6b1b6d292900e06d3138234449ee45ce85cdff5374bbc5942a2da51ffb62e210`.
- All 14 accepted working-file hashes remained unchanged; incoming timeout,
  termination, repeated-Uninstall, historical documentation and dirty Payload
  content remain local and unmodified. Index empty after commit.
- Package identity: `0.3.0-preview.5 / poc.43`; generation transition NONE.

## Exact artifact closure

Existing unchanged exporter ran once against only the new frozen commit.

- ZIP: `.artifacts/s32-install-command-b0462ed/com.rice.ai-codedb.zip`.
- ZIP SHA-256: `56fdfbe2f81fe5ff3f1ccce07c6bc7fdd65610a218450f4ead9a3afaa5500fae`.
- Extraction: `.artifacts/s32-install-command-b0462ed/review/com.rice.ai-codedb`.
- 623 files / ZIP entries, 13,347,096 extracted bytes. All 623 files match the
  frozen candidate; checked again after semantic evidence, no Package mutation.
- PASS separately for commit-staged Package and exact ZIP: production read-only
  payload admission (60 files), byte/hash closure (zero mismatches), native
  source/build/binary binding and generation/contract identity closure.
- Generation manifest SHA-256:
  `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`.
- Host-current SHA-256:
  `ef73f381ffc3f5a611b1712edaf91958cacb6dc304eec4e9d3d96495403619e1`.
- Runtime contract SHA-256:
  `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- Exact extracted Package path provenance and direct helper binding checks PASS.
- Export log: `.artifacts/delivery/s32-install-command-b0462ed/export.log`, SHA-256
  `2b8fa26a2b90407175f4be77df691d65e9612c7638ccec108a103f5d756b641b`.
- Path log in the same directory: `path-provenance.log`, SHA-256
  `ad19e1143c6d924e8b003fe779679a8bb4eeff171f54028de7b53062293e5fd8`.

## Exact artifact semantic closure

Task-local run-focused.ps1 and run-disposition.ps1 gained only optional explicit
SourcePackageRoot selection and repository-local/nonredirected root checks.
Output is derived from that Package's parent, satisfying existing production-test
entry root guards without editing the extraction or weakening assertions. Existing
case bodies and assertion families remain unchanged. New final driver SHA-256:

- run-focused.ps1: `d7059e4cd030247688a09dd0fc2b886954513dfe0e00801643ad4f736b67b4f3`.
- run-disposition.ps1: `ad8729e567a63943580c72262edf57bf9322c4147350b941fa407cb292e37d0a`.

Both runs use the exact extraction above and existing hash-bound local tools/
references. Fresh output root relative to its parent review directory:
`.artifacts/tests/s32-install/`.

- `d1` PASS: original extracted Editor and test source compilation, same three
  existing warnings (CS4014 twice, CS0414 once). Original writer/materializer's
  genuine controlled refusal -> real receipt reader -> normal/reopened Manager
  resolver -> exact release; first/retained topology, repeated admission,
  missing terminal, competing Supervisor map and pre-dispatch refusal. Existing
  install-reconcile predicate cases pass. All 25 original locked Install-guard
  admission/rejection cases pass, including F1 relevance, F2 completeness,
  hidden unfinished records, retained origin, PID reuse and live/unknown identity.
- `e1` PASS: original no-spawn producer -> terminal/durable/public serializer ->
  actual locked PowerShell reader. Sticky pre-spawn admission, legacy absence,
  failed capture and multi-child evidence checks pass; all 12 reader cases pass.
- Both first attempts passed; no mechanical correction or semantic retry.
- `d1/manifest.json` SHA-256:
  `92283643d19b77a85e6ff451a32b0822fc1acb3ad553b7d384a52db00e898b42`.
- `d1/focused-test.log` SHA-256:
  `d96f77853dc6ce2fef552a29151ceae2908216ab9479cba8ce28e982ba2942c8`.
- `d1/admission-test.log` SHA-256:
  `12c12dad56e11f0d10de98efa713a364f61d1c086858746763a467c1608971c5`.
- `e1/manifest.json` SHA-256:
  `a2eff9eb73b1ffbf2aee5074b41f1b694d07a667f6787fe385291d849eebeb68`.
- `e1/producer.log` SHA-256:
  `16f3509c35d2f676e2ba3857dd664aad4e13d6d60167ceb8e9e429d40db40533`.
- `e1/reader.log` SHA-256:
  `9a9dbe4fd17db7079b960501768496ccc4a43be03f448053f26fdb1de12eeeba`.

Evidence remains HARNESS. Process/Coordinator/retained-closure inputs are mocked;
no successful full installation, initialization, Provider, Ready or Unity result
is inferred. No live Supervisor/backend or full regression was started.

## S30 reference switch and preservation

Immediately before switching, no attributed S30 Unity process or Unity lock
was present. Both original reference file hashes matched the plan. Hash-verified
backups are under `.backups/s32-install-command-b0462ed/`.

Only S30 Packages/manifest.json and Packages/packages-lock.json CodeDB references
changed from the S31-D extraction to the exact S32 extraction. Text comparison
against backups proves all other bytes unchanged; parsed JSON references agree,
and CodeDB remains in testables.

| File | Backup SHA-256 | Current SHA-256 |
| --- | --- | --- |
| manifest.json | 599af94eb4eaeacf223e719054d9fab88f37ad41535b7ad99a386f7b11a0346e | 4403660cfa8eff983797450fd30686a3be1b96a76cae05be229d6c3e433f0273 |
| packages-lock.json | 7d73367478748ba240d9cdfead652a598e5d7ba7c558e906edea92fe35b2a3e7 | 1298107ff26332b4ff0c8bccce16fa000336294a9c031b3e52e299171c433307 |

All eight remaining protected baseline inputs match. Protected S30 pending
action `6b9678672d3744f0ab052e521ae42ad6`, runtime/config/history and old failure
evidence remain untouched. Legacy missing disposition is not repaired or made
NO_CHILD by this delivery. No action is auto-released and no real retry is granted.
No process termination, Unity/MCP/BatchMode launch, push or publication occurred.

## Handoff

Next actor: User, HUMAN-CHECKLIST.md. No reinstall/manual package replacement is
needed for compilation/tests/UI validation. Next parent action after the human
result is bounded read-only verification. Real lifecycle and historical-state
disposition remain separate decisions; this delivery does not close them.

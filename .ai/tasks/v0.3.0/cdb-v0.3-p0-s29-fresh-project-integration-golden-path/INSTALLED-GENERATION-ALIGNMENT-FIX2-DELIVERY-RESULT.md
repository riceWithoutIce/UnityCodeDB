# S29 generation alignment FIX2 — delivery result

Date: 2026-10-13.
Status: REFERENCE_SWITCH_COMPLETE / HUMAN_COMPILE_FAILED.

Subsequent human report on 2026-10-13: exact Package compilation failed with
CS7036 in RunUpgradeAsync at AICodedbHostPayloadMaterializer.cs(107,20).
Read-only source/hash/log checks confirm a missing fifth argument, not delivery
drift. See FIX2-HUMAN-COMPILE-FAILURE.md with this document's prefix. The
delivery-time NOT_RUN observations below are preserved historically; current
human compilation is FAIL and dependent acceptance is stopped.

The user approved the exact grouped delivery in FIX2-DELIVERY-PREPARATION.md.
Local source commit, exact export verification and two-file S29 reference
switch are complete. The human checklist is
INSTALLED-GENERATION-ALIGNMENT-FIX2-HUMAN-CHECKLIST.md.

## Exact source and artifact

- Branch: `codex/v0.3.0-legacy-workflow`.
- Source commit: `d127a45eafa62f04f25a4b578839e6056e46299a`.
- Parent: `61408bc7e43a63edf2f717d299ee5da868a62894`.
- Tree: `43b81038e0c9aa11d37b3ea41af8ecd8005d6d32`.
- Commit message: `Align immutable generations and enforce removal preflight handoff`.
- Exact diff: 63 files, comprising 42 product and 21 task/evidence files.
  The product scope is seven source/test changes and 35 projection changes.
- ZIP: `.artifacts/s29-generation-alignment-d127a45/com.rice.ai-codedb.zip`.
- ZIP SHA256: `d94632952236e33d34129aba2f412465ea826fc0ca67e2c7ce6896d9ee5764bf`.
- Exact review: `.artifacts/s29-generation-alignment-d127a45/review/com.rice.ai-codedb`.
- Inventory: 617 files/ZIP entries; 13,055,564 uncompressed bytes.

Existing export gates passed on both commit-stage Package and exact ZIP:
60-file byte closure with zero mismatches, production ValidatePayload admission
and native VerifyOnly. All 617 stage/extraction files match. Seven accepted
source files plus 63 projected files match their accepted hashes. All 30 original
poc.42 predecessor files match the frozen predecessor, with zero mismatches.
No payload regeneration or second export was performed.

The 63-file projection inventory SHA256 is
`81242f1d8e0ee5ba73add1d7615a9c0797b833fd04811750846a88ae89c3f753`.
Package runtime SHA256 is
`69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`;
poc.43 manifest SHA256 is
`55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`.

## Reference switch and preservation

A fresh read-only process check found no S29 Unity before switching references.
Backup: `.backups/s29-generation-alignment-d127a45`.
Only S29 `Packages/manifest.json` and `Packages/packages-lock.json` changed to:
`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-generation-alignment-d127a45/review/com.rice.ai-codedb`.

| S29 reference file | Before SHA256 | After SHA256 |
| --- | --- | --- |
| manifest.json | c723ee546d1166dd8cec9274a804d57817dc0f544db3c7bd2560abb708db6046 | 16978556a0816b9b58f731b84f6f63f1122335debc0d26ea2ba4be6bcf9fd759 |
| packages-lock.json | 7defc8f775e20094fd9555711a68c78b224dd967b04a2c2cb289246df242b570 | 0b5c064ec498d2123326b13c3254078d63c907d4389587ad13c34ffcb0918c0f |

Both JSON documents parse. Each has exactly one reference replacement, and
the complete text equals its backup with only that replacement. Final bounded
protection checks passed: seven non-reference protected roots and all 33
originally dirty tracked files retain their pre-delivery bytes. The eighth
protected root, S29 Packages, contains exactly the two authorized reference
files with the recorded hashes and verified backup preimages. AIWork, actual
receipts, previous artifacts, installed runtime and unrelated processes were
not mutated by this delivery.

The commit used an isolated index and accepted candidate projection. Working
Payload/OwnerIdentity fixture bytes remain preserved. New committed poc.43
files were not copied into the working tree, so Git may show their absence as
working-tree deletions; this is intentional preservation and not runtime
removal. Do not reset/checkout those protected paths to clean the worktree.
The normal index was updated only for committed paths; no staged changes
remained after the source commit.

## Evidence limits and retained follow-up

- Independent FIX2 review: PASS_WITH_LIMITS; user accepted the source snapshot.
- Focused production-path evidence: 35-case synthetic PASS.
- Exact source/artifact/reference/protection checks: PASS as stated above.
- Full staged formatting: PASS_WITH_INHERITED_FORMAT_LIMIT. The inherited
  `Payload~/Generations/poc.43/shared/codedb-strict-json.ps1:225` final empty
  line remains byte-identical to frozen predecessor blob
  `1869a9e18c18a9bbed7f30d3121a31c7d2e3e97b`; keep this FOLLOW-UP.
- PathProvenanceOnly retains the declared inherited ManagerUi limitation;
  no repair or blanket PASS is claimed.
- C# compilation, Unity import, focused EditMode and Manager UI: NOT_RUN /
  HUMAN_PENDING for this exact Package.
- Live readiness, real Remove/Install and release acceptance: NOT_RUN.
- Shutdown hang: deferred observation, preserving earlier samples.

No Unity automation, real Install/Remove/Uninstall, cleanup, process control,
push or publication occurred. Source/static, synthetic, exact Package, human
Unity, live-operation and release evidence remain separate; S29/release stay
PARTIAL. The next action is the bounded human checklist, followed by read-only
attribution of the human result.

Repository-local ignored evidence is retained in
`.artifacts/delivery/s29-generation-alignment/`: source-commit.json,
stage-record.json, export-a1.log, artifact-inventory.json,
artifact-verification.json, reference-switch.json, final-protection.json and
staged-whitespace.json. Earlier failure/review records remain intact.

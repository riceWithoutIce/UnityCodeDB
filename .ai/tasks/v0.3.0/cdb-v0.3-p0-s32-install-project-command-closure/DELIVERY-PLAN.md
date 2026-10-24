# S32 precise delivery proposal - 2026-10-18

Status: SOURCE ACCEPTED / GROUP DELIVERY COMPLETE / HUMAN_REPORTED_PASS_WITH_LIMITS.

Execution completed as recorded in DELIVERY-RESULT.md. HUMAN-CHECKLIST.md is
the retained requested scope; HUMAN-RESULT.md records the human report and
read-only follow-up. The proposal below preserves its approved scope and baseline.

## Explicit user grant - 2026-10-18

User `授权` approves the exact 14-file candidate/projections and the entire
bounded group below: precise commit -> exact Package export/closure and focused
extracted-artifact evidence -> closed S30 reference switch. Continue without
repeated stage confirmation. Real lifecycle/history recovery, Unity/process
control, push and publication remain excluded. Earlier pending wording records
the preparation boundary only.

User `同意 accept 我们继续` accepts the reviewed source and permits reversible
delivery preparation. It does not yet authorize the operations proposed below.

## Concrete candidate

- Base HEAD: `97471f537749eba97171f6756a29112dd552a22b`.
- Source candidate: `.artifacts/tests/s32-delivery-preparation-a/candidate/com.rice.ai-codedb`.
- Candidate manifest: `.artifacts/tests/s32-delivery-preparation-a/manifest.json`.
- Manifest SHA-256: `6b1b6d292900e06d3138234449ee45ce85cdff5374bbc5942a2da51ffb62e210`.
- Preparation driver SHA-256: `f7b333db555cae486c5a830e189fa7211a4a0f35e8831b8de3fd7a672833ba65`.
- 623 files; exactly 14 task files below, all other files equal the committed base.
- Package identity: `0.3.0-preview.5 / poc.43`, generation transition NONE.
  All Payload bytes come from the committed base, not the dirty checkout.
  Changed operation producer/readers are Package Tools; immutable generation
  consumers and identity contracts are unchanged. No generation regeneration.

Paths below are Package-relative. Ten files equal the accepted source bytes;
four use mechanical task-only hunk projections from the same base:

| File | Candidate SHA-256 | Projection |
| --- | --- | --- |
| Editor/AICodedbActions.cs | 024f405b11a3c482d7d0cfd3f424e855a060469cd3653165116c9dc21bd14600 | Exact accepted bytes |
| Editor/AICodedbManagerActionJournal.cs | 0987f76cc98f5250e3018d77c88184775fb9a6cae1c91eb858e16a6f2e48bfed | Exact accepted bytes |
| Editor/AICodedbManagerWindow.cs | f62d589a32c32e31baab29c463a099a5ea002fc42859fbc716d48bf9aecf7dcc | Exact accepted bytes |
| Editor/AICodedbProcessRunner.cs | 56fe365a01da3a9b526f494080055c4d42e5b8f809849f1868d42eb4185fd32f | Only route manifest serialization/validation; excludes incoming timeout changes |
| Editor/AICodedbInstallAdmission.cs | c6cc6823ba589a675f7072643f662d70b3823019dea57442b28ed583b07650c0 | Exact accepted bytes, new |
| Editor/AICodedbInstallAdmission.cs.meta | 05d0b3f0ed5c532c2fa2b6523f6ca06eb53dce60ac2ebb765fdc04f7ae67f62b | Exact accepted bytes, new |
| Tools~/invoke-codedb-manager-action.ps1 | cb0a431dc5f0340623d5e79ea8a48a45cb5f74d883f45cce7aa31e9793d5d017 | Only route authentication/child admission locator; excludes incoming timeout/termination changes |
| Tools~/codedb-instance-engine.ps1 | 8cbf048a196ca2ee670668c2bbf349263fbbae2922aabd83316660c973cfd219 | Only Install admission functions/locked invocation; excludes incoming repeated-Uninstall idempotence |
| Tools~/codedb-project-supervisor.mjs | 4842c3ed260b05bfe0adf65bce24c8acc7cdf0b68f8d2ffc852bf301f2de92be | Exact accepted bytes |
| Tools~/materialize-codedb-host-payload.ps1 | 44b1455513b32843b801d243e04ef2fb2267795f715181f8c904ffdd80cda73b | Exact accepted bytes |
| Tests/Editor/AICodedbS32InstallTests.cs | 9726c9115d61447d6417ff5c96a03a00971ad172557a11040a6faefaefbfde59 | Exact accepted bytes, new |
| Tests/Editor/AICodedbS32InstallTests.cs.meta | 9ddb5c599dd4ffdcc8b7c2ef90acc8a1813bef025c41f6854aff268e4e6640f0 | Exact accepted bytes, new |
| Tests~/test-codedb-project-supervisor.mjs | 2d434fbd1869472e6085ebb70e450d792c9580af543afcd1e8c6693092a7bb02 | Exact accepted bytes |
| Documentation~/v0.3.0-p0-host-action-execution.md | 63e6e2b3f92c5dd14ad498d218fa8e13df840b1bdb11c1e36df8a53765efa615 | HEAD plus S32 route/convergence/disposition append; excludes incoming historical sections |

## Preparation evidence

The preparation driver generated a task-only source candidate from the exact
base, without staging/committing, exporting a distributable artifact or modifying
working source. The four projections select exactly six task hunks, then apply
them to base files. All other changes are exact accepted source files.

- PASS original candidate Editor and Editor-test compilation. Same three existing
  warnings: CS4014 twice, CS0414 once; no compile error.
- PASS original candidate Package path-provenance check and helper binding checks.
- Four new task files only; all non-task bytes equal base, including Payload.
- All 14 accepted working-source hashes remain unchanged; ten protected hashes
  match; HEAD unchanged and staged index empty.
- No semantic-test replay, Unity, backend, Install/Uninstall or S30 recovery ran.

## Proposed one-group authorization

Approve these exact task-only projections and the following bounded actions as
one group; no repeated per-command or per-stage approval inside the group:

1. Recheck the frozen candidate/source/base/index. Stage only these 14 candidate
   blobs, preserving the working-file incoming hunks and unrelated dirty state.
   Commit message: `fix: route project installs directly and distinguish supervisor child execution`.
   Do not stage task records, Payload or unrelated files.
2. Run the existing Package exporter against only the resulting frozen commit,
   using a fresh `.artifacts/s32-install-command-<commit-prefix>/` root. Preserve
   earlier artifacts. Validate exact commit-stage and ZIP extraction: full byte/
   hash/identity/native closure, production read-only payload admission and Package
   path provenance. Package identity remains the committed identity above.
3. Reuse S32's existing focused route/result/admission/disposition evidence on
   the exact extraction. Task-local drivers may accept an explicit Package root
   and fresh output root rather than the checkout; no assertion weakening or
   product repair. Cover original writer/materializer refusal -> real receipt/
   normal/reopen/exact release plus disposition producer -> actual locked PS
   reader and their declared adjacent rejection cases. Compile changed projected
   sources as needed. Keep HARNESS semantic closure distinct from byte closure;
   no whole-suite, Provider/model/download or live backend expansion. Use fresh
   repository-local evidence; preserve failures. Stop on semantic failure or an
   independent cause; at most two mechanical driver corrections for the same
   scenario, no unchanged retries.
4. Only after all exact-artifact gates pass, recheck that human-owned S30 Unity
   is closed. Back up `UnityFreshLifecycleValidationProjectS30/Packages/manifest.json`
   and `Packages/packages-lock.json` under a fresh repository-local
   `.backups/s32-install-command-<commit-prefix>/` root. Change only their CodeDB
   references to the exact new extraction; preserve testables and other fields.
   Confirm both JSON references and exact non-reference preservation. If Unity
   is open, defer the reference switch and wait for the human close handoff;
   never terminate it.
5. Return artifact/source identity and a focused human compile/Test Runner/
   Manager checklist. Human Unity opening and acceptance remain human-owned.

Stop dependent delivery on source drift, identity/closure/contract failure or
new authority needs. No dirty-source export, unrelated repair or generation
change. Pending S30 action and old missing-disposition history remain protected;
this proposal does not promise automatic Install availability in that old state.

## Consumer and runtime boundary

Target: `<repository-root>/UnityFreshLifecycleValidationProjectS30`.
Both Package references currently identify
`.artifacts/s31d-uninstall-terminal-97471f5/review/com.rice.ai-codedb`.

- Manifest SHA-256: `599af94eb4eaeacf223e719054d9fab88f37ad41535b7ad99a386f7b11a0346e`.
- Lock SHA-256: `7d73367478748ba240d9cdfead652a598e5d7ba7c558e906edea92fe35b2a3e7`.
- Preparation observed no attributed S30 Unity process and no Unity lock;
  recheck immediately before any authorized switch.

Excluded: actual Install/Uninstall, historical backfill/archive/unlock, pending
action `6b9678672d3744f0ab052e521ae42ad6` recovery or retry, runtime/config writes,
process control, Unity/MCP/BatchMode launch, push and publication. Existing S30
old operation records are not made NO_CHILD by future producer code. Real
lifecycle acceptance and historical-state disposition require a separate plan.

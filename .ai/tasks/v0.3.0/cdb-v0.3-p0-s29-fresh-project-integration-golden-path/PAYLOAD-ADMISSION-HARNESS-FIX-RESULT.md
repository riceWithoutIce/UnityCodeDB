# S29 F-PA01 harness correction Coder result

2026-10-09. `F-PA01_SOURCE_FIX_AND_FOCUSED_EVIDENCE_PASS / SOURCE_SNAPSHOT_FROZEN`.
Authorization: user `同意修复`, PAYLOAD-ADMISSION-HARNESS-FIX.md.
Base HEAD `97c46f577c17639af32579c41dbb832eacb9346b`.
No new commit. S29 remains PARTIAL; no human recovery/install acceptance.

## Change and source identity

Only product-tree change: `com.rice.ai-codedb/Tests~/test-codedb-payload-admission.ps1`.
The script-layout parent remains the evidence base and retains the existing
`.artifacts/tests/pa41*` containment and fresh-root rules. Fixture archive's Git
root is independently discovered through `git -C $package rev-parse --show-toplevel`.
Discovery must return one root containing `com.rice.ai-codedb`; failure gives an
explicit PackageRoot-attributed diagnostic before evidence creation.

The four stage overlays still copy from `$package`, the Package under test,
including when it is extracted below `review/com.rice.ai-codedb`. Each source
path and SHA256 is recorded and compared with its stage SHA256. Discovery does
not replace tested scripts with worktree scripts. Six-target, real production
reader/export/closure, source/hash, negative layout and no-write assertions are
unchanged.

Final changed script SHA256:
`0041b6458a77bc321d0fd2425b170400e4c9c14decdd598866d0bd7c711a21df`.
Diff: 26 additions / 3 deletions. `git diff --check` PASS.
Windows PowerShell `5.1.19041.6456` parser PASS; proof is
`.artifacts/tests/pa41-hf-preservation/parse-hash.txt`.

Protected production scripts, all unchanged before/after:

| Path relative to com.rice.ai-codedb | SHA256 |
| --- | --- |
| Tools~/materialize-codedb-host-payload.ps1 | 1708bf8df295953c40a3698f6781f7e488076de4516b8b303a529aaaf918e65d |
| Tests~/test-codedb-package-release-closure.ps1 | d5100c392056174746bd63f02766f68d9eac284173173adb30213153650b57f2 |
| Tests~/export-codedb-package.ps1 | c0e4da862e6b3f4e6276dc9ce017d7223ce0ea8cd2a68ce8b8aa90b44c91668f |

## Commands and focused evidence

Run from `G:\RiceProgram\UnityCodeDB`. Every harness child subprocess command,
exit code, stdout/stderr and Package before/after snapshot is retained in the
corresponding fresh evidence directory.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .artifacts/tests/pa41-hf-preservation/capture.ps1 -Phase Before
powershell.exe -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-payload-admission.ps1 -EvidenceRoot G:/RiceProgram/UnityCodeDB/.artifacts/tests/pa41-hf-source
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .artifacts/tests/pa41-hf-layout/run.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .artifacts/tests/pa41-hf-nogit/check.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .artifacts/tests/pa41-hf-preservation/capture.ps1 -Phase After
git diff --check -- com.rice.ai-codedb/Tests~/test-codedb-payload-admission.ps1
```

| Run | Outcome and evidence |
| --- | --- |
| Source layout | Exit 0, full focused harness PASS; `.artifacts/tests/pa41-hf-source/` |
| Extracted layout | Exit 0, full focused harness PASS; `.artifacts/tests/pa41-hf-layout/review/.artifacts/tests/pa41-hf-extracted/` |
| Discovery unavailable | Nonzero, explicit `Cannot discover the fixture archive Git root from PackageRoot` error; evidence projection directory absent; `.artifacts/tests/pa41-hf-nogit/` |

`pa41-hf-layout/run.ps1` extracts the source run's actual deterministic ZIP into
fresh `review/com.rice.ai-codedb`, then directly invokes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "G:\RiceProgram\UnityCodeDB\.artifacts\tests\pa41-hf-layout\review\com.rice.ai-codedb\Tests~\test-codedb-payload-admission.ps1" -EvidenceRoot "G:\RiceProgram\UnityCodeDB\.artifacts\tests\pa41-hf-layout\review\.artifacts\tests\pa41-hf-extracted"
```

Its exact command and success exit are also retained in `pa41-hf-layout/command.txt`
and `exit.txt`. Extracted `roots.txt` proves:

- Package under test: `.artifacts/tests/pa41-hf-layout/review/com.rice.ai-codedb`.
- Evidence base: `.artifacts/tests/pa41-hf-layout/review`.
- Archive Git root: `G:\RiceProgram\UnityCodeDB`, independently discovered.

Both runs retain `roots.txt`, `package-under-test-overlays.txt`,
`source-script-hashes.txt`, `base-commit.txt` and `summary.txt`. Extracted overlay
source paths are all below the extracted Package, and every source/stage hash
matches. Their base-commit.txt is the authorized base HEAD above.

Each complete focused run accepted canonical 58 files/all six targets, passed
source-stage production admission and byte closure, passed its exact ZIP
admission and byte closure, rejected flat/generation unknown adjacent native
targets with reader exit 2 and export gate nonzero, and asserted identical
Package before/after snapshots with no logical project state created. Negative
fixture source hashes remain valid. Production gate behavior was preserved.

The narrow discovery-failure check only sets the child process's
`GIT_CEILING_DIRECTORIES` to the fresh review directory, preventing ancestor
repository discovery; it invokes the same extracted harness and verifies the
clear early rejection without creating its requested evidence root.

## Preservation and stop

`pa41-hf-preservation/Before.txt` and `After.txt` are identical for the three
protected production scripts and every source Payload file, including all
flat/generation bytes, manifests, pointers and transitions. Both focused runs
also preserve the complete Package under test and all reader/gate fixture
Package snapshots. Existing unrelated dirty state was not edited; no commands
addressed consumer configuration, history or receipts. No prior failed delivery
root was rerun, modified or cleaned.

Writes are limited to the allowed harness, this result and fresh pa41-hf*
fixture/evidence roots (including the authorized extracted directory-local
evidence). No materializer/export/closure product changes, Payload or metadata
changes, other docs, consumer operations, Unity, daemon, configuration,
process kill, cleanup, full suite, commit/push or nested agent.

Both requested full focused harness runs passed on their first attempts. The
initial quick parser probe used the outer PowerShell 7 shell; final attributable
parser proof explicitly ran Windows PowerShell 5.1. No semantic correction cycle
or evidence rerun was needed. Tool output stayed bounded.

Coder stops at this stable snapshot. Independent read-only Verifier may reuse
the saved evidence for F-PA01 and its adjacent directory/attribution regression.
Parent owns later scoped commit, fresh actual export/extracted run and reference
switch; these have not been performed by Coder.

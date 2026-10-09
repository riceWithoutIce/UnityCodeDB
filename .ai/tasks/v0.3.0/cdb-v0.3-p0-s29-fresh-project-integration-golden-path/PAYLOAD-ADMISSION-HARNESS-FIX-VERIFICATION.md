# S29 F-PA01 harness correction verification

2026-10-09. Fresh independent read-only Verifier; Coder stopped.
Verdict: `F-PA01_SCOPED_SOURCE_AND_SAVED_EVIDENCE_REVIEW_PASS`.
Original F-PA01 is closed for this frozen source snapshot. No scoped findings.

## Admission and scope

Read PAYLOAD-ADMISSION-HARNESS-FIX.md and
PAYLOAD-ADMISSION-HARNESS-FIX-RESULT.md completely. Reviewed only directory-root
separation, adjacent tested-Package attribution, and preservation of the declared
focused gates. Used saved evidence; did not execute the harness, parser, tests,
Unity, daemon, install, export, extraction, or other runtime operations.

Observed HEAD `97c46f577c17639af32579c41dbb832eacb9346b`; index empty.
Reviewed harness diff: 26 additions / 3 deletions.
Current harness SHA256 matches the stopped snapshot and saved parser proof:
`0041b6458a77bc321d0fd2425b170400e4c9c14decdd598866d0bd7c711a21df`.
Other existing Documentation~ diffs were left unexamined and unchanged.

## Directory correction and attribution

At harness lines 11-25, evidence containment still derives from the script-layout
parent, while `git -C $package rev-parse --show-toplevel` independently supplies
the archive root. Discovery checks exit status, one nonblank root, and the
`com.rice.ai-codedb` directory. Its explicit PackageRoot-attributed failure occurs
before evidence creation. Archive at line 125 uses the discovered root, removing
the original relative-pathspec failure without a hardcoded developer path.

Saved source roots identify the checkout Package and checkout evidence base.
Saved extracted roots identify:

- tested Package: `.artifacts/tests/pa41-hf-layout/review/com.rice.ai-codedb`;
- evidence base: `.artifacts/tests/pa41-hf-layout/review`;
- archive Git root: `G:\RiceProgram\UnityCodeDB`.

Both saved base-commit.txt files match the observed HEAD. Read layout/run.ps1,
command.txt and exit.txt: the source run's actual deterministic ZIP was extracted
into review/com.rice.ai-codedb and that extracted harness was directly invoked;
saved exit is 0. This is saved Coder fixture evidence, not a new final-delivery run.

The four overlays at lines 132-143 still read from `$package`. Their extracted
source paths in package-under-test-overlays.txt all reside inside the extracted
Package, and recorded source/stage hashes agree. Independently read current file
hashes for those four extracted sources and their extracted-run stage copies;
all match the live source snapshot and recorded hashes. The harness hash above
also matches the actually extracted script. Git-root discovery therefore does
not substitute checkout repair scripts for tested-Package scripts.

## Saved adjacent gate and preservation evidence

Evidence roots reviewed:
`.artifacts/tests/pa41-hf-source/` and
`.artifacts/tests/pa41-hf-layout/review/.artifacts/tests/pa41-hf-extracted/`.
Reviewed roots, base commit, overlays, summary, exit/stdout/stderr, source/hash
proof, and before/after snapshot files relevant to the scope.

Both runs retain six targets. Canonical reader exit is 0 with production
admission PASS and file_count=58. Source-stage and exact-ZIP exits are 0 with
production admission PASS, byte closure PASS (58 sources, 0 mismatches), and
export gate PASS. Flat and generation adjacent unknown targets produce reader
exit 2 and export gate exit 1; stderr identifies the same target outside the
audited production allowlist. Both saved negative source-hash proofs PASS.

The diff leaves these gates and assertions unchanged. Inspection confirms the
reader uses the tested Root's production materializer, export uses that Root's
exporter/closure validator, and no-write and source/hash assertions remain.
Saved source snapshots and all seven reader/gate Package before/after pairs in
each run are byte-identical by SHA256. No logical-project directories remain.

Read pa41-hf-nogit/check.ps1 and saved exit/stderr. The isolated child uses
GIT_CEILING_DIRECTORIES to block ancestor discovery; saved exit is 1 with the
explicit PackageRoot discovery diagnostic. Its requested evidence directory is
absent. No discovery-failure test was rerun.

Preservation Before.txt/After.txt are byte-identical. Current protected script
hashes also match the saved values and actual extracted/stage copies:

- materializer: `1708bf8df295953c40a3698f6781f7e488076de4516b8b303a529aaaf918e65d`;
- release closure: `d5100c392056174746bd63f02766f68d9eac284173173adb30213153650b57f2`;
- exporter: `c0e4da862e6b3f4e6276dc9ce017d7223ce0ea8cd2a68ce8b8aa90b44c91668f`.

Saved preservation includes Payload flat/generation files and metadata. No
production repair, Payload, consumer, configuration, or history writes were
performed by this Verifier. Sole write is this report; no Coder messages,
commits, push, cleanup, or nested agents.

## Limits and stop

Saved Windows PowerShell 5.1.19041.6456 parse proof is PASS; this Verifier did not
independently execute parsing or tests. Parent still owns the scoped commit,
fresh actual committed export, exact extracted focused run and closed-project
reference switch. This verdict does not claim those pending steps, Unity/C#
compile, real recovery/install, consumer runtime, or release acceptance.
S29 remains PARTIAL. Original blocker closed; scoped review stops here.

Operational note: one initial batched document-read call exceeded the requested
6 KiB aggregate output bound. Some subsequent combined listings were truncated;
the complete diff and relevant evidence were then read in narrower calls. This
does not retroactively satisfy that initial output bound and is recorded as a
Verifier workflow deviation, not an F-PA01 product finding.

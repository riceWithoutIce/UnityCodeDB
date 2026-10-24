# S40 exact four-file primary-source integration proposal

Date: 2026-10-22. Status: COMPLETE / PRIMARY SOURCE INTEGRATION PASS.
User explicitly replied `好的 同意` to this exact four-file proposal. The
grant covers the source synchronization and byte/index verification below.
Execution is complete; see SOURCE-INTEGRATION-RESULT.md. Historical proposal
wording below defines the executed boundary, not another pending grant.

## Current task and rationale

The user deferred identity-handoff/heartbeat analysis and asked to return to
the current task. Continue basic-flow stabilization closeout, keeping that
independent investigation dormant. The observed functional gates and qualified
ordinary-reopen result are recorded in RESULT.md; no repeat test is needed to
refresh those completed results.

The delivered fix is commit `186aacf0371ba64e47114306170b449dbca261c9` on the
repository-local isolated branch. The primary development checkout remains on
`codex/v0.3.0-legacy-workflow`, HEAD
`237c72d9980114b99887fb8e805658447dd8d4fd`, with earlier approved integration
and unrelated dirty state. S40's engine/test changes are not yet present there.
The original delivery grant covered the isolated commit, exact export and
consumer reference switch; primary-source integration is proposed separately.

## Prepared exact result

Read-only comparison confirms the primary engine exactly equals S40's parent
commit bytes. The two focused tests do not exist in the primary checkout.
The primary contract contains local first-install/reinstall terminology and
attribution clarifications that the isolated document does not contain.
Replacing that document wholesale would discard those local agreements.

Preparation derived an insertion-only contract proposal. Removing just the
accepted same-Package retained-reader paragraph reproduces every primary
preimage byte, including BOM/EOL. The other three proposed files are exactly
the accepted commit bytes. No product source has been changed by preparation.

| Primary path under `com.rice.ai-codedb/` | Proposed operation | Proposed SHA-256 |
| --- | --- | --- |
| `Tools~/codedb-instance-engine.ps1` | Replace exact parent bytes with accepted engine | `b8931439f2f77fbebc65f81a3614cedf94b0c5b62f1ddac0e62ae402bf8b045f` |
| `Tests~/test-codedb-retained-mcp-install.ps1` | Add exact accepted file | `e349d4344eafb8081ccf57c04b67066905c46663c364ec749ab447d7c2c9e37c` |
| `Tests~/test-codedb-retained-mcp-install.mjs` | Add exact accepted file | `6dfae913d97e220b3bad0309e64a6b647d3dbb6648e4f5a9fd60f41e9b296df2` |
| `Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md` | Insert only accepted same-Package paragraph; preserve local clarifications | `be1bfa25f380ff75e954b1236d594cb5ba24a8aa612bd693d4982abf1838f8f5` |

Preparation manifest, exact preimages and proposed files:
`<repository-root>/.artifacts/maintenance/s40-primary-source-integration-preparation-a/`.
The manifest records primary hashes/absence, accepted/proposed hashes and
unchanged primary index. Preparation script lives in this task directory.
This is a source-integration proposal, not another Package or release candidate.

## Proposed execution after approval

1. Recheck the preparation manifest, four primary preimages/absence and
   proposed hashes, isolated commit and primary index identity. Stop on drift.
2. Preserve the exact preimages and a separate execution receipt. Write only
   the four proposed primary files, checking each resulting byte hash. Use
   exclusive creation for the two new tests. Stop on partial effects; do not
   reset or overwrite unexpected files.
3. Verify that removing only the inserted contract paragraph restores its
   exact preimage; the other three files must equal accepted Git blob bytes.
   Confirm primary index unchanged and preserve unrelated dirty files.
4. Record completion in this task's RESULT and integration receipt. Reuse
   existing exact-byte parse/harness/review evidence for the unchanged engine
   and tests; this does not require another 46-check run or real project test.

Preserve all unrelated local changes, immutable generations and the two
expressly unaccepted writer-lifetime implementation deltas. Do not use stash,
reset, broad staging, merge or cherry-pick to perform this bounded copy.
No commit, push, export, Package/reference switch, Unity/MCP/lifecycle action,
identity/heartbeat analysis or cleanup is included. Consumer CodedbTest_2 and
the exact delivered 186aacf artifact remain as they are.

## Closeout and next decision

After integration, the primary source contains the reviewed S40 repair plus
preserved local work. The combined primary tree is still not the exact tested
delivery candidate; do not export it under the 186aacf artifact identity.
The independently deferred startup/heartbeat task remains unstarted.

Refresh the basic-flow evidence summary against the full roadmap for the next
user decision. Functional preview stabilization, full Discover Read completion
and public release acceptance remain different gates. This integration does
not waive Runtime Release Gates or turn incomplete identity/live-holder
evidence into accepted results.

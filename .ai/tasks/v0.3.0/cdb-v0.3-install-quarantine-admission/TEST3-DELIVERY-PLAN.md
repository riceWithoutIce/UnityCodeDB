# Test3 candidate freeze and delivery

Date: 2026-10-26. Status: `DELIVERY_PASS / HUMAN_UNITY_PENDING`.
User created the suggested new project and confirmed Unity closed. Read-only
inspection verifies `<external-test-root>/CodedbTest_3` exists, declares Unity
2022.3.62f3, has Assets/Packages/ProjectSettings, no UnityLockfile, no AIWork and
no CodeDB manifest dependency. No target-project Unity process was observed.
Other Unity projects are outside this task and must not be controlled.

## Protected preimages

| Project-relative file | SHA-256 |
| --- | --- |
| `Packages/manifest.json` | `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1` |
| `Packages/packages-lock.json` | `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6` |
| `ProjectSettings/ProjectVersion.txt` | `b51164d22c4d2716ba8aee7f0b59d6b7dd0efa8552fd1db2a8c3b123fae3a1ec` |

Source: branch `codex/install-quarantine-admission`, base
`09d345d96ec782be2ac101016d8b75b14bce6000`, repository-local isolated checkout.
The ten-file source snapshot still matches. The required Package
`-PathProvenanceOnly` gate passed in Windows PowerShell 5.1. No source change.

## Concrete proposed handoff

1. Stage and commit exactly the ten files listed in CHILD-CLOSURE-RESULT.md's
   source-snapshot.json, on the existing isolated branch. Proposed message:
   `fix(codedb): persist owned child close evidence`.
   Keep unrelated main-checkout/task changes unstaged. Preserve task evidence
   in its current location; no merge, push, tag or board update.
2. Export the exact commit with the existing exporter to a new task-owned
   `.artifacts` directory. Run its staged/extracted payload byte-closure and
   production read-only admission gates. Run the changed producer/readers from
   that exact extracted Package with fresh bounded fixture output. Retain any
   failure and stop before delivery if a required gate fails.
3. Copy the verified Package to a new directory named
   `<external-test-root>/Packages/<commit-short>-v03-child-close/com.rice.ai-codedb`.
   Verify every copied file hash against the extracted candidate. Never
   overwrite an old Package directory.
4. Save both JSON preimages, then add only the direct local CodeDB dependency
   in Test3 manifest and lock. Both references are
   `file:../../Packages/<commit-short>-v03-child-close/com.rice.ai-codedb`.
   Lock entry: local source, depth 0, no dependencies, Package name from
   candidate package.json. Preserve all unrelated dependency values.
5. Record commit/archive/inventory/reference hashes and a human opening
   checklist. Do not create registration/runtime records or copy anything from
   Test2. Unity imports and product Install remain human actions afterward.

Unity opening, Install/Uninstall, runtime process control, historical recovery,
Git push/merge and publication are outside this handoff. If the project or
source preimages drift, stop and report before replacing references.

Explicit Git handoff permission is required by the accepted
CHILD-CLOSURE-NEXT-ACCEPTANCE-PLAN.md candidate preparation step 1. No commit,
export, copied Package or project-reference modification has been performed.

Execution update: the user subsequently approved this exact group. Commit,
export, extracted contract gates and scoped delivery completed. See
TEST3-DELIVERY-RESULT.md for actual identities and protected-state checks.

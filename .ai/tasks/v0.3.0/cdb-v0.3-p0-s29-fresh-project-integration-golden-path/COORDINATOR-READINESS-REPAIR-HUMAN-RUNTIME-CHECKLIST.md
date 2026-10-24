# S29 coordinator readiness repair — exact-package runtime gate

Date: 2026-10-11 (Asia/Shanghai). This is a new human operational gate after
the user explicitly authorized continuation from the delivered exact package.

## Bound target

- Project: `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`
- Package reference:
  `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-coordinator-readiness-repair-427a424/review/com.rice.ai-codedb`
- ZIP SHA256:
  `117465d29401d26d2f550f8c820645c0028c35874d9fb670eae9a4a0d273b341`
- Current source/delivery HEAD: `427a42495e0fd8a5707da3adf368f895dbf524ad`

## One-session human steps

1. Open the S29 project and wait for package import/compilation. Confirm there
   are zero new C# compile errors.
2. Open CodeDB Manager and confirm the displayed Package path/version is the
   exact package above. The existing `Needs Setup`/generation mismatch is
   expected before materialization.
3. Use the normal Manager `Install CodeDB` action once. Do not use Uninstall,
   Remove Integration, Configure replay, or a second Install in this gate.
4. Wait for the action to reach a terminal result. Record the action id,
   terminal state, elapsed time, and any displayed failure category/detail.
5. After the action completes, observe Manager in EditMode for about two
   minutes. Record the sequence of `Starting`, `Ready`, `NeedsAttention`, or
   other states and the exact visible reason for every non-Ready state.
6. Close and reopen Manager once, observe for about one minute, and record
   whether it remains on an authenticated Ready observation or returns to
   NeedsAttention/Starting.
7. Close Unity normally once. If Unity crashes, the action times out, or the
   install reports an unknown/non-terminal result, preserve screenshot/log/time
   evidence and stop this gate.

## Acceptance boundary

PASS requires: exact-package Install terminal success, selected instance and
generation aligned to the new Package manifest, authenticated Coordinator and
Provider Ready, and stable Ready after one Manager reopen. Normal Unity shutdown
is reported separately.

Compilation/UI/close PASS alone does not close this gate. Do not manually edit
runtime manifests, receipts, leases, indexes, or cleanup state. Do not retry a
failed or timed-out action in this gate.

After the human report, parent performs only bounded read-only receipt/index and
Coordinator log checks against the reported action. No automatic repair or
publication follows from this checklist.

# IPC consumer reference switch completion

Date: 2026-10-22. Status: CONSUMER_REFERENCE_SWITCH_PASS_NOT_REOPENED.
The human explicitly approved the narrow completion in
IPC-CONSUMER-SWITCH-PARTIAL-RESULT.md. Frozen helper hash matched and the helper
ran once successfully. The original failed journal remains unchanged.

## Actual completion

- UTC write window: 2026-10-22T09:04:21.5227002Z to
  2026-10-22T09:04:21.5448817Z, after successful read-only preconditions.
- Exactly one write: Packages/packages-lock.json. Manifest not rewritten;
  Package not recopied; no rollback or retry.
- Both references now parse to
  `file:../../Packages/c53e181-s42-ipc-diagnostics/com.rice.ai-codedb`.
- Both files equal their original backup bytes with only the unique reference
  replaced. Backups remain intact.
- manifest.json SHA-256:
  `0e58c681df2d6e317ee2ee36c8f82fa9f61901bc3d0e4f65cdc4958c9e035811`.
- packages-lock.json SHA-256:
  `c55673264a975bd48ad6aa711a7dd0de9a8a9cb400833eecf6a19d11945cbd8c`.
- All 667 Package files match the retained exact export inventory. Selected
  pointer, both probes and both meta files retain the frozen protected hashes.
  Both Library/UnityLockfile and Temp/UnityLockfile were absent at completion.

Receipt, relative to the repository root:
`.artifacts/tests/s42-ipc-consumer-switch-c53e181/execution-a/lock-completion-result.json`.
SHA-256: `0589f91dae6e4f44bc405c430dee3044d541031fd389a8eb6373d7e4281763ac`.

## Evidence boundary and human handoff

This closes the file-copy and reference-consistency gate after the separately
approved partial-write recovery. It does not retroactively turn the original
attempt into PASS. Earlier journal/backup and the partial result are retained.
The observation limits stated there, including no fresh backend retirement
proof, remain applicable. No further consumer or runtime files were modified.

Unity starts, process control, Supervisor/Provider service operations,
Install/Repair/Restart/Uninstall, live logs and MCP calls: zero in completion.
No Unity compile, real service health, timeout reproduction or root-cause claim.

Next human step: open the existing CodedbTest_2 normally once. Report compile
errors and the first Manager state; preserve full error details if an error or
Needs attention appears. Do not use Install/Repair/Restart/Uninstall, repeated
refresh or reopen loops as part of this observation. If it later naturally
becomes Ready, report that separately; Ready does not erase the first error.
Subsequent log collection or target-client calls require their own aligned scope.

# IPC diagnostics consumer switch partial result and completion plan

Date: 2026-10-22. Status: PARTIAL_SWITCH / STOPPED_NO_REPLAY.
The human approved the consumer copy/reference switch with Unity closed.
Package delivery is not declared complete; keep Unity closed pending disposition.

Subsequent disposition: the human explicitly approved the narrow lock-only
completion below. It ran once successfully; see
IPC-CONSUMER-SWITCH-COMPLETION-RESULT.md. The partial-attempt facts and original
journal remain historical evidence; no original failure receipt was overwritten.

## Actual effects

- Exact Package copied to
  `<external-project>/../Packages/c53e181-s42-ipc-diagnostics/com.rice.ai-codedb`.
- All 667 destination paths/hashes match the retained exact-export inventory.
- ZIP hash remains c7d374856c76ea0dc5b3c6e4124d391cac3b10bde26a85843a5caa63cb95ea5f.
- Exact original manifest/lock backups are retained at
  `<repository-root>/.backups/s42-ipc-consumer-switch-c53e181/`.
- manifest.json was written once. Its bytes match the original with only the
  unique CodeDB reference changed to
  `file:../../Packages/c53e181-s42-ipc-diagnostics/com.rice.ai-codedb`.
  Current SHA-256: 0e58c681df2d6e317ee2ee36c8f82fa9f61901bc3d0e4f65cdc4958c9e035811.
- packages-lock.json has not been written and equals its original backup.
  SHA-256: b2b7e48cdb5b8316c1873a88e1ab60ad9fbee569e30eb11864863639bc4f0f39.
- Pointer, original query probe, retained S41 B and both meta files retain their
  observed pre-switch hashes. Both Library/UnityLockfile and Temp/UnityLockfile
  were absent at the subsequent read-only check.

## Failure and limits

The first invocation failed on a PowerShell Test-Path condition before mutation.
After that preparation correction, the executor copied the Package and wrote
manifest.json, then failed in its verification expression: PowerShell cannot
invoke the AsSpan extension method on the returned byte array this way. The
catch handler retained STOPPED_NO_REPLAY. This is an assistant-authored delivery
script defect, not a CodeDB product, Package, compile or runtime failure.

Original journal and preimages are retained under
`<repository-root>/.artifacts/tests/s42-ipc-consumer-switch-c53e181/execution-a/`.
The journal was not overwritten by later checks. No lock write, automatic
rollback, recopy, cleanup, product repair, service operation or Unity launch
followed the partial failure.

This execution did not run the prior delivery's normal-retirement observer or
establish fresh process ownership/retirement evidence. Human closure and absent
lockfiles are the available closure evidence; they do not establish backend
retirement. Registration, wrapper, instance manifest and other runtime state
were not part of this executor's retained protected-hash baseline and must not
be reported as verified unchanged. No broader runtime claim is made.

## Prepared narrow completion

Task helper: complete-ipc-consumer-lock-switch.ps1.
SHA-256: 8fd211523613043ce46e3981d28b5e86b75d1842b6bb6204c5ba2ebd36418901.
Syntax check and actual read-only preflight PASS. No write was made by this
helper. Byte equality uses exact Base64 comparison, not AsSpan.

Proposed fresh grant, once only:

1. Revalidate frozen helper and backups, partial manifest, unchanged lock,
   both absent lockfiles, exact 667-file Package and five protected hashes.
2. Write only packages-lock.json once from its backup with the single reference
   replaced. Do not rewrite manifest or recopy the Package.
3. Verify both complete expected byte sequences, protected hashes and lockfiles.
   Retain lock-completion-result.json beside the original journal and stop
   before human reopen. No replay, rollback or additional mutation on failure.

Command, from the repository root:
`pwsh -NoProfile -File .ai/tasks/v0.3.0/cdb-v0.3-p0-s42-coordinator-query-readiness-contract/complete-ipc-consumer-lock-switch.ps1 -ProjectRoot <external-project> -ExecuteApproved`.

This plan awaits explicit approval because the agreed consumer envelope stops
on partial writes. It does not authorize Unity, Install/Repair/Restart,
Stop/Start, process control, MCP, or a new live observation. It completes file
reference consistency only; human compilation and real diagnosis remain later.

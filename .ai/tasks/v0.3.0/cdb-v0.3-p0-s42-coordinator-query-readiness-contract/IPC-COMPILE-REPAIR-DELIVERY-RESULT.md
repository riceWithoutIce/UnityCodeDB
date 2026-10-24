# IPC diagnostics compile repair delivery result

Date: 2026-10-22. Status: CONSUMER_REPAIR_REFERENCE_SWITCH_PASS_NOT_REOPENED.
The human approved IPC-COMPILE-REPAIR-DELIVERY-PROPOSAL.md. The exact repair
commit, export and closed-project replacement completed once.

## Repair artifact

- Commit: `61dcd26383c42766763eca2b885b159725b2f7dc`.
- Parent: `c53e181fbfb24dea07e6e80daa71787ce192baa0`.
- ZIP: `<repository-root>/.artifacts/exports/s42-ipc-compile-repair-61dcd26/com.rice.ai-codedb.zip`.
- ZIP SHA-256: `3830edc8521788fdbed01283aec02173e5334098d35ddf51cabdd4300189f26f`.
- Exact Package inventory: 667 files / 667 ZIP entries / 14,141,650
  uncompressed bytes. Production admission and byte closure passed at commit
  and exact ZIP stages.
- Repaired Bridge SHA-256:
  `b2fe1c6564ea0bf5f386eaf40e1ca6ace7643f925203ff520ffb202500a2bfe5`.
- Repaired focused test SHA-256:
  `165c283496a9cc0f2093994a518b361ee7d9750da07fee150ce7b81c808e18c8`.

## Consumer replacement

- Unity remained closed; Library/UnityLockfile and Temp/UnityLockfile were
  absent at completion.
- New destination:
  `<external-packages>/61dcd26-s42-ipc-compile-repair/com.rice.ai-codedb`.
- All 667 copied files match the exact export inventory.
- Both `Packages/manifest.json` and `Packages/packages-lock.json` now reference
  `file:../../Packages/61dcd26-s42-ipc-compile-repair/com.rice.ai-codedb`.
- Current manifest SHA-256:
  `a4c8adddcfaf0906a790cc15620b599eb66407248b93214df86862da25fc49d8`.
- Current lock SHA-256:
  `db918d2edac60b46d29f6e7a57a0a81d64b7009f21c3b62a89ef3421b491297c`.
- The prior c53e181 manifest/lock bytes are backed up under
  `<repository-root>/.backups/s42-ipc-compile-repair-61dcd26/`.
- Selected pointer, both probes and both meta files retained their protected
  hashes. No Unity, service, MCP or CodeDB operations occurred.

## Receipts

Relative to `<repository-root>`:
`.artifacts/tests/s42-ipc-compile-repair-consumer/execution-a/` contains the
preflight, copied inventory and result receipts. The final result SHA-256 is
`50f29f9385f86021ab5c315a9f71fb06f9e447daef9092e8255aefa96ffbfe13`.

## Next gate

The original compile regression is addressed in the delivered source by the
three-argument compatibility overload. This result is still a file-delivery
gate, not Unity compile acceptance. Human action is to open CodedbTest_2 once
and report the first compile and Manager state. Do not click Install, Repair,
Restart or Uninstall. Preserve the first error details if any remain. A clean
compile does not by itself establish runtime readiness or close the timeout,
heartbeat or identity-handoff investigation.

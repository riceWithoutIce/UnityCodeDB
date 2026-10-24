# S29 shutdown comparison without tests

Date: 2026-10-12 (Asia/Shanghai).
Status: HUMAN_NORMAL_CLOSE_PASS / READ_ONLY_EXIT_CORROBORATED.
User grant: "同意" in response to the concrete one-session no-test comparison.

## Fixed comparison boundary

- Same S29 project and exact 74c4db0 Package; ZIP SHA256 remains
  1325857c43a0f002f6feb25e1830efd00fc312e4e4de8120952d4963ef00e26c.
- Same Unity 2022.3.62f3 executable and process-local retained-fixture variable
  as the failed session. The deliberate behavioral difference is no Test Runner.
- Dedicated new log:
  .artifacts/delivery/s29-retained-disposition/shutdown-control/editor-no-tests.log.
- Parent verified no S29 process, exact manifest/lock and ZIP hash, present
  executable/fixture files and absent log before launching.
- Parent launched the Editor with the dedicated log and unchanged process-local
  fixture environment, verified one S29 process and its log-file argument.
- One visible Editor launch only. Human owns Manager open/reopen, tabs,
  observation for about one minute and normal close. No tests or action buttons.
- If hang recurs, preserve the live window and report it before force ending
  when practical. Process stop/dump collection/retry is not granted here.
- Parent may inspect this session's dedicated log and process state read-only.
  No source repair, installation, cleanup, export/reference switch or commit.

Original 26-test/UI PASS and forced-close AppHang failure remain preserved in
RETAINED-DISPOSITION-HUMAN-RESULT-2026-10-12.md. This comparison cannot establish
root cause by itself or erase that failure. S29/release remain PARTIAL.

## Human result and read-only attribution

User reported "可以正常关闭这次". Control PID 36064 launched at 18:16:10
and is absent from subsequent process enumeration. Dedicated log ends at
18:20:03 after Cleanup mono (line 537), with subsequent allocator teardown and
Memory Statistics (line 890). No matching Unity Application Hang/Crash events
were observed in the inspected Application event window starting 18:16.
No prior fatal crash markers appear in the dedicated log.

CodeDB quitting entry/return each=1, callback max=2192 microseconds;
reconcile/refresh/queue pending/queue active=0 at return, violations=0.
shutdown_request_count=1 and NOT_EVALUATED at checkpoint remain snapshot-only.
Log SHA256:
4c47cba664372de2732ca41546dc03bee356432ddf0334d64cd48cfa4339c475.

This establishes one successful no-test close on the same exact Package.
It does not reproduce all actions of the original session: the human explicitly
reported normal close only, while recorded Manager open/tab-change counters are
zero (close=1). These counters do not establish whether a restored window was
visible, but the requested interaction sequence is not independently evidenced.
The two sessions are not a fully controlled test-only comparison. Test lifetime/
isolation remains a priority hypothesis, not a proven culprit or a source FIX.
Original forced-close AppHang remains unresolved; no new Unity attempt launched.

## Subsequent user disposition

On 2026-10-12, user deferred the unresolved hang for observation in subsequent
tests because the current sample cannot establish development causation.
Preserve both sessions; the successful close does not erase the AppHang.
No dedicated investigation or extra experiment now. This observation no longer
blocks the current slice; it is not a resolved defect or full shutdown PASS.

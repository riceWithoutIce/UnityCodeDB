# S42 consumer copy and reference switch result

Status: CONSUMER_REFERENCE_SWITCH_PASS_NOT_REOPENED.
Human approved CONSUMER-SWITCH-PROPOSAL.md steps 1-5 once. The frozen executor
hash matched before execution; the approved sequence completed without retry.
Execution: 2026-10-22T06:25:53.608Z to 06:26:02.409Z.

## Delivery and verification

- Commit: 4589249564c7affb541634d61656c0cc895ca9d4.
- Exact ZIP SHA-256:
  71bf71b09a7f71f0754f04564f16b2cca4f99e23ce45ffa5f2cbfa6858641cc8.
- New external destination:
  <external-project>/../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb.
- Complete copied inventory: 666 files, every path/hash matches exact export.
- New reference in both Packages/manifest.json and Packages/packages-lock.json:
  file:../../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb.
- Exact original bytes backed up under
  <repository-root>/.backups/s42-consumer-switch-4589249/.
- Each changed file differs only by its unique CodeDB reference replacement.
  New manifest SHA-256:
  003e58e939b2a63e6ae9d8174e4d7ef5b054c6942e0f2e15f79ecd9865426f2f.
  New lock SHA-256:
  b2b7e48cdb5b8316c1873a88e1ab60ad9fbee569e30eb11864863639bc4f0f39.

Both fresh read-only snapshots returned OBSERVED_RETIRED with stable pointer:

| Point | Safe receipt under <repository-root> | SHA-256 |
| --- | --- | --- |
| Before copy | .artifacts/tests/s42-normal-close/2026-10-22T06-25-53-776Z-2c3a17/report.json | 0c9e790442fc555b1e21b64b46c57e6f6287ee780340dc9d2ed4e7e439055d48 |
| Before reference switch | .artifacts/tests/s42-normal-close/2026-10-22T06-26-01-596Z-03f5d6/report.json | daac0d3bf3db036071b9f63d665376d2e09781c30d03d652b181b040827edede |

Protected registration, selected pointer, instance manifest, stable wrapper,
original query probe, retained S41 A probe and both .meta files preserved their
existence and hashes. Final UnityLockfile absent. Old Package retained.

Machine receipt, journal and copied inventory:
<repository-root>/.artifacts/tests/s42-consumer-switch/execution-a/.
result.json SHA-256:
399e4c8bd5a3eec386ba39e49d74029895b5d8b60c003aece9144b74821c92e1.

## Boundary and next human step

Service RPC 0; Install/Uninstall 0; CodeDB calls 0; no Unity launch or process
control. Earlier failed Stop remains a failure and was not replayed.

Delivery is complete; real reopened runtime acceptance is not established.
Next: human opens CodedbTest_2 normally and reports compilation and Manager
state. Do not click Install/Uninstall/Repair/Restart as part of that observation.
If an error or Needs attention occurs, preserve the first result for analysis.
Subsequent runtime shape / target-client checks and S41 A-to-B freshness remain
separate gates. Heartbeat and formal response identity findings remain open.

Human subsequently reported no errors and Needs attention -> Ready; screenshots
retain an initial SUPERVISOR_IPC_TIMEOUT and later cached Ready. See
HUMAN-REOPEN-RESULT.md. This supplements, rather than alters, the delivery result.

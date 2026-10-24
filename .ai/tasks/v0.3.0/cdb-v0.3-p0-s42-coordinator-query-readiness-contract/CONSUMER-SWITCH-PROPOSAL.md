# S42 exact consumer copy and reference switch

Status: APPROVED_EXECUTED_PASS; see CONSUMER-SWITCH-RESULT.md.

Target: the existing external CodedbTest_2 project bound by the S42 receipts.
Human reported Unity closed. The previous one-shot observation established
OBSERVED_RETIRED at capture, not a continuing guarantee. Its grant is consumed.
This proposal covers the next copy/reference-switch boundary only.

## Frozen artifact and destination

- Commit: 4589249564c7affb541634d61656c0cc895ca9d4.
- ZIP: <repository-root>/.artifacts/exports/s42-instance-context-4589249/com.rice.ai-codedb.zip.
- ZIP SHA-256: 71bf71b09a7f71f0754f04564f16b2cca4f99e23ce45ffa5f2cbfa6858641cc8.
- Source: the exact ZIP extraction at the export's review/com.rice.ai-codedb.
  Existing production admission, byte closure and three focused artifact checks
  passed; delivery rechecks the ZIP and complete 666-file inventory.
- New destination, derived from the approved external project root:
  <external-project>/../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb.
- Old reference: file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb.
- New reference: file:../../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb.

No existing external Package directory is overwritten or removed.

## One proposed execution envelope

1. Recheck the frozen artifact and source inventory. Take one fresh bounded
   read-only closed/retired snapshot using observe-normal-close-once.mjs.
   Require OBSERVED_RETIRED, stable pointer and the frozen consumer preimages.
2. Back up the exact manifest and lock bytes under
   <repository-root>/.backups/s42-consumer-switch-4589249/.
3. Copy into the fresh destination and verify all 666 file paths and SHA-256
   values against the exact exported inventory.
4. Take a second fresh bounded read-only closed/retired snapshot immediately
   before reference mutation; recheck protected inputs and both preimages.
5. Replace only the unique CodeDB reference bytes in
   <external-project>/Packages/manifest.json and Packages/packages-lock.json.
   Parse both results, verify exact written bytes, protected input stability and
   absent UnityLockfile. Record completion and stop before reopening.

The two snapshots are new precondition observations included in this proposed
grant, not retries of the previous observation or failed Stop. Each observer
retains its existing maximum 30-second observation budget and 10-second process
inventory command limit; caller timeout is 35 seconds. No status RPC or process
control is added. A blocking first snapshot prevents copy; a blocking second
snapshot prevents reference mutation.

Frozen manifest SHA-256:
ea79c33e16767692fc3cb14cc92145e97705c42353e84e7955da539164da4485.
Frozen lock SHA-256:
183766b27213ff3a0bc1b604785661d5e39372c4918ef7c5b9bc9e947da2298d.
Frozen pointer SHA-256:
1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a.

Protected snapshots cover project .codex/config.toml, selected pointer, selected
instance manifest, stable wrapper, original query probe, retained S41 A probe,
and both optional .meta files, preserving existence and bytes. No runtime,
registration, sample, policy or manual-state writes are authorized.

Evidence and write journal:
<repository-root>/.artifacts/tests/s42-consumer-switch/execution-a/.
Existing destination, backup or execution output blocks execution. Drift,
residual/unknown owners, failed inventory, timeout, or partial write stops once.
Preserve the journal and partial effects; no automatic rollback, replay,
cleanup, Install/Uninstall, service command, real CodeDB call or Unity launch.

## Prepared executor and completion boundary

Executor: execute-consumer-switch.cjs in this task directory.
SHA-256: 3cb0685c13677274525c634388dad5ea5b936fcbdc4b2fc506bc97b9100eb495.
Preparation validation: Node syntax check PASS; executor not run.
Before approved execution, recheck this hash and create an operational grant
receipt binding the human approval, target root and approval time. Concrete
operational paths belong in that receipt, not this durable proposal.

Expected terminal result: CONSUMER_REFERENCE_SWITCH_PASS_NOT_REOPENED.
This proves exact copy and reference switching only. Human reopening, compile /
Manager observation, runtime materialization and real target-client validation
remain later gates. No A-to-B freshness or heartbeat acceptance is inferred.

Approval requested: execute steps 1-5 together once while Unity remains closed.
The prior NORMAL-CLOSE-OBSERVATION-TASK.md explicitly excluded external Package
copy and manifest/lock switching, so those mutations need this new grant.

# REMOVAL-PREFLIGHT-MANIFEST-RECOVERY — focused follow-up verification

Date: 2026-10-14 (Asia/Shanghai)  
Base: `d88a101f15d21f916cbee9578ab887aa1ea862cd`  
Scope: original recovery-call-site blocker and nearest regressions only  
Disposition: **PASS_WITH_LIMITS — original blocker closed**

## Review boundary

This read-only follow-up reviewed the declared two-file stable snapshot. It did
not dispatch a repair, rerun broad tests, start Unity/MCP/CUA/BatchMode, run a
real Install/Remove/Upgrade, start or stop a process, or change Payload, C#,
Manager/UI, recovery policy, or namespace contract.

The exact recorded hashes match the working files:

- `Tools~/codedb-instance-engine.ps1` —
  `b80cccb974c4c30385ee9fe6be6106b5e8e5d17f1da2498a943a3e9f0786becf`
- `Tests~/test-codedb-host-payload-materializer.ps1` —
  `e014f3399bb83b97b69c7f4454d000fa6b2dd69db860e9644ce2cd2e066d2ba8`

The source hash file records the same values. `git diff --check` passes for the
two scoped files.

## Original blocker is closed

The Install/Upgrade/Reinstall convergence body now calls:

```text
Invoke-InstanceOperationRecovery -ProjectRoot $ProjectRoot -StageRoot $lock.Root -Manifest $Manifest
```

at `Tools~/codedb-instance-engine.ps1:4904`. The Uninstall/automatic-cleanup
body uses the same forwarding at `:5253`. Both callers already own the Package
manifest, and both now reach the existing `COMMITTED REMOVEINTEGRATION` guard,
which performs Package-backed terminal validation before journal cleanup.

The focused test inspects the actual production function bodies, rather than a
test-only substitute. `manifest-routing-a2.log` reports PASS54 with
`native_children=0` and a copied project. Its first two assertions prove both
forwarding call sites. The same fixture then verifies valid Manifest-backed
committed recovery clears only the transaction journal, while retained-evidence
drift is rejected and the journal remains present.

## Attempt accounting and adjacent evidence

`manifest-routing-a1.log` is a preserved failed attempt. It used an overlay
whose engine copy predated the two forwarding edits and stopped at the expected
source-shape assertion before the namespace/removal scenario. The log does show
the synthetic original42 Install fixture setup before that assertion; its copied
fixture therefore contains setup mutations. No real-project mutation occurred.
The RESULT phrase "made no product mutation" must be read with this narrower
qualification. The attempt is not counted as passing evidence.

The neighboring frozen evidence remains coherent: namespace `scenario-a4` is
PASS52, wrapper-original is PASS27, and wrapper-before-install is PASS32. Those
fixtures retain the synthetic process seam (`native_children=0`) and do not
claim real Supervisor or Unity recovery.

## Scope check and remaining limits

The follow-up delta is exactly the two production argument forwards and four test
lines implementing the two focused source-shape assertions. In-memory reversal
of just those edits reproduces both prior snapshot SHA-256 values. The other
four original allowlisted source/test hashes are unchanged. The existing
recovery guard, terminal proof, preserved-history fingerprint, and fail-closed
namespace rules are unchanged. No new schema, authority, cleanup policy,
Payload, C#, or UI route was introduced by this follow-up.

Real crash/restart behavior, Unity/runtime acceptance, live process identity,
IPC, and release acceptance remain unrun. Existing `child=null` and whole
retained-namespace absence fail-closed limits remain in force. These are stated
limits, not new findings against this narrow repair.

No remaining BLOCKER or follow-up finding was established within the authorized
original-blocker scope. The parent may close the original BLOCKER, while keeping
the broader namespace-contract and real-runtime gates separate.

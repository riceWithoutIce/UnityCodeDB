# S29 removal namespace contract — source acceptance

Date: 2026-10-14 (Asia/Shanghai).
User disposition: `同意 accept`.
Status: SOURCE_ACCEPTED / PASS_WITH_LIMITS.
Base: d88a101f15d21f916cbee9578ab887aa1ea862cd.

The user accepted the complete six-file namespace-contract source snapshot,
including the narrow Manifest-forwarding repair. Coder and independent Verifier
have both terminated. The original COMMITTED REMOVEINTEGRATION recovery-call-site
blocker is closed; the follow-up verification is
REMOVAL-PREFLIGHT-MANIFEST-RECOVERY-VERIFICATION.md. The original namespace review
and its evidence limits remain recorded in
REMOVAL-PREFLIGHT-NAMESPACE-CONTRACT-VERIFICATION.md.

## Accepted SHA-256 snapshot

Paths below are relative to com.rice.ai-codedb. Parent rechecked all six hashes
when recording acceptance; HEAD is unchanged and the staged index is empty.

```text
1bc989195aa14def596e16231cc2876afcedfbab4a5f342ca1384f9567de695a  Tools~/materialize-codedb-host-payload.ps1
b80cccb974c4c30385ee9fe6be6106b5e8e5d17f1da2498a943a3e9f0786becf  Tools~/codedb-instance-engine.ps1
958a0855562b983d7355cf3714c313314703bf481107c402a6fb74e727e6a782  Editor/AICodedbEditorLifecycle.cs
e014f3399bb83b97b69c7f4454d000fa6b2dd69db860e9644ce2cd2e066d2ba8  Tests~/test-codedb-host-payload-materializer.ps1
20f8ce32012cd2212013831595fc99fef9d174fd236cffaec081362e7c38892e  Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs
7af9bccac0843fc49d1c0b946b43840dfe7cfa7181b850a7d779828b7028ade3  Tests/Editor/AICodedbEditorLifecycleTests.cs
```

## Evidence and retained limits

Namespace isolation PASS52, Manifest-forwarding focused isolation PASS54,
wrapper controls PASS27/32, recorded original-byte semantic compilation and
diagnostic/cache/UI seam evidence support source acceptance. Production call
sites were checked statically; the full Install/Uninstall entrances were not
executed by the focused recovery fixture. The failed routing-a1 overlay attempt
had synthetic copied-fixture Install setup mutations before its first assertion;
it is retained as a failure, not passing evidence or a real-project operation.

Actual Manager button availability, live process identity, real crash/restart,
full v1/partial-v1 transaction, stale-pair count overflow, combined failed-before-
install removal, Unity/runtime and release acceptance remain unrun. Child-null
and whole-namespace-missing recovery remain fail-closed. CleanupMono remains
deferred. S29/release remain PARTIAL.

## Next gate

This acceptance authorizes no commit, export, reference switch, live preflight,
Install/Remove/Upgrade, process control or Unity operation. Delivery requires its
own concrete approved envelope under development-workflow.md revision 2.6.
Preserve dirty Payload, unrelated state, historical receipts and prior artifacts.

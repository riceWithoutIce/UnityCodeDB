# S29 v2 removal process identity — source accepted

Date: 2026-10-14. User disposition: `同意 accept`.
Base HEAD: 39d79aeee1bd5525c6ed2eb1369f6c27334b9d07.
Source status: ACCEPTED / SOURCE_AND_ISOLATED_PASS. Overall S29: PARTIAL.

## Accepted snapshot

Parent rechecked the three working-tree hashes against the frozen result before
recording acceptance:

```text
22aa5eedc0f5f61e90f2c17cabbe4496cccd8ba1b2e33028c2101a02268b4f2c  com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1
4b9e60cb7906852e6de3a694b6303451cc69473b4593a593632ad96fe439089b  com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
49aacc0dd0065c32f9d451dfe40da05b7a540afffba71b826dc9e2ab0f2a7f45  com.rice.ai-codedb/Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs
```

Independent verification: REMOVAL-PREFLIGHT-PROCESS-IDENTITY-VERIFICATION.md,
SHA256 d8fb9ae6c5f2ef6bfdeb26685110bb291dc9c1af5d64b99f1abbf88d0420125e.
Coder and Verifier both reached terminal completion. Review returned
0 BLOCKER / 0 FOLLOW-UP within the frozen three-file scope.

Mandatory source gates passed: PowerShell syntax, scoped diff-check,
PathProvenanceOnly, original-byte Editor and Editor.Tests compilation.
Isolated production-call-chain evidence passed 141 assertions; exact C#
diagnostic/cache/UI consumer evidence passed with 13 source members bound.
The recorded protected-state comparison has 4174 unchanged entries. Accepted
input/isolated overlay inventories have 618 files each, with exactly the three
authorized changes. These remain source/isolated evidence, not live acceptance.

## Accepted limits and next boundary

v2 removal now distinguishes an absent original process, matching original live
identity, a reused PID and unavailable identity. It does not claim or stop a
reused process, and classification alone grants no removal permission.
Missing child remains an explicit refusal; the two known actual records are not
reconstructed, deleted or bypassed. Real removal is not declared unlocked.
CleanupMono and non-Windows execution remain deferred/unrun as documented.

This acceptance records the source snapshot only. No commit/export/reference
switch, live preflight/Install/Remove/Upgrade/Probe/IPC, automated Unity, process
control, cleanup, push or publication is authorized by it. HEAD and staged index
were unchanged at recording. No tests were rerun to record acceptance.

Next stage may prepare a concrete delivery envelope for these exact bytes.
Commit, exact export/verification, reference switching and human Unity acceptance
retain their own applicable authority and evidence; prior completed delivery
grants are not silently carried into this new source outcome.

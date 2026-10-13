# S29 preflight handoff FIX2 — candidate projection manifest

Date: 2026-10-12. Candidate: `.artifacts/tests/s29-generation-alignment/fix2-a4/com.rice.ai-codedb`.
This is a distinct candidate from `fix-a1`; all earlier candidates and logs are
retained. The candidate uses only the approved materializer/C# consumer/test
scope.

## Source projection

| Candidate-relative file | SHA256 |
|---|---|
| `Tools~/materialize-codedb-host-payload.ps1` | `70ce751c2a0044855f28132611d01dc84ec59c0aec0835833eff524a4a550758` |
| `Tests~/test-codedb-host-payload-materializer.ps1` | `111c92202b586de960ffa392710e0f9b2e24dedfdf37f683778a394082b41cf4` |
| `Editor/AICodedbHostPayloadMaterializer.cs` | `c229d9778f07154d8dbb74ddf5e431ecf5fe82c29d8e5f7d0e4efea3dab70b3f` |
| `Editor/AICodedbActions.cs` | `9afd83bf12e6e2cdde38cc1630686fc9beb020bf745b6322544a4ec5fc2371e0` |
| `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs` | `a072bf1564b3189b766e6cacb9a23c88d79b27363d37b814c09dfa1a749013b7` |

## Focused evidence

- Log: `.artifacts/tests/s29-generation-alignment/fix2-a4/focused-a4.log`.
- Log SHA256: `12ec4821ab97703753ec11413d75056fe686c3410c2a98acbcc59dedaf8d32f2`;
  6569 bytes.
- Result: `GENERATION_ALIGNMENT PASS cases=35 native_children=0 PocFixture=true
  external_process_observation=synthetic`.
- New direct-entry cases cover missing, expired, authority-drift and
  configuration-drift handoffs, plus a valid direct durable entry.
- The `UNINSTALLED` early entry with no authenticated authority returns the
  explicit conflict before cleanup/recovery and the fixture digest is unchanged.

## Retained failed attempts

`fix2-a1/focused-a1.log` stopped because the generation helper used a function
defined only in another test scope. `fix2-a2/focused-a2.log` stopped for the
same reason with a later snapshot helper. `fix2-a3/focused-a3.log` exposed a
test-only tamper construction that could leave a token unchanged when its last
hash character was already `0`. These attempts remain intact; the bounded
mechanical corrections are included in `fix2-a4` and do not alter production
semantics.

## Protection

No Manager UI test, OwnerIdentity status, dirty Payload, Unity project, receipt,
real Remove/Install/Uninstall, process control, export, reference switch,
commit, cleanup, Unity/MCP/CUA/BatchMode operation was performed. The prior
fix-a1 source/evidence and protected baseline remain separate and unchanged.

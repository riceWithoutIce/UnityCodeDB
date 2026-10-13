# S29 preflight handoff fix — candidate projection manifest

Date: 2026-10-12. Candidate: `.artifacts/tests/s29-generation-alignment/fix-a1/com.rice.ai-codedb`.
The candidate contains only the approved source/test projection and synthetic
fixture evidence. The source snapshot is stable for a new read-only Verifier.

## Changed source projection

| Candidate-relative file | SHA256 |
|---|---|
| `Tools~/materialize-codedb-host-payload.ps1` | `ad75757fd5ff229972e9f77f0259e6add5d69aa65a0e8862cfb216a2979f8d40` |
| `Tests~/test-codedb-host-payload-materializer.ps1` | `0e2c7aa31753f4ddaa468608537146054380fd5625242c359a900ff43ac0bb18` |
| `Editor/AICodedbHostPayloadMaterializer.cs` | `c229d9778f07154d8dbb74ddf5e431ecf5fe82c29d8e5f7d0e4efea3dab70b3f` |
| `Editor/AICodedbActions.cs` | `9afd83bf12e6e2cdde38cc1630686fc9beb020bf745b6322544a4ec5fc2371e0` |
| `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs` | `a072bf1564b3189b766e6cacb9a23c88d79b27363d37b814c09dfa1a749013b7` |

## Focused evidence

- `.artifacts/tests/s29-generation-alignment/fix-a1/focused-a3.log`
  SHA256 `cbf33d45f80bc417cbbf5a9ac0bbd8035a0afebf33ae4506611be7d837465fbf`;
  5463 bytes.
- `GENERATION_ALIGNMENT PASS cases=29 native_children=0 PocFixture=true
  external_process_observation=synthetic`.
- The run covers valid producer/consumer roundtrip, token-integrity refusal,
  historical authority cases, actual `RemoveIntegration` retained intent,
  predecessor-byte retention, and fresh successor publication.

The earlier `focused-a2.log` failure is retained as evidence of the repaired
Windows PowerShell numeric-parser mismatch: `ConvertFrom-Json` materialized
`schema_version` as `Int32` while the strict contract requires an Int64 token.
The fix parses the handoff with the Package strict JSON parser instead.

## Scope and protection

The approved production scope is limited to `AICodedbHostPayloadMaterializer.cs`,
`AICodedbActions.cs`, and the approved materializer PowerShell/test files, plus
the new dedicated Editor parser test. No Manager UI test, OwnerIdentity status,
dirty Payload, Unity project, real Remove/Install/Uninstall, process, export,
reference switch, commit, cleanup, Unity/MCP/CUA/BatchMode operation was run.
The original protected baseline and prior implementation evidence remain
separate and are not overwritten. The pre-existing path-provenance gate and
protected `OwnerIdentityV2Status.json` drift remain outside this fix.

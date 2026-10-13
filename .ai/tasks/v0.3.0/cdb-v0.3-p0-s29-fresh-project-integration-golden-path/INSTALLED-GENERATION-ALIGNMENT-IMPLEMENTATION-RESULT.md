# S29 installed generation alignment — implementation result

Status: `CODER_STABLE_SYNTHETIC_PASS_WITH_PATH_GATE_LIMIT`.

Implementation is limited to the approved five-source allowlist. The canonical
generator now accepts a separately validated predecessor Package root, derives
the predecessor raw payload-manifest SHA256 from those original bytes, preserves
the exact predecessor generation closure, and emits `source_runtime_contract_sha256`
on its exact bootstrap transition while producing corrected successor `poc.43`.

PowerShell readers validate the optional transition hash, resolve historical
selected-v2 runtime context from the Package-declared predecessor identity, and
keep ordinary CURRENT/Uninstall validation strict. `Invoke-RemoveIntegration`
passes a removal-only historical context through its three actual
`Assert-InstanceNextChangeAdmission` calls (entry, authority, pre-commit), while
retaining holder, configuration, effect, journal, fingerprint and final commit
checks. No C# or Node production reader edit was required; Node syntax and
existing transition consumer compatibility were checked.

Evidence:

- Changed source hashes: `INSTALLED-GENERATION-ALIGNMENT-IMPLEMENTATION-SOURCE-SHA256.txt`.
- Candidate file inventories and exact generated hashes:
  `INSTALLED-GENERATION-ALIGNMENT-PROJECTION-MANIFEST.md`.
- `ValidatePayload`: PASS, 60 files.
- Native `VerifyOnly`: PASS.
- Focused synthetic production batch: PASS, 27 cases; log retained under
  `.artifacts/tests/s29-generation-alignment/implementation-a2/focused-a5.log`.
- Node supervisor syntax: PASS.
- Frozen original42 generation closure: 30 files, zero raw-hash differences.
- All eight protected root inventories from the earlier baseline were rechecked
  unchanged before implementation; no real project, dirty Payload, previous
  artifact, receipt, process or Unity state was written.

The existing package-boundary `-PathProvenanceOnly` gate was executed against the
candidate and its frozen retained-disposition source. Both fail at the same
pre-existing finding: `Tests/Editor/AICodedbManagerUiTests.cs` contains a
machine-local absolute path. This task did not alter that out-of-scope test file;
the finding is retained as a release/path-provenance limitation, not concealed as
PASS. No package export, commit, reference switch, Unity/MCP/CUA/BatchMode,
real preflight, Install/Uninstall/Remove, process control or cleanup occurred.
Source is stable for independent read-only Verifier admission; S29/release remain
partial and source ACCEPT is a separate user decision.

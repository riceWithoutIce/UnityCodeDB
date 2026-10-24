# Narrow manifest forwarding repair — stable result

Date: 2026-10-14. Base: d88a101f15d21f916cbee9578ab887aa1ea862cd.
Disposition: PASS_WITH_LIMITS / STABLE FOR PARENT REVIEW.

This follow-up was limited to the two production recovery entrances in
Tools~/codedb-instance-engine.ps1:

- Invoke-InstanceConvergence (Install/Upgrade/Reinstall path)
- Invoke-InstanceUninstall (Uninstall/automatic cleanup path)

Both now forward their existing Package $Manifest to
Invoke-InstanceOperationRecovery. No recovery policy, namespace contract,
Payload, C# or Manager/UI source was changed by this follow-up. The existing
committed REMOVEINTEGRATION recovery guard remains the authority that requires
Package-backed terminal validation before journal cleanup.

## Focused evidence

Evidence root: .artifacts/tests/s29-removal-namespace/coder-a1.

- PowerShell AST syntax parse and git diff --check: PASS.
- manifest-routing-a1.log is retained as a failed attempt caused by using an
  overlay whose engine copy predated these two forwarding edits; it stopped at
  the expected source-shape assertion before the namespace/removal scenario.
  Synthetic original42 Install setup had already mutated the copied fixture;
  no real project was changed. The independent Verifier clarified this limit.
- manifest-routing-a2.log: PASS54, native_children=0, copied project only.
  The first two assertions inspect the actual production function bodies and
  prove both Install and Uninstall entrances pass -Manifest $Manifest.
  The same isolated COMMITTED REMOVEINTEGRATION journal scenario then proves
  Manifest-backed recovery validates retained evidence before cleanup, rejects
  drift while preserving the journal, and clears the journal only after valid
  terminal proof.
- Existing nearest regressions remain in the same retained family: namespace
  scenario a4 PASS52, wrapper ORIGINAL PASS27 and before-install PASS32.
- No Unity, MCP, CUA, BatchMode, real Install/Remove/Upgrade, process start/stop,
  external IPC, commit, export or reference switch was run.

## Scope and limitations

The test uses the previously approved synthetic prerequisite/process seams and
an exclusive copied fixture. It does not claim a real Unity or real Supervisor
recovery result. Existing child=null and whole retained-namespace absence
fail-closed limits remain unchanged. The working tree contains the already
reviewed namespace-contract changes pending user source acceptance; this
follow-up delta is only the two
forwarding call sites plus two focused assertions.

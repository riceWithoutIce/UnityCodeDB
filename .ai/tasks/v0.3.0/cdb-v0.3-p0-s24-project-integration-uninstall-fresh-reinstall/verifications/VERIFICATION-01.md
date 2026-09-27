# S24 GUARDED Verification 01

Task: `cdb-v0.3-p0-s24-project-integration-uninstall-fresh-reinstall`

## Conclusion

**FAIL**. One P1 finding blocks acceptance. The frozen identity admission
passed, but the Manager ordinary-uninstall gate contradicts the frozen
independent-admission contract for an authenticated non-Ready integration.

## Frozen Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- HEAD: `5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`
- Base HEAD recorded by Coder: `5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`
- Seven-path binary diff identity: `a79e661a9ed3368632b976a2e988234ad2413f14`
- Measured seven-path binary diff identity: `a79e661a9ed3368632b976a2e988234ad2413f14`

The seven changed paths match the S24 RESULT allowlist. No identity drift was
observed.

## Finding

### P1-01: Ordinary uninstall is suppressed whenever runtime state is not Ready

`AICodedbManagerWindow.IsUninstallAvailable` requires both an authenticated
cached removal preflight and `status.State == Ready` (source around
`Editor/AICodedbManagerWindow.cs:2077-2084`). The primary-action path likewise
offers only `Remove CodeDB Integration` for `NeedsAttention` and never the
ordinary uninstall action (`Editor/AICodedbManagerWindow.cs:1997-2001`).

This conflicts with the frozen reinstall contract: runtime admission and
uninstall admission are separate; runtime `Needs attention` is not a reason
to suppress a separately authenticated uninstall route, and Manager must
distinguish “Needs attention - can uninstall safely” from “Needs attention -
removal requires review” (`Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md`,
Separate Admission Decisions and Manager requirements). A project that is
installed, non-operational, and passes `UninstallPreflight` therefore has no
ordinary `Uninstall CodeDB from Project` action, even though the contract
requires that route to remain available. The direct UI test currently encodes
the narrower Ready-only behavior (`Tests/Editor/AICodedbManagerUiTests.cs`
around `UninstallPreflight_UsesReadOnlyActionAndGatesReadyMenu`) rather than
covering the required authenticated `NeedsAttention` case.

Impact: a normal user cannot reach the confirmed logical uninstall/fresh
reinstall workflow for a recoverable installed project whose runtime is
temporarily unavailable or otherwise reports `Needs attention`; the user is
forced into the historical `RemoveIntegration` classification or receives no
action. This is a user-path contract violation, not a theoretical hardening
issue.

## Evidence Reused

Per the guarded instruction, no tests were rerun. The review reused the Coder
evidence recorded in RESULT.md:

- Windows PowerShell 5.1 `-PartialV1RemovalOnly`: PASS, exit 0.
- Windows PowerShell 5.1 `-OwnerIdentityRemovalOnly`: PASS, exit 0.
- Windows PowerShell 5.1 `-UninstallOnly`: PASS, exit 0.
- Three affected PowerShell files: AST parse PASS.
- Seven-path scoped `git diff --check`: PASS, exit 0.

The source review confirmed durable removal intent and shared deactivation
entries, `UNINSTALLED / PENDING`, retained inert closure, fail-closed intent
validation, fresh-install non-adoption, worker-cached read-only preflight,
and Manager cache-only reads. Those areas have no additional finding in this
one-shot review.

## Boundaries

No production or test bytes were changed by Verifier. No tests were rerun;
Unity, Unity MCP, C# compile/EditMode, real project removal, external
processes, Provider operations, Package export, full regression, commit,
push, or publication were not run. No Coder contact or follow-up request was
made.

Next role: Planner/User. Decide `FIX`, `DEFER`, or `STOP`; do not route this
snapshot as accepted while P1-01 remains open.

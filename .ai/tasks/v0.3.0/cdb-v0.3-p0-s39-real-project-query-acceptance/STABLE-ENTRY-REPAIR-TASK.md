# S39 stable-entry dependency repair

Date: 2026-10-20. Status: SOURCE_FOCUSED_PASS.
Workflow: codedb-workflow-v2 revision 2.7. Review: NORMAL. Mode: DURABLE_SESSION.
Authorization: the user approved the dependency-publication design and focused
verification, then said "好的 同意". No delegation is authorized or used.

## Objective and scope

Close the diagnosed stable-entry dependency gap without duplicating the shared
instance decoder. Publish the declared bootstrap closure in the existing
activation transaction, verify it in operational readers, preserve it during
legacy retirement, and exercise the real stable entry after activation before
reporting installation Ready. Existing selected identities and failed attempt
01 remain historical evidence; no external attempt is replayed.

Implementation allowlist:

- Tools~/codedb-instance-engine.ps1
- Tools~/materialize-codedb-host-payload.ps1
- Tools~/codedb-project-supervisor.mjs
- Editor/AICodedbPackageRuntimeContract.cs
- Editor/AICodedbHostGenerationStore.cs
- Editor/AICodedbProjectIntegrationState.cs
- Tests~/test-codedb-stable-bootstrap.ps1 (new focused harness)
- Tests~/test-codedb-stable-bootstrap.mjs (new bounded client fixture)
- Tests~/test-codedb-host-payload-materializer.ps1 (only directly coupled fixture support if needed)
- Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md (this bootstrap contract only)
- This S39 task packet.

Paths above are relative to com.rice.ai-codedb except this task packet.
Existing dirty contents in allowlisted files are preserved. Read closure:
stable wrapper, shared decoder, generation/payload manifests, direct publisher,
transaction, readiness, removal and retained-bootstrap consumers and test
helpers. No generic bootstrap framework or serialized schema change is planned.

## Contract and consumer map

The bootstrap closure is the stable wrapper plus its declared direct shared
decoder, using payload-manifest hashes for publication and authenticated
selected-generation bytes for operational dependency validation. Historical
wrappers without that import keep their existing wrapper-only contract.
Publication must check ownership before overwrite and publish dependencies
before the final selection pointer. Existing transaction rollback owns all
new entries. Retirement preserves active bootstrap files; uninstall removes
only authenticated managed files through existing removal transactions.

Operational consumers: PowerShell selected-instance reader, Supervisor selected
closure, C# generation/integration readers. Removal-only historical observations
must not become operational readiness or lose their missing-path semantics.
Post-commit stable-entry probe failure preserves COMMITTED activation and
candidate effects and reports BLOCKED; it does not synthesize rollback.

## Evidence plan and boundaries

L0: PowerShell AST parse, Node syntax, scoped whitespace, unchanged immutable
payload identity. Focused L1: dedicated stable-bootstrap harness using actual
production publisher/validators and stable wrapper in isolated fixtures under
<repository-root>/.artifacts/tests/s39-stable-bootstrap/<run-id>/.
Cover complete publication, missing/drifted dependency and unknown-file refusal,
transaction rollback, legacy-retirement preservation and authenticated removal,
actual stable-entry initialize with a test-owned downstream worker, and probe
failure preserving the committed selection. Adjacent parser contract/activation
fixtures run only as needed for the touched contract; no full suite.

Tests own fixture children and cleanup; retain logs/results, never touch external
runtime. A synthetic downstream worker is not real Provider or Codex acceptance.
No Unity automation/EditMode, live MCP, real Install/uninstall/reinstall, consumer
modification, generation rewrite, version bump, export, commit or push. Exact
artifact, C# Unity compilation and human/client gates remain separate.

Terminal source result: STABLE-ENTRY-REPAIR-RESULT.md. Source implementation and
declared focused evidence are complete; original external acceptance stays blocked.

# v0.3 candidate source integration

Date: 2026-10-25. Status: COMPLETE / SOURCE_INTEGRATION_OFFLINE_PASS.
Authorization: user "ok 继续" after F01/F02 closure and the proposed next step
of unique candidate source integration. No new thread or independent agent.
Workflow: codedb-workflow-v2 revision 2.7. Paths are repository-relative.

## Frozen objective and sources

Converge the primary Package source onto the delivered/accepted
`fe08d6e0961189cedd467487675062564c470644` implementation plus F01 from the
existing `.worktrees/cdb-identity-handoff-heartbeat-followup/` checkout.
Primary HEAD at admission: `f7634d29664e6557308938068814d5d2d1c0fd5c`.
Retain five newer primary documents and the prior F02 exclusion unchanged.
Do not merge branches or copy isolation dirty payload/validation files.

Exact primary product/test write allowlist, under `com.rice.ai-codedb/`:

1. `Editor/AICodedbEditorLifecycle.cs`
2. `Editor/AICodedbHostPayloadMaterializer.cs`
3. `Editor/AICodedbLifecycleEvidence.cs`
4. `Editor/AICodedbManagerTransitionEvidence.cs` (add)
5. `Editor/AICodedbManagerTransitionEvidence.cs.meta` (add)
6. `Editor/AICodedbManagerWindow.cs`
7. `Editor/AICodedbSupervisorBridge.cs`
8. `Tests/Editor/AICodedbEditorLifecycleTests.cs`
9. `Tests/Editor/AICodedbManagerUiTests.cs`
10. `Tests~/test-codedb-project-supervisor.mjs`
11. `Tests~/test-codedb-supervisor-ipc-diagnostics.ps1` (add)
12. `Tools~/codedb-instance-engine.ps1`
13. `Tools~/codedb-project-supervisor.mjs`

Use immutable fe08d6e blob bytes for twelve files; use the verified F01 file
SHA-256 `e939c8d8163ede9ca4a372a608fc5d7c66e24d83d230438e71db496048ea865e`
for LifecycleEvidence. The domain-cached opt-in remains off by default.

Protected: all other primary files, five newer docs, both F02 writer files,
Git index/HEAD, all isolation dirty files, UnityValidationProject, consumer
projects/references, runtime state and previous evidence. Four payload files
listed by Git differ only through EOL normalization relative to the index;
their actual bytes already equal fe08d6e. Do not rewrite them.

Pre-write admission found additional checkout CRLF-only differences (first:
package.json). Preserve those bytes as protected state as well. Compare text
content after CRLF-to-LF solely to classify existing EOL differences; retain
raw SHA-256 for every file. This does not authorize normalization, metadata
repair, or broader source writes. The first check stopped before any product
write; no product failure or external acceptance attempt occurred.

## Execution and evidence envelope

- Task records/scripts only in this directory. Generated plan, preimages,
  journal, full source SHA-256 manifest and receipts only in
  `.artifacts/tests/cdb-v0.3-candidate-source-integration/<run-id>/`.
- Read closure: named sources and direct Package identity/manifest/test tooling.
- Prepare exact preimage/proposed hashes; preserve old bytes before writes;
  reject drift; apply only the allowlist; verify complete tracked Package source
  against fe08d6e with only F01 and the five declared docs differing in content;
  list any preserved checkout EOL-only byte differences explicitly.
- Verify unchanged index/HEAD and all protected files, GUID metadata, C#/PS/MJS
  syntax for changed sources, current payload/generation declared byte hashes.
- Reuse the prior F01 executable offline receipt only if integrated bytes match;
  do not repeat unchanged diagnostic tests or claim new Unity evidence.
- Same-session scoped source review after a stable snapshot. No broad audit.
- STANDARD_30M; two mechanical corrections per scenario, two local repair
  iterations. Stop on external prerequisite/scope drift and consolidate.
- No Unity/BatchMode, MCP, watcher/Supervisor start, installation, package export,
  reference switch, commit, push, board mutation, tag or release authorized.

## Completion

One primary source candidate and explicit complete byte identity manifest;
focused offline checks pass; original dirty state/protected docs retained;
RESULT.md separates source integration from unrun candidate compilation,
consumer/client, lifecycle and release acceptance. Handoff to the user for the
next concrete delivery/acceptance step, without reopening the residual review.

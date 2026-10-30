# Install quarantine admission static review — 2026-10-26

Review mode: read-only review of the bounded source delta in
`.worktrees/cdb-v03-install-quarantine-admission`.

## Scope confirmation

The source worktree changes exactly two product/test files:

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-install-quarantine-admission.ps1`

Task records and repository-owned artifacts are outside the source worktree
change allowlist. The primary checkout remains untouched by the source delta.
No Supervisor producer, Manager, heartbeat, payload, generation, consumer
registration or project runtime file was changed.

## Review conclusions

1. The new branch is reached only while scanning the existing Install Supervisor
   namespace. It recognizes the exact producer shape
   `supervisor-state.json.stale.<timestamp>.<32-lower-hex>` and its matching
   `supervisor.lock` file. Other names continue through the existing rejection
   path.
2. A complete pair is bounded, non-redirected, strictly parsed, project/root/
   runtime/control bound, and checked for matching owner identity. The old
   selected instance and generation are validated structurally but are not used
   to nominate a new selection or trust root.
3. Process absence is checked through the existing Windows start-identity
   comparison. A live same-start owner, uncomparable identity, or unavailable
   observation remains a blocker. A changed start identity only proves PID reuse;
   the replacement process is not touched.
4. Quarantine bytes are never removed or rewritten by the production admission
   path. Existing canonical operation, history, writer, retained-holder and
   competing-project checks remain after the new pair scan.
5. The focused test loads the production functions through the established AST
   harness. Only declared process observations are synthetic; the JSON, path,
   identity, pair and admission validators under review are production code.

No BLOCKER or scope-expansion finding was found in this review. The remaining
limitations are evidence-class boundaries: the harness does not prove a real
Windows Supervisor exit or real consumer Install, and no independent Verifier
session was dispatched.

## Evidence

- PowerShell parse: PASS.
- Focused quarantine admission: PASS, 28 cases.
- Retained-MCP `-L0Only` regression: PASS, 17 cases.
- `git diff --check`: PASS.
- Source hashes are recorded in `RESULT.md` and the source-snapshot manifest.

This review does not authorize a commit, export, Package delivery, reference
switch, Unity operation, real Install retry, board update or release. Those are
the next explicit handoff boundary.

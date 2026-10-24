# Watch-manager selected instance context repair

Status: COMPLETE_SOURCE_REPAIR. Human approved INSTANCE-CONTEXT-REPAIR-PROPOSAL.md.
Result: INSTANCE-CONTEXT-REPAIR-RESULT.md. No commit/export or live acceptance.
Mode: continuous source repair and focused verification; no delegation.
Base: 267b921dee0385962885e8e3142b4e4903ab711b, clean repository-local S42
worktree, existing codex/coordinator-query-readiness branch. Primary dirty state,
index, consumer projects and exact prior export are protected.

Change allowlist: Tools~/codedb-project-supervisor.mjs and
Tests~/test-codedb-project-supervisor.mjs under com.rice.ai-codedb, plus task
records. Pass selected project/instance environment only at runWatchManager's
runChild boundary. No generic child-launch behavior or immutable payload change.

L0: Node syntax on both files, diff/allowlist check.
Affected L1: one explicit --watch-manager-context-fixture invocation in the
existing harness. Original JS launch functions and PowerShell context/session
reader; controlled process-start evidence and intercepted product spawn. Cases:
absent/matching/foreign inherited instance; incorrect inherited Unity root;
no valid lease negative control. Preserve parent/unrelated environment, child
admission/capture and expected lifecycle. Synthetic fixture process only.
One initial batch, up to two same-cause mechanical fixture corrections. Do not
repeat unchanged passing tests or run broad regression.

Not run: production service, consumer recovery, Stop replay, Unity/MCP, Provider,
performance or release acceptance. No commit/export/reference switch. Source
repair completion does not modify the running old Supervisor. Stop if immutable
generation/schema changes or expanded ownership authority are required.

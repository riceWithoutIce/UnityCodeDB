# S40 bounded review handoff

Readiness: stable Coder snapshot admitted by source hashes and evidence receipts.
Review execution is approved: the user explicitly replied `批准` to one
independent read-only Verifier child using inherited model/reasoning settings.
This packet does not authorize delivery, repair, tests or external operations.

## Identity and inputs

- Primary task records: this directory's TASK.md, RESULT.md, SOURCE-SHA256.json.
- Source checkout:
  `<repository-root>/.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission`.
- Base/HEAD: `c848049d90fbdf618905be25225580642d98d987`.
- Branch: `codex/retained-mcp-install-admission`.
- Source is uncommitted; admit the four exact hashes in SOURCE-SHA256.json.
- Raw evidence:
  `<repository-root>/.artifacts/tests/s40-retained-mcp-install/`.
- Final full harness: `cleanup-accounting-ps51-a/result.json`, `run.log`,
  `manifest.json`, `cleanup-observation.json`.
- Prior unchanged-function evidence: `s32-regression-a/run.log` and
  `l1-ps51-b/worker-result.json`, `worker-run-c.log`.

Pre-review admission confirmed all four source hashes, the final test's engine
hash matching the source snapshot, and the readable 29-check PASS receipt.
These checks establish identity and readiness, not semantic acceptance.

## Declared review claims

1. Install admission allows only known same-Package, normal-uninstalled MCP
   readers; unknown ownership, failed preparation and runtime writers remain
   denied. The new exception does not grant deletion or process-stop authority.
2. Existing retained workers remain bound to their own instance. New selection
   does not silently redirect them to the new config/index/coordinator.
3. Final cleanup accounting preserves PENDING while normal-removal retention
   remains; first activation without retained instances stays COMPLETE. The
   extra accounting call is read-only, after existing versioned retirement.
4. Evidence remains isolated HARNESS evidence. No real MCP/Provider, eventual
   lease-drain cleanup, Unity, release, delivery or PS7 PASS is claimed.

## Read and action boundary

Review the four changed files, their diff from the base, and only direct helper
references needed to assess those claims. Inspect the named serialized evidence
without rerunning Coder tests. Avoid broad audits, theoretical hardening, new
requirements and unrelated PS7 repairs.

Source/tests, payload generations, primary dirty state, external projects,
configuration and process state are read-only. No Unity, MCP, Provider, native
service, lifecycle action, test rerun, repair, commit, export or cleanup. No
subagents and no messages to the Coder or other chats. Do not dispatch repairs.

If approved, the single task-level Verifier inherits the main session's model
and reasoning settings. It owns only this task's VERIFICATION.md. Return all
in-scope findings once, prioritized with concrete file/line evidence and impact.
BLOCKER is reserved for the user-defined actual user-path/data/process/release
risks; theoretical hardening and unfrozen requirements are FOLLOW-UP. State
evidence limits even when no actionable findings are identified.

The task records DURABLE_SESSION development with TASK_SPECIFIC delegation for
this one review-only child. The source snapshot and all other authority remain
unchanged; no recursive delegation or further child is authorized.

# Event-triggered transition observer

Status: AUTHORIZED_FOR_ONE_SHOT_READ_ONLY_OBSERVATION.

Use the existing `CodedbTest_2` Unity project. Unity should remain open and
idle; do not close/reopen it and do not perform any Manager action.

From the UnityCodeDB repository root, run the task-owned observer once:

```text
node .ai/tasks/v0.3.0/cdb-identity-handoff-heartbeat-followup/observe-transition-once.mjs <CodedbTest_2-root> 120000
```

Replace `<CodedbTest_2-root>` with the actual external project root. Do not
replace it with a Package, worktree or another test project.

The observer is read-only and task-owned. It does not call MCP, start/stop
processes, reconnect, refresh, install, repair, uninstall, inspect processes or
read product logs. It listens for filesystem changes under the selected
Supervisor, Coordinator and Editor-lease state directories. It captures one
sanitized tuple on the first backend readiness transition and exits, or exits
after 120 seconds with `NO_WINDOW_OBSERVED`.

Return the complete stdout, exit code, and the generated `result.json` path.
Do not rerun if the observer reports `WATCH_UNAVAILABLE`, a path mismatch or an
unexpected read error. Preserve the first result.

Interpretation limits: the observer can capture backend `starting`/`degraded`
and heartbeat evidence. `Unconfirmed` and some `Needs attention` presentations
may be Manager action/cache overrides and are therefore reported as not directly
read; no UI state is inferred from backend files.

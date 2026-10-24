# S38 installed-state smoke - 2026-10-20

Status: `HUMAN_REOPEN_SMOKE_PASS / UNINSTALL_NOT_RUN`.

The user reports that Manager close/reopen, the visible tabs, normal Unity
close/reopen of the same S38 project, retained Ready state and Console behavior
all passed without an abnormality. This is human observation; the parent did not
open Unity or drive the UI.

A bounded read-only checkpoint after the report found the same selected
instance `2fec1db083b74b2c9d371e1bce558736`, generation `poc.43`, and
activation epoch `7fb0873abd2547ba86a3c4ea984bd1db`. Its manifest hash still
matches the current pointer. Desired state is `INSTALLED`, cleanup state
`PENDING`. The existing Supervisor sample at `2026-10-20T05:59:00.724Z`
records `core_ready / COORDINATOR_OPERATIONAL` for the same instance and epoch;
its latest `materialize:Upgrade` operation is completed. This point-in-time
sample does not prove all background work or physical cleanup complete.

Both Package references still identify the exact S37 `d856a8f` extraction and
their hashes match `SETUP-RESULT.md`. Project `.codex/config.toml` exists with
only `[mcp_servers.codedb-current-lifecycle]`; its SHA-256 is
`e146e1a2ccc218635dd0c90fff2c0a6ced11d0e1a2ae53dc9c1d5afa85e118af`.
The exact project Manager index has no current-action file at this checkpoint.
No live status command, test, process control or state mutation was performed.

## Proposed logical Uninstall

After a separate explicit grant, the human selects `Uninstall CodeDB from
Project` once in this S38 Manager and confirms once. Normal product-owned
logical removal, owned MCP registration/current selection changes and
identity-checked owned-runtime handling are within that one action. Keep
Manager and Unity open while it settles. Report Last activity, final Manager
state, and any Console errors or warnings, preferably with a screenshot.

The parent then checks the exact attributable terminal, logical desired state,
current selection, owned MCP registration and separate runtime handoff/cleanup
observations. Acceptance requires a successful Uninstall result, desired state
`UNINSTALLED`, no active current instance, removal of the CodeDB-owned project
MCP table, and Manager's `Install CodeDB` entry. Retained files or cleanup
`PENDING` are reported separately from logical removal. The Unity Package and
unrelated user configuration remain untouched.

On failure, unknown/partial result, unexpected no-op, identity conflict, or
ten-minute nonconvergence, preserve the first result and stop. Do not click
again, manually remove files/configuration, stop a process, retry Install or
proceed to same-version reinstall. This proposal does not itself grant the
Uninstall action; reinstall will be aligned after the actual Uninstall result.

## Explicit Uninstall grant and pre-action checkpoint

The user replied `同意 Uninstall`, authorizing the one human-owned confirmed
logical Uninstall and the bounded read-only result check above. Reinstall and
manual process/state cleanup are outside this grant. The human action/result
is pending.

At the read-only checkpoint, the selected `poc.43` instance and activation
epoch still match the earlier sample and its manifest hash matches the pointer.
Desired state remains `INSTALLED`, cleanup `PENDING`; the Package references
and the sole CodeDB-owned MCP table are unchanged. The exact project Manager
index has no current-action file. An automatic `materialize:Probe` was running
in the Supervisor sample, while its independent operational observation was
`core_ready` for the same instance and epoch. This is a transient maintenance
sample, not a claim of idle or cleanup completion. The human should use the
visible normal Uninstall entry when Manager offers it; if it is unavailable or
the state fails to settle, report that without forcing an action.

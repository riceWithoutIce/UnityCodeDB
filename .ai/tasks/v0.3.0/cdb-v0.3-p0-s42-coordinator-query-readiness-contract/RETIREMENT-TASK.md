# S42 one authenticated retirement attempt

Human authorization: the current development chat explicitly approved one owned Stop. Unity remains open during this gate.

Execute the prepared `retire-live-adapter.mjs` once with the fresh task-owned approval receipt in `.artifacts/tests/s42-retirement/grant-20261022-a/approval.json`. The receipt binds the selected instance, activation, old package reference, Supervisor owner, coordinator PID/start identity and both reviewed script hashes.

The adapter must revalidate those bindings and authenticated ownership before dispatch. At most one Stop is allowed, with the explicit coordinator lifecycle. Poll only its admitted operation within the prepared 90-read/180-second budget. Preserve the first failure, drift, rejection, lost response or timeout and stop without replay.

Success requires terminal completion and all prepared postconditions: the recorded coordinator process absent, coordinator state absent and manual mode stopped. The Supervisor is not shut down by this gate.

No package switch, Start, Install/Uninstall, Unity operation, real MCP query, PID kill or repair is authorized here. Preserve the original evidence. Record the safe receipt and exact counts in `RETIREMENT-RESULT.md`.

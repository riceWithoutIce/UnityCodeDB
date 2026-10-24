# S39 bounded old-Supervisor handoff proposal

Date: 2026-10-20. Status: AUTHORIZED / ORIGINAL_OWNER_ALREADY_EXITED /
STOP_NOT_INVOKED / HUMAN_REOPEN_PENDING.
Cause and evidence: POST-DELIVERY-HUMAN-RESULT.md.

Objective: let the new c07bb59 Package observe an exited, authenticated old
Supervisor, preserving the existing installation and repaired bootstrap.
This does not authorize source repair, Install/Reinstall, automatic new-owner
startup, a client query or broad runtime cleanup.

1. Human closes CodedbTest_0 and explicitly authorizes this bounded stop. Recheck
   Unity process/lock absence and preserve the state/lock evidence, protected
   runtime/config hashes and relevant process observations under a fresh
   task-owned repository backup. Do not print or publish the state auth token.
2. Freshly authenticate exactly the old recorded owner using the lock/state,
   project identity, selected instance/epoch/generation, process start identity,
   reviewed Node executable and full argv/command-line fingerprints. Freeze the
   old Package script hash before invocation. Expected observed PID 75380 and
   owner epoch bf12b96a51544279a65186d8a1754d7b are evidence to recheck, never
   sufficient authority to terminate a process by PID alone. If the owner has
   changed, stop and report rather than target a substitute.
3. Invoke the original d856a8f Package's existing `stop` entry once using that
   reviewed Node executable, exact project/runtime and unity-bridge routing:

   ```text
   <reviewed-node> <external-packages>/d856a8f/com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs stop
     --root <external-project>
     --runtime <external-project>/AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor
     --package-root <external-packages>/d856a8f/com.rice.ai-codedb
     --lifecycle-id unity-bridge --supervisor-id unity-bridge
     --startup-timeout-ms 30000
     --provider <reviewed-provider-executable>
     --provider-config <selected-instance>/config/codedb-mcp.toml
   ```

   Use structured process arguments/PowerShell argument arrays, not literal
   placeholder command text. The existing entry authenticates the live owner
   before sending its authenticated shutdown request. Its shutdown path also
   requests a lifecycle-scoped Coordinator stop and removes its own runtime
   evidence; these normal shutdown side effects are part of this proposal.
4. Bound command completion and observation of the original owner's actual exit
   to 30 seconds total. A printed STOPPED/acknowledgement alone is insufficient.
   Refusal, changed identity, timeout or inconclusive exit stops the attempt.
   No retry, kill, taskkill, lock deletion, state reset or automatic fallback.
5. Verify protected Package references, selection, instance, activation epoch,
   generation, wrapper, recovered helper and MCP registration remain unchanged.
   Preserve the receipt, including any remaining Coordinator evidence. No
   physical cleanup is authorized.
6. Only after successful observed exit and protected-hash checks, hand back to
   the human to reopen the same project and report compilation/Manager status.
   Do not claim Ready until observed; the old state also records a separate
   Coordinator-start failure. Keep real Codex query acceptance pending.

The user explicitly authorized this bounded handoff and confirmed the project
closed. The first fresh observation found the original PID absent, no target
Node process and no Supervisor state/lock. The last retained event records
authenticated_shutdown at 2026-10-20T13:27:57.080Z. No stop command was needed or
invoked. SUPERVISOR-HANDOFF-RECEIPT.json records observed exit and unchanged
protected hashes. The human may reopen the same project for status observation;
Manager and Coordinator readiness and real-client query remain unverified.

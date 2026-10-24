# S39 post-delivery human observation and read-only diagnosis

Date: 2026-10-20.
Status: HUMAN_COMPILE_NO_ERRORS_REPORTED / MANAGER_NEEDS_ATTENTION /
REAL_CLIENT_QUERY_BLOCKED.

The human reopened CodedbTest_0 and reported no compilation errors. Their
Manager screenshot shows Needs attention, no recent command, Host payload
Needs Setup and several downstream checks Not evaluated. The visible shared
reason is `INVALID_OR_AMBIGUOUS: Supervisor process command identity is invalid.`
This is human compile/UI evidence, not Ready, a failed Install, or query success.

Read-only observations explain the refusal:

- The consumer manifest still selects `file:../../Packages/c07bb59/com.rice.ai-codedb`.
- Supervisor lock and state agree on PID 75380, owner epoch
  `bf12b96a51544279a65186d8a1754d7b`, lifecycle/supervisor `unity-bridge`.
- That PID is live, created at 2026-10-20T09:56:18.529845Z, running the old
  d856a8f Package's Supervisor script as `daemon` for this project/runtime.
- Process start identity `639280869785298450`, executable, normalized argv
  SHA-256 `4b4c2ee22c3e8e01cca3afbbc9af940b85857ff51d216c8019f4ee3ed8a3038c`
  and normalized raw command-line SHA-256
  `2a9301088ddc47378939fb2b3478b40bcbfcdb7f5b260c683fe1a2b5c65065eb`
  were independently recomputed and match the lock's owner evidence. These
  support attribution to the recorded owner rather than PID reuse.
- `inspectExistingSupervisor` first authenticates the recorded live process,
  then invokes `validateSupervisorInvocation`. That validator derives its
  expected script from `import.meta.url` and rejects the old script's path.
  Source: `Tools~/codedb-project-supervisor.mjs:581` and `:2780` in c07bb59.
- The new Editor has also launched its new-Package `start` entry. This does
  not change the old daemon's command identity or establish successful takeover.
- The selected pointer, instance manifest, `.codex/config.toml` and restored
  helper hashes still match DELIVERY-RECOVERY-RECEIPT.json.
- Old Supervisor state separately reports degraded / COORDINATOR_START_FAILED.
  That retained status was observed but its cause was not investigated here;
  a successful owner handoff would not itself close Coordinator readiness.

Delivery preflight checked Unity closure but missed this independent live old
Supervisor. The delivery byte-closure and historical module recovery evidence
remain valid; operational handoff is incomplete. This is the same refusal
mechanism previously documented in S30's post-switch reopening diagnosis.
Do not weaken ownership validation or edit historical Package files to bypass it.

No external files, source, process state or configuration were changed in this
diagnosis. No production Supervisor command, MCP, Install/Reinstall/Uninstall,
Unity automation, process termination or query retry was executed. Only S39
records were written. Next proposal: SUPERVISOR-HANDOFF-PLAN.md; authorization
and a fresh human Unity-closed confirmation are required before execution.

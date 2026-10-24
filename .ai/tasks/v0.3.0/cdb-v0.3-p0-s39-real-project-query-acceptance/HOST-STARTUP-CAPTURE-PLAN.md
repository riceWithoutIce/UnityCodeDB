# S39 one-shot actual-host startup capture proposal

Date: 2026-10-20. Status: DEFERRED_NOT_SELECTED / NOT_AUTHORIZED / NOT_EXECUTED.
Cause remains unresolved; see CLIENT-ATTEMPT-02-RESULT.md.

The user prefers discussing system-side observation that preserves the original
registration and timing. This shim is retained as an inert historical proposal;
see PASSIVE-TRACE-CAPABILITY-ASSESSMENT.md for the active route discussion.

Objective: obtain the effective host Node executable/version, working directory,
original wrapper args, child stderr and exit code for one actual Codex startup.
This is startup diagnosis, not Attempt 03 query acceptance or an Installer fix.

## Reviewable prepared implementation

Inert script: `.artifacts/tests/s39-host-startup-capture.mjs`.
Uses Node built-ins only, requires a fresh explicit authorization.json file,
checks selected project config/wrapper/pointer/helper hashes and a single-spawn
CreateNew lock. It invokes the same Node executable with exactly:

```text
AIWork/codedb/wrapper/codedb-project-wrapper.mjs --root .
```

It preserves the actual inherited cwd and environment, forwards stdio, records
stderr up to 64 KiB, and records the original child's exit. It does not correct
paths or dump environment/config tokens. Repeated host entries are refused
before spawning another original-wrapper child. After 20 seconds it gracefully
ends only its own child's stdin; five seconds later a still-live child is
recorded as cleanup pending. No kill, Supervisor stop or deletion is performed.
The diagnostic can leave its own lease while connected; normal EOF cleanup
belongs to the original wrapper/worker, not manual runtime cleanup.

Only syntax checking of this inert script is permitted before this grant.
Actual-host runtime behavior remains untested.

## Proposed authorized sequence

1. Freeze/protect current external project config bytes (expected SHA-256
   770d2319ae6fbfa0eb01cec1faf4870e2a96033453dee44637aef4f88a943502),
   selected pointer, instance, generation, wrapper, recovered helper and Package
   reference hashes. Verify no drift and no redirected capture/target ancestry.
   Create a fresh `.backups/s39-host-startup-capture-01/` with original config,
   protected hashes, script hash, reviewed project root and explicit per-run
   authorization. No global config or Package/source edit.
2. Temporarily change only the target registration args to one absolute path
   to the prepared capture script. Keep registration name, command node, cwd
   '.', timeout 120 and all other config bytes unchanged. Record the exact
   temporary config hash in the grant and before/after receipt.
3. Human creates one new diagnostic Codex chat at CodedbTest_0. The development
   parent does not create/message the chat. The prompt explicitly prohibits
   all MCP tool calls, other-server substitution and retries; it only reads
   the capture files and reports startup observations. This permits normal
   host initialize/discovery and original-wrapper lease side effects. It does
   not permit status/search calls, runtime commands or Installer actions.
4. Read capture output once the child exits or reports cleanup pending. Preserve
   actual cwd, executable/version, stderr/overflow, code, timing and number of
   original-wrapper spawns. A shim refusal is not an original-wrapper result.
   A successful diagnostic handshake is not query acceptance. If no capture
   entry is reached, preserve that fact instead of bypassing the failed gate.
5. Restore original registration bytes only if the current config still equals
   the recorded temporary hash; never overwrite another edit. Verify original
   config hash and all protected instance/Package/bootstrap hashes. Preserve
   all raw receipts under the backup; do not delete evidence or force-stop a
   remaining process. Refusal, timeout, output overflow, changed selection or
   changed config stops the attempt with an explicit partial result.

Keep Unity in its current state; no Unity closure, launch or process stop is
required for this config-only diagnostic. No real Install/Reinstall/Uninstall,
new Package delivery, source commit, push, alternate provider or global config
change is included. Any repair and later real-query attempt follow the evidence.

## Authorization boundary

The earlier attempt grants ended on first failure and explicitly prohibit
registration changes and direct startup substitutions. This proposal requests
one new grant for the temporary project registration, one original-wrapper
startup capture, normal lease side effects and byte-exact config restoration.
No such operation has occurred. User approval is needed before creating its
authorization file or changing external config.

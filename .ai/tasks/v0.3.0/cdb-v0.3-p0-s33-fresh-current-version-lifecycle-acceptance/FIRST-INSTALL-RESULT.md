# S33 first real Install result - 2026-10-18

Status: FIRST_INSTALL_PASS / READY_OBSERVED / CLEANUP_PENDING.

## Human observation

After the authorized single confirmed first Install, user reported `成功了`
and supplied Manager screenshot ending `7b827239-f7e7-4abd-aeeb-a121a1c0fcf9.png`.
It shows CodeDB ready, Last activity Install CodeDB/Ready, displayed duration
12.82 s, and the visible Uninstall CodeDB from Project entry. The screenshot
explicitly labels the Ready display cached; it is not a fresh check on every
GUI read. Diagnostics describe cleanup as not checked by that cached view.

## Bounded read-only evidence

Both S33 Package references still identify the exact b0462ed Package. Follow-up
read only selected project state and the receipt identified by instance origin:

- Action id: `930090062b2c40f88c48ee78e2dfb629`.
- Originating operation id: `ed06285161114339a3b06afbd8984cd3`.
- Action manifest records execution_route project-install-v1 and expected
  project/Package identity. Receipts remain in existing product-local storage.
- Exact writer terminal: state terminal, exit_code 0, timed_out false,
  output_overflow false, output_drain_incomplete false, stderr empty.
- COMMAND_RESULT: INSTALL / INSTALLED / COMPLETE / INSTANCE_ACTIVATED,
  exit_code 0, cleanup_state PENDING.
- Terminal SHA-256:
  `f743d8c6372659953778aa6160c5b1242edec31004c80b126fa82238bfe18969`.
- Output reports verified existing Node/Provider prerequisites and candidate
  verify READY: initialize, exact tools, usable status and bounded query passed.
  Installed/configured/MCP_AVAILABLE report CURRENT. No dependency acquisition
  was performed in this read-only parent follow-up.
- Desired state: INSTALLED, cleanup_state PENDING.
- Selected instance: `1f69a1ae6d4a4b3085c92c6bc1c56dd7`, generation poc.43,
  Package 0.3.0-preview.5, owner identity v2.
- Selected instance manifest hash matches the pointer:
  `80e77960b9d52c816c572f9a866ffe2d1eb3b854dae437a202faa650d84dc424`.
- Activation journal records INSTALL / COMMITTED and this candidate, using
  runtime contract `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- Existing independent Supervisor observation at 2026-10-18T10:39:55.334Z is
  core_ready / COORDINATOR_OPERATIONAL, same selected instance, target generation
  poc.43 and activation epoch `a5e191e93d284a758fe112ba4e4018a3`.
  No new status RPC/probe was issued.
- Exact current-action index is absent at checkpoint, consistent with command
  release; no manual release was performed.

The terminal retains watcher-related execution and reports cleanup PENDING.
Do not report physical cleanup complete or safe Uninstall from Ready alone.
An automatic materialize:Upgrade was running at an earlier read-only checkpoint;
a later state sample was ready. This does not prove all maintenance operations
terminal. Preserve these point-in-time samples without background intervention.

No agent Install/retry/Uninstall, runtime/config mutation, history cleanup,
process control, Unity launch, tests or source repair occurred. Only task records
are updated. This is real first-install evidence, not merely HARNESS evidence.

## Next gate

First Install and independent readiness pass in this environment. Reopen,
Uninstall and same-version reinstall remain NOT RUN. Next human checkpoint:
close/reopen Manager, switch tabs, close Unity normally and reopen the same S33;
report retained Ready and errors/shutdown blocking. This observes normal installed
lifecycle, not another Install. No Uninstall or repeated Install yet; real
Uninstall remains separately aligned after the reopen result.

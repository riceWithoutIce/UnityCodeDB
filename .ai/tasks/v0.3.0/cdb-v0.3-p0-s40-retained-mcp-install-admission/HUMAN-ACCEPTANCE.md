# S40 human acceptance and next bounded gate

## Human open/compile confirmation

On 2026-10-22 (user local date), the user reported `没有报错` after opening
CodedbTest_2. Their attached screenshot shows CodeDB Manager:

- Project: CodedbTest_2; state: Uninstalled.
- Package: v0.3.0-preview.5.
- Project integration message: CodeDB is uninstalled from this project.
- Automatic installation and watcher attachment disabled.
- Install CodeDB action available; no recent command.

Classification: HUMAN_CONFIRMED open/compile checkpoint. The no-error claim
comes from the user's report; this is not an independent Console-log scan.
Uninstalled is the expected preserved logical state after Package replacement.
This does not establish Ready, successful reinstall, a currently retained old
MCP reader or current runtime/response identity. No operation was performed by
the development chat for this checkpoint.

## Proposed single Install gate (historical proposal, superseded by human result)

Keep the same project and natural client lifecycle. Do not manufacture a lease,
stop an old client, reconnect MCP or reset state to establish a starting condition.

1. Development chat performs one bounded read-only starting snapshot: current
   Package reference/engine hash, selected pointer/desired state and existing
   retained-instance/removal-intent/lease evidence relevant to this Install.
   If a retained MCP reader is recorded, check its current PID/start and wrapper
   invocation using read-only process observations. Historical records alone do
   not establish liveness. Do not expose unrelated process/configuration data.
   Stop on conflicting delivered identity or unexpected selected state. An absent
   retained reader limits original-topology coverage; it is not fabricated or
   silently counted as retained-reader acceptance.
2. After that checkpoint, the human clicks Install CodeDB once and completes
   its normal confirmation. No repeat click, automated Install or second attempt.
3. Capture the action's terminal result/Action ID and full output/error plus
   Manager state and any Console errors. On failure stop immediately; preserve
   the original result, do not repair, uninstall or replay.
4. A single bounded read-only post-action snapshot may check selected/new
   instance identity and cleanup state against the original retained evidence.
   Do not run Provider/MCP queries, alter runtime/configuration, clean up or
   control processes. If the action has not reached a terminal result, report
   that fact rather than starting another action.

Success requires a successful terminal Install result and a consistent selected
new instance/Manager outcome. Retained-reader regression coverage additionally
requires an attributable live old reader at the starting checkpoint and
evidence that it was preserved. Logical success with retained cleanup PENDING
does not establish physical cleanup. Real MCP exposure/status/query, second
lifecycle cycle, performance and release remain separate gates.

Approval is requested because DELIVERY-PLAN.md explicitly ended before real
Install; the delivered source/artifact is already complete and reviewable.
The user's no-error report completes the open/compile checkpoint, not this
separately agreed operational grant.

## Human Install result and bounded post-action observation

On 2026-10-22 the user reported `ready 了` with a screenshot showing
CodedbTest_2 Ready and last activity Install CodeDB / Ready / 34.91 seconds.
The human performed the action before the proposed development-chat starting
snapshot. Do not infer an installation count or pre-action live-holder state
from this result. The development chat did not execute or replay Install.

A bounded read-only post-action observation captured the following:

- Action: `63a1cc9fc5fa4e4eb18f67b0442c5685`.
- Receipt route: `project-install-v1`; authorization source recorded by the
  product: `UserConfirmationAndBackendAdmission`.
- Terminal: exit 0, no stderr, no timeout, no output overflow/drain failure.
  Elapsed 34907 ms, completed 2026-10-22T02:08:36.6071205Z.
- Structured result: INSTALL / INSTALLED / COMPLETE / INSTANCE_ACTIVATED;
  cleanup PENDING. Full original stdout/stderr retained in terminal.json.
- Manifest and lock still reference the delivered 186aacf Package. Action
  Package root and current engine hash match that delivery. Action/admitted/
  claim/terminal identifiers and stage linkage match in the captured records.
- Selected/new instance: `a492a5e936c14e4da3ed7e4cc7c8c16c`, READY;
  epoch `063aa347f49a4b9f955a5447f293a0ac`, generation `poc.44`.
- Project identity matches pointer/instance/terminal. Instance bytes match the
  pointer manifest SHA-256, and pointer bytes stayed stable during capture.
- Desired state INSTALLED / cleanup PENDING.
- Old instance `fe3b257859f34023a9e290db3b2ad457` and its removal intent remain.
  Its instance manifest matches the retained manifest hash in that intent.
- Two old MCP lease records remain. At post-action observation PID 53456 was
  absent; PID 25692 existed with a different process start identity and did not
  match the registered wrapper invocation. Neither observation establishes a
  live matching old holder. The unrelated process command line was not archived.

The backend stdout records candidate verification and stable-entry MCP checks
(initialize/tools/status/bounded query) as successful. These are product-internal
installation probes, not actual target Codex-session calls by this development
chat. Screenshot readiness is explicitly cached; it does not perform a new
runtime check merely by being displayed.

Classification: REAL INSTALL TERMINAL / NEW INSTANCE SELECTION PASS. The prior
convergence failure did not recur in this observed action. Acceptance of the
specific live-retained-old-MCP regression remains unestablished: no pre-action
snapshot was captured, and post-action lease records do not prove that liveness.
Physical cleanup and a second lifecycle cycle are not accepted. No repeat
installation, reconnect, cleanup or process stop is performed to fill that gap.

Canonical raw evidence:
`<repository-root>/.artifacts/tests/s40-retained-mcp-install/human-install-post-a/`.
It contains the exact action/admitted/claim/terminal, pointer/new and old
manifests, desired state, old removal intent/leases and snapshot.json with hashes
and limited post-action process observations. The capture script's initial
terminal summary displayed null fields due to Select-Object on an ordered
dictionary; the on-disk snapshot was intact and read back successfully. Only
the summary cast was corrected; no second runtime snapshot was run.

Next separate acceptance step: target Codex session must observe the selected
new instance using its exact namespace and bounded status/query calls, with
response identity distinguished from local disk binding. No such calls were
made in this post-action observation. Keep the current Ready state while that
task is aligned; no new project or additional lifecycle action is required now.

## Target-client result received

The user subsequently returned the completed CLIENT-POST-REINSTALL-TASK.md
report: exact namespace exposed six tools, status=1 and text_search=1, both
successful, real sample hit matched path/line/text, pointer stable, no retries.
See CLIENT-POST-REINSTALL-RESULT.md for the user-transferred evidence and
identity limitations. This closes the agreed post-reinstall functional gate;
it does not close full response/session attribution or real pre-Install
live-old-reader coverage. No additional operations are initiated.

## Post-reinstall reopen result

The human reported no errors but Needs attention, then Ready after about one
minute. A failed Probe and a later successful same-instance readiness/Probe
record were observed read-only. See POST-REINSTALL-REOPEN-RESULT.md: final
convergence PASS with a retained startup warning. No clean-startup guarantee,
additional query, repair, cleanup or repeated close/reopen is claimed.

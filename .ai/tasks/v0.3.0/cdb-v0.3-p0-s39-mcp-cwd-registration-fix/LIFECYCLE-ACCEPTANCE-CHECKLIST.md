# CodedbTest_2 exact-candidate lifecycle acceptance checklist

Date: 2026-10-21. Current status: INSTALLED_REOPEN_SMOKE_PASS /
LOGICAL_UNINSTALL_PASS / SAME_VERSION_REINSTALL_BLOCKED / ATTEMPT_STOPPED.

The user separately approved and attempted one same-version Install. Its
original terminal failed at PREFLIGHT with exit 6: retained instance execution
is live or unknown. See LIFECYCLE-REINSTALL-BLOCKED-RESULT.md. Post-reinstall
reopen is NOT RUN. Do not retry, close an unidentified client, delete leases or
manually clear state. Preparation/next-stage proposals below are historical;
their approval was consumed by the one failed action, not an ongoing retry grant.

The user separately approved and completed one logical Uninstall. Original
action/operation and logical postconditions passed; see
LIFECYCLE-UNINSTALL-RESULT.md. Pending cleanup and handoff explain the warning
at their stated limits. One same-version Install is proposed, not yet approved
or executed. The earlier handoff/preparation text below is historical.

The human confirmed the initial Ready state and subsequently reported normal
Unity reopen, still Ready, no errors. Matching selection/configuration and an
independent core_ready snapshot were checked; see LIFECYCLE-REOPEN-RESULT.md.
The preparation snapshot below remains historical. One logical Uninstall is
prepared as the next separately confirmed human action; do not click Install.

The user requested preparation for the lifecycle acceptance described in
LIFECYCLE-GAP-PLAN.md. This permits read-only consumer binding checks and
preparation of this checklist. It does not authorize automated Unity operation,
Uninstall/Install clicks, process control, environment repair or extra MCP calls.

## Prepared binding baseline

Read-only receipt:
`.artifacts/maintenance/s39-lifecycle-acceptance/preparation-01/baseline.json`.
Sample time: `2026-10-21T09:03:26.716598Z`.

- Project: `<test-projects>/CodedbTest_2`; Unity `2022.3.62f3`.
- Exact source: `c848049d90fbdf618905be25225580642d98d987`.
- Manifest/lock reference:
  `file:../../Packages/c848049-codedbtest2/com.rice.ai-codedb`.
- Package `0.3.0-preview.5`; selected generation `poc.44`.
- Original ZIP SHA-256:
  `3d266307ba7e052140575ada0c39d689e5a62d28a9aa3d686420f15e76a98a5d`.
- All 664 original Package files match the exact ZIP. The single additional
  test `.meta` file was already observed after normal Unity import; it remains
  untouched and separately hashed. Its creator was not independently proved.
  Do not delete it or call the working Package directory byte-identical to the
  original ZIP's entire inventory.
- Project identity:
  `sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c`.
- Selected instance: `fe3b257859f34023a9e290db3b2ad457`.
- Activation epoch: `5bed173a875e461c981da8b7829a897b`.
- Instance file hash matches its pointer; state is `READY`; activation is
  `COMMITTED`; desired state is `INSTALLED`; cleanup is `PENDING`.
- Project registration hash and C# marker hash match the original accepted
  baseline. Generated cwd still identifies this project, with no hand edit.
- The selected pointer bytes did not change during baseline capture.

The latest sampled Supervisor file binds the same identity but shows
`maintenance / SUPERVISOR_MAINTENANCE`. Its operation file records a running
automatic `materialize:Probe` with no Manager action id. A slightly earlier
read showed `core_ready / COORDINATOR_OPERATIONAL`; those are distinct samples,
not a proved transition trace or a Ready assertion for the later timestamp.
No status RPC, new probe, component start/stop or retry was issued by this chat.
The current human-visible Manager state and Unity open/closed state remain
unconfirmed. A file snapshot does not substitute for those observations or
independent process/lease identity.

## First handoff: installed-state ordinary reopen only

Confirm the human's current Unity/Manager state first. If Unity is open, allow
the normal product observation to settle to Ready before the intended close;
do not trigger a refresh/repair to obtain that state. If it is already closed,
record that start state and reopen it normally without inventing an observed
close. If necessary, a subsequent ordinary close/reopen can supply that smoke
evidence within this stage; stop rather than looping on a failed opening.

Human actions for this stage:

1. Normally close the target Unity Editor and reopen the same CodedbTest_2
   project, subject to the confirmed starting state above.
2. Open the CodeDB Manager; observe whether it returns to Ready and whether
   Console reports compilation/errors. Normal Manager open/close and tab use
   may be observed as part of this smoke check.
3. Report the final state, any errors and whether any Unconfirmed presentation
   recovered. Do not click Uninstall, Install or repair during this stage.

After the human report, this chat checks bounded existing state for unchanged
Package/config/selection and an independent matching readiness observation.
Record human smoke separately from disk evidence. A normal reopen PASS does
not establish Domain Reload reconnect identity or a full process-isolation test.

If readiness does not converge within the proposed ten-minute ceiling, a real
error/ownership conflict occurs, or the initial Ready prerequisite remains
unavailable, preserve the first evidence and stop. No timed retry or manual
cleanup is included. Brief Unconfirmed alone is not automatically failure.

## Subsequent stages: prepare only, do not click yet

| Stage | Admission before the human action | Evidence to close before proceeding |
| --- | --- | --- |
| One logical Uninstall | First-stage report and disk evidence checked; exact current action/project baseline captured; real action scope confirmed. | Attributable original terminal and logical postconditions, including inactive selection/owned registration and preserved unrelated settings. Cleanup pending stays separate. |
| One same-version Install | Prior logical Uninstall has a confirmed successful original terminal/postconditions; same Package still selected; real action scope confirmed. | New action/operation, a distinguishable current instance and activation, generated cwd and independent Ready evidence. |
| Post-reinstall ordinary reopen | Reinstall action and Ready evidence checked. | Human no-error/Manager smoke plus retained selection and matching independent readiness. |

Do not promote the most recent unrelated automatic operation to the human
action result. Do not reuse the original instance's query as a result for a
future activation. No extra explicit target MCP call is included in this route.
Normal product-internal probes remain part of the ordinary product operation.

An original action failure, unknown outcome, binding drift or safe refusal
stops dependent stages. Never delete leases/history, force-stop external
clients, patch configuration or repeat a failed click to satisfy this checklist.

## Retained limits

No stage has passed merely because preparation passed. Existing initial
install and real-client C# sample acceptance remain closed and attributable
to their original records. This supplement does not accept full session
identity, Shader/HLSL coverage, transparent cross-version upgrade, physical
cleanup, performance, complete Runtime/Discover Read gates or public release.
No implementation source or external file was modified during preparation.

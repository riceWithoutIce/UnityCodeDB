# CodedbTest_2 installed-state normal reopen result

Date: 2026-10-21. Status: INSTALLED_REOPEN_SMOKE_PASS /
UNINSTALL_NOT_EXECUTED.

## Human and independent file evidence

The human confirmed the starting state: Unity open, Manager Ready. Following
the ordinary close/reopen handoff, the human reported:

> unity 重新打开 还是ready，没有报错

At `2026-10-21T09:27:16.728823Z`, read-only checks found:

- Package manifest/lock, project registration, selected pointer/instance,
  activation, Unity version declaration and marker hashes match the prepared
  baseline; there are no binding mismatches.
- Selection remains instance `fe3b257859f34023a9e290db3b2ad457`, epoch
  `5bed173a875e461c981da8b7829a897b`, generation `poc.44`.
- Desired state remains `INSTALLED`, cleanup `PENDING`.
- The independently written Supervisor and operational-readiness snapshot at
  `2026-10-21T09:27:16.650Z` reports
  `core_ready / COORDINATOR_OPERATIONAL` for the same project, instance, epoch
  and runtime contract.
- Selected pointer bytes were unchanged across this read.

Receipt:
`.artifacts/maintenance/s39-lifecycle-acceptance/reopen-01/result.json`.
No status RPC, explicit CodeDB call, component start/stop or external write was
performed by this chat. Readiness is an existing file observation; the human
supplies the UI/normal reopen evidence. This is not a Domain Reload identity
trace, OS process/lease authentication or complete runtime-isolation acceptance.

The agreed first lifecycle stage passes for the exact c848049 / poc.44
candidate. Later lifecycle stages and release acceptance remain unrun.

## Prepared next stage: one logical Uninstall

Project-bound Manager index observation at `2026-10-21T09:28:23.655621Z` found
no current-action file and only the already resolved initial Install marker.
Receipt:
`.artifacts/maintenance/s39-lifecycle-acceptance/pre-uninstall-01/baseline.json`.
This is a pre-action file sample, not proof that no future background work can
start. Do not lock, pause or reset normal product maintenance for acceptance.

Proposed human scope after explicit confirmation: invoke normal
`Uninstall CodeDB from Project` once and confirm its normal dialog once in this
same project and unchanged Package. Product-owned logical deactivation and
configuration/runtime handling remain under the existing product contract.
Do not remove the UPM Package or manually delete any file/lease, kill a process
or patch configuration. Uncertain ownership must retain the product's refusal.

After the action settles, report final Manager state, Last activity/outcome and
any errors or warning. This chat will read the new attributable original action,
terminal, operation and logical postconditions; do not treat an unrelated latest
maintenance operation as the human action. Pending physical cleanup is separate.

Do not click Install until this Uninstall result has been checked. A failed or
unknown outcome, conflict or ten-minute nonconvergence stops the attempt with
no retry or manual repair. This proposal has not executed or authorized the
Uninstall, reinstall or another query.

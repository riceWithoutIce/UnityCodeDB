# Current preview basic-flow lifecycle evidence gap

Date: 2026-10-21. Status: STATIC_MAPPING_COMPLETE /
BOUNDED_ACCEPTANCE_PROPOSAL / REAL_OPERATIONS_NOT_AUTHORIZED.

Current terminal update: preparation and separately authorized human actions
subsequently ran. Installed-state reopen and logical Uninstall passed. The
single same-version Install failed at PREFLIGHT with exit 6 (retained holder),
so the supplement is stopped/incomplete and its final reopen is NOT RUN. See
LIFECYCLE-REINSTALL-BLOCKED-RESULT.md. The original proposal below is historical
and grants no retry, repair or client/process stop.

Preparation update: the user requested preparation for this acceptance.
Read-only current-consumer checks and the binding receipt are complete; see
LIFECYCLE-ACCEPTANCE-CHECKLIST.md. Human starting state is pending. No Unity,
Uninstall or Install action has been executed or silently authorized by the
preparation request. The proposal below remains the intended evidence route.

## Selected scope and evidence already closed

The user agreed to basic-use-flow preview stabilization and confirmed that the
work completed so far is the basic flow. Use exact
`c848049d90fbdf618905be25225580642d98d987`, Package
`0.3.0-preview.5 / poc.44`; preserve the existing exact ZIP and CodedbTest_2
Package reference. Do not export from the dirty combined primary tree.

S39's fresh install/generated registration/client startup/status/one C# hit
gate remains closed at its documented limits. Do not repeat first install,
status or marker search just to reconfirm that same result. Full response/chat
identity, broader language/query coverage and performance are not established.

S38's install, installed-state reopen, logical uninstall and same-version
reinstall evidence is attributable to `d856a8f / poc.43`, not this exact
candidate. Its periodic-observation warning and cleanup pending are retained.

## Bounded static mapping

Read-only comparison of the two committed Packages found 58 changed paths.
Only the lifecycle-adjacent changes are relevant to this proposal:

| Change family | Relevant source | Why older lifecycle evidence is not a full current-candidate PASS |
| --- | --- | --- |
| Selected stable launcher dependency validation | `Editor/AICodedbHostGenerationStore.cs`, `Editor/AICodedbPackageRuntimeContract.cs`, `Editor/AICodedbProjectIntegrationState.cs`, `Tools~/codedb-project-supervisor.mjs` | Installed-state admission/reconnect now checks a shared bootstrap dependency against the authenticated generation. Normal reopening must retain a usable current selection under these readers. |
| Bootstrap publication and current/retained-instance checks | `Tools~/codedb-instance-engine.ps1` | Publication, preflight and selected-instance validation cover the fixed bootstrap dependency; retained-effect validation used by removal is also amended. Fresh install PASS does not exercise a complete normal uninstall/reinstall sequence. |
| Post-activation stable-entry probe | `Tools~/codedb-instance-engine.ps1`, `Tools~/probe-codedb-mcp-availability.mjs` | A committed activation followed by probe failure retains selection and reports failure separately. A successful initial install covers that initial action, not a later reinstall action. |
| Project registration values and bootstrap retirement handling | `Tools~/materialize-codedb-host-payload.ps1` and selected payload scripts | Registration uses project-derived cwd; bootstrap dependency handling changed. Reinstall should regenerate the intended owned registration and preserve unrelated configuration. |

`Editor/AICodedbProcessRunner.cs` and
`Tools~/invoke-codedb-manager-action.ps1` are byte-identical between the two
committed candidates. Their primary-only unaccepted lifetime WIP was expressly
excluded by earlier delivery and remains outside this runtime baseline. No
safe-cancellation completion or new shutdown guarantee is inferred here.

This mapping identifies affected evidence, not a defect, implementation review
or claim that unchanged historical tests are invalid. It does not reopen S31,
S29 or all Runtime/Discover Read release gates as development tasks.

## Minimal proposed real route

Prefer reusing `<test-projects>/CodedbTest_2` and its current exact Package.
No evidence requires another fresh project for this same-version sequence.
This round did not inspect the live consumer; the last accepted identities are
historical baselines, not a claim that its present state is unchanged.

Before any real attempt, confirm its current Package reference/bytes, project
selection and normal Manager state against the agreed candidate. Stop and
report drift before writes or actions. Preserve the test marker, existing
configuration, runtime records and external client processes. Do not clear
leases, change global config, patch registration, hand-start components or
force-stop an owner to make the route pass.

The proposed one-attempt sequence is:

| Stage | Human action | Acceptance evidence |
| --- | --- | --- |
| Installed-state reopen | Normally close/reopen Unity and use the Manager. | Human compile/UI observations plus separate current selection/readiness evidence. Ordinary reopen is smoke evidence, not a Domain Reload identity trace. |
| Logical uninstall, once | Invoke the normal product Uninstall action. | Original attributable action/terminal result and logical postconditions: inactive project selection and owned registration; preserve unrelated settings. Cleanup may remain separately pending under the existing contract. |
| Same-version Install, once | Only after logical uninstall has a confirmed successful terminal state, invoke normal Install with the same Package. | New attributable action and activation, matching current selection/contract, generated cwd and independent Ready evidence. Do not reuse the original instance's query response as proof of this activation. |
| Post-reinstall reopen | Normally close/reopen Unity and use the Manager. | Retained current selection/readiness and human compile/UI smoke observations. |

The human owns all Unity launch/close/menu actions. Development-side observation
uses bounded existing receipts and state; no shell/SDK query substitutes for a
real client. No additional explicit CodeDB tool call is proposed by this
lifecycle route. Normal product-internal probes remain part of the product's
ordinary action, not manually injected diagnostics.

Use the existing S38 ten-minute nonconvergence ceiling as the proposed outer
observation bound, without extending product timeouts or adding a timed retry.
Any failed/unknown original action, nonconvergence, ownership/config conflict,
or missing prerequisite stops dependent stages. A safe refusal is recorded as
a refusal, not overridden. Do not click the next action after a stop, retry
automatically, reset state or repair the environment within this attempt.

The recorded transient Unconfirmed presentation alone is not failure if it
recovers within the agreed observation window and the original action and
independent readiness succeed. Persistent nonconvergence or unavailable normal
interaction stops the attempt; no cause is assigned from the UI label alone.

## Decision and limits

This is the proposed supplement for the current basic lifecycle gap, not a
runtime execution grant. After its exact target, actions and observation scope
are approved, prepare the current binding baseline before the first human
action. No new Package switch, first-install repeat or fresh project is assumed.

Even a PASS would close only this same-version lifecycle supplement. It would
not establish full Domain Reload/scheduling/freshness/process-isolation gates,
cross-version migration, public release or the full Discover Read roadmap.
Those promises retain their separate evidence decisions; no broad test suite
or further feature implementation is automatically activated.

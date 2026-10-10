# S29 post-install status and activity repair

2026-10-10. Scope and acceptance frozen following user agreement. Source baseline b8a143214076445b3435507782132366eb1418d2; existing dirty state is not part of this task unless explicitly identified below. S29 remains PARTIAL.

## Evidence and responsibility

See POST-INSTALL-EDITMODE-UI-DIAGNOSIS.md. INSTALL dc72675bc8e54b4daaf82592115f2448 has authenticated successful terminal evidence and selected a new instance. This is installation outcome evidence, not a continuing availability guarantee. Human stayed in EditMode. Incorrect Play wording and Provider-only progress gating are confirmed source defects. Retirement overwrites product observation in the lifecycle; exact photographed oscillation timing and the reason successful-action index release failed remain unresolved. Do not describe those hypotheses as proven causes.

Four independent facts must remain independent:

- Command outcome: the authenticated action terminal and original success/failure.
- Current product readiness: authenticated observation of this selected instance, with provenance and freshness preserved.
- Historical cleanup: pending/completed/failed retirement, including any concrete risk affecting current readiness.
- Next-change admission: authenticated action journal disposition, not a UI label or cleanup flag alone.

## Frozen changes

1. EditMode cached status must use accurate cache/observation wording. Play-specific suspension messages apply only to explicit Play suspension. Retain last-observed time/provenance; never label a cache read a new verification.
2. Every running Manager action must show visible progress feedback in Activity. Use an indeterminate indicator when measurable stages are absent; preserve determinate Provider stages when present. Do not invent percentages, add progress to the header, call global DisplayProgressBar, or delay terminal completion until a status refresh finishes.
3. Separate current-instance readiness from historical retirement results. Pending cleanup alone must neither fail a successful INSTALL nor invalidate an otherwise fresh authenticated Ready observation. A retirement result lacking readiness fields is not itself a failed readiness observation. Preserve genuine current-instance invalidity, unavailable MCP, stale evidence and unknown effects; no unconditional sticky Ready, TTL removal or weakened identity checks. Trace the actual competing observations and add a focused regression for the proven route. Evaluate the cleanup-COMPLETE post-install reconcile restriction only within this route; do not broaden automatic mutation permissions.
4. Trace and retain the return/detail of successful terminal-to-index release. Identify and repair its concrete failure within the journal/session boundary if reproduced. Do not manually delete/release the real index or assume PENDING cleanup is the cause. If repair requires changing ownership/authentication semantics, return a design finding before that change. Preserve original historical failed outcomes and retained-effect dispositions.

## Implementation and review boundaries

Expected surfaces: Editor/AICodedbActivityPanel.cs, AICodedbStatusSnapshot.cs, AICodedbManagerWindow.cs, AICodedbEditorLifecycle.cs, AICodedbActions.cs and AICodedbManagerActionJournal.cs, plus narrowly relevant existing Editor tests. Touch only surfaces required by the proven fix; no payload/generation bump, transport redesign, general Host refactor or historical cleanup redesign.

Use the agreed sequential Coder -> stable attributable snapshot -> independent read-only Verifier workflow. Reviewer checks these four findings and adjacent regression only; returns findings together to the user. No directing a running Coder to make additional changes. Freeze actual changed-source hashes and clearly distinguish source compilation, isolated regressions and human Unity evidence.

Unity is currently human-controlled. No launch, batchmode, MCP/UI control, real Install/retry, uninstall, receipt rewrite, process stop, cleanup, system TEMP/ACL workaround or external configuration edit. Source/isolated tests must use repository/project-local owned workspaces. Delivery preparation retains standing user authority, but reference switching requires confirmed closed Unity and a verified concrete package.

## Acceptance

- EditMode cache snapshots have no false Play explanation; explicit Play suspension retains accurate wording.
- Running Install/Uninstall without stage output retains visible indeterminate feedback; Provider stages remain measurable; terminal ends command progress independently of read-only refresh.
- A successful INSTALL plus cleanup PENDING keeps success, current readiness, cleanup and admission distinguishable. Retirement with no readiness result cannot erase fresh authenticated Ready. Genuine unavailability and expiry still render honestly.
- An authenticated complete successful terminal either releases its exact matching index or exposes the specific release failure. Unknown/incomplete output and mismatched identity still retain admission. Historical failed outcomes remain unchanged.
- Tests exercise production reader/classifier/session routes, not copied implementations. Semantic compilation covers new test calls where feasible; report tool limits instead of claiming Unity compile.
- Human final checks are limited to compilation, focused changed-flow tests, Manager running/completed presentation and sustained EditMode observation. Reuse installed success evidence; no repeated real INSTALL solely to obtain a progress screenshot. If a real operation is necessary, explain the remaining evidence gap and obtain its own confirmation.

## Handoff status

2026-10-10: user explicitly authorized task dispatch. Coder implementation is authorized within this frozen scope. Coder must produce POST-INSTALL-EDITMODE-UI-RESULT.md and a stable changed-source SHA256 manifest before independent read-only verification. Stop at a stable handoff or concrete design blocker; no commit/export/reference switch by the Coder. Parent coordinates subsequent verification. Existing baseline HEAD remains b8a143214076445b3435507782132366eb1418d2; no pre-existing Editor/Tests source diff was observed at dispatch. Preserve all other dirty state.

Parent confirmed Coder completed/stopped and verified all six frozen source hashes. Independent read-only Verifier `/root/s29_post_install_ui_verifier` dispatched. User clarified orchestration: parent remains active, monitors child completion and returned questions, and follows each authorized stage through its attributable result; dispatch alone is not completion. Findings require user disposition before additional repairs. No durable-memory write was requested or performed.

Parent monitored Verifier through its terminal result and separately confirmed completed status. POST-INSTALL-EDITMODE-UI-VERIFICATION.md reports scoped source/isolated PASS with no BLOCKER: six hashes match, semantic compile zero errors, 13 methods/20 cases PASS, copied exact index release/session PASS and 26 original records unchanged. Native Unity gates remain NOT_RUN. Next role: User source acceptance, then authorized delivery preparation; S29 remains PARTIAL.

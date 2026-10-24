# S32 F1/F2 targeted repair review - 2026-10-18

Disposition: **FIX / user boundary decision recommended**. F1 is closed for the
reported unrelated-inaccessible-process case. The unsafe terminal-result
acceptance in F2 is corrected, but its directly coupled history discovery still
rejects a supported, normally completed no-spawn Supervisor operation. Source
ACCEPT is not recommended for the complete agreed retained-history route yet.

## Review boundary and evidence

Reviewed the parent-admitted repaired snapshot, TASK's 2026-10-18 amendment,
RESULT's repair append, immutable original VERIFICATION, the new engine
admission/terminal helpers, S32 contract append, repair drivers and final logs,
and only their direct writer/Supervisor producer and terminal-validation
references. Parent had already admitted hashes and protected inputs. No hash
checks or tests were rerun. No product/test/evidence bytes were changed; this
report is the only write. No Coder contact, children, Unity, process operations,
network, real lifecycle execution, commit or delivery occurred.

Evidence remains HARNESS. The 25 reported admission cases and frozen immediate
writer/result/reopen regression passed in the existing repair-e logs. Process
inventory/identity and retained closure are mocked. The original runtime chain
starts at ProcessRunner; actual Manager invocation, successful full Install,
Provider/convergence/Ready, real inventory visibility and Unity remain deferred.
Those declared limits are not additional findings.

## Original finding dispositions

### F1 - CLOSED for original reported defect

`Tools~/codedb-instance-engine.ps1:4873` now skips unrelated rows with inaccessible
CommandLine rather than treating executable name alone as project ownership.
Readable project-bound rows remain refused at :4880; identifiable competing
writers have their admitted project identity checked at :4883. Authenticated
current writer/child checks remain at :4856 and :4863, retained holders at :4903,
and owner/start/takeover/unknown namespace evidence at :4923. A referenced child
still goes through the existing identity-aware process-absence helper at :5000.

The existing repair-e log distinguishes unrelated inaccessible metadata from
referenced identity unavailable, original child live and PID reuse. The reused
`Assert-RemoveIntegrationV2ProcessAbsent` implementation
(`Tools~/materialize-codedb-host-payload.ps1:10156`) preserves unknown/live refusal
and treats a different valid start identity as PID reuse without termination.
This establishes the agreed supported project-evidence boundary, not global
absence or detection of all unmanaged/foreign processes.

### F2 - UNSAFE ACCEPTANCE CORRECTED; adjacent normal-history refusal OPEN

The original missing-result/timeout/incomplete-output acceptance is corrected.
Structural discovery calls `Assert-ProjectInstallTerminalResult` for every
discovered operation before inert classification (:4950). It requires the
terminal envelope, valid timestamps, child shape, consistent exit/state, and
explicit Boolean false timeout/overflow/drain flags (:5011 through :5035).
Queued/running and incomplete noncanonical operations cannot be hidden by a
later canonical record (:4942). Canonical/hash, action-map references and
retained-origin/current/same-action deep checks are present (:4964 through
:5000). Complete failure remains failure, with independent retained-effect
admission. Coherent inert old history does not require its old Package closure.

**Remaining P1 / BLOCKER within F2's history exception:** unconditional non-null
child discovery at `Tools~/codedb-instance-engine.ps1:4947` treats an ordinary
completed no-spawn `ensure`/`reconcile` record as unfinished execution forever,
even when it is noncanonical inert history after a complete uninstall.

Source-grounded trigger and path:

1. The existing supported Supervisor `ensure` or `reconcile` command is admitted
   as a maintenance operation (`Tools~/codedb-project-supervisor.mjs:1568`). Its
   original producer initializes `child: null` at :1484.
2. When Coordinator is already ready, original `ensureCoordinator` returns a
   successful attached result at :1915-1916, without spawning a child or calling
   `prepareOperationChildEvidence`/`recordChildEvidence`.
3. Original `finishOperation` writes `completed/completed` and the compact
   successful result at :1314-1330; `compactResult` supplies false completeness
   flags at :2060. The child intentionally remains null. The public supported
   reconcile success route is also exercised by the existing Supervisor test
   source at `Tests~/test-codedb-project-supervisor.mjs:992` (not rerun here).
4. A later complete uninstall can become canonical while this coherent older
   operation remains in operation-history; `persistOperation` preserves the
   per-operation file (:2137). The new Install discovers it and throws at engine
   :4947 before the :4988 current/reference filter, even if all actual owners,
   holders and children are gone and the final uninstall is complete.

This is not a request to support arbitrary legacy missing-child records or to
infer child absence from terminal labels. A no-spawn success and a missed
post-spawn capture can both currently have null child; blindly allowing null
would recreate the ambiguity the repair correctly refuses. The specific
producer/consumer boundary needs disposition: preserve trustworthy no-effect
distinction (if available within the agreed authority) or explicitly return the
supported-history limitation for the user. Do not silently broaden authority,
delete history, migrate old records, or add blanket child-null acceptance.

The repair harness only produces non-null-child completed history. Its inert-old
generation case clones that same shape, so its PASS does not cover this original
producer shape. This finding is a directly coupled normal-history availability
gap in F2, not a new full audit or a requirement for full Provider installation.

## Pre-effect authority prerequisite and unchanged regression

The narrowed relevance strategy has source-backed pre-effect ownership for
the reviewed original producers:

- Direct writer authenticates its command/admission, publishes claim at
  `Tools~/invoke-codedb-manager-action.ps1:266`, then starts child at :286.
  The engine checks writer/child identity under the existing project lock.
- Supervisor publishes exclusive attributable start claim at
  `Tools~/codedb-project-supervisor.mjs:370` before daemon spawn at :907; daemon
  obtains owner lock at :1011 before serving/Coordinator startup.
- Queued operation is persisted at :1495 before scheduling; running operation
  at :1360 before callback execution; materializer phase at :2038 before child
  spawn. Canonical/history publication is :2137. Child identity capture at
  :2381 is post-spawn, but published owner/operation evidence covers that
  interval; a missing child is not used as pre-effect absence proof.

No additional finding was found in this bounded publication-order check.
The repaired engine remains before recovery/candidate creation under the
existing project lock (:5072-5102). Route markers/readers/writer producers,
initialization, readiness and exact pending-action handling were not changed
by the repair; the existing immediate route/result/reopen regression passed.
No new work is assigned by this report. All dispositions are returned together
to the parent/user; this review stops here.

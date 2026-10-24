# S42 Stop failure: scoped read-only diagnosis

Status: DIRECT_FAILURE_ESTABLISHED / INSTANCE_CONTEXT_PROPAGATION_CANDIDATE.

Follow-up: INSTANCE-CONTEXT-REPRO-RESULT.md now establishes the inherited-context
dependency through an offline original-function reproduction. Historical child
environment attribution remains unobserved. The narrow unimplemented source
proposal is INSTANCE-CONTEXT-REPAIR-PROPOSAL.md.
Date: 2026-10-22. The human requested continuation after RETIREMENT-RESULT.md;
this continuation inspected existing evidence and source only. No product edit,
new Stop, status RPC, process probe or consumer change was performed.

## Attributed terminal evidence

Read the history entry for operation `cbe070b2575946efb75ad8eaef555b61`, rather
than the rolling operation.json that subsequent Probe work can replace. Verified
the exact operation name, selected instance, project identity and Supervisor owner.
Operation bytes SHA-256:
`9a3c32a6fb0c1f38ca892c285ae97b96643b6d3c0a0ec874592a5b4d7b611a3a`.

The operation is terminal `failed`, disposition `CHILD_ADMITTED`, with a recorded
PowerShell child PID/start/argv hash. Execution began at 04:29:23.864Z and ended
at 04:29:24.937Z. Exit code is 1; timeout, output overflow and incomplete drain
are all false. This establishes child execution failure, not a missing operation
or a merely queued request. It does not establish current child liveness.

Persisted stderr matches this static watch-manager error exactly:
`Start now, Stop now, and Restart require an interactive Unity Editor session.`
Raw stderr, tokens, pipe names and child argv were not emitted or copied.

The selected generation's manage-codedb-project-watch.ps1 has SHA-256
`2dd95cf67c0cf30a6c9e9333dcd739e49549ca3ba32e99a5ca95c0d8cc8c67eb`.
For Action Stop, lines 871-874 reject an empty Get-ActiveEditorSessionIds result;
the coordinator stop is invoked later at lines 876-879, and manual-stopped state
is written at 881-882. The identical message at Write-ManualRuntime line 457 is
guarded by the same nonempty session array already checked by this Stop branch.
This narrows the failure to the active-session prerequisite before coordinator
Stop dispatch. The management lock can already have been created/acquired at
lines 676-677; do not claim the child was globally without filesystem effects.

## Static context propagation gap

In the installed old Package:

- Get-ProjectCodedbContext in generation scripts/codedb-project-common.ps1,
  lines 130-144, selects the instance ProviderRoot only when
  RICE_CODEDB_INSTANCE_ROOT is present. Otherwise it selects the project-named
  legacy runtime. The generation script location and project cwd do not select
  an instance by themselves.
- Watch manager lines 617-622 derive the Editor lease directory from ProviderRoot.
  Its reader rejects missing, malformed, stale or process-mismatched leases;
  an empty result alone does not distinguish those cases.
- Supervisor runWatchManager, lines 1999-2014, does not explicitly pass selected
  instance environment. runChild, lines 3096-3102, inherits process.env when no
  environment argument is supplied. Supervisor daemon launch sets the Unity root
  explicitly, not the instance root (line 926).
- Editor AICodedbSupervisorLauncher.RunNodeStart, lines 150-165, also does not
  explicitly set the instance environment. A separate PowerShell runner has
  instance-environment support, but this is a different launch path.

The exported S42 source retains the same watcher invocation behavior at lines
2082-2097. Its service-shape/readiness fix does not close this context propagation
gap. No immutable generation source or production Package has been edited here.

## Current disk corroboration, separately timed

At 04:35:19.947Z a single bounded disk comparison observed:

- Selected instance editor-leases directory: present, one JSON lease. Schema,
  managed-by, filename/session, project/root, tick shape and timestamp ordering
  checks match. Heartbeat age was 4814 ms. Process identity/liveness NOT_PROBED.
- Legacy project-named editor-leases directory: absent.
- Selected pointer unchanged from the retirement baseline.

This is current disk evidence, not a failure-time lease sample. The Supervisor's
actual inherited environment was not read. Accordingly, missing explicit instance
propagation is a concrete source gap and the leading explanation; this record
does not prove the historical child lacked that environment or rule out all
lease validation failures. Do not declare heartbeat expiry the root cause.
PowerShell -NonInteractive by itself is not this script's session test.

## Evidence artifacts and limits

Canonical directory:
`<repository-root>/.artifacts/tests/s42-stop-diagnosis/2026-10-22T04-32-25-869Z/`.

| Artifact | SHA-256 |
| --- | --- |
| report.json | e651b99b1db5aad27c2f7c75b6d8f1d5b34b6a57335a68be73a92b28ff6f2e1f |
| lease-candidates.json | f3073f7f594e4038f9ee1c2e214883570a53baae510ef8d5b9f26f8e4ca366fc |

Task-owned observe-stop-result-once.mjs syntax check PASS; this is not a product
test. No Unity, MCP, process-control or runtime repair was executed. The original
Stop receipt remains intact. No lease was refreshed, removed or manufactured.
No new assertion about coordinator process absence or current manual mode is made.

## Narrow next direction

Keep the exact exported Package undelivered and Unity open while aligning the
next step. Prefer an isolated offline reproduction of the actual Supervisor
watch-manager launch with controlled inherited environment and distinct instance/
legacy lease roots. Capture spawn without starting a product service. Verify
whether selected context wins both when instance environment is absent and when
an unrelated inherited instance is present.

If confirmed, propose the smallest launch-boundary fix: derive explicit Unity
and instance environment from the already validated selected context for this
child invocation. Preserve session/lifecycle authentication and the original
Stop prerequisite. No hardcoded machine paths, fabricated leases, widened TTL,
guard bypass or broad heartbeat/ownership refactor. Freeze any source repair and
focused adjacent tests separately; do not rewrite the completed export.

Recovery remains blocked on established owned retirement. Do not replay Stop,
switch references, close Unity automatically, or route to an unbound PID stop
under this read-only diagnosis.

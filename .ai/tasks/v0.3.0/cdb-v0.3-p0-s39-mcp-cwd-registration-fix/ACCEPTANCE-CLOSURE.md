# S39 cwd registration fix: bounded fresh-project acceptance closure

Date: 2026-10-21. Status: FRESH_PROJECT_CWD_FIX_ACCEPTED /
NO_FURTHER_CALLS_REQUIRED_FOR_THIS_GATE.

## Accepted behavior and evidence

Source commit: `c848049d90fbdf618905be25225580642d98d987`.
Delivered Package: 0.3.0-preview.5, generation poc.44. Exact ZIP SHA-256:
`3d266307ba7e052140575ada0c39d689e5a62d28a9aa3d686420f15e76a98a5d`.
The fix derives absolute MCP cwd from the verified Unity root, preserving
relative wrapper/root args and the existing startup timeout. No machine root
is hardcoded in source, and the consumer config was not hand-edited to pass.

Completed gates:

- Source/isolated checks and exact Package closure: RESULT.md and
  DELIVERY-RESULT.md retain the exact passed checks and declared limitations.
- Fresh CodedbTest_2 first install: human no-compile-error and Manager Ready
  reports, plus static config/selection/activation bindings, recorded in
  CODEDBTEST2-READY-RESULT.md.
- Real new-client startup/status: six exact target tools exposed; one successful
  status with matching version/generation/manifest. User-transferred raw response
  and evidence provenance: CODEDBTEST2-CLIENT-STARTUP-RESULT.md.
- Actual C# retrieval: one Provider hit at the agreed sample path/line 5, matching
  marker content, from one text-search call. User-transferred raw response:
  CODEDBTEST2-HIT-QUERY-RESULT.md.

Total agreed target-client calls across the two phases: status=1,
text-search=1, other CodeDB=0. The query phase added no status call and no retry.
The development chat never substituted another namespace or a shell query.

This closes the agreed normal fresh-project install -> generated registration
-> new Codex-client tools/status -> one real C# hit flow for this delivered
candidate. It supports the cwd fix under the observed environment. It does not
retroactively establish the failed historical child's exact effective cwd or
guarantee all client/environment configurations.

## Explicit remaining boundaries

- Complete response/chat/lease identity: response fields do not independently
  expose project_identity, instance_id and activation_epoch. Local binding is
  recorded separately; complete session attribution remains unestablished.
  This limitation is not a new blocker on the agreed functional gate.
- Existing CodedbTest_1 previous-generation migration and ownership/removal
  admission remain deferred. Its environment was not proved file-corrupt.
- Ready/Unconfirmed transition investigation remains deferred.
- Shader/HLSL hit queries, comprehensive regression, old-version upgrade,
  performance and public release acceptance are not passed by this sample.

Stop the current gate: no repeat status/query, broadened audit, protocol change
or new Unity project is needed to close this bounded task. Further work needs
its own selected objective; do not auto-start deferred items.

## Locations and retained evidence

Primary task records live in this primary-root `.ai/tasks/` directory; test and
delivery evidence live in primary-root `.artifacts/tests/s39-cwd-fix/`, and the
original ZIP in `.artifacts/exports/s39-cwd-c848049/`. Repository-local checkout:
`.worktrees/cdb-v0.3-p0-s39-mcp-cwd-registration-fix/`.
RELOCATION-RESULT.md records the completed location correction and cleanup.

Keep the accepted test sample, original ZIP, failed predecessor evidence and
remaining recovery backups. No source merge/push/new commit, further package
delivery or consumer modification is implied by this closure record.

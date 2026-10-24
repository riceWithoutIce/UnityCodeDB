# Task: S39 project MCP working directory registration

## Current location authority — 2026-10-21

Repository-local source checkout: `.worktrees/cdb-v0.3-p0-s39-mcp-cwd-registration-fix/`.
This primary-root task directory owns ongoing handoffs; durable evidence lives
in primary-root `.artifacts/tests/s39-cwd-fix/` and the exact ZIP in
`.artifacts/exports/s39-cwd-c848049/`. See RELOCATION-RESULT.md for verified
migration, duplicate cleanup and the retained app snapshot. The source/isolated
validation and delivery sections below describe their original completed gates;
Startup/status and the single C# hit query subsequently passed per the
user-transferred target-client reports. See ACCEPTANCE-CLOSURE.md for the
completed fresh-project functional gate and explicit deferred boundaries;
complete session attribution remains unestablished. No further call is needed.

Primary source integration subsequently completed under the user's separate
72-path approval. See SOURCE-INTEGRATION-RESULT.md for preserved local changes,
actual static checks and the combined-tree acceptance boundary. HEAD and index
remain unchanged; no new commit, export or consumer acceptance was performed.

The subsequent CANDIDATE-EVIDENCE-MATRIX.md traces the two retained implementation
deltas to earlier unaccepted lifetime WIP explicitly excluded by S32 delivery.
It recommends retaining the exact c848049 preview baseline, with release scope
and evidence decisions still open. This is planning, not acceptance of that WIP.

The user subsequently agreed to basic-use-flow preview stabilization and
confirmed only the basic flow has been completed. V0.3-PREVIEW-SCOPE-DRAFT.md
records that aligned scope; LIFECYCLE-GAP-PLAN.md records the proposed
current-candidate lifecycle supplement. Real lifecycle actions remain unrun
under this new proposal and are not authorized by scope alignment alone.

The subsequent user request to prepare acceptance was executed as read-only
CodedbTest_2 binding checks. LIFECYCLE-ACCEPTANCE-CHECKLIST.md records the
prepared baseline, automatic maintenance snapshot and first human handoff.
No new lifecycle stage has run; current human Unity/Manager starting state
must be confirmed before the first ordinary reopen smoke.

The human start state and normal Unity close/reopen were subsequently confirmed.
LIFECYCLE-REOPEN-RESULT.md records installed-state reopen smoke PASS with matching
bindings and independent core_ready file evidence. A one-action logical
Uninstall proposal and pre-action index baseline are prepared; no Uninstall or
reinstall has occurred in this supplement.

The user then approved and performed the one logical Uninstall. The original
action and operation, exit 0 and logical postconditions pass per
LIFECYCLE-UNINSTALL-RESULT.md; physical cleanup remains pending. Same-version
Install is prepared as the next separately confirmed stage, not executed.

The user then approved and attempted one same-version Install. It failed with
exit 6 at PREFLIGHT, retained-instance execution live or unknown. The lifecycle
supplement is stopped/incomplete; post-reinstall reopen is NOT RUN. See
LIFECYCLE-REINSTALL-BLOCKED-RESULT.md for the original terminal, unchanged logical
Uninstalled state and bounded matching MCP lease/Node process observation.
No retry, process stop, lease deletion or repair is authorized by this failure.

## Metadata
- Product: UnityCodeDB; Version: v0.3
- Workflow: codedb-workflow-v2; revision: 2.6
- Status: COMPLETE (source, exact delivery and bounded fresh-project functional
  acceptance; deferred boundaries in ACCEPTANCE-CLOSURE.md); Review mode: NORMAL
- Planner/Coder: current development session; Verifier: not requested
- Execution mode: DURABLE_SESSION; delegation: NOT_AUTHORIZED
- Requirement source: user approved dynamic project-derived cwd and explicitly
  required proportionate validation, without hardcoded machine paths.

## Objective and scope
- Generate a machine-local absolute cwd from the verified Unity project root.
- Use the same values for creation and repair; validate actual cwd/root equality
  rather than one literal representation. Update the draft and targeted tests.
- Preserve unrelated config, existing publication/backup/drift guards, original
  command/args/stdio/timeout and user-owned Unity/Codex startup.
- Base: 237c72d9980114b99887fb8e805658447dd8d4fd, isolated managed worktree.
- Protected: original checkout dirty state; external projects and Package;
  historical generations through poc.43 (exact Git bytes retained); global config.
- Allowlist: materializer registration functions; one pure registration helper;
  successor generation scripts/draft/metadata; necessary payload/host/status
  cross-hashes; focused tests; integration contract; this task's records.
- No full TOML parser, unrelated config audit, new background repair/reload,
  new dependency, runtime/query change, Unconfirmed work or historical cleanup.

## Execution envelope
- User grant: IMPLEMENT and focused source validation following agreed scope.
- Delivery authorization: GRANTED on 2026-10-21 after the prepared delivery
  plan was presented; user response: "同意 批准". Exact commit (no push),
  export verification and CodedbTest_1 Package-reference switch only.
- L0: test-codedb-mcp-cwd.ps1, production registration generator/planner and cwd
  contract under owned temporary roots; both supported PowerShell hosts.
- Affected L1: focused harness -Mode Flow, using the actual config publisher and
  successor validator/draft; package closure/admission
  for new generation and cross-hashes, not release acceptance.
- Test refinement before execution: the older aggregate -McpConfigOnly fixture
  hardcodes 46 total managed entries while the delivered manifest already has
  60. It is not expanded/repaired here. The new bounded Flow scenario exercises
  the same production planner/publisher and the immediate cwd consumers, without
  assembling unrelated Provider/watch lifecycle fixtures.
- Explicitly not run: full materializer suite, Unity/EditMode, real MCP/Provider,
  external Install/Reinstall, performance, upgrade and release acceptance.
- Rationale: changes affect serialized registration and its immediate consumers;
  owned fixtures replace machine dependencies, never real consumer state.
- Child processes: existing focused fixture roles only, no real server startup.
- Corrected semantic attempts per local scenario: 2; unchanged reruns forbidden.
- Unity complexity: Low; Editor requirement NONE; EditMode NOT_REQUESTED.
- Evidence class: CONTRACT_ISOLATED; native/static closure checks separate.
- Stop on external dependency/root/ownership conflict; preserve evidence.

## Definition of done
- New/old/stale-root registrations compute correct cwd and are idempotent;
  formatting-equivalent current paths accepted; wrong/missing cwd rejected.
- Spaces/Unicode and TOML escaping covered; unrelated config retained.
- One new generation; immutable predecessor bytes unchanged; static closure
  and declared focused checks pass or exact limitation recorded.
- Stable source diff/result returned; delivery and real-client acceptance remain
  separate user-owned gates. No new operational attempt authorized.

## Handoff
- Source/result: RESULT.md; raw source hashes in the local evidence manifest.
- New successor: poc.44; prior generations preserved as exact Git bytes.
- Source-phase delivery authorization was NONE; no commit, export, external
  project modification, Unity launch or real CodeDB/MCP call occurred then.
- Subsequent bounded delivery grant: DELIVERY-PLAN.md. Execution outcomes must
  be recorded separately; authorization alone is not evidence of delivery.
- The source validation gate is complete; delivery and real-client identity/query
  acceptance require their separately agreed human-owned sequence.

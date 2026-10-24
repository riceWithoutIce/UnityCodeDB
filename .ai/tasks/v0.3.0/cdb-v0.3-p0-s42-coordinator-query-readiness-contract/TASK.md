# Task: cdb-v0.3-p0-s42-coordinator-query-readiness-contract

## Metadata
- Product: UnityCodeDB; Version: v0.3; Workflow: codedb-workflow-v2 revision 2.7.
- Status: COMPLETE (isolated source contract only); Planner/Coder: current development session; Verifier: none.
- Review mode: NORMAL; Execution mode: DURABLE_SESSION; profile: current session.
- Delegation authorization: NOT_AUTHORIZED; Session policy: REUSE_ONLY.
- Requirement source: v0.3 roadmap runtime lifecycle and query availability; approved REPAIR-PLAN in sibling identity-handoff-heartbeat-followup task.

## Objective and scope
Make Supervisor startup, compatible reuse and operational Ready satisfy the existing complete watch/query service contract. No Supervisor refactor or heartbeat/child-handoff repair.

Change allowlist:
- com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs
- com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs
- this task's records (canonical records in primary workspace).

Read closure: direct references in poc.44 coordinator, watch manager, instance worker, common adapter contract; Package materializer and Editor Supervisor/operational-observation consumers. These are read-only.

Implementation base: accepted delivery 186aacf0371ba64e47114306170b449dbca261c9.
Isolation: <repository-root>/.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract; branch codex/coordinator-query-readiness.
Protected: primary dirty work including writer-lifetime WIP, immutable generations/manifests, all consumer projects/runtime and previous attempt evidence.

## Execution envelope
- Mode: CONTINUOUS_WITHIN_SCOPE. User's latest continue after agreed minimal repair authorizes implementation, local corrections, focused testing and consolidation.
- Delivery authorization: NONE. No commit/export/consumer switch or live recovery.
- L0: Node syntax checks and scoped diff/allowlist check.
- Affected L1: new isolated query-readiness scenario, plus directly coupled S32 disposition fixture. Capture actual production launch with VM seams; exercise original immutable worker readiness predicate with controlled process probes. No real child, server, Provider, Unity or MCP starts.
- Scenarios: complete derived startup and missing-watch-config refusal; compatible watching/pending/building reuse; incompatible config/adapter/generation/exclusive-owner refusal without second owner or stop; Ready implication to worker predicate; original attribution and timeout classifications, unknown/live child refusal.
- Test rationale: producer/service-shape mismatch has a deterministic isolated contract boundary. Evidence does not establish live convergence or freshness SLA.
- Artifact root: isolated checkout .artifacts/tests/s42-readiness/<unique-run>; adjacent fixture uses its existing owned .artifacts/tests/s32-install/<unique-run>.
- Not run: broad harness/regression, EditMode, live collection, Unity, MCP, performance/release validation.
- EditMode authorization: NOT_REQUESTED; mechanical corrections 2/scenario; semantic attempts 2/scenario; independent product causes 2; active budget STANDARD_30M; output V2_DEFAULT.
- Broad search/full diff/full regression: FORBIDDEN. Side effects: only declared source/docs and owned isolated fixture files; Node test runners only.
- Stop/escalation: required immutable/schema changes, new automatic stop/recovery/ownership authority, protected state mutation, or structural budget reached. No model escalation.
- Structural guard: starting repairs 0/2, independent product causes 1/2, consecutive diagnostic-only checkpoints 0/3.

## Definition of done
Coherent startup/reuse/readiness fix and focused checks pass; exact changed-source hashes and limitations recorded. Existing safe recovery entry is described without execution. Heartbeat continuity, Unconfirmed and short-lived child admission stay deferred.

## Handoff
Current task: S42 coordinator-query-readiness-contract.
Current status: SOURCE_CONTRACT_PASS / NOT_DELIVERED.
Next notification: user.
Next action: review RESULT and align exact delivery plus owned recovery/real-client acceptance.
Human authorization required: later exact delivery, consumer recovery and real-client acceptance only.

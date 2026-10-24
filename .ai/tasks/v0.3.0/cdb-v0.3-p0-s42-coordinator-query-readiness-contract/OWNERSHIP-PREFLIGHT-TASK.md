# S42 single read-only ownership preflight

Status: COMPLETE (owners established; active-operation retirement gate not met).
Workflow: codedb-workflow-v2 revision 2.7; NORMAL, no delegation.
User grant: agreed to proposed one read-only preflight and confirmed Unity open.
Manager state at this attempt: not supplied; do not infer from historical Ready.

Objective: determine whether the current CodedbTest_2 Supervisor/coordinator have
attributable live owners and whether their existing operation state permits a
later separately authorized bounded retirement. No mutation or recovery now.

Allowlist: this task's preflight script/records and fresh repository-local
`.artifacts/tests/s42-ownership/<unique-run>/` safe projections only.
Consumer reads: target Packages manifest/lock, installed Package metadata and
Supervisor source; selected pointer/instance, lifecycle desired/manual state,
Supervisor state/lock/current operation, coordinator state; final pointer.
Read closure: existing installed Supervisor read-only validation, process-evidence
and authenticated status request functions, including their normal bounded
Package payload/control contract, selected-generation manifest/declared-file and
stable-wrapper reads. Accepted Supervisor source bytes are compared with the
S40 Git blob before the VM is loaded. No executable import/entry point.

Execution: one script invocation. No retries, polling or loops waiting for state.
Use original read-only functions in a VM with filesystem writes disabled and
only status IPC permitted. One Supervisor status through original owner inspection,
at most one coordinator status, one additional coordinator process identity probe.
Supervisor process probe belongs to original inspection. No Provider/worker/Unity
process scan, CodeDB tools or query. Tokens/pipe/argv remain in memory; safe
identity/status projections and comparison booleans only are written.

Stop affected branch on binding/source disagreement, malformed record, unavailable
authentication or ownership conflict; preserve one terminal report. Final pointer
comparison is permitted to delimit the single capture, not a retry. Ordinary
status may update existing server observation counters; no maintenance command
or lease heartbeat is requested. Do not claim globally zero server-side writes.

Protected: all consumer configuration/source/runtime, old evidence, primary dirty
source, immutable generations; no launch/stop/ensure/reconnect/export/commit/switch.
Budgets: STANDARD_30M; mechanical correction 2, semantic attempt 1; no broad search.
Required evidence: script syntax plus actual one bounded preflight report, exact
call counts, pointer stability, safe source hashes and limits. Not runtime/Unity
acceptance or permission to send stop. No new independent review.

Handoff: COMPLETE; see OWNERSHIP-PREFLIGHT-RESULT.md. No further live grant active.

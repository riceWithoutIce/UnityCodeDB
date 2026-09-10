# S13 FIX 02: Corrected Cold Start Attribution

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Status: `READY_AWAITING_DISPATCH`
- Owner profile: `v0.3.coder.deep`
- Phase: Runtime Release Gate; one evidence-only corrected Cold Start snapshot
- Human gate: the user opened the existing `UnityValidationProject/` and
  confirmed that Unity compilation completed without compiler errors
- Verifier routing: prohibited in this checkpoint

## Frozen Input Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- Committed HEAD: `9aada838e26879810a4f79760273ca66340ebf12`

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/FIX-02.md` | `8680` | `cc5f36810a6662e9727ea14d2d22e1a0711bd858ff7effc7fab63c8fbdf39ba7` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/RESULT.md` | `37224` | `e1c7e7eeda11a5bc7800e1a2edb3c70e5890127a98a86f5cca2891bdf61ef101` |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `151262` | `e712874560af3a8e3ad0034d4e93cfb51ea9eb8b42ac1d4d638f3aa780763264` |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | `27323` | `dbe38367a1e14cf0ab85d01e846028465437234de4f7de9cba4ef629cd784250` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `197530` | `a20561347e1fa13127564f5d154250b86bd5f90dd753c97d2c2a2199ae0ef163` |

Identity drift is a hard stop. Do not repair, reset, or substitute a different
snapshot. `RESULT.md` may grow only through the append authorized below.

## Objective

Capture one immediate passive snapshot from the already-open, already-compiled
validation project and determine the exact FIX 02 prerequisite classification.
Do not wait for another lifecycle pass and do not cause one.

First bind the observation passively to exactly one Unity process for the
current validation project. Record only match count, PID, and Unity version;
never record its command line or absolute project path.

Then locate the latest complete sanitized lifecycle evidence record and record
only this allowlist:

- checkpoint name;
- `reconcile_started_count` and `reconcile_completed_count`;
- `last_product_state`;
- `prerequisite_evidence_disposition`;
- `coordinator_admission_disposition`;
- Supervisor PID and Coordinator PID;
- materializer-command and direct-fallback counts;
- main-thread violation count.

Do not copy the raw evidence line or any non-allowlisted JSON field into command
output or `RESULT.md`.

## Evidence Read Contract

- Read at most the final `16,384` bytes of the current Unity Editor log using a
  direct file-stream seek. Do not use a line-count tail, whole-file read,
  search command, or historical log enumeration.
- Discard the first partial line after decoding the bounded byte window. Parse
  only complete lines and select the last valid sanitized lifecycle evidence
  record.
- Captured terminal output, including metadata and errors, must remain below
  `8 KiB`.
- Refer to the source only as `Unity Editor log` in durable records. Do not
  persist a drive, user profile, absolute path, command line, or machine name.
- If the marker is absent, truncated, malformed, or cannot be bound to the
  current project, report `INSUFFICIENT_EVIDENCE` and stop. Do not enlarge the
  byte window.

## Decision Table

- One of `ResultAbsent`, `CommandTimedOut`, `CommandEnvelopeInvalid`,
  `MarkerCardinalityInvalid`, `MarkerMalformed`, or
  `MarkerProductStatusMismatch`: report `ATTRIBUTED_FAIL_CLOSED` with the exact
  sanitized code.
- `TrustworthyCurrent`: report the downstream
  `coordinator_admission_disposition` and whether Supervisor/Coordinator
  admission was established; do not diagnose or repair a downstream failure.
- `TrustworthyMissing`: report `ATTRIBUTED_MISSING`; do not run Reinstall or a
  materializer.
- Empty, `Unknown`, an unrecognized value, or no current record: report
  `INSUFFICIENT_EVIDENCE`.

The prior `CancellationTokenSource.Dispose` diagnostic is out of scope and
must remain `DIAGNOSTIC_ATTRIBUTION_UNAVAILABLE` even if it is visible in the
bounded bytes.

## Execution Boundaries

- One passive evidence command, one invocation, maximum 30 seconds, no retry.
- Only the parent `RESULT.md` may be appended. Production, tests, task cards,
  Unity project files, and runtime state are strictly read-only.
- Do not operate Unity UI, Manager, Play Mode, Domain Reload, Unity Hub, Unity
  MCP, BatchMode, or any process. Do not start, stop, signal, or wait on a
  process.
- Do not run tests, compilation, source checks, `git diff`, Git status, or
  repository searches.
- Do not read or enumerate `UnityValidationProject/.codex/` or
  `UnityValidationProject/AIWork/`.
- Do not commit, push, contact Coder again, contact Verifier, or dispatch any
  next role.

## Completion And Handoff

Append one `S13 FIX 02 - Corrected Cold Start attribution` section to
`RESULT.md` with:

- frozen identity result;
- exact bytes read and captured-output bytes;
- only the allowlisted sanitized fields;
- one outcome from the decision table;
- explicit no-wait/no-retry and `NOT RUN` boundaries.

Stop and notify Planner. The next step is a Planner/User decision based on the
exact code: bounded production repair, another explicitly justified evidence
step, Verifier routing only after a passing stable snapshot, or stop/defer.

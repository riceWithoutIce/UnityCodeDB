# S13 FIX 03: Post-Admission Downstream Attribution

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Previous evidence: `FIX-03-COLD-START-REVERSE-SCAN.md`
- Status: `READY_AWAITING_DISPATCH`
- Owner: `v0.3.coder.deep`
- Human gate: the existing `UnityValidationProject/` remains open after its
  user-confirmed successful compile
- Scope: one passive evidence command; no repair and no Verifier routing

## Frozen Identity

- HEAD: `9aada838e26879810a4f79760273ca66340ebf12`
- `FIX-03-COLD-START-REVERSE-SCAN.md`: `4128 / 448bd820d4381d9f728667e74852e940f0428d9742fdfdb1428d3cb077ed4613`
- parent `RESULT.md`: `49189 / f6ac77a8191fb43d01efc27f8cd70e99d5176a3354c24b695f48a08e8eaf7119`
- `codedb-instance-engine.ps1`: `249426 / d0ae1df93e9be3d9c1538b783356dce4ac4ea1272f5c5964ef2cc8a71e11d9b4`
- `AICodedbEditorLifecycle.cs`: `151262 / e712874560af3a8e3ad0034d4e93cfb51ea9eb8b42ac1d4d638f3aa780763264`
- `AICodedbLifecycleEvidence.cs`: `27323 / dbe38367a1e14cf0ab85d01e846028465437234de4f7de9cba4ef629cd784250`

Identity drift is a hard stop. Only the parent `RESULT.md` may grow through the
authorized append.

## Established Input

The prior bounded snapshot established:

- prerequisite disposition `TrustworthyCurrent`;
- coordinator admission disposition `EditorLeasePublished`;
- positive Supervisor and Coordinator PIDs;
- zero main-thread violations;
- product state `NeedsAttention`.

Do not re-review FIX 03 or reinterpret these gates. This checkpoint only
classifies the lifecycle warning immediately associated with the latest
complete `reconcile_completed` evidence record.

## Evidence Contract

Run one immediate passive command. Confirm exactly one Unity process matches
the current validation project, but output only match count, PID, and Unity
version. Binding strength remains
`single-current-opening/latest-record`; the evidence schema does not provide
record-level Editor PID authentication.

Read at most the final `65536` bytes of the current Unity Editor log using one
direct file-stream seek/read. Discard the first partial decoded line. Locate
the last complete valid sanitized lifecycle evidence record with checkpoint
`reconcile_completed`, then inspect at most the next `24` complete lines or up
to the next lifecycle evidence record, whichever comes first.

Do not emit raw log lines, raw JSON, stack traces, arbitrary detail text, paths,
commands, tokens, or non-allowlisted fields. Output only:

- bytes read and captured-output bytes;
- process binding metadata allowed above;
- checkpoint, reconcile counts, product state, prerequisite disposition,
  coordinator admission disposition, Supervisor PID, Coordinator PID, and
  main-thread violation count;
- number of adjacent lines inspected;
- exactly one warning category below;
- exactly one optional detail category below.

Warning categories are matched only by these known lifecycle message prefixes:

- `AvailabilityEnsureFailed`: `CodeDB could not restore current-instance availability:`
- `AvailabilityProbeNotReady`: `CodeDB could not restore current-instance availability without replacing the instance:`
- `AutomaticInstanceConvergenceFailed`: `CodeDB automatic instance convergence failed:`
- `AutomaticRetirementConvergenceFailed`: `CodeDB automatic retired-instance convergence failed:`
- `CurrentInstanceInvalid`: `CodeDB current instance identity is invalid:`
- `SelectedInstanceUnsupported`: `CodeDB selected-instance state is unsupported by the v0.3 Supervisor route.`
- `IntegrationInvalid`: `CodeDB project integration desired state is invalid:`
- `LeaseAdmissionBlocked`: `CodeDB could not establish the current Editor lease before coordinator admission.`
- `NoAdjacentLifecycleWarning`: no known or other CodeDB lifecycle warning is
  present in the bounded adjacent lines
- `OtherLifecycleWarning`: a CodeDB lifecycle warning is present but no known
  prefix matches; do not persist its text

Optional detail categories may be recorded only on exact, case-insensitive
containment of these fixed phrases:

- `SelectedInstanceCoordinatorNotOperational`: `Selected instance coordinator is not operational.`
- `AvailabilityProbeDidNotReachReady`: `Current instance availability probe did not reach Ready`
- `NoAllowlistedDetail`: neither phrase is present

Terminal output must not exceed `4096` UTF-8 bytes. Durable records must refer
to the source only as `Unity Editor log`.

## Outcome

- `ATTRIBUTED`: one known warning category matched; report its optional detail
  category and stop.
- `NO_ADJACENT_WARNING`: category is `NoAdjacentLifecycleWarning`; the current
  evidence does not expose the downstream branch.
- `UNCLASSIFIED_WARNING`: category is `OtherLifecycleWarning`; do not expose
  raw content.
- `INSUFFICIENT_EVIDENCE`: singular project binding or a complete latest
  reconcile record cannot be established within the bounded read.

Do not investigate or repair any outcome. The prior
`CancellationTokenSource.Dispose` message remains out of scope.

## Hard Boundaries

- One evidence command, maximum 30 seconds, retry `0/0`.
- Do not wait, poll, sleep, cause another reconcile, or enlarge the read.
- Append only one `S13 FIX 03 - Post-admission downstream attribution` section
  to the parent `RESULT.md`; no other write.
- Do not operate Unity UI, Manager, Play Mode, Domain Reload, Unity Hub, Unity
  MCP, BatchMode, or any process.
- Do not run tests, compilation, source reads, diff, Git status, or repository
  search.
- Do not read runtime state, `UnityValidationProject/.codex/`, or
  `UnityValidationProject/AIWork/`.
- Do not commit, push, contact Verifier, or dispatch another role.

## Handoff

Append frozen identity, binding strength, bounded allowlisted evidence, the
warning/detail categories, one outcome, and explicit `NOT RUN` boundaries to
`RESULT.md`. Notify Planner and stop. Planner/User decides whether a bounded
production repair, sanitized instrumentation, Verifier routing, or defer is
appropriate.

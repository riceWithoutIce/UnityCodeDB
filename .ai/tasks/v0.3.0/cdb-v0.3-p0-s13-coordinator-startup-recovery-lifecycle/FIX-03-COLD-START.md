# S13 FIX 03: Corrected Cold Start Evidence

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Status: `READY_AWAITING_DISPATCH`
- Owner: `v0.3.coder.deep`
- Human gate: the existing `UnityValidationProject/` is open and the user
  confirmed compilation completed without compiler errors
- Scope: one immediate passive evidence snapshot; no Verifier routing

## Frozen Identity

- HEAD: `9aada838e26879810a4f79760273ca66340ebf12`
- `FIX-03-ATTEMPT-03.md`: `2970 / 9c8fbb38af0f0dc8961e2440650a359aaa5c58bd16e4451959169cfb7fe110ed`
- parent `RESULT.md`: `45941 / e64c98e8c222872f3f34b8bae8eeb3a36fa79c46a006694989a8e9d1ea3ad85d`
- `codedb-instance-engine.ps1`: `249426 / d0ae1df93e9be3d9c1538b783356dce4ac4ea1272f5c5964ef2cc8a71e11d9b4`
- `test-codedb-host-payload-materializer.ps1`: `734522 / a405c4750eb8ba82a8e5fa719fe8120d9241ffcd7ada82ae1360960b3a2b53df`
- `AICodedbEditorLifecycle.cs`: `151262 / e712874560af3a8e3ad0034d4e93cfb51ea9eb8b42ac1d4d638f3aa780763264`
- `AICodedbLifecycleEvidence.cs`: `27323 / dbe38367a1e14cf0ab85d01e846028465437234de4f7de9cba4ef629cd784250`

Identity drift is a hard stop. Only `RESULT.md` may grow through the authorized
append.

## Evidence Contract

Run one immediate passive command. Bind it to exactly one Unity process for the
current validation project, but persist only match count, PID, and Unity
version. Do not output or persist command lines or absolute paths.

Read at most the final `16384` bytes of the current Unity Editor log by direct
file-stream seek. Discard the first partial decoded line, parse only complete
sanitized lifecycle evidence records, and select the latest valid record. Do
not use a line-count tail, whole-file read, search, historical log enumeration,
waiting, or retry. Captured terminal output must remain below `8 KiB`.

Persist only:

- bytes read and captured-output bytes;
- checkpoint;
- reconcile started/completed counts;
- last product state;
- prerequisite evidence disposition;
- coordinator admission disposition;
- Supervisor and Coordinator PIDs;
- materializer-command and direct-fallback counts;
- main-thread violation count.

Never persist the raw evidence line, non-allowlisted JSON, a drive, user
profile, project absolute path, machine name, token, stdout, or stderr.

## Outcome

- `COLD_START_PASS`: prerequisite is `TrustworthyCurrent`, product state is
  `Ready`, Supervisor and Coordinator PIDs are positive, admission is no longer
  prerequisite-blocked, and main-thread violations remain zero.
- `DOWNSTREAM_BLOCKED`: prerequisite is `TrustworthyCurrent`, but a later
  sanitized state/disposition or missing owner prevents the full pass. Record
  it without investigation or repair.
- `PREREQUISITE_BLOCKED`: prerequisite remains any untrustworthy or missing
  category. Record the exact sanitized code without repair.
- `INSUFFICIENT_EVIDENCE`: no current complete record, unrecognized/empty code,
  failed project binding, or truncated/malformed evidence. Do not enlarge the
  read window.

The prior `CancellationTokenSource.Dispose` diagnostic remains out of scope and
non-actionable.

## Hard Boundaries

- One command, maximum 30 seconds, retry `0/0`.
- Only append one `S13 FIX 03 - Corrected Cold Start evidence` section to the
  parent `RESULT.md`; no other write.
- Do not operate Unity UI, Manager, Play Mode, Domain Reload, Unity Hub, Unity
  MCP, BatchMode, or any process. Do not wait for or cause another reconcile.
- Do not run tests, compilation, source reads, diff, Git status, or repository
  search.
- Do not read runtime state, `UnityValidationProject/.codex/`, or
  `UnityValidationProject/AIWork/`.
- Do not commit, push, contact Verifier, or dispatch another role.

## Handoff

Append frozen identity, bounded evidence, one outcome above, and explicit
`NOT RUN` boundaries to `RESULT.md`, then notify Planner and stop. Planner/User
decides whether the stable snapshot can route to Verifier or needs one bounded
downstream repair.

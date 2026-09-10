# S13 FIX 03: Bounded Cold Start Reverse Scan

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Previous evidence: `FIX-03-COLD-START.md`, immutable
  `INSUFFICIENT_EVIDENCE`
- Status: `READY_AWAITING_DISPATCH`
- Owner: `v0.3.coder.deep`
- Human gate: the existing `UnityValidationProject/` remains open after a
  user-confirmed successful compile
- Scope: one passive evidence command; no Verifier routing

## Frozen Identity

- HEAD: `9aada838e26879810a4f79760273ca66340ebf12`
- `FIX-03-COLD-START.md`: `3991 / ba0063dd422fa9bd178ebeeae5112b786c9b0badc32f288f4c367237c4d4d608`
- parent `RESULT.md`: `47370 / 08d0729bf8e26226574e11ce4c4071549b524e77eda70336c904758c7d0a79eb`
- `codedb-instance-engine.ps1`: `249426 / d0ae1df93e9be3d9c1538b783356dce4ac4ea1272f5c5964ef2cc8a71e11d9b4`
- `AICodedbEditorLifecycle.cs`: `151262 / e712874560af3a8e3ad0034d4e93cfb51ea9eb8b42ac1d4d638f3aa780763264`
- `AICodedbLifecycleEvidence.cs`: `27323 / dbe38367a1e14cf0ab85d01e846028465437234de4f7de9cba4ef629cd784250`

Identity drift is a hard stop. Only the parent `RESULT.md` may grow through the
authorized append.

## Evidence Contract

Run one immediate command. Passively confirm exactly one Unity process matches
the current validation project. Persist only match count, PID, and Unity
version; never emit or persist its command line or an absolute path.

Using one direct file-stream seek/read, inspect at most the final `524288`
bytes of the current Unity Editor log. Discard the first partial decoded line,
parse only complete sanitized lifecycle evidence records, and choose the last
valid record. Do not emit raw log text, raw JSON, candidate records, or
non-allowlisted fields.

The evidence schema has no Editor PID or process-start field. Therefore report
the binding accurately as `single-current-opening/latest-record`, not as
record-level PID authentication. If exactly one current project process cannot
be confirmed, stop as `INSUFFICIENT_EVIDENCE`.

Persist only:

- actual log bytes read and captured-output bytes;
- target match count, PID, and Unity version;
- checkpoint;
- reconcile started/completed counts;
- last product state;
- prerequisite evidence disposition;
- coordinator admission disposition;
- Supervisor and Coordinator PIDs;
- materializer-command and direct-fallback counts;
- main-thread violation count.

Terminal output must remain at or below `4096` UTF-8 bytes. Durable records
must use only repository-relative paths and the label `Unity Editor log`.

## Outcome

- `COLD_START_PASS`: `TrustworthyCurrent`, product `Ready`, positive
  Supervisor and Coordinator PIDs, admission no longer prerequisite-blocked,
  and zero main-thread violations.
- `DOWNSTREAM_BLOCKED`: `TrustworthyCurrent`, but a later sanitized
  disposition/state or absent owner prevents the pass.
- `PREREQUISITE_BLOCKED`: prerequisite remains missing or untrustworthy.
- `INSUFFICIENT_EVIDENCE`: no complete valid record exists within the bounded
  window, project binding is not singular, or the disposition is empty,
  unknown, or malformed.

Do not investigate or repair any outcome. The prior
`CancellationTokenSource.Dispose` diagnostic remains out of scope.

## Hard Boundaries

- One evidence command, maximum 30 seconds, retry `0/0`.
- Do not wait, poll, sleep, cause another reconcile, or enlarge the scan.
- Append only one `S13 FIX 03 - Bounded Cold Start reverse scan` section to
  `RESULT.md`; no other write.
- Do not operate Unity UI, Manager, Play Mode, Domain Reload, Unity Hub, Unity
  MCP, BatchMode, or any process.
- Do not run tests, compilation, source reads, diff, Git status, or repository
  search.
- Do not read runtime state, `UnityValidationProject/.codex/`, or
  `UnityValidationProject/AIWork/`.
- Do not commit, push, contact Verifier, or dispatch another role.

## Handoff

Append the identity result, accurate binding strength, bounded allowlisted
evidence, one outcome, and explicit `NOT RUN` boundaries to `RESULT.md`. Notify
Planner and stop. If no record is found within `524288` bytes, recommend
stopping/defer rather than another larger log scan.

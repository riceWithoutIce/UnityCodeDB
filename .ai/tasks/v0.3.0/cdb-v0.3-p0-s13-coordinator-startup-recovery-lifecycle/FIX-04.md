# S13 FIX 04: Post-Admission Route Instrumentation

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Status: `READY_AWAITING_DISPATCH`
- Owner profile: `v0.3.coder.deep`
- Review profile: `v0.3.verifier.deep`, only after a later stable passing
  lifecycle snapshot and explicit Planner routing
- Phase: Runtime Release Gate; final sanitized downstream attribution
- Validation gate: the user confirmed `UnityValidationProject/` is closed

## Frozen Input Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- Committed HEAD: `9aada838e26879810a4f79760273ca66340ebf12`

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/FIX-03-DOWNSTREAM-ATTRIBUTION.md` | `5990` | `82330382dff69827c3b5331eeae0a8644ed8cf9707cc3aa425e7b36cb83bdc1c` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/RESULT.md` | `50956` | `0747c43f9af28cef8ecb2bc36a76a130751ccaae8ec423b23001ab2251fa8489` |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `151262` | `e712874560af3a8e3ad0034d4e93cfb51ea9eb8b42ac1d4d638f3aa780763264` |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | `27323` | `dbe38367a1e14cf0ab85d01e846028465437234de4f7de9cba4ef629cd784250` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `197530` | `a20561347e1fa13127564f5d154250b86bd5f90dd753c97d2c2a2199ae0ef163` |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `249426` | `d0ae1df93e9be3d9c1538b783356dce4ac4ea1272f5c5964ef2cc8a71e11d9b4` |

Identity drift before work is a hard stop. Do not reset, repair, or substitute
another snapshot. `RESULT.md` may grow only through the append authorized here.

## Established Evidence

The corrected Cold Start has closed the prerequisite/bootstrap finding:

- prerequisite disposition is `TrustworthyCurrent`;
- coordinator admission disposition is `EditorLeasePublished`;
- Supervisor and Coordinator PIDs are positive;
- main-thread violations are zero.

The same latest reconcile remains `NeedsAttention`. A bounded read found no
adjacent lifecycle warning. Static flow therefore cannot distinguish a
migration return, an initial Probe product-layer combination, or a
current-instance convergence-plan branch. Further log scanning is prohibited.

## Objective

Add typed, sanitized lifecycle evidence for the already-computed
post-admission decision. Do not change any decision, return value, ordering,
retry, command invocation, or product state.

The persisted evidence must expose:

- `post_admission_disposition`;
- `post_admission_prerequisite_state`;
- `post_admission_installed_state`;
- `post_admission_configured_state`;
- `post_admission_mcp_available_state`;
- `current_instance_state`;
- `current_instance_convergence_plan`.

`post_admission_disposition` must be a new enum-like code covering, at minimum:

- migration blocked before normal post-admission reconciliation;
- backend reconcile not required;
- integration invalid;
- uninstall cleanup or already uninstalled;
- initial Supervisor Probe evaluated;
- Probe reported missing prerequisite;
- current instance invalid;
- retirement plan selected;
- deployment plan selected;
- availability-recovery plan selected;
- convergence blocked/no supported recovery plan;
- convergence complete/no additional action.

Names may follow established local style. Persisted route, layer, instance, and
plan values must originate from enums or fixed enum mappings and pass through
the existing `SanitizeCode` boundary. Never persist detail strings, paths,
command lines, stdout/stderr, errors, tokens, process identity, marker payloads,
or arbitrary text.

## Recording Semantics

- Record only values already computed by `RunReconcileWorker`; instrumentation
  must perform no filesystem, process, lock, IPC, PowerShell/Node, hash, index,
  or full-status work.
- Clear or overwrite stale route fields deterministically at the start of each
  admitted reconcile so a later evidence record cannot present a prior pass as
  current.
- Record Probe layer states immediately after the initial Supervisor Probe is
  parsed.
- Record current-instance state and convergence plan immediately after their
  existing read/classification.
- Before each post-admission return, the route disposition must identify the
  branch actually taken. A no-warning `NeedsAttention` return must not remain
  `Unknown`.
- Branches that occur before Probe/current-instance evaluation must retain an
  explicit `NotEvaluated`/empty-safe enum code rather than stale values.
- Existing prerequisite and coordinator admission evidence fields remain
  unchanged and independent.

## Required Regression Coverage

Add focused pure/source-level tests proving:

- evidence record/capture/restore accepts only sanitized enum codes for all
  seven new fields;
- a legacy evidence document with missing new fields restores safely;
- migration, no-reconcile, invalid/uninstalled, initial Probe, missing
  prerequisite, invalid current instance, Retire, Deploy,
  RecoverAvailability, Blocked, and completed/None paths map deterministically;
- a no-warning `NeedsAttention` + blocked convergence path records enough enum
  state to identify that branch;
- instrumentation does not alter the existing convergence-plan result,
  Supervisor admission Boolean, retry behavior, or product-state value;
- no raw detail, output, path separator, or machine-specific value can enter
  the new evidence fields.

Reuse existing convergence-plan tests where possible. Do not create an
integration harness or broaden into materializer, Supervisor, queue, Bridge,
activation, retirement, or `CancellationTokenSource` testing.

## Writable Surface

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- parent `RESULT.md`, append-only with FIX 04 evidence

The PowerShell producer and every other file are read-only. Any additional
write requires a new Planner/User decision.

## Read And Execution Budget

- Confirm passively that the validation project remains closed before editing;
  if a matching Unity process exists, stop without edits.
- Reuse prior S13 source evidence. Read only targeted symbols in the three
  writable files; no repository search, full-file read, full diff, or prior log
  read. One read batch, maximum 60 seconds and `32 KiB` captured output.
- One focused static/source test batch, maximum 60 seconds and `16 KiB`
  captured output. Do not claim C# compilation from textual checks.
- One final `git diff --check` scoped only to the three changed C# files.
- No retry is authorized. A command, output, or time-budget failure stops the
  task and is recorded honestly.
- C# L1, Unity EditMode, Cold Start, Unity UI, Unity MCP, BatchMode, Node L0,
  PowerShell L0, and all other tests are `NOT_AUTHORIZED / DEFERRED`.
- Do not start, close, or operate Unity, Unity Hub, Unity MCP, a validation
  process, or a business process.
- Do not commit, push, contact Verifier, or perform runtime evidence capture.

## Preserved Contracts

- FIX 03 single prerequisite marker authority and FIX 02 exact-one consumer
  remain unchanged.
- Prerequisite, migration, lease, Supervisor, current-instance, availability,
  retry, fallback, ownership, and main-thread behavior remain byte-for-byte
  semantic equivalents apart from evidence-only record calls.
- `Payload~/Generations/poc.34/` remains byte-identical and is not read.
- No new authority, process owner, retry, Reinstall, direct fallback, or
  materializer invocation is introduced.
- The prior `CancellationTokenSource.Dispose` diagnostic remains out of scope.

## Stop Conditions

Stop without a speculative repair when:

- the validation project is open or frozen identity drifted;
- a new field requires raw detail/output or a file outside the writable scope;
- instrumentation cannot identify the no-warning path without changing
  lifecycle behavior;
- a check fails independently or a budget is exhausted.

## Completion And Handoff

Append one `S13 FIX 04` section to `RESULT.md` containing:

- final enum contract and recording points;
- three-file pre/post bytes and SHA-256;
- static evidence, command exit/time/output, and scoped diff-check result;
- explicit `NOT RUN / DEFERRED` boundaries;
- one status: `INSTRUMENTED_READY_FOR_COLD_START`, `BLOCKED`, or `FAILED`.

If instrumented, stop and notify Planner. The next step is a separate human
decision to open the existing validation project once for one bounded Cold
Start evidence pass. Do not open Unity or route Verifier.

If blocked or failed, notify Planner with the exact decision required and stop.

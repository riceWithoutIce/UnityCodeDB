# S13 FIX 02: Prerequisite Evidence Attribution

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Status: `READY_AWAITING_DISPATCH`
- Owner profile: `v0.3.coder.deep`
- Review profile: `v0.3.verifier.deep`, only after a later passing visible
  lifecycle snapshot and explicit Planner routing
- Phase: Runtime Release Gate; diagnostic instrumentation before the next
  corrected Cold Start
- Dispatch gate: the user must confirm that `UnityValidationProject/` is
  closed before this card is dispatched

## Frozen Input Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- Committed HEAD: `9aada838e26879810a4f79760273ca66340ebf12`

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/TASK.md` | `12747` | `a69f5f5561ec238198de730ccfd3265f77eddd39f3459671d00c17fb55e13da6` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/FIX-01.md` | `9882` | `2dd08a4c29f9622064e9948469f045c2136177e7f88101ff7bdd9133edf35470` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/RESULT.md` | `32176` | `bcf96ac03c03b6ae93e1b81868ff0bcaa7485891098f98562b6564cbe3c1cb6f` |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `148433` | `a0781d74f5b5a89620842344fb7eb5169008a445d0336849dc60c0c457ccd767` |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | `26307` | `414e81b2504b4fd5650f98815dda4d6ad9febf2e8c137b4f12bce115c513189c` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `192325` | `38dcfaa4b19a44fa55cb534b11dd28667a84ec1477836d86eb95e60ec0c59504` |

Identity drift before work is a hard stop. Do not reset, repair, or substitute
another baseline. The append-only `RESULT.md` may grow only with the record for
this FIX after all other frozen inputs match.

## Confirmed Finding

FIX 01 reached the real lifecycle worker, but the corrected Cold Start still
did not reach Supervisor admission:

- `reconcile_started_count=10` and `reconcile_completed_count=10`;
- `last_product_state=NeedsAttention`;
- `coordinator_admission_disposition=PrerequisiteEvidenceUntrustworthy`;
- Supervisor PID, Coordinator PID, selected instance, and selected generation
  remained empty/zero;
- no materializer command or main-thread violation was observed.

The current disposition merges several independent trust failures in
`TryReadIndependentPrerequisiteEvidence` and `TryReadPrerequisiteMarker`.
Existing runtime evidence cannot distinguish them. The prior passive log tail
contained no prerequisite or command markers and ended as
`INSUFFICIENT_EVIDENCE`; it processed more than the requested 16 KiB and must
not be treated as authorization for another broad log read.

The adjacent `CancellationTokenSource.Dispose` message remains
`DIAGNOSTIC_ATTRIBUTION_UNAVAILABLE`. It is not a finding, root cause, or repair
target in this FIX.

## Objective

Add one stable, sanitized, deterministic classification for the prerequisite
evidence trust decision, without changing its admission result or executing
another runtime scenario.

The classification must distinguish exactly these outcomes:

1. result is absent/null;
2. command timed out;
3. command envelope is present but invalid;
4. prerequisite marker cardinality is not exactly one;
5. the single prerequisite marker is malformed;
6. the parsed marker disagrees with the product-status prerequisite state;
7. trustworthy `CURRENT`;
8. trustworthy `MISSING`.

Names may follow established C# naming, but persisted values must be enum-like
sanitized codes only. Do not persist paths, command lines, raw stdout/stderr,
exception text, tokens, machine identity, marker payloads, or arbitrary
strings.

For an untrustworthy outcome, coordinator admission must remain denied exactly
as before. `CURRENT` must continue into the existing lease-publication path;
`MISSING` must retain the existing `PrerequisiteMissing` product behavior. This
FIX is instrumentation, not authority or policy repair.

## Required Regression Coverage

Add focused pure tests for all eight outcomes above. The tests must also prove:

- classification precedence is deterministic when more than one invalid
  condition is present;
- every untrustworthy category maps to the same fail-closed admission Boolean
  as the former aggregate category;
- no marker content, raw process output, path, or machine-specific value enters
  lifecycle evidence;
- existing lease publication, Supervisor admission, missing prerequisite,
  integration eligibility, and current-instance classification behavior is
  unchanged;
- no automatic retry, Reinstall, direct materializer fallback, second command
  owner, or main-thread work is introduced.

Do not broaden this into exhaustive materializer parsing, producer-contract
changes, queue/Bridge repair, or `CancellationTokenSource` investigation.

## Writable Surface

Expected writes:

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- the parent `RESULT.md`, append-only with FIX 02 evidence

If the classification can safely reuse the existing sanitized
`coordinator_admission_disposition` field, do so. A second evidence field is
allowed only when reusing that field would erase the later lease/admission
disposition; record that reason before editing. Any other write requires a new
Planner/User decision.

## Read Boundaries

- Read only this card, the parent `TASK.md`, `FIX-01.md`, the relevant tail of
  `RESULT.md`, and targeted symbols in the three writable source/test files.
- Do not read the Unity Editor log in this code phase.
- Do not read or enumerate `UnityValidationProject/.codex/` or
  `UnityValidationProject/AIWork/`.
- Do not inspect user-level Codex configuration, raw runtime state, unrelated
  projects, or unrelated repository changes.
- Use repository-relative paths in all task records. Refer to the external log
  only as `Unity Editor log`; never persist a user profile or machine path.

## Execution Budget

- The project must remain closed for the entire code phase. If a matching Unity
  process is observed, stop without edits.
- Targeted source reads: one batch, maximum 60 seconds and 24 KiB captured
  output.
- Focused static/source checks: one batch, maximum 60 seconds and 16 KiB
  captured output.
- Run one final `git diff --check` scoped only to files changed by FIX 02.
- C# L1, Unity EditMode, Cold Start, Unity UI, Unity MCP, BatchMode, and all
  other tests are `NOT_AUTHORIZED / DEFERRED`.
- No retry is authorized. A command, output, or time-budget failure stops this
  FIX and is recorded honestly.
- Do not start, close, or control Unity, Unity Hub, Unity MCP, any validation
  process, or any business process.
- Do not commit, push, contact Verifier, or enter the visible lifecycle phase.

## Preserved Contracts

- FIX 01 lease-target selection and all prior S12/S13 admission boundaries stay
  unchanged.
- Missing, Uninstalled, invalid integration, migration attention, ownership,
  single-flight, and main-thread safety behavior stays unchanged.
- `Payload~/Generations/poc.34/` remains byte-identical and is not read in this
  FIX.
- No new prerequisite authority, lease authority, producer marker, process
  owner, retry path, or materialization path is introduced.

## Stop Conditions

Stop without a speculative fix when:

- the validation project is open or frozen identity drifted;
- classification requires a producer-contract change or any file outside the
  writable surface;
- the eight outcomes cannot be classified without retaining sensitive/raw
  evidence;
- the change would alter admission behavior rather than expose its reason;
- a check fails independently or any execution budget is exhausted.

## Completion And Handoff

Append one `S13 FIX 02` section to `RESULT.md` containing:

- the exact classification contract and precedence;
- files changed with pre/post byte counts and SHA-256 identities;
- bounded static evidence and scoped `git diff --check` result;
- explicit `NOT RUN / DEFERRED` boundaries;
- one status: `INSTRUMENTED_READY_FOR_COLD_START`, `BLOCKED`, or `FAILED`.

If `INSTRUMENTED_READY_FOR_COLD_START`, stop and notify Planner. The next step
is a separate human decision to open the existing `UnityValidationProject/`
once for one corrected Cold Start and to capture only the new sanitized code.
Do not open Unity and do not dispatch Verifier.

If `BLOCKED` or `FAILED`, notify Planner with the exact decision required. Do
not attempt a policy repair, another instrumentation pass, or a runtime test.

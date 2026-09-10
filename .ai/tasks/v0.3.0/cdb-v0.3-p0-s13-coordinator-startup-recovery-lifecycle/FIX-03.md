# S13 FIX 03: Single Prerequisite Marker Authority

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Status: `READY_AWAITING_DISPATCH`
- Owner profile: `v0.3.coder.deep`
- Review profile: `v0.3.verifier.deep`, only after a later passing corrected
  Cold Start and explicit Planner routing
- Phase: Runtime Release Gate; bounded producer repair
- Validation gate: the user confirmed `UnityValidationProject/` is closed

## Frozen Input Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- Committed HEAD: `9aada838e26879810a4f79760273ca66340ebf12`

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/FIX-02.md` | `8680` | `cc5f36810a6662e9727ea14d2d22e1a0711bd858ff7effc7fab63c8fbdf39ba7` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/FIX-02-COLD-START.md` | `5384` | `831d9d1dbfe09d010708719ac69569ed4696914b93a8b1ca5c2e60afaf095341` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/RESULT.md` | `38784` | `5657e9f8b36ee1ccc889c399d2510a6e165463c3e3617e494708abc0824f2546` |
| `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` | `577751` | `47d88ea12ccb78d6c17ea825c9cb6474ee61ae3a2a80394b28fa2a72315a0040` |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `249662` | `cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `733447` | `ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058` |

Identity drift before work is a hard stop. Do not reset, repair, or substitute
another baseline. `RESULT.md` may grow only through the append authorized by
this card.

## Confirmed Finding

The corrected Cold Start produced:

- `prerequisite_evidence_disposition=MarkerCardinalityInvalid`;
- `coordinator_admission_disposition=PrerequisiteEvidenceUntrustworthy`;
- `reconcile_started_count=15`, `reconcile_completed_count=15`;
- Supervisor and Coordinator PID zero;
- no materializer fallback or main-thread violation.

The exact production path proves the cardinality is two for a current
instance-backed DryRun:

1. the top-level materializer obtains machine prerequisite status and calls
   `Write-MachinePrerequisiteStatus` before the action switch;
2. the same DryRun enters `Write-InstanceProductStatus`;
3. the instance engine writes a second
   `[PRODUCT_LAYER PREREQUISITE] CURRENT` marker.

The instance engine also contains prerequisite marker writes in convergence
success branches. Every production path reaching those branches has already
passed the top-level prerequisite writer. The marker therefore has two
writers, while the C# consumer correctly requires exactly one.

## Objective

Make the top-level materializer the only prerequisite marker authority for one
command invocation.

- Preserve `Write-MachinePrerequisiteStatus` as the sole producer of
  `[PRODUCT_LAYER PREREQUISITE]` output.
- Remove duplicate prerequisite marker emission from the instance engine's
  product-status and convergence-success branches.
- Do not suppress, deduplicate, or relax validation in the C# consumer.
- Do not add an action-specific exception or tolerate multiple equal markers.
- Preserve every installed/configured/MCP/product-state/result/cleanup marker
  and all command-result behavior.

This is an output ownership repair only. It must not change prerequisite
evaluation, instance selection, activation, retirement, lease publication,
Supervisor admission, retry, or mutation behavior.

## Required Regression Coverage

Strengthen the existing focused machine-prerequisite fixture so it proves:

- current DryRun output contains exactly one prerequisite marker and its value
  is `CURRENT`;
- missing prerequisite DryRun output contains exactly one prerequisite marker
  and its value is `MISSING`;
- the instance-backed DryRun/current status path does not add a second marker;
- the instance engine contains no independent prerequisite marker producer;
- current and missing results retain their existing exit codes and do not
  mutate the fixture project;
- no additional materializer, process, retry, or fallback path is introduced.

Do not expand the fixture into lifecycle, Supervisor, Unity, activation,
retirement, or full materializer regression coverage.

## Writable Surface

Expected writes:

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- the parent `RESULT.md`, append-only with FIX 03 evidence

`com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` is read-only in
this FIX because its top-level writer is the retained authority. If changing it
becomes necessary, stop and return to Planner rather than broadening the patch.
No C# file is writable in this FIX.

## Read Boundaries

- Read this card, the FIX 02 cards, the relevant tail of `RESULT.md`, and only
  the prerequisite/status functions and focused prerequisite fixture in the
  three frozen PowerShell files.
- Do not read the Unity Editor log or any runtime state.
- Do not read or enumerate `UnityValidationProject/.codex/` or
  `UnityValidationProject/AIWork/`.
- Do not inspect unrelated repository files, projects, user configuration, or
  worktree changes.
- Use repository-relative paths in all durable records.

## Execution Budget

- Confirm passively that the validation project remains closed before editing.
  If a matching Unity process is present, stop without edits.
- Targeted reads and static checks: one batch, maximum 60 seconds and 24 KiB
  captured output.
- Focused L0: exactly one invocation of
  `test-codedb-host-payload-materializer.ps1 -PrerequisiteOnly`, maximum 120
  seconds and 16 KiB captured output.
- One corrected retry is allowed only for a command-construction or fixture
  setup failure before a production assertion executes. Any product assertion
  failure stops the FIX.
- Run one final `git diff --check` scoped only to files changed by FIX 03.
- C# L1, EditMode, Cold Start, Unity UI, Unity MCP, BatchMode, Node L0, and all
  other tests are `NOT_AUTHORIZED / DEFERRED`.
- Do not start, close, or operate Unity, Unity Hub, Unity MCP, any validation
  process, or any business process.
- Do not commit, push, contact Verifier, or perform the corrected Cold Start.

## Preserved Contracts

- The C# exact-one marker consumer and all FIX 01/FIX 02 behavior remain
  unchanged.
- Machine prerequisite checks remain the prerequisite authority and remain
  fail-closed.
- Instance activation, recovery, retirement, holder preservation, and
  immutable generation behavior remain unchanged.
- No automatic Reinstall, direct fallback, new process owner, or additional
  command invocation is introduced.
- The previous `CancellationTokenSource.Dispose` diagnostic remains out of
  scope and non-actionable.

## Stop Conditions

Stop without a partial workaround when:

- the validation project is open or a frozen input drifted;
- the fix requires changing the top-level materializer, C#, or any unlisted
  file;
- exact-one output cannot be achieved without weakening the consumer or
  changing prerequisite policy;
- focused L0 exposes an independent production failure;
- any command, time, output, or retry budget is exhausted.

## Completion And Handoff

Append one `S13 FIX 03` section to `RESULT.md` containing:

- the confirmed duplicate-writer path and final single-writer contract;
- files changed with pre/post bytes and SHA-256;
- focused L0 command, exit code, elapsed time, output summary, batch and retry
  ledger;
- final scoped `git diff --check` result;
- explicit `NOT RUN / DEFERRED` boundaries;
- one status: `FIXED_READY_FOR_COLD_START`, `BLOCKED`, or `FAILED`.

If `FIXED_READY_FOR_COLD_START`, stop and notify Planner. The next step is a
separate human decision to open the existing `UnityValidationProject/` once
for one corrected Cold Start. Do not open Unity and do not dispatch Verifier.

If `BLOCKED` or `FAILED`, notify Planner with the exact decision required and
stop. Do not attempt another fix or runtime scenario.

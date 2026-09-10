# S13 FIX 03 Attempt 02: Single Prerequisite Marker Authority

## Metadata

- Parent task: `cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle`
- Supersedes execution only: the BLOCKED FIX 03 attempt remains immutable
- Status: `READY_AWAITING_DISPATCH`
- Owner profile: `v0.3.coder.deep`
- Validation gate: the user confirmed `UnityValidationProject/` is closed
- Verifier routing: prohibited in this attempt

## Frozen Input Identity

- Branch: `codex/v0.3.0-legacy-workflow`
- Committed HEAD: `9aada838e26879810a4f79760273ca66340ebf12`

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/FIX-03.md` | `8155` | `50d8ccf798768b74c1bb1133eb815aa79391cb3c08168c0487b7f7fe012b64b5` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s13-coordinator-startup-recovery-lifecycle/RESULT.md` | `40350` | `51f11a2825fcdfae298c8ca54ea0adcd897f2142c2f4c859a9bd2b13c3ff28f7` |
| `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` | `577751` | `47d88ea12ccb78d6c17ea825c9cb6474ee61ae3a2a80394b28fa2a72315a0040` |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `249662` | `cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af` |
| `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1` | `733447` | `ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058` |

Identity drift is a hard stop. Do not reset, repair, or substitute another
snapshot. The parent `RESULT.md` may grow only through the append authorized
below.

## Confirmed Repair

No discovery is required. The top-level materializer is the retained single
prerequisite marker authority. Remove the four duplicate instance-engine
writers currently located in these pre-edit ranges:

- current-instance convergence return: lines `3861-3869`;
- completed activation return: lines `3987-3995`;
- `Write-InstanceProductStatus`: lines `4190-4212`, containing both the
  `MISSING` and `CURRENT` duplicate writers.

Do not edit the top-level materializer. Do not change the C# exact-one
consumer. Preserve every other output marker and all status/control behavior.

Strengthen only `Invoke-MachinePrerequisiteContractScenarios` and its direct
failure helper so the fixture checks exact prerequisite marker cardinality and
value for current and missing DryRun results. Their pre-edit read range is
test lines `7754-7821`.

## Writable Surface

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- parent `RESULT.md`, append-only with Attempt 02 evidence

`com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1` is frozen
read-only. Any other write is a hard stop requiring Planner/User approval.

## Predeclared Read Contract

Use one command and only these exact pre-edit line ranges:

- engine `3861-3869`, `3987-3995`, and `4190-4212`;
- test `7754-7821`.

Do not run `rg`, `Select-String`, repository search, symbol discovery, full-file
read, diff, or a substitute scan for source context. The combined emitted
source text must be measured before output and must not exceed `12,288` UTF-8
bytes. If it exceeds the cap, stop without emitting or editing.

After editing, a static count-only check may report only:

- number of `[PRODUCT_LAYER PREREQUISITE]` producers remaining in the instance
  engine, expected `0`;
- presence of the retained top-level writer function/call, expected true;
- presence of exact-count assertions in the focused fixture, expected true.

Do not emit matching source lines during that check.

## Required Focused Evidence

- Exactly one invocation:
  `test-codedb-host-payload-materializer.ps1 -PrerequisiteOnly`.
- Maximum wall time: `120` seconds.
- Captured output maximum: `16 KiB`.
- Required assertions: current DryRun has exactly one `CURRENT` prerequisite
  marker; missing prerequisite DryRun has exactly one `MISSING` prerequisite
  marker; existing exit codes and fixture project immutability remain valid.
- One corrected retry is allowed only for command construction or fixture setup
  failure before any production assertion. Any product assertion failure stops
  the attempt.
- Run one final `git diff --check` scoped to the two writable source/test files.

## Hard Boundaries

- Confirm passively that the validation project remains closed before editing;
  if it is open, stop without edits.
- Do not start or operate Unity, Unity Hub, Unity MCP, BatchMode, a validation
  process, or a business process.
- Do not read the Unity Editor log, runtime state,
  `UnityValidationProject/.codex/`, or `UnityValidationProject/AIWork/`.
- Do not modify prerequisite policy, instance lifecycle, activation,
  retirement, lease, Supervisor, retry, fallback, or C# behavior.
- Do not run C# L1, EditMode, Node L0, any other PowerShell suite, or full
  regression.
- Do not commit, push, contact Verifier, or perform the corrected Cold Start.

## Completion And Handoff

Append `S13 FIX 03 Attempt 02` to `RESULT.md` with:

- frozen identity result;
- exact read/output bytes;
- two changed-file pre/post bytes and SHA-256;
- count-only static evidence;
- focused L0 exit, elapsed time, batch/retry ledger, and bounded output summary;
- scoped `git diff --check` result;
- all `NOT RUN / DEFERRED` boundaries;
- one status: `FIXED_READY_FOR_COLD_START`, `BLOCKED`, or `FAILED`.

If fixed, stop and notify Planner. A later Cold Start requires a separate human
decision and manual Unity open. Do not route Verifier. If blocked or failed,
stop with the exact next decision required.

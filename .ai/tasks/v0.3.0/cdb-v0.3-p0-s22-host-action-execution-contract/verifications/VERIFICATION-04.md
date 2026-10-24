# S22 GUARDED FIX 01 Verification 04

## Verdict

**FAIL**. FIX 01 closes most of `VERIFICATION-03.md` P1-01, but the original
fail-closed receipt finding remains open for one immediate cross-record
timeout regression. A terminal receipt can assert timeout with exit 4 while
reporting an elapsed duration shorter than the admitted command timeout, and
the recovery reader still treats that impossible combination as authoritative.

This is a targeted source re-review only. No new architecture or broader S22
audit was performed.

## Frozen Identity

- HEAD: `6b64f27adb51eeab8394aac6bca722117ac6863c` - **PASS**.
- Ordered tracked 13-path binary-diff Git blob:
  `e1b89e07bcb70b159e53c7cb22e98da7b3a2c605` - **PASS**.
- Writer Git blob: `1072cb06b529fc47271c51a39025076252c5ab1e` - **PASS**.
- FIX 01 composite SHA-256:
  `6255c7faa377a2beb203e6d30967db41c71118a029a01894424279019f302cb3` - **PASS**.
- Identity was checked once with the frozen ordered path list and raw binary
  Git pipeline. No drift was observed before semantic review.

## P1-01 Re-review

### Closed portions

`ReadTerminalReceipt` now calls `HasValidManagerActionReceiptEnvelope` before
constructing an authoritative result. The validator requires and checks:

- admission, claim, and terminal `schema_version`, `managed_by`, and `state`;
- positive matching claim/terminal writer PID and a positive distinct child
  PID;
- numeric bounded writer-start ticks and an exact UTC completion timestamp
  that is not earlier than writer start;
- typed `output_overflow` and `timed_out`, required exit code, and nonnegative
  elapsed milliseconds;
- exit code 4 whenever timeout or overflow is asserted.

The existing reader continues to bind action/stage, project/Package keys and
roots, command identity, effect/authority, terminal-for-action, and the current
receipt scope. Missing or malformed required fields throw or return false and
therefore remain fail-closed (`AICodedbProcessRunner.cs:740-929`).

The focused tests declare one positive envelope, 15 missing-field cases, and
altered owner/state/writer/child/time/overflow cases
(`AICodedbManagerUiTests.cs:188-262`). These are source coverage; NUnit was not
executed.

### Remaining finding

1. **P1-01 OPEN - timeout evidence is not bound to the admitted timeout.**

   The admission record contains `command.timeout_ms`, and the one-shot writer
   only reports `timed_out=true` after its stopwatch reaches that admitted
   timeout. `HasValidManagerActionReceiptEnvelope`, however, never reads the
   admission command timeout. Its final predicate accepts any nonnegative
   elapsed value when timeout is true as long as exit code is 4
   (`AICodedbProcessRunner.cs:913-921`). Consequently, a terminal record such
   as `timed_out=true`, `exit_code=4`, `elapsed_milliseconds=1` can release
   Recovery even when the admitted timeout is 120000 ms. This is a direct
   missing cross-record consistency check, not theoretical hardening.

   The added negative cases do not mutate or remove `timed_out`, `exit_code`,
   `elapsed_milliseconds`, or admission `command.timeout_ms`; therefore the
   focused source assertions do not demonstrate this immediate regression is
   rejected.

No BLOCKER, additional P2, or FOLLOW-UP finding was identified. The accepted
S21 partial-v1 risk remains excluded.

## Declared FIX Boundary

- RESULT declares changes only to
  `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs` and
  `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`.
- The reviewed production validator and adjacent negative source coverage are
  confined to those two declared paths. The writer blob is unchanged.
- No other production/test behavior was re-reviewed.

## Reused Coder Evidence

- FIX 01 focused source/negative-recovery batch: exit `0`, `238 ms`; two C#
  syntax trees, 15 missing-field cases, positive envelope, and declared
  conflicting-evidence assertions passed as source checks.
- Ordered tracked 13-path `git diff --check`: exit `0`, no output.
- Earlier focused writer, Supervisor correlation, Manager source,
  Package-boundary, release closure (`source_count=46`, `mismatch_count=0`),
  and writer whitespace evidence were reused without rerun.
- Final identity evidence matched the frozen values above with no retry.

These records do not convert source assertions into executed NUnit, semantic
compile, or Unity runtime evidence.

## NOT RUN / DEFERRED

- Direct Editor/NUnit tests and C# semantic compilation: **NOT RUN**.
- EditMode, Unity, Unity MCP, and live Domain Reload recovery: **NOT RUN /
  DEFERRED**.
- Real Provider or consumer-project actions, process probes, and protected
  runtime reads: **NOT RUN / DEFERRED**.
- Full regression, commit-derived Package, commit/push, export/publication,
  and release acceptance: **NOT RUN / DEFERRED**.

## Routing

Current task: `cdb-v0.3-p0-s22-host-action-execution-contract`

Current status: **FAIL**

Next notification: UnityCodeDB v0.3 Planner

Next action: Planner consolidates this targeted result; Planner/User decides
`ACCEPT / FIX / DEFER / STOP`. Any FIX re-review must remain limited to the
original P1-01 timeout cross-record binding and its immediate negative case.

Current S22 FIX 01 targeted verification is complete. No Coder contact,
repair, test rerun, protected-runtime read, commit, push, export, publication,
or next-role dispatch was performed.

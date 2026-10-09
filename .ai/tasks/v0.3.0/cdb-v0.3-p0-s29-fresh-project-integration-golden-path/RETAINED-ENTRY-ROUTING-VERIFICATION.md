# S29 retained recovery entry verification

2026-10-09. Fresh independent depth-one read-only Verifier after Coder stopped.
Verdict: **SCOPED_SOURCE_AND_SYNTHETIC_ENTRY_REVIEW_PASS**. Original early-dispatch
blocker is closed for the frozen source/synthetic CLI scope. No BLOCKER or
actionable adjacent frozen-path finding. S29 remains PARTIAL.

## Admission

Base/current HEAD independently matched
`a06944c1cb7e29ff0b2b209eebe6ca4fe502de85` before and after review.
Read RETAINED-ENTRY-ROUTING-TASK.md and RETAINED-ENTRY-ROUTING-RESULT.md fully.
Admitted `.artifacts/tests/s29-entry/source.sha256` SHA256:
`c43f45b5189294a5a465df3dcef3bcc72b56dc43117efe86c258b8d239adc55b`.
All six repository-relative rows independently match current file hashes.
The three protected Payload identities also have no diff against HEAD.
Scoped changed-path `git diff --check` exited 0.

## Original blocker and adjacent proof

- `Tools~/materialize-codedb-host-payload.ps1:11962` adds only the empty
  UninstallPreflight early-switch case. It falls through to the existing
  dedicated case at line 12129; candidate/intent lookup, original action/receipt/
  project/Package hash validation, PID/process/holder validation are retained.
  The unchanged default at line 11971 still refuses Reinstall in UNINSTALLED.
- Mutation confirmation is still required before the early switch (line 11923,
  existing Assert-MutationConfirmation). Confirmed Uninstall uses its unchanged
  early branch at line 11957 and engine retained disposition at
  `Tools~/codedb-instance-engine.ps1:5181`. The engine requires unique original
  action binding and publishes through the existing checked writer; it neither
  replays Install nor replaces a prior intent.
- Reviewed the complete focused harness. Each Windows PowerShell child invokes
  the original on-disk materializer with actual CLI parameters (runner lines
  125-129). Imported definitions only prepare/read fixtures; no copied body
  replaces entry dispatch. BuildFixtureOnly returns before the existing helper's
  backend recovery and process seams. The runner's sole native seam is
  Get-CimInstance/Win32_Process: synthetic clear or relevant-name/unobservable
  command rows. Production PID checks and record/action/hash/holder readers
  remain active. This is explicitly synthetic process evidence.
- Existing successful evidence `r-c61f2fc8/summary.txt` reports PASS, 22
  assertions, eight CLI invocations, Windows PowerShell 5.1.19041.6456. Per-case
  stdout/stderr agree with AVAILABLE for matching retained authority; BLOCKED
  for unknown action, mismatched admission and unobservable process command;
  missing-confirmation refusal; confirmed Reinstall refusal; and confirmed
  retained Uninstall success. The harness asserts complete project/local-receipt
  file digest identity for all seven read-only/refused invocations.
- Confirmed-Uninstall assertions check original action, retained instance,
  removal-state and terminal/intent/desired hash links; unchanged retained
  effects, intent and receipt bytes; original exit 6/incomplete drain/failure
  output; existing production readers and absence of a pending marker. Its
  command result remains UNINSTALLED/PENDING with reason
  FAILED_CANDIDATE_EFFECTS_RETAINED. No manufactured successful original terminal
  or EOF is accepted by these assertions.
- Preserved first-attempt evidence `r-dd8031a3/matching.stderr.txt` identifies
  the missing owned Unity marker. Source includes the causal marker correction.
  No review rerun or additional correction was performed.

## Limits and procedure

Only this verification document was created. No source/fixture mutation, suite
or focused-test execution, real runtime/receipt access, Unity/MCP/CUA/BatchMode,
process control, commit/export/remote write, nested agent or Coder contact.
Findings are returned once to Parent/User. Review ends at the original blocker
and declared adjacent evidence; no wider Host/format/security audit.

Review completed within the 15-minute window. One combined validator range plus
search output exceeded the 6 KiB packet target and was tool-truncated; only its
missing directly relevant six lines were subsequently read. No retroactive
compliance is claimed. A read-only metadata command initially had a PowerShell
parser error and was corrected without executing mutations. Cumulative output
was not byte-instrumented; the 48 KiB aim is not certified (approximately
60-70 KiB returned, below the frozen 128 KiB overall ceiling). Search result
counts stayed below 50 per search.

This verdict reviews existing Coder synthetic evidence; it is not independently
rerun test evidence, actual live process safety, real recovery, Unity compile/
EditMode, runtime/consumer/device/performance or release acceptance. Authentic
current preflight and concrete real-operation authorization remain separate.

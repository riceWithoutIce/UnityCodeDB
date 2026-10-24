# S29 startup authentication boundary — F-01 repair result

Date: 2026-10-13. Status: F01_SOURCE_READY_FOR_TARGETED_REVIEW / PASS_WITH_LIMITS.
User grant: “同意” to the concrete filename repair and F-01/nearest-regression
re-review proposal. Parent owns repair; completed Verifier will be reused only
after this stable snapshot. No other implementation finding or task is added.
Base/current HEAD: 04e9a6bd49ae46f5c10989f6e4c6efddc479ad24.
Source identity: STARTUP-AUTH-BOUNDARY-REPAIR-F01-SOURCE-SHA256.txt.

## Exact delta from the first reviewed snapshot

- AICodedbManagerActionJournal.cs: the runtime-state presence guard now checks
  `watch/coordinator/coordinator-state.json`, matching the production coordinator
  filename, instead of `watch/coordinator/state.json`. The existing lease checks
  and watch/state.json/retiring.json presence guards are unchanged.
- AICodedbManagerUiTests.cs: the existing production journal fixture gains one
  `coordinator-state` case. It creates the real-named state file for an otherwise
  unrelated older candidate with no active lease and expects Conflict specifically
  due to `unresolved runtime authority`. Other fixture cases are unchanged.
- The other three original source/test files retain their first-review hashes.
  No runtime-status parsing, live probing, process control, cleanup, or mutation
  permission is added. Mere real-named state presence remains conservatively blocking.

## Focused validation

One corrected-source standalone focused run, exit 0: seven actual journal-reader
fixture cases PASS: historical, stale-editor, editor-holder, instance-holder,
generation-holder, invalid-lease, coordinator-state. These retain six fixture
file hash assertions across each read. The no-holder state-file case checks the
specific refusal reason rather than accepting any unrelated Conflict.

One current-source semantic compilation, exit 0: 34 files, C# 9, zero errors.
Five-file scoped whitespace check passed. No unchanged full suite was rerun;
the previous 51-case batch is attributed to the first reviewed snapshot, not a
fresh 52-case execution claim. The current test method has 16 cases; only the
seven declared F-01/adjacent cases were executed here.

The existing ignored harness RuntimeTests.cs now has an explicit
RICE_S29_AUTH_REVIEW_FILTER=F01 branch selecting only those seven cases and
returning before the original real-project reader. No product script or live
reader was executed by that branch. Native/static Unity and old NUnit adapters
remain exactly the previously declared standalone limitations.
Commands built the harness then executed the named .dll directly; the shared
apphost was not used. No failed product validation attempt occurred in this
repair; one documentation patch context mismatch made no file change and was
corrected. No final output truncation or attempt-budget compliance is inferred
for the earlier full task.

## Preservation and acceptance limits

The four real S29 protected state hashes and both Package-reference file hashes
match the initial repair result. Current project still references the already
delivered s29-historical-handoff-04e9a6b extraction. This repair is uncommitted
source, not part of that referenced Package.

No Unity/MCP/BatchMode/CUA, Probe/Ensure/Install/Upgrade/Remove, external process
control, history cleanup, index release, source commit, export, project-reference
switch, push or publication was performed. Existing unrelated dirty state and
historical result/review records are preserved. Source ACCEPT, native Unity,
live readiness/mutation and delivery remain separate pending gates; S29/release
remain PARTIAL.

Next: same Verifier performs only F-01 closure and nearest regression static
review, admits replacement hashes once and writes F01-VERIFICATION. Parent
waits for completion and returns its verdict to the human. No extra spawn
approval is requested for this already approved same-task fix/re-review.

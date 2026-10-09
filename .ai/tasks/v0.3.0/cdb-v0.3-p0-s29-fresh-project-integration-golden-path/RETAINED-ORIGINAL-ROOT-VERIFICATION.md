# Original INSTALL project-root independent verification

2026-10-09. PASS_WITH_LIMITS / SCOPED_SOURCE_REVIEW_PASS.
Original finding and its frozen adjacent boundaries reviewed; no scoped finding.
S29 remains PARTIAL. No real preflight/recovery or Unity/release gate closed.

## Admission and scope

Read REVIEW-GRANT, all TASK slices, RESULT, and both selected project-root
contract sections. Coder source was stopped. Base is 9e682a3f23cba4fd0f279593f3c2853060cd3c4f.
Independently recomputed source.sha256 fingerprint:
98b0f4282cccbd69b5288f6d8941872ef0a37422a4f9cc00f3e685688f52f86a.
Independently recomputed all 38 listed file hashes: 0 drift, including three
protected runtime/Payload projections. Inspected bounded source/diff for the
materializer, retained fixture builder, and focused CLI test only.

## Findings disposition

Test-RetainedAbsoluteProjectRootIdentity admits both operands before GetFullPath:
Windows drive-absolute or complete UNC roots; invalid characters, NUL,
relative/drive-relative/current-drive-rooted/incomplete UNC roots refuse.
Windows comparison handles slash/case/trailing separators; non-Windows admission
and comparison remain platform-absolute and ordinal. It neither expands env
variables nor infers a drive/CWD for incomplete roots. The generic helper and
its unrelated consumers remain untouched.

Both Get-FailedCandidateActionEvidence consumers use that same helper:
admission.project_root and the original command -ProjectRoot. All other expected
arguments still compare ordinally. Original argument strings still feed the
existing newline-joined hash and command-identity computation; original record
hashes are returned without normalized byte rewriting. Action/operation binding,
required confirmation, terminal failure identity, containment/reparse/process/
holder and physical-cleanup boundaries were not weakened by this scoped diff.

The optional RecordedProjectRoot fixture input changes synthetic admission and
raw command argument together before their existing hashes are generated;
omitted input preserves earlier callers. The focused mode independently selects
forward-slash historical spelling against a native CLI caller. Main actual CLI
tests therefore exercise both affected production readers, not a substituted
decoder. The materialized runner substitutes only Win32_Process enumeration.
Helper cases cover both operands and case/trailing equivalence; adjacent actual
CLI cases cover context variants, different/incomplete argument, raw hash tamper,
operation/action mismatches, ambiguous process and confirmation refusal.
The confirmed synthetic retained path checks original failed/incomplete outcome,
intent/history/candidate preservation, emitted links and UNINSTALLED/PENDING.

## Executed evidence and limits

Read existing attempt-2.log final evidence: Coder PASS 46 assertions / 14 actual
CLI invocations. Read closure-attempt-2.log: source_count 60, mismatch_count 0,
production admission PASS without canonical repair. These are attributable
Coder execution results, not independently rerun tests. Parent exact-commit ZIP
closure, extracted focused execution and authentic read-only preflight remain
separate prerequisites. No new human Unity cycle was executed or requested.

Original attempt and Coder output-budget breaches remain disclosed in RESULT;
they are not retroactively erased. This review also requested a combined
materializer/fixture diff that returned 90 lines and was token-truncated; its
single-read 6 KiB compliance cannot be claimed. Targeted source ranges then
covered the materializer helper/consumers/hash flow and fixture construction.
Exact cumulative captured-byte accounting was not retained, so the 32 KiB
cumulative target is not asserted as proven. No tests or broad audit were added
to compensate for that workflow deviation.

Only this verification record was written. No product edits, real runtime or
receipt reads/writes, Unity/MCP/process control, commit/export, remote action,
Coder fix requests or nested delegation. Review stops at this scoped disposition.

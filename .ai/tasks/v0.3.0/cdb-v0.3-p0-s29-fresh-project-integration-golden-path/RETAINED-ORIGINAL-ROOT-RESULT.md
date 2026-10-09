# S29 original INSTALL project-root consumer closure - Coder result

2026-10-09. SOURCE_FROZEN / READY_FOR_INDEPENDENT_REVIEW. S29 PARTIAL.
Base:9e682a3f23cba4fd0f279593f3c2853060cd3c4f. No commit/export/live operation.

## Implementation and unchanged boundaries

Only the three source paths in RETAINED-ORIGINAL-ROOT-TASK.md changed.
Materializer adds Test-RetainedAbsoluteProjectRootIdentity: admit fully-qualified
platform absolute roots before GetFullPath; compare Windows slash/case/trailing
variants without CWD/drive inference. Both admission.project_root and original
command -ProjectRoot in Get-FailedCandidateActionEvidence use this entry.
Non-Windows comparison remains ordinal. Existing generic argument path helper
and unrelated callers stay unchanged; C#/engine/receipts/Payload untouched.
Other original arguments stay ordinal; conflict diagnostic names the key.
Original recorded argument strings still feed original hash computations.

The existing retained fixture builder adds optional RecordedProjectRoot for
test-owned admission and arguments; omitted parameter retains prior behavior.
The focused entry test adds exclusive -OriginalProjectRoots mode. It records
forward-slash historical roots independently from the native CLI caller.

## Evidence

PowerShell syntax parse of all three changed files and materialized runner PASS.
Successful actual Windows PowerShell CLI proof:46 assertions /14 invocations.
Evidence: `.artifacts/tests/s29-original-root/attempt-2.log`,
fixture `r-3eb7691e` (all stdout/stderr and synthetic records retained).
Main actual preflight AVAILABLE; uppercase/trailing admission variant AVAILABLE.
Different argument root, drive-relative original argument, current-drive-rooted
admission, raw argument/hash tamper, exact operation mismatch, unknown action,
action mismatch, ambiguous process, absent confirmation and confirmed Reinstall
refuse without changing project/receipt digest. Helper assertions also refuse
relative, drive-relative, current-drive-rooted, malformed/NUL, incomplete UNC
and different roots on both operands. Slash/case/trailing roots accepted.
Confirmed synthetic retained Uninstall emits production disposition, preserves
original failed/incomplete terminal, intent and candidate bytes; desired state
remains UNINSTALLED/PENDING. Production intent/next-change readers accept links.
Only Win32_Process enumeration is synthetic; actual on-disk materializer,
record/hash/root readers, retained disposition, PID and holder checks execute.
Fixture construction uses existing test-owned producer setup; no real receipts.

Command:
`powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-retained-entry-routing.ps1 -OriginalProjectRoots`

Standard release closure without RepairCanonicalMetadata PASS:source60,
mismatch0, production admission PASS. Command supplies explicit PackageRoot
`G:/RiceProgram/UnityCodeDB/com.rice.ai-codedb` and AdmissionProjectRoot
`.artifacts/tests/s29-original-root/closure-project`; log
`closure-attempt-2.log`. Runtime contract538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d;
host pointer3bd992ea2245d50fa927d39bddc6cd7f8e74420d696596b8436b2da928c1a870;
poc.42 manifest2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026.

Prior Adapter snapshot37 rows:35 unchanged, only allowed materializer/entry
test differ. Fixture builder added to frozen source inventory:38 rows.
`.artifacts/tests/s29-original-root/source.sha256` SHA256:
`98b0f4282cccbd69b5288f6d8941872ef0a37422a4f9cc00f3e685688f52f86a`.
Scoped git diff --check PASS. Source edits stopped after freeze.

## Attempts and limitations

First focused attempt:7 assertions/1 CLI passed before a test-only array
precedence bug turned the appended separator into an extra equivalent case.
One causal correction parenthesized string concatenations. Failure preserved:
`attempt-1.log`, fixture `r-35eb7f43`. Second attempt PASS46/14. Total actual
CLI invocations across attempts15; no blind retry or process termination.
First closure command failed at default PackageRoot binding because its
PSScriptRoot was empty; `closure.log` retained. Explicit package/project roots
fixed command admission; second closure PASS. No source repair to closure.

Output budget breach:initial param-pattern multi-file search produced458 lines/
13,352 original tokens and truncation, exceeding single-read/search limits.
Later unfiltered git status likewise exceeded bounded read/line expectations.
Those outputs are not retroactively compliant; exact cumulative byte accounting
is unavailable and96KiB cumulative compliance is not claimed. Broad reads were
stopped in favor of exact functions/ranges and log tails. Stable product evidence
does not erase this workflow limitation.

No unchanged Adapter14-case suite rerun; no real S29 preflight/recovery,
historical receipt mutation, Package export/reference switch, Unity/C# compile,
EditMode/human Manager check, MCP/process control or release acceptance.
Fresh Verifier owns original finding and adjacent frozen checks only.

# S29 accepted compact receipt layout - delivery result

2026-10-08. SOURCE_ACCEPTED / COMMIT_EXPORT_CONSUMER_PASS /
HUMAN_COMPILE_TEST_PENDING / S29_PARTIAL.

Commit df91ef6a279ba0ffd3387ff00369137a5878df04:
`fix(editor): compact Manager receipt storage and preserve recovery identity`.
Exactly24 paths per DELIVERY-PLAN. All nine reviewed source/test hashes matched
FIX01 identity; eight changed source/test files plus four docs and12task records.
Raw source staging preserved reviewed bytes. Workflow/Host Action staged documents
include only compact-layout sections over HEAD; unrelated dirty worktree content
preserved. Empty initial/final index, staged exact set/blob checks and diff-check
PASS. No amend, reset/clean, push/tag/publication or remote changes.

## Exact exported artifact

Fresh .artifacts/s29-receipt-layout-poc40 from the exact commit via unchanged
committed Tests~/export-codedb-package.ps1. Both commit-staged and ZIP-extracted
closure gates PASS52sources/0mismatches. Reviewed nine source/test hashes and
four committed document blobs match exact extraction.

- Package: review/com.rice.ai-codedb/package.json.
- Version0.3.0-preview.5; generation poc.40 unchanged.
- ZIP: com.rice.ai-codedb.zip,2,416,403bytes,517entries.
- ZIP SHA256:167b6f5efc026a20cf127c72cb9df19842a425577b673300b50d43df9deb2baf.
- Extracted517files/10,778,819bytes.
- Generation manifest SHA256:d427ffa383c7de5203637ca16cee5a1480e470c812d30fa523f332d7385d92d3.

Exact extracted ManagerActionWriterOnly executed once in Windows PowerShell5.1:
12/12 PASS, exit0, deepest publication path270characters. Copied writer and
synthetic children isolated below extracted review/.artifacts/tests with child-only
LOCALAPPDATA/TEMP/TMP. This is extracted-consumer evidence, not C# or Unity proof.
Source writer12/12 at227 remains previous evidence; no source test batch rerun.
No export retry, real Host/Provider or Unity action. Mechanical read-only command
path mistakes (wrong exporter directory and LiteralPath wildcard) were corrected
without repeating export/evidence or affecting files.

## Human-confirmed closed project switch

User confirmed UnityFreshInstallValidationProjectS29 normally closed and allowed
reference switch. After all gates PASS, apply_patch changed exactly CodeDB's
reference line in manifest.json and packages-lock.json from test-workspace-poc40
to s29-receipt-layout-poc40/review/com.rice.ai-codedb. Both JSON documents parse and
resolve the exact new reference; no other dependency edit was requested/performed.
Reference-normalized final text hashes (UTF8, value replaced by <CODEDB_PACKAGE>):

- manifest:4AAA6ACC8BE49754617B2F0F53E34A748881221544E0503DE2D3651AC4F39300.
- lock:81920D91CE6BC6961578D971D4F2F94E107648C19097573E7A71BA1C9ED46899.

Pre-switch hash display was truncated by table formatting; only displayed prefixes
can be compared retrospectively. Exact two-line patches are the edit-scope evidence,
not a claimed complete before/after hash comparison.

RECEIPT-LAYOUT-HUMAN-CHECKLIST.md defines one opening: zero C# errors,34methods/
80cases, then Manager tab/window observations with no mutation buttons. All remain
NOT RUN. Preserve existing artifacts, candidates and real journals; no cleanup or
adoption. These follow-up records and local references are uncommitted; no amend.

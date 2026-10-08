# S29 compact receipt layout FIX01 - bounded repair verification

2026-10-08. Disposition: SOURCE_REVIEW_PASS for F1/F2, their immediate
regressions and the specifically authorized unfinished dependency check.
F1 CLOSED. F2 CLOSED. Named dependency gap CLOSED. No new finding in this scope.
HUMAN_COMPILE_TEST_PENDING remains unchanged; this is not Unity, integration,
S29 or release acceptance.

## Snapshot and authority

Read active FIX01-TASK and complete FIX01-RESULT/IDENTITY after stopped Coder
handoff. Independent checks matched every final hash and all nine pre-fix hashes
against original IDENTITY. Exactly Journal and ManagerUi differ from that snapshot;
the other seven original allowed files remain identical. HEAD/branch/index match:

- HEAD: 332c7ffd510daebb6da6a386d66783d4aabf6bd6
- Branch: codex/v0.3.0-legacy-workflow
- Index SHA256: C23240C3B59C82E0E7F794A030D47DF1A8E68657A553AA308AC60F456B07FD65
- FIX01-RESULT SHA256: 2C8D657831D4FD334686C2677ABA8658DFBA0E868C4146354EE3A73EFDDBECF6
- FIX01-IDENTITY SHA256: 4A6B2747A16E28E2E211D41F513157DFC4C0891207F4EBAAF0030EB477817A17
- Editor/AICodedbManagerActionJournal.cs SHA256:
  B4A89217804BA841C4571BDF435D9A7B6BEC9ADF4356675ED08B67D968261FAA
- Tests/Editor/AICodedbManagerUiTests.cs SHA256:
  3F4231F718202BFF03D0C7E7473CEB6F7DD2D61936D6816727597FE43B5B9E94

The authenticated FIX01-IDENTITY supplies the other seven exact verified hashes.
Staged diff is empty. Earlier review and implementation/test files were preserved;
this report is the only reviewer write. Paths below are relative to
com.rice.ai-codedb unless explicitly identified otherwise.

## F1 closure: compact fixture consumers

Tests/Editor/AICodedbManagerUiTests.cs:55-56,88-93 now names the returned locator
stagePrefix. StagePath at :133 consistently derives its sibling evidence file.
The former stale INSTALL accesses now use that helper at :410 and :418.
Required-file assertions precede intentional corruption/deletion at :411,419;
the shared ChangeField helper checks its target at :127.

The missing-predecessor branch at :318 calls DeleteStage (:135-151). It computes
only admitted.json, claim.json, terminal.json and optional start-failure.json;
validates all four owned paths and the three required existing records before
deletion, then revalidates each path before its exact File.Delete. It neither
deletes an Action container nor treats a filename prefix as a directory.
Adjacent malformed/pending-stage mutations at :300-316 and single-stage pending
at :479-484 also verify their actual compact target exists. Original recovery,
conflict and blocked-admission assertions remain intact.

A narrow stale-pattern inspection found zero remaining occurrences of the
three original obsolete compact-consumer forms. Explicit historical fixtures
retain their real Stage64 directory interpretation. This closes the deterministic
source fixture errors; it does not claim that the Editor suite executed.

## F2 closure: authenticated original context on conflict

Editor/AICodedbManagerActionJournal.cs:449-452 now returns Conflict with an index
bound to closure.Key, marker.Context and marker.StorageLayout. Those values come
from the validated resolved marker already used by the original branch, not from
unvalidated receipt fields. The generic title/effect/authority follows the adjacent
legacy convention. Conflict remains Conflict; no historical success is fabricated.

The same eight UnclassifiedEvidenceStaysBlockedWithOriginalPackage cases now
assert Action ID, original project/Package context, compact layout and null
HistoricalResult at ManagerUiTests.cs:428-436. Restored-session checks at :437-448
cover authenticated context, conflict state, original warning, retained layout,
session re-entry refusal and durable journal refusal. This exercises the original
Package replacement failure path without widening scope or adding cases.

## Named dependency closure

Structured inspection confirms package version 0.3.0-preview.5, payload generation
poc.40, 52 payload file entries and 25 generation file entries. Neither file list
references Tools~ or invoke-codedb-manager-action.ps1. Payload source prefixes are
AIWork, Generations and host-current.json. The standalone Tools writer is outside
this immutable-generation manifest closure; this change needs no generation
transition on the inspected bindings.

Payload~/host-current.json points to
AIWork/.runtime/codedb/host/generations/poc.40. Its generation_manifest_sha256
matches the actual generation manifest SHA256:
D427FFA383C7DE5203637CA16CEE5A1480E470C812D30FA523F332D7385D92D3.

All six authorized dependency files are Git-blob-identical to HEAD, with empty
HEAD diff: package.json, Payload~/payload-manifest.json, Payload~/host-current.json,
Payload~/Generations/poc.40/generation-manifest.json,
Tools~/materialize-codedb-host-payload.ps1 and
Tests~/test-codedb-host-payload-materializer.ps1.

The historical reader at materializer :10954-11043 still binds Action
3049af7cfc9f4260928e3f89d18672c0 and Stage
b571e3a38c0f134306d1df4d412804de66048b32de371c95112d363e6b664b56.
It follows project24/Package24/Action32/Stage64 and requires the original
admitted.json + claim.json pair, schema1 envelopes and frozen original script/
writer hashes. It reads the writer from the admission's original Package, not
the replacement Package. The fixture at :10498-10557 retains the same IDs, legacy
paths and old hashes. Special marker publication at materializer :11169-11185
remains schema2 / HistoricalUnknownReconciled / command_outcome unknown with
original identities; fixture :10709-10715 still checks unknown disposition and
repeated-publication refusal. This is read-only source evidence, not execution
of that historical reconciliation fixture or authority to touch real evidence.

## Evidence and stopping boundary

Independent static attribute inspection matches the frozen inventory: 34 methods,
80 cases, zero count mismatches. C# compile and all Editor cases remain NOT RUN.
Coder's one scoped diff-check PASS is retained as reported evidence, not rerun.
Unchanged script hashes preserve attribution of earlier PowerShell 12/12 and
parser/path evidence; FIX01 adds no new executable PowerShell result.

No tests, Unity/MCP/CUA, live receipts, real processes/state, cleanup, export,
commit, Coder contact or implementation writes occurred. An initial read-only
inventory regex was interrupted for excessive evaluation time and replaced with
a bounded line-based source attribute scan; this was not a test execution/retry.

Prior review output-budget breaches remain historical and are not retrospectively
compliant. This repair review used bounded reads (each <=80 lines/8 KiB), about
55 KiB captured shell output before report metadata, within the 64 KiB repair
budget and 20-minute window. No full source audit was restarted. Original findings
and the named dependency gap are closed at source level; stop here. The later
human compile/test and any packaging/integration authority remain separate.

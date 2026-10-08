# S29 compact receipt layout - independent source verification

Date: 2026-10-08. Reviewer: independent stopped-snapshot Verifier.
Disposition: CHANGES_REQUIRED; no independent SOURCE PASS is issued.
Human compile/EditMode, real integration, S29 and release acceptance remain open.

## Authority and snapshot

Read REVIEW-PACKET first, then TASK, RESULT, IDENTITY and the two canonical
storage/workspace contracts. Coder was stopped and parent admitted this snapshot.
Implementation and test files remained read-only. The sole reviewer write is this
report. No test batch, C# compilation, Unity/MCP/CUA, live receipt/journal/process
inspection, implementation edit, Coder contact, child delegation, commit or export
was performed.

Independently verified HEAD and branch:

- HEAD: 332c7ffd510daebb6da6a386d66783d4aabf6bd6
- Branch: codex/v0.3.0-legacy-workflow
- Index SHA256: C23240C3B59C82E0E7F794A030D47DF1A8E68657A553AA308AC60F456B07FD65
- RESULT SHA256: C317AD9BEFC58C430D61A98ABD80ED884F41C7C02A23A0E99E95A2748153CD0C
- IDENTITY SHA256: 61ED0BFCD65F3DCB0B46BD19A7ECD5823484335FBC18AC45F3EA5318F3EB87DE

All nine final file SHA256 values independently matched IDENTITY. Exact verified
values below are relative to com.rice.ai-codedb:

| File | SHA256 |
| --- | --- |
| Editor/AICodedbPaths.cs | 6DAAACD5722BBE4341CAF66BDCED79E4CB39E0B41A1ED96DCF2BBB0F8FBDAC32 |
| Editor/AICodedbProcessRunner.cs | 1ECA668E0AC0B2CB98E0C35964456111DD1A75DB4E6FC5581228F2845F657CFC |
| Editor/AICodedbManagerActionJournal.cs | D5CE44268989FB253E484B39D83F9587C79348C304FD4EA87D5FBFCFCA629077 |
| Editor/AICodedbManagerWindow.cs | A9924977CEDC93475F92DF97A0618C33EFAE0D82D138D5EA20198731C710F23C |
| Tools~/invoke-codedb-manager-action.ps1 | 657F780C53D2CC69E47B16A4B28954003A3FDFCF9397D551DB779AC0F8BED0A4 |
| Tests/Editor/AICodedbTestWorkspace.cs | DAE7C664E250FF70213EA1F32387C91B4078708ABA5D56ADFDC2309C304987BC |
| Tests/Editor/AICodedbManagerUiTests.cs | AE9641971D19D9F630FF48D616638B2DBEFADCF3D9F03C68A2AE69DA69811538 |
| Tests/Editor/AICodedbEditorLifecycleTests.cs | B4D5520E89213B320F90C502DBBE4E690127AACDBB76B35B0008352DA92933FC |
| Tests~/test-codedb-package-boundary.ps1 | 9F368E6F675243D8391D1DF272423F40AFA0E000C6412D23169FFCF662689323 |

The eight source/test changed paths agree with the identity artifact. Lifecycle
tests remain hash-identical. Inherited documentation modifications were observed
and preserved; reviewer does not claim an independent protected-tree baseline.

## Consolidated findings

### F1 - P1: compact fixture consumers still use removed stage directories

Locations: Tests/Editor/AICodedbManagerUiTests.cs:287, :379 and :386.
Changed producer: the same file :55 and :88-94.
Adjacent consumer: Tests/Editor/AICodedbTestWorkspace.cs:215-229.

ManagerReceiptFixture.Add now returns an Action32/Stage16 filename stem and writes
the admitted/claim/terminal records as sibling files. It no longer creates a
directory at that stem. However:

- DeclaredRedeployRejectsUnknownOrIncompleteChain("missing-predecessor") still
  calls DeleteOwnedTree on that stem. DeleteOwnedTree enumerates it as a directory,
  producing DirectoryNotFoundException before the recovery assertion.
- UnclassifiedEvidenceStaysBlockedWithOriginalPackage("malformed"), ("identity")
  and ("arguments") still write/read stem/terminal.json or stem/admitted.json.
  Those parents no longer exist, so setup fails before the intended recovery and
  original-Package assertions. The "pending" variant also targets the obsolete
  path instead of deleting the actual compact terminal record.

This is a deterministic source/fixture regression, not a claim of an observed
Unity run. It prevents the declared later 34-method/80-case suite from exercising
the preserved business assertions as authored. The coupled correction is to
address actual compact evidence files and remove the predecessor's exact evidence
set while retaining ownership checks and the existing assertions. No broader
test redesign or extra suite is requested.

### F2 - P2: resolved compact conflicts discard authenticated original context

Location: Editor/AICodedbManagerActionJournal.cs:449-450.
Direct expectation: Tests/Editor/AICodedbManagerUiTests.cs:393-400.
Recovery consumer: AICodedbManagerActionSession.RestoreDurable in
Editor/AICodedbManagerWindow.cs (conflict branch around :3518-3525).

Trigger: an existing compact resolved marker validates for the original Package,
the Package is replaced, and its direct receipt becomes conflicting or remains
incomplete (for example, a nonterminal/unclassified retained action). At :441-442
the marker already supplies its authenticated original Context and StorageLayout.
The new conflict return instead supplies a null index and only the Action ID.

After a full exit there is no prior in-memory session. RestoreDurable therefore
falls back to currentContext and marks HasOriginalContext false. The historical
warning reports the original Package as unavailable even though the validated
resolved marker contains it. This breaks the frozen original-context recovery
contract and the retained source assertions at :399-400. Admission stays blocked;
this finding does not assert replay, data damage or unsafe process termination.

The focused correction is to preserve an authenticated original index/context
and its storage layout on this conflict result, retaining the conflict disposition.
The existing unclassified-history tests and directly adjacent context restoration
are sufficient review scope; no new general audit is proposed.

No normal production-path data/configuration damage or external-process BLOCKER
was established. These are concrete source/fixture defects, not speculative
hardening. User/Planner owns whether to repair now, defer or accept risk; the
Verifier issued no repair order to Coder.

## Reviewed contract and evidence classes

Source inspection supports the following bounded observations, not an overall
PASS in the presence of F1/F2 and the procedure limitation below:

- AICodedbPaths derives Action32/Stage16.kind.json, keeps full stage identity and
  explicitly distinguishes compact-v1 from absent-layout legacy paths. The changed
  readers reject layout/path mismatch; schema2 remains legacy-only in the journal.
- Journal/session changes propagate storage layout and original Package identity
  for current recovery. Resolved compact history is looked up through project
  markers rather than a machine-wide scan; F2 covers its lost-context branch.
- Admission publishes a manifest under the existing project journal/lock, then
  publishes stage admission. C# temporary files and PowerShell temporary files use
  CreateNew and no-overwrite Move. Duplicate evidence does not authorize replay.
- The PowerShell writer receives the admitted file, validates machine-root
  confinement, reparse paths, full manifest identity and command hash binding,
  and rejects legacy/directory arguments before command launch.
- Test workspace allocation uses a parent CreateNew reservation, a 12-hex run
  name, a full 32-hex ownership token and owned bounded cleanup. Deep-path probes
  use production required-path derivation and System.IO; these Editor probes were
  inspected but not executed. F1 is the remaining concrete consumer migration gap.
- The focused PowerShell fixture copies the writer below repository-owned scratch
  and assigns LOCALAPPDATA/TEMP/TMP only to its ProcessStartInfo. Cleanup validates
  owner, containment and reparse/bounded traversal; primary and cleanup failures
  have distinct reporting. No parent environment rewrite was introduced there.
- Explicit legacy reader/caller changes preserve old path interpretation and the
  special historical marker scenario. No automatic migration or old-writer launch
  was introduced by the inspected changes.

Coder reports Windows PowerShell 5.1 parser 2/2, PathProvenanceOnly, scoped
diff-check and the isolated synthetic writer batch 12/12, deepest publication
path 227 characters. This review inspected the corresponding changed fixture and
writer; it did not independently execute or reproduce those claims. They are
PowerShell/source evidence only. The authored C# 34 methods/80 cases are NOT RUN;
F1/F2 identify source contradictions before that human cycle.

Direct immutable-generation/materializer dependency closure was not completed
independently. The initial exact-path lookup used two nonexistent guessed paths;
a bounded filename lookup located the actual Payload~/ manifests and the
materialize-codedb-host-payload.ps1 / corresponding fixture. Their contents were
not subsequently read because the output guard had already been exceeded.
Consequently the RESULT's 52/25 manifest counts, poc.40 binding and unchanged
historical materializer behavior remain Coder-reported here, not independently
verified claims. This limitation does not invalidate the directly evidenced F1/F2.

## Procedure deviation and stopping boundary

The reviewer exceeded the requested cumulative 128 KiB output guard during
source/diff reads. Exact cumulative byte accounting was not retained; do not
treat this as budget-compliant. The combined RESULT+IDENTITY read was 211 lines,
and some unsegmented contract/diff reads also exceeded the 200-line command cap.
Narrowing subsequent reads does not retroactively cure these breaches.

Once recognized, source exploration stopped. No test rerun or compensating broad
scan was used. The findings are delivered once at this stable snapshot, with this
explicit incomplete-closure/procedure qualification. There is no independent
SOURCE PASS and no runtime/Unity/integration/release PASS. A later authorized
repair review should cover F1/F2 and their immediate regressions, plus only any
explicitly reauthorized unfinished dependency check; do not restart a full audit.

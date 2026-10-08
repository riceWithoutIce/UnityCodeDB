# S29 operation result semantics - Coder result

Date: 2026-10-08. Status: SOURCE_IMPLEMENTED / PS_WRITER_PASS /
INDEPENDENT_REVIEW_PENDING / CSHARP_UNITY_EXECUTION_PENDING.
Baseline HEAD: `3b09859045d0d4547d9ba2cef332a550e8530f99`.
Branch: `codex/v0.3.0-legacy-workflow`.
Authority: RESULT-SEMANTICS-IMPLEMENTATION-PLAN.md, SOURCE_EXECUTION_AUTHORIZED.
Stable source fingerprints: RESULT-SEMANTICS-IDENTITY.json. Coder stops editing
at this handoff; existing unrelated dirty state is preserved.

## Change and safety boundaries

Exactly the five frozen source/test paths were changed. One shared
`AICodedbMaterializerCommandSemantics.ClassifyHistoricalNonSuccess` entry consumes
the unchanged strict parser and classifies only the two contract shapes:

- Authoritative, complete, nonzero matching INSTALL; BLOCKED or FAILED;
  CANDIDATE; exactly host_runtime and instance_candidate; PENDING.
- Authoritative, complete, nonzero matching UPGRADE; BLOCKED or FAILED;
  PREFLIGHT; no scopes; COMPLETE.

Actions' pending-Install predicate and ProcessRunner's refused-Upgrade predicate
now consume that shared classification. Other outcomes/shapes return None; no
permissive fallback or change to JSON decoding was introduced. Existing stage
count, identity, argument binding, terminal flags and original Install result
ownership stay in the existing recovery implementation. The Upgrade's COMPLETE
does not clear Install's PENDING. No replay or next-action authorization is added.

Journal and Manager are unchanged. Tests exercise their existing historical
restoration, session and removal presentation/confirmation boundaries. Fixture
identities are generated under the approved `AICodedbTestWorkspace`; real action
IDs, real Package roots and live machine journal records are not copied or read.
The sanitized DryRun uses the recorded NEEDS_ATTENTION/MISSING/UNAVAILABLE/NONE
shape, replacing the former synthetic UPGRADE_READY assumption for this chain.
The historical fixture preserves INSTANCE_CANDIDATE_FAILED and
INSTANCE_CONVERGENCE_FAILED reason codes while testing both allowed outcomes.

## Producer/consumer evidence route

The existing PowerShell test script has one early focused switch,
`-CommandResultSemanticsOnly`. It parses the actual sibling production
materializer, imports exactly five writer/dependency function bodies and nine
production default initializers, and returns before the test script's other
execution entry points. It never dot-sources or runs the materializer top level.
It performs no file mutation, install, upgrade, process probe or live prerequisite
lookup. Only fixture operation context is supplied to the actual functions.

Six outputs cover default BLOCKED Install/Upgrade, explicit FAILED
Install/Upgrade, and zero-exit default outcome controls. The success controls
exercise writer defaults; they are not successful installation simulations.
The source production writer is unchanged.

The authored Editor test locates its own resolved Package (fully qualified
PackageInfo), invokes that Package's focused harness, and consumes the original
stdout records using the real parser and shared semantics. It then binds the
default BLOCKED output into fixture-owned admitted/claim/terminal records and
passes it through ProcessRunner, Journal and Manager session restoration.
Original Install stdout, unsuccessful result, PENDING warning and no automatic
reconcile are asserted. The child PowerShell process uses the fixture workspace
as working directory/TEMP/TMP; no system TEMP or C-drive fixture is introduced.
The launch has a 15-second execution bound and 5-second output-drain bound.

No pre-existing isolated real-C# consumer harness was found in the directly
scoped tests. The available generated csproj files are Unity project artifacts,
not an authorized standalone harness. This gap was reported before source work;
no external compiler/test platform was invented. Real C# consumer execution is
therefore explicitly pending the human-owned Unity stage, not silently PASS.

## Executed evidence

- Windows PowerShell 5.1: `powershell.exe -NoLogo -NoProfile -NonInteractive
  -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
  -CommandResultSemanticsOnly`: exit 0, 6/6 actual writer scenarios, approximately
  3.0 seconds. Initial attempt passed; no correction/repeat.
- The invoked script and the production materializer both parsed successfully;
  the latter is explicitly AST-checked before any writer import.
- Scoped `git diff --check`: exit 0. Scoped diff: five files, 284 insertions,
  26 deletions. Source inspection confirmed both old FAILED-only predicates are
  replaced; identity/chain readers and production writer remain unchanged.
- Fingerprints and authored test-case counts read from the final files.

A discovery search initially produced truncated output; follow-ups were narrowed
to explicit dependencies. No truncated output was treated as test evidence.

## Consolidated focused human inventory

All five methods are in `AICodedbProjectSettingsTests`, ordinary synchronous
NUnit Test/TestCase entries compatible with the current Unity test entry route.
No parameterized async Task, NonParallelizable attribute or new platform is used.

| Method | Cases | Purpose |
| --- | ---: | --- |
| ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate | 8 | FAILED/BLOCKED, single/three-stage, pending/resolved, original output, journal/session, existing removal confirmation/presentation |
| MaterializerResults_ProductionWriterFeedsHistoricalRecoveryAndSession | 1 | Six actual PS writer outputs to real C# parser/classifier, then BLOCKED chain to recovery/journal/session |
| MaterializerResults_UnsupportedShapeCannotResolveHistoricalChain | 20 | Both actions: zero exit, exit mismatch, success/unsupported outcome, wrong action/phase/scopes/cleanup, missing/malformed result; direct classification and three-stage journal refusal |
| MaterializerResults_IncompleteEvidenceIsNotKnownFailure | 8 | Both actions: missing authoritative evidence, timeout, overflow, incomplete drain |
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage | 8 | Existing adjacent missing/malformed/foreign/unbound, extra/duplicate stages, nonterminal and mutating-Upgrade refusals |

Total: 5 methods / 45 NUnit cases. Of these, 3 methods / 29 cases are new;
the existing positive method grows from 4 to 8 cases, and the existing 8-case
negative method is reused. The PS writer's six scenarios run inside one Editor
case and are not six additional NUnit cases.

Pending: C# compile, those 45 Editor cases (including actual-writer-to-C# closure),
independent Verifier review, exact extracted-package semantic/byte evidence,
human Manager observation, and separate real integration acceptance. No Unity,
MCP, BatchMode, live receipts/project inspection or writes, install/remove/replay,
candidate cleanup, package reference switch, commit, export, tag or push occurred.
S29 remains PARTIAL; this source task does not establish Ready or completed cleanup.

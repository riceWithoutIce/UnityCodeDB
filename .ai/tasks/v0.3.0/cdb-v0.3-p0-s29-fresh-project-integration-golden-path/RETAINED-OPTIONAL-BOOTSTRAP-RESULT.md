# Optional bootstrap absence consumer result

2026-10-09. CODER_COMPLETE / STABLE_FOR_INDEPENDENT_SCOPED_REVIEW.
Base HEAD12f8147fa0ef9cd2897d3da217debae0b2396e6a. Index remains empty.
No commit/export/reference switch, real project/receipt write, Unity/MCP launch,
process termination, generation/Payload repair, or remote write performed.
S29 PARTIAL. C# consumer and human Manager gates explicitly NOT_RUN.

## Changes within the three frozen source files

- AICodedbManagerActionJournal.cs skips only the exact unrecorded AIWork/codedb
  root when both File.Exists and Directory.Exists are false, after the existing
  RetainedProjectPath containment/reparse checks. Snapshot-recorded paths still
  pass the earlier mandatory existence/hash validation. Required instance and
  generation roots, unknown present content, file roots and redirects retain
  existing refusals. Adjacent unrecorded-effect detail now names its relative path.
- AICodedbManagerUiTests.cs makes the existing actual-PowerShell retained proof
  test self-contained on Windows: resolves the installed Package and prepares
  the real emitted intent/disposition proof under its owned test workspace.
  No manual PowerShell command, environment variable or real recovery is needed.
  It reads the proof before fresh Install, restores the original failed/incomplete
  session, and checks equivalent project roots plus existing hash/root refusals.
  Adjacent tests within the same method cover missing recorded directory,
  required generation/candidate, retained file hash drift, unknown present child,
  root-as-file, recorded optional root disappearance and root junction redirect.
  Fault bytes/topology are restored in finally; original terminal bytes preserved.
- test-codedb-host-payload-materializer.ps1 adds RetainedOptionalFlatOnly and
  optional owned fixture parent routing. Only this mode omits both flat fixture
  files, selects ABSENT, imports the already accepted shared Adapter contract
  definitions, emits actual production proof and stops before synthetic fresh
  Install. Prior modes/defaults are preserved. No production PS semantics change.

## Executed evidence and actual limits

Evidence directory `.artifacts/tests/s29-optional-flat/`.

1. Actual Windows PowerShell fixture attempt1 failed after7 assertions because
   the existing AST harness missed Get-CodedbTextAdapterOutputContract. The new
   mode's exact shared definition import is the causal fix. Preserve attempt-1.log,
   attempt-1-failure.md and r-156506f8; stderr capture limitation recorded there.
2. Attempt2 PASS:41 assertions, native_children=0, elapsed98619ms;
   attempt-2.log / r-58335e7b/emitted-record-context.json. Actual production
   intent/removal/disposition functions run on synthetic owned records. Holder,
   prerequisite and unrelated process observation seams remain synthetic;
   this is not authentic process safety or real recovery acceptance. Two fixture
   PowerShell process invocations total across attempts; no standalone production
   CLI invocation. Original retained interruption and subsequent completion are
   covered; original incomplete failed terminal byte hash preserved. Emitted
   project AIWork/codedb stays absent and its retained inventory has no root row.
3. Normal source release closure PASS:60 sources /0 mismatches, production
   admission and native VerifyOnly PASS, explicit PackageRoot and owned
   AdmissionProjectRoot; no RepairCanonicalMetadata. closure.log.
4. SDK Roslyn syntax-only, C#9, two final source files /0 syntax errors;
   csharp-syntax-final.log. This is neither Unity C# compilation nor journal/
   session consumer execution. No ready direct production consumer harness was
   available; focused EditMode method is the separately pending human gate.
   First dotnet diagnostic attempt was interrupted by WindowsPS native stderr
   banner capture; csharp-syntax.log empty. Corrected capture invocation ran
   successfully; csharp-syntax-attempt-2.log retained. Final syntax-only repeated
   after adjacent test additions; no unchanged broader suite repeated.
5. Changed fixture and ignored runner parsed; final syntax-only and whitespace
   checks pass. Protected prior38rows:37 unchanged, only permitted existing
   fixture source changed; journal/UI add2rows for40rows total.

Human focused target:
`ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession`.
It automatically invokes an isolated test-owned PowerShell producer, followed
by the actual journal/session reader. Human only runs the EditMode method;
no manual env or shell operation. WindowsPS fixture timeout180s, no automatic
retry or external process kill. Real fresh Install and Manager button/UI remain
open; never claim source/fixture PASS closes those gates.

## Frozen identities

`.artifacts/tests/s29-optional-flat/source.sha256`:40rows,
SHA25698047bcee78f7879316fa1619521765bee95217916f75749958d3fbb74a32c69.

- journal67cd1440a86a1b1247bad078160e4f846ca4b23ecb72151ae6193b22e8e2ed1d
- UI testbeeab1814f41686b13f44d1e2ca31b94b8fa9c35a882bd26f443ea113fe60493
- PS fixturebf90d9a76b24cbc5391cc3512f4e28ec61449c2dda2ce433a49c5fc13408fff0
- runtime contract538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d
- host pointer3bd992ea2245d50fa927d39bddc6cd7f8e74420d696596b8436b2da928c1a870
- poc42manifest2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026

No source edits after this stable record. Parent may independently recompute
snapshot and review original finding plus adjacent refusal regressions.

## Budget/search deviations

One combined read of four bounded-looking source ranges exceeded the aggregate
tool output budget and was truncated. A broad existing PowerShell keyword search
returned132lines, exceeding50matches, also truncated; a later source range hit
the embedded historical wrapper base64 line. Several source reads exceeded the
6KiB practical target; cumulative64KiB output target was not strictly enforced
and may be exceeded. These are review-output deviations, not retroactive
compliance. Subsequent searches used exact scopes/max counts and logs/tails.
One wildcard-like literal rg directory and one guessed closure script filename
were absent; corrected to exact existing paths. No resulting product mutation.

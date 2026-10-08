# S29 B-MR-01 correction - Coder stopped snapshot

Date: 2026-10-08. Active work approximately 02:48-03:01 UTC, within 60 minutes.
Final nine source identities captured at 02:59:49 UTC; no later source edits.
Base HEAD: `651f9b3b4a8af3108823036107f1d76bc450f760`.
Fix baseline: the stopped manifest in `MANAGER-RECEIPT-REPAIR-RESULT.md`; all nine
identities were checked and matched before this correction.

Status: B-MR-01 SOURCE_CORRECTED / SOURCE_CHECKS_PASS / UNITY_NOT_RUN /
INDEPENDENT_FIX_REVIEW_PENDING. This is not independent finding closure, C# compile,
Unity acceptance, live recovery or release acceptance. Whole S29 remains PARTIAL.

## Narrow correction

The actual producer has an optional Manager UI preflight followed by worker
preflight, the declared Redeploy mutation, and runtime-config. Only the final
runtime-config stage carries the persisted action-terminal flag. The former
correction recognized neither the four-stage Manager nor three-stage worker shape.

- `AICodedbActions` now declares the four existing stage names once; its worker
  scopes and `ManagerWindow`'s UI scope use those declarations.
- `ProcessRunner` first checks for this declared stage chain, before the generic
  single-terminal or historical INSTALL compatibility paths. A stage name must
  reproduce the existing action/name/command-identity stage hash. Every stage
  still passes the strict terminal receipt reader, with no nonterminal skipping.
- Each preflight binds to the captured Package materializer, authenticated DryRun
  arguments and successful Redeploy-admitting status before a successor is allowed.
  Mutation binds to confirmed Redeploy and the strict matching REDEPLOY result.
  The actual producer's success is CONVERGED with COMPLETE cleanup.
- Runtime-config binds to the captured project's generation or legacy
  `scripts/prepare-codedb-project-runtime.ps1`, exactly `-Force`, and the validated
  command hash/effect/authority. Classification uses admitted historical identities,
  not a current generation lookup or live project/process observation.
- A successful complete chain returns the final outcome together with the original
  mutation output. Config failure retains that mutation output and its own failed
  exit. An authenticated failed prefix is a derived completed failure only when
  no successor exists; original failure output, mutation scopes and PENDING remain.
  The aggregate's action-terminal status does not rewrite any stage receipt flag.
- Missing final completion remains Pending. Missing predecessors, extra/unknown
  stages, wrong terminal flags, malformed/unbound evidence, or a successor after a
  failed stage remain blocked. Timeout, overflow and incomplete drain also remain
  blocked. No receipt schema, new writer, live cleanup or replay was introduced.

Only five of the nine allowlisted files changed in FIX01: Actions, ProcessRunner,
ManagerWindow, ManagerUiTests and the appended contract section. Paths, lifecycle,
journal and lifecycle-test files retain their previous exact hashes. Original
failed INSTALL/PENDING classification, lifecycle isolation and original-Package
presentation were retained. Original repair and verification reports are immutable.

## Evidence and correction accounting

- Scoped `git diff --check` over the nine allowlisted files: PASS, exit 0.
- The single focused source consistency batch emitted 12 PASS assertions: shared
  producer declarations; named-chain routing before generic terminal handling;
  strict-reader wiring; stage-hash binding; undeclared-stage rejection; unique
  final-stage attribution; incomplete-stage blocking; no successor after failure;
  preserved mutation output; exact config arguments; retained historical INSTALL
  path; retained earlier test declarations.
- That batch's regex declaration scan printed the three correct 4/7/11 case counts
  but then spent excessive time scanning the remainder of the large test file.
  Its own tool session was interrupted (exit 1). This is not reported as a clean
  batch exit. One causally justified mechanical correction replaced only that scan
  with a bounded substring and simple literal counts. Completed assertions were
  not rerun. The corrected unfinished checks returned exit 0: 22 cases/3 methods,
  exact 30,597-byte FIX01 contract baseline prefix, and exact 28,222-byte original
  dirty contract prefix. Final hashes were then collected in the same command.
- Source observations confirmed the real producer's stage flags, stage-ID formula,
  runtime-config `-Force` call and materializer REDEPLOY CONVERGED/COMPLETE result.
  No claimed behavioral PASS was inferred from source text assertions.
- L0 DEFERRED: no applicable pure harness in the direct closure; no external
  compilation or Unity substitute platform was created.
- C# compilation, all Editor tests, Unity/MCP/CUA/BatchMode, real Install/Remove/
  replay, process probes and full regression: NOT RUN. No old 48/11/201 batch ran.

This pass used local bounded source slices (normally 40 lines or fewer), searches
below the 50-match limit and commands below 200 lines/32 KiB. Conservative command
output reserve accounting finished at 82,582 bytes: an initial 45,000-byte allowance
plus twice subsequent returned output string lengths. This is an accounting bound,
not an exact transcript byte audit; no output-budget breach was observed in FIX01.
The prior repair's reported guard breach remains in its original result and is
not erased or reclassified by this narrower pass.

## Human test manifest

All new cases are in `AICodedbProjectSettingsTests` within
`Tests/Editor/AICodedbManagerUiTests.cs`. They use the existing test-owned temporary
journal and saved-session fixture, real receipt/journal readers and production
session admission. Nothing in these fixtures was executed by Coder.

| Method | Cases | Coverage |
| --- | --- | --- |
| `ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory` | 4 | Manager four / worker three stages x pending current index / resolved marker; original Package after replacement; mutation output; legacy and generation config paths; immutable receipt bytes; next action admission. |
| `ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects` | 7 | UI failure; Manager/worker worker-preflight failure; Manager/worker mutation failure including PENDING; Manager/worker config failure including original mutation output; session completion and resolved marker. |
| `ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain` | 11 | Extra mutation, unknown stage name, wrong terminal flag, malformed receipt, unbound arguments, wrong config script, pending stage, missing predecessor, incomplete output, missing config, failure with successor. |

New: 22 cases, NOT RUN. Prior repair: 19 cases, still NOT RUN. Total authored
repair coverage: 41 cases, none executed here. Shared fixture helpers gained an
optional action title, explicit stage name/config path, declared Redeploy producer
shape and JSON-array serialization for test-only tampering; previous helper defaults
and historical INSTALL assertions remain. Lifecycle test bytes did not change.

## Final SHA256 manifest

Relative to `com.rice.ai-codedb/`; FIX01 baseline is the previous result manifest.

| Path | Final SHA256 | FIX01 |
| --- | --- | --- |
| Editor/AICodedbPaths.cs | C6735CE5B81886C7FDD100BCA460E134346733D35E4F7E8B6D4BEF59458565CA | Unchanged |
| Editor/AICodedbEditorLifecycle.cs | F6AEDEF76CC029CC3F046F97A30F739AEDC4B5EA695F6948CCD1F0BA35FAF765 | Unchanged |
| Editor/AICodedbActions.cs | 4D2E3FCAFFA9EF34A92C54D9C5C1F16E89F910479B15ACD7A3BE3C75D1B8E6A6 | Changed |
| Editor/AICodedbProcessRunner.cs | C0FADEDB9A10431D20D0B4EF7825737AD7B6075CD66BB96050D1BBBD013BBB3A | Changed |
| Editor/AICodedbManagerActionJournal.cs | F9CB0A93858542CCE3173DF0F1EDB1186FA56C4448E414642DBF5D3C2B7A14EC | Unchanged |
| Editor/AICodedbManagerWindow.cs | 6441AC880E463C0B585A7A3E850AF037C82944A43676EC4B8BF16E1A09311C9D | Changed |
| Tests/Editor/AICodedbManagerUiTests.cs | 9B9487C941A07B9127CD8E4CB28BFED08706E3905A8CC09BE030AFDFB1E992DC | Changed |
| Tests/Editor/AICodedbEditorLifecycleTests.cs | 59BF754DF11E63F9EE3755EA4A8700069172DDA4D189F1885736BB5BFA4D2068 | Unchanged |
| Documentation~/v0.3.0-p0-host-action-execution.md | 2C9C1FA37CD3059D59320F82352A6BA70D6DEFA8D59084C31E04C898838FEC2F | Append only |

Contract prefix identities retained exactly:

- FIX01 baseline, first 30,597 bytes:
  `C44546077E57B4F55F6F3BD642983461F3D577939FB6E2CDEA934DE136D94DAC`.
- Original inherited dirty contract, first 28,222 bytes:
  `DB3208BD3872A013CB8AAFC8DF4A611090D7AFB7F67DD129454A439E34B94AE9`.

Coder is stopped. Parent may admit these identities for independent B-MR-01 and
immediate-regression review; no broad audit or automatic repair dispatch follows.
Protected Unity/project/artifact/generation/live-receipt state was not touched.
No commit, push, export or publication. F-IMC-01/P3 and human/runtime gates remain
DEFERRED.

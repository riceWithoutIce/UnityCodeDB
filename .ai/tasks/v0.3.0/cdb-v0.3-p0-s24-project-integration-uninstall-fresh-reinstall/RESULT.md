# S24 Result

Status: ACCEPTED / NON_UNITY_EVIDENCE_ONLY

Frozen base HEAD: `5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`.
Four-path source/test binary diff identity: `66e63c523ecf897df36efaca243c631cf5ce30ba`.
Only the four paths below were changed in this checkpoint:

- `com.rice.ai-codedb/Editor/AICodedbControlContract.cs`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

## Implemented And Proved

- The partial Owner Identity v1 classifier now authenticates a later failed Supervisor operation independently of the historical activation/journal runtime hash. The activation and journal still have to agree on their own historical hash, contract, project, epoch, operation, candidate, current selection, and mutation bindings.
- PowerShell removal authority reads the bounded historical activation record to form a validation context, then runs the existing strict activation/journal validator. Supervisor failure, event continuity, selected instance/generation, and holder checks remain separate requirements. Ordinary activation reading was not relaxed.
- The focused partial-v1 fixture uses different valid historical activation and later Supervisor runtime hashes. It rejects activation/journal hash disagreement, live holder, mismatched selection, unknown evidence, missing activation, partial Supervisor evidence, missing selection mutation, and conflicting last-known-good without project mutation.
- The synthetic removal publishes authenticated `UNINSTALLED / COMPLETE`. An injected fresh-install candidate failure retains `UNINSTALLED` without selection. A later fresh Install selects a new instance and current Package generation, publishes its own v2 committed `INSTALL` activation with a new epoch, and does not restore the predecessor activation journal. The retained predecessor closure and external generation lease remain unchanged.

Evidence: PowerShell AST parse PASS; focused `-PartialV1RemovalOnly` PASS, exit 0 on Windows PowerShell 5.1; four-path scoped `git diff --check` PASS, exit 0. The initial PowerShell 7 run stopped before product assertions because `Add-Type -OutputType ConsoleApplication` is unsupported there. Two intermediate extensions of the focused test exposed command-side fixture setup errors (duplicate `node.exe` lookup without fixture mode, then fixture/confirmation mutual exclusion); a third exposed the test helper return shape. The corrected final focused run passed. No production correction was made for those command-side test errors.

## Remaining S24 Boundary

The frozen allowlist does not include the command bridge and lifecycle cache/status ownership needed to publish an independent, read-only removal preflight result to Manager. `AICodedbManagerWindow` must remain cache-only: opening, repainting, and tab switching cannot launch an ownership probe. Its current `RequiresReinstall` presentation is not sufficient to claim that the full PowerShell holder/ownership preflight passed. Interrupted removal recovery and ambiguous-holder preservation have not received new S24-specific fixture coverage. Do not route this source snapshot to Verifier or present S24 as complete.

Planner/User decision requested for one coherent continuation of the same S24 task: authorize the minimal command bridge plus lifecycle/status cache paths needed to run and cache an independent preflight on the worker, then wire Manager availability and text to that result. Recheck preflight under the removal lock before mutation, and add the remaining interruption/holder fixtures before claiming S24 complete. The exact expanded path list should be frozen before continuation; likely dependencies are `Editor/AICodedbHostPayloadMaterializer.cs`, `Editor/AICodedbEditorLifecycle.cs`, and `Editor/AICodedbStatusSnapshot.cs`. If a smaller direct closure is proved, keep it smaller.

No Unity, Unity MCP, C# compile/EditMode, real project removal, Provider operation, Package export, commit, push, tag, or publication occurred. `UnityValidationProject/**`, machine state, immutable generations, and unrelated dirty/untracked files were preserved. C# fixture assertions are source changes only and remain unexecuted until separately authorized Unity validation.

## Authorized Continuation - Read-Only Preflight And Recovery Evidence

The user authorized the same S24 task to expand its Editor allowlist for a
worker-owned, read-only removal preflight. The minimal change closure added
`Editor/AICodedbHostPayloadMaterializer.cs` and
`Editor/AICodedbEditorLifecycle.cs`; `Editor/AICodedbStatusSnapshot.cs` was
not edited. The frozen base HEAD remained
`5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`.

- `RemoveIntegrationPreflight` is a read-only materializer action. It invokes
  the same authority classifier used by the locked removal transaction and
  emits one exact `AVAILABLE` marker only on success; refused evidence emits
  `BLOCKED` and exit 4. It does not create a project operation or use a
  mutation confirmation credential.
- The lifecycle worker performs that probe for an installed project with an
  authenticated obsolete control or instance classification. It caches a
  boolean on product status and discards a result after cancellation or a
  stale worker generation. Runtime prerequisite readiness is not a removal
  credential. Manager open, repaint, and tab switching consume the cache
  without launching the preflight process.
- Manager and action admission expose `Remove CodeDB Integration` only for a
  cached successful preflight. On confirmation, the materializer still
  rechecks exact ownership and holders under its project operation lock.
  The confirmation copy now points to fresh `Install CodeDB` in the current
  Package rather than UPM Package removal.
- Focused partial-v1 L0 passed on Windows PowerShell 5.1, exit 0. Added cases
  prove preflight rejection without mutation for live, invalid, and mismatched
  holder/selection evidence; exact availability for authenticated evidence;
  rejection after removal; rollback after injected mutation 1; durable crash
  at mutation 1 (fixture child exit 86); blocked fresh Install during
  recovery; and successful later removal and fresh activation. One
  intermediate fixture expectation was corrected from exit 4 to the existing
  invalid-JSON exit 2; the final invocation passed.
- PowerShell AST parse PASS. Nine-path scoped `git diff --check` PASS, exit 0.
  Nine-path binary diff identity:
  `e83f117835cdf825e0951bed12048cdf3c5e9974`.

Status remains `ROUTE_REASSESSMENT_REQUIRED`, not S24 COMPLETE. The existing
`RemoveIntegration` transaction deletes the authenticated control selection,
Supervisor evidence, and MCP registration, then reports
`UNINSTALLED / COMPLETE`; the focused fixture proves the predecessor instance,
immutable generation, and external generation lease remain. The frozen
reinstall contract instead requires holder-bound retained content to be inert
and identified as pending cleanup, and forbids fresh Install from ambiguous
partial removal. After the old activation/journal are deleted, existing
desired-state alone does not bind a later cleanup to that exact removed
closure. Treating the retained bytes as `COMPLETE`, or allowing generic
pending cleanup without a durable removal authority, would weaken the
contract. This is a new authority design decision under the task's explicit
stop condition, not a fixture-only issue.

Planner/User must freeze either a durable removal-intent/retained-closure
authority that supports recovery and fresh-install admission, or an explicit
contract change for what `UNINSTALLED / COMPLETE` means. No further
implementation, Verifier routing, real removal, Unity, Unity MCP, C# compile,
EditMode, commit, push, tag, or publication was performed in this checkpoint.

## Design Alignment Checkpoint - Retained Instance Ownership

Planner/User aligned logical `UNINSTALLED / PENDING` separately from physical
cleanup, a durable exact removal intent, and a stable project-local MCP entry
that does not require repeated Codex rebinding. The contract and task card
were updated with those semantics; no real project state was touched.

A bounded implementation attempt then exposed an adjacent ownership conflict.
The existing Owner Identity removal fixture places dynamic index/sentinel
bytes inside the old instance and requires them to remain byte-identical.
An intent-bound cleanup prototype used the existing recursive retired-instance
deletion helper after holder drain; `-OwnerIdentityRemovalOnly` correctly
failed because those bytes disappeared. This is not an assertion to weaken:
holder drain proves process safety, not ownership of every mutable instance
child. The prototype source/test changes were removed with `apply_patch`.
The original nine-path source/test binary diff identity was recomputed as
`e83f117835cdf825e0951bed12048cdf3c5e9974`, exactly matching the prior
frozen checkpoint; `codedb-instance-engine.ps1` is clean again.

The prototype's isolated `-PartialV1RemovalOnly` run passed after matching
the pending-intent expectation, but that result belongs only to the removed
prototype and is not S24 acceptance evidence. No Unity, Unity MCP, C# compile,
EditMode, real removal, Provider operation, commit, push, tag, publication, or
Verifier contact occurred. Status remains `ROUTE_REASSESSMENT_REQUIRED`.

Planner/User decision required: either retain the entire old instance/index
as inert pending explicit ownership review, or define an exact reclaimable
subset that excludes unproved dynamic content. The same S24 task can then
continue with durable intent, cleanup and fresh-install admission; no new
micro-task or source snapshot is being routed to Verifier now.

## Design Alignment - One Removal Workflow

Planner/User chose to retain the old instance/index/sentinel closure byte-exact
and inert under `UNINSTALLED / PENDING`. Holder drain alone does not authorize
recursive instance deletion or `COMPLETE`; further physical reclamation needs
an individually authenticated, durable-intent-bound target and a separately
reviewed ownership rule.

User-initiated `Uninstall CodeDB from Project` and incompatible-version
`Remove CodeDB Integration`/guided Reinstall are entry contexts for one
ownership classifier, confirmation boundary, serialized removal transaction,
recovery, and cleanup authority. Historical-control recognition is a
preflight input, not a second mutation engine. The contract and TASK.md now
record this decision. This checkpoint changes only documentation; it does not
authorize or claim a production fix, L0, Unity, Verifier, commit, or release.

## S24 Source Implementation And Focused Evidence

The same S24 continuation now has a stable seven-path source/test patch on
HEAD `5fb5121c9141be2bb5273a28c1c1b27775f2a1c5`. The seven-path binary
diff identity is `a79e661a9ed3368632b976a2e988234ad2413f14`, calculated by
`git diff --binary -- <seven S24 source/test paths> | git hash-object --stdin`.
The changed paths are:

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- `com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`

Both presentation contexts use the same durable `removal-intents/<state-id>.json`
document and shared transaction deactivation entries. The intent is written
before desired-state, managed MCP-key, and selection changes. The ordinary
path requires selected-instance plus committed activation authority; the
historical path independently authenticates historical activation and later
Supervisor failure. Both paths report `UNINSTALLED / PENDING`, retain the old
instance/index/generation closure byte-exact, and do not stop holders. Generic
retired-instance cleanup skips an intent-bound retained instance. Missing or
invalid intent blocks pending Uninstall cleanup and fresh Install admission.
The older pending Install fallback based only on committed activation and a
retired-instance scan was removed; it cannot substitute for durable intent.
Fresh Install uses a new candidate and committed activation without adopting
the predecessor journal; the old intent remains durable.

Read-only `UninstallPreflight` and `RemoveIntegrationPreflight` share their
respective locked-action authority classifier. The historical preflight also
validates the managed MCP removal plan. The lifecycle worker caches the
result by project/package/selected instance/activation epoch for 120 seconds;
the existing background scheduler refreshes it only at expiry. Manager
opening, repaint, and tab switching only read in-memory lifecycle status.
Ready shows `Uninstall CodeDB from Project` only with ordinary preflight;
incompatible installed status shows `Remove CodeDB Integration` only with
historical preflight. Action callbacks recheck cached admission, and the
PowerShell mutation path rechecks authority under the project lock.

Final focused evidence on this source snapshot:

- Windows PowerShell 5.1 `-PartialV1RemovalOnly`: PASS, exit 0. Covers
  independent historical/Supervisor evidence, holder and mismatch refusal,
  transaction recovery, pending retained closure, and fresh activation.
- Windows PowerShell 5.1 `-OwnerIdentityRemovalOnly`: PASS, exit 0. Covers
  live/invalid/conflicting authority, exact orphan admission, idempotent
  recovery, and preservation of instances, indexes, sentinels, unrelated TOML,
  user data, and processes.
- Windows PowerShell 5.1 `-UninstallOnly`: PASS, exit 0. Covers read-only
  ordinary preflight, complete/repeated logical Uninstall, missing selection
  and missing intent refusal without project mutation, fresh Install,
  concurrent cleanup/Install, live watcher preservation, and crash recovery.
- Three affected PowerShell files: AST parse PASS, zero errors.
- Seven-path scoped `git diff --check`: PASS, exit 0, no output.

An initial invocation under bundled PowerShell 7 stopped before product
assertions because the existing fixture uses an unsupported
`Add-Type -OutputType ConsoleApplication`; all final L0 evidence used Windows
PowerShell 5.1. C# source assertions were added but C# compile/EditMode was
NOT RUN. Unity, Unity MCP, real project removal, Provider operations, Package
export, full regression, commit, push, tag, publication, and Verifier contact
were NOT RUN. The validation project, immutable generation bytes, external
runtime, and inherited dirty/untracked work were not modified by S24.

Next role: Planner reviews this stable snapshot and decides whether to route
one guarded Verifier pass. Unity/EditMode, real project integration, commit,
export, push, and publication require separate authorization.

## FIX 01 - P1-01 Manager Admission Correction

The first guarded verification found P1-01: ordinary Uninstall was suppressed
whenever runtime status was not `Ready`, even when the independent ordinary
`UninstallPreflight` had passed. The fix is limited to
`Editor/AICodedbManagerWindow.cs` and `Tests/Editor/AICodedbManagerUiTests.cs`.

Ordinary uninstall admission now requires:

- the project is not already `UNINSTALLED`;
- the status is `Ready`, or `NeedsAttention` with no contract ambiguity/reinstall
  reason;
- the cached ordinary removal preflight passed.

Historical `Remove CodeDB Integration` remains restricted to a reinstall reason
and its own cached historical preflight. Primary action, overview banner,
header menu, and callbacks now use the same mutually exclusive routing. An
ambiguous `NeedsAttention` reason remains blocked even if a malformed cached
boolean is supplied. Confirmation and the locked PowerShell authority check
were unchanged.

FIX 01 static evidence:

- Two-path Manager source/test binary diff identity:
  `10b832985a92fdaedbd49de62877bb9e2f6ee30d`.
- Final seven-path S24 source/test binary diff identity:
  `dd24b129403581169bcd3a286f78faa84f6f2868`.
- Manager/test scoped `git diff --check`: PASS, exit 0, no output.
- Direct source assertions now cover ordinary `Ready`, ordinary
  `NeedsAttention`, historical reinstall `NeedsAttention`, ambiguous
  `NeedsAttention`, cached-preflight failure, and project-already-uninstalled
  cases.

No Unity, Unity MCP, C# compile, EditMode, PowerShell L0 rerun, real project
operation, Provider operation, Package export, commit, push, publication, or
Verifier re-run occurred after FIX 01. The original `VERIFICATION-01.md`
remains the P1 finding record; a new guarded re-verification is required before
acceptance.

## Disposition - ACCEPT

`VERIFICATION-02.md` admitted HEAD
`5fb5121c9141be2bb5273a28c1c1b27775f2a1c5` and final seven-path identity
`dd24b129403581169bcd3a286f78faa84f6f2868`, then passed the bounded
read-only re-verification of P1-01 and its adjacent Manager routing. The
original finding is closed; BLOCKER/P1/P2/FOLLOW-UP findings: none. The user
accepted this frozen non-Unity S24 source snapshot.

This acceptance reuses the focused PowerShell L0, AST and scoped diff-check
evidence already recorded above. It does not convert C# source assertions
into executed tests: C# compile, EditMode, Unity, Unity MCP, and real project
uninstall/fresh-install remain NOT RUN/DEFERRED. No commit, Package export,
push, tag, or publication was authorized by this disposition.

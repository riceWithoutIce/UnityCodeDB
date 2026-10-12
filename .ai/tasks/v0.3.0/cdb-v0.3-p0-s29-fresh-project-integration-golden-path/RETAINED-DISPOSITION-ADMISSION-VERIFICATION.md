# Retained disposition admission independent verification

Date: 2026-10-12.
Verdict: **BLOCKED — two P1/BLOCKER findings on the frozen normal recovery path.**
Review: GUARDED, retained-disposition slice and directly adjacent consumers only.
Verifier: `/root/retained_disposition_verifier`, inherited parent model/effort;
no model override, no delegation, no Coder repair instruction.

## Snapshot admission and evidence

- Base: `b76957a9dbcae9b00eff73775a97c4e8f33ae785`.
- All eight allowlisted file hashes match `SOURCE-SHA256.txt` at initial and
  final admission. Seven files differ; ProcessRunner is unchanged.
- Independently checked the frozen task, route/result packet, touched source/test
  differences and directly referenced owner validators/session/UI consumers.
- Independent read-only checks: changed PowerShell parse errors=0; scoped
  `git diff --check` PASS. No implementation/test bytes or real state changed.
- Coder evidence remains attributable **Coder synthetic evidence**, not an
  independent rerun: owner fixture 47 checks PASS, semantic errors=0 and standalone
  consumer 13 cases PASS. The consumer harness covers journal reads, session
  restoration and eligibility helpers; it does not call the actual Window
  attachment or confirmed durable-admission path below.

## Findings — returned together for User/Planner disposition

### F1 — P1 / BLOCKER: published admission drops the observation that admitted the orphan

Location: `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs:1120`;
coupled caller: `AICodedbManagerWindow.cs:2858`.

Trigger: the backend has fully validated an inert retained PROVISIONING instance
whose original action is absent from Manager history, and an eligible confirmed
operation reaches `TryAdmit(index, ..., effectsObservation)`.

The first read at line 1073 consumes the fresh observation and correctly returns
Empty. The method then writes `current-action-<new>.json`, but its mandatory
published-identity read at line 1120 calls `Read(index.Context)` without that
observation. `ReadLegacyPending`/`FindUnownedProvisioningCandidate` therefore
classifies the old absent-origin candidate as Conflict again. `TryAdmit` returns
false before `PublishActionManifest` and before the confirmed command dispatch,
while the newly published pending index remains on disk. The caller restores
that Conflict as recovery ownership. Thus the source can display recovery
eligibility yet cannot complete the normal dispatch route and creates another
pending recovery index without executing the user command.

This is a deterministic source contradiction, not a theoretical race: the same
unchanged retained candidate is accepted by the initial read and rejected by the
post-publication read solely because the argument is omitted. It blocks the
frozen requirement that harmless retained history stop preventing the next
eligible operation. The adjacent release reads at lines 1146/1177 also do not
consume retained observation, so repairing admission must retain an explicit
authority-preserving policy for the exact action lifecycle; this is the same
finding's nearest regression, not a new audit scope.

Required disposition: FIX within this frozen path, or explicit User acceptance
that executable recovery remains unavailable. The narrow regression must reach
actual `TryAdmit` with production-emitted SAFE observation and an absent-origin
candidate, inspect the exact published ownership/result, and preserve fresh
backend revalidation and unresolved/foreign-owner refusal. No repair was made.

### F2 — P1 / BLOCKER: clearing the session leaves the Window recovery gate latched

Location: `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs:449`;
coupled clear: lines 3623-3642; visible gate: lines 1509-1516 and 2175-2176.

Trigger: a Window first attaches an existing stale recovering session (including
the normal reopen/domain-reload path), then a fresh SAFE aggregate proves that
its action is historical or that its anonymous evidence conflict is cleared.

`RestoreDurable` now intentionally sets `_current = null`. Both asynchronous
consumers immediately call `AttachCurrentActionSession`, but its null branch
returns without clearing `_userActionInFlight` or replacing the previously
attached recovering `_userActionStatus`. Repeated Editor update attachments
take the same null-return branch. The real session is gone, while Overview still
passes the old true in-flight flag to `ResolvePrimaryAction` and displays the
old action presentation instead of making the eligible action callback usable.
Reopening can repeat the problem because OnEnable attaches pending/static
recovery before the fresh observation clears it.

The new production consumer test asserts `CurrentFor(context) == null` and the
eligibility helper with a null session; it does not verify this Window projection.
This directly blocks the frozen session/UI/reopen behavior and is not merely a
cosmetic historical warning. Required disposition: FIX the null-session Window
projection without clearing a running/foreign owner or rewriting old results;
verify the attached recovering Window -> SAFE aggregate -> usable current
presentation transition. No repair was made.

## Verified boundaries and limits

- Backend SAFE is emitted only after existing removal-intent identity, manifest /
  generation / complete effect inventory / fingerprint / wrapper validators,
  holder validation, distinct selection checks and full relevant-instance
  admission. Duplicate bindings and PREPARED/ACTIVATING ownership return BLOCKED;
  no partial instance-ID grant is emitted. No-intent/drift/duplicate/live-holder
  refusal has Coder fixture evidence. Pending activation and committed wrapper
  handoff are source-verified reuse, not newly executed scenario evidence.
- The strict parser rejects absent/malformed/duplicate markers, unsuccessful or
  incomplete-output commands, foreign context, duplicate/invalid IDs and a
  BLOCKED grant. `Succeeded` already rejects timeout/overflow. SAFE and
  `install_eligible` are separate; an INSTALLED project does not gain Install or
  Ready merely from safe retained effects.
- Empty aggregate results carry action-ID collections and warning text, not a
  selected newest/single historical command result. Conflict presentation may
  retain a diagnostic historical result, but cannot grant dispatch. Original
  receipts/outcomes are not rewritten by the observation route.
- Stale session clearing requires same project plus attributable historical ID
  (or anonymous evidence conflict); running state and a different/unattributed
  pending owner are preserved by the new SAFE branch. F2 concerns the Window's
  stale projection after that legitimate clearing.
- New observation production code is on DryRun after payload/project validation
  and before action selection. Its owner/helper chain reads evidence and process
  identity only; it does not enter lock/mutation/cleanup/process-control branches.
  The Coder fixture digest reports no writes. No real DryRun was run by Verifier.
- UI-cached observation is not passed to dispatch: the worker fetches fresh
  DryRun evidence, the journal retains its index lock, and confirmed backend
  resource revalidation remains in place. F1 prevents that route from completing.

## Not run / disposition boundary

Unity import, actual Unity/NUnit, Window lifecycle/UI execution, current real S29
holder/wrapper/generation admission, confirmed operations, export/hash closure,
reference switching, commit/push/publication, migration and release are NOT_RUN.
This report does not promise an Install button in the actual INSTALLED S29
project. Current package/generation migration and post-stability cleanup remain
deferred. No histories, candidates, receipts, intents or processes were changed.

The current review stops here. User/Planner decides FIX/DEFER/ACCEPT/STOP; a repair
review should cover F1/F2 and their nearest declared regressions only.

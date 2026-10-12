# Retained disposition F1/F2 independent repair verification

Date: 2026-10-12.
Verdict: **PASS_WITH_LIMITS** — F1 and F2 closed at source/static review level;
no remaining BLOCKER/P1/P2 in this authorized repair review.
Review: one GUARDED read-only repair review of original F1/F2 and their nearest
regressions only. No new comprehensive audit or Coder repair dispatch.
Verifier: `/root/retained_disposition_verifier`, inherited parent model/effort,
no override or child delegation.

## Frozen identity and evidence admission

- Base remains `b76957a9dbcae9b00eff73775a97c4e8f33ae785` plus the original
  retained-disposition refactor. The authoritative fix hash record is
  `RETAINED-DISPOSITION-ADMISSION-FIX-SOURCE-SHA256.txt`; the abbreviated
  `FIX-SOURCE-SHA256.txt` in dispatch does not exist. The exact path was obtained
  from FIX RESULT, without creating an alias or modifying either record.
- All eight current hashes matched the fix record on entry and final check.
  Exactly Journal, Window and ManagerUiTests differ from original
  `SOURCE-SHA256.txt`; all other five hashes remain identical to the first
  review snapshot. Original RESULT, SOURCE-SHA256 and BLOCKED VERIFICATION are
  preserved; this report does not replace the earlier findings/evidence.
- Independently inspected the actual admission, exact release, Window attachment,
  label/callback consumers and the newly added focused tests. Scoped
  `git diff --check` PASS. No implementation/test/fixture or protected state edit.
- Coder's semantic errors=0 and 15 standalone managed cases PASS are accepted
  as **Coder evidence**, not relabeled as independent reruns. Inspected runner
  and native-boundary shims. The unchanged original 47 backend checks were not
  rerun, regenerated or overwritten.

## F1 closed — observation survives exact publication, release stays separate

`AICodedbManagerActionJournal.cs:1086` and `:1133` now pass the same fresh parsed
backend observation to initial admission and mandatory post-publication identity
read. The absent-origin retained candidate is no longer reclassified simply
because the latter read omitted its argument. The existing index lock, compact
layout/path validation, exactly matching Pending action-ID check and subsequent
`PublishActionManifest(index)` remain. The Window worker still obtains fresh
DryRun evidence for dispatch (`AICodedbManagerWindow.cs:2884` vicinity); it does
not pass its cached UI observation. Actual backend resource revalidation was
not weakened; its source bytes are unchanged from the first frozen snapshot.

Public `Read` always invokes private `ReadCore(..., true)`. The only callers of
`ReadCore(..., null, false)` are the two exact release methods. That private mode
skips candidate-origin scanning, not index identity, journal/history validation
or retained-effects marker proof. It cannot be invoked by public admission or
return a cached mutation permit. `TryRelease` keeps its lock, permitted
terminal/refusal disposition restriction, exact Pending action/package/storage
comparison, durable marker publication and exact current-index removal.
The adjacent session caller still requires matching original action evidence,
terminal-for-action authority (or authenticated pre-effect refusal), complete
output observation and durable admission. `TryReleaseRetainedEffects` still
requires an Empty read with the exact matching Index and its validated
FailedCandidateEffectsRetained result; the original receipt/intent/effect/current
state reader remains active even in private mode.

The new actual-consumer test has terminal and pre-effect-refusal cases: production
SAFE observation plus absent-origin candidate -> actual TryAdmit -> exact index
and validated action manifest -> no second owner/foreign release -> exact session
release and durable closure -> subsequent no-observation/foreign-context
admission refusal with no new index. It intentionally uses synthetic command
results; no backend command/real terminal receipt is executed by the harness.
This is sufficient focused consumer evidence for the argument-loss defect, with
actual process/runtime acceptance still outside this source gate.

## F2 closed — Window clears only its vanished historical projection

`AICodedbManagerWindow.cs:447` now records the attached session. When CurrentFor
returns null, it clears the Window's stale in-flight/status only if that attached
session is nonrunning and belongs to the same project. `_lastResult` and its
title are not cleared by this branch. The attachment reference is then null, so
repeated null attachment is stable. A current running or unrelated recovering
owner follows the normal attachment path and remains in-flight; the underlying
session owner's existing running/attribution guard is unchanged.

Overview invokes the extracted private `GetPrimaryActionCallback`, which retains
the original `ResolvePrimaryAction || ResolveProviderInstallAction` expression
and uses the corrected actual Window in-flight field. Current label and callback
selection therefore agree after the legitimate SAFE aggregate clears recovery.
The added test calls real attachment/label/callback bodies: recovering attached
Window -> attributable SAFE aggregate -> null session -> in-flight false,
current Install label and nonnull production callback, original result preserved;
repeat stable; running and foreign/unattributed recovering sessions stay blocked.
The fixture explicitly attributes the stale test ID rather than manufacturing
historical action association from the backend observation.

## Limits and stop boundary

PASS_WITH_LIMITS covers attributable source/static review plus the declared
Coder synthetic evidence. Native Window/ScriptableObject allocation, Unity
OnEnable/rendering/confirmation, execution of the returned callback, actual
Unity/NUnit, current real S29 admission/holders/wrapper/generation, actual
terminal/refusal process execution, retained-effects marker production and full
golden path are NOT_RUN by this repair review. Retained-effects exact release is
source-verified reuse, not a newly executed retained-marker scenario.

Commit, export/package closure, reference switching, Unity/MCP/CUA/BatchMode,
Install/Uninstall/Configure/removal, history cleanup and process control were
not performed. An INSTALLED real S29 generation mismatch remains deferred;
this result does not promise that its Install button is now eligible, nor grant
Ready or full S29/release PASS. Original deferred runtime/release/cleanup items
remain explicit.

F1/F2 are closed and the agreed repair evidence is sufficient within these
limits. This review stops; User/Planner decides source acceptance and any later
separately authorized gate.

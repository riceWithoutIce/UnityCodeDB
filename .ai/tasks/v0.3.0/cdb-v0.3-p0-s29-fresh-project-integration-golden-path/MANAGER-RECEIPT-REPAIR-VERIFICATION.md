# S29 Manager receipt closure - independent verification

Date: 2026-10-08. Disposition: FINDING / FIX DECISION REQUIRED.
One BLOCKER from the existing normal Redeploy flow. This is a source-level
finding, not a Unity/runtime reproduction. Whole S29 remains PARTIAL.

## Stable identity and review envelope

Coder was stopped before dispatch. Independently checked HEAD
`651f9b3b4a8af3108823036107f1d76bc450f760`, empty staged index, and all nine
final SHA256 values in MANAGER-RECEIPT-REPAIR-RESULT.md: MATCH.
The result file SHA256 also MATCHED:
`AB58D2D0ACCF2CC762E6292DC09B43303699AB3B6B0DF19E1EC13E24ABCA4F0F`.

Read REVIEW-PACKET, REPAIR-TASK and REPAIR-RESULT completely. Reviewed changed
symbols and their direct consumers/fixtures only. No source edits, test reruns,
compiler launches, Unity/MCP/CUA, process probes, live receipt reads/writes,
Coder contact, recursive delegation, commit, export or publication occurred.
Only this verification report was written. Review completed within 30 minutes.

## B-MR-01 / BLOCKER: legitimate Redeploy stages become a permanent conflict

Primary changed anchors: `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs:817`
and `:849` (single completed stage versus all multistage sets), plus `:857`
(every accepted compatibility stage must itself be action-terminal).

The normal confirmed Host Payload Redeploy route deliberately has several
separately identified stages under one Manager action:

1. `AICodedbManagerWindow.cs:2441-2448` runs `redeploy-ui-preflight` with
   `terminalForAction=false`, then continues the same action at `:2511`.
2. `AICodedbActions.cs:113-114` runs `redeploy-worker-preflight` with false;
   `:147-148` runs `redeploy-mutation` with false; `:153-155` runs
   `redeploy-runtime-config` with true and returns the combined result.
3. `AICodedbProcessRunner.cs:661-664` includes the stage name in the stage ID,
   so these are distinct receipt directories, not overwrites of one stage.
4. The new reader collects all completed stages. More than one completed stage
   enters `RecoverFailedInstallFollowUp`, which accepts only exactly three
   action-terminal INSTALL/DryRun/Upgrade records. The legitimate four-stage
   Redeploy therefore returns Conflict at `:849-850`; even a three-stage worker
   set would fail its nonterminal-stage requirement at `:857-859`.

This affects the immediate successful execution, not just an unusual restart:
`AICodedbManagerWindow.cs:2799-2810` resolves durable action evidence after the
callback returns; `:2655-2659` converts this Conflict into an Indeterminate result.
It cannot release the durable index at `:2818-2823`, and `:3640-3652` switches the
session to recovering. `:3459-3463` then rejects subsequent Manager actions.
Re-reading the unchanged valid receipts produces the same Conflict. Previously
the reader adopted the final terminal stage while skipping these nonterminal
stages; the repair removed that behavior without recognizing the existing staged
producer. For previously resolved Redeploy receipts, journal validation at
`AICodedbManagerActionJournal.cs:355-379` likewise rejects a CommandTerminal marker
when the new aggregate returns Conflict.

User impact: a supported, confirmed Redeploy can complete its project mutation
and runtime-config generation but leave Manager unable to recognize completion
or admit the next operation. This meets the agreed BLOCKER criterion of normal
user-path failure. It is not a request to restore indiscriminate nonterminal
skipping: any repair must recognize the legitimate staged contract while keeping
unknown, extra-mutating and malformed evidence blocked.

Missing adjacent regression: the 19 new cases contain the special historical
three-stage shape and normal single-stage results, but no legitimate Redeploy
stage set. If User chooses FIX, verify this same finding with a production-reader
fixture for the real staged shape through session/admission, including its
resolved-marker path, while retaining the already frozen negative cases.

## Disposition of the six frozen claims

1. **Supported in inspected source.** Completed stages pass the strict
   admission/claim/terminal reader before aggregation (`ProcessRunner:800-810`,
   `:944-1064`). Pending stages use the pending validator (`:793-798`). Invalid
   evidence fails closed. The special aggregate returns the original INSTALL
   result (`:877-881`); `Actions:224-236` requires its failed CANDIDATE outcome,
   both mutation scopes and PENDING cleanup. Later COMPLETE does not replace it.
2. **Blocked by B-MR-01.** Negative/unknown evidence remains blocked and the
   single-stage terminal branch remains, but the adjacent legitimate multistage
   workflow is rejected. No blanket normal-flow acceptance is given.
3. **Supported in inspected source.** `Paths:104-124` resets inherited stage,
   terminality and tracker for detached/new identities and restores them in the
   scope. `EditorLifecycle:633`, `:1867` and `:2375` apply the detached context at
   reconcile and private automatic command boundaries. Captured roots remain;
   no confirmed-action fallback was added. Async/scope assertions exist in
   `AICodedbEditorLifecycleTests.cs:17-83`, but have not executed.
4. **Supported for the diagnosed shape, subject to B-MR-01 for Redeploy.**
   Journal scanning uses `RecoverManagerAction` (`ManagerActionJournal:350`),
   validates resolved markers against that outcome, retains failed INSTALL
   result/warning (`:389-400`, `:429-435`), and session restoration consumes that
   result (`ManagerWindow:3491-3510`). Known completed failure is distinguished
   from unknown. Removal confirmation and existing status safety admission are
   still required (`ManagerWindow:2222-2245`); no live removal gate was run.
5. **Supported in inspected source.** Conflict retains a validated marker or
   accepted original receipt context (`ManagerActionJournal:316-325`, `:350-354`,
   `:415-420`). Session conflict checks original action/project correspondence
   and tracks whether original context exists (`ManagerWindow:3511-3530`);
   warning rendering at `:501-507` explicitly says unavailable when it does not.
6. **Present, not executed; incomplete adjacent regression coverage.** The four
   failed-INSTALL cases, eight negative cases, one unavailable-context case,
   three single-stage cases and three lifecycle/context cases are declared.
   Fixtures use temporary roots, production receipt/journal readers, Package
   replacement, session recovery, removal presentation, confirmation cancellation
   and PENDING retention (`ManagerUiTests:18-238`). Session fixture isolates its
   temporary context and saves the original session (`:287-358`). B-MR-01 is not
   covered. These source observations are not test PASS or C# compile evidence.

## Evidence limits and procedural disclosure

No L0 harness, C# compilation, 19-case Editor execution, Unity, runtime, real
recovery/removal, full regression or release gate was run. Prior human 11-case
PASS and artifact 201-assertion PASS belong to the prior repair; they do not
validate this snapshot. F-IMC-01/P3 remains DEFERRED and was not reopened.

The Coder's declared guarded-output breach is preserved, not rehabilitated.
This Verifier also exceeded the 4 KiB per-read slice limit: a 69-line numbered
journal slice was measured at 6,168 UTF-8 bytes. Earlier under-80-line slices were
not byte-instrumented and may also exceed 4 KiB. After recognition, source reads
used byte-checked roughly 30-40-line slices; unchanged evidence was not replayed
to manufacture compliance. Commands remained below 200 lines/32 KiB and searches
below 50 returned matches/16 KiB; cumulative bytes were not instrumented, so no
certified overall guarded-output compliance is claimed. This is a separate
procedural limitation, not a substitute for or invalidation of the deterministic
source finding above.

Findings are returned once to Planner/User for FIX/DEFER/ACCEPT/STOP disposition.
No implementation was requested from Coder. Stop this review here; any fix review
should cover B-MR-01 and its immediate regressions only.

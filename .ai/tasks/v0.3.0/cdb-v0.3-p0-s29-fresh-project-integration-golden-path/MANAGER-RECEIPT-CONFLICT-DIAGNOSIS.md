# S29 Manager historical action conflict - read-only diagnosis

Date: 2026-10-08. Status: CAUSE_IDENTIFIED / SOURCE_CHANGE_NOT_STARTED.
User authorized continuing the exact-action read-only comparison. No source,
receipt, resolved marker, project/runtime/configuration or Unity state changed.
No live process/service probe, action replay, test execution or cleanup.

## Exact evidence scope

Action: d8c736504562495dbafdd673c6851efb.
Project receipt index:
C:/Users/admin/AppData/Local/Rice/CodeDB/manager-actions/a31d47273d22f34d00000fc2.
Index has one Package directory, index.lock, and the action's resolved marker.
Bound Package directory: 484a0de012a134f1eec7c80f.
Only this action's three stage directories and admitted/claim/terminal JSON
files were read. Ancestors/entries checked for reparse; stage count bounded to
32, marker 32 KiB, receipt files 1 MiB. No recursive machine-wide discovery.

Resolved marker: schema 1, disposition CommandTerminal; SHA256
fa25ef8f4b00e84a326d3238c33bd922bed160d931bc62091f0be260b47031a7.
Its project/package roots and keys agree with every stage's admission:
G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-compile-fix-70f33f7/review/com.rice.ai-codedb.
Thus the conflict is NOT a simple marker-versus-admission Package key mismatch.

| Stage prefix | Admitted action | UTC completed | Exit | terminal_for_action in admission AND receipt | Product effects |
| --- | --- | --- | --- | --- | --- |
| 21d439d6 | Install | 2026-10-07T07:06:04.4954570Z | 6 | true / true | CANDIDATE failure, host_runtime + instance_candidate, PENDING |
| 5a92364e | DryRun | 2026-10-07T07:06:07.1954356Z | 0 | true / true | status output; no COMMAND_RESULT mutation claim |
| adf9f6ec | Upgrade | 2026-10-07T07:06:10.1747866Z | 6 | true / true | PREFLIGHT failure, mutated_scopes empty, COMPLETE for this attempt only |

All three stages have matching action/stage/project/package keys across
admission/claim/terminal, and matching command hash/effect/authorization/
project-identity/package-identity/terminal flag across admission/terminal.
Envelope schema/managed_by/state comparisons show zero mismatches. Writer PIDs
match claims; child PIDs are positive and distinct. Timeout, output overflow
and incomplete drain are false. Raw terminal timestamps parse using the exact
.NET round-trip O rule and occur after claimed writer start ticks. These are
record consistency checks, not proof about currently running processes.

An initial diagnostic converted JSON timestamps automatically to DateTime,
making a later string cast look invalid. That intermediate false result was
discarded; raw JSON timestamp strings above were rechecked directly. No timestamp
defect is established. Receipt JSON was not rewritten.

## Consumer chain and cause

1. AICodedbProcessRunner.RecoverManagerAction (around 735-812) loads all stages;
   after one valid terminal_for_action result, another such result returns
   Conflict("Multiple terminal stages claim the same Manager action.").
2. AICodedbManagerActionJournal.ReadHistorical... (around 336-361) sees the
   CommandTerminal resolved marker but recovery is not Terminal, then throws
   the screenshot's generic resolved-marker/original-receipt conflict.
3. All three real stage records claim action-level finality. The source rule
   deterministically refuses this combination even though each stage has its
   own completed command. Command completion and unique action finality have
   been conflated in the historical record set.

This conclusion is direct data comparison plus production source tracing.
The Unity C# reader was not invoked anew or compiled outside Unity during this
read-only diagnosis; no new runtime reproduction is claimed.

The actual old Package source still contains unconditional RequestReconcile
after RunInstallCodeDB/Async. Manager runs the action inside UseActionContext;
action identities are AsyncLocal and CurrentActionStageIsTerminal defaults true.
RequestReconcile can immediately dispatch background reconciliation, consistent
with the observed Install -> DryRun -> Upgrade sequence sharing this action ID.
The persisted three receipts prove shared attribution; source explains its
available route. No second user click or exact unobserved scheduler timing is
inferred. Latest repair suppresses failed-Install reconciliation prospectively,
but leaves historical conflicting receipts untouched as required.

## Separate display defect

ManagerActionJournal's historical-conflict return preserves actionId/detail but
returns null Index, losing the original execution context. ManagerWindow's
Restore/Conflict branch (around 3493-3504) builds the session with
prior?.Context ?? currentContext. The banner labels this context PackageRoot
as "original Package" (around line 503). With no prior recovering context, this
shows the new failed-install-recovery-poc40 Package even though every actual
receipt and the resolved marker still names compile-fix-70f33f7.
Do not treat this UI fallback as proof that the stored original path changed.

## Recommended coherent next repair (proposal, not implementation)

Unify Manager action versus command-stage result semantics and historical
classification. Keep stage completion, action outcome and outstanding project
effects separate. Explicitly isolate unrelated lifecycle observation/convergence
from the user action's action-terminal context. Read-only status must not inherit
ConfirmedProjectMutation / UserConfirmation attribution merely from async context.

For this historical shape, validate every actual stage and retain all original
bytes. Define an explicit bounded aggregate classification that preserves the
original failed INSTALL and PENDING effects while recognizing subsequent completed
observation / rejected-before-effect stages. Do not choose first/latest terminal
blindly, delete receipts, rewrite terminal flags or let a later COMPLETE clear
the original PENDING state. Unknown outcomes, unclassified mutations or conflicting
identities still block. If a durable summary is needed, bind it to the complete
original receipt hashes under the existing journal owner, not a competing executor.
Known failed completion must not be relabeled unknown just because multiple
stage records require classification; removal safety remains its separate gate.

Preserve original Package context in conflict display, or label it unavailable;
never substitute the current Package while calling it original.

Focused fixture should use the real historical three-stage shape through actual
production writer/reader boundaries, plus one-terminal normal path, genuine
conflict/unknown, changed Package context, original PENDING preservation and the
same Manager admission -> removal presentation path. No broad historical recovery
platform, machine scan, or automatic replay. Continue child Coder -> stable
snapshot -> independent Verifier only after source-repair disposition.

Existing 11 human tests, 201 exact-artifact assertions and source ACCEPT stay
valid for their scope. Missing coverage is cross-session historical Manager
receipt admission after failed-action follow-up, before the recovery engine.
Whole S29/live recovery remains BLOCKED. Unity may remain open for discussion;
closing/reopening or rerunning tests cannot resolve these persistent records.

## Receipt fingerprints

| Stage prefix | admitted SHA256 | claim SHA256 | terminal SHA256 |
| --- | --- | --- | --- |
| 21d439d6 | fe3171876821e511b7347e49ab0578b2eee945271356ad5345f4f0c61120c599 | aa840f6a1d045347c176080ce034bb5945668e9106a52f89bbada02dfbe3a2ab | b03ebbb90521b5b0c4d1352c3bc1b424994bcebf780bc1e23dd94d5b5dae5748 |
| 5a92364e | 3900a1001d5806625d5bcc6720a26c63a77f8ac415f0c8bebf63f2fe76957f76 | 44c14b9d82b3451ffc6b678ca1fe0164ab1e8d6dc830b215c6925fb140ff1b99 | 6e9c24ec18bc25568979e4c2f8340bd0b9537e0f4c3b89deef79a4ab62430feb |
| adf9f6ec | 5bdfa928a8a7c00789bf3be7aee2529b2f20d7adfa483b7e3081522de88a2db6 | 9b35780b556f3e0630bcfbaa8cd0daf20824384a869b4d61bee5b151bc47a215 | dfdc36ad718ccd627f3003d82f528fb60868f5c7505e18223d2a44b54de47bb1 |

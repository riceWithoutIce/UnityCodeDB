# Missing optional bootstrap root blocks the Manager retained reader

2026-10-09. READ_ONLY_DIAGNOSIS_CONFIRMED / FRESH_MANAGER_INSTALL_NOT_DISPATCHED.
S29 PARTIAL. User reported no Install CodeDB button with screenshot.
No product edit, real runtime/receipt write, Install/Uninstall, test rerun,
Unity control, package switch, process termination or Coder dispatch performed.

## Observed block and evidence

Screenshot: project is explicitly uninstalled; banner reports unknown previous
action and blocks new project changes. Last activity detail:
"Manager action index validation failed: Failed candidate contains an unrecorded effect."
Manager hides the Install entry under that history conflict. No new Install
action or candidate has been dispatched in this human attempt.

Current manifest and lock select the exact accepted s29-original-root-poc42
extraction. Source and extracted AICodedbManagerActionJournal.cs both contain
the same refusal. Parent mirrored only its three-root bounded traversal in
read-only PowerShell, without replacing or executing the C# reader:

| Root | Entries traversed | Unrecorded paths |
| --- | --- | --- |
| candidate5a6ff71560234b558e1a42148b680a77 | 32 | 0 |
| host/generations/poc.40 | 31 | 0 |
| AIWork/codedb | 1 attempted root | AIWork/codedb (absent) |

The optional flat root is absent on disk; there is no new file/unknown candidate
effect. Nine baseline original/history/new-link files unchanged; desired hash
matches authentic recovered UNINSTALLED/PENDING state.

## Exact consumer disagreement

PowerShell Get-FailedPreparationEffects (codedb-instance-engine.ps1) validates
safe path/reparse traversal, then explicitly continues if AIWork/codedb is absent.
Other missing retained roots refuse. Thus its emitted authenticated inventory
correctly has no row for the absent optional root.

C# ReadRetainedEffects marker consumption (AICodedbManagerActionJournal.cs around
419-436) enqueues candidate, generation and AIWork/codedb unconditionally. Its
unrecorded-effect exception permits only *existing directories* for the two
fixed flat launcher ancestors. An absent AIWork/codedb therefore fails snapshot
membership and that directory exemption, causing the screenshot's exact error.
This is a deterministic producer/consumer optional-root semantics gap.
Existing hash/record identity and native recovery proof remain intact.

## Coverage gap and scoped next proposal

The PS emitted-record consumer test exists, but retained-only fixture selection
uses WrapperMode CURRENT. Its emitted proof setup proceeds through a synthetic
fresh Install handoff before the C# consumer reads it. That path does not prove
the real intermediate state where the optional flat root is still absent.
The original-root task verified path spelling through actual CLI but did not
execute the Manager C# consumer on the real absent-root topology. Prior backend
and exact-package PASS therefore did not close this human Manager gate.

Propose only align this C# optional-root traversal with the existing PS contract:
skip an absent, unrecorded AIWork/codedb after existing safe-path checks; keep
recorded-file/directory hash/existence checks, mandatory instance/generation
roots, redirects, unknown-present entries and bounds refusing. Include offending
relative path in the adjacent refusal diagnostic.
Add actual-PS-emitted proof -> C# reader coverage before a fresh handoff with
flat root absent; adjacent missing recorded/mandatory path and new unknown entry
must still conflict. Preserve original outcome and immutable hashes.

No creation of an empty real AIWork/codedb directory to bypass this finding,
no forced button display or direct backend Install workaround. No global path/
Host audit, new schema, generation bump or physical-cleanup relaxation.
Implementation and independent review await User's scoped disposition.
Unity may remain open during alignment/source work; only a later approved
Package reference switch requires a closed target Editor.

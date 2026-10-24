# S29 path-guard separation — exact-package human result

Date: 2026-10-12 (Asia/Shanghai).
Status: `FOCUSED_HUMAN_GATE_PASS_WITH_LIMITS / SHUTDOWN_CONFIRMED`.
This status covers the reported Manager/tab/shutdown checks and visible
path-guard diagnostic only; focused Unity EditMode tests remain NOT_REPORTED.

## Exact source and delivery

- Commit: `b76957a9dbcae9b00eff73775a97c4e8f33ae785`.
- Package: `.artifacts/s29-manager-admission-b76957a/review/com.rice.ai-codedb`.
- ZIP: `.artifacts/s29-manager-admission-b76957a/com.rice.ai-codedb.zip`.
- ZIP SHA256: `f6b82ec21851c528ab9e947e9d1f058059be02a5f389e3b3c56cf937806f3c20`.
- Human checklist: PATH-GUARD-SEPARATION-HUMAN-CHECKLIST.md.
- Delivery evidence: PATH-GUARD-SEPARATION-DELIVERY-RESULT.md.

## Human and screenshot evidence

The user reported:

> Manager 关闭重开、页签切换、Unity 正常关闭 都正常

These three checks are HUMAN PASS for this run. Screenshot evidence:

`C:/Users/admin/AppData/Local/Temp/codex-clipboard-7596e853-1c2f-4b4b-b96f-e9c997ae1bbc.png`

The visible Manager no longer displays
`Manager action index escapes its user-local root`. Its Last activity panel
instead reports ambiguous historical candidate ownership: candidate
`330b7a972a7649259409fbce4de8ca56`, originating action
`73c9d6a0a8ba4df0898721265ec515d6`, has no matching Manager action journal
marker or terminal closure. The diagnostics also report that the selected
generation manifest does not match the Package generation manifest.

These visible reasons are consistent with the intentionally retained
fail-closed admission boundary. The screenshot does not establish that the
historical ownership conflict was resolved, that Install became available,
or that authenticated Ready was reached. This record does not independently
audit or reconcile the historical candidate/receipt chain.

## Bounded read-only confirmation

At 2026-10-12T14:10:05+08:00:

- HEAD matches the exact commit above.
- S29 manifest and lock parse successfully and both select
  `file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-manager-admission-b76957a/review/com.rice.ai-codedb`.
- Lock source is `local`; target package.json exists.
- The actual ZIP SHA256 matches the delivery record above.
- No Editor/C# test source diff or staged path was reported by the scoped Git
  checks. Existing unrelated dirty/untracked state remains preserved.
- Process enumeration found no S29 Unity process. The observed Unity process
  was the unrelated miniGame_int project (PID 50768), which was untouched.
  This supports process exit; crash-free close is the user's human observation.

## Acceptance limits and disposition

Manager close/reopen, tab switching and normal Unity shutdown passed according
to the user report. The old false user-local-root diagnostic is absent from
the supplied screenshot. The four focused EditMode groups / nine cases in
the checklist were not explicitly reported for this exact package; their
Unity execution remains NOT_REPORTED. No test-result XML was examined and
Unity compilation was not separately claimed by this report.

Source evidence remains semantic compilation with zero errors, standalone
focused 9/9 PASS and read-only Verifier PASS_WITH_LIMITS without BLOCKER/P1/P2,
as recorded in PATH-GUARD-SEPARATION-REPAIR-RESULT.md. Those evidence classes
do not substitute for the missing focused Unity test report.

Historical orphan attribution, multi-failure recovery policy and installed
generation/package alignment remain deferred. Install button restoration,
real Install/removal/reinstall, runtime readiness and full release acceptance
are outside this focused result; S29/release remain PARTIAL.

Only task evidence was recorded after the human report. No product source,
package export, project reference switch, Unity launch/test automation,
Install, Uninstall, Remove Integration, Configure, process control,
receipt/candidate/runtime/history cleanup, commit, push or publication was
performed. Further repairs or operational actions require a new explicit task.

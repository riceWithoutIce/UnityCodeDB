# S29 compact receipt layout FIX01 - Coder result

2026-10-08. F1/F2 corrections complete; stable source snapshot ready for parent
admission and the bounded independent repair review. HUMAN_COMPILE_TEST_PENDING.
Only ManagerUiTests.cs and ManagerActionJournal.cs changed in FIX01. Original
RECEIPT-LAYOUT-RESULT.md, IDENTITY.json and review remain historical records.

## F1 - compact fixture consumers

The remaining INSTALL admitted/terminal consumers now use the existing StagePath
helper. The Add return/local and helper parameters explicitly say stagePrefix.
The missing-predecessor scenario deletes only its named admitted.json, claim.json,
terminal.json and optional start-failure.json records. It validates all paths
against workspace ownership and asserts the three required records exist before
any deletion, then rechecks ownership for each exact file. It never deletes the
action container or treats the prefix as a directory.

Required-file assertions now precede intentional compact record corruption or
deletion in the affected scenarios and ChangeField helper. The original business
assertions remain intact. Explicit legacy stage-directory fixtures were not
rewritten.

## F2 - authenticated identity retained on conflict

The resolved compact conflict return now carries an index constructed from the
already validated marker Context, action key and StorageLayout. It follows the
adjacent legacy generic-title/effect convention. Disposition remains Conflict;
no receipt-controlled replacement identity or successful result is fabricated.

The existing eight UnclassifiedEvidenceStaysBlockedWithOriginalPackage cases now
assert original project/Package roots, action ID and compact layout in the journal
read and restored session, authenticated-context/conflict flags, no historical
success result, and both session and durable-journal refusal of new admission.
Their original warning and blocked-reentry assertions remain.

## Checks and human inventory

- One scoped git diff --check: PASS.
- Narrow compact-consumer consistency inspection: PASS; stale INSTALL Path.Combine,
  prefix-as-directory deletion and misleading compact stageRoot patterns removed.
- Pre-fix hashes matched all nine entries in original IDENTITY. Final FIX01 hashes
  show exactly the two authorized source changes; the other seven match pre-fix.
- Frozen Editor inventory checked against source attributes: unchanged34 methods /
  80 cases. No new cases. All C#/Unity tests remain NOT RUN.

Directly strengthened methods are:

| Method | Existing cases |
| --- | ---: |
| ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain |11|
| ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage |8|
| ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown |3|

Shared fixture/helper corrections are covered by the same frozen34/80 inventory
listed in the original result. This is authored source evidence, not runtime PASS.
No PathProvenanceOnly, script parser batch or writer scenarios were rerun. Prior
PowerShell12/12 evidence remains attributable to the exact unchanged writer and
fixture script hashes; FIX01 adds no new executable PowerShell evidence.

## Identity and handoff

Base/final HEAD:332c7ffd510daebb6da6a386d66783d4aabf6bd6.
Branch:codex/v0.3.0-legacy-workflow. Git index unchanged:
C23240C3B59C82E0E7F794A030D47DF1A8E68657A553AA308AC60F456B07FD65.
RECEIPT-LAYOUT-FIX01-IDENTITY.json contains all nine pre/final hashes.

No scripts, ManagerWindow, ProcessRunner, path authority, versions, generations,
real project/reference, live receipt state or prior evidence were edited. No
Unity/C# execution, process probe, real cleanup, commit, export or publication.
The named unfinished dependency check remains assigned to the independent
Verifier by FIX01-TASK; this Coder did not reopen that audit or execute its fixture.

Stopped after the single planned check set, without corrected retries. Parent
may admit the final identity for F1/F2 repair review and the named dependency gap.

# Process observation 02 — preflight rejected an absent session

Date: 2026-10-21. Status: STOPPED_BEFORE_ETW_CREATE / NO_SESSION_LEFT.

The user executed the authorized launcher in administrator Windows PowerShell.
The screenshot shows RUN02_EVIDENCE followed by OBSERVER_ENDED OBSERVER_ERROR,
without OBSERVER_READY. The receipt confirms initial query exit -2144337918
(0x80300002), exception `Cannot establish absent session; no start attempted`,
null start/stop codes, empty before hashes and no host events. Only receipt.json
exists in the evidence directory; no ETL was created. A read-only exact-name
query confirms the session is absent. There was no observer-ready window or
instruction from the parent to trigger a target chat.

Evidence: `.artifacts/tests/s39-process-observation/6b144c9ac2b34dcc921c447585171f8c/receipt.json`.
Original receipt is retained unmodified. Its after hashes are a terminal snapshot,
not a before/after invariance comparison because the before set is empty.

## Cause and correction

The observer required both an absent-session exit code and an exact English
output sentence to proceed. In this run, the English-text condition rejected the
known absent-session code. This is an observer preflight defect, not evidence
about UnityCodeDB initialize or a failure to enable the process provider.

The failed run did not retain initial query text, so its exact character/locale
difference is unknown. A later non-elevated read-only query in Windows PowerShell
5.1 returned the same code with English text; do not claim that reproduces the
administrator output or proves Chinese localization was the original trigger.

The observer now uses numeric PLA_E_DCS_NOT_FOUND (0x80300002) for both preflight
and final absence checks, retains initial query text, prints caught exceptions,
and explicitly reports an unconfirmed partial-session state. Unknown query
errors still fail closed. No real create/start/stop was issued during this repair.

## Verification and next boundary

Four mocked cases passed on each of Windows PowerShell 5.1.19041.6456 and
PowerShell 7.6.5: localized absent-session output plus partial-create cleanup;
existing-session isolation; unknown initial query rejection; unknown post-cleanup
query reporting. Real ETW calls in those fixtures: zero. Results are retained in
the `compatibility-windowsps51-*` and `compatibility-pwsh7-*` directories under
the same evidence parent. This checks observer logic/host compatibility only;
successful administrator provider enable and actual emitted fields remain untested.

This bounded attempt is stopped. The corrected, prefilled observation 03 launcher
is prepared, not run, at
`.artifacts/tests/s39-process-observation/launch-03-eae4fb16d8894512967086c76f0ceaab.ps1`.
It uses a new session/output identity and preserves observation 02. Any fresh
real window follows user authorization; do not rerun the old launcher or ask
the target session to initialize before OBSERVER_READY.

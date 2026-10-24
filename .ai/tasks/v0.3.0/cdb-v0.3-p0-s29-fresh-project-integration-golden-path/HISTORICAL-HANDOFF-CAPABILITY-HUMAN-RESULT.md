# S29 historical handoff capability — human Unity result

Date: 2026-10-13. Status: HUMAN_TEST_UI_CLOSE_REPORTED_PASS /
PRODUCT_AUTHENTICATION_UNRESOLVED. S29/release remain PARTIAL.

## Human evidence

The user reports `testrun 通过`, Manager open/close/reopen once and tab
switching passed, and Unity closed without hanging. Record these as human
reported PASS for this run. No exact method list, case count or exported NUnit
result was supplied, so this record does not claim a quantified full-suite or
individual comparator/preflight-case execution result. A successful Test Runner
report is consistent with compilation, but no separate compile assertion was
explicitly supplied in this message.

The attached Manager screenshot shows:

- CodeDB needs attention: `CodeDB could not safely identify its control state.
  No project changes were made.`
- Control contract migration: Error / Review required. The visible detail ends
  with `...nticated Supervisor status is not an owner-bound coord_ready
  observation.` The clipped screenshot is not a complete diagnostic payload.
- Previous action: unknown command outcome; new project changes remain blocked
  until execution safety is proved.
- Outcome unconfirmed: `Manager action index validation failed: Retained
  candidate fresh selection is not authenticated.`
- No recent command; Coordinator startup NOT_EVALUATED and other product layers
  not evaluated. No authenticated removal availability is demonstrated.

Screenshot source supplied by the user:
`C:/Users/admin/AppData/Local/Temp/codex-clipboard-3737033d-bce9-4e3c-b150-f824573ae6ab.png`.
This is a temporary attachment location, not a retained release artifact.

## Post-human read-only checks

Both project Package references still select
`.artifacts/s29-historical-handoff-04e9a6b/review/com.rice.ai-codedb`.
Manifest hash remains
936a1efb51c3b847b1fb134e7064a8d6c1821fc538f9399673e36158598879b9;
lock hash remains
1a1ae372733552c4d970bc9fe5f8ba009930c6dbd4fd4421e80a522379449ce1.
Exact ZIP hash remains d76c5a2cec01323c6bd220564a78dee2a75d67e0da6dccd2aa74d8015d4ea681.
All eight exact Package source hashes match the accepted terminal record.

Desired/current/activation/operation hashes still match the pre-human delivery
baseline. The resolved successful INSTALL index dc72675b... remains resolved
with its original Package attribution; its last-write timestamp is 2026-10-10.
This one resolved record does not resolve the separate unconfirmed historical
candidate shown by Manager, and no receipt/index was repaired or cleared.

The Supervisor event tail records authenticated_shutdown at
2026-10-13T10:34:27.270Z (18:34:27 local). Latest materialize operation-history
entries still date to the older 11:10 local session. No new automatic Upgrade
appeared in that bounded operation-history inspection. This does not establish
authenticated removal routing, sustained Ready or complete lifecycle coverage.

A point-in-time process check found S29 Unity.exe PID 60832. Therefore this
read-only check does not assert that the project is currently closed. The
human's report that their close completed without hanging is retained; no
process was stopped or Editor log from another project treated as S29 evidence.

## Acceptance boundary and handoff

Test Runner/UI interaction/one normal close passed as reported. Product
authentication remains unresolved in the screenshot, so continuous Ready,
controlled removal presentation and the actual recovery route are not accepted
by this run. The screenshot does not by itself identify a new production root
cause or justify weakening authentication. Prior source/Package evidence and
the accepted previous-v2 removal-only boundary remain attributable.

No Unity launch/automation, live Probe/Ensure, real Remove/Install/Upgrade,
process control, history cleanup, new source repair, export, reference switch,
push or publication was performed after this human report.
Next action: align the remaining control-authentication and historical-action
presentation issue before any separately authorized diagnosis/repair or real
operation. CleanupMono remains observation-only; this run supplied a normal
close sample, not a universal shutdown fix claim.

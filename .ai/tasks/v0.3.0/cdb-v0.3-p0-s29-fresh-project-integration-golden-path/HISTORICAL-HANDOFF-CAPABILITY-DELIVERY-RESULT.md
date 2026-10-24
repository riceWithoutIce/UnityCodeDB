# S29 historical handoff capability — delivery result

Date: 2026-10-13. Status: REFERENCE_SWITCH_COMPLETE / HUMAN_UNITY_PENDING.

## Source and package

- Source commit: `04e9a6bd49ae46f5c10989f6e4c6efddc479ad24`.
- Exactly eight allowlisted Package source/test paths were committed; no push.
- Exact Package ZIP: `.artifacts/s29-historical-handoff-04e9a6b/com.rice.ai-codedb.zip`.
- ZIP SHA256: `d76c5a2cec01323c6bd220564a78dee2a75d67e0da6dccd2aa74d8015d4ea681`.
- ZIP inventory: 617 entries; uncompressed Package bytes `13,071,668`.
- Commit-stage and exact-extraction byte closure, production payload admission,
  native build and Package release closure all passed.
- Compared with the prior 617-entry ZIP, exactly the eight accepted paths differ;
  all Payload/generation and other Package entries are byte-identical.

## Project reference switch

- Project: `UnityFreshInstallValidationProjectS29`.
- Backup root: `.backups/s29-historical-handoff-04e9a6b/`.
- Backups: `manifest.json` SHA256
  `9adea12c24219aea55d06364dbb38346b418079746e59c05c37fcb7efd8fbc09`;
  `packages-lock.json` SHA256
  `507a4db713e10748a63d7a694729649f5550b2e2e42cd449d86a74636d9982d6`.
- Both JSON files parse successfully; each has exactly one new reference and no
  old reference. New Package path is the exact review extraction above.
- Protected desired/current/activation/operation JSON hashes remained unchanged.
- No matching S29 Unity process was present before the switch. Unity was not
  started or automated by this delivery.

## Remaining acceptance boundary

Human Unity must validate the exact switched Package. Source and Package gates
do not prove Unity import, EditMode/NUnit execution, lifecycle lease IO,
Manager presentation, Provider behavior or shutdown stability. Real
Remove/Install/Upgrade/Uninstall, push, publication and release remain outside
this delivery.

Current S29 status: PARTIAL / HUMAN_TEST_UI_CLOSE_REPORTED_PASS /
PRODUCT_AUTHENTICATION_UNRESOLVED. See
HISTORICAL-HANDOFF-CAPABILITY-HUMAN-RESULT.md for the user result, screenshot
limits and bounded read-only reference/runtime checks. Do not replay delivery.

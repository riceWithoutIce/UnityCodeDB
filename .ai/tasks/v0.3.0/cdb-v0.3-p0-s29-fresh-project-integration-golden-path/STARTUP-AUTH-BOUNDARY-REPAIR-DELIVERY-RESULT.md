# S29 startup authentication boundary — delivery result

Date: 2026-10-14, Asia/Shanghai.
Status: DELIVERY_COMPLETE / HUMAN_UNITY_PENDING.

2026-10-14 continuation: the human reported 52 focused EditMode cases passed,
Manager reopen/tabs and Unity close normal. Post-human reference/protected
hash checks passed. See STARTUP-AUTH-BOUNDARY-REPAIR-HUMAN-RESULT.md.
The photographed historical removal preflight is still refused (exit 4), so
real recovery, sustained Ready and S29/release closure remain pending.

## Commit

Accepted source was committed as:

`c6c2f036aa3c5d08a2334118d9049eff9dd3b875`

Commit subject: `fix: separate historical candidate and readiness admission`.
The commit contains exactly the five accepted source/test files:

- `com.rice.ai-codedb/Editor/AICodedbControlContract.cs`
- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`

Pre-existing dirty and untracked repository content was not staged or committed.

## Exact package

Exporter: `com.rice.ai-codedb/Tests~/export-codedb-package.ps1`.
Output root:
`.artifacts/s29-startup-auth-boundary-c6c2f03/`.

- Review package: `.artifacts/s29-startup-auth-boundary-c6c2f03/review/com.rice.ai-codedb`
- ZIP: `.artifacts/s29-startup-auth-boundary-c6c2f03/com.rice.ai-codedb.zip`
- ZIP SHA256: `fa181fb701c0824271dd7c68a71e766d4b9493914d88b3f1031f68bf7d36b04b`
- 617 files / ZIP entries; 13,117,412 uncompressed bytes

Commit-staged and exact-ZIP validation both passed:

`PRODUCTION_PAYLOAD_ADMISSION PASS`, `PACKAGE_BYTE_CLOSURE PASS`,
`source_count=60`, `mismatch_count=0`.

Package generation remains `poc.43`; runtime contract hash remains
`69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.

## S29 reference switch

Target: `UnityFreshInstallValidationProjectS29`.

Both files now select exactly:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-startup-auth-boundary-c6c2f03/review/com.rice.ai-codedb`

- `Packages/manifest.json`
- `Packages/packages-lock.json`

Parsed references are equal and the exact package `package.json` exists.
Original files were copied before the switch to:
`.backups/s29-startup-auth-boundary-c6c2f03/`.
Original hashes:

- manifest: `936a1efb51c3b847b1fb134e7064a8d6c1821fc538f9399673e36158598879b9`
- lock: `1a1ae372733552c4d970bc9fe5f8ba009930c6dbd4fd4421e80a522379449ce1`

Current hashes:

- manifest: `99dd35fff5d95eea9a775986ccc5afca7e9af79517a6ab1b8f1ecb06a62903b7`
- lock: `b03cdcbbf3dcb636a263442de847d565e38444d2aa810c5456907e708cfe8d49`

The five Unity processes observed during preflight belonged to `G:/work/miniGame_int`
and its AssetImportWorkers. No process command line referenced
`UnityFreshInstallValidationProjectS29`; no process was stopped.

## Human gate

Do not repeat Install or export. Open the S29 project with the switched
reference and perform the existing human checklist: compile/import observation,
focused EditMode tests if part of the declared Unity gate, open Manager, close
and reopen once, switch tabs, observe status/readiness transitions, and close
Unity. Record any first-close block separately from this delivery result.

This delivery does not claim Unity import, EditMode execution, UI acceptance,
live Supervisor IPC/readiness, runtime, device, or release acceptance. S29 and
release remain `PARTIAL` until the human result is recorded.

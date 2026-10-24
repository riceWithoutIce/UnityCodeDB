# S29 retained-candidate package-mismatch recovery — delivery result

Date: 2026-10-11 (Asia/Shanghai).

## Source delivery

- Source commit: `9179d8a1a679056bef19b7e9246988510c3c9284` (`fix(s29): expose safe install after package switch`).
- Allowlist: `Editor/AICodedbManagerActionJournal.cs`, `Editor/AICodedbManagerWindow.cs`, `Tests/Editor/AICodedbManagerUiTests.cs`.
- Verifier disposition: `PASS_WITH_LIMITS`; original P1 selected-instance-origin bypass is fixed.
- Unity, runtime, receipt, Install, Uninstall, MCP, publication, and push were not run.

## Exact package

- Output root: `.artifacts/s29-package-mismatch-recovery-9179d8a`.
- Review package: `.artifacts/s29-package-mismatch-recovery-9179d8a/review/com.rice.ai-codedb`.
- ZIP: `.artifacts/s29-package-mismatch-recovery-9179d8a/com.rice.ai-codedb.zip`.
- ZIP SHA256: `80f0a6caa55b1486a65da2862f038c09e3e5d18c59e4629625d93417e0190663`.
- 586 files / ZIP entries.
- Commit-staged and exact-ZIP closure/admission: PASS, `source_count=60`, `mismatch_count=0`.
- Runtime contract SHA256: `24bc8da5c9fb1914113b0d9270ecbb77285b09a7ce9f31841a6ac58906863604`.

## S29 reference switch

Project: `UnityFreshInstallValidationProjectS29`.

Both `Packages/manifest.json` and `Packages/packages-lock.json` now select:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-package-mismatch-recovery-9179d8a/review/com.rice.ai-codedb`

Parsed references are equal and the exact package `package.json` exists. The previous reference files are backed up under `.backups/s29-package-mismatch-recovery-9179d8a/`.

## Acceptance boundary

The new package is ready for human Unity import/compilation and Manager observation. Do not execute Install automatically from this delivery step. The next human gate is one normal `Install CodeDB` action if the button is visible, followed by terminal-result and Ready/reopen observation. Unity/runtime/release acceptance remains pending.
